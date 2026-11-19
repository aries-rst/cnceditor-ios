"""App Store Connect: карточка CNC Editor 2D, возрастной рейтинг, данные для проверки, цена (бесплатно) и покупка Premium $14.99."""
import os, time, json, re, jwt, requests
KID=os.environ["ASC_KEY_ID"]; ISS=os.environ["ASC_ISSUER_ID"]; KEY=os.environ["ASC_KEY"]; B="https://api.appstoreconnect.apple.com"
BUNDLE="com.aries-rst.cnceditor.app"; IAP_ID="com.ariesrst.cnceditor.app.premium"; IAP_PRICE="14.99"
PRIV="https://claude.ai/artifact/UDf2ks9Dh8YXW2TC39TuuK"
def H():
    t=jwt.encode({"iss":ISS,"iat":int(time.time()),"exp":int(time.time())+900,"aud":"appstoreconnect-v1"},KEY,algorithm="ES256",headers={"kid":KID}); return {"Authorization":"Bearer "+t,"Content-Type":"application/json"}
def call(m,p,body=None):
    r=requests.request(m,p if p.startswith("http") else B+p,headers=H(),data=json.dumps(body) if body else None)
    if r.status_code>=300: print("ERR",m,p,r.status_code,r.text[:700]); return {}
    return r.json() if r.text else {}
def all_pages(p):
    out=[]; url=B+p
    while url:
        r=requests.get(url,headers=H()); j=r.json(); out+=j.get("data",[]); url=j.get("links",{}).get("next")
    return out

EN=dict(name="CNC Editor 2D: DXF & G-code", sub="Draw, DXF, toolpaths, G-code",
 kw="cnc,dxf,gcode,router,cam,cad,engraving,toolpath,nc,tap,plywood,mdf,svg,vector,cutting,mill",
 promo="Draw a part, calculate toolpaths and save a G-code program for your CNC router right on your iPhone.",
 desc="""Want to draw a part and get a G-code program for your CNC router right on your phone? CNC Editor 2D is a pocket 2D CAD/CAM for furniture makers, sign makers and woodworkers cutting plywood, MDF and plastic.

DRAWING
• Rectangle, circle, ellipse, polygon, star, arc, polyline — by finger or exact numbers
• Node editing, fillets, offset, mirror, block and circular copy
• Weld, subtract, intersect, trim, scissors, vector doctor
• Vector text, text on a curve, single-line engraving font
• Envelope: fit a pattern into an arch or a wave
• Nesting parts on sheets and Multi-Plate signs

PHOTO TO VECTOR
• Take a photo of a drawing or template and use it as an underlay for tracing
• Automatic image vectorization
• Photo perspective correction, stencil bridges

TOOLPATHS & G-CODE
• Profile inside/outside, tabs, ramps, machine vectors, area clearance, V-carving, drilling
• Machining simulation — check the cut before the machine does
• Weihong / NcStudio (.tap), Superstar 4-spindle (.nc) and your own .con post processor
• Fully editable tool database
• Import G-code programs (.tap, .nc, .ngc, .gcode) back into vectors

FILES
• Open and save DXF (works with most CAD/CAM programs), SVG with Inkscape layers
• Export PDF at 1:1, PNG, JPG; share files via Files, AirDrop, mail or messengers

Free: all drawing and toolpath calculation plus one machine program per day. Premium (one-time purchase, forever): unlimited machine programs and no ads.

17 app languages: English, Russian, Uzbek, Kazakh, Turkish, German, Spanish, French, Portuguese, Indonesian, Hindi, Arabic, Persian, Japanese, Korean, Chinese (Simplified and Traditional). Your drawings stay on your device.""")
RU=dict(name="ЧПУ Редактор 2D – DXF и G-код", sub="Чертёж, DXF, траектории, УП",
 kw="чпу,dxf,g-код,фрезер,станок,cam,cad,гравировка,траектория,nc,tap,фанера,мдф,svg,вектор,раскрой",
 promo="Начертите деталь, рассчитайте траектории и сохраните управляющую программу для фрезерного станка прямо на iPhone.",
 desc="""Нужно быстро начертить деталь и получить управляющую программу для фрезерного станка с ЧПУ прямо на телефоне? ЧПУ Редактор 2D — карманный 2D CAD/CAM для мебельщиков, рекламщиков и мастеров по дереву, фанере, пластику и МДФ.

ЧЕРЧЕНИЕ
• Прямоугольник, окружность, эллипс, многоугольник, звезда, дуга, полилиния — пальцем или точными числами
• Редактирование узлов, скругление углов, смещение (offset), зеркало, копирование блоком и по кругу
• Объединение, вычитание, пересечение, обрезка, ножницы, доктор векторов
• Векторный текст, в том числе по кривой, однолинейный шрифт для гравировки
• Огибающая: уложить узор в арку или волну
• Раскрой деталей на листе (Nesting) и таблички Multi-Plate

ИЗ ФОТО В ВЕКТОР
• Сфотографируйте рисунок или шаблон, и он станет подложкой для обводки
• Автоматическая векторизация картинок
• Исправление перспективы фото, мостики для трафаретов

ТРАЕКТОРИИ И УП
• Профиль снаружи и внутри, мостики, рампа, вдоль векторов, выборка, V-гравировка, сверление
• Имитация обработки — проверьте рез до станка
• Weihong / NcStudio (.tap), Superstar 4 шпинделя (.nc) и свой постпроцессор .con
• База фрез с полной настройкой
• Импорт управляющих программ (.tap, .nc, .ngc, .gcode) обратно в векторы

ФАЙЛЫ
• Открытие и сохранение DXF (совместим с большинством CAD/CAM-программ), SVG со слоями Inkscape
• Экспорт PDF 1:1, PNG, JPG; отправка файлов через «Файлы», AirDrop, почту и мессенджеры

Бесплатно: всё черчение и расчёт траекторий плюс одна программа для станка в день. Премиум (разовая покупка навсегда): без ограничений и без рекламы.

17 языков приложения: русский, английский, узбекский, казахский, турецкий, немецкий, испанский, французский, португальский, индонезийский, хинди, арабский, персидский, японский, корейский, китайский (упрощённый и традиционный). Чертежи хранятся на вашем устройстве.""")
for t in (EN,RU): assert len(t["name"])<=30 and len(t["sub"])<=30 and len(t["kw"])<=100 and len(t["promo"])<=170, (t["name"],len(t["kw"]),len(t["promo"]))

