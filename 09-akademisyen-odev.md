# Modül 8 — Akademisyen CRUD (Bağımsız Ödev)

**Süre:** 1 ders saati (giriş) + ödev süresi
**Ön koşul:** Modül 7
**Kim yazıyor:** ⭐⭐ **Tamamen öğrenci. Sen kod göstermeyeceksin.**

---

## 🎯 Bu modülün amacı

Öğrenci, öğrendiği kalıbı **rehbersiz** uygulayabildiğini kendine kanıtlayacak.

> **Bu modülün pedagojik değeri, kod değerinden yüksek.** Akademisyen tablosu öğrenci tablosunun neredeyse aynısı (tek fark: sınıf alanı yok). Yani yeni bir şey öğrenmiyorlar — **öğrendiklerini kullanabildiklerini görüyorlar.** Bu deneyim, "ben bunu yapabiliyorum" hissini yaratır ve dersin en kalıcı çıktısıdır.

---

## 🗣️ Derse giriş — 15 dakika

### 1. Tabloları karşılaştırın (tahtada, beraber)

```
     ogrenci                      akademisyen
─────────────────────      ─────────────────────
 ogrenci_id                 akademisyen_id
 bolum_id                   bolum_id
 ogrenci_ad                 akademisyen_ad
 ogrenci_soyad              akademisyen_soyad
 ogrenci_sinif       ←──── ✂️ BU YOK
 ogrenci_dogum_tarihi       akademisyen_dogum_tarihi
 ogrenci_cinsiyet           akademisyen_cinsiyet
 ogrenci_adres              akademisyen_adres
 ogrenci_telefon            akademisyen_telefon
 ogrenci_eposta             akademisyen_eposta
 ogrenci_tc                 akademisyen_tc
 created_date               created_date
 updated_date               updated_date
 is_active                  is_active
```

**Tek fark:** `ogrenci_sinif` alanı akademisyende yok. Gerisi birebir aynı.

### 2. Yapılacaklar listesini beraber çıkarın

Sen yazma, **onlara söylettir**:

```
□ Models/Akademisyen.cs
□ Data/AkademisyenRepository.cs
    □ TumunuGetir()      (JOIN'li)
    □ IdIleGetir(id)
    □ Ekle(model)
    □ Guncelle(model)
    □ PasifYap(id)
    □ SatiriNesneyeCevir(okuyucu)
□ Program.cs → AddScoped<AkademisyenRepository>()
□ Controllers/AkademisyenController.cs
    □ Index()
    □ Create()  GET
    □ Create(model)  POST + try-catch
    □ Edit(id)  GET
    □ Edit(model)  POST + try-catch
    □ Delete(id)  GET
    □ DeleteConfirmed(id)  POST
    □ BolumListesiniHazirla(secili)
□ Views/Akademisyen/
    □ Index.cshtml
    □ Create.cshtml
    □ Edit.cshtml
    □ Delete.cshtml
□ _Layout.cshtml → menü linki (zaten var, kontrol et)
```

Bu listeyi tahtada bırak, silme. Öğrenciler ilerledikçe kendi listelerinden işaretlesinler.

### 3. Kuralları söyle

> **"Öğrenci CRUD'unun kodunu açıp bakabilirsiniz. Kopyala-yapıştır yapabilirsiniz. Ama her kopyaladığınız satırda 'ogrenci' kelimesini 'akademisyen' yapmayı unutmayacaksınız — ve bunu yaparken kodun ne yaptığını okumak zorunda kalacaksınız. Amaç bu zaten."**

> **"Bana soru sormadan önce 10 dakika kendiniz uğraşın. Hata mesajını okuyun. `EK-A-sik-hatalar.md` dosyasına bakın. Sonra gelin."**

---

## 🧭 Yönlendirme stratejisi

Ders boyunca dolaş. Takılan öğrenciye **cevabı verme, soru sor:**

