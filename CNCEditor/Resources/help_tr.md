# CNC Editor 2D — Kılavuz

CNC freze makinesi için 2D işler hazırlama uygulaması: vektörleri çizin veya açın, takım yollarını hesaplayın ve makineniz için NC programını kaydedin.
- **Weihong / NcStudio**: **.tap** dosyası, tek iş mili.
- **Superstar (4 iş mili)**: **.nc** dosyası. Takım numarası iş mili numarasıdır.

## 1. Başlarken

### Başlangıç ekranı
- **Yeni model oluştur**: levha boyutunu girin.
- **Model aç**: DXF, SVG veya .cnc2d projesi.
- **Resimden / fotoğraftan model**: kamera veya galeri görüntüsü altlık olur.
- **Modele dön**: bir model açıkken görünür.
- En üstte **dil** seçimi (🌐, 17 dil). Altında **Kılavuz**, **Premium** ve diğer ARESTI Labs uygulamalarına ve web sitesine bağlantılar.

### Yeni model boyutu
- **Genişlik (X)** ve **Yükseklik (Y)**: ham parça boyutu. 1830×2750, 2070×2800, 1220×2440, 2050×3050 düğmeleri standart levhaları girer.
- **Model sıfırı**: şemada bir köşeye veya merkeze dokunun. Bu, makinenin X0 Y0 noktasıdır; genellikle sol alt köşe.
- **Birimler**: mm veya inç. İçeride her şey milimetre olarak saklanır.
- **Malzeme kalınlığı**: takım yolu derinlikleri için kullanılır.

## 2. Editör ekranı

- **Menü çubuğu** (üstte): 🏠 — başlangıç ekranına dönüş; ardından Dosya, Düzen, Model, Vektörler, Takım yolları, Yardım. ▸ işaretli öğe alt menü açar, «← Geri» geri döner.
- **Görünüm çubuğu** (menünün altında):
  - ☰ — paneli göster / gizle;
  - tüm model, yakınlaştır, uzaklaştır, ızgara;
  - geri al, yinele;
  - **Seçim**, **Düğümler**, **Seçime ekle**;
  - ⟳ ekranı döndür: yatay → dikey → otomatik;
  - **Seç ▾** menüsü, ⋮ işlemler menüsü;
  - «Seçili: N» sayacı.
- Üç sekmeli **panel** (dikeyde altta, yatayda solda):
  - **Proje**: bilgi, katmanlar, seçim ipuçları, altlık;
  - **Asistan**: tüm çizim ve düzenleme araçları; açık bir araç alanlarını burada gösterir;
  - **Takım yolları**: liste, malzeme, takım veritabanı, hesaplama ve NC kaydetme.
- **Levha**: beyaz dikdörtgen ham parçadır. Kırmızı ve yeşil çizgiler sıfırdaki X ve Y eksenleridir.
- Alttaki **ipucu** şimdi ne yapılacağını söyler. Nokta beklenirken «İptal» düğmesi vardır.

Bir simgeye uzun basmak adını gösterir. ◢ köşeli simge bir gruptur: dokunmak araç listesini açar. Son seçilen araç düğmede kalır.

## 3. Levhadaki hareketler

- **Vektöre tek parmak**: seçer.
- **Seçili vektörü sürükleme**: taşır.
- **Köşelerdeki kare tutamaçlar**: orantılı ölçekleme.
- **Çerçevenin üstündeki yuvarlak tutamaç**: 1° adımlarla döndürme.
- **Boş alanda sürükleme**: seçim çerçevesi.
  - **Soldan sağa** (mavi, düz): tamamen içerideki vektörler seçilir.
  - **Sağdan sola** (yeşil, kesikli): çerçevenin değdiği tüm vektörler seçilir.
