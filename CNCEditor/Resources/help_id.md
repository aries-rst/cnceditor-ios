# CNC Editor 2D — Panduan

Aplikasi untuk menyiapkan pekerjaan 2D bagi mesin router CNC: gambar atau buka vektor, hitung jalur pahat, lalu simpan program NC untuk mesin Anda.
- **Weihong / NcStudio**: file **.tap**, satu spindel.
- **Superstar (4 spindel)**: file **.nc**. Nomor pahat adalah nomor spindel.

## 1. Memulai

### Layar awal
- **Buat model baru**: tentukan ukuran lembar.
- **Buka model**: DXF, SVG, atau proyek .cnc2d.
- **Model dari gambar / foto**: foto kamera atau gambar galeri menjadi latar.
- **Kembali ke model**: muncul bila model sudah terbuka.
- Di bagian atas ada pilihan **bahasa** (🌐, 17 bahasa). Di bawahnya: **Panduan**, **Premium**, serta tautan ke aplikasi ARESTI Labs lain dan situs web.

### Ukuran model baru
- **Lebar (X)** dan **Tinggi (Y)**: ukuran benda kerja. Tombol 1830×2750, 2070×2800, 1220×2440, 2050×3050 mengisi lembar standar.
- **Titik nol model**: ketuk sudut atau tengah skema. Ini X0 Y0 mesin, biasanya sudut kiri bawah.
- **Satuan**: mm atau inci. Di dalam aplikasi semua disimpan dalam milimeter.
- **Tebal material**: dipakai untuk kedalaman jalur pahat.

## 2. Layar editor

- **Bilah menu** (atas): 🏠 — kembali ke layar awal; lalu File, Edit, Model, Vektor, Jalur pahat, Bantuan. Item bertanda ▸ membuka submenu, «← Kembali» untuk kembali.
- **Bilah tampilan** (di bawah menu):
  - ☰ — tampilkan/sembunyikan panel;
  - seluruh model, perbesar, perkecil, grid;
  - urungkan, ulangi;
  - **Pilih**, **Simpul**, **Tambahkan ke pilihan**;
  - ⟳ putar layar: lanskap → potret → otomatis;
  - menu **Pilih ▾**, menu tindakan ⋮;
  - penghitung «Dipilih: N».
- **Panel** dengan tiga tab (di bawah saat potret, di kiri saat lanskap):
  - **Proyek**: info, lapisan, tips memilih, latar;
  - **Asisten**: semua alat gambar dan edit; alat yang terbuka menampilkan kolomnya di sini;
  - **Jalur pahat**: daftar, material, basis data pahat, perhitungan dan penyimpanan program NC.
- **Lembar**: persegi putih adalah benda kerja. Garis merah dan hijau adalah sumbu X dan Y di titik nol.
- **Petunjuk** di bawah memberi tahu langkah berikutnya. Bila perlu menunjuk titik, ada tombol «Batal».

Tekan lama ikon untuk melihat namanya. Ikon bersudut ◢ adalah grup: ketuk untuk membuka daftar alatnya. Alat terakhir yang dipilih tetap di tombol.

## 3. Gerakan di lembar

- **Satu jari pada vektor**: memilihnya.
- **Seret vektor terpilih**: memindahkannya.
- **Pegangan persegi di sudut**: skala proporsional.
- **Pegangan bulat di atas bingkai**: putar per 1°.
- **Seret di area kosong**: bingkai pilihan.
  - **Kiri ke kanan** (biru, garis penuh): memilih vektor yang seluruhnya di dalam bingkai.
  - **Kanan ke kiri** (hijau, putus-putus): memilih semua vektor yang tersentuh bingkai.
- **Ketuk area kosong**: batalkan pilihan.
- **Dua jari**: geser dan zoom.
- **Tekan lama pada vektor**: mengaktifkan pilihan ganda.
  - Setiap ketukan berikutnya menambah atau menghapus vektor.
  - Angka dalam lingkaran merah muda menunjukkan urutan. Urutan penting: saat meratakan, dasarnya adalah yang terakhir dipilih; saat mengurangi, yang terakhir yang dikurangkan.
- **Tekan lama saat ada vektor terpilih** (di area kosong) membuka menu tindakan.

Vektor terpilih digambar dengan garis merah muda tebal bercahaya; yang tertutup juga diberi isian tipis.

## 4. Memilih banyak vektor (pengganti tombol Shift)

