# Use one APK when your Quick Tunnel address changes

The app now gets the current public backend address from the Firestore document
`appConfig/backend`. Your PC's launcher updates that document automatically
whenever you start a new Quick Tunnel. Firebase only supplies the address;
conversions still run on your PC.

## One-time setup

1. Deploy this project's updated Firestore rules. Open PowerShell in
   `C:\Users\CJ\Desktop\SoundSight` and run:

   ```powershell
   firebase.cmd deploy --only firestore:rules --project soundsight-b1d16
   ```

   If asked to sign in, first run `firebase.cmd login`. The rules allow verified,
   signed-in app users to read this specific setting. They do not allow app
   users, including admin-app accounts, to change the address. The PC's Firebase
   Admin credential is used to update it. No service-account key goes in the APK.

2. Keep the downloaded Cloudflare program at:

   ```text
   C:\Users\CJ\Downloads\cloudflared-windows-amd64.exe
   ```

3. Keep your existing Firebase credential at:

   ```text
   C:\Users\CJ\SoundSightKeys\soundsight-service-account.json
   ```

4. Install a newly built APK containing Firebase discovery. Build using the IDE's
   Flutter SDK, with no `SOUNDSIGHT_BACKEND_URL` argument:

   ```powershell
   & "$env:USERPROFILE\develop\flutter\bin\flutter.bat" build apk --release
   ```

   The APK is `build\app\outputs\flutter-apk\app-release.apk`. Do not reuse a
   previous APK containing a LAN or tunnel address. Users need this update once;
   subsequent tunnel address changes do not need new APKs.

## Start hosting each day

1. Double-click **Start Backend.cmd** in the project root. Keep its API and worker
   windows open.
2. Open `http://127.0.0.1:8000/health`. Wait for `workerAvailable: true`.
3. Double-click **Start Quick Tunnel.cmd** in the project root.
4. Wait for **READY: Firebase now contains the new address.** The launcher checks
   the public connection before updating Firebase. Keep this third window open.
5. Open the app and sign in with a verified account. Turn off Wi-Fi and use mobile
   data on your phone, then try a conversion. It should reach your PC from outside
   your home network.

You do not need to copy the new tunnel address into the app or Firebase yourself.
Cloudflare is a standalone program, not a Python virtual environment. The
launcher reuses `backend/venv` for its Firebase helper, so no new venv is needed.

## When the address changes

Reopen **Start Quick Tunnel.cmd**. After its READY message, users can reopen the
app or try their request again. The app refreshes on verified sign-in and resume,
shares a two-minute in-memory cache between requests, and refreshes after
connection failures or expired-tunnel responses.

Job submissions reuse the same submission identifier if a request is repeated
after an address change. Publishing/unpublishing is not automatically repeated
after an uncertain connection failure; users can try it again themselves.

If the PC, backend, worker, internet, or tunnel is off, conversion features remain
unavailable. Firebase does not replace the PC. The old URL stays in Firebase when
the tunnel stops; the next successful startup replaces it. Quick Tunnels are for
testing/development and do not guarantee availability.

To stop the tunnel, press Ctrl+C in its window. This does not stop the API or
worker. Close any existing Quick Tunnel launcher before starting a new one.

## Check the setup without starting it

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\backend\start-tunnel.ps1 -CheckOnly
```

This checks local files/imports only. It does not create a public tunnel, write to
Firebase, deploy rules, or verify internet access. Normal startup checks the
backend, public connection, and Firebase write.

Logs are in ignored `backend/data/quick-tunnel.log`. The most recently published
URL is also saved to `backend/data/public-backend-url.txt`. These contain no
service-account private key.

If Cloudflare is moved, update `CloudflaredPath` in `backend/start-tunnel.ps1`.
An existing `.cloudflared/config.yaml` or `config.yml` may interfere with Quick
Tunnels; check Cloudflare's error output rather than changing app settings.

## Optional: local Wi-Fi development

For a deliberate LAN-only build, pass your PC's current LAN address explicitly:

```powershell
& "$env:USERPROFILE\develop\flutter\bin\flutter.bat" run --dart-define=SOUNDSIGHT_BACKEND_URL=http://192.168.0.104:8000
```

This override bypasses Firebase discovery. Remove it for the distributed APK.

References:
- https://developers.cloudflare.com/tunnel/get-started/quick-tunnels/
- https://firebase.google.com/docs/firestore/security/rules-conditions