| Öğrenci diyor ki | Sen cevap verme, bunu sor |
|---|---|
| "Çalışmıyor" | "Hata mesajı ne diyor? Yüksek sesle oku." |
| "Invalid column name hatası" | "Hangi sütun adı? Veritabanında bu isim tam olarak nasıl yazılıyor?" |
| "Sayfa boş geliyor" | "Repository metodu veri dönüyor mu? Bir breakpoint koyup bakalım mı?" |
| "Açılır liste boş" | "Bu hatayı Bölüm modülünde de yaşamıştık. Ne yapmıştık?" |
| "Kaydediyor ama güncellemiyor" | "Gizli alanları kontrol ettin mi? Modül 5'te bu vardı." |
| "NullReferenceException" | "Hangi satırda? O satırda hangi değer null olabilir?" |

> **Kendini tut.** Klavyeyi eline alıp düzeltmek 30 saniye sürer ama öğrenci hiçbir şey öğrenmez. Soru sorarak yönlendirmek 5 dakika sürer ve kalıcı olur.

---

## 🔍 Hata ayıklama (debugging) — bu ders öğretilecek beceri

Bu iyi bir fırsat: öğrenciler artık hata alacak ve **kendi başlarına** çözmeye çalışacak. Ders başında 10 dakika breakpoint kullanımını göster.

### Breakpoint nasıl konur?

1. Kod satırının **solundaki gri şeride tıkla** → kırmızı nokta çıkar
2. F5 ile çalıştır
3. Kod o satıra geldiğinde **durur**
4. Değişkenlerin üzerine fareyi getir → o anki değeri görürsün

### Nereye breakpoint koymalı?

```csharp
public IActionResult Index()
{
    var liste = _repo.TumunuGetir();   // 🔴 buraya → liste kaç eleman geldi?
    return View(liste);
}
```

```csharp
public void Ekle(Akademisyen a)
{
    // ...
    baglanti.Open();
    komut.ExecuteNonQuery();   // 🔴 buraya → parametreler doğru mu?
}
```

### Faydalı kısayollar

| Tuş | Ne yapar |
|---|---|
| F9 | Breakpoint koy/kaldır |
| F5 | Çalıştır / devam et |
| F10 | Bir satır ilerle (metoda girme) |
| F11 | Bir satır ilerle (metoda gir) |
| Shift+F5 | Durdur |

### SQL'i gözle görmek

Öğrenciye çok yardımcı olan bir numara — repository'de geçici olarak:

```csharp
Console.WriteLine(sql);
foreach (SqlParameter p in komut.Parameters)
    Console.WriteLine($"{p.ParameterName} = {p.Value}");
```

Çıktı Visual Studio'nun **Output** penceresinde görünür. *"Gönderdiğim SQL gerçekten bu mu?"* sorusunun cevabı.

---

## 📊 Değerlendirme rubriği

Ödevi puanlarken kullan (100 üzerinden):

| Ölçüt | Puan | Açıklama |
|---|---|---|
| Model sınıfı doğru ve tam | 10 | Tüm alanlar, doğru tipler |
| Data Annotation kuralları var | 10 | `[Required]`, `[EmailAddress]`, TC regex |
| Repository — 5 metot çalışıyor | 25 | Her biri 5 puan |
| Parametreli sorgu kullanılmış | 10 | ⚠️ String birleştirme varsa **0 puan** |
| Controller — 7 metot doğru | 20 | GET/POST ayrımı doğru |
| View'lar çalışıyor ve düzenli | 15 | Bootstrap kullanımı |
| try-catch ile hata yakalama | 5 | Benzersizlik hatası çökmüyor |
| Kod düzeni ve okunabilirlik | 5 | Girinti, isimlendirme, gereksiz kod yok |

**Otomatik puan kırma:**
- SQL'e `+` ile değer eklenmişse → parametreli sorgu maddesinden **0**
- Gerçek `DELETE` kullanılmışsa (soft delete yerine) → **−10**
- `Program.cs`'e repository eklenmemiş, uygulama açılmıyorsa → **−15**

---

## ✅ Teslim kontrol listesi (öğrenciye ver)

Teslim etmeden önce şunları kendin test et:

```
□ Uygulama hatasız açılıyor
□ Menüden "Akademisyenler" tıklanınca liste geliyor
□ Listede bölüm ADI görünüyor (id değil)
□ "Yeni akademisyen" formu açılıyor
□ Bölüm açılır listesi dolu geliyor
□ Boş form gönderilince hata mesajları çıkıyor
□ TC'ye 5 hane yazınca hata çıkıyor
□ Geçerli veri kaydediliyor
□ Kayıttan sonra yeşil "kaydedildi" mesajı çıkıyor
□ SSMS'te created_date dolu görünüyor
□ Düzenleme formu dolu geliyor
□ Düzenleme kaydediliyor, updated_date doluyor
□ Silme onay sayfası çıkıyor
□ Silinen kayıt listeden gidiyor
□ SSMS'te silinen kayıt duruyor, is_active = '0'
□ Aynı e-postayı ikinci kez girince uygulama ÇÖKMÜYOR
```

---

## 🎁 Ekstra puan görevleri

Erken bitirenler için:

**+5 puan — Unvan alanı**
Akademisyenlerin unvanı olur (Prof. Dr., Doç. Dr., Dr. Öğr. Üyesi, Arş. Gör.). Veritabanına yeni sütun ekle ve forma açılır liste olarak koy:

```sql
ALTER TABLE akademisyen ADD akademisyen_unvan NVARCHAR(50) NULL;
```

**+5 puan — Bölüme göre gruplama**
Akademisyen listesini bölüme göre gruplandır. Her bölüm bir başlık, altında o bölümün akademisyenleri.
*(İpucu: SQL'de `ORDER BY b.bolum_adi`, view'da bir önceki satırın bölümüyle karşılaştır.)*

**+10 puan — Kartlı görünüm**
Tablo yerine kart görünümü ekle. Her akademisyen bir kart, üstte baş harfleri daire içinde. Tablo/kart arasında geçiş butonu olsun.

**+10 puan — Excel'e aktar**
Listeyi CSV olarak indiren bir buton ekle:

```csharp
public IActionResult CsvIndir()
{
    var liste = _repo.TumunuGetir();
    var sb = new System.Text.StringBuilder();

    sb.AppendLine("Ad;Soyad;Bolum;Telefon;Eposta");
    foreach (var a in liste)
        sb.AppendLine($"{a.AkademisyenAd};{a.AkademisyenSoyad};{a.BolumAdi};{a.AkademisyenTelefon};{a.AkademisyenEposta}");

    // UTF-8 BOM: Excel'in Türkçe karakterleri doğru açması için
    var bom = new byte[] { 0xEF, 0xBB, 0xBF };
    var icerik = System.Text.Encoding.UTF8.GetBytes(sb.ToString());
    var dosya = bom.Concat(icerik).ToArray();

    return File(dosya, "text/csv", "akademisyenler.csv");
}
```

> Türk Excel'i `;` ayracı bekler, `,` değil. BOM olmadan Türkçe karakterler bozuk açılır. İki küçük detay ama gerçek hayatta çok baş ağrıtır — öğrenciye anlatmaya değer.

---

## 🗣️ Ders sonu — 10 dakikalık kapanış

Ödev teslim edildikten sonraki derste, şu soruları sınıfa sor:

1. **"En çok hangi hatada takıldınız?"** → Ortak hataları tahtaya yaz, beraber çözün.
2. **"Kopyala-yapıştır yaparken en çok neyi değiştirmeyi unuttunuz?"** → Genelde: sütun adları, `GetInt32`/`GetInt64`, view'daki `@model` satırı.
3. **"Bu dördüncü tekrardı. Şimdi beşinci bir tablo verilse ne kadar sürede yaparsınız?"** → İlkinde 2 ders, şimdi belki 1 saat. Bu ilerlemeyi onlara **fark ettir**. Öğrencinin kendi gelişimini görmesi motivasyonun en güçlü kaynağıdır.
4. **"Bu kadar tekrar eden kodu azaltmanın bir yolu var mı sizce?"** → Generic repository, base controller, EF Core... Buradan bir sonraki döneme köprü kur.

---

## Sonraki adım

👉 [`10-dashboard-istatistikler.md`](10-dashboard-istatistikler.md) — Ana sayfadaki sahte sayıları gerçekle değiştiriyoruz.
