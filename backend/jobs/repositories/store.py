"""SQLite is authoritative for admission, execution and delivery retries.

No Firebase imports here: concurrency and recovery can be tested offline.
"""
import json
import os
from pathlib import Path
import sqlite3
import time
import uuid
from contextlib import contextmanager

ACTIVE = ("admitting", "queued", "processing", "finishing")
TERMINAL = ("completed", "failed", "cancelled")


class ClosingConnection(sqlite3.Connection):
    def __exit__(self, *args):
        try:
            return super().__exit__(*args)
        finally:
            self.close()


class QueueError(Exception):
    def __init__(self, status, message):
        self.status = status
        super().__init__(message)


class Store:
    def __init__(self, path=None):
        self.path = Path(path or os.environ.get(
            "SOUNDSIGHT_JOBS_DB", Path(__file__).resolve().parents[2] / "data/jobs.sqlite3"))
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with self.connect() as db:
            db.execute("PRAGMA journal_mode=WAL")
            db.executescript("""
                CREATE TABLE IF NOT EXISTS jobs (
                    id TEXT PRIMARY KEY, owner TEXT NOT NULL, kind TEXT NOT NULL,
                    target TEXT NOT NULL, submission TEXT NOT NULL,
                    state TEXT NOT NULL, created REAL NOT NULL, started REAL,
                    finished REAL, attempts INTEGER NOT NULL DEFAULT 0,
                    snapshot TEXT NOT NULL, revision TEXT NOT NULL,
                    outcome TEXT, result TEXT, error TEXT,
                    UNIQUE(owner, submission)
                );
                CREATE INDEX IF NOT EXISTS queue_order ON jobs(state, created);
                CREATE TABLE IF NOT EXISTS runtime (key TEXT PRIMARY KEY, value REAL);
                CREATE TABLE IF NOT EXISTS devices (
                    installation TEXT PRIMARY KEY, owner TEXT NOT NULL,
                    token TEXT NOT NULL, language TEXT NOT NULL, updated REAL NOT NULL
                );
                CREATE TABLE IF NOT EXISTS deliveries (
                    job TEXT NOT NULL, installation TEXT NOT NULL, token TEXT NOT NULL,
                    attempts INTEGER NOT NULL DEFAULT 0, next_at REAL NOT NULL DEFAULT 0,
                    PRIMARY KEY(job, installation)
                );
                CREATE TABLE IF NOT EXISTS cleanup (job TEXT PRIMARY KEY);
            """)

    def connect(self):
        db = sqlite3.connect(self.path, timeout=10, factory=ClosingConnection)
        db.row_factory = sqlite3.Row
        db.execute("PRAGMA synchronous=FULL")
        db.execute("PRAGMA busy_timeout=10000")
        return db

    @contextmanager
    def transaction(self):
        with self.connect() as db:
            db.execute("BEGIN IMMEDIATE")
            yield db

    @staticmethod
    def decode(row):
        if row is None:
            return None
        job = dict(row)
        job["snapshot"] = json.loads(job["snapshot"])
        job["result"] = json.loads(job["result"]) if job["result"] else {}
        return job

    def get(self, job_id, owner=None):
        with self.connect() as db:
            job = self.decode(db.execute("SELECT * FROM jobs WHERE id=?", (job_id,)).fetchone())
        if job is None or (owner is not None and job["owner"] != owner):
            raise QueueError(404, "The job was not found.")
        return job

    def existing(self, owner, submission, kind, target):
        with self.connect() as db:
            job = self.decode(db.execute(
                "SELECT * FROM jobs WHERE owner=? AND submission=?", (owner, submission)).fetchone())
        if job and (job["kind"] != kind or job["target"] != target):
            raise QueueError(409, "This submission identifier belongs to another request.")
        return job

    def reserve(self, owner, kind, target, submission, snapshot, revision):
        with self.transaction() as db:
            row = db.execute("SELECT * FROM jobs WHERE owner=? AND submission=?",
                             (owner, submission)).fetchone()
            if row:
                job = self.decode(row)
                if job["kind"] != kind or job["target"] != target:
                    raise QueueError(409, "This submission identifier belongs to another request.")
                return job
            # Music-sheet jobs share a target namespace; compositions use a separate one.
            collection = "composition" if kind == "composition" else "sheet"
            rows = db.execute("SELECT kind,target,owner,state FROM jobs WHERE state IN (?,?,?,?)", ACTIVE).fetchall()
            if any(r["owner"] == owner and r["target"] == target and
                   ("composition" if r["kind"] == "composition" else "sheet") == collection for r in rows):
                raise QueueError(409, "This item already has an unfinished task.")
            if sum(r["owner"] == owner for r in rows) >= 2:
                raise QueueError(429, "You already have two unfinished tasks.")
            if sum(r["state"] in ("admitting", "queued") for r in rows) >= 20:
                raise QueueError(429, "The waiting list is full. Try again later.")
            job_id = uuid.uuid4().hex
            db.execute("""INSERT INTO jobs
                (id,owner,kind,target,submission,state,created,snapshot,revision)
                VALUES (?,?,?,?,?,'admitting',?,?,?)""",
                (job_id, owner, kind, target, submission, time.time(), json.dumps(snapshot, default=str), revision))
        return self.get(job_id)

    def ready(self, job_id):
        with self.transaction() as db:
            db.execute("UPDATE jobs SET state='queued' WHERE id=? AND state='admitting'", (job_id,))

    def abandon(self, job_id):
        with self.transaction() as db:
            db.execute("DELETE FROM jobs WHERE id=? AND state='admitting'", (job_id,))

    def pending(self, state):
        with self.connect() as db:
            return [self.decode(r) for r in db.execute(
                "SELECT * FROM jobs WHERE state=? ORDER BY created,id", (state,))]

    def claim(self):
        with self.transaction() as db:
            if db.execute("SELECT 1 FROM jobs WHERE state IN ('processing','finishing') LIMIT 1").fetchone():
                return None
            row = db.execute("SELECT id FROM jobs WHERE state='queued' ORDER BY created,id LIMIT 1").fetchone()
            if row is None:
                return None
            db.execute("UPDATE jobs SET state='processing',started=?,attempts=attempts+1 WHERE id=?",
                       (time.time(), row[0]))
        return self.get(row[0])

    def finish(self, job_id, outcome, result=None, error=None):
        if outcome not in TERMINAL:
            raise ValueError("Invalid outcome")
        with self.transaction() as db:
            db.execute("""UPDATE jobs SET state='finishing',outcome=?,result=?,error=?,finished=?
                WHERE id=? AND state='processing'""",
                (outcome, json.dumps(result or {}), error, time.time(), job_id))

    def cancel(self, job_id, owner):
        with self.transaction() as db:
            row = db.execute("SELECT * FROM jobs WHERE id=? AND owner=?", (job_id, owner)).fetchone()
            if row is None:
                raise QueueError(404, "The job was not found.")
            if row["state"] == "cancelled" or (row["state"] == "finishing" and row["outcome"] == "cancelled"):
                return
            if row["state"] != "queued":
                raise QueueError(409, "Only waiting tasks can be cancelled.")
            db.execute("UPDATE jobs SET state='finishing',outcome='cancelled',finished=? WHERE id=?",
                       (time.time(), job_id))

    def recover(self, job):
        with self.transaction() as db:
            if job["attempts"] < 2:
                # Preserve the active reservation, ahead of the waiting list.
                db.execute("UPDATE jobs SET attempts=attempts+1,started=? WHERE id=? AND state='processing'",
                           (time.time(), job["id"]))
            else:
                db.execute("""UPDATE jobs SET state='finishing',outcome='failed',error=?,finished=?
                    WHERE id=? AND state='processing'""",
                    ("Processing was interrupted again. Please retry.", time.time(), job["id"]))
        return self.get(job["id"])

    def commit_terminal(self, job):
        with self.transaction() as db:
            changed = db.execute("UPDATE jobs SET state=?,outcome=?,error=? WHERE id=? AND state='finishing'",
                                 (job["outcome"], job["outcome"], job["error"], job["id"])).rowcount
            if changed:
                db.execute("INSERT OR IGNORE INTO cleanup VALUES (?)", (job["id"],))
            if changed and job["outcome"] in ("completed", "failed"):
                db.execute("""INSERT OR IGNORE INTO deliveries(job,installation,token)
                    SELECT ?,installation,token FROM devices WHERE owner=?""", (job["id"], job["owner"]))

    def heartbeat(self):
        with self.connect() as db:
            db.execute("INSERT OR REPLACE INTO runtime VALUES ('heartbeat',?)", (time.time(),))

    def cleanup_jobs(self):
        with self.connect() as db:
            return [self.decode(r) for r in db.execute("SELECT j.* FROM jobs j JOIN cleanup c ON c.job=j.id LIMIT 20")]

    def cleanup_done(self, job_id):
        with self.connect() as db:
            db.execute("DELETE FROM cleanup WHERE job=?", (job_id,))

    def health(self):
        with self.connect() as db:
            counts = {r[0]: r[1] for r in db.execute("SELECT state,count(*) FROM jobs GROUP BY state")}
        return {"workerAvailable": self.available(), "waiting": counts.get("queued", 0) + counts.get("admitting", 0),
                "processing": counts.get("processing", 0), "awaitingSync": counts.get("finishing", 0),
                "waitingCapacity": 20, "concurrency": 1}

    def available(self):
        with self.connect() as db:
            row = db.execute("SELECT value FROM runtime WHERE key='heartbeat'").fetchone()
        return bool(row and time.time() - row[0] < 30)

    def register(self, installation, owner, token, language):
        with self.transaction() as db:
            db.execute("DELETE FROM devices WHERE token=? AND installation<>?", (token, installation))
            db.execute("INSERT OR REPLACE INTO devices VALUES (?,?,?,?,?)",
                       (installation, owner, token, language, time.time()))

    def unregister(self, installation, owner):
        with self.connect() as db:
            db.execute("DELETE FROM devices WHERE installation=? AND owner=?", (installation, owner))

    def deliveries(self):
        with self.connect() as db:
            return [dict(r) for r in db.execute("""SELECT d.*,v.owner,v.language FROM deliveries d
                JOIN devices v ON v.installation=d.installation AND v.token=d.token
                JOIN jobs j ON j.id=d.job AND j.owner=v.owner
                WHERE d.next_at<=? LIMIT 30""", (time.time(),))]

    def delivery_done(self, delivery, invalid=False):
        with self.transaction() as db:
            db.execute("DELETE FROM deliveries WHERE job=? AND installation=?", (delivery["job"], delivery["installation"]))
            if invalid:
                db.execute("DELETE FROM devices WHERE installation=? AND token=?", (delivery["installation"], delivery["token"]))

    def delivery_retry(self, delivery):
        with self.connect() as db:
            db.execute("UPDATE deliveries SET attempts=attempts+1,next_at=? WHERE job=? AND installation=?",
                       (time.time() + min(3600, 2 ** min(delivery["attempts"] + 3, 12)), delivery["job"], delivery["installation"]))


def public_job(job):
    state = job["state"]
    if state == "admitting":
        state = "queued"
    elif state == "finishing":
        # The result is not public until Firebase has committed it.
        state = "queued" if job["outcome"] == "cancelled" else "processing"
    return {"jobId": job["id"], "taskType": job["kind"], "targetId": job["target"],
            "status": state, "attemptCount": job["attempts"], "error": job["error"]}
