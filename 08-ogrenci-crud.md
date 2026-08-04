# Modül 7 — Öğrenci CRUD (Validasyon ve Hata Yakalama)

**Süre:** 2 ders saati
**Ön koşul:** Modül 6 (Bölüm CRUD çalışıyor)
**Kim yazıyor:** ⭐ **Öğrenci yazar, sen yönlendirirsin**

---

## 🎯 Bu derste ne yapacağız

Öğrenci tablosu için CRUD. Kalıp aynı ama **üç yeni konu** var:

1. Farklı form elemanları — tarih seçici, radyo düğmesi, sayı kutusu
2. Özel doğrulama kuralı — TC kimlik numarası
3. Veritabanı hatalarını **çökmeden** yakalamak

> ⭐ **Ders formatı değişiyor.** Bu modülde sen kod yazmayacaksın. Tahtaya sadece adım başlıklarını yaz, öğrenciler yazsın. Sen dolaş, takılanlara yardım et. Yeni konuları (aşağıdaki 3 madde) beraber çözün.

---

## 🗣️ Derse başlangıç — 10 dakika

Tahtaya sadece şunu yaz ve öğrencilere sor:

```
ÖĞRENCİ CRUD — YAPILACAKLAR
1. Models/Ogrenci.cs
2. Data/OgrenciRepository.cs   (5 metot)
3. Program.cs'e kaydet
4. Controllers/OgrenciController.cs  (7 metot)
5. Views/Ogrenci/  →  Index, Create, Edit, Delete
```

**Sor:** *"Bölüm CRUD'unda hangi 5 repository metodu vardı? Hangi 7 controller metodu?"*

Cevaplar gelene kadar bekle. Gelmiyorsa Modül 5'in sonundaki özet kartına baktır. **Sen söyleme, onlar hatırlasın.**

---

## ⌨️ Adım 1: Model — yeni alan tipleri

`Models/Ogrenci.cs`:

```csharp
using System.ComponentModel.DataAnnotations;

namespace OkulYonetim.Models;

public class Ogrenci
{
    public long OgrenciId { get; set; }

    [Required(ErrorMessage = "Bölüm seçmelisiniz.")]
    [Display(Name = "Bölüm")]
    public long BolumId { get; set; }

    [Required(ErrorMessage = "Ad zorunludur.")]
    [StringLength(255)]
    [Display(Name = "Ad")]
    public string OgrenciAd { get; set; } = "";

    [Required(ErrorMessage = "Soyad zorunludur.")]
    [StringLength(255)]
    [Display(Name = "Soyad")]
    public string OgrenciSoyad { get; set; } = "";

    // ⭐ YENİ: sayı alanı, aralık kontrolü ile
    [Required(ErrorMessage = "Sınıf zorunludur.")]
    [Range(1, 6, ErrorMessage = "Sınıf 1 ile 6 arasında olmalıdır.")]
    [Display(Name = "Sınıf")]
    public int OgrenciSinif { get; set; }

    // ⭐ YENİ: tarih alanı
    [Required(ErrorMessage = "Doğum tarihi zorunludur.")]
    [DataType(DataType.Date)]
    [Display(Name = "Doğum tarihi")]
    public DateTime OgrenciDogumTarihi { get; set; }

    // ⭐ YENİ: sınırlı seçenek
    [Required(ErrorMessage = "Cinsiyet seçmelisiniz.")]
    [Display(Name = "Cinsiyet")]
    public string OgrenciCinsiyet { get; set; } = "";

    [Required(ErrorMessage = "Adres zorunludur.")]
    [Display(Name = "Adres")]
    public string OgrenciAdres { get; set; } = "";

    [Required(ErrorMessage = "Telefon zorunludur.")]
    [Phone(ErrorMessage = "Geçerli bir telefon numarası girin.")]
    [Display(Name = "Telefon")]
    public string OgrenciTelefon { get; set; } = "";

    [Required(ErrorMessage = "E-posta zorunludur.")]
    [EmailAddress(ErrorMessage = "Geçerli bir e-posta adresi girin.")]
    [Display(Name = "E-posta")]
    public string OgrenciEposta { get; set; } = "";

    // ⭐ YENİ: desen (regex) kontrolü
    [Required(ErrorMessage = "TC kimlik numarası zorunludur.")]
    [RegularExpression(@"^[1-9][0-9]{10}$",
        ErrorMessage = "TC kimlik numarası 11 haneli olmalı ve 0 ile başlamamalıdır.")]
    [Display(Name = "TC kimlik no")]
    public string OgrenciTc { get; set; } = "";

    public DateTime CreatedDate { get; set; }
    public DateTime? UpdatedDate { get; set; }
    public string IsActive { get; set; } = "1";

    // JOIN ile gelecek — veritabanında yok
    [Display(Name = "Bölüm")]
    public string BolumAdi { get; set; } = "";

    // Kolaylık için hesaplanan alan
    public string TamAd => OgrenciAd + " " + OgrenciSoyad;
}
```