- Tombol **Tambahkan ke pilihan**: selama aktif, setiap ketukan menambah atau menghapus; bingkai juga menambah.
- **Tekan lama pada vektor** mengaktifkan mode yang sama sementara. Matikan dengan «Tambahkan ke pilihan» atau «Batalkan pilihan».
- Menu **Pilih ▾**: semua; semua di lapisan aktif; hanya tertutup, hanya terbuka; ukuran serupa (seperti contoh pertama); balik pilihan; batalkan pilihan; daftar pilihan.
- **Daftar pilihan** (atau ketuk «Dipilih: N»): vektor berurutan beserta ukurannya. ✕ menghapus vektor dari pilihan.

## 5. Menggambar bentuk

Tab **Asisten** → «Alat vektor». Setiap bentuk bisa digambar dua cara:
- **Dengan jari**: seret di lembar; kolom langsung menampilkan ukuran.
- **Dengan angka**: isi pusat, lebar, tinggi, radius, dll. lalu tekan «Buat / Selesai».

Selama bentuk baru saja digambar, mengubah kolom langsung mengubahnya. «Selesai» menetapkan bentuk. «Pusat dengan ketukan» menentukan pusat dengan mengetuk.

- **Persegi panjang**: lebar, tinggi, radius sudut; sudut bulat atau terbalik (cekung).
- **Lingkaran**: pusat dan radius atau diameter.
- **Elips**: pusat, lebar, tinggi, sudut putar.
- **Poligon**: jumlah sisi, radius, putaran.
- **Bintang**: jumlah sudut, radius luar dan dalam.
- **Busur**, tiga cara: tiga titik; pusat, awal dan akhir; awal, akhir dan radius.
- **Polyline**: ketuk lembar — tiap ketukan menambah titik. Titik berikutnya bisa diketik. «Tutup» menyambung ke titik pertama.

**Mengubah bentuk jadi**: pilih lalu ⋮ → «Edit bentuk / teks…».

## 6. Simpul

Tombol **Simpul**: pilih vektor lalu seret titiknya.
- Kotak biru = titik, hijau = titik awal, lingkaran = titik kendali Bézier.
- **Tekan lama titik**: hapus, haluskan, jadikan awal, masukkan koordinat.
- **Tekan lama segmen**: ubah jadi garis, busur, atau kurva Bézier; sisipkan titik; sisipkan titik awal; hapus segmen (memotong vektor).

## 7. Mengedit vektor

Semua perintah ada di menu **Vektor** dan bagian Asisten «Posisi, gabung, pangkas».
- **Transformasi**: pindah tepat, ukuran (proporsional), putar, miringkan, dengan atau tanpa salinan.
- **Cermin**: horizontal atau vertikal, terhadap pusatnya atau lembar.
- **Offset**: keluar atau ke dalam sejauh jarak tertentu; sudut tajam atau bulat.
- **Salin blok**: baris dan kolom dengan jarak atau langkah. **Melingkar**: N salinan mengelilingi pusat.
- **Ratakan**: tepi dan pusat terhadap yang terakhir dipilih; «Tengah lembar» — terhadap benda kerja.
- **Kelompokkan / Pisahkan grup**: grup dipilih dan dipindah utuh.
- **Gabung vektor tertutup**: Weld (satukan); Perpotongan; Kurangi (yang terakhir dipilih dikurangkan); kecualikan bagian bersama.
- **Tutup**: dengan garis, kurva, atau menggeser ujung. **Gabungkan dua vektor terbuka**: dengan garis, kurva, atau menggeser ujung. **Titik berimpit**: menyambung banyak potongan jadi rantai dengan toleransi.
- **Dokter vektor**: menemukan titik berimpit, perpotongan diri, dan loop lalu memperbaikinya.
- **Busur pengganti kurva**: mengganti Bézier dengan busur dan garis (program NC lebih pendek, potongan lebih halus).
- **Lengkungan**: ketuk sudut, atur radius. Di sini juga: memperpanjang dua vektor sampai berpotongan.
- **Gunting (pangkas)**: mengetuk segmen menghapus potongannya di antara perpotongan.
- **Potong menurut kontur (Clipping)**: mempertahankan vektor di dalam atau di luar kontur terpilih.
- **Belah**: memotong vektor dengan garis X atau Y.
- **Bingkai di sekitar**: persegi panjang di sekitar pilihan dengan jarak.
- **Ubah**: mencari lingkaran atau persegi panjang di antara vektor dan menjadikannya «bentuk».
- **Balik arah**: penting untuk urutan dan sisi pemrosesan.
- **Kunci**: vektor tidak terpindah tanpa sengaja.
- **Properti**: ukuran, panjang, luas, jumlah titik, garis, busur, dan kurva.

## 8. Teks

