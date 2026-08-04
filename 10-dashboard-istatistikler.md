# Modül 9 — Dashboard İstatistikleri

**Süre:** 1 ders saati
**Ön koşul:** Modül 8 (dört CRUD da çalışıyor)
**Kim yazıyor:** Beraber

---

## 🎯 Bu derste ne yapacağız

Modül 4'te dashboard'a elle yazdığımız sahte sayıları **gerçek verilerle** değiştireceğiz. Yolda iki yeni kavram öğreneceğiz: **ViewModel** ve **ExecuteScalar**.

---

## 📖 Kavram 1: ViewModel

**Sorunu ortaya koy:**

> *"Dashboard'da 4 farklı sayı ve bir de bölüm bazlı dağılım listesi göstereceğiz. Controller bunları View'a nasıl gönderecek? `return View(???)`"*

Öğrenciler ViewBag önerecek. Sınırlarını göster:

```csharp
// ❌ ViewBag ile — çalışır ama sorunlu
ViewBag.FakulteSayisi = 3;
ViewBag.BolumSayisi = 6;
ViewBag.OgrenciSayisi = 15;
ViewBag.Dagilim = liste;
```

**Neden sorunlu?**
- Yazım hatası derleme zamanında yakalanmaz. `ViewBag.OgrenciSayısı` (Türkçe ı ile) yazarsan sessizce boş gelir.
- Visual Studio otomatik tamamlama yardımı vermez.
- View'a bakan biri hangi verilerin geldiğini anlayamaz.

**Çözüm: ViewModel**

> *"O ekran için özel bir sınıf yazarız. İçinde ekranın ihtiyacı olan her şey vardır. Bu sınıf hiçbir veritabanı tablosuna karşılık gelmez — sadece o ekranın taşıyıcısıdır."*

```
Model      = Veritabanı tablosunun karşılığı        (Fakulte, Ogrenci)
ViewModel  = Bir ekranın ihtiyacının karşılığı      (DashboardViewModel)
```

---

## ⌨️ Adım 1: ViewModel'i yaz

`Models/DashboardViewModel.cs`:

```csharp
namespace OkulYonetim.Models;

public class DashboardViewModel
{
    // Üstteki kartlar için sayılar
    public int FakulteSayisi { get; set; }
    public int BolumSayisi { get; set; }
    public int OgrenciSayisi { get; set; }
    public int AkademisyenSayisi { get; set; }

    // Bölüme göre öğrenci dağılımı
    public List<BolumDagilim> BolumDagilimlari { get; set; } = new();

    // Sınıflara göre öğrenci dağılımı
    public List<SinifDagilim> SinifDagilimlari { get; set; } = new();

    // Son eklenen öğrenciler
    public List<Ogrenci> SonEklenenOgrenciler { get; set; } = new();
}

// Yardımcı sınıflar — sadece dashboard'da kullanılacak
public class BolumDagilim
{
    public string BolumAdi { get; set; } = "";
    public string FakulteAd { get; set; } = "";
    public int OgrenciSayisi { get; set; }
    public int AkademisyenSayisi { get; set; }
}

public class SinifDagilim
{
    public int Sinif { get; set; }
    public int OgrenciSayisi { get; set; }
}
```

---

## 📖 Kavram 2: ExecuteScalar

Üçüncü ve son Execute metodumuz. Tabloyu tamamla:

| Metot | Ne zaman | Ne döner |
|---|---|---|
| `ExecuteReader()` | `SELECT` — çok satır | `SqlDataReader` |
| `ExecuteNonQuery()` | `INSERT`, `UPDATE`, `DELETE` | Etkilenen satır sayısı (int) |
| `ExecuteScalar()` | **Tek değer** — `COUNT`, `SUM`, `MAX`, `AVG` | `object` (dönüştürmen gerekir) |

```csharp
string sql = "SELECT COUNT(*) FROM ogrenci WHERE is_active = '1'";
// ...
object sonuc = komut.ExecuteScalar();
int sayi = Convert.ToInt32(sonuc);
```

> **Neden `Convert.ToInt32`?** `ExecuteScalar` her zaman `object` döner çünkü ne geleceğini bilmez. Biz `int` istediğimizi söylemek zorundayız.

