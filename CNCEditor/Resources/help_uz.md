# ChPU Muharrir 2D — qo‘llanma

ChPU frezer stanogi uchun 2D ishlarni tayyorlash dasturi: vektorlarni chizasiz yoki ochasiz, freza traektoriyalarini hisoblaysiz va stanok uchun boshqaruv dasturini (BD) saqlaysiz.
- **Weihong / NcStudio**: **.tap** fayl, bitta shpindel.
- **Superstar (4 shpindel)**: **.nc** fayl. Asbob raqami — shpindel raqami.

## 1. Ishni boshlash

### Boshlang‘ich ekran
- **Yangi model yaratish**: list o‘lchamini bering.
- **Modelni ochish**: DXF, SVG yoki .cnc2d loyiha.
- **Rasm / fotodan model**: kamera surati yoki galereyadagi rasm taglik bo‘ladi.
- **Modelga qaytish**: model ochiq bo‘lsa ko‘rinadi.
- Yuqorida — **til** tanlash (🌐, 17 til). Pastda — **Qo‘llanma**, **Premium**, **Chiqish** hamda ARESTI Labs’ning boshqa ilovalari va saytiga havolalar.

### Yangi model o‘lchami
- **Kenglik (X)** va **Balandlik (Y)**: zagotovka o‘lchami. 1830×2750, 2070×2800, 1220×2440, 2050×3050 tugmalari standart listlarni qo‘yadi.
- **Model noli**: sxemada burchak yoki markazga teging. Bu stanokning X0 Y0 nuqtasi. Odatda chap past burchak.
- **Birliklar**: mm yoki dyuym. Dastur ichida hammasi millimetrda saqlanadi.
- **Material qalinligi**: traektoriya chuqurliklari uchun kerak.

## 2. Muharrir ekrani

- **Menyu qatori** (yuqorida): 🏠 — boshlang‘ich ekranga, keyin Fayl, Tahrir, Model, Vektorlar, Traektoriyalar, Yordam menyulari. ▸ belgili band ichki menyuni ochadi, «← Orqaga» qaytaradi.
- **Ko‘rinish paneli** (menyu ostida):
  - ☰ — chap panelni ko‘rsatish yoki yashirish;
  - butun model, yaqinlashtirish, uzoqlashtirish, to‘r;
  - bekor qilish, qaytarish;
  - **Tanlash**, **Tugunlar**, **Tanlovga qo‘shish**;
  - ⟳ ekranni burish: albom → kitob → avto-burilish;
  - **Tanlash ▾** menyusi, ⋮ amallar menyusi;
  - «Tanlangan: N» hisoblagichi.
- Uch bo‘limli **panel** (kitob holatida — pastda, albom holatida — chapda):
  - **Loyiha**: ma’lumot, qatlamlar, tanlash bo‘yicha maslahatlar, taglik;
  - **Yordamchi**: chizish va tahrirlashning barcha asboblari. Asbob ochilganda shu yerda uning maydonlari ko‘rinadi;
  - **Traektoriyalar**: traektoriyalar ro‘yxati, material, frezalar bazasi, hisoblash va BD ni saqlash.
- **List**: oq to‘rtburchak — zagotovka. Qizil va yashil chiziqchalar — noldan X va Y o‘qlari.
- Listning pastidagi **maslahat** hozir nima qilishni aytadi. Nuqta kerak bo‘lsa, «Bekor» tugmasi bor.

Istalgan belgini uzoq bossangiz, nomi ko‘rinadi. ◢ burchakli belgi — guruh: tegilganda guruh asboblari ro‘yxati ochiladi. Oxirgi tanlangan asbob tugmada qoladi.

## 3. Listdagi imo-ishoralar