### 📖 Yeni kavramlar

**1. `[Range(1, 6)]`** — Sayı belirtilen aralıkta olmalı.

**2. `[DataType(DataType.Date)]`** — Tarayıcıya "bu bir tarih alanı" der. Sonuç: HTML'de `<input type="date">` üretilir ve tarayıcının **takvim seçicisi** açılır. Bedava kazanç.

**3. `[RegularExpression]`** — Düzenli ifade (regex) ile desen kontrolü.

Regex'i parçala:
```
^[1-9][0-9]{10}$
│  │      │     │
│  │      │     └─ metnin sonu
│  │      └─ 0-9 arası 10 rakam daha
│  └─ ilk karakter 1-9 arası (0 olamaz)
└─ metnin başı
```
Toplam: 1 + 10 = **11 hane**, ilki sıfır değil. TC kimlik numarasının temel kuralı.

> Öğrenciye: *"Regex korkutucu görünür ama bir kalıp dilidir. Şimdilik ezberlemenize gerek yok, kopyalayıp kullanın. İleride öğreneceksiniz."*

**4. `public string TamAd => OgrenciAd + " " + OgrenciSoyad;`**
Bu bir **hesaplanan özellik**. Veritabanında karşılığı yok, her okunduğunda hesaplanır. View'da `@ogrenci.TamAd` yazabilmek için pratik.

---

## ⌨️ Adım 2: Repository

⭐ **Bu adımı öğrenci tek başına yazsın.** Sen sadece iki noktayı hatırlat:

**Uyarı 1 — Tarih okuma:**
```csharp
o.OgrenciDogumTarihi = okuyucu.GetDateTime(okuyucu.GetOrdinal("ogrenci_dogum_tarihi"));
```
Veritabanında `DATE` tipi, C#'ta yine `DateTime` olarak okunur. Saat kısmı 00:00 gelir.

**Uyarı 2 — Sınıf okuma:**
```csharp
o.OgrenciSinif = okuyucu.GetInt32(okuyucu.GetOrdinal("ogrenci_sinif"));
```
`ogrenci_sinif` alanı `INT` (BIGINT değil!) → `GetInt32` kullanılır. `GetInt64` yazarsan `Specified cast is not valid` hatası alırsın.

**JOIN'li listeleme sorgusu** (ipucu olarak tahtaya yaz, gerisini onlar yazsın):

```sql
SELECT o.ogrenci_id, o.bolum_id, o.ogrenci_ad, o.ogrenci_soyad,
       o.ogrenci_sinif, o.ogrenci_dogum_tarihi, o.ogrenci_cinsiyet,
       o.ogrenci_adres, o.ogrenci_telefon, o.ogrenci_eposta, o.ogrenci_tc,
       o.created_date, o.updated_date, o.is_active,
       b.bolum_adi
FROM ogrenci o
INNER JOIN bolum b ON o.bolum_id = b.bolum_id
WHERE o.is_active = '1'
ORDER BY o.ogrenci_ad, o.ogrenci_soyad
```

---

## 📖 Kavram: Veritabanı hatalarını yakalamak

⭐ **Bu bölümü beraber yapın.** Modül 1'de "bunu sonra çözeceğiz" dediğimiz konu bu.

### Önce sorunu gösterin

Öğrencilere şunu yaptır:
1. Bir öğrenci ekle, e-postası `test@okul.edu.tr` olsun.
2. Bir öğrenci daha ekle, **aynı e-postayla**.

Sonuç: **Sarı hata sayfası, uygulama çöktü.**

```
SqlException: Cannot insert duplicate key row in object 'dbo.ogrenci'
with unique index 'ogrenci_ogrenci_eposta_unique'.
```