---

## ⌨️ Adım 2: DashboardRepository

`Data/DashboardRepository.cs`:

```csharp
using Microsoft.Data.SqlClient;
using OkulYonetim.Models;

namespace OkulYonetim.Data;

public class DashboardRepository
{
    private readonly string _baglantiMetni;

    public DashboardRepository(IConfiguration configuration)
    {
        _baglantiMetni = configuration.GetConnectionString("OkulDb")!;
    }

    /// <summary>
    /// Verilen tablodaki aktif kayıt sayısını döner.
    /// </summary>
    private int AktifKayitSayisi(string tabloAdi)
    {
        // ⚠️ DİKKAT: Burada tablo adını SQL'e birleştiriyoruz.
        //    Tablo adı parametre OLAMAZ (SQL'in kuralı böyle).
        //    Bu yüzden tablo adının kullanıcıdan gelmediğinden emin olmalıyız!
        //    Bu metot sadece bizim yazdığımız sabit isimlerle çağrılıyor → güvenli.
        string sql = $"SELECT COUNT(*) FROM {tabloAdi} WHERE is_active = '1'";

        using (SqlConnection baglanti = new SqlConnection(_baglantiMetni))
        using (SqlCommand komut = new SqlCommand(sql, baglanti))
        {
            baglanti.Open();
            return Convert.ToInt32(komut.ExecuteScalar());
        }
    }

    public int FakulteSayisi()     => AktifKayitSayisi("fakulte");
    public int BolumSayisi()       => AktifKayitSayisi("bolum");
    public int OgrenciSayisi()     => AktifKayitSayisi("ogrenci");
    public int AkademisyenSayisi() => AktifKayitSayisi("akademisyen");

    /// <summary>
    /// Her bölümdeki öğrenci ve akademisyen sayısı.
    /// </summary>
    public List<BolumDagilim> BolumDagilimi()
    {
        var liste = new List<BolumDagilim>();

        string sql = @"
            SELECT b.bolum_adi,
                   f.fakulte_ad,
                   (SELECT COUNT(*) FROM ogrenci o
                    WHERE o.bolum_id = b.bolum_id AND o.is_active = '1')     AS ogrenci_sayisi,
                   (SELECT COUNT(*) FROM akademisyen a
                    WHERE a.bolum_id = b.bolum_id AND a.is_active = '1')     AS akademisyen_sayisi
            FROM bolum b
            INNER JOIN fakulte f ON b.fakulte_id = f.fakulte_id
            WHERE b.is_active = '1'
            ORDER BY ogrenci_sayisi DESC";

        using (SqlConnection baglanti = new SqlConnection(_baglantiMetni))
        using (SqlCommand komut = new SqlCommand(sql, baglanti))
        {
            baglanti.Open();
            using (SqlDataReader okuyucu = komut.ExecuteReader())
            {
                while (okuyucu.Read())
                {
                    liste.Add(new BolumDagilim
                    {
                        BolumAdi          = okuyucu.GetString(okuyucu.GetOrdinal("bolum_adi")),
                        FakulteAd         = okuyucu.GetString(okuyucu.GetOrdinal("fakulte_ad")),
                        OgrenciSayisi     = okuyucu.GetInt32(okuyucu.GetOrdinal("ogrenci_sayisi")),
                        AkademisyenSayisi = okuyucu.GetInt32(okuyucu.GetOrdinal("akademisyen_sayisi"))
                    });
                }
            }
        }

        return liste;
    }

    /// <summary>
    /// Sınıflara göre öğrenci sayısı.
    /// </summary>
    public List<SinifDagilim> SinifDagilimi()
    {
        var liste = new List<SinifDagilim>();

        string sql = @"SELECT ogrenci_sinif, COUNT(*) AS adet
                       FROM ogrenci
                       WHERE is_active = '1'
                       GROUP BY ogrenci_sinif
                       ORDER BY ogrenci_sinif";

        using (SqlConnection baglanti = new SqlConnection(_baglantiMetni))
        using (SqlCommand komut = new SqlCommand(sql, baglanti))
        {
            baglanti.Open();
            using (SqlDataReader okuyucu = komut.ExecuteReader())
            {
                while (okuyucu.Read())
                {
                    liste.Add(new SinifDagilim
                    {
                        Sinif         = okuyucu.GetInt32(okuyucu.GetOrdinal("ogrenci_sinif")),
                        OgrenciSayisi = okuyucu.GetInt32(okuyucu.GetOrdinal("adet"))
                    });
                }
            }
        }

        return liste;
    }
}
```

