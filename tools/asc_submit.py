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
def subs_(): return call("GET", f"/v1/reviewSubmissions?filter[app]={APP}&filter[platform]=IOS&limit=20")["data"]
for x in subs_(): print("sub", x["id"], x["attributes"]["state"])
old = next((x["id"] for x in subs_() if x["attributes"]["state"] in ("WAITING_FOR_REVIEW", "IN_REVIEW")), None)
if old:
    call("PATCH", f"/v1/reviewSubmissions/{old}", {"data": {"type": "reviewSubmissions", "id": old, "attributes": {"canceled": True}}})
    for _ in range(40):
        j = call("GET", f"/v1/reviewSubmissions/{old}", ok=(200, 404)); st = j["data"]["attributes"]["state"] if j.get("data") else "GONE"; print("old", st)
        if st not in ("CANCELING", "WAITING_FOR_REVIEW", "IN_REVIEW"): break
        time.sleep(15)
for _ in range(40):
    vs = call("GET", f"/v1/apps/{APP}/appStoreVersions?filter[platform]=IOS&limit=5")["data"]
    st = vs[0]["attributes"]["appStoreState"]; print("version", st)
    if st in ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED"): break
    time.sleep(15)
v = vs[0]["id"]
b = None
for _ in range(60):
    bs = call("GET", f"/v1/builds?filter[app]={APP}&sort=-uploadedDate&limit=3")["data"]
    b = next((x for x in bs if int(x["attributes"]["version"]) >= 17 and x["attributes"]["processingState"] == "VALID"), None)
    if b: break
    time.sleep(30)
if not b: raise SystemExit("build 17 not ready")
call("PATCH", f"/v1/appStoreVersions/{v}/relationships/build", {"data": {"type": "builds", "id": b["id"]}})
print("attached build", b["attributes"]["version"])
sub = next((x["id"] for x in subs_() if x["attributes"]["state"] == "READY_FOR_REVIEW"), None)
if not sub:
    sub = call("POST", "/v1/reviewSubmissions", {"data": {"type": "reviewSubmissions", "attributes": {"platform": "IOS"}, "relationships": {"app": {"data": {"type": "apps", "id": APP}}}}})["data"]["id"]
call("POST", "/v1/reviewSubmissionItems", {"data": {"type": "reviewSubmissionItems", "relationships": {"reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub}}, "appStoreVersion": {"data": {"type": "appStoreVersions", "id": v}}}}}, ok=(201, 409))
print("iap state", call("GET", f"/v2/inAppPurchases/{IAP}")["data"]["attributes"]["state"])
try:
    call("POST", "/v1/inAppPurchaseSubmissions", {"data": {"type": "inAppPurchaseSubmissions", "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": IAP}}}}})
    print("iap added")
except SystemExit as e: print("iap:", str(e)[:500])
print("items", len(call("GET", f"/v1/reviewSubmissions/{sub}/items")["data"]))
r = call("PATCH", f"/v1/reviewSubmissions/{sub}", {"data": {"type": "reviewSubmissions", "id": sub, "attributes": {"submitted": True}}})
print("submission", r["data"]["attributes"]["state"])
print("iap", call("GET", f"/v2/inAppPurchases/{IAP}")["data"]["attributes"]["state"])
print("DONE")