**Sor:** *"Gerçek bir sitede kullanıcıya bu ekranı gösterebilir miyiz?"*

Hayır. Üç sebeple:
1. Kullanıcı anlamaz
2. Veritabanı yapımızı ifşa eder (güvenlik açığı)
3. Kullanıcı ne yapacağını bilmez

### Çözüm: try-catch

`OgrenciController` içinde `Create` POST metodunu güncelle:

```csharp
[HttpPost]
[ValidateAntiForgeryToken]
public IActionResult Create(Ogrenci ogrenci)
{
    if (!ModelState.IsValid)
    {
        BolumListesiniHazirla(ogrenci.BolumId);
        return View(ogrenci);
    }

    try
    {
        _ogrenciRepo.Ekle(ogrenci);
        TempData["Basarili"] = "Öğrenci kaydedildi.";
        return RedirectToAction("Index");
    }
    catch (SqlException ex)
    {
        // 2627 ve 2601: benzersizlik kuralı ihlali
        if (ex.Number == 2627 || ex.Number == 2601)
        {
            // Hangi alan çakıştı? Hata metninden anlıyoruz.
            if (ex.Message.Contains("eposta"))
                ModelState.AddModelError("OgrenciEposta",
                    "Bu e-posta adresi başka bir öğrenciye kayıtlı.");
            else if (ex.Message.Contains("telefon"))
                ModelState.AddModelError("OgrenciTelefon",
                    "Bu telefon numarası başka bir öğrenciye kayıtlı.");
            else if (ex.Message.Contains("tc"))
                ModelState.AddModelError("OgrenciTc",
                    "Bu TC kimlik numarası başka bir öğrenciye kayıtlı.");
            else
                ModelState.AddModelError("", "Bu kayıt zaten mevcut.");
        }
        else
        {
            ModelState.AddModelError("",
                "Kayıt sırasında bir sorun oluştu. Lütfen tekrar deneyin.");
        }

        BolumListesiniHazirla(ogrenci.BolumId);
        return View(ogrenci);   // Kullanıcının yazdıkları korunur
    }
}
```

`using Microsoft.Data.SqlClient;` satırını controller'ın en üstüne eklemeyi unutma.

### try-catch nasıl çalışır?

```csharp
try
{
    // Riskli iş — hata verebilir
}
catch (SqlException ex)
{
    // Hata olursa buraya düşer, uygulama çökmez
    // ex → hatanın detayları
}
```

| Kavram | Anlamı |
|---|---|
| `try` | "Şunu deneyeceğim, patlayabilir" |
| `catch (SqlException ex)` | "SQL hatası olursa yakala, `ex` içinde bilgisi olsun" |
| `ex.Number` | SQL Server'ın hata kodu (2627 = benzersizlik ihlali) |
| `ModelState.AddModelError("Alan", "Mesaj")` | O alanın altında kırmızı hata mesajı gösterir |
| `ModelState.AddModelError("", "Mesaj")` | Genel hata — validation summary'de görünür |

> **Güvenlik dersi #3:** `ModelState.AddModelError("", ex.Message)` **yazmayın.** Ham hata mesajı tablo adlarını, sütun adlarını, hatta bazen bağlantı bilgilerini içerir. Saldırgana yol gösterir. Kullanıcıya her zaman kendi yazdığınız, sade bir mesaj gösterin.

> **Aynı işlemi `Edit` metodunda da yap.** Öğrenci alıştırmasında bu var.

---

## ⌨️ Adım 3: Controller

⭐ Öğrenci yazsın. Bölüm controller'ının aynısı, tek fark: açılır liste **bölümlerden** oluşacak.

```csharp
private void BolumListesiniHazirla(long? secili = null)
{
    var bolumler = _bolumRepo.TumunuGetir();

    // Fakülte adını da göstermek istersek:
    var liste = bolumler.Select(b => new {
        Id = b.BolumId,
        Ad = b.BolumAdi + " (" + b.FakulteAd + ")"
    }).ToList();

    ViewBag.Bolumler = new SelectList(liste, "Id", "Ad", secili);
}
```

> Açılır listede "Bilgisayar Mühendisliği (Mühendislik Fakültesi)" yazması, aynı adlı bölümler farklı fakültelerde varsa karışıklığı önler. Küçük ama düşünülmüş bir detay — öğrenciye bunu fark ettir.