- **Bir barmoq bilan vektorga**: uni tanlash.
- **Tanlangan vektorni tortish**: ko‘chirish.
- **Ramka burchaklaridagi kvadrat dastaklar**: nisbatni saqlab masshtablash.
- **Ramka ustidagi dumaloq dastak**: 1° qadam bilan burish.
- **Bo‘sh joyda tortish**: tanlash ramkasi.
  - **Chapdan o‘ngga** (ko‘k, to‘liq chiziq): ramka ichiga to‘liq tushgan vektorlar tanlanadi.
  - **O‘ngdan chapga** (yashil, punktir): ramka tekkan barcha vektorlar tanlanadi.
- **Bo‘sh joyga tegish**: tanlovni bekor qilish.
- **Ikki barmoq**: siljitish va masshtab (chimdish).
- **Vektorni uzoq bosish**: bir nechtasini tanlash yoqiladi.
  - Har bir keyingi tegish vektorni qo‘shadi yoki tanlovdan olib tashlaydi.
  - Pushti doirachalardagi raqamlar tanlash tartibini ko‘rsatadi. Tartib muhim: tekislashda oxirgi tanlangan asos hisoblanadi, ayirishda oxirgisi ayiriladi.
- **Vektorlar tanlangan holda uzoq bosish** (bo‘sh joyda) amallar menyusini ochadi.

Tanlangan vektorlar yorug‘ hoshiyali qalin pushti chiziq bilan chiziladi, yopiqlari esa yengil bo‘yaladi.

## 4. Bir nechta vektorni tanlash (Shift tugmasi o‘rniga)

- Ko‘rinish panelidagi **Tanlovga qo‘shish** tugmasi: yoqilgan paytda har bir tegish vektorni qo‘shadi yoki olib tashlaydi. Ramka ham tanlanganlarga qo‘shadi.
- **Vektorni uzoq bosish** shu rejimni vaqtincha yoqadi. «Tanlovga qo‘shish» yoki «Tanlovni bekor qilish» bilan o‘chiriladi.
- **Tanlash ▾** menyusi:
  - hammasi;
  - joriy qatlamdagi barchasi;
  - faqat yopiq, faqat ochiq;
  - o‘lchami o‘xshash (birinchi tanlangan namunaga);
  - tanlovni teskari qilish;
  - tanlovni bekor qilish;
  - tanlanganlar ro‘yxati.
- **Tanlanganlar ro‘yxati** (yoki «Tanlangan: N» yozuviga tegish): vektorlar tartib bilan va o‘lchamlari bilan. ✕ belgisi vektorni tanlovdan chiqaradi.

## 5. Shakllarni chizish

**Yordamchi** bo‘limi → «Vektor asboblari». Har bir shaklni ikki usulda chizish mumkin:
- **Barmoq bilan**: listda torting. Paneldagi maydonlar o‘lchamlarni darhol ko‘rsatadi.
- **Raqamlar bilan**: markaz, kenglik, balandlik, radiuslar va h.k. ni kiritib, «Yaratish / Tayyor» ni bosing.

Shakl endigina chizilgan paytda istalgan maydonni o‘zgartirish uni listda darhol o‘zgartiradi. «Tayyor» shaklni mahkamlaydi. «Markazni tegib ko‘rsatish» markazni tegib belgilash imkonini beradi.

- **To‘rtburchak**: kenglik, balandlik, burchak radiusi; burchaklar yumaloq yoki teskari (botiq).
- **Aylana**: markaz va radius yoki diametr.
- **Ellips**: markaz, kenglik, balandlik, burilish burchagi.
- **Ko‘pburchak**: tomonlar soni, radius, burilish.
- **Yulduz**: nurlar soni, tashqi va ichki radiuslar.
- **Yoy**, uch usulda: uch nuqta bo‘yicha; markaz, boshi va oxiri; boshi, oxiri va radius.
- **Polichiziq**: listga teging — har bir tegish nuqta qo‘shadi. Keyingi nuqtani raqam bilan kiritish mumkin. «Yopish» birinchi nuqta bilan ulaydi.

**Tayyor shaklni o‘zgartirish** uchun: uni tanlang va ⋮ → «Shakl / matnni tahrirlash…» ni bosing.

## 6. Tugunlar

