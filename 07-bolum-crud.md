# Modül 6 — Bölüm CRUD (Yabancı Anahtar)

**Süre:** 2 ders saati
**Ön koşul:** Modül 5 (Fakülte CRUD çalışıyor)
**Kim yazıyor:** Beraber — sen tahtada, öğrenci ekranda, aynı anda

---

## 🎯 Bu derste ne yapacağız

Aynı CRUD kalıbını bölümler için tekrarlayacağız. **Yeni olan tek şey:** bir bölüm bir fakülteye bağlı. Bu da iki yeni beceri getiriyor:

1. Formda **açılır liste (dropdown)** ile fakülte seçtirmek
2. Listede fakülte **adını** göstermek (id değil) → **JOIN**

---

## 📖 Kavram 1: Yabancı anahtarın iki yüzü

```
VERİTABANINDA                         KULLANICI EKRANINDA
─────────────                         ────────────────────
bolum_id | fakulte_id | bolum_adi     Bölüm              | Fakülte
   1     |     2      | Bilgisayar    Bilgisayar Müh.    | Mühendislik Fakültesi
   2     |     2      | Makine        Makine Müh.        | Mühendislik Fakültesi
   3     |     1      | Türk Dili     Türk Dili ve Ed.   | Fen-Edebiyat Fakültesi
              ▲                                              ▲
        veritabanı sayı sever                    kullanıcı isim sever
```

**İki yönlü çeviri yapmamız gerekiyor:**

| Yön | Nerede | Nasıl |
|---|---|---|
| Sayı → İsim | Listede gösterirken | SQL `JOIN` |
| İsim → Sayı | Formda seçerken | HTML `<select>` (value=id, text=isim) |

---

## ⌨️ Adım 1: Model

`Models/Bolum.cs`:

```csharp
using System.ComponentModel.DataAnnotations;

namespace OkulYonetim.Models;

public class Bolum
{
    public long BolumId { get; set; }

    [Required(ErrorMessage = "Fakülte seçmelisiniz.")]
    [Display(Name = "Bağlı olduğu fakülte")]
    public long FakulteId { get; set; }          // ⭐ yabancı anahtar

    [Required(ErrorMessage = "Bölüm adı zorunludur.")]
    [StringLength(255)]
    [Display(Name = "Bölüm adı")]
    public string BolumAdi { get; set; } = "";   // ⚠️ dikkat: bolum_adi (fakültede _ad idi)

    [Required(ErrorMessage = "Adres zorunludur.")]
    [Display(Name = "Adres")]
    public string BolumAdres { get; set; } = "";

    [Required(ErrorMessage = "Telefon zorunludur.")]
    [Phone(ErrorMessage = "Geçerli bir telefon numarası girin.")]
    [Display(Name = "Telefon")]
    public string BolumTelefon { get; set; } = "";

    [Required(ErrorMessage = "E-posta zorunludur.")]
    [EmailAddress(ErrorMessage = "Geçerli bir e-posta adresi girin.")]
    [Display(Name = "E-posta")]
    public string BolumEposta { get; set; } = "";

    public DateTime CreatedDate { get; set; }
    public DateTime? UpdatedDate { get; set; }
    public string IsActive { get; set; } = "1";

    // ⭐ Veritabanında OLMAYAN alan!
    // JOIN sonucu gelen fakülte adını taşımak için ekledik.
    // Sadece listede göstermek için var.
    [Display(Name = "Fakülte")]
    public string FakulteAd { get; set; } = "";
}
```

### 📖 Kavram: Veritabanında olmayan özellik

`FakulteAd` alanı `bolum` tablosunda **yok**. Peki neden model'de var?

> *"Model sınıfı, veritabanı tablosunun birebir kopyası olmak zorunda değil. Model, 'ekranda göstereceğim verinin şekli'dir. JOIN ile gelen fakülte adını taşıyacak bir yere ihtiyacımız var — işte o yer bu alan."*

⚠️ **Kritik uyarı:** `INSERT` ve `UPDATE` sorgularında bu alanı **kullanmayacağız**. Yoksa "böyle bir sütun yok" hatası alırız.

> **Not — ileri seviye:** Profesyonel projelerde bu iş için `BolumListeViewModel` gibi ayrı bir sınıf yazılır (ViewModel deseni). Ders seviyesinde tek sınıfa fazladan alan eklemek yeterli ve daha az kafa karıştırıcı. Öğrenciye "büyük projelerde ayrı sınıf yazılır" diye not düş.

