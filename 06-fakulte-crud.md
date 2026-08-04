# Modül 5 — Fakülte CRUD (Ana Kalıp)

**Süre:** 2 ders saati
**Ön koşul:** Modül 4 (layout hazır)

---

## 🎯 Bu derste ne yapacağız

Fakülte kayıtlarını **ekleyeceğiz, düzenleyeceğiz, sileceğiz.** Yani tam bir CRUD.

> ⭐ **Bu modül kursun kalbi.** Buradaki 7 metotluk kalıp, kalan üç tabloda birebir tekrarlanacak. Öğrenci bu kalıbı kavrarsa gerisi mekanik. Acele etme.

**Ders sonunda öğrenci:** CRUD kalıbının 7 parçasını ezberden sayabilecek.

---

## 📖 Kavram 1: CRUD nedir?

| Harf | İngilizce | Türkçe | SQL | Bizim metot |
|---|---|---|---|---|
| **C** | Create | Oluştur | `INSERT` | `Ekle()` |
| **R** | Read | Oku | `SELECT` | `TumunuGetir()`, `IdIleGetir()` |
| **U** | Update | Güncelle | `UPDATE` | `Guncelle()` |
| **D** | Delete | Sil | `UPDATE is_active='0'` | `PasifYap()` |

> *"Dünyadaki her yönetim uygulamasının %80'i bu dört işlemden ibarettir. Bunu öğrendiğinizde web programlamanın temelini öğrenmiş olursunuz."*

---

## 📖 Kavram 2: GET ve POST

Bu ayrımı **mutlaka** anlat, yoksa öğrenci controller'da neden iki tane `Create` metodu olduğunu asla anlamaz.

```
┌──────────────────────────────────┬──────────────────────────────────┐
│              GET                 │              POST                │
├──────────────────────────────────┼──────────────────────────────────┤
│ "Bana bir şey göster"            │ "Al şu veriyi, kaydet"           │
│ Adres çubuğuna yazılır           │ Form gönderilince olur           │
│ Veri adreste görünür             │ Veri gizli gider                 │
│ Yenilenebilir, zararsız          │ Yenilersen ikinci kez kaydeder   │
│ /Fakulte/Create → boş form       │ /Fakulte/Create → kaydet         │
└──────────────────────────────────┴──────────────────────────────────┘
```

**Aynı adres, iki farklı iş.** Bu yüzden controller'da iki `Create` metodu olacak:

```csharp
public IActionResult Create()              // GET  → formu göster

[HttpPost]
public IActionResult Create(Fakulte f)     // POST → kaydet
```

**Benzetme:** *"Bankaya gidip 'para yatırma formu verir misiniz?' demek GET'tir. Doldurup geri vermek POST'tur. Aynı gişe, iki farklı iş."*

---

## 📖 Kavram 3: SQL Injection — güvenlik dersi

**Bu 10 dakikayı atlama.** Öğrencinin ilk gerçek güvenlik dersi.

Diyelim kullanıcı adına göre arama yapıyoruz ve SQL'i şöyle yazdık:

```csharp
// ❌❌❌ ASLA BÖYLE YAPMAYIN
string sql = "SELECT * FROM fakulte WHERE fakulte_ad = '" + aramaMetni + "'";
```

Kullanıcı arama kutusuna şunu yazarsa:
```
'; DROP TABLE fakulte; --
```

Oluşan SQL:
```sql
SELECT * FROM fakulte WHERE fakulte_ad = ''; DROP TABLE fakulte; --'
```

**Tablo silinir.** 💀

### Çözüm: Parametreli sorgu

```csharp
// ✅ DOĞRU
string sql = "SELECT * FROM fakulte WHERE fakulte_ad = @ad";
komut.Parameters.AddWithValue("@ad", aramaMetni);
```

**Neden güvenli?**
> *"Parametre kullandığınızda SQL Server, gelen değeri 'komut' olarak değil, sadece 'veri' olarak görür. İçinde ne yazarsa yazsın, sadece aranacak metin olarak kabul eder."*

**Kural (tahtaya yaz, dersin sonuna kadar sil me):**
> **SQL içine `+` ile hiçbir zaman değer eklemeyin. Her değer bir parametre olacak.**

---

## ⌨️ Adım 1: Repository'yi tamamla

`Data/FakulteRepository.cs` dosyasına Modül 3'teki `TumunuGetir()` metodunun yanına diğer metotları ekliyoruz.

Önce, tekrarı azaltmak için bir yardımcı metot yazalım:

```csharp
    /// <summary>
    /// SqlDataReader'dan gelen bir satırı Fakulte nesnesine çevirir.
    /// Aynı kodu her metotta tekrar yazmamak için ayrı metot yaptık.
    /// </summary>
    private Fakulte SatiriNesneyeCevir(SqlDataReader okuyucu)
    {
        Fakulte f = new Fakulte();

        f.FakulteId      = okuyucu.GetInt64(okuyucu.GetOrdinal("fakulte_id"));
        f.FakulteAd      = okuyucu.GetString(okuyucu.GetOrdinal("fakulte_ad"));
        f.FakulteAdres   = okuyucu.GetString(okuyucu.GetOrdinal("fakulte_adres"));
        f.FakulteTelefon = okuyucu.GetString(okuyucu.GetOrdinal("fakulte_telefon"));
        f.FakulteEposta  = okuyucu.GetString(okuyucu.GetOrdinal("fakulte_eposta"));
        f.CreatedDate    = okuyucu.GetDateTime(okuyucu.GetOrdinal("created_date"));
        f.IsActive       = okuyucu.GetString(okuyucu.GetOrdinal("is_active"));

        int sutunNo = okuyucu.GetOrdinal("updated_date");
        f.UpdatedDate = okuyucu.IsDBNull(sutunNo) ? null : okuyucu.GetDateTime(sutunNo);

        return f;
    }
```

> Şimdi `TumunuGetir()` içindeki uzun atama bloğunu silip yerine `liste.Add(SatiriNesneyeCevir(okuyucu));` yazabilirsin. Öğrenciye **tekrarı azaltmanın (DRY prensibi)** güzel bir örneği olarak göster.

### 📥 READ — Tek kayıt getir

Düzenleme sayfası için tek bir fakülteye ihtiyacımız var:

```csharp
    /// <summary>
    /// Verilen id'ye sahip fakülteyi getirir. Bulunamazsa null döner.
    /// </summary>
    public Fakulte? IdIleGetir(long id)
    {
        Fakulte? sonuc = null;

        string sql = @"SELECT fakulte_id, fakulte_ad, fakulte_adres,
                              fakulte_telefon, fakulte_eposta,
                              created_date, updated_date, is_active
                       FROM fakulte
                       WHERE fakulte_id = @id";

        using (SqlConnection baglanti = new SqlConnection(_baglantiMetni))
        using (SqlCommand komut = new SqlCommand(sql, baglanti))
        {
            // ⭐ Parametre: değeri SQL metnine YAPIŞTIRMIYORUZ
            komut.Parameters.AddWithValue("@id", id);

            baglanti.Open();
            using (SqlDataReader okuyucu = komut.ExecuteReader())
            {
                if (okuyucu.Read())          // while değil, if — tek satır bekliyoruz
                {
                    sonuc = SatiriNesneyeCevir(okuyucu);
                }
            }
        }

        return sonuc;
    }
```

> **`Fakulte?` sonundaki `?`:** "Bu metot null dönebilir" demek. Olmayan bir id sorulursa `null` döner. Controller bunu kontrol etmek zorunda.

### ➕ CREATE — Yeni kayıt ekle

```csharp
    /// <summary>
    /// Yeni fakülte ekler.
    /// </summary>
    public void Ekle(Fakulte fakulte)
    {
        // DİKKAT: fakulte_id yazmıyoruz! IDENTITY olduğu için SQL Server kendi veriyor.
        string sql = @"INSERT INTO fakulte
                          (fakulte_ad, fakulte_adres, fakulte_telefon,
                           fakulte_eposta, created_date, updated_date, is_active)
                       VALUES
                          (@ad, @adres, @telefon, @eposta, @createdDate, NULL, @isActive)";

        using (SqlConnection baglanti = new SqlConnection(_baglantiMetni))
        using (SqlCommand komut = new SqlCommand(sql, baglanti))
        {
            komut.Parameters.AddWithValue("@ad",          fakulte.FakulteAd);
            komut.Parameters.AddWithValue("@adres",       fakulte.FakulteAdres);
            komut.Parameters.AddWithValue("@telefon",     fakulte.FakulteTelefon);
            komut.Parameters.AddWithValue("@eposta",      fakulte.FakulteEposta);
            komut.Parameters.AddWithValue("@createdDate", DateTime.Now);  // ⭐ tarihi biz veriyoruz
            komut.Parameters.AddWithValue("@isActive",    "1");           // ⭐ yeni kayıt aktiftir

            baglanti.Open();
            komut.ExecuteNonQuery();   // Veri dönmeyen komutlar için: INSERT, UPDATE, DELETE
        }
    }
```

**Üç noktaya dikkat çek:**