---

## ⌨️ Adım 4: Form — yeni elemanlar

`Views/Ogrenci/Create.cshtml` — ⭐ **Beraber yazın**, yeni form elemanları burada.

```html
@model OkulYonetim.Models.Ogrenci
@{
    ViewData["Title"] = "Yeni öğrenci";
}

<div class="row">
    <div class="col-md-10">
        <div class="card border-0 shadow-sm">
            <div class="card-body">
                <form asp-action="Create" method="post">

                    @* Genel hatalar burada görünür *@
                    <div asp-validation-summary="ModelOnly" class="alert alert-danger"></div>

                    <h6 class="text-muted mb-3">Kişisel bilgiler</h6>

                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label asp-for="OgrenciAd" class="form-label"></label>
                            <input asp-for="OgrenciAd" class="form-control" />
                            <span asp-validation-for="OgrenciAd" class="text-danger small"></span>
                        </div>
                        <div class="col-md-6 mb-3">
                            <label asp-for="OgrenciSoyad" class="form-label"></label>
                            <input asp-for="OgrenciSoyad" class="form-control" />
                            <span asp-validation-for="OgrenciSoyad" class="text-danger small"></span>
                        </div>
                    </div>

                    <div class="row">
                        @* ⭐ TARİH SEÇİCİ *@
                        <div class="col-md-4 mb-3">
                            <label asp-for="OgrenciDogumTarihi" class="form-label"></label>
                            <input asp-for="OgrenciDogumTarihi" type="date" class="form-control" />
                            <span asp-validation-for="OgrenciDogumTarihi" class="text-danger small"></span>
                        </div>

                        @* ⭐ RADYO DÜĞMESİ *@
                        <div class="col-md-4 mb-3">
                            <label class="form-label">Cinsiyet</label>
                            <div>
                                <div class="form-check form-check-inline">
                                    <input class="form-check-input" type="radio"
                                           asp-for="OgrenciCinsiyet" value="Kadın" id="cinsiyetK" />
                                    <label class="form-check-label" for="cinsiyetK">Kadın</label>
                                </div>
                                <div class="form-check form-check-inline">
                                    <input class="form-check-input" type="radio"
                                           asp-for="OgrenciCinsiyet" value="Erkek" id="cinsiyetE" />
                                    <label class="form-check-label" for="cinsiyetE">Erkek</label>
                                </div>
                            </div>
                            <span asp-validation-for="OgrenciCinsiyet" class="text-danger small"></span>
                        </div>

                        @* ⭐ SAYI KUTUSU *@
                        <div class="col-md-4 mb-3">
                            <label asp-for="OgrenciSinif" class="form-label"></label>
                            <input asp-for="OgrenciSinif" type="number" min="1" max="6"
                                   class="form-control" />
                            <span asp-validation-for="OgrenciSinif" class="text-danger small"></span>
                        </div>
                    </div>

                    <div class="mb-3">
                        <label asp-for="OgrenciTc" class="form-label"></label>
                        <input asp-for="OgrenciTc" class="form-control"
                               maxlength="11" placeholder="11 haneli TC kimlik numarası" />
                        <span asp-validation-for="OgrenciTc" class="text-danger small"></span>
                    </div>

                    <hr class="my-4" />
                    <h6 class="text-muted mb-3">İletişim ve kayıt bilgileri</h6>

                    <div class="mb-3">
                        <label asp-for="BolumId" class="form-label"></label>
                        <select asp-for="BolumId" asp-items="ViewBag.Bolumler" class="form-select">
                            <option value="">-- Bölüm seçin --</option>
                        </select>
                        <span asp-validation-for="BolumId" class="text-danger small"></span>
                    </div>

                    <div class="mb-3">
                        <label asp-for="OgrenciAdres" class="form-label"></label>
                        <textarea asp-for="OgrenciAdres" class="form-control" rows="2"></textarea>
                        <span asp-validation-for="OgrenciAdres" class="text-danger small"></span>
                    </div>

                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label asp-for="OgrenciTelefon" class="form-label"></label>
                            <input asp-for="OgrenciTelefon" class="form-control" />
                            <span asp-validation-for="OgrenciTelefon" class="text-danger small"></span>
                        </div>
                        <div class="col-md-6 mb-3">
                            <label asp-for="OgrenciEposta" class="form-label"></label>
                            <input asp-for="OgrenciEposta" class="form-control" />
                            <span asp-validation-for="OgrenciEposta" class="text-danger small"></span>
                        </div>
                    </div>

                    <hr />
                    <button type="submit" class="btn btn-primary">
                        <i class="bi bi-check-lg"></i> Öğrenciyi kaydet
                    </button>
                    <a asp-action="Index" class="btn btn-outline-secondary">Vazgeç</a>

                </form>
            </div>
        </div>
    </div>
</div>

@section Scripts {
    <partial name="_ValidationScriptsPartial" />
}
```