- **Boş alana dokunma**: seçimi kaldırır.
- **İki parmak**: kaydırma ve yakınlaştırma.
- **Vektöre uzun basma**: çoklu seçimi açar.
  - Sonraki her dokunuş vektörü ekler veya çıkarır.
  - Pembe dairelerdeki sayılar sırayı gösterir. Sıra önemlidir: hizalamada son seçilen taban, çıkarmada son seçilen çıkarılandır.
- **Vektörler seçiliyken uzun basma** (boş alanda) işlemler menüsünü açar.

Seçili vektörler kalın, parlak kenarlı pembe çizgiyle, kapalı olanlar ayrıca hafif dolguyla çizilir.

## 4. Birden fazla vektör seçmek (Shift yerine)

- **Seçime ekle** düğmesi: açıkken her dokunuş vektör ekler veya çıkarır; çerçeve de mevcut seçime ekler.
- **Vektöre uzun basma** aynı modu geçici açar. «Seçime ekle» veya «Seçimi kaldır» ile kapatılır.
- **Seç ▾** menüsü: tümü; geçerli katmandakiler; yalnız kapalılar, yalnız açıklar; benzer boyut (ilk seçilen örnek gibi); seçimi tersine çevir; seçimi kaldır; seçilenler listesi.
- **Seçilenler listesi** (veya «Seçili: N»ye dokunun): sıralı vektörler ve boyutları. ✕ vektörü seçimden çıkarır.

## 5. Şekil çizmek

**Asistan** sekmesi → «Vektör araçları». Her şekil iki yolla çizilir:
- **Parmakla**: levhada sürükleyin; alanlar boyutları hemen gösterir.
- **Sayıyla**: merkez, genişlik, yükseklik, yarıçap vb. girip «Oluştur / Tamam»a basın.

Şekil yeni çizilmişken herhangi bir alanı değiştirmek onu anında değiştirir. «Tamam» şekli sabitler. «Dokunarak merkez» merkezi dokunuşla belirler.

- **Dikdörtgen**: genişlik, yükseklik, köşe yarıçapı; yuvarlak veya ters (içbükey) köşeler.
- **Daire**: merkez ve yarıçap veya çap.
- **Elips**: merkez, genişlik, yükseklik, dönüş açısı.
- **Çokgen**: kenar sayısı, yarıçap, dönüş.
- **Yıldız**: ışın sayısı, dış ve iç yarıçap.
- **Yay**, üç yol: üç nokta; merkez, başlangıç ve bitiş; başlangıç, bitiş ve yarıçap.
- **Çoklu çizgi**: levhaya dokunun — her dokunuş bir nokta ekler. Sonraki nokta sayıyla girilebilir. «Kapat» ilk noktaya bağlar.

**Hazır şekli düzenlemek**: seçin ve ⋮ → «Şekil / metin düzenle…».

## 6. Düğümler

**Düğümler** düğmesi: bir vektör seçin ve noktalarını sürükleyin.
- Mavi kareler noktalar, yeşil başlangıç noktası, daireler Bézier kontrol noktalarıdır.
- **Noktaya uzun basma**: noktayı sil, yumuşat, başlangıç yap, koordinat gir.
- **Bölüme uzun basma**: çizgiye, yaya veya Bézier eğrisine dönüştür; nokta ekle; başlangıç noktası ekle; bölümü sil (vektörü kes).

## 7. Vektörleri düzenlemek