`Program.cs`:
```csharp
builder.Services.AddScoped<DashboardRepository>();
```

### Yeni SQL kavramları

**1. Alt sorgu (subquery)**
```sql
(SELECT COUNT(*) FROM ogrenci o WHERE o.bolum_id = b.bolum_id AND o.is_active='1')
```
Bir sorgunun içindeki başka bir sorgu. Dış sorgudaki her satır için ayrı çalışır.

**2. `GROUP BY`**
```sql
SELECT ogrenci_sinif, COUNT(*) FROM ogrenci GROUP BY ogrenci_sinif
```
Aynı değere sahip satırları gruplar ve her grup için hesap yapar.

```
ÖNCESİ                     SONRASI
sinif                      sinif | adet
  1                          1   |  4
  1                          2   |  3
  2                          3   |  5
  1                          4   |  3
  3
  ...
```

**3. `=>` (expression-bodied member)**
```csharp
public int FakulteSayisi() => AktifKayitSayisi("fakulte");

// Aynı şey:
public int FakulteSayisi()
{
    return AktifKayitSayisi("fakulte");
}
```
Tek satırlık metotlar için kısa yazım.

> **Güvenlik notu — `AktifKayitSayisi` metodundaki uyarıyı atlama.** Tablo adı SQL parametresi olamaz, bu yüzden orada string birleştirme kullandık. Bu, "SQL'e asla değer birleştirme" kuralının **istisnası**, ama sadece değer kullanıcıdan gelmediği için güvenli. Öğrenciye şunu sor: *"Bu metoda tablo adını kullanıcıdan alsaydık ne olurdu?"*

---

## ⌨️ Adım 3: HomeController

```csharp
using Microsoft.AspNetCore.Mvc;
using OkulYonetim.Data;
using OkulYonetim.Models;

namespace OkulYonetim.Controllers;

public class HomeController : Controller
{
    private readonly DashboardRepository _repo;

    public HomeController(DashboardRepository repo)
    {
        _repo = repo;
    }

    public IActionResult Index()
    {
        var model = new DashboardViewModel
        {
            FakulteSayisi     = _repo.FakulteSayisi(),
            BolumSayisi       = _repo.BolumSayisi(),
            OgrenciSayisi     = _repo.OgrenciSayisi(),
            AkademisyenSayisi = _repo.AkademisyenSayisi(),
            BolumDagilimlari  = _repo.BolumDagilimi(),
            SinifDagilimlari  = _repo.SinifDagilimi()
        };

        return View(model);
    }

    public IActionResult Privacy() => View();
}
```

---

## ⌨️ Adım 4: Dashboard view'ı

`Views/Home/Index.cshtml`:

```html
@model OkulYonetim.Models.DashboardViewModel
@{
    ViewData["Title"] = "Panel";
}

@* ============ ÜST KARTLAR ============ *@
<div class="row g-3 mb-4">

    <div class="col-md-3">
        <a asp-controller="Fakulte" asp-action="Index" class="text-decoration-none">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body d-flex justify-content-between align-items-center">
                    <div>
                        <div class="text-muted small">Fakülte</div>
                        <div class="fs-3 fw-bold text-dark">@Model.FakulteSayisi</div>
                    </div>
                    <i class="bi bi-building fs-1 text-primary opacity-25"></i>
                </div>
            </div>
        </a>
    </div>

    <div class="col-md-3">
        <a asp-controller="Bolum" asp-action="Index" class="text-decoration-none">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body d-flex justify-content-between align-items-center">
                    <div>
                        <div class="text-muted small">Bölüm</div>
                        <div class="fs-3 fw-bold text-dark">@Model.BolumSayisi</div>
                    </div>
                    <i class="bi bi-diagram-3 fs-1 text-success opacity-25"></i>
                </div>
            </div>
        </a>
    </div>

    <div class="col-md-3">
        <a asp-controller="Ogrenci" asp-action="Index" class="text-decoration-none">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body d-flex justify-content-between align-items-center">
                    <div>
                        <div class="text-muted small">Öğrenci</div>
                        <div class="fs-3 fw-bold text-dark">@Model.OgrenciSayisi</div>
                    </div>
                    <i class="bi bi-people fs-1 text-warning opacity-25"></i>
                </div>
            </div>
        </a>
    </div>

    <div class="col-md-3">
        <a asp-controller="Akademisyen" asp-action="Index" class="text-decoration-none">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body d-flex justify-content-between align-items-center">
                    <div>
                        <div class="text-muted small">Akademisyen</div>
                        <div class="fs-3 fw-bold text-dark">@Model.AkademisyenSayisi</div>
                    </div>
                    <i class="bi bi-person-badge fs-1 text-info opacity-25"></i>
                </div>
            </div>
        </a>
    </div>

</div>

<div class="row g-3">

    @* ============ BÖLÜM DAĞILIMI ============ *@
    <div class="col-lg-8">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-header bg-white fw-semibold">Bölümlere göre dağılım</div>
            <div class="card-body p-0">
                <table class="table table-sm mb-0 align-middle">
                    <thead class="table-light">
                        <tr>
                            <th>Bölüm</th>
                            <th>Fakülte</th>
                            <th class="text-center">Öğrenci</th>
                            <th class="text-center">Akademisyen</th>
                            <th style="width: 30%;">Doluluk</th>
                        </tr>
                    </thead>
                    <tbody>
                        @{
                            // En kalabalık bölümü bul — çubukları ona göre ölçekleyeceğiz
                            int enYuksek = Model.BolumDagilimlari.Count > 0
                                ? Model.BolumDagilimlari.Max(b => b.OgrenciSayisi)
                                : 1;
                            if (enYuksek == 0) enYuksek = 1;   // sıfıra bölme koruması
                        }

                        @foreach (var b in Model.BolumDagilimlari)
                        {
                            int yuzde = (b.OgrenciSayisi * 100) / enYuksek;
                            <tr>
                                <td class="fw-semibold">@b.BolumAdi</td>
                                <td class="text-muted small">@b.FakulteAd</td>
                                <td class="text-center">@b.OgrenciSayisi</td>
                                <td class="text-center">@b.AkademisyenSayisi</td>
                                <td>
                                    @* ⭐ Basit çubuk grafik — sadece CSS, kütüphane yok *@
                                    <div class="progress" style="height: 8px;">
                                        <div class="progress-bar bg-primary"
                                             style="width: @yuzde%;"></div>
                                    </div>
                                </td>
                            </tr>
                        }
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    @* ============ SINIF DAĞILIMI ============ *@
    <div class="col-lg-4">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-header bg-white fw-semibold">Sınıflara göre öğrenci</div>
            <div class="card-body">
                @if (Model.SinifDagilimlari.Count == 0)
                {
                    <p class="text-muted small mb-0">Henüz öğrenci kaydı yok.</p>
                }
                else
                {
                    @foreach (var s in Model.SinifDagilimlari)
                    {
                        int yuzde = Model.OgrenciSayisi > 0
                            ? (s.OgrenciSayisi * 100) / Model.OgrenciSayisi
                            : 0;

                        <div class="mb-3">
                            <div class="d-flex justify-content-between small mb-1">
                                <span>@s.Sinif. sınıf</span>
                                <span class="text-muted">@s.OgrenciSayisi kişi (%@yuzde)</span>
                            </div>
                            <div class="progress" style="height: 6px;">
                                <div class="progress-bar bg-warning" style="width: @yuzde%;"></div>
                            </div>
                        </div>
                    }
                }
            </div>
        </div>
    </div>

</div>
```

### Çubuk grafiği anlat

```csharp
int yuzde = (b.OgrenciSayisi * 100) / enYuksek;
```
```html
<div class="progress-bar" style="width: @yuzde%;"></div>
```