### Form elemanları özeti

| İhtiyaç | HTML | Not |
|---|---|---|
| Metin | `<input asp-for="X" />` | Varsayılan |
| Uzun metin | `<textarea asp-for="X" rows="3">` | Adres için |
| Sayı | `<input asp-for="X" type="number" min="1" max="6" />` | |
| Tarih | `<input asp-for="X" type="date" />` | Takvim açılır |
| Seçim listesi | `<select asp-for="X" asp-items="ViewBag.Y">` | Çok seçenek varsa |
| Radyo | `<input type="radio" asp-for="X" value="Kadın" />` | 2-3 seçenek varsa |
| Onay kutusu | `<input type="checkbox" asp-for="X" />` | `bool` alanlar için |

> **Tasarım sorusu — öğrenciye sor:** *"Cinsiyeti neden açılır liste değil de radyo düğmesi yaptık?"*
> Cevap: 2-3 seçenek varsa radyo daha hızlıdır — kullanıcı tek tıkla seçer, açılır listede iki tık gerekir. 5'ten fazla seçenekte açılır liste daha uygun olur.

---

## ⌨️ Adım 5: Liste

`Views/Ogrenci/Index.cshtml` içinde tabloya ekleyebileceğin faydalı sütunlar:

```html
<td>@ogrenci.TamAd</td>

<td>
    <span class="badge bg-info">@ogrenci.OgrenciSinif. sınıf</span>
</td>

<td>@ogrenci.OgrenciDogumTarihi.ToString("dd.MM.yyyy")</td>

@* Yaş hesabı — Razor içinde küçük hesap *@
<td>
    @{
        var yas = DateTime.Today.Year - ogrenci.OgrenciDogumTarihi.Year;
        if (ogrenci.OgrenciDogumTarihi.Date > DateTime.Today.AddYears(-yas))
            yas--;   // doğum günü henüz gelmediyse bir yaş düş
    }
    @yas
</td>

@* TC'yi maskele — gizlilik *@
<td>@ogrenci.OgrenciTc.Substring(0, 3)********</td>
```

> **Gizlilik notu — anlatmaya değer:** TC kimlik numarası kişisel veridir. Listede tam gösterilmesi gerekmez. Gerçek projelerde KVKK gereği bu tür veriler maskelenir veya yalnızca yetkili kullanıcılara gösterilir. Küçük bir `Substring` ile başlayan bu bilinç, öğrencinin ilerideki projelerinde işine yarar.

---

## ▶️ Çalıştır ve gör — test senaryoları

Öğrencilerin **kendi kendine** test etmesi gereken senaryolar (tahtaya yaz):