**Tugunlar** tugmasi: vektorni tanlang va uning nuqtalarini torting.
- Ko‘k kvadratlar — nuqtalar, yashil — boshlang‘ich nuqta, doirachalar — Bezye egri chiziqlarining boshqaruv nuqtalari.
- **Nuqtani uzoq bosish**: nuqtani o‘chirish, silliqlash, boshlang‘ich qilish, koordinatalarni kiritish.
- **Bo‘lakni uzoq bosish**:
  - chiziq, yoy yoki Bezye egri chizig‘iga aylantirish;
  - nuqta qo‘shish;
  - boshlang‘ich nuqta qo‘shish;
  - bo‘lakni o‘chirish (vektorni kesish).

## 7. Vektorlarni tahrirlash

Barcha buyruqlar **Vektorlar** menyusida va Yordamchidagi «Joylash, birlashtirish, kesish» bo‘limida.
- **Transformatsiya**: aniq ko‘chirish, o‘lcham (nisbatni saqlab), burish, qiyshaytirish, nusxa bilan yoki nusxasiz.
- **Ko‘zgu aks**: gorizontal yoki vertikal, o‘z markazi yoki listga nisbatan.
- **Siljitish (offset)**: berilgan masofaga tashqariga yoki ichkariga; burchaklar o‘tkir yoki yumaloq.
- **Blok nusxalash**: oraliq yoki qadam bilan qator va ustunlar. **Aylana bo‘yicha**: markaz atrofida N ta nusxa.
- **Tekislash**: oxirgi tanlanganga nisbatan chetlar va markazlar bo‘yicha; «List markazida» — zagotovkaga nisbatan.
- **Guruhlash / Guruhdan chiqarish**: guruh butunligicha tanlanadi va ko‘chiriladi.
- **Yopiq vektorlarni birlashtirish**:
  - Weld (qo‘shish);
  - Kesishma;
  - Ayirish (oxirgi tanlangan qolganlaridan ayiriladi);
  - Umumiy qismni chiqarish.
- **Yopish**: chiziq, egri chiziq bilan yoki uchini surib. **Ikki ochiq vektorni ulash**: chiziq, egri chiziq bilan yoki uchlarini surib. **Ustma-ust nuqtalar**: ko‘p bo‘laklarni aniqlik bilan zanjirga yopishtirish.
- **Vektor doktori**: ustma-ust nuqtalar, o‘z-o‘zini kesish va halqalarni topib tuzatadi.
- **Egri chiziqlar o‘rniga yoylar**: Bezye egri chiziqlarini yoy va chiziqlar bilan almashtiradi (BD da qatorlar kamroq, kesim tekisroq).
- **Yumaloqlash**: burchakka teging, radiusni bering. Shu yerda ikki vektorni kesishmagacha uzaytirish ham bor.
- **Qaychi (kesish)**: bo‘lakka tegish uning kesishmalar orasidagi qismini o‘chiradi.
- **Kontur bo‘yicha kesish (Clipping)**: tanlangan kontur ichidagi yoki tashqarisidagi vektorlarni qoldirish.
- **Kesib bo‘lish**: vektorlarni X yoki Y bo‘yicha chiziq bilan kesish.
- **Atrofida ramka**: tanlangan atrofida chekinish bilan to‘rtburchak.
- **Aylantirish**: vektorlar orasidan aylana yoki to‘rtburchaklarni topib, ularni «shakl» qilish.
- **Yo‘nalishni teskari qilish**: ishlov tartibi va tomoni uchun muhim.
- **Qulflash**: vektorni tasodifan siljitib bo‘lmaydi.
- **Xususiyatlar**: o‘lcham, uzunlik, maydon, nuqtalar, chiziqlar, yoylar va egri chiziqlar soni.

## 8. Matn

**Vektor matn**:
- shrift: Arial-, Times-, Courierga o‘xshash, DejaVu yoki bir chiziqli (bir chiziq bilan gravyura uchun);
- balandlik, qalin, kursiv;
- tekislash, harflar va qatorlar oralig‘i, kerning;
- cho‘zish, qiyalik, burish;
- X/Y joylashuvi.