1. **`ExecuteNonQuery()`** — "sonuç satırı beklemiyorum" demek. `SELECT` için `ExecuteReader()`, `INSERT/UPDATE/DELETE` için `ExecuteNonQuery()`.
2. **`created_date`'i biz dolduruyoruz** — kullanıcıdan istemiyoruz, sistem tarihini kullanıyoruz. Kullanıcı bunu değiştirebilseydi kayıt geçmişi güvenilmez olurdu.
3. **`is_active = "1"`** — her yeni kayıt aktif başlar.

### ✏️ UPDATE — Kaydı güncelle

```csharp
    /// <summary>
    /// Var olan fakülteyi günceller.
    /// </summary>
    public void Guncelle(Fakulte fakulte)
    {
        string sql = @"UPDATE fakulte
                       SET fakulte_ad      = @ad,
                           fakulte_adres   = @adres,
                           fakulte_telefon = @telefon,
                           fakulte_eposta  = @eposta,
                           updated_date    = @updatedDate
                       WHERE fakulte_id    = @id";

        using (SqlConnection baglanti = new SqlConnection(_baglantiMetni))
        using (SqlCommand komut = new SqlCommand(sql, baglanti))
        {
            komut.Parameters.AddWithValue("@ad",          fakulte.FakulteAd);
            komut.Parameters.AddWithValue("@adres",       fakulte.FakulteAdres);
            komut.Parameters.AddWithValue("@telefon",     fakulte.FakulteTelefon);
            komut.Parameters.AddWithValue("@eposta",      fakulte.FakulteEposta);
            komut.Parameters.AddWithValue("@updatedDate", DateTime.Now);
            komut.Parameters.AddWithValue("@id",          fakulte.FakulteId);

            baglanti.Open();
            komut.ExecuteNonQuery();
        }
    }
```

> 🚨 **En tehlikeli hata — mutlaka göster:**
> `WHERE` satırını **unutursanız**, tablodaki **BÜTÜN** fakülteler aynı isme dönüşür.
>
> Bunu SSMS'te canlı göster (test verisinde, geri alınabilir bir ortamda):
> ```sql
> UPDATE fakulte SET fakulte_ad = 'Hepsi Aynı Oldu';   -- WHERE yok!
> SELECT * FROM fakulte;   -- felaket
> ```
> Öğrenci bu görüntüyü unutmaz. Sonra test verisini yeniden yükle.

### 🗑️ DELETE — Yumuşak silme

```csharp
    /// <summary>
    /// Kaydı gerçekten silmez, pasif duruma alır (soft delete).
    /// </summary>
    public void PasifYap(long id)
    {
        string sql = @"UPDATE fakulte
                       SET is_active = '0',
                           updated_date = @updatedDate
                       WHERE fakulte_id = @id";

        using (SqlConnection baglanti = new SqlConnection(_baglantiMetni))
        using (SqlCommand komut = new SqlCommand(sql, baglanti))
        {
            komut.Parameters.AddWithValue("@updatedDate", DateTime.Now);
            komut.Parameters.AddWithValue("@id", id);

            baglanti.Open();
            komut.ExecuteNonQuery();
        }
    }
```

> **Hatırlat:** Bu bir `DELETE` değil, `UPDATE`. Veri duruyor, sadece listede görünmüyor. `TumunuGetir()` içindeki `WHERE is_active = '1'` filtresi bunu sağlıyor.

---

## ⌨️ Adım 2: Model'e doğrulama kuralları ekle

`Models/Fakulte.cs` dosyasını güncelle:

```csharp
using System.ComponentModel.DataAnnotations;

namespace OkulYonetim.Models;

public class Fakulte
{
    public long FakulteId { get; set; }

    [Required(ErrorMessage = "Fakülte adı zorunludur.")]
    [StringLength(255, ErrorMessage = "Fakülte adı en fazla 255 karakter olabilir.")]
    [Display(Name = "Fakülte adı")]
    public string FakulteAd { get; set; } = "";

    [Required(ErrorMessage = "Adres zorunludur.")]
    [Display(Name = "Adres")]
    public string FakulteAdres { get; set; } = "";

    [Required(ErrorMessage = "Telefon zorunludur.")]
    [Phone(ErrorMessage = "Geçerli bir telefon numarası girin.")]
    [Display(Name = "Telefon")]
    public string FakulteTelefon { get; set; } = "";

    [Required(ErrorMessage = "E-posta zorunludur.")]
    [EmailAddress(ErrorMessage = "Geçerli bir e-posta adresi girin.")]
    [Display(Name = "E-posta")]
    public string FakulteEposta { get; set; } = "";

    public DateTime CreatedDate { get; set; }
    public DateTime? UpdatedDate { get; set; }
    public string IsActive { get; set; } = "1";
}
```

### 📖 Kavram: Data Annotation

Köşeli parantez içindekilere **öznitelik (attribute)** denir. Sınıfa "etiket yapıştırmak" gibidir.

