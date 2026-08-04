# Okul Yönetim Sistemi — Ders Rehberi

**ASP.NET Core MVC + ADO.NET + Bootstrap 5**
İlk web uygulaması dersi için hazırlanmış, adım adım eğitmen rehberi.

---

## Bu rehber kimin için?

Bu rehber **eğitmen içindir**. Her modül şu düzende yazılmıştır:

| Bölüm | Ne işe yarar |
|---|---|
| 🎯 Bu derste ne yapacağız | Derse başlarken tahtaya yazacağın hedef |
| 📖 Kavram | Kod yazmadan önce anlatılacak teori (5-10 dk) |
| ⌨️ Adım adım kod | Senin canlı yazacağın kod, satır satır açıklamalı |
| ▶️ Çalıştır ve gör | Öğrencinin ekranda görmesi gereken sonuç |
| ⚠️ Sık yapılan hatalar | Derste %90 ihtimalle karşılaşacağın sorunlar |
| ✏️ Öğrenci alıştırması | Ders sonunda onların yapacağı iş |

> **Öğretim modeli:** Önce sen yazarsın (öğrenci izler) → sonra beraber yazarsınız → sonra onlar tek başına yazar. Modül 6'ya kadar sen yazarsın, Modül 7'de beraber, Modül 8'den sonra onlar yazar.

---

## Sistem hakkında

Öğrencilerin geliştireceği uygulama: bir üniversitenin **fakülte → bölüm → öğrenci / akademisyen** kayıtlarını yöneten basit bir yönetim paneli.

```
fakulte  (Mühendislik Fakültesi)
   │
   └── bolum  (Bilgisayar Mühendisliği)
          ├── ogrenci     (Ayşe Yılmaz)
          └── akademisyen (Dr. Mehmet Kaya)
```

Bu hiyerarşi kasıtlı olarak basit: aynı CRUD kalıbı 4 kez tekrar edecek, öğrenci 4. tekrarda kalıbı ezberlemiş olacak.

---

## Teknoloji tercihleri ve gerekçeleri

| Tercih | Neden |
|---|---|
| **ASP.NET Core MVC** | Klasör yapısı görsel olarak net: Model / View / Controller ayrımı öğretilebilir. |
| **ADO.NET (SqlConnection, SqlCommand)** | Entity Framework "sihirli" davranır; öğrenci SQL'i göremez. ADO.NET ile yazdıkları SQL doğrudan veritabanına gider. Veritabanı dersinde öğrendikleri SQL burada işe yarar. |
| **Bootstrap 5 (CDN)** | CSS öğretmeye vaktimiz yok. Hazır sınıflarla profesyonel görünüm. |
| **Repository sınıfları** | Controller içinde SQL yazmak kısa vadede kolay ama öğrenciye kötü alışkanlık kazandırır. Basit bir katman ayrımı yeterli. |

> **Not:** İleride "peki EF Core nedir?" sorusu gelecektir. Cevap: *"Bizim elle yazdığımız bu SQL'leri sizin yerinize yazan bir araç. Ama önce elle yazmayı bilmeniz gerekiyor."*

---

## .NET sürümü

Rehber **.NET 10 (LTS)** hedeflenerek yazılmıştır. .NET 10 Kasım 2025'te çıktı ve Kasım 2028'e kadar destekleniyor. .NET 8 ve .NET 9'un desteği **10 Kasım 2026'da** bitiyor, dolayısıyla yeni bir ders için .NET 10 doğru tercih.

Elindeki laboratuvarda .NET 8 kuruluysa endişelenme: bu rehberdeki **tüm kodlar .NET 8'de de aynen çalışır**. Fark yalnızca proje dosyasındaki `<TargetFramework>` satırıdır.

---

## Ders takvimi

Toplam **14-16 ders saati** öngörülmüştür. Haftada 2 saatlik bir derste yaklaşık 8 hafta.

| # | Modül | Süre | Kim yazıyor? | Dosya |
|---|---|---|---|---|
| 0 | Ortam kurulumu | 1 saat | — | `01-ortam-kurulumu.md` |
| 1 | Veritabanını kurma ve tanıma | 1 saat | Eğitmen | `02-veritabani.md` |
| 2 | İlk MVC projesi | 1 saat | Eğitmen | `03-proje-olusturma-mvc.md` |
| 3 | ADO.NET ile ilk bağlantı | 2 saat | Eğitmen | `04-adonet-ilk-baglanti.md` |
| 4 | Bootstrap dashboard iskeleti | 1 saat | Eğitmen | `05-bootstrap-dashboard-layout.md` |
| 5 | **Fakülte CRUD** (ana kalıp) | 2 saat | Eğitmen | `06-fakulte-crud.md` |
| 6 | **Bölüm CRUD** (yabancı anahtar) | 2 saat | Beraber | `07-bolum-crud.md` |
| 7 | **Öğrenci CRUD** (validasyon) | 2 saat | Öğrenci + rehberlik | `08-ogrenci-crud.md` |
| 8 | **Akademisyen CRUD** (ödev) | 1 saat | Öğrenci tek başına | `09-akademisyen-odev.md` |
| 9 | Dashboard istatistikleri | 1 saat | Beraber | `10-dashboard-istatistikler.md` |
| 10 | Arama, filtreleme, sayfalama | 1 saat | Beraber | `11-arama-filtreleme-sayfalama.md` |
| 11 | Cila: mesajlar, onaylar, hata yönetimi | 1 saat | Beraber | `12-cila-ve-hata-yonetimi.md` |
| 12 | Opsiyonel: giriş ekranı ve yayınlama | 1-2 saat | Beraber | `13-opsiyonel-login-ve-yayinlama.md` |