| # | Test | Beklenen sonuç |
|---|---|---|
| 1 | Boş form gönder | Tüm alanlarda kırmızı hata |
| 2 | TC'ye `123` yaz | "11 haneli olmalı" hatası |
| 3 | TC'ye `01234567890` yaz | "0 ile başlamamalı" hatası |
| 4 | Sınıfa `9` yaz | "1 ile 6 arasında olmalı" hatası |
| 5 | E-postaya `abc` yaz | "Geçerli bir e-posta girin" hatası |
| 6 | Aynı e-postayı ikinci kez kaydet | Kırmızı uyarı, **çökme yok** |
| 7 | Aynı TC'yi ikinci kez kaydet | Kırmızı uyarı, **çökme yok** |
| 8 | Hatalı gönderimden sonra | Açılır liste dolu, yazılanlar duruyor |
| 9 | Doğru doldur, kaydet | Listeye dön, yeşil mesaj |
| 10 | Düzenle, kaydet | `updated_date` doldu mu? (SSMS'ten bak) |

---

## ⚠️ Sık yapılan hatalar

| Hata | Sebep | Çözüm |
|---|---|---|
| `Specified cast is not valid` | `ogrenci_sinif` INT ama `GetInt64` kullanılmış | `GetInt32` kullan |
| Tarih alanı boş geliyor | `type="date"` yok | `<input type="date" />` ekle |
| Tarih formatı hatası | Tarayıcı dili farklı | `type="date"` kullanıldığında sorun çıkmaz |
| Radyo düğmesi seçili gelmiyor (Edit'te) | `asp-for` doğru kullanılmamış | `asp-for` + `value` birlikte olmalı, ASP.NET Core eşleşeni işaretler |
| `SqlException` sayfası hâlâ çıkıyor | `try-catch` yok veya `Edit`'e eklenmemiş | Her iki POST metoduna da ekle |
| `The name 'SqlException' does not exist` | `using` eksik | `using Microsoft.Data.SqlClient;` ekle |
| TC regex çalışmıyor | `@` öneki unutulmuş | `@"^[1-9][0-9]{10}$"` — başındaki `@` şart |
| `Substring` hatası (TC maskeleme) | TC 3 karakterden kısa | Önce uzunluk kontrolü yap veya veriyi düzelt |
| Cinsiyet kaydolmuyor | Radyo düğmelerinin `name` değeri farklı | `asp-for` kullan, elle `name` yazma |

---

## ✏️ Öğrenci alıştırması

**A. Tamamlama (ders içinde bitmezse ödev)**
Öğrenci CRUD'unun tamamı çalışır durumda olmalı.

**B. Edit için try-catch**
`Edit` POST metoduna da benzersizlik hatası yakalamayı ekle. `Create`'tekiyle aynı mantık.
*Ekstra düşünce:* Bir öğrenciyi düzenlerken kendi e-postasını değiştirmezse hata almamalı. Neden almıyor?

**C. Detay sayfası**
`Details` sayfası yaz. Öğrencinin tüm bilgileri, bölümü, fakültesi ve yaşı görünsün.

**D. TC doğrulama algoritması (zorlayıcı)**
TC kimlik numarasının gerçek bir doğrulama algoritması vardır:
- 11 hane, ilki 0 olamaz
- İlk 10 hanenin toplamının birler basamağı = 11. hane
- (1,3,5,7,9. hanelerin toplamı × 7 − 2,4,6,8,10. hanelerin toplamı) mod 10 = 10. hane

Bu kuralı uygulayan özel bir doğrulama özniteliği yaz:

```csharp
public class TcKimlikAttribute : ValidationAttribute
{
    public override bool IsValid(object? value)
    {
        string? tc = value?.ToString();
        if (string.IsNullOrEmpty(tc) || tc.Length != 11) return false;
        if (!tc.All(char.IsDigit)) return false;
        if (tc[0] == '0') return false;

        int[] h = tc.Select(c => c - '0').ToArray();

        int tek = h[0] + h[2] + h[4] + h[6] + h[8];
        int cift = h[1] + h[3] + h[5] + h[7];

        if ((tek * 7 - cift) % 10 != h[9]) return false;
        if (h.Take(10).Sum() % 10 != h[10]) return false;

        return true;
    }
}
```

Kullanımı:
```csharp
[TcKimlik(ErrorMessage = "Geçersiz TC kimlik numarası.")]
public string OgrenciTc { get; set; } = "";
```

Test için geçerli örnek: `10000000146`

**E. Düşünme soruları**
1. Doğrulama hem tarayıcıda hem sunucuda yapılıyor. İkisi de gerekli mi? Birini kaldırırsak ne olur?
2. F12 ile HTML'i değiştirip `maxlength="11"` sınırını kaldırdım. 20 haneli TC gönderebilir miyim? Neden?
3. `try-catch` ile hata yakalamak yerine, kayıt eklemeden önce "bu e-posta var mı?" diye sorgu atsaydık ne fark ederdi? Hangisi daha iyi?
   *(İpucu: iki kullanıcı aynı anda kaydederse ne olur? Bu duruma "yarış koşulu / race condition" denir.)*

---

## Sonraki adım

👉 [`09-akademisyen-odev.md`](09-akademisyen-odev.md) — Tamamen öğrencinin.
