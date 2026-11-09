"""Start a Quick Tunnel and publish its current address using trusted PC credentials."""
import argparse
import json
from pathlib import Path
import queue
import re
import subprocess
import threading
import time
from urllib.request import Request, urlopen

import firebase_admin
from firebase_admin import credentials, firestore

from jobs.process_guard import ProcessTree, WorkerLock

ROOT = Path(__file__).resolve().parent
PROJECT = "soundsight-b1d16"
LOCAL_URL = "http://127.0.0.1:8000"
CONFIG_DOCUMENT = "appConfig/backend"
TUNNEL_URL = re.compile(r"https://([a-z0-9-]+)\.trycloudflare\.com\b")


def health(base_url):
    request = Request(base_url + "/health", headers={"Cache-Control": "no-cache"})
    with urlopen(request, timeout=5) as response:
        data = json.load(response)
    return (data.get("status") == "ok" and data.get("jobProtocol") == 1
            and data.get("workerAvailable") is True)


def read_output(process, urls):
    for raw in iter(process.stdout.readline, b""):
        line = raw.decode("utf-8", errors="replace")
        print(line.rstrip(), flush=True)
        for match in TUNNEL_URL.finditer(line):
            if match.group(1) != "api":
                urls.put(match.group(0))


def wait_for_url(process, urls):
    deadline = time.monotonic() + 120
    while time.monotonic() < deadline:
        if process.poll() is not None:
            raise RuntimeError(f"Cloudflare exited with code {process.returncode}. See its output above.")
        try:
            return urls.get(timeout=1)
        except queue.Empty:
            pass
    raise RuntimeError("No tunnel URL received within 120 seconds. See Cloudflare output above.")


def wait_for_backend(public_url, process):
    deadline = time.monotonic() + 120
    last_error = "The API or processing worker is not ready."
    while time.monotonic() < deadline:
        if process.poll() is not None:
            raise RuntimeError(f"Cloudflare exited with code {process.returncode} before readiness.")
        try:
            if health(public_url):
                return
        except Exception as error:
            last_error = str(error)
        time.sleep(2)
    raise RuntimeError(f"Public backend health check failed: {last_error}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cloudflared", type=Path,
                        default=Path.home() / "Downloads/cloudflared-windows-amd64.exe")
    parser.add_argument("--credentials", type=Path,
                        default=Path.home() / "SoundSightKeys/soundsight-service-account.json")
    args = parser.parse_args()
    tree = None
    lock = None
    reader = None
    stage = "Checking startup files"
    try:
        for path in (args.cloudflared, args.credentials):
            if not path.is_file():
                raise RuntimeError(f"File not found: {path}")
        stage = "Checking the local backend"
        if not health(LOCAL_URL):
            raise RuntimeError("The API or worker is not ready. Start Backend.cmd first.")
        stage = "Loading Firebase credentials"
        certificate = credentials.Certificate(str(args.credentials.resolve()))
        if certificate.project_id != PROJECT:
            raise RuntimeError("The credentials belong to a different Firebase project.")
        app = firebase_admin.initialize_app(certificate, {"projectId": PROJECT})
        database = firestore.client(app=app)
        (ROOT / "data").mkdir(exist_ok=True)
        stage = "Acquiring the tunnel lock (close any other tunnel launcher)"
        lock = WorkerLock(ROOT / "data/quick-tunnel.lock")
        stage = "Starting Cloudflare"
        print(stage, flush=True)
        tree = ProcessTree(
            [str(args.cloudflared.resolve()), "tunnel", "--no-autoupdate", "--url", LOCAL_URL],
            subprocess.PIPE, ROOT, runner_gate=False)
        urls = queue.Queue()
        reader = threading.Thread(target=read_output, args=(tree.process, urls), daemon=True)
        reader.start()
        public_url = wait_for_url(tree.process, urls)
        stage = "Checking the public backend"
        print(f"{stage}: {public_url}", flush=True)
        wait_for_backend(public_url, tree.process)
        stage = "Saving the URL to Firebase"
        database.document(CONFIG_DOCUMENT).set({
            "baseUrl": public_url,
            "updatedAt": firestore.SERVER_TIMESTAMP,
            "jobProtocol": 1,
        }, timeout=15)
        print(f"READY: saved {public_url} to Firebase. Keep this window open; Ctrl+C stops the tunnel.", flush=True)
        stage = "Running Cloudflare"
        code = tree.process.wait()
        raise RuntimeError(f"Cloudflare exited with code {code}. Reopen Start Quick Tunnel.cmd.")
    except KeyboardInterrupt:
        print("\nTunnel stopped. The backend and worker have not been stopped.")
        return 0
    except Exception as error:
        print(f"\n{stage} failed: {error}")
        return 1
    finally:
        if tree:
            tree.close()
        if reader:
            reader.join(timeout=3)
        if lock:
            lock.close()


if __name__ == "__main__":
    raise SystemExit(main())