NOTES="""CNC Editor 2D is a 2D drawing (CAD) and toolpath (CAM) app for owners of small CNC routers. The user draws or imports a part (DXF/SVG/photo), calculates toolpaths and saves a G-code program (.tap / .nc) for the machine.

HOW TO USE (no account, no login, no demo credentials needed; everything works offline):
1. Launch, pick a language, tap "Create new model", OK.
2. In the left/bottom panel "Assistant" tap the rectangle or circle icon and drag on the sheet (or type numbers) to draw. Tap a vector to select it; pinch to zoom.
3. Panel tab "Toolpaths" > "Profile" > "Calculate", then "Simulation" to see the cut.
4. Menu "Toolpaths" > "Save toolpaths as…" > "Save" writes a .tap/.nc file via the Files picker (or "Share").
5. Paid feature: Help > Premium (non-consumable In-App Purchase "com.ariesrst.cnceditor.app.premium", one-time). Free users can save 1 machine program per day; Premium removes the limit and ads. "Restore" is in the same window. Use a Sandbox Apple ID for testing.

EXTERNAL SERVICES: Apple StoreKit only. Google AdMob SDK is included but ads are DISABLED in this version. No servers, no analytics, no accounts, no user-generated content shared with others; files stay on the device. Camera/photos are used only to load a picture as a drawing underlay.

REGIONAL DIFFERENCES: none (17 interface languages selectable in Help > Language). REGULATED / THIRD-PARTY MATERIAL: none."""

apps=call("GET",f"/v1/apps?filter[bundleId]={BUNDLE}")["data"]; APP=apps[0]["id"]; print("APP",APP)
# ---- app info: категории и названия ----
ai=call("GET",f"/v1/apps/{APP}/appInfos")["data"]
info=([a for a in ai if a["attributes"].get("appStoreState") in ("PREPARE_FOR_SUBMISSION","DEVELOPER_REJECTED","REJECTED","METADATA_REJECTED")] or ai)[0]["id"]
call("PATCH",f"/v1/appInfos/{info}",{"data":{"type":"appInfos","id":info,"relationships":{"primaryCategory":{"data":{"type":"appCategories","id":"UTILITIES"}},"secondaryCategory":{"data":{"type":"appCategories","id":"PRODUCTIVITY"}}}}})
ls={l["attributes"]["locale"]:l["id"] for l in call("GET",f"/v1/appInfos/{info}/appInfoLocalizations")["data"]}
for loc,t in (("en-US",EN),("ru",RU)):
    at={"name":t["name"],"subtitle":t["sub"],"privacyPolicyUrl":PRIV}
    if loc in ls: call("PATCH",f"/v1/appInfoLocalizations/{ls[loc]}",{"data":{"type":"appInfoLocalizations","id":ls[loc],"attributes":at}})
    else: call("POST","/v1/appInfoLocalizations",{"data":{"type":"appInfoLocalizations","attributes":dict(at,locale=loc),"relationships":{"appInfo":{"data":{"type":"appInfos","id":info}}}}})