«Yaratish» matnni listga qo‘shadi. Keyinroq uni tanlab, ⋮ → «Shakl / matnni tahrirlash» orqali o‘zgartirish mumkin.

**Egri chiziq bo‘ylab matn**: egri chiziq yoki aylanani tanlang, «Egri chiziq bo‘ylab matn» ni oching, egri chiziqdagi boshlanishni, undan chekinishni va tomonni bering. Harflar egri chiziq yo‘nalishi bo‘yicha buriladi.

## 9. Qobiq va «Egri chiziq bo‘ylab qo‘yish»

- **Qobiq**: rasm yoki naqshni tanlang, «Qobiq» ni oching. Atrofida tugunli ramka paydo bo‘ladi. Burchaklar va tomonlar o‘rtasini torting. Yoki «Yuqori egri chiziq…» / «Pastki egri chiziq…» ni bosib, tayyor egri chiziqqa (masalan, yoyga) teging — ramka uning shaklini oladi. «Qo‘llash» rasmni buzadi. Shu tarzda naqshni ravoq, to‘lqin va h.k. ga joylash mumkin.
- **Egri chiziq bo‘ylab qo‘yish**: tanlangan rasm nusxalari egri chiziq bo‘ylab teng joylanadi — berilgan son bilan yoki qadam bilan, egri chiziq bo‘ylab burilgan yoki burilmagan holda.

## 10. Lavhalar va joylash

- **Multi-Plate**: lavha shabloni (kontur + matn) listda ko‘paytiriladi, matn fayldagi satrlar bilan almashtiriladi. Masalan, xonadon raqamlari yoki ismlar: bitta satr — bitta lavha.
- **Joylash (Nesting)**: tanlangan detallar berilgan o‘lchamdagi listlarga oraliq va chetdan chekinish bilan joylanadi. Burishga ruxsat berish mumkin. Teshiklar avtomatik o‘z detali bilan qoladi.

## 11. Rasmlar va fotolar

- **Fayl → Rasm / foto import** menyusi yoki «Rasm» belgisi. Manba — **galereya** yoki **kamera**. Rasm yarim shaffof **taglik** bo‘ladi.
- **Taglik sozlamalari**: shaffoflik, ko‘rsatish, qulflash. O‘lcham raqam bilan yoki **ikki nuqta bo‘yicha** beriladi: o‘lchami ma’lum ikki nuqtaga teging va haqiqiy masofani kiriting.
- **Qo‘lda chizib olish**: taglik ustidan polichiziq va shakllar bilan chizing.
- **Vektorlash** («Vektorlash» belgisi):
  1. Rejimni tanlang: oq-qora (chegara bo‘yicha siluet) yoki konturlar.
  2. Yorqinlik chegarasini (yoki «avto»), silliqlash, mayda axlatni olib tashlash, teskari qilishni bering.
  3. «Ko‘rib chiqish» bo‘lajak vektorlarni rasm ustida ko‘rsatadi.
  4. «Vektorlar yaratish» ularni modelga qo‘shadi.
- **Perspektivani tuzatish**: list qiya burchakdan suratga olingan bo‘lsa, fotoda to‘rt burchakka teging va haqiqiy o‘lchamni kiriting. Foto to‘g‘ri va 1:1 masshtabda bo‘ladi.
- **Trafaret ko‘prikchalari**: harf va detallarning ichki qismlari tushib ketmasligi uchun bog‘lovchilar.

## 12. Traektoriyalar (ishlov)

Ish tartibi:
1. **Material** (Traektoriyalar bo‘limi → material belgisi): qalinlik, xavfsiz Z balandligi, «uy» nuqtasi (oxirida stanok boradigan joy).
2. **Asboblar bazasi**: raqam, diametr, burchak (V-kesgichlar uchun), pastga va yon qadam, aylanish, surish va kirish tezligi bilan frezalar. Surish mm/s yoki mm/daq da. Frezalarni qo‘shish, nusxalash, o‘zgartirish va o‘chirish mumkin; baza telefonda saqlanadi.
3. Listda **vektorlarni tanlang** va kerakli ishlov turini bosing.

