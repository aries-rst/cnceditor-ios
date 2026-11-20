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
# 1) права на контент (шрифты и Clipper — открытые лицензии)
call("PATCH", f"/v1/apps/{APP}", {"data": {"type": "apps", "id": APP, "attributes": {"contentRightsDeclaration": "USES_THIRD_PARTY_CONTENT"}}})
print("content rights ok")
# 2) цена: бесплатно (США — базовая страна)
pp = call("GET", f"/v1/apps/{APP}/appPricePoints?filter[territory]=USA&limit=200")["data"]
free = next(p for p in pp if float(p["attributes"]["customerPrice"]) == 0)
call("POST", "/v1/appPriceSchedules", {"data": {"type": "appPriceSchedules", "relationships": {
    "app": {"data": {"type": "apps", "id": APP}}, "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
    "manualPrices": {"data": [{"type": "appPrices", "id": "${p0}"}]}}},
    "included": [{"type": "appPrices", "id": "${p0}", "attributes": {"startDate": None}, "relationships": {"appPricePoint": {"data": {"type": "appPricePoints", "id": free["id"]}}}}]})
print("price free ok")
# 3) материковый Китай — убрать из стран (нужны лицензия и оценки безопасности)
av = call("GET", f"/v1/apps/{APP}/appAvailabilityV2")["data"]["id"]
url = f"/v2/appAvailabilities/{av}/territoryAvailabilities?include=territory&limit=200"
while url:
    j = call("GET", url)
    for t in j["data"]:
        if t["relationships"]["territory"]["data"]["id"] == "CHN" and t["attributes"].get("available"):
            call("PATCH", f"/v1/territoryAvailabilities/{t['id']}", {"data": {"type": "territoryAvailabilities", "id": t["id"], "attributes": {"available": False}}}); print("CHN removed")
    url = j.get("links", {}).get("next")
# 4) ждём сборку без NSUserTrackingUsageDescription (номер > 12)
vs = call("GET", f"/v1/apps/{APP}/appStoreVersions?filter[platform]=IOS&limit=5")["data"]
v = [x for x in vs if x["attributes"]["appStoreState"] in ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED")][0]["id"]
b = None
for _ in range(80):
    bs = call("GET", f"/v1/builds?filter[app]={APP}&sort=-uploadedDate&limit=3")["data"]
    b = next((x for x in bs if int(x["attributes"]["version"]) >= 14 and x["attributes"]["processingState"] == "VALID"), None)
    if b: break
    time.sleep(30)
if not b: raise SystemExit("new build not ready")
call("PATCH", f"/v1/appStoreVersions/{v}/relationships/build", {"data": {"type": "builds", "id": b["id"]}})
print("attached build", b["attributes"]["version"])
# 5) заявка: версия (+ покупка Premium идёт вместе с первой версией)
subs = call("GET", f"/v1/reviewSubmissions?filter[app]={APP}&filter[platform]=IOS")["data"]
sub = next((x["id"] for x in subs if x["attributes"]["state"] == "READY_FOR_REVIEW"), None)
if not sub:
    sub = call("POST", "/v1/reviewSubmissions", {"data": {"type": "reviewSubmissions", "attributes": {"platform": "IOS"}, "relationships": {"app": {"data": {"type": "apps", "id": APP}}}}})["data"]["id"]
call("POST", "/v1/reviewSubmissionItems", {"data": {"type": "reviewSubmissionItems", "relationships": {"reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub}}, "appStoreVersion": {"data": {"type": "appStoreVersions", "id": v}}}}}, ok=(201, 409))
try:
    call("POST", "/v1/inAppPurchaseSubmissions", {"data": {"type": "inAppPurchaseSubmissions", "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": IAP}}}}})
    print("iap submitted")
except SystemExit as e: print("iap:", str(e)[:400])
r = call("PATCH", f"/v1/reviewSubmissions/{sub}", {"data": {"type": "reviewSubmissions", "id": sub, "attributes": {"submitted": True}}})
print("submission", r["data"]["attributes"]["state"])
print("DONE")