**Ekler:**
- `EK-A-sik-hatalar.md` — Derste karşılaşacağın hataların tam listesi ve çözümleri
- `EK-B-odevler-ve-degerlendirme.md` — Ödev listesi ve değerlendirme rubriği
- `EK-C-test-verisi.sql` — Hazır örnek veri

---

## Proje mimarisi (final hâli)

Ders sonunda ortaya çıkacak klasör yapısı:

```
OkulYonetim/
│
├── Program.cs                  ← Uygulamanın başlangıç noktası
├── appsettings.json            ← Veritabanı bağlantı bilgisi
├── OkulYonetim.csproj          ← Proje ayarları, paketler
│
├── Models/                     ← Veriyi temsil eden sınıflar
│   ├── Fakulte.cs
│   ├── Bolum.cs
│   ├── Ogrenci.cs
│   ├── Akademisyen.cs
│   └── DashboardViewModel.cs
│
├── Data/                       ← Veritabanı işlemleri (SQL burada)
│   ├── FakulteRepository.cs
│   ├── BolumRepository.cs
│   ├── OgrenciRepository.cs
│   └── AkademisyenRepository.cs
│
├── Controllers/                ← İstekleri karşılayan sınıflar
│   ├── HomeController.cs
│   ├── FakulteController.cs
│   ├── BolumController.cs
│   ├── OgrenciController.cs
│   └── AkademisyenController.cs
│
├── Views/                      ← Kullanıcının gördüğü HTML
│   ├── Shared/
│   │   └── _Layout.cshtml      ← Ortak sayfa iskeleti
│   ├── Home/
│   │   └── Index.cshtml        ← Dashboard
│   ├── Fakulte/
│   │   ├── Index.cshtml
│   │   ├── Create.cshtml
│   │   └── Edit.cshtml
│   └── ... (Bolum, Ogrenci, Akademisyen)
│
└── wwwroot/                    ← Statik dosyalar (css, js, resim)
```

---

## Veri akışı — öğrencilere tahtada çizeceğin şema

Bu şemayı Modül 3'te tahtaya çiz ve dersin geri kalanında sürekli ona geri dön:

```
 1. Kullanıcı tarayıcıda /Fakulte adresine gider
                │
                ▼
 2. Program.cs → "bu adres FakulteController'ın Index metodunu çağırır"
                │
                ▼
 3. FakulteController.Index()  →  FakulteRepository.TumunuGetir()
                │
                ▼
 4. Repository SQL yazar:  SELECT * FROM fakulte
                │
                ▼
 5. SQL Server veriyi döner  →  List<Fakulte> nesnesine çevrilir
                │
                ▼
 6. Controller listeyi View'a gönderir:  return View(liste)
                │
                ▼
 7. Views/Fakulte/Index.cshtml listeyi HTML tabloya çevirir
                │
                ▼
 8. Tarayıcıda tablo görünür
```

> **Eğitmen notu:** Öğrenciler en çok bu akışta kaybolur. "Şu an 8 adımın hangisindeyiz?" sorusunu derste sık sor.

---

## Şemaya dair tasarım notları

Elimizdeki SQL şeması ders için gayet uygun, ancak üç noktada gerçek dünyada farklı yapılırdı. **Bunları Modül 1'de tartışma sorusu olarak kullan** — öğrenci "neden böyle" diye düşünmeyi öğrenir:

| Mevcut hâli | Gerçek projede | Neden |
|---|---|---|
| `is_active NVARCHAR(255)` | `is_active BIT` | Sadece "var/yok" bilgisi için 255 karakterlik metin alanı israf. `BIT` 1 bit yer kaplar ve yanlış değer girilmesini engeller. |
| `fakulte_adres TEXT` | `NVARCHAR(MAX)` | `TEXT` tipi SQL Server'da artık kullanılmıyor (deprecated), Türkçe karakterde de sorun çıkarabilir. |
| `ogrenci_tc NVARCHAR(255)` | `CHAR(11)` | TC kimlik no her zaman tam 11 hane. Sabit uzunluk hem yer kazandırır hem hatalı veriyi engeller. |

**Rehber boyunca mevcut şemaya sadık kalınmıştır** — öğrencinin elindeki script neyse kod da onunla uyumlu. `is_active` alanı `"1"` (aktif) / `"0"` (pasif) metin değerleri olarak kullanılacak.

---

## Öğrenciye ilk derste söylenecekler

1. **"Bu uygulamayı 8 hafta boyunca parça parça inşa edeceğiz."** Her hafta çalışan bir şey çıkacak, en sonda tek seferde büyük bir şey yapmayacağız.
2. **"Kodu kopyalamayın, yazın."** Kas hafızası gerçek. Kopyalayan öğrenci sınavda yazamıyor.
3. **"Hata almak normal."** Bu derste hata mesajı okumayı öğreneceğiz. Hata mesajı düşman değil, ipucu.
4. **"Her hafta projenizi yedekleyin."** (Modül 0'da git veya basit klasör kopyalama anlatılıyor.)

---

## Sonraki adım

👉 [`01-ortam-kurulumu.md`](01-ortam-kurulumu.md) ile başla.