### Ishlov turlari
- **Profil**: kontur tashqarisidan yoki ichidan (freza radiusini hisobga olib) yoki chiziq bo‘ylab kesish. Sozlamalar:
  - boshlang‘ich va oxirgi chuqurlik;
  - qo‘yim;
  - yo‘nalish (yo‘ldosh yoki qarama-qarshi);
  - aylanib o‘tish tartibi.
- **Ko‘prikchalar (ushlagichlar)**: kesish paytida detallar uzilib ketmaydi. Avtomatik (soni yoki qadami bilan) yoki konturga tegib qo‘lda qo‘yiladi. Uzunligi va balandligi beriladi.
- **Silliq kirish (rampa)**: freza materialga tik emas, qiya kiradi — yuklama va iz kamroq.
- **Vektorlar bo‘ylab**: freza aynan chiziq bo‘ylab yuradi. Gravyura, ariqchalar, bir chiziqli matn uchun.
- **Maydonni tozalash**: kontur ichidagi cho‘ntak. Siljitish (kontur bo‘ylab) yoki rastr (zigzag) o‘tishlari, berilgan ustma-ustlik bilan.
- **V-o‘yma**: V-kesgich; chuqurlik chiziq kengligiga qarab o‘zgaradi, «o‘yilgan» harflar va naqshlar hosil bo‘ladi.
- **Burg‘ulash**: aylana markazlarida teshiklar, qirindini sindirish bilan (burg‘ulash qadami).

Bazadan freza olish uchun «Asbob» bo‘limida **Tanlash…** ni bosing. **Hisoblash** tugmasi traektoriyani quradi. Uning ostida kesim uzunligi, kirishlar soni va taxminiy vaqt ko‘rinadi.

Traektoriyalar ro‘yxati:
- tegish traektoriyani va uning vektorlarini tanlaydi;
- belgi — ko‘rsatish yoki yo‘q;
- «O‘zgartirish…» — parametrlarni ochish;
- «Qayta hisoblash» — vektorlar o‘zgargandan keyin;
- «O‘chirish».

### Imitatsiya
«Imitatsiya» belgisi: freza materialdan qanday o‘tishini yuqoridan ko‘rish. Boshlash/pauza, tezlik, «Natija» (hammasini birdan), «Boshidan». Ko‘prikchalar, ichki burchaklar va o‘tkazib yuborilgan joylarni tekshirish uchun qulay.

### BD ni saqlash
**Traektoriyalar → Traektoriyalarni boshqacha saqlash…**:
1. Kerakli traektoriyalarni belgilang.
2. Postprotsessorni tanlang:
   - **Weihong (.tap)**: NcStudio uchun;
   - **Superstar (.nc)**: 4 shpindel; freza raqami 1–4 = shpindel raqami;
   - **o‘z .con faylingiz**: «O‘z .con faylingizni yuklash…» — stanokning postprotsessor fayli (ArtCAM formati). U eslab qolinadi.
3. Fayl nomini bering. «Ko‘rib chiqish» dastur boshini ko‘rsatadi. «Saqlash» — papkani tanlang (masalan, fleshka yoki stanokka uzatish papkasi).

**Bepul** kuniga 1 ta stanok dasturini saqlash mumkin. **Premium** (bir martalik, umrbod xarid) cheklovni va reklamani olib tashlaydi.

**Maslahat:** birinchi kesishdan oldin stanokda nol va Z ni tekshiring. Avval dasturni «havoda» (Z ko‘tarilgan holda) yurgizib ko‘ring.

## 13. Saqlash va eksport