---

## ⌨️ Adım 2: Repository — JOIN'li listeleme

`Data/BolumRepository.cs`:

```csharp
using Microsoft.Data.SqlClient;
using OkulYonetim.Models;

namespace OkulYonetim.Data;

public class BolumRepository
{
    private readonly string _baglantiMetni;

    public BolumRepository(IConfiguration configuration)
    {
        _baglantiMetni = configuration.GetConnectionString("OkulDb")!;
    }

    /// <summary>
    /// Aktif bölümleri, bağlı oldukları fakültenin adıyla birlikte getirir.
    /// </summary>
    public List<Bolum> TumunuGetir()
    {
        List<Bolum> liste = new List<Bolum>();

        // ⭐ İKİ TABLOYU BİRLEŞTİRİYORUZ
        string sql = @"SELECT b.bolum_id, b.fakulte_id, b.bolum_adi, b.bolum_adres,
                              b.bolum_telefon, b.bolum_eposta,
                              b.created_date, b.updated_date, b.is_active,
                              f.fakulte_ad
                       FROM bolum b
                       INNER JOIN fakulte f ON b.fakulte_id = f.fakulte_id
                       WHERE b.is_active = '1'
                       ORDER BY f.fakulte_ad, b.bolum_adi";

        using (SqlConnection baglanti = new SqlConnection(_baglantiMetni))
        using (SqlCommand komut = new SqlCommand(sql, baglanti))
        {
            baglanti.Open();
            using (SqlDataReader okuyucu = komut.ExecuteReader())
            {
                while (okuyucu.Read())
                {
                    Bolum b = SatiriNesneyeCevir(okuyucu);
                    // JOIN'den gelen ekstra sütun
                    b.FakulteAd = okuyucu.GetString(okuyucu.GetOrdinal("fakulte_ad"));
                    liste.Add(b);
                }
            }
        }

        return liste;
    }
```

### JOIN'i tahtada anlat

```sql
FROM bolum b
INNER JOIN fakulte f ON b.fakulte_id = f.fakulte_id
```

| Parça | Anlamı |
|---|---|
| `bolum b` | `bolum` tablosuna kısaca `b` diyoruz (takma ad / alias) |
| `INNER JOIN fakulte f` | `fakulte` tablosunu da işin içine kat, ona da `f` de |
| `ON b.fakulte_id = f.fakulte_id` | **Eşleştirme kuralı:** bölümün fakülte numarası, fakültenin numarasına eşit olan satırları birleştir |

Görsel olarak anlat:

```
bolum tablosu                 fakulte tablosu
┌────┬────────────┬────┐      ┌────┬─────────────────┐
│ id │ bolum_adi  │ f_id│      │ id │ fakulte_ad      │
├────┼────────────┼────┤      ├────┼─────────────────┤
│ 1  │ Bilgisayar │  2 │──┐   │ 1  │ Fen-Edebiyat    │
│ 2  │ Makine     │  2 │──┼──▶│ 2  │ Mühendislik     │
│ 3  │ Türk Dili  │  1 │──┘   │ 3  │ İktisat         │
└────┴────────────┴────┘      └────┴─────────────────┘

SONUÇ:
┌────┬────────────┬─────────────────┐
│ 1  │ Bilgisayar │ Mühendislik     │
│ 2  │ Makine     │ Mühendislik     │
│ 3  │ Türk Dili  │ Fen-Edebiyat    │
└────┴────────────┴─────────────────┘
```

> **INNER vs LEFT JOIN:** `INNER JOIN`, eşleşme bulunmayan satırları **atar**. Fakültesi silinmiş bir bölüm listede görünmez. Bu bizim için sorun mu? Tartıştır. (Yabancı anahtar kısıtı olduğu için fakülte gerçekten silinemez, sadece pasife alınır — dolayısıyla sorun çıkmaz.)

### Repository'nin kalanı