> *"Grafik kütüphanesi kurmadan, sadece bir div'in genişliğini yüzdeyle ayarlayarak çubuk grafik yaptık. Bazen en basit çözüm en iyisidir."*

**Sıfıra bölme koruması** — `if (enYuksek == 0) enYuksek = 1;` satırını göster. Hiç öğrenci yoksa uygulama `DivideByZeroException` ile çökerdi. Küçük ama kritik.

---

## ▶️ Çalıştır ve gör

1. Ana sayfaya git → gerçek sayılar görünüyor mu?
2. Yeni bir öğrenci ekle → dashboard'a dön → sayı arttı mı?
3. Bir öğrenciyi sil → sayı azaldı mı?
4. SSMS'ten sayıları doğrula:
   ```sql
   SELECT COUNT(*) FROM ogrenci WHERE is_active = '1';
   ```

---

## ⚠️ Sık yapılan hatalar

| Hata | Sebep | Çözüm |
|---|---|---|
| `Unable to cast object of type 'System.Int32'` | `ExecuteScalar` sonucu doğrudan `(int)` ile dönüştürülmüş | `Convert.ToInt32()` kullan |
| `Attempted to divide by zero` | Hiç kayıt yokken yüzde hesabı | Payda sıfırsa kontrol et |
| `Object reference not set` | ViewModel'deki liste `null` | `= new()` ile başlat |
| Sayılar hep 0 | `is_active` filtresi `'1'` yerine `1` yazılmış | Tırnak içinde olmalı: `'1'` |
| `Invalid column name 'adet'` | Takma ad kullanılmamış | SQL'de `AS adet` var mı? |
| Kartlar tıklanabilir ama mavi/altı çizili | Link stili | `class="text-decoration-none"` ekle |
| `Max()` metodu yok hatası | LINQ using eksik | `using System.Linq;` (genelde otomatik gelir) |

---

## ✏️ Öğrenci alıştırması

**A. Son eklenenler listesi**
ViewModel'de hazır duran `SonEklenenOgrenciler` alanını doldur. Dashboard'a "Son eklenen 5 öğrenci" kartı ekle.

İpucu:
```sql
SELECT TOP 5 o.*, b.bolum_adi
FROM ogrenci o
INNER JOIN bolum b ON o.bolum_id = b.bolum_id
WHERE o.is_active = '1'
ORDER BY o.created_date DESC
```

**B. Cinsiyet dağılımı**
Kadın/erkek öğrenci sayısını gösteren bir kart ekle. İki renkli çubukla göster.

**C. Fakülte bazlı özet**
Her fakülte için: kaç bölüm, kaç öğrenci, kaç akademisyen. Tablo hâlinde.

**D. Gerçek grafik (zorlayıcı)**
Chart.js kütüphanesini ekleyip sınıf dağılımını pasta grafiği olarak göster.

```html
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<canvas id="sinifGrafik"></canvas>

<script>
    new Chart(document.getElementById('sinifGrafik'), {
        type: 'doughnut',
        data: {
            labels: [@Html.Raw(string.Join(",", Model.SinifDagilimlari.Select(s => $"'{s.Sinif}. sınıf'")))],
            datasets: [{
                data: [@string.Join(",", Model.SinifDagilimlari.Select(s => s.OgrenciSayisi))]
            }]
        }
    });
</script>
```

> `@Html.Raw` — Razor'ın metni HTML olarak (kaçış yapmadan) yazmasını sağlar. ⚠️ Kullanıcıdan gelen veriyle **asla** kullanma, XSS açığı yaratır. Burada güvenli çünkü veri bizim ürettiğimiz sayılardan oluşuyor.

**E. Düşünme sorusu**
> Dashboard 6 ayrı sorgu çalıştırıyor. 10.000 öğrencide bu ne kadar sürer? Nasıl hızlandırılabilir?
> *(Cevap yönü: tek sorguda birleştirme, önbellekleme, indeks ekleme.)*

---

## Sonraki adım

👉 [`11-arama-filtreleme-sayfalama.md`](11-arama-filtreleme-sayfalama.md)