| Öznitelik | Ne yapar |
|---|---|
| `[Required]` | Boş bırakılamaz |
| `[StringLength(255)]` | En fazla 255 karakter |
| `[EmailAddress]` | E-posta formatında olmalı |
| `[Phone]` | Telefon formatında olmalı |
| `[Display(Name="...")]` | Ekranda görünecek etiket adı |
| `[Range(1, 4)]` | Sayı 1-4 arasında olmalı |

**Bu özniteliklerin gücü:** Tek bir yere yazıyorsun, hem sunucu tarafı hem tarayıcı tarafı doğrulama otomatik çalışıyor.

---

## ⌨️ Adım 3: Controller'ı tamamla

`Controllers/FakulteController.cs`:

```csharp
using Microsoft.AspNetCore.Mvc;
using OkulYonetim.Data;
using OkulYonetim.Models;

namespace OkulYonetim.Controllers;

public class FakulteController : Controller
{
    private readonly FakulteRepository _repo;

    public FakulteController(FakulteRepository repo)
    {
        _repo = repo;
    }

    // ═══════════════════════════════════════════
    // 1) LİSTELEME
    // GET: /Fakulte
    // ═══════════════════════════════════════════
    public IActionResult Index()
    {
        var fakulteler = _repo.TumunuGetir();
        return View(fakulteler);
    }

    // ═══════════════════════════════════════════
    // 2) YENİ KAYIT FORMU (boş form göster)
    // GET: /Fakulte/Create
    // ═══════════════════════════════════════════
    public IActionResult Create()
    {
        return View();
    }

    // ═══════════════════════════════════════════
    // 3) YENİ KAYDI KAYDET
    // POST: /Fakulte/Create
    // ═══════════════════════════════════════════
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Create(Fakulte fakulte)
    {
        // Model'deki kurallara uyuyor mu?
        if (!ModelState.IsValid)
        {
            // Uymuyorsa formu geri göster — kullanıcının yazdıkları kaybolmasın
            return View(fakulte);
        }

        _repo.Ekle(fakulte);

        // Başarı mesajı (bir sonraki sayfada gösterilecek)
        TempData["Basarili"] = "Fakülte kaydedildi.";

        // Listeye geri dön
        return RedirectToAction("Index");
    }

    // ═══════════════════════════════════════════
    // 4) DÜZENLEME FORMU (dolu form göster)
    // GET: /Fakulte/Edit/5
    // ═══════════════════════════════════════════
    public IActionResult Edit(long id)
    {
        var fakulte = _repo.IdIleGetir(id);

        if (fakulte == null)
        {
            return NotFound();   // 404 sayfası
        }

        return View(fakulte);
    }

    // ═══════════════════════════════════════════
    // 5) DÜZENLEMEYİ KAYDET
    // POST: /Fakulte/Edit/5
    // ═══════════════════════════════════════════
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Edit(Fakulte fakulte)
    {
        if (!ModelState.IsValid)
        {
            return View(fakulte);
        }

        _repo.Guncelle(fakulte);
        TempData["Basarili"] = "Fakülte güncellendi.";
        return RedirectToAction("Index");
    }

    // ═══════════════════════════════════════════
    // 6) SİLME ONAY SAYFASI
    // GET: /Fakulte/Delete/5
    // ═══════════════════════════════════════════
    public IActionResult Delete(long id)
    {
        var fakulte = _repo.IdIleGetir(id);

        if (fakulte == null)
        {
            return NotFound();
        }

        return View(fakulte);
    }

    // ═══════════════════════════════════════════
    // 7) SİLMEYİ ONAYLA
    // POST: /Fakulte/Delete/5
    // ═══════════════════════════════════════════
    [HttpPost, ActionName("Delete")]
    [ValidateAntiForgeryToken]
    public IActionResult DeleteConfirmed(long id)
    {
        _repo.PasifYap(id);
        TempData["Basarili"] = "Fakülte silindi.";
        return RedirectToAction("Index");
    }
}
```

### Üç önemli kavram

**1. `ModelState.IsValid` nedir?**
Model'e yazdığımız `[Required]`, `[EmailAddress]` gibi kurallara uyulup uyulmadığını söyler. ASP.NET Core bunu otomatik kontrol eder.

> **Kritik:** Tarayıcı tarafındaki doğrulama kandırılabilir (F12 ile HTML değiştirilebilir). Bu yüzden sunucuda **tekrar** kontrol etmek zorundayız. *"Tarayıcıya asla güvenme"* — güvenlik dersi #2.

**2. `RedirectToAction` neden gerekli?**
Kaydettikten sonra `return View()` yazarsak kullanıcı F5'e bastığında **aynı kayıt ikinci kez eklenir**. Yönlendirme yaparak bunu engelleriz.