Tüm komutlar **Vektörler** menüsünde ve Asistanın «Konum, birleştirme, kırpma» bölümündedir.
- **Dönüştürme**: tam taşıma, boyut (oranlı), döndürme, eğme; kopyalı veya kopyasız.
- **Ayna**: yatay veya dikey, kendi merkezine veya levhaya göre.
- **Ofset**: dışa veya içe belirli mesafe; keskin veya yuvarlak köşeler.
- **Blok kopya**: aralık veya adımla satır ve sütun. **Dairesel**: merkez etrafında N kopya.
- **Hizalama**: son seçilene göre kenar ve merkezler; «Levha merkezi» — ham parçaya göre.
- **Grupla / Grubu çöz**: grup tek parça seçilir ve taşınır.
- **Kapalı vektörleri birleştirme**: Weld (topla); Kesişim; Çıkar (son seçilen çıkarılır); ortak kısmı çıkar.
- **Kapat**: çizgiyle, eğriyle veya ucu kaydırarak. **İki açık vektörü birleştir**: çizgiyle, eğriyle veya uçları kaydırarak. **Çakışan noktalar**: çok sayıda parçayı toleransla zincire bağlar.
- **Vektör doktoru**: çakışan noktaları, kendi kendini kesmeleri ve döngüleri bulup düzeltir.
- **Eğriler yerine yaylar**: Bézier eğrilerini yay ve çizgilerle değiştirir (daha kısa NC, daha düzgün kesim).
- **Yuvarlatma**: köşeye dokunun, yarıçapı girin. Burada iki vektörü kesişime kadar uzatmak da var.
- **Makas (kırpma)**: bir bölüme dokunmak kesişimler arasındaki parçasını siler.
- **Kontura göre kırp (Clipping)**: seçili konturun içindeki veya dışındaki vektörleri bırakır.
- **Böl**: vektörleri X veya Y boyunca bir çizgiyle böler.
- **Etrafında çerçeve**: seçimin etrafına boşluklu dikdörtgen.
- **Dönüştür**: vektörler arasında daire veya dikdörtgenleri bulup «şekil» yapar.
- **Yönü tersine çevir**: işleme sırası ve tarafı için önemlidir.
- **Kilitle**: vektör yanlışlıkla taşınamaz.
- **Özellikler**: boyut, uzunluk, alan, nokta, çizgi, yay ve eğri sayısı.

## 8. Metin

**Vektör metin**:
- yazı tipi: Arial, Times, Courier benzeri, DejaVu veya tek çizgili (tek çizgi gravür için);
- yükseklik, kalın, italik;
- hizalama, karakter ve satır aralığı, kerning;
- uzatma, eğim, dönüş;
- X/Y konumu.

«Oluştur» metni levhaya ekler. Daha sonra seçip ⋮ → «Şekil / metin düzenle» ile değiştirilebilir.

**Eğri üzerinde metin**: bir eğri veya daire seçin, «Eğri üzerinde metin»i açın, eğri üzerindeki başlangıcı, uzaklığı ve tarafı girin. Harfler eğri boyunca döner.

## 9. Zarf ve «Eğri boyunca yapıştır»

- **Zarf**: bir çizim veya desen seçin, «Zarf»ı açın. Çevresinde düğümlü bir çerçeve çıkar. Köşeleri ve kenar ortalarını sürükleyin. Ya da «Üst eğri…» / «Alt eğri…»ye basıp mevcut bir eğriye (ör. yay) dokunun. «Uygula» çizimi bozar — böylece desen kemere veya dalgaya oturur.
- **Eğri boyunca yapıştır**: seçili çizimin kopyaları bir eğri boyunca eşit dağılır — adet veya adım ile, eğriye göre dönerek ya da dönmeden.

## 10. Tabelalar ve yerleştirme

- **Multi-Plate**: bir tabela şablonu (kontur + metin) levhada çoğaltılır, metinler bir metin dosyasından satır satır alınır. Örneğin daire numaraları veya isimler: bir satır — bir tabela.
- **Yerleştirme (Nesting)**: seçili parçalar, aralık ve kenar boşluğuyla belirli boyuttaki levhalara yerleştirilir. Döndürmeye izin verilebilir. Delikler otomatik olarak parçalarıyla kalır.

## 11. Resimler ve fotoğraflar