# ---- версия: описания ----
vs=call("GET",f"/v1/apps/{APP}/appStoreVersions?filter[platform]=IOS&limit=5")["data"]
v=[x for x in vs if x["attributes"]["appStoreState"] in ("PREPARE_FOR_SUBMISSION","DEVELOPER_REJECTED","REJECTED","METADATA_REJECTED")][0]["id"]
call("PATCH",f"/v1/appStoreVersions/{v}",{"data":{"type":"appStoreVersions","id":v,"attributes":{"copyright":"2026 Rustamjon Suvanqulov"}}})
vl={l["attributes"]["locale"]:l["id"] for l in call("GET",f"/v1/appStoreVersions/{v}/appStoreVersionLocalizations")["data"]}
for loc,t in (("en-US",EN),("ru",RU)):
    at={"description":t["desc"],"keywords":t["kw"],"promotionalText":t["promo"],"supportUrl":PRIV,"marketingUrl":PRIV}
    if loc in vl: call("PATCH",f"/v1/appStoreVersionLocalizations/{vl[loc]}",{"data":{"type":"appStoreVersionLocalizations","id":vl[loc],"attributes":at}})
    else: call("POST","/v1/appStoreVersionLocalizations",{"data":{"type":"appStoreVersionLocalizations","attributes":dict(at,locale=loc),"relationships":{"appStoreVersion":{"data":{"type":"appStoreVersions","id":v}}}}})
# ---- возрастной рейтинг: всё «нет» ----
ar=call("GET",f"/v1/appInfos/{info}/ageRatingDeclaration").get("data")
if ar:
    at={k:"NONE" for k in ["alcoholTobaccoOrDrugUseOrReferences","contests","gamblingSimulated","horrorOrFearThemes","matureOrSuggestiveThemes","medicalOrTreatmentInformation","profanityOrCrudeHumor","sexualContentGraphicAndNudity","sexualContentOrNudity","violenceCartoonOrFantasy","violenceRealistic","violenceRealisticProlongedGraphicOrSadistic","gunsOrOtherWeapons"]}
    at.update({"gambling":False,"unrestrictedWebAccess":False,"lootBox":False})
    for _ in range(14):
        r=requests.patch(B+f"/v1/ageRatingDeclarations/{ar['id']}",headers=H(),data=json.dumps({"data":{"type":"ageRatingDeclarations","id":ar["id"],"attributes":at}}))
        if r.status_code<300: print("age ok"); break
        print("age retry",r.status_code,r.text[:300])
        u=re.search(r"Unknown attribute '?(\w+)",r.text) or re.search(r"'(\w+)' is not a valid",r.text)
        m=re.search(r"attribute '(\w+)'",r.text) or re.search(r"/data/attributes/(\w+)",r.text)
        if u and u.group(1) in at: del at[u.group(1)]
        elif m and m.group(1) not in at: at[m.group(1)]=False
        else: break
# ---- данные для проверки ----
rd={"contactFirstName":"Rustamjon","contactLastName":"Suvanqulov","contactPhone":"+998507332414","contactEmail":"games.dev4u@gmail.com","demoAccountRequired":False,"notes":NOTES}
ex=call("GET",f"/v1/appStoreVersions/{v}/appStoreReviewDetail").get("data")
if ex: call("PATCH",f"/v1/appStoreReviewDetails/{ex['id']}",{"data":{"type":"appStoreReviewDetails","id":ex["id"],"attributes":rd}})
else: call("POST","/v1/appStoreReviewDetails",{"data":{"type":"appStoreReviewDetails","attributes":rd,"relationships":{"appStoreVersion":{"data":{"type":"appStoreVersions","id":v}}}}})
# ---- цена приложения: бесплатно ----
cur=call("GET",f"/v1/apps/{APP}/appPriceSchedule").get("data")
if not cur:
    pp=call("GET",f"/v1/apps/{APP}/appPricePoints?filter[territory]=USA&limit=200")["data"]
    free=[p for p in pp if p["attributes"]["customerPrice"] in ("0","0.0","0.00")]
    if free:
        call("POST","/v1/appPriceSchedules",{"data":{"type":"appPriceSchedules","relationships":{"app":{"data":{"type":"apps","id":APP}},"baseTerritory":{"data":{"type":"territories","id":"USA"}},"manualPrices":{"data":[{"type":"appPrices","id":"${p0}"}]}}},
            "included":[{"type":"appPrices","id":"${p0}","attributes":{"startDate":None},"relationships":{"appPricePoint":{"data":{"type":"appPricePoints","id":free[0]["id"]}}}}]})
        print("price: free")