Bu kalıbın adı **POST-Redirect-GET**:
```
POST /Fakulte/Create  →  kaydet  →  302 yönlendirme  →  GET /Fakulte
```
Böylece kullanıcı F5'e bastığında sadece listeyi yeniler.

**3. `[ValidateAntiForgeryToken]` nedir?**
CSRF saldırısına karşı koruma. Kötü niyetli bir site, sizin oturumunuzu kullanarak bizim formumuza gizlice veri gönderemesin diye. Form içindeki gizli bir güvenlik anahtarını doğrular.

> Öğrenciye: *"Şimdilik 'güvenlik için gerekli, her POST metoduna yazacağız' demeniz yeterli. Ayrıntısını ileri seviye derslerde öğreneceksiniz."*

**4. `[HttpPost, ActionName("Delete")]` neden?**
C#'ta aynı isim ve aynı parametrelerle iki metot olamaz. `Delete(long id)` zaten var. İkincisine `DeleteConfirmed` adını verdik ama `ActionName("Delete")` diyerek "adres olarak yine Delete kullanılsın" dedik.

---

## ⌨️ Adım 4: View'ları yaz

### Create.cshtml

`Views/Fakulte/Create.cshtml`:

```html
@model OkulYonetim.Models.Fakulte
@{
    ViewData["Title"] = "Yeni fakülte";
}

<div class="row">
    <div class="col-md-8">
        <div class="card border-0 shadow-sm">
            <div class="card-body">

                <form asp-action="Create" method="post">

                    @* Genel hata özeti *@
                    <div asp-validation-summary="ModelOnly" class="alert alert-danger d-none"></div>

                    <div class="mb-3">
                        <label asp-for="FakulteAd" class="form-label"></label>
                        <input asp-for="FakulteAd" class="form-control" />
                        <span asp-validation-for="FakulteAd" class="text-danger small"></span>
                    </div>

                    <div class="mb-3">
                        <label asp-for="FakulteAdres" class="form-label"></label>
                        <textarea asp-for="FakulteAdres" class="form-control" rows="3"></textarea>
                        <span asp-validation-for="FakulteAdres" class="text-danger small"></span>
                    </div>

                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label asp-for="FakulteTelefon" class="form-label"></label>
                            <input asp-for="FakulteTelefon" class="form-control"
                                   placeholder="02121234567" />
                            <span asp-validation-for="FakulteTelefon" class="text-danger small"></span>
                        </div>

                        <div class="col-md-6 mb-3">
                            <label asp-for="FakulteEposta" class="form-label"></label>
                            <input asp-for="FakulteEposta" class="form-control"
                                   placeholder="ornek@okul.edu.tr" />
                            <span asp-validation-for="FakulteEposta" class="text-danger small"></span>
                        </div>
                    </div>

                    <hr />

                    <button type="submit" class="btn btn-primary">
                        <i class="bi bi-check-lg"></i> Fakülteyi kaydet
                    </button>
                    <a asp-action="Index" class="btn btn-outline-secondary">Vazgeç</a>

                </form>

            </div>
        </div>
    </div>
</div>

@section Scripts {
    @* Tarayıcı tarafı doğrulama scriptleri *@
    <partial name="_ValidationScriptsPartial" />
}
```

### Form Tag Helper'ları — satır satır açıkla

| Yazdığımız | Ne oluyor |
|---|---|
| `asp-for="FakulteAd"` | `name`, `id`, `value` niteliklerini **otomatik** üretir |
| `<label asp-for="...">` | `[Display(Name="...")]`'deki metni yazar |
| `<span asp-validation-for="...">` | O alanın hata mesajını gösterir |
| `asp-action="Create"` | Formun nereye gönderileceğini belirler |
| `asp-validation-summary="ModelOnly"` | Alan bazlı olmayan genel hataları listeler |

**Canlı gösteri:** Sayfayı aç, sağ tık → sayfa kaynağını görüntüle. `asp-for="FakulteAd"` yazdığımız satırın şuna dönüştüğünü göster:

```html
<input class="form-control" type="text" data-val="true"
       data-val-required="Fakülte adı zorunludur."
       id="FakulteAd" name="FakulteAd" value="" />
```

> *"Bir satır yazdık, ASP.NET Core bunların hepsini üretti."* Öğrenci Tag Helper'ların değerini burada anlar.

### Edit.cshtml

`Views/Fakulte/Edit.cshtml` — Create'in neredeyse aynısı, **tek fark gizli id alanı**:

```html
@model OkulYonetim.Models.Fakulte
@{
    ViewData["Title"] = "Fakülteyi düzenle";
}

<div class="row">
    <div class="col-md-8">
        <div class="card border-0 shadow-sm">
            <div class="card-body">

                <form asp-action="Edit" method="post">

                    @* ⭐ ÇOK ÖNEMLİ: Hangi kaydı güncellediğimizi taşır.
                       Bu satır olmazsa id sıfır gelir ve güncelleme çalışmaz. *@
                    <input type="hidden" asp-for="FakulteId" />

                    @* Kayıt tarihi de korunmalı, aksi halde formda kaybolur *@
                    <input type="hidden" asp-for="CreatedDate" />
                    <input type="hidden" asp-for="IsActive" />

                    <div class="mb-3">
                        <label asp-for="FakulteAd" class="form-label"></label>
                        <input asp-for="FakulteAd" class="form-control" />
                        <span asp-validation-for="FakulteAd" class="text-danger small"></span>
                    </div>

                    <div class="mb-3">
                        <label asp-for="FakulteAdres" class="form-label"></label>
                        <textarea asp-for="FakulteAdres" class="form-control" rows="3"></textarea>
                        <span asp-validation-for="FakulteAdres" class="text-danger small"></span>
                    </div>

                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label asp-for="FakulteTelefon" class="form-label"></label>
                            <input asp-for="FakulteTelefon" class="form-control" />
                            <span asp-validation-for="FakulteTelefon" class="text-danger small"></span>
                        </div>
                        <div class="col-md-6 mb-3">
                            <label asp-for="FakulteEposta" class="form-label"></label>
                            <input asp-for="FakulteEposta" class="form-control" />
                            <span asp-validation-for="FakulteEposta" class="text-danger small"></span>
                        </div>
                    </div>

                    <div class="text-muted small mb-3">
                        Kayıt tarihi: @Model.CreatedDate.ToString("dd.MM.yyyy HH:mm")
                        @if (Model.UpdatedDate.HasValue)
                        {
                            <span> | Son güncelleme: @Model.UpdatedDate.Value.ToString("dd.MM.yyyy HH:mm")</span>
                        }
                    </div>

                    <hr />

                    <button type="submit" class="btn btn-primary">
                        <i class="bi bi-check-lg"></i> Değişiklikleri kaydet
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

> **Eğitmen numarası:** `<input type="hidden" asp-for="FakulteId" />` satırını bilerek sil ve düzenlemeyi dene. Hiçbir şey güncellenmez (çünkü `WHERE fakulte_id = 0`). Sonra geri ekle. Öğrenci gizli alanların ne işe yaradığını böyle anlar.

### Delete.cshtml

```html
@model OkulYonetim.Models.Fakulte
@{
    ViewData["Title"] = "Fakülteyi sil";
}

<div class="row">
    <div class="col-md-7">
        <div class="card border-danger shadow-sm">
            <div class="card-header bg-danger text-white">
                <i class="bi bi-exclamation-triangle"></i> Silme onayı
            </div>
            <div class="card-body">

                <p>Bu fakülteyi silmek üzeresiniz:</p>

                <dl class="row mb-4">
                    <dt class="col-sm-3">Fakülte adı</dt>
                    <dd class="col-sm-9">@Model.FakulteAd</dd>

                    <dt class="col-sm-3">Telefon</dt>
                    <dd class="col-sm-9">@Model.FakulteTelefon</dd>

                    <dt class="col-sm-3">E-posta</dt>
                    <dd class="col-sm-9">@Model.FakulteEposta</dd>
                </dl>

                <div class="alert alert-warning small">
                    <i class="bi bi-info-circle"></i>
                    Kayıt veritabanından tamamen silinmez, pasif duruma alınır.
                    Bu fakülteye bağlı bölümler listede kalmaya devam eder.
                </div>

                <form asp-action="Delete" method="post">
                    <input type="hidden" asp-for="FakulteId" name="id" />

                    <button type="submit" class="btn btn-danger">
                        <i class="bi bi-trash"></i> Evet, sil
                    </button>
                    <a asp-action="Index" class="btn btn-outline-secondary">Vazgeç</a>
                </form>

            </div>
        </div>
    </div>
</div>
```

> **Tasarım kararı — tartışmaya açık:** Silmeden önce ayrı bir onay sayfası göstermek klasik yöntemdir. Modül 11'de bunu bir modal (açılır pencere) ile değiştireceğiz. Öğrenciye ikisini de gösterip "hangisi daha iyi kullanıcı deneyimi?" diye sor.

### Index.cshtml'i güncelle

Butonları artık gerçek adreslere bağlayalım ve başarı mesajını ekleyelim:

```html
@model List<OkulYonetim.Models.Fakulte>
@{
    ViewData["Title"] = "Fakülteler";
}

