#!/usr/bin/env python3
"""
Sync MarshSight waitlist signups into TestFlight external testers.

Reads the waitlist emails from your Supabase, then adds any that are not yet
testers to a TestFlight external beta group via the App Store Connect API. Run
it whenever you want to invite new signups. Your data goes straight from your
Supabase to Apple; nothing leaves your machine otherwise.

Prerequisites:
  - platform/api/.env has SUPABASE_URL and SUPABASE_SERVICE_KEY.
  - The App Store Connect API key .p8 is at the path below.
  - You have created an EXTERNAL beta group in App Store Connect (TestFlight).

Usage:
  python3 sync_waitlist_testers.py                # uses the first external group
  python3 sync_waitlist_testers.py "Field Testers"  # target a group by name
  python3 sync_waitlist_testers.py --dry-run      # show who would be added
"""
import json, time, base64, subprocess, urllib.request, urllib.error, sys, os

# --- Config ---
KID = "A42DC5CRJT"
ISS = "4da8cc25-8b63-4764-82b6-f9629d9805ae"
P8 = os.path.expanduser("~/.appstoreconnect/private_keys/AuthKey_A42DC5CRJT.p8")
APP_ID = "6784405350"
ASC = "https://api.appstoreconnect.apple.com"

def load_env():
    env = {}
    path = os.path.join(os.path.dirname(__file__), "..", "api", ".env")
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, _, v = line.partition("=")
                env[k.strip()] = v.strip()
    return env

def b64u(b): return base64.urlsafe_b64encode(b).rstrip(b"=")

def asc_jwt():
    hdr = b64u(json.dumps({"alg": "ES256", "kid": KID, "typ": "JWT"}).encode())
    now = int(time.time())
    pay = b64u(json.dumps({"iss": ISS, "iat": now, "exp": now + 1000,
                           "aud": "appstoreconnect-v1"}).encode())
    signing = hdr + b"." + pay
    der = subprocess.run(["openssl", "dgst", "-sha256", "-sign", P8],
                         input=signing, capture_output=True).stdout
    i = 2
    if der[1] & 0x80: i = 2 + (der[1] & 0x7f)
    def rd(i): ln = der[i + 1]; return der[i + 2:i + 2 + ln].lstrip(b"\x00"), i + 2 + ln
    r, i = rd(i); s, i = rd(i)
    sig = b64u(r.rjust(32, b"\x00") + s.rjust(32, b"\x00"))
    return (signing + b"." + sig).decode()

def asc_call(method, path, body=None):
    url = ASC + path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers={
        "Authorization": "Bearer " + asc_jwt(), "Content-Type": "application/json"})
    try:
        r = urllib.request.urlopen(req, timeout=40)
        return r.status, json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read() or b"{}")

def waitlist_emails(env):
    url = f"{env['SUPABASE_URL']}/rest/v1/waitlist?select=email"
    req = urllib.request.Request(url, headers={
        "apikey": env["SUPABASE_SERVICE_KEY"],
        "Authorization": "Bearer " + env["SUPABASE_SERVICE_KEY"]})
    rows = json.loads(urllib.request.urlopen(req, timeout=40).read())
    return sorted({r["email"].strip().lower() for r in rows if r.get("email")})

def main():
    args = [a for a in sys.argv[1:] if a != "--dry-run"]
    dry = "--dry-run" in sys.argv
    group_name = args[0] if args else None

    env = load_env()

    # Find the external beta group.
    _, groups = asc_call("GET", f"/v1/apps/{APP_ID}/betaGroups?limit=50")
    externals = [g for g in groups.get("data", []) if not g["attributes"].get("isInternalGroup")]
    if group_name:
        externals = [g for g in externals if g["attributes"].get("name") == group_name]
    if not externals:
        print("No external beta group found. Create one in TestFlight first.")
        return
    group = externals[0]
    gid = group["id"]
    print(f"Group: {group['attributes']['name']} ({gid})")

    # Emails already in the group.
    _, existing = asc_call("GET", f"/v1/betaGroups/{gid}/betaTesters?limit=200&fields[betaTesters]=email")
    have = {t["attributes"]["email"].strip().lower() for t in existing.get("data", [])}

    emails = waitlist_emails(env)
    todo = [e for e in emails if e not in have]
    print(f"Waitlist: {len(emails)} | already testers: {len(have)} | to add: {len(todo)}")

    if dry:
        for e in todo: print("  would add:", e)
        return

    added, failed = 0, 0
    for e in todo:
        code, resp = asc_call("POST", "/v1/betaTesters", {"data": {
            "type": "betaTesters", "attributes": {"email": e},
            "relationships": {"betaGroups": {"data": [{"type": "betaGroups", "id": gid}]}}}})
        if code in (200, 201):
            added += 1; print("  added:", e)
        else:
            failed += 1
            print("  failed:", e, resp.get("errors", [{}])[0].get("detail", code))
    print(f"Done. Added {added}, failed {failed}.")

if __name__ == "__main__":
    main()