else: print("price schedule exists")
# доступность во всех странах
terr=[t["id"] for t in all_pages("/v1/territories?limit=200")]
av=call("GET",f"/v1/apps/{APP}/appAvailabilityV2").get("data")
if not av:
    call("POST","/v2/appAvailabilities",{"data":{"type":"appAvailabilities","attributes":{"availableInNewTerritories":True},"relationships":{"app":{"data":{"type":"apps","id":APP}},"territoryAvailabilities":{"data":[{"type":"territoryAvailabilities","id":f"${{{t}}}"} for t in terr]}}},
        "included":[{"type":"territoryAvailabilities","id":f"${{{t}}}","attributes":{"available":True},"relationships":{"territory":{"data":{"type":"territories","id":t}}}} for t in terr]})
    print("availability set", len(terr))
# ---- покупка Premium ----
iaps=call("GET",f"/v1/apps/{APP}/inAppPurchasesV2?limit=50").get("data",[])
iap=next((i for i in iaps if i["attributes"]["productId"]==IAP_ID),None)
if not iap:
    iap=call("POST","/v2/inAppPurchases",{"data":{"type":"inAppPurchases","attributes":{"name":"Premium","productId":IAP_ID,"inAppPurchaseType":"NON_CONSUMABLE","familySharable":False,
        "reviewNote":"Help > Premium. Removes the daily limit of 1 saved machine program (.tap/.nc) and removes ads. One-time purchase. Restore button in the same window."},"relationships":{"app":{"data":{"type":"apps","id":APP}}}}}).get("data")
IID=iap["id"]; print("IAP",IID,iap["attributes"].get("state"))
il={l["attributes"]["locale"]:l["id"] for l in call("GET",f"/v2/inAppPurchases/{IID}/inAppPurchaseLocalizations").get("data",[])}
for loc,nm,ds in (("en-US","Premium","No limit on machine programs, no ads"),("ru","Премиум","Без лимита на программы и без рекламы")):
    at={"name":nm,"description":ds}
    if loc in il: call("PATCH",f"/v1/inAppPurchaseLocalizations/{il[loc]}",{"data":{"type":"inAppPurchaseLocalizations","id":il[loc],"attributes":at}})
    else: call("POST","/v1/inAppPurchaseLocalizations",{"data":{"type":"inAppPurchaseLocalizations","attributes":dict(at,locale=loc),"relationships":{"inAppPurchaseV2":{"data":{"type":"inAppPurchases","id":IID}}}}})
ps=call("GET",f"/v2/inAppPurchases/{IID}/iapPriceSchedule").get("data")
if not ps:
    pts=all_pages(f"/v2/inAppPurchases/{IID}/pricePoints?filter[territory]=USA&limit=200")
    pt=[p for p in pts if p["attributes"]["customerPrice"]==IAP_PRICE]
    print("price points found",len(pts),"match",len(pt))
    if pt:
        call("POST","/v1/inAppPurchasePriceSchedules",{"data":{"type":"inAppPurchasePriceSchedules","relationships":{"inAppPurchase":{"data":{"type":"inAppPurchases","id":IID}},"baseTerritory":{"data":{"type":"territories","id":"USA"}},"manualPrices":{"data":[{"type":"inAppPurchasePrices","id":"${p0}"}]}}},
            "included":[{"type":"inAppPurchasePrices","id":"${p0}","attributes":{"startDate":None},"relationships":{"inAppPurchasePricePoint":{"data":{"type":"inAppPurchasePricePoints","id":pt[0]["id"]}}}}]})
        print("IAP price",IAP_PRICE)
else: print("IAP price schedule exists")
iav=call("GET",f"/v2/inAppPurchases/{IID}/inAppPurchaseAvailability").get("data")
if not iav:
    call("POST","/v1/inAppPurchaseAvailabilities",{"data":{"type":"inAppPurchaseAvailabilities","attributes":{"availableInNewTerritories":True},"relationships":{"inAppPurchase":{"data":{"type":"inAppPurchases","id":IID}},"availableTerritories":{"data":[{"type":"territories","id":t} for t in terr]}}}})
    print("IAP availability set")
# ---- сборка ----
bs=call("GET",f"/v1/builds?filter[app]={APP}&sort=-uploadedDate&limit=5")["data"]
print("builds",[(b["attributes"]["version"],b["attributes"]["processingState"]) for b in bs])
print("DONE")