@* Başarı mesajı — TempData'dan geliyor *@
@if (TempData["Basarili"] != null)
{
    <div class="alert alert-success alert-dismissible fade show">
        <i class="bi bi-check-circle"></i> @TempData["Basarili"]
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
}

<div class="card border-0 shadow-sm">
    <div class="card-header bg-white d-flex justify-content-between align-items-center">
        <span class="fw-semibold">Kayıtlı fakülteler (@Model.Count)</span>
        <a asp-action="Create" class="btn btn-primary btn-sm">
            <i class="bi bi-plus-lg"></i> Yeni fakülte
        </a>
    </div>

    <div class="card-body p-0">
        @if (Model.Count == 0)
        {
            <div class="text-center text-muted py-5">
                <i class="bi bi-inbox fs-1 d-block mb-2"></i>
                Henüz fakülte eklenmemiş. Yukarıdaki butondan ilk kaydı oluşturun.
            </div>
        }
        else
        {
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                    <tr>
                        <th>#</th>
                        <th>Fakülte adı</th>
                        <th>Telefon</th>
                        <th>E-posta</th>
                        <th>Kayıt tarihi</th>
                        <th class="text-end">İşlemler</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach (var fakulte in Model)
                    {
                        <tr>
                            <td>@fakulte.FakulteId</td>
                            <td class="fw-semibold">@fakulte.FakulteAd</td>
                            <td>@fakulte.FakulteTelefon</td>
                            <td>@fakulte.FakulteEposta</td>
                            <td>@fakulte.CreatedDate.ToString("dd.MM.yyyy")</td>
                            <td class="text-end">
                                <a asp-action="Edit" asp-route-id="@fakulte.FakulteId"
                                   class="btn btn-sm btn-outline-primary">
                                    <i class="bi bi-pencil"></i> Düzenle
                                </a>
                                <a asp-action="Delete" asp-route-id="@fakulte.FakulteId"
                                   class="btn btn-sm btn-outline-danger">
                                    <i class="bi bi-trash"></i> Sil
                                </a>
                            </td>
                        </tr>
                    }
                </tbody>
            </table>
        }
    </div>