```csharp
    private Bolum SatiriNesneyeCevir(SqlDataReader okuyucu)
    {
        Bolum b = new Bolum();

        b.BolumId      = okuyucu.GetInt64(okuyucu.GetOrdinal("bolum_id"));
        b.FakulteId    = okuyucu.GetInt64(okuyucu.GetOrdinal("fakulte_id"));
        b.BolumAdi     = okuyucu.GetString(okuyucu.GetOrdinal("bolum_adi"));
        b.BolumAdres   = okuyucu.GetString(okuyucu.GetOrdinal("bolum_adres"));
        b.BolumTelefon = okuyucu.GetString(okuyucu.GetOrdinal("bolum_telefon"));
        b.BolumEposta  = okuyucu.GetString(okuyucu.GetOrdinal("bolum_eposta"));
        b.CreatedDate  = okuyucu.GetDateTime(okuyucu.GetOrdinal("created_date"));
        b.IsActive     = okuyucu.GetString(okuyucu.GetOrdinal("is_active"));

        int sutunNo = okuyucu.GetOrdinal("updated_date");
        b.UpdatedDate = okuyucu.IsDBNull(sutunNo) ? null : okuyucu.GetDateTime(sutunNo);

        return b;
    }

    public Bolum? IdIleGetir(long id)
    {
        Bolum? sonuc = null;

        string sql = @"SELECT bolum_id, fakulte_id, bolum_adi, bolum_adres,
                              bolum_telefon, bolum_eposta,
                              created_date, updated_date, is_active
                       FROM bolum
                       WHERE bolum_id = @id";

        using (SqlConnection baglanti = new SqlConnection(_baglantiMetni))
        using (SqlCommand komut = new SqlCommand(sql, baglanti))
        {
            komut.Parameters.AddWithValue("@id", id);
            baglanti.Open();

            using (SqlDataReader okuyucu = komut.ExecuteReader())
            {
                if (okuyucu.Read())
                    sonuc = SatiriNesneyeCevir(okuyucu);
            }
        }

        return sonuc;
    }

    public void Ekle(Bolum bolum)
    {
        string sql = @"INSERT INTO bolum
                          (fakulte_id, bolum_adi, bolum_adres, bolum_telefon,
                           bolum_eposta, created_date, updated_date, is_active)
                       VALUES
                          (@fakulteId, @adi, @adres, @telefon,
                           @eposta, @createdDate, NULL, @isActive)";

        using (SqlConnection baglanti = new SqlConnection(_baglantiMetni))
        using (SqlCommand komut = new SqlCommand(sql, baglanti))
        {
            komut.Parameters.AddWithValue("@fakulteId",   bolum.FakulteId);
            komut.Parameters.AddWithValue("@adi",         bolum.BolumAdi);
            komut.Parameters.AddWithValue("@adres",       bolum.BolumAdres);
            komut.Parameters.AddWithValue("@telefon",     bolum.BolumTelefon);
            komut.Parameters.AddWithValue("@eposta",      bolum.BolumEposta);
            komut.Parameters.AddWithValue("@createdDate", DateTime.Now);
            komut.Parameters.AddWithValue("@isActive",    "1");

            baglanti.Open();
            komut.ExecuteNonQuery();
        }
    }

    public void Guncelle(Bolum bolum)
    {
        string sql = @"UPDATE bolum
                       SET fakulte_id    = @fakulteId,
                           bolum_adi     = @adi,
                           bolum_adres   = @adres,
                           bolum_telefon = @telefon,
                           bolum_eposta  = @eposta,
                           updated_date  = @updatedDate
                       WHERE bolum_id    = @id";

        using (SqlConnection baglanti = new SqlConnection(_baglantiMetni))
        using (SqlCommand komut = new SqlCommand(sql, baglanti))
        {
            komut.Parameters.AddWithValue("@fakulteId",   bolum.FakulteId);
            komut.Parameters.AddWithValue("@adi",         bolum.BolumAdi);
            komut.Parameters.AddWithValue("@adres",       bolum.BolumAdres);
            komut.Parameters.AddWithValue("@telefon",     bolum.BolumTelefon);
            komut.Parameters.AddWithValue("@eposta",      bolum.BolumEposta);
            komut.Parameters.AddWithValue("@updatedDate", DateTime.Now);
            komut.Parameters.AddWithValue("@id",          bolum.BolumId);

            baglanti.Open();
            komut.ExecuteNonQuery();
        }
    }

    public void PasifYap(long id)
    {
        string sql = @"UPDATE bolum
                       SET is_active = '0', updated_date = @updatedDate
                       WHERE bolum_id = @id";

        using (SqlConnection baglanti = new SqlConnection(_baglantiMetni))
        using (SqlCommand komut = new SqlCommand(sql, baglanti))
        {
            komut.Parameters.AddWithValue("@updatedDate", DateTime.Now);
            komut.Parameters.AddWithValue("@id", id);
            baglanti.Open();
            komut.ExecuteNonQuery();
        }
    }
}
```

