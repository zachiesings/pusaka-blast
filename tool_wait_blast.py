#!/usr/bin/env python3
"""Wait for Blast iOS GH Actions run, then for the ASC build, then assign it to
the QC Internal group (allBuilds=False) so jo.js217 sees it."""
import time, json, urllib.request, urllib.error, jwt, re
KEY_ID="DK5TAZT3F9"; KP="/mnt/c/Users/Desktop/Downloads/AuthKey_DK5TAZT3F9.p8"
ISS="cdaa6ed4-07f4-4151-ac76-eb1e66b6effb"; B="https://api.appstoreconnect.apple.com/v1"
APP="6782779454"
key=open(KP).read()
TOKEN=re.search(r'(ghp_[A-Za-z0-9]+|github_pat_[A-Za-z0-9_]+)',open("/home/desktop/.git-credentials").read()).group(1)
def gh():
    r=urllib.request.Request("https://api.github.com/repos/zachiesings/pusaka-blast/actions/workflows/ios.yml/runs?per_page=1",headers={"Authorization":f"Bearer {TOKEN}"})
    return json.load(urllib.request.urlopen(r,timeout=30))["workflow_runs"][0]
def tok():
    n=int(time.time()); return jwt.encode({"iss":ISS,"iat":n-30,"exp":n+1000,"aud":"appstoreconnect-v1"},key,algorithm="ES256",headers={"kid":KEY_ID,"typ":"JWT"})
def req(method,p,body=None):
    data=json.dumps(body).encode() if body else None
    r=urllib.request.Request(B+p,data=data,method=method,headers={"Authorization":f"Bearer {tok()}","Content-Type":"application/json"})
    try:
        with urllib.request.urlopen(r,timeout=30) as resp:
            t=resp.read().decode(); return resp.status,(json.loads(t) if t else {})
    except urllib.error.HTTPError as e: return e.code,e.read().decode()[:200]
start=time.time()
while time.time()-start<20*60:
    r=gh()
    if r["status"]=="completed":
        print(f"RUN_DONE conclusion={r['conclusion']} {r['html_url']}",flush=True)
        if r["conclusion"]!="success": print("BUILD_FAILED",flush=True); raise SystemExit(0)
        break
    time.sleep(20)
# wait for new ASC build today PDT then assign
while time.time()-start<30*60:
    _,bl=req("GET",f"/builds?filter[app]={APP}&sort=-uploadedDate&limit=3")
    for b in bl["data"]:
        up=b["attributes"].get("uploadedDate","") or ""
        if up.startswith("2026-06-23"):
            bid=b["id"]; ver=b["attributes"].get("version")
            # set compliance
            req("PATCH",f"/builds/{bid}",{"data":{"type":"builds","id":bid,"attributes":{"usesNonExemptEncryption":False}}})
            _,gs=req("GET",f"/apps/{APP}/betaGroups?limit=20")
            qc=[x for x in gs["data"] if x["attributes"]["isInternalGroup"]][0]["id"]
            st,_=req("POST",f"/betaGroups/{qc}/relationships/builds",{"data":[{"type":"builds","id":bid}]})
            print(f"ASC_BUILD_FOUND {ver} assigned_to_QC={st} up={up} id={bid}",flush=True)
            raise SystemExit(0)
    time.sleep(45)
print("ASC_TIMEOUT (run ok but build not visible yet)",flush=True)
