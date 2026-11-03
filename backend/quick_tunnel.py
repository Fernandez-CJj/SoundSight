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


def run(args):
    for label, path in (("Cloudflare program", args.cloudflared),
                        ("Firebase credential file", args.credentials)):
        if not path.is_file():
            raise RuntimeError(f"{label} was not found: {path}")
    if args.check_only:
        print("Tunnel launcher checks passed. Nothing was started or written to Firebase.")
        return

    try:
        ready = health(LOCAL_URL)
    except Exception:
        ready = False
    if not ready:
        raise RuntimeError("Start Backend.cmd first, then wait for workerAvailable: true at "
                           + LOCAL_URL + "/health before opening this launcher.")

    # Check the credential belongs to this app before opening a public tunnel.
    certificate = credentials.Certificate(str(args.credentials.resolve()))
    if certificate.project_id != PROJECT:
        raise RuntimeError("The credential file belongs to a different Firebase project.")
    app = firebase_admin.initialize_app(certificate, {"projectId": PROJECT})
    database = firestore.client(app=app)
    data_dir = ROOT / "data"
    data_dir.mkdir(exist_ok=True)
    try:
        lock = WorkerLock(data_dir / "quick-tunnel.lock")
    except RuntimeError:
        raise RuntimeError("A Quick Tunnel launcher is already open. Close it first.") from None
    tree = None
    reader = None
    try:
        urls = queue.Queue()
        print("Starting Cloudflare Quick Tunnel...", flush=True)
        tree = ProcessTree(
            [str(args.cloudflared.resolve()), "tunnel", "--no-autoupdate", "--url", LOCAL_URL],
            subprocess.PIPE, ROOT, runner_gate=False)

        def read_output():
            with (data_dir / "quick-tunnel.log").open("a", encoding="utf-8") as log:
                for raw in iter(tree.process.stdout.readline, b""):
                    line = raw.decode("utf-8", errors="replace")
                    log.write(line)
                    log.flush()
                    print(line.rstrip(), flush=True)
                    for match in TUNNEL_URL.finditer(line):
                        if match.group(1) != "api":
                            urls.put(match.group(0))

        reader = threading.Thread(target=read_output, daemon=True)
        reader.start()
        deadline = time.monotonic() + 120
        public_url = None
        while time.monotonic() < deadline:
            if tree.process.poll() is not None:
                raise RuntimeError("Cloudflare stopped. See backend/data/quick-tunnel.log.")
            try:
                public_url = urls.get(timeout=1)
                break
            except queue.Empty:
                pass
        if public_url is None:
            raise RuntimeError("Cloudflare did not provide an address within two minutes.")

        print("Checking the public connection...", flush=True)
        while time.monotonic() < deadline:
            if tree.process.poll() is not None:
                raise RuntimeError("Cloudflare stopped before the connection was ready.")
            try:
                if health(public_url):
                    break
            except Exception:
                pass
            time.sleep(2)
        else:
            raise RuntimeError("The public address is not ready. No new address was saved.")

        database.document(CONFIG_DOCUMENT).set({
            "baseUrl": public_url,
            "updatedAt": firestore.SERVER_TIMESTAMP,
            "jobProtocol": 1,
        }, timeout=15)
        (data_dir / "public-backend-url.txt").write_text(public_url + "\n", encoding="utf-8")
        print("\nREADY: Firebase now contains the new address.", flush=True)
        print("Phone apps using Firebase discovery can connect without a new APK.", flush=True)
        print("Public health page: " + public_url + "/health", flush=True)
        print("Keep this window open. Press Ctrl+C to stop the tunnel.\n", flush=True)
        while tree.process.poll() is None:
            time.sleep(1)
        raise RuntimeError("Cloudflare stopped. Reopen Start Quick Tunnel.cmd to reconnect.")
    finally:
        if tree:
            tree.close()
        if reader:
            reader.join(timeout=3)
        lock.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cloudflared", type=Path,
                        default=Path.home() / "Downloads/cloudflared-windows-amd64.exe")
    parser.add_argument("--credentials", type=Path,
                        default=Path.home() / "SoundSightKeys/soundsight-service-account.json")
    parser.add_argument("--check-only", action="store_true")
    args = parser.parse_args()
    try:
        run(args)
    except KeyboardInterrupt:
        print("\nTunnel stopped. The backend and worker have not been stopped.")
        return 0
    except Exception as error:
        print("\nCould not start the public connection: " + str(error))
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