</div>
```

**`asp-route-id` nedir?**
Adrese id ekler. `asp-route-id="5"` → `/Fakulte/Edit/5`
Genel kural: `asp-route-XXX` → `XXX` adında bir parametre gönderir.

**`TempData` nedir?**
`ViewBag`'e benzer ama **bir sonraki isteğe kadar** yaşar. Yönlendirme (redirect) sonrasında da okunabilir. Bu yüzden "kaydedildi" mesajları için ideal. Okunduktan sonra otomatik silinir.

| Taşıyıcı | Ömrü | Kullanım |
|---|---|---|
| `ViewBag` / `ViewData` | Tek istek | Controller → View |
| `TempData` | Bir sonraki isteğe kadar | Redirect sonrası mesaj |
| `Model` | Tek istek | Asıl veri (tercih edilen yol) |

---

## ▶️ Çalıştır ve gör — test senaryosu

Öğrencilerle beraber sırayla test edin:

1. ✅ `/Fakulte` → liste geliyor mu?
2. ✅ "Yeni fakülte" → form açılıyor mu?
3. ✅ Boş formu gönder → kırmızı hata mesajları çıkıyor mu?
4. ✅ E-posta alanına `abc` yaz → "Geçerli bir e-posta adresi girin" çıkıyor mu?
5. ✅ Doğru doldur, kaydet → listeye dönüp yeşil mesaj çıkıyor mu?
6. ✅ SSMS'te kontrol et → kayıt gerçekten eklendi mi? `created_date` dolu mu?
7. ✅ Düzenle → form dolu geliyor mu?
8. ✅ Adı değiştir, kaydet → değişti mi? `updated_date` doldu mu?
9. ✅ Sil → onay sayfası geliyor mu?
10. ✅ Onayla → listeden kayboldu mu?
11. ✅ SSMS'te kontrol et → **kayıt hâlâ orada mı?** `is_active = '0'` mu?

11. maddeyi mutlaka yaptır. Soft delete'in ne anlama geldiğini öğrenci burada gözüyle görür.

---

## 📋 CRUD kalıbı — özet kart

Bu tabloyu öğrencilere **dağıt**. Sonraki üç modülde sürekli bakacaklar.

| # | Metot | HTTP | Adres | Ne yapar |
|---|---|---|---|---|
| 1 | `Index()` | GET | `/X` | Listeyi göster |
| 2 | `Create()` | GET | `/X/Create` | Boş form göster |
| 3 | `Create(model)` | POST | `/X/Create` | Kaydet, listeye dön |
| 4 | `Edit(id)` | GET | `/X/Edit/5` | Dolu form göster |
| 5 | `Edit(model)` | POST | `/X/Edit/5` | Güncelle, listeye dön |
| 6 | `Delete(id)` | GET | `/X/Delete/5` | Onay sayfası göster |
| 7 | `DeleteConfirmed(id)` | POST | `/X/Delete/5` | Pasif yap, listeye dön |

**Repository tarafı:**

| Metot | SQL | Execute metodu |
|---|---|---|
| `TumunuGetir()` | `SELECT ... WHERE is_active='1'` | `ExecuteReader()` |
| `IdIleGetir(id)` | `SELECT ... WHERE id=@id` | `ExecuteReader()` |
| `Ekle(model)` | `INSERT INTO ...` | `ExecuteNonQuery()` |
| `Guncelle(model)` | `UPDATE ... WHERE id=@id` | `ExecuteNonQuery()` |
| `PasifYap(id)` | `UPDATE SET is_active='0' WHERE id=@id` | `ExecuteNonQuery()` |

---

## ⚠️ Sık yapılan hatalar

| Hata | Sebep | Çözüm |
|---|---|---|
| Form gönderiliyor ama hiçbir şey kaydolmuyor | `[HttpPost]` unutulmuş | POST metodunun üstüne ekle |
| `Cannot insert the value NULL into column 'created_date'` | Tarih atanmamış | `Ekle()` içinde `DateTime.Now` ver |
| `Cannot insert the value NULL into column 'is_active'` | is_active atanmamış | `"1"` ver |
| Düzenleme kaydediyor ama hiçbir şey değişmiyor | Gizli `FakulteId` alanı yok | `<input type="hidden" asp-for="FakulteId" />` ekle |
| Düzenlemede `created_date` NULL oluyor | Gizli alan yok, form boş gönderiyor | `<input type="hidden" asp-for="CreatedDate" />` ekle (veya UPDATE'te bu sütuna hiç dokunma) |
| `Violation of UNIQUE KEY constraint` | Aynı e-posta/telefon ikinci kez | Modül 7'de güzel yakalamayı öğreneceğiz. Şimdilik farklı değer gir. |
| `The required antiforgery cookie is not present` | `[ValidateAntiForgeryToken]` var ama form Tag Helper kullanmıyor | Formu `<form asp-action="...">` şeklinde yaz (token otomatik eklenir) |
| Tarayıcıda hata mesajları çıkmıyor | Doğrulama scriptleri yüklenmemiş | `@section Scripts { <partial name="_ValidationScriptsPartial" /> }` ekle |
| Sil butonu direkt siliyor, onay sormuyor | GET metodu POST'a bağlanmış | GET onay sayfası + POST silme işlemi ayrımına dikkat |
| Kayıttan sonra F5 → çift kayıt | `RedirectToAction` yerine `View()` dönülmüş | `return RedirectToAction("Index");` |
| `Ambiguous action` hatası | İki metot aynı isim ve aynı imzada | `[ActionName]` kullan veya parametre imzasını değiştir |

---

## ✏️ Öğrenci alıştırması

**A. Tekrar (herkes, ders içinde)**
Fakülte CRUD'unu baştan sona kendi projende yaz. Bakarak yaz, kopyalama.

**B. Detay sayfası**
`Details(long id)` metodu ve `Details.cshtml` view'ı ekle. Bir fakültenin tüm bilgilerini (kayıt tarihi ve güncelleme tarihi dâhil) düzenli bir kart içinde göstersin. Listedeki fakülte adına tıklanınca bu sayfa açılsın.

**C. Pasif kayıtlar sayfası**
`Pasifler()` adında bir metot ve sayfa yaz: `is_active = '0'` olan fakülteleri listelesin. Her satırda "Geri getir" butonu olsun ve tıklanınca kayıt yeniden aktif olsun.
*(İpucu: `PasifYap`'ın tersi bir `AktifYap(long id)` metodu yaz.)*

**D. Zorlayıcı: onay kutusu**
Silme sayfasına "Bu işlemi anladım" yazan bir onay kutusu (checkbox) ekle. İşaretlenmeden silme butonu çalışmasın.

**E. Düşünme soruları (yazılı)**
1. `RedirectToAction` yerine `return View()` yazsaydık ne olurdu? Bunu deneyip gözlemini yaz.
2. Bir fakülteyi sildik ama ona bağlı bölümler hâlâ aktif. Bu bir sorun mu? Nasıl çözülmeli?
3. `[ValidateAntiForgeryToken]` olmasaydı hangi saldırı mümkün olurdu?

---

## Sonraki adım

👉 [`07-bolum-crud.md`](07-bolum-crud.md) — Aynı kalıp, bu sefer yabancı anahtar ile.
