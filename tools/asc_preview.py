import os, time, hashlib, json, glob, jwt, requests
KID = os.environ["ASC_KEY_ID"]; ISS = os.environ["ASC_ISSUER_ID"]; KEY = os.environ["ASC_KEY"]
APP = "6836888868"; IAP = "6836914348"; B = "https://api.appstoreconnect.apple.com"
def H():
    t = jwt.encode({"iss": ISS, "iat": int(time.time()), "exp": int(time.time()) + 900, "aud": "appstoreconnect-v1"}, KEY, algorithm="ES256", headers={"kid": KID})
    return {"Authorization": "Bearer " + t, "Content-Type": "application/json"}
def call(m, p, body=None, ok=(200, 201, 204)):
    r = requests.request(m, B + p if p.startswith("/") else p, headers=H(), data=json.dumps(body) if body else None)
    if r.status_code not in ok: raise SystemExit(f"{m} {p} -> {r.status_code} {r.text[:600]}")
    return r.json() if r.text else {}
def upload(kind_path, create_body, patch_path, f):
    data = open(f, "rb").read()
    body = create_body(os.path.basename(f), len(data)); r = call("POST", kind_path, body)["data"]
    for op in r["attributes"]["uploadOperations"]:
        hs = {h["name"]: h["value"] for h in op["requestHeaders"]}
        x = requests.put(op["url"], headers=hs, data=data[op["offset"]:op["offset"] + op["length"]]); x.raise_for_status()
    call("PATCH", patch_path + "/" + r["id"], {"data": {"type": r["type"], "id": r["id"], "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
    print("uploaded", f, r["id"])
vs = call("GET", f"/v1/apps/{APP}/appStoreVersions?filter[platform]=IOS&limit=5")["data"]
v = [x for x in vs if x["attributes"]["appStoreState"] in ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED")][0]["id"]
loc = next(l["id"] for l in call("GET", f"/v1/appStoreVersions/{v}/appStoreVersionLocalizations")["data"] if l["attributes"]["locale"] == "en-US")
sets = call("GET", f"/v1/appStoreVersionLocalizations/{loc}/appPreviewSets")["data"]
st = next((s["id"] for s in sets if s["attributes"]["previewType"] == "IPHONE_67"), None)
if not st:
    st = call("POST", "/v1/appPreviewSets", {"data": {"type": "appPreviewSets", "attributes": {"previewType": "IPHONE_67"}, "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc}}}}})["data"]["id"]
for p in call("GET", f"/v1/appPreviewSets/{st}/appPreviews")["data"]:
    call("DELETE", f"/v1/appPreviews/{p['id']}", ok=(204,))
upload("/v1/appPreviews", lambda n, s: {"data": {"type": "appPreviews", "attributes": {"fileName": n, "fileSize": s, "mimeType": "video/mp4", "previewFrameTimeCode": "00:00:20:00"}, "relationships": {"appPreviewSet": {"data": {"type": "appPreviewSets", "id": st}}}}}, "/v1/appPreviews", "store/preview.mp4")
time.sleep(60)
for p in call("GET", f"/v1/appPreviewSets/{st}/appPreviews")["data"]:
    print("state", p["attributes"].get("assetDeliveryState"))
print("DONE")