**Teks vektor**:
- font: mirip Arial, Times, Courier, DejaVu, atau satu garis (gravir satu garis);
- tinggi, tebal, miring;
- perataan, jarak huruf dan baris, kerning;
- regangan, kemiringan, putaran;
- posisi X/Y.

«Buat» menaruh teks di lembar. Nanti pilih dan ubah lewat ⋮ → «Edit bentuk / teks».

**Teks pada kurva**: pilih kurva atau lingkaran, buka «Teks pada kurva», atur awal, jarak dari kurva, dan sisi. Huruf berputar mengikuti kurva.

## 9. Envelope dan «Tempel sepanjang kurva»

- **Envelope**: pilih gambar atau pola, buka «Envelope». Muncul bingkai bersimpul. Seret sudut dan titik tengah sisi. Atau tekan «Kurva atas…» / «Kurva bawah…» lalu ketuk kurva yang ada (misalnya busur). «Terapkan» mendistorsi gambar — pola jadi pas di lengkungan atau gelombang.
- **Tempel sepanjang kurva**: salinan gambar disebar merata di sepanjang kurva — menurut jumlah atau langkah, ikut berputar atau tidak.

## 10. Papan nama dan nesting

- **Multi-Plate**: templat papan (kontur + teks) diperbanyak di lembar dengan baris dari file teks. Misalnya nomor apartemen atau nama: satu baris — satu papan.
- **Nesting**: bagian terpilih disusun di lembar berukuran tertentu dengan jarak dan tepi. Rotasi dapat diizinkan. Lubang otomatis tetap bersama bagiannya.

## 11. Gambar dan foto

- Menu **File → Impor gambar / foto** atau ikon «Gambar». Sumber: **galeri** atau **kamera**. Gambar menjadi **latar** semi-transparan.
- **Pengaturan latar**: opasitas, tampil, kunci. Ukuran dengan angka atau **dengan dua titik**: ketuk dua titik yang jaraknya diketahui dan masukkan jarak sebenarnya.
- **Jiplak manual**: gambar dengan polyline dan bentuk di atas latar.
- **Vektorisasi** (ikon «Vektorkan»):
  1. Pilih mode: hitam-putih (siluet menurut ambang) atau kontur.
  2. Atur ambang kecerahan (atau «otomatis»), penghalusan, hapus noda, balik.
  3. «Pratinjau» menampilkan calon vektor di atas gambar.
  4. «Buat vektor» menambahkannya ke model.
- **Koreksi perspektif**: bila lembar difoto miring, ketuk empat sudut dan masukkan ukuran sebenarnya. Foto menjadi lurus dan berskala 1:1.
- **Jembatan stensil**: penghubung kecil agar bagian dalam huruf tidak jatuh.

## 12. Jalur pahat (permesinan)

Langkah:
1. **Material** (tab Jalur pahat → ikon material): tebal, Z aman, titik home (tempat mesin pergi di akhir).
2. **Basis data pahat**: pahat dengan nomor, diameter, sudut (mata V), langkah turun dan samping, putaran, laju makan, dan kecepatan penetrasi. Laju makan dalam mm/dtk atau mm/mnt. Bisa ditambah, disalin, diedit, dihapus; tersimpan di ponsel.
3. **Pilih vektor** di lembar lalu tekan jenis pemrosesan.

### Jenis pemrosesan
- **Profil**: potong di luar atau di dalam kontur (memperhitungkan radius pahat) atau tepat di garis. Pengaturan: kedalaman awal dan akhir; sisa bahan; arah (climb atau konvensional); urutan.
- **Jembatan (penahan)**: bagian tidak terlepas saat dipotong. Otomatis (jumlah atau jarak) atau manual dengan mengetuk kontur. Panjang dan tinggi dapat diatur.
- **Penetrasi ramp**: pahat masuk miring, bukan tegak — beban dan bekas lebih sedikit.
- **Sepanjang vektor**: pahat berjalan tepat di garis. Untuk gravir, alur, teks satu garis.
- **Pengosongan area**: kantong di dalam kontur. Lintasan offset (mengikuti kontur) atau raster (zig-zag), dengan tumpang tindih tertentu.
- **Ukir V**: mata V; kedalaman mengikuti lebar garis sehingga huruf dan pola tampak «terukir».
- **Pengeboran**: lubang di pusat lingkaran, dengan bor bertahap (langkah bor).

Di bagian «Pahat», tekan **Pilih…** untuk mengambil pahat dari basis data. **Hitung** membuat jalur pahat. Di bawahnya tampil panjang potong, jumlah penetrasi, dan perkiraan waktu.