**`Program.cs`'e kaydetmeyi unutma:**
```csharp
builder.Services.AddScoped<BolumRepository>();
```

---

## ⌨️ Adım 3: Controller — dropdown verisi

Formda fakülte seçtirmek için, forma **fakülte listesini de** göndermemiz gerekiyor.

`Controllers/BolumController.cs`:

```csharp
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;   // ⭐ SelectList için
using OkulYonetim.Data;
using OkulYonetim.Models;

namespace OkulYonetim.Controllers;

public class BolumController : Controller
{
    private readonly BolumRepository _bolumRepo;
    private readonly FakulteRepository _fakulteRepo;   // ⭐ İKİ repository!

    public BolumController(BolumRepository bolumRepo, FakulteRepository fakulteRepo)
    {
        _bolumRepo = bolumRepo;
        _fakulteRepo = fakulteRepo;
    }

    /// <summary>
    /// Fakülte açılır listesini hazırlar.
    /// Create ve Edit sayfalarında tekrar tekrar lazım olduğu için ayrı metot.
    /// </summary>
    private void FakulteListesiniHazirla(long? secili = null)
    {
        var fakulteler = _fakulteRepo.TumunuGetir();

        // SelectList: (kaynak liste, value alanı, görünen metin alanı, seçili değer)
        ViewBag.Fakulteler = new SelectList(fakulteler, "FakulteId", "FakulteAd", secili);
    }

    // GET: /Bolum
    public IActionResult Index()
    {
        return View(_bolumRepo.TumunuGetir());
    }

    // GET: /Bolum/Create
    public IActionResult Create()
    {
        FakulteListesiniHazirla();     // ⭐ Formu göstermeden önce listeyi hazırla
        return View();
    }

    // POST: /Bolum/Create
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Create(Bolum bolum)
    {
        if (!ModelState.IsValid)
        {
            FakulteListesiniHazirla(bolum.FakulteId);   // ⭐ Hata varsa listeyi TEKRAR hazırla
            return View(bolum);
        }

        _bolumRepo.Ekle(bolum);
        TempData["Basarili"] = "Bölüm kaydedildi.";
        return RedirectToAction("Index");
    }

    // GET: /Bolum/Edit/5
    public IActionResult Edit(long id)
    {
        var bolum = _bolumRepo.IdIleGetir(id);
        if (bolum == null) return NotFound();

        FakulteListesiniHazirla(bolum.FakulteId);   // ⭐ Mevcut fakülte seçili gelsin
        return View(bolum);
    }

    // POST: /Bolum/Edit/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Edit(Bolum bolum)
    {
        if (!ModelState.IsValid)
        {
            FakulteListesiniHazirla(bolum.FakulteId);
            return View(bolum);
        }

        _bolumRepo.Guncelle(bolum);
        TempData["Basarili"] = "Bölüm güncellendi.";
        return RedirectToAction("Index");
    }

    // GET: /Bolum/Delete/5
    public IActionResult Delete(long id)
    {
        var bolum = _bolumRepo.IdIleGetir(id);
        if (bolum == null) return NotFound();
        return View(bolum);
    }

    // POST: /Bolum/Delete/5
    [HttpPost, ActionName("Delete")]
    [ValidateAntiForgeryToken]
    public IActionResult DeleteConfirmed(long id)
    {
        _bolumRepo.PasifYap(id);
        TempData["Basarili"] = "Bölüm silindi.";
        return RedirectToAction("Index");
    }
}
```

### ⚠️ En çok unutulan şey — mutlaka vurgula

```csharp
if (!ModelState.IsValid)
{
    FakulteListesiniHazirla(bolum.FakulteId);   // ← BU SATIR
    return View(bolum);
}
```

**Bu satırı yazmazsan ne olur?** Kullanıcı formu hatalı doldurur, sayfa geri gelir ama **açılır liste boş olur** ve uygulama `NullReferenceException` ile çöker.