- **Dosya → Resim / fotoğraf içe aktar** veya «Resim» simgesi. Kaynak: **galeri** veya **kamera**. Resim yarı saydam **altlık** olur.
- **Altlık ayarları**: opaklık, gösterme, kilitleme. Boyut sayıyla veya **iki noktayla**: bilinen mesafedeki iki noktaya dokunun ve gerçek mesafeyi girin.
- **Elle çizim**: altlığın üzerine çoklu çizgi ve şekillerle çizin.
- **Vektörleştirme** («Vektörleştir» simgesi):
  1. Mod seçin: siyah-beyaz (eşiğe göre siluet) veya konturlar.
  2. Parlaklık eşiği (veya «otomatik»), yumuşatma, leke temizleme, ters çevirme ayarlayın.
  3. «Önizleme» gelecek vektörleri resmin üzerinde gösterir.
  4. «Vektör oluştur» onları modele ekler.
- **Perspektifi düzelt**: levha açılı çekildiyse dört köşeye dokunun ve gerçek boyutu girin. Fotoğraf düzleşir ve 1:1 ölçeğe gelir.
- **Şablon köprüleri**: harflerin iç kısımları düşmesin diye küçük bağlantılar.

## 12. Takım yolları (işleme)

Sıra:
1. **Malzeme** (Takım yolları sekmesi → malzeme simgesi): kalınlık, güvenli Z, ev noktası (makinenin sonunda gittiği yer).
2. **Takım veritabanı**: numara, çap, açı (V-uçlar), dikey ve yan adım, devir, ilerleme ve dalış hızlı frezeler. İlerleme mm/sn veya mm/dk. Frezeler eklenebilir, kopyalanabilir, düzenlenebilir, silinebilir; veritabanı telefonda saklanır.
3. Levhada **vektörleri seçin** ve işleme türüne basın.

### İşleme türleri
- **Profil**: konturun dışında veya içinde (freze yarıçapı hesaba katılır) ya da çizgi üzerinde kesim. Ayarlar: başlangıç ve bitiş derinliği; pay; yön (eşyönlü veya karşı); sıra.
- **Köprüler (tutucular)**: parçalar kesim sırasında kopmaz. Otomatik (adet veya mesafe) ya da kontura dokunarak elle. Uzunluk ve yükseklik ayarlanır.
- **Rampalı dalış**: freze malzemeye dik değil eğik girer — daha az yük ve iz.
- **Vektörler boyunca**: freze tam çizginin üzerinden gider. Gravür, kanal, tek çizgili metin için.
- **Alan boşaltma**: kontur içinde cep. Ofset (kontur boyunca) veya tarama (zikzak) geçişleri, belirli bindirmeyle.
- **V-oyma**: V-uç; derinlik çizgi genişliğine göre değişir, «oyma» harfler ve desenler çıkar.
- **Delme**: daire merkezlerinde delikler, talaş kırmayla (kademe adımı).

«Takım» bölümünde veritabanından freze almak için **Seç…**e basın. **Hesapla** takım yolunu oluşturur. Altında kesim uzunluğu, dalış sayısı ve tahmini süre görünür.

Takım yolu listesi: dokunmak yolu ve vektörlerini seçer; onay işareti — göster/gizle; «Değiştir…» — parametreler; «Yeniden hesapla» — vektörler değişince; «Sil».

### Simülasyon
«Simülasyon» simgesi: frezenin malzemede nasıl ilerlediğinin üstten görünümü. Başlat/duraklat, hız, «Sonuç» (hepsi birden), «Baştan». Köprüleri, iç köşeleri ve boşlukları kontrol etmek için idealdir.

### NC programını kaydetmek
**Takım yolları → Takım yollarını farklı kaydet…**:
1. Gerekli yolları işaretleyin.
2. Post işlemci seçin: **Weihong (.tap)** NcStudio için; **Superstar (.nc)** 4 iş mili, freze numarası 1–4 = iş mili numarası; **kendi .con dosyanız** — «Kendi .con dosyanı yükle…», makinenizin post işlemci dosyası (ArtCAM biçimi). Hatırlanır.
3. Dosya adını girin. «Önizleme» programın başını gösterir. «Kaydet» — klasör seçin (ör. USB bellek).