- **Saqlash (DXF)**: oddiy DXF R12 istalgan CAD/CAM dasturida ochiladi. Uning ichida butun loyiha sezdirmay saqlanadi: qatlamlar, traektoriyalar, frezalar, taglik. Bunday DXF shu dasturda ochilsa, hammasi tiklanadi.
- **Boshqacha saqlash**:
  - DXF;
  - SVG (qatlamlar Inkscape da qatlam bo‘lib ochiladi);
  - .cnc2d loyiha.
- **Eksport**:
  - 1:1 masshtabda PDF (shablonni chop etish uchun);
  - tanlangan ruxsatda PNG yoki JPG; PNG shaffof fon bilan ham bo‘lishi mumkin.
- **Vektor import**: boshqa DXF yoki SVG dan vektorlarni joriy modelga qo‘shish.
- Eski Windows-1251 kodlashdagi DXF (ArtCAM/AutoCAD dan kirill yozuvlari) to‘g‘ri ochiladi.

## 14. Qatlamlar

**Loyiha** bo‘limi → Qatlamlar yoki **Tahrir → Qatlamlar…**:
- qatlam qo‘shish;
- nomini o‘zgartirish ✎;
- rang;
- ko‘rsatish yoki yashirish 👁;
- qulflash 🔒;
- o‘chirish ✕.

Yangi vektorlar **faol** (ajratilgan) qatlamga tushadi. «Ko‘chirish» tanlangan vektorlarni faol qatlamga o‘tkazadi.

## 15. Bekor qilish va «Orqaga» tugmasi

- **Bekor qilish / Qaytarish**: 80 qadamgacha.
- Tizimning **«Orqaga»** tugmasi tartib bilan:
  1. nuqta ko‘rsatishni bekor qiladi;
  2. ochiq asbobni yopadi;
  3. oynani yopadi;
  4. boshlang‘ich ekranga qaytaradi (model saqlanmagan bo‘lsa, so‘raydi).

## 16. G-kodni import qilish (.tap, .nc)

Ilova tayyor stanok dasturini (.tap, .nc, .ngc, .gcode va b.) ochadi va undan chizmani tiklaydi.
- Faylni oching: boshlang‘ich ekranda **Modelni ochish** (yangi model) yoki **Fayl → Vektor import…** (joriy modelga qo‘shish).
- **Freza kompensatsiyasi**: dasturda freza markazining yo‘li yozilgan.
  - «Yo‘q» — vektorlar freza markazi bo‘yicha (gravyura va vektor bo‘ylab ishlov uchun);
  - «Avto» — detallar ichkariga, teshiklar tashqariga freza radiusiga suriladi;
  - «Hammasi ichkariga» / «Hammasi tashqariga». Freza diametrini kiriting.
- **Chuqurlik o‘tishlarini birlashtirish** — turli chuqurlikdagi o‘tishlar bitta konturga aylanadi.
- **Har bir asbob — alohida qatlam** — dasturda bir nechta freza bo‘lsa, T1, T2… qatlamlari.
- So‘ng chizmani saqlang: **Fayl → Saqlash (DXF)**, tahrirlang yoki yangi traektoriyalarni hisoblang.

## 17. Ko‘p beriladigan savollar

- **Traektoriya hisoblanmayapti:**
  - tashqi/ichki profil va tozalash uchun **yopiq** vektorlar kerak. «Vektor doktori» yoki «Ustma-ust nuqtalarni ulash» dan foydalaning;
  - freza cho‘ntakdan kengroq bo‘lishi mumkin.
- **Detal noto‘g‘ri tomondan kesilyapti:** tashqi/ichki va vektor yo‘nalishini tekshiring («Yo‘nalishni teskari qilish»).
- **Trafaret kesishda harflar tushib ketyapti:** «Trafaret ko‘prikchalari» yoki profildagi ko‘prikchalardan foydalaning.
- **Stanok «siljib ketyapti»:** model nolini (Model → Nol holati) va Materialdagi «uy» nuqtasini tekshiring.
- **Mayda vektorlarni tanlash qiyin:** ikki barmoq bilan yaqinlashtiring yoki o‘ngdan chapga ramkadan foydalaning.
