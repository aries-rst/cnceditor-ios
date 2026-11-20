import os, time, hashlib, json, glob, jwt, requests
KID = os.environ["ASC_KEY_ID"]; ISS = os.environ["ASC_ISSUER_ID"]; KEY = os.environ["ASC_KEY"]
APP = "6836888868"; IAP = "6836914348"; B = "https://api.appstoreconnect.apple.com"
def H():
    t = jwt.encode({"iss": ISS, "iat": int(time.time()), "exp": int(time.time()) + 900, "aud": "appstoreconnect-v1"}, KEY, algorithm="ES256", headers={"kid": KID})
    return {"Authorization": "Bearer " + t, "Content-Type": "application/json"}
def call(m, p, body=None, ok=(200, 201, 204)):
    r = requests.request(m, B + p if p.startswith("/") else p, headers=H(), data=json.dumps(body) if body else None)
    if r.status_code not in ok: raise SystemExit(f"{m} {p} -> {r.status_code} {r.text[:3000]}")
    return r.json() if r.text else {}
def upload(kind_path, create_body, patch_path, f):
    data = open(f, "rb").read()
    body = create_body(os.path.basename(f), len(data)); r = call("POST", kind_path, body)["data"]
    for op in r["attributes"]["uploadOperations"]:
        hs = {h["name"]: h["value"] for h in op["requestHeaders"]}
        x = requests.put(op["url"], headers=hs, data=data[op["offset"]:op["offset"] + op["length"]]); x.raise_for_status()
    call("PATCH", patch_path + "/" + r["id"], {"data": {"type": r["type"], "id": r["id"], "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
    print("uploaded", f, r["id"])
subs = call("GET", f"/v1/reviewSubmissions?filter[app]={APP}&filter[platform]=IOS&limit=20")["data"]
for x in subs: print("sub", x["id"], x["attributes"]["state"])
old = next((x["id"] for x in subs if x["attributes"]["state"] == "WAITING_FOR_REVIEW"), None)
if old:
    call("PATCH", f"/v1/reviewSubmissions/{old}", {"data": {"type": "reviewSubmissions", "id": old, "attributes": {"canceled": True}}})
    for _ in range(40):
        st = call("GET", f"/v1/reviewSubmissions/{old}")["data"]["attributes"]["state"]; print("old", st)
        if st in ("CANCELING",): time.sleep(15); continue
        if st != "WAITING_FOR_REVIEW": break
        time.sleep(15)
vs = call("GET", f"/v1/apps/{APP}/appStoreVersions?filter[platform]=IOS&limit=5")["data"]
for _ in range(40):
    vs = call("GET", f"/v1/apps/{APP}/appStoreVersions?filter[platform]=IOS&limit=5")["data"]
    st = vs[0]["attributes"]["appStoreState"]; print("version", st)
    if st in ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED"): break
    time.sleep(15)
v = vs[0]["id"]
subs = call("GET", f"/v1/reviewSubmissions?filter[app]={APP}&filter[platform]=IOS&limit=20")["data"]
sub = next(x["id"] for x in subs if x["attributes"]["state"] == "READY_FOR_REVIEW")
call("POST", "/v1/reviewSubmissionItems", {"data": {"type": "reviewSubmissionItems", "relationships": {"reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub}}, "appStoreVersion": {"data": {"type": "appStoreVersions", "id": v}}}}})
items = call("GET", f"/v1/reviewSubmissions/{sub}/items")["data"]; print("items", len(items))
r = call("PATCH", f"/v1/reviewSubmissions/{sub}", {"data": {"type": "reviewSubmissions", "id": sub, "attributes": {"submitted": True}}})
print("submission", r["data"]["attributes"]["state"])
print("iap", call("GET", f"/v2/inAppPurchases/{IAP}")["data"]["attributes"]["state"])
print("DONE")