> **Sebep:** `ViewBag.Fakulteler` sadece o istek boyunca yaşar. POST yeni bir istektir, önceki ViewBag yok olmuştur. Yeniden doldurmak zorundayız.
>
> **Eğitmen numarası:** Bu satırı bilerek sil, formu hatalı gönder, çökmesini göster. Sonra geri ekle. Bu hata öğrenciyi en çok uğraştıracak hatalardan biri, önceden aşılamak iyi olur.

### 📖 SelectList nedir?

```csharp
new SelectList(fakulteler, "FakulteId", "FakulteAd", secili)
                    │           │            │          │
                    │           │            │          └─ hangisi seçili gelsin
                    │           │            └─ kullanıcının GÖRECEĞİ metin
                    │           └─ arka planda GÖNDERİLECEK değer
                    └─ kaynak liste
```

Bu, HTML'e şuna dönüşecek:

```html
<select>
    <option value="1">Fen-Edebiyat Fakültesi</option>
    <option value="2" selected>Mühendislik Fakültesi</option>
    <option value="3">İktisat Fakültesi</option>
</select>
```

> **İşte "isim → sayı" çevirisi burada oluyor:** Kullanıcı "Mühendislik Fakültesi" görüyor ve seçiyor, sunucuya `2` gidiyor.

---

## ⌨️ Adım 4: View'lar

### Create.cshtml

```html
@model OkulYonetim.Models.Bolum
@{
    ViewData["Title"] = "Yeni bölüm";
}

<div class="row">
    <div class="col-md-8">
        <div class="card border-0 shadow-sm">
            <div class="card-body">
                <form asp-action="Create" method="post">

                    @* ⭐ AÇILIR LİSTE *@
                    <div class="mb-3">
                        <label asp-for="FakulteId" class="form-label"></label>
                        <select asp-for="FakulteId"
                                asp-items="ViewBag.Fakulteler"
                                class="form-select">
                            <option value="">-- Fakülte seçin --</option>
                        </select>
                        <span asp-validation-for="FakulteId" class="text-danger small"></span>
                    </div>

                    <div class="mb-3">
                        <label asp-for="BolumAdi" class="form-label"></label>
                        <input asp-for="BolumAdi" class="form-control" />
                        <span asp-validation-for="BolumAdi" class="text-danger small"></span>
                    </div>

                    <div class="mb-3">
                        <label asp-for="BolumAdres" class="form-label"></label>
                        <textarea asp-for="BolumAdres" class="form-control" rows="3"></textarea>
                        <span asp-validation-for="BolumAdres" class="text-danger small"></span>
                    </div>

                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label asp-for="BolumTelefon" class="form-label"></label>
                            <input asp-for="BolumTelefon" class="form-control" />
                            <span asp-validation-for="BolumTelefon" class="text-danger small"></span>
                        </div>
                        <div class="col-md-6 mb-3">
                            <label asp-for="BolumEposta" class="form-label"></label>
                            <input asp-for="BolumEposta" class="form-control" />
                            <span asp-validation-for="BolumEposta" class="text-danger small"></span>
                        </div>
                    </div>

                    <hr />
                    <button type="submit" class="btn btn-primary">
                        <i class="bi bi-check-lg"></i> Bölümü kaydet
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

**`asp-items` Tag Helper'ı** `<option>` etiketlerini otomatik üretir. Elle yazmamıza gerek yok.

> **`<option value="">-- Fakülte seçin --</option>` neden var?**
> Kullanıcı hiçbir şey seçmeden gönderirse, ilk fakülte otomatik seçili görünmesin diye. Boş değer gider, `[Required]` hatayı yakalar. Küçük ama kullanıcı deneyimi açısından önemli bir detay.

### Edit.cshtml

Create'in aynısı, üç gizli alan farkıyla:

```html
<form asp-action="Edit" method="post">
    <input type="hidden" asp-for="BolumId" />
    <input type="hidden" asp-for="CreatedDate" />
    <input type="hidden" asp-for="IsActive" />

    @* ... geri kalan alanlar Create ile aynı ... *@
</form>
```

### Index.cshtml

```html
@model List<OkulYonetim.Models.Bolum>
@{
    ViewData["Title"] = "Bölümler";
}

@if (TempData["Basarili"] != null)
{
    <div class="alert alert-success alert-dismissible fade show">
        <i class="bi bi-check-circle"></i> @TempData["Basarili"]
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
}

