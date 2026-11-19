"""TestFlight: внутренняя группа Test-iOS (все сборки) с теми же тестировщиками, что у «Строителя»."""
import os, time, json, jwt, requests
KID=os.environ["ASC_KEY_ID"]; ISS=os.environ["ASC_ISSUER_ID"]; KEY=os.environ["ASC_KEY"]; B="https://api.appstoreconnect.apple.com"
APP="6836888868"; DONOR="6834818658"
def H():
    t=jwt.encode({"iss":ISS,"iat":int(time.time()),"exp":int(time.time())+900,"aud":"appstoreconnect-v1"},KEY,algorithm="ES256",headers={"kid":KID}); return {"Authorization":"Bearer "+t,"Content-Type":"application/json"}
def call(m,p,body=None):
    r=requests.request(m,B+p,headers=H(),data=json.dumps(body) if body else None)
    if r.status_code>=300: print("ERR",m,p,r.status_code,r.text[:500]); return {}
    return r.json() if r.text else {}
gs=call("GET",f"/v1/apps/{APP}/betaGroups").get("data",[])
g=next((x for x in gs if x["attributes"]["isInternalGroup"]),None)
if not g:
    g=call("POST","/v1/betaGroups",{"data":{"type":"betaGroups","attributes":{"name":"Test-iOS","isInternalGroup":True,"hasAccessToAllBuilds":True},"relationships":{"app":{"data":{"type":"apps","id":APP}}}}}).get("data")
print("group",g and g["id"])
testers=[]
for dg in call("GET",f"/v1/apps/{DONOR}/betaGroups").get("data",[]):
    testers+= [t["id"] for t in call("GET",f"/v1/betaGroups/{dg['id']}/betaTesters").get("data",[])]
testers=list(dict.fromkeys(testers)); print("testers",len(testers))
if g and testers: call("POST",f"/v1/betaGroups/{g['id']}/relationships/betaTesters",{"data":[{"type":"betaTesters","id":t} for t in testers]})
bs=call("GET",f"/v1/builds?filter[app]={APP}&sort=-uploadedDate&limit=5")["data"]
print("builds",[(b["attributes"]["version"],b["attributes"]["processingState"]) for b in bs])
print("DONE")