**Ücretsiz** günde 1 makine programı kaydedilebilir. **Premium** (tek seferlik satın alma) sınırı ve reklamları kaldırır.

**İpucu:** ilk kesimden önce makinede sıfırı ve Z'yi kontrol edin, programı önce «havada» (Z yukarıdayken) çalıştırın.

## 13. Kaydetme ve dışa aktarma

- **Kaydet (DXF)**: normal bir DXF R12, her CAD/CAM programında açılır. İçinde tüm proje görünmez şekilde saklanır: katmanlar, takım yolları, frezeler, altlık. Burada açılırsa her şey geri gelir.
- **Farklı kaydet**: DXF; SVG (katmanlar Inkscape'te katman olarak açılır); .cnc2d projesi.
- **Dışa aktar**: 1:1 PDF (şablon yazdırmak için); seçilen çözünürlükte PNG veya JPG, PNG şeffaf arka planla da olabilir.
- **Vektör içe aktar**: başka bir DXF veya SVG'den vektörleri mevcut modele ekler.
- Eski Windows-1251 kodlamalı DXF (ArtCAM/AutoCAD'den Kiril metin) doğru açılır.

## 14. Katmanlar

**Proje** sekmesi → Katmanlar veya **Düzen → Katmanlar…**: katman ekle; yeniden adlandır ✎; renk; göster/gizle 👁; kilitle 🔒; sil ✕.

Yeni vektörler **etkin** (vurgulu) katmana gider. «Taşı» seçili vektörleri etkin katmana aktarır.

## 15. Geri alma ve Geri düğmesi

- **Geri al / Yinele**: 80 adıma kadar.
- Sistem **Geri** düğmesi sırasıyla: nokta seçimini iptal eder; açık aracı kapatır; pencereyi kapatır; başlangıç ekranına döner (model kaydedilmemişse sorar).

## 16. G-kodu içe aktarma (.tap, .nc)

Uygulama hazır bir makine programını (.tap, .nc, .ngc, .gcode vb.) açar ve ondan çizimi geri oluşturur.
- Dosyayı açın: başlangıç ekranında **Model aç** (yeni model) veya **Dosya → Vektör içe aktar…** (mevcut modele ekle).
- **Freze telafisi**: programda freze merkezinin yolu kayıtlıdır.
  - “Yok” — vektörler freze merkezinden (gravür ve vektör boyunca işleme için);
  - “Otomatik” — parçalar içe, delikler dışa freze yarıçapı kadar kaydırılır;
  - “Tümü içe” / “Tümü dışa”. Freze çapını girin.
- **Derinlik pasolarını birleştir** — farklı derinlikteki pasolar tek kontur olur.
- **Her takım ayrı katmanda** — programda birden fazla freze varsa T1, T2… katmanları.
- Sonra çizimi kaydedin: **Dosya → Kaydet (DXF)**, düzenleyin veya yeni takım yolları hesaplayın.

## 17. Sık sorulan sorular

- **Takım yolu hesaplanmıyor:** dış/iç profil ve boşaltma **kapalı** vektör ister — «Vektör doktoru» veya «Çakışan noktaları birleştir» kullanın; freze cepten geniş olabilir.
- **Parça yanlış taraftan kesiliyor:** dış/iç ayarını ve vektör yönünü kontrol edin («Yönü tersine çevir»).
- **Şablon keserken harfler düşüyor:** «Şablon köprüleri» veya profildeki köprüleri kullanın.
- **Makine «kayıyor»:** model sıfırını (Model → Sıfır konumu) ve Malzemedeki ev noktasını kontrol edin.
- **Küçük vektörleri seçmek zor:** iki parmakla yakınlaştırın veya sağdan sola çerçeve kullanın.