<div class="card border-0 shadow-sm">
    <div class="card-header bg-white d-flex justify-content-between align-items-center">
        <span class="fw-semibold">Kayıtlı bölümler (@Model.Count)</span>
        <a asp-action="Create" class="btn btn-primary btn-sm">
            <i class="bi bi-plus-lg"></i> Yeni bölüm
        </a>
    </div>

    <div class="card-body p-0">
        @if (Model.Count == 0)
        {
            <div class="text-center text-muted py-5">
                <i class="bi bi-inbox fs-1 d-block mb-2"></i>
                Henüz bölüm eklenmemiş. Önce en az bir fakülte oluşturun.
            </div>
        }
        else
        {
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                    <tr>
                        <th>#</th>
                        <th>Bölüm adı</th>
                        <th>Fakülte</th>
                        <th>Telefon</th>
                        <th>E-posta</th>
                        <th class="text-end">İşlemler</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach (var bolum in Model)
                    {
                        <tr>
                            <td>@bolum.BolumId</td>
                            <td class="fw-semibold">@bolum.BolumAdi</td>
                            <td>
                                @* ⭐ JOIN'den gelen fakülte adı *@
                                <span class="badge bg-secondary">@bolum.FakulteAd</span>
                            </td>
                            <td>@bolum.BolumTelefon</td>
                            <td>@bolum.BolumEposta</td>
                            <td class="text-end">
                                <a asp-action="Edit" asp-route-id="@bolum.BolumId"
                                   class="btn btn-sm btn-outline-primary">
                                    <i class="bi bi-pencil"></i> Düzenle
                                </a>
                                <a asp-action="Delete" asp-route-id="@bolum.BolumId"
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

### Delete.cshtml

Fakültedekiyle aynı yapıda; sadece alan adları ve uyarı metni değişir:

```html
@model OkulYonetim.Models.Bolum
@{
    ViewData["Title"] = "Bölümü sil";
}

<div class="row">
    <div class="col-md-7">
        <div class="card border-danger shadow-sm">
            <div class="card-header bg-danger text-white">
                <i class="bi bi-exclamation-triangle"></i> Silme onayı
            </div>
            <div class="card-body">
                <p>Bu bölümü silmek üzeresiniz:</p>

                <dl class="row mb-4">
                    <dt class="col-sm-3">Bölüm adı</dt>
                    <dd class="col-sm-9">@Model.BolumAdi</dd>
                    <dt class="col-sm-3">Telefon</dt>
                    <dd class="col-sm-9">@Model.BolumTelefon</dd>
                    <dt class="col-sm-3">E-posta</dt>
                    <dd class="col-sm-9">@Model.BolumEposta</dd>
                </dl>

                <div class="alert alert-warning small">
                    <i class="bi bi-info-circle"></i>
                    Bu bölüme kayıtlı öğrenci ve akademisyenler etkilenmez,
                    listelerde görünmeye devam eder.
                </div>

                <form asp-action="Delete" method="post">
                    <input type="hidden" asp-for="BolumId" name="id" />
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

---

## ▶️ Çalıştır ve gör

1. `/Bolum` → Fakülte adları listede görünüyor mu?
2. Yeni bölüm → açılır listede fakülteler geliyor mu?
3. Fakülte seçmeden kaydet → "Fakülte seçmelisiniz" hatası çıkıyor mu?
4. **Hatalı gönderimden sonra açılır liste hâlâ dolu mu?** (Bu, `FakulteListesiniHazirla` satırının testi)
5. Düzenle → mevcut fakülte seçili geliyor mu?
6. Bölümün fakültesini değiştir, kaydet → listede yeni fakülte görünüyor mu?

---

## 💬 Sınıf tartışması

**Soru:** *"Bir fakülteyi sildik. Ona bağlı bölümler ne olacak?"*

Şu an sistemde ne oluyor?
- Fakülte `is_active='0'` oluyor
- Bölümler hâlâ `is_active='1'`
- Bölüm listesindeki `INNER JOIN` fakülteyi bulmaya devam ediyor (çünkü kayıt duruyor, sadece pasif)
- Yani **bölümler listede kalıyor ama fakülteleri artık "silinmiş"**

Üç olası yaklaşım — öğrencilere tartıştır:

| Yaklaşım | Artısı | Eksisi |
|---|---|---|
| **Zincirleme pasifleme:** Fakülte pasif olunca bölümleri de pasif yap | Tutarlı veri | Yanlışlıkla silmede büyük kayıp |
| **Engelleme:** Bağlı bölümü olan fakülte silinemesin | Güvenli, uyarıcı | Kullanıcı önce bölümleri silmeli |
| **Serbest bırak:** Şu anki durum | Basit | Tutarsız veri oluşabilir |

Gerçek projelerde genelde **2. seçenek** tercih edilir. Bunu Modül 11'de uygulayabilirsin (aşağıda alıştırma olarak da var).

---

## ⚠️ Sık yapılan hatalar

| Hata | Sebep | Çözüm |
|---|---|---|
| `NullReferenceException` — açılır liste boş | POST'ta `FakulteListesiniHazirla()` çağrılmamış | `if (!ModelState.IsValid)` bloğuna ekle |
| `Invalid column name 'bolum_ad'` | Sütun adı `bolum_adi` | Şemayı kontrol et — fakültede `_ad`, bölümde `_adi` |
| `Invalid column name 'FakulteAd'` | INSERT/UPDATE'e model'e eklediğimiz ekstra alan yazılmış | O alanı SQL'de kullanma |
| `Ambiguous column name 'created_date'` | JOIN'de iki tabloda da aynı sütun var, hangisi belli değil | `b.created_date` şeklinde tablo takma adıyla yaz |
| Açılır listede fakülte yok | Hiç aktif fakülte kaydı yok | Önce fakülte ekle |
| Fakülte seçilmiyor, hep ilki seçili | `SelectList`'e seçili değer verilmemiş | 4. parametreye mevcut `FakulteId`'yi ver |
| Düzenlemede fakülte değişmiyor | `UPDATE`'te `fakulte_id` güncellenmiyor | SQL'e `fakulte_id = @fakulteId` ekle |
| `Unable to resolve service for type 'BolumRepository'` | `Program.cs`'e eklenmemiş | `AddScoped<BolumRepository>()` |
| `The INSERT statement conflicted with the FOREIGN KEY constraint` | Olmayan fakülte id'si gönderiliyor | Açılır listenin doğru çalıştığını kontrol et |

---

## ✏️ Öğrenci alıştırması

**A. Tekrar (herkes)**
Bölüm CRUD'unu kendi projende tamamla.

**B. Fakülteye göre filtreleme**
Bölüm listesinin üstüne bir açılır liste koy: "Fakülte seçin". Seçilince sadece o fakültenin bölümleri listelensin.

İpucu:
```csharp
public IActionResult Index(long? fakulteId)
{
    var liste = _bolumRepo.TumunuGetir();

    if (fakulteId.HasValue && fakulteId.Value > 0)
        liste = liste.Where(b => b.FakulteId == fakulteId.Value).ToList();

    FakulteListesiniHazirla(fakulteId);
    return View(liste);
}
```
*(Bu, LINQ ile filtreleme. Daha doğrusu SQL'de `WHERE` ile yapmaktır — Modül 10'da öğreneceğiz.)*

**C. Fakülte detayında bölümler**
Fakülte listesinde her satıra "Bölümleri gör" butonu ekle. Tıklanınca o fakültenin bölümleri açılsın.

**D. Zorlayıcı: silme engeli**
Fakülte silmeye çalışıldığında, o fakültede aktif bölüm varsa silmeyi engelle ve şu mesajı göster:
> "Bu fakültede 3 aktif bölüm var. Önce bölümleri silmelisiniz."

İpucu: `FakulteRepository`'ye şöyle bir metot ekle:
```csharp
public int AktifBolumSayisi(long fakulteId)
{
    string sql = "SELECT COUNT(*) FROM bolum WHERE fakulte_id = @id AND is_active = '1'";
    // ...
    return Convert.ToInt32(komut.ExecuteScalar());   // ⭐ tek değer için ExecuteScalar
}
```

`ExecuteScalar()` — tek bir değer dönen sorgular için (COUNT, SUM, MAX...). Üçüncü Execute metodumuz.

**E. Düşünme sorusu**
> `FakulteAd` alanını model'e eklemek yerine, view'da her satır için ayrı bir sorgu çalıştırıp fakülte adını çekseydik ne olurdu? 100 bölüm varsa kaç sorgu çalışırdı?
> *(Bu problemin adı "N+1 sorgu problemi"dir ve gerçek projelerde en yaygın performans hatasıdır.)*

---

## Sonraki adım

👉 [`08-ogrenci-crud.md`](08-ogrenci-crud.md) — Bu sefer klavye öğrencide.