Daftar jalur: ketuk memilih jalur dan vektornya; centang — tampil/sembunyi; «Ubah…» — parameter; «Hitung ulang» — setelah vektor berubah; «Hapus».

### Simulasi
Ikon «Simulasi»: tampak atas bagaimana pahat melewati material. Putar/jeda, kecepatan, «Hasil» (sekaligus), «Dari awal». Cocok untuk memeriksa jembatan, sudut dalam, dan bagian terlewat.

### Menyimpan program NC
**Jalur pahat → Simpan jalur pahat sebagai…**:
1. Centang jalur yang diperlukan.
2. Pilih post-processor: **Weihong (.tap)** untuk NcStudio; **Superstar (.nc)** 4 spindel, nomor pahat 1–4 = nomor spindel; **.con sendiri** — «Muat .con sendiri…», file post-processor mesin Anda (format ArtCAM). File ini diingat.
3. Tentukan nama file. «Pratinjau» menampilkan awal program. «Simpan» — pilih folder (misalnya flashdisk).

**Gratis**: 1 program mesin per hari. **Premium** (sekali beli) menghapus batas dan iklan.

**Tips**: sebelum potong pertama, periksa titik nol dan Z di mesin, lalu jalankan program «di udara» (Z terangkat) lebih dulu.

## 13. Menyimpan dan mengekspor

- **Simpan (DXF)**: DXF R12 biasa yang terbuka di program CAD/CAM mana pun. Di dalamnya seluruh proyek tersimpan tanpa terlihat: lapisan, jalur pahat, pahat, latar. Bila dibuka lagi di sini, semuanya kembali.
- **Simpan sebagai**: DXF; SVG (lapisan terbuka sebagai lapisan di Inkscape); proyek .cnc2d.
- **Ekspor**: PDF 1:1 (untuk mencetak mal); PNG atau JPG pada resolusi pilihan, PNG juga bisa berlatar transparan.
- **Impor vektor**: menambahkan vektor dari DXF atau SVG lain ke model.
- DXF berkode lama Windows-1251 (huruf Kiril dari ArtCAM/AutoCAD) terbuka dengan benar.

## 14. Lapisan

Tab **Proyek** → Lapisan, atau **Edit → Lapisan…**: tambah; ganti nama ✎; warna; tampil/sembunyi 👁; kunci 🔒; hapus ✕.

Vektor baru masuk ke lapisan **aktif** (disorot). «Pindahkan» membawa vektor terpilih ke lapisan aktif.

## 15. Urungkan dan tombol Kembali

- **Urungkan / Ulangi**: hingga 80 langkah.
- Tombol **Kembali** sistem, berurutan: membatalkan penunjukan titik; menutup alat yang terbuka; menutup jendela; kembali ke layar awal (bertanya bila model belum disimpan).

## 16. Impor G-code (.tap, .nc)

Aplikasi membuka program mesin yang sudah jadi (.tap, .nc, .ngc, .gcode, dll.) dan memulihkan gambarnya.
- Buka file: **Buka model** di layar awal (model baru) atau **File → Impor vektor…** (tambahkan ke model saat ini).
- **Kompensasi pisau**: program menyimpan jalur pusat pisau.
  - “Tidak ada” — vektor mengikuti pusat pisau (cocok untuk ukiran dan pemesinan sepanjang vektor);
  - “Otomatis” — bagian digeser ke dalam dan lubang ke luar sebesar jari-jari pisau;
  - “Semua ke dalam” / “Semua ke luar”. Masukkan diameter pisau.
- **Gabungkan lintasan kedalaman** — beberapa lintasan pada kedalaman berbeda menjadi satu kontur.
- **Setiap alat di lapisan sendiri** — lapisan T1, T2… jika program memakai beberapa pisau.
- Lalu simpan gambar: **File → Simpan (DXF)**, edit, atau hitung jalur pahat baru.

## 17. Pertanyaan umum

- **Jalur pahat tidak dihitung:** profil luar/dalam dan pengosongan membutuhkan vektor **tertutup** — gunakan «Dokter vektor» atau «Gabungkan titik berimpit»; pahat mungkin lebih lebar dari kantong.
- **Bagian dipotong di sisi yang salah:** periksa luar/dalam dan arah vektor («Balik arah»).
- **Huruf jatuh saat memotong stensil:** gunakan «Jembatan stensil» atau jembatan pada profil.
- **Mesin «bergeser»:** periksa titik nol model (Model → Posisi nol) dan titik home di Material.
- **Vektor kecil sulit dipilih:** perbesar dengan dua jari atau pakai bingkai kanan ke kiri.
