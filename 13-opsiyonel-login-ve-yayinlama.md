# Modül 12 — Giriş Ekranı ve Yayınlama (Opsiyonel)

**Süre:** 1-2 ders saati
**Ön koşul:** Modül 11
**Durum:** Opsiyonel — zaman kalırsa veya ileri seviye grup için

---

## 🎯 Bu derste ne yapacağız

1. Basit bir kullanıcı girişi ekleyeceğiz
2. Sayfaları giriş yapmamış kullanıcılara kapatacağız
3. Uygulamayı yayınlamayı göstereceğiz

> ⚠️ **Baştan söyle:** Bu, gerçek bir kimlik doğrulama sisteminin **basitleştirilmiş** hâlidir. Gerçek projelerde ASP.NET Core Identity kullanılır — kullanıcı yönetimi, şifre sıfırlama, iki faktörlü doğrulama, hesap kilitleme gibi onlarca özelliği hazır getirir. Biz mekanizmayı anlamak için elle yazıyoruz.

---

## 📖 Kavram 1: Kimlik doğrulama vs yetkilendirme

| Kavram | Soru | Örnek |
|---|---|---|
| **Kimlik doğrulama** (authentication) | "Sen kimsin?" | Kullanıcı adı + şifre |
| **Yetkilendirme** (authorization) | "Buna hakkın var mı?" | Sadece yönetici silebilir |

Biz sadece birincisini yapacağız.

---

## 📖 Kavram 2: Şifreler asla düz metin saklanmaz

**Bu, dersin en önemli güvenlik konusu. Atlama.**

**Sor:** *"Veritabanına şifreyi olduğu gibi yazsak ne olur?"*

Cevaplar:
- Veritabanı sızarsa herkesin şifresi açığa çıkar
- Veritabanına erişimi olan herkes (siz dâhil) şifreleri görür
- İnsanlar aynı şifreyi başka sitelerde de kullanır → zincirleme felaket

**Çözüm: Hash (özet)**

```
"sifre123"  ──hash──▶  "8d969eef6ecad3c29a3a629280e686cf..."
                              ▲
                    Bu geri çevrilemez!
```

Girişte şifreyi tekrar hash'ler, saklanan hash ile karşılaştırırız. Şifreyi hiç bilmeyiz.

> **Not — dürüst olalım:** Aşağıda basitlik için SHA256 kullanıyoruz. Gerçek projelerde bu **yeterli değildir**; şifre hash'lemede BCrypt, Argon2 veya ASP.NET Core'un `PasswordHasher` sınıfı kullanılır. Bunlar kasıtlı olarak **yavaştır** ve her şifreye rastgele bir "tuz" (salt) ekler — böylece saldırgan milyonlarca tahmini hızlıca deneyemez. Öğrenciye bu farkı mutlaka söyle, yoksa SHA256'yı doğru yöntem sanır.

---

## ⌨️ Adım 1: Kullanıcı tablosu

```sql
USE OkulDB;
GO

CREATE TABLE kullanici (
    kullanici_id BIGINT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    kullanici_adi NVARCHAR(100) NOT NULL,
    sifre_hash NVARCHAR(255) NOT NULL,
    ad_soyad NVARCHAR(255) NOT NULL,
    rol NVARCHAR(50) NOT NULL DEFAULT 'Kullanici',
    created_date DATETIME NOT NULL DEFAULT GETDATE(),
    is_active NVARCHAR(255) NOT NULL DEFAULT '1'
);

CREATE UNIQUE INDEX kullanici_adi_unique ON kullanici(kullanici_adi);
GO

-- Test kullanıcısı
-- Kullanıcı adı: admin
-- Şifre: admin123
-- (Aşağıdaki hash, "admin123" metninin SHA256 özetidir)
INSERT INTO kullanici (kullanici_adi, sifre_hash, ad_soyad, rol)
VALUES ('admin',
        '240BE518FABD2724DDB6F04EEB1DA5967448D7E831C08C8FA822809F74C720A9',
        N'Sistem Yöneticisi',
        'Yonetici');
GO
```

> **Hash'i öğrenciye doğrulattır:** Kendi projelerinde `SifreyiHashle("admin123")` metodunu çağırıp çıktının bu değere eşit olduğunu görsünler. Böylece hash'in ne olduğunu somut olarak anlarlar.

---

## ⌨️ Adım 2: Model ve Repository

`Models/Kullanici.cs`:

```csharp
using System.ComponentModel.DataAnnotations;

namespace OkulYonetim.Models;

public class Kullanici
{
    public long KullaniciId { get; set; }
    public string KullaniciAdi { get; set; } = "";
    public string SifreHash { get; set; } = "";
    public string AdSoyad { get; set; } = "";
    public string Rol { get; set; } = "Kullanici";
}

// Giriş formu için ayrı bir ViewModel
public class GirisViewModel
{
    [Required(ErrorMessage = "Kullanıcı adı gerekli.")]
    [Display(Name = "Kullanıcı adı")]
    public string KullaniciAdi { get; set; } = "";

    [Required(ErrorMessage = "Şifre gerekli.")]
    [DataType(DataType.Password)]
    [Display(Name = "Şifre")]
    public string Sifre { get; set; } = "";
}
```

> **Neden ayrı `GirisViewModel`?** Giriş formunda `SifreHash` veya `Rol` alanı olmamalı. Form ne kadar dar olursa o kadar güvenli. Kullanıcının gönderdiği veriye asla fazladan alan bırakma.

`Data/KullaniciRepository.cs`:

```csharp
using System.Security.Cryptography;
using System.Text;
using Microsoft.Data.SqlClient;
using OkulYonetim.Models;

namespace OkulYonetim.Data;

public class KullaniciRepository
{
    private readonly string _baglantiMetni;

    public KullaniciRepository(IConfiguration configuration)
    {
        _baglantiMetni = configuration.GetConnectionString("OkulDb")!;
    }

    /// <summary>
    /// Metni SHA256 ile hash'ler.
    /// ⚠️ Öğretim amaçlıdır. Gerçek projelerde BCrypt/Argon2 kullanın.
    /// </summary>
    public static string SifreyiHashle(string sifre)
    {
        byte[] bayt = Encoding.UTF8.GetBytes(sifre);
        byte[] hash = SHA256.HashData(bayt);
        return Convert.ToHexString(hash);
    }

    /// <summary>
    /// Kullanıcı adı ve şifre doğruysa kullanıcıyı döner, değilse null.
    /// </summary>
    public Kullanici? Dogrula(string kullaniciAdi, string sifre)
    {
        string hash = SifreyiHashle(sifre);

        string sql = @"SELECT kullanici_id, kullanici_adi, ad_soyad, rol
                       FROM kullanici
                       WHERE kullanici_adi = @ad
                         AND sifre_hash    = @hash
                         AND is_active     = '1'";

        using (SqlConnection baglanti = new SqlConnection(_baglantiMetni))
        using (SqlCommand komut = new SqlCommand(sql, baglanti))
        {
            komut.Parameters.AddWithValue("@ad", kullaniciAdi);
            komut.Parameters.AddWithValue("@hash", hash);

            baglanti.Open();
            using (SqlDataReader okuyucu = komut.ExecuteReader())
            {
                if (okuyucu.Read())
                {
                    return new Kullanici
                    {
                        KullaniciId  = okuyucu.GetInt64(okuyucu.GetOrdinal("kullanici_id")),
                        KullaniciAdi = okuyucu.GetString(okuyucu.GetOrdinal("kullanici_adi")),
                        AdSoyad      = okuyucu.GetString(okuyucu.GetOrdinal("ad_soyad")),
                        Rol          = okuyucu.GetString(okuyucu.GetOrdinal("rol"))
                    };
                }
            }
        }

        return null;
    }
}
```

---

## ⌨️ Adım 3: Çerez tabanlı oturum

`Program.cs`:

```csharp
using Microsoft.AspNetCore.Authentication.Cookies;

// ... builder.Services satırlarının arasına:

builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(secenekler =>
    {
        secenekler.LoginPath = "/Hesap/Giris";           // giriş yapılmamışsa buraya yönlendir
        secenekler.AccessDeniedPath = "/Hesap/Yetkisiz"; // yetkisi yoksa buraya
        secenekler.ExpireTimeSpan = TimeSpan.FromHours(4);
    });

builder.Services.AddScoped<KullaniciRepository>();

var app = builder.Build();

// ... boru hattında SIRA ÖNEMLİ:
app.UseRouting();
app.UseAuthentication();   // ⭐ ÖNCE: "sen kimsin?"
app.UseAuthorization();    // ⭐ SONRA: "hakkın var mı?"
```

> ⚠️ **Sıra kritik.** `UseAuthentication` mutlaka `UseAuthorization`'dan önce gelmeli. Ters yazarsan giriş yapmış kullanıcılar bile "yetkisiz" görür ve sebebini bulmak saatler alır.

---

## ⌨️ Adım 4: HesapController

```csharp
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using OkulYonetim.Data;
using OkulYonetim.Models;

namespace OkulYonetim.Controllers;

public class HesapController : Controller
{
    private readonly KullaniciRepository _repo;

    public HesapController(KullaniciRepository repo)
    {
        _repo = repo;
    }

    [HttpGet]
    public IActionResult Giris()
    {
        return View();
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Giris(GirisViewModel model)
    {
        if (!ModelState.IsValid)
            return View(model);

        var kullanici = _repo.Dogrula(model.KullaniciAdi, model.Sifre);

        if (kullanici == null)
        {
            // ⚠️ "Kullanıcı yok" ile "şifre yanlış" AYRIMI YAPMA!
            ModelState.AddModelError("", "Kullanıcı adı veya şifre hatalı.");
            return View(model);
        }

        // Kullanıcının kimlik bilgilerini hazırla
        var iddialar = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, kullanici.KullaniciId.ToString()),
            new Claim(ClaimTypes.Name, kullanici.AdSoyad),
            new Claim("KullaniciAdi", kullanici.KullaniciAdi),
            new Claim(ClaimTypes.Role, kullanici.Rol)
        };

        var kimlik = new ClaimsIdentity(iddialar, CookieAuthenticationDefaults.AuthenticationScheme);

        // Çerezi oluştur — kullanıcı artık giriş yapmış sayılır
        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(kimlik));

        return RedirectToAction("Index", "Home");
    }

    public async Task<IActionResult> Cikis()
    {
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToAction("Giris");
    }

    public IActionResult Yetkisiz() => View();
}
```

### Kavramlar

**`Claim` (iddia) nedir?**
> *"Kullanıcı hakkındaki bir bilgi parçası. 'Adı Ahmet', 'rolü Yönetici', 'id'si 5'... Bunlar çereze şifrelenerek yazılır ve her istekte sunucuya gelir."*

**`async` / `await` nedir?**
> *"Bazı işler zaman alır. `await`, 'bu işi bekle ama bu arada sunucu başka isteklerle ilgilenebilsin' demektir. Şimdilik 'çereze yazma işlemi böyle yapılıyor' demeniz yeterli."*

**Neden "kullanıcı adı veya şifre hatalı"?**
Ayrı ayrı söylersek saldırgan hangi kullanıcı adlarının var olduğunu öğrenir. Buna **kullanıcı sayımı (user enumeration)** denir. Belirsiz mesaj kasıtlıdır.

> **Güvenlik dersi #4** — bunu vurgula: bazen daha az bilgi vermek daha güvenlidir.

---

## ⌨️ Adım 5: Giriş sayfası

`Views/Hesap/Giris.cshtml`:

```html
@model OkulYonetim.Models.GirisViewModel
@{
    ViewData["Title"] = "Giriş";
    Layout = null;   // ⭐ Giriş sayfasında sol menü olmasın
}

<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Giriş - Okul Yönetim Sistemi</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
</head>
<body class="bg-light">

    <div class="container">
        <div class="row justify-content-center align-items-center" style="min-height: 100vh;">
            <div class="col-md-4">

                <div class="card border-0 shadow">
                    <div class="card-body p-4">

                        <div class="text-center mb-4">
                            <i class="bi bi-mortarboard-fill fs-1 text-primary"></i>
                            <h5 class="mt-2 mb-0">Okul Yönetim Sistemi</h5>
                            <p class="text-muted small">Devam etmek için giriş yapın</p>
                        </div>

                        <form asp-action="Giris" method="post">

                            <div asp-validation-summary="ModelOnly" class="alert alert-danger py-2 small"></div>

                            <div class="mb-3">
                                <label asp-for="KullaniciAdi" class="form-label"></label>
                                <input asp-for="KullaniciAdi" class="form-control" autofocus />
                                <span asp-validation-for="KullaniciAdi" class="text-danger small"></span>
                            </div>

                            <div class="mb-3">
                                <label asp-for="Sifre" class="form-label"></label>
                                <input asp-for="Sifre" type="password" class="form-control" />
                                <span asp-validation-for="Sifre" class="text-danger small"></span>
                            </div>

                            <button type="submit" class="btn btn-primary w-100">
                                Giriş yap
                            </button>

                        </form>

                    </div>
                </div>

                <p class="text-center text-muted small mt-3">
                    Test hesabı: <code>admin</code> / <code>admin123</code>
                </p>

            </div>
        </div>
    </div>

</body>
</html>
```

> Bu satırı gerçek projede **silmeyi unutma** demeyi ihmal etme. Test hesabı bilgisini giriş ekranında göstermek yalnızca ders ortamı için uygundur.

---

## ⌨️ Adım 6: Sayfaları koru

Her controller'ın üstüne `[Authorize]` ekle:

```csharp
using Microsoft.AspNetCore.Authorization;

[Authorize]   // ⭐ Bu controller'a giriş yapmadan girilemez
public class FakulteController : Controller
{
    // ...
}
```

`HesapController` **hariç** hepsine ekle. Giriş sayfası herkese açık olmalı.

Alternatif — tek yerden tüm uygulamayı koru (`Program.cs`):

```csharp
builder.Services.AddControllersWithViews(secenekler =>
{
    var politika = new Microsoft.AspNetCore.Authorization.AuthorizationPolicyBuilder()
        .RequireAuthenticatedUser()
        .Build();
    secenekler.Filters.Add(new Microsoft.AspNetCore.Mvc.Authorization.AuthorizeFilter(politika));
});
```

Bu durumda giriş sayfasına `[AllowAnonymous]` eklemen gerekir:

```csharp
[AllowAnonymous]
public class HesapController : Controller { }
```

> **Hangisi daha iyi?** İkincisi. Sebep: birinci yöntemde yeni bir controller yazıp `[Authorize]` eklemeyi unutursan sayfa herkese açık kalır. İkincisinde varsayılan "kapalı"dır, açmak için bilinçli bir hamle gerekir. **Güvenlikte varsayılan her zaman en kısıtlayıcı seçenek olmalı.**

---

## ⌨️ Adım 7: Layout'a kullanıcı bilgisi

`_Layout.cshtml`'deki üst çubuğa:

```html
<div class="d-flex justify-content-between align-items-center border-bottom pb-2 mb-4">
    <h4 class="mb-0">@ViewData["Title"]</h4>

    <div class="dropdown">
        <button class="btn btn-sm btn-outline-secondary dropdown-toggle"
                data-bs-toggle="dropdown">
            <i class="bi bi-person-circle"></i> @User.Identity?.Name
        </button>
        <ul class="dropdown-menu dropdown-menu-end">
            <li>
                <span class="dropdown-item-text small text-muted">
                    @User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value
                </span>
            </li>
            <li><hr class="dropdown-divider"></li>
            <li>
                <a class="dropdown-item" asp-controller="Hesap" asp-action="Cikis">
                    <i class="bi bi-box-arrow-right"></i> Çıkış yap
                </a>
            </li>
        </ul>
    </div>
</div>
```

`@User` — giriş yapmış kullanıcı. Her view'da hazır bulunur.

---

## ▶️ Çalıştır ve gör

| Test | Beklenen |
|---|---|
| `/Fakulte` (giriş yapmadan) | Giriş sayfasına yönlendirir |
| Yanlış şifre | "Kullanıcı adı veya şifre hatalı" |
| Doğru giriş | Dashboard'a gider |
| Sağ üstte | Ad soyad ve rol görünür |
| Çıkış yap | Giriş sayfasına döner |
| Çıkıştan sonra `/Fakulte` | Yine giriş sayfası |
| Tarayıcıyı kapat-aç | Çerez hâlâ geçerli (4 saat) |

---

## 🚀 Yayınlama

### Seçenek 1 — IIS (Windows Server)

```bash
dotnet publish -c Release -o C:\yayin
```

1. Sunucuya **ASP.NET Core Hosting Bundle** kur
2. IIS'te yeni site oluştur, klasörü göster
3. Uygulama havuzunu **"No Managed Code"** yap ⚠️ (en sık atlanan adım)
4. `appsettings.json`'daki bağlantı dizesini sunucuya göre güncelle

### Seçenek 2 — Kendi kendine çalışan dosya

```bash
dotnet publish -c Release -r win-x64 --self-contained true -o C:\yayin
```
Hedef bilgisayarda .NET kurulu olmasa bile çalışır. Boyut büyür (~70 MB).

### Seçenek 3 — Azure (öğrenciler için ücretsiz)

Öğrenciler https://azure.microsoft.com/free/students adresinden ücretsiz kredi alabilir.

Visual Studio → Projeye sağ tık → **Yayımla** → Azure App Service → sihirbazı takip et.

### ⚠️ Yayınlamadan önce kontrol listesi

```
□ appsettings.json'daki bağlantı dizesi canlı sunucuya göre ayarlandı
□ Şifreler appsettings.json'da DEĞİL (ortam değişkeni veya Azure ayarları)
□ ASPNETCORE_ENVIRONMENT = Production
□ Giriş sayfasındaki test hesabı bilgisi silindi
□ Varsayılan 'admin/admin123' hesabının şifresi değiştirildi
□ HTTPS zorunlu
□ Veritabanı yedeği alındı
```

> **Bu kontrol listesi tek başına bir ders konusu.** Gerçek dünyada projeler tam da bu maddeler atlandığı için hacklenir.

---

## ⚠️ Sık yapılan hatalar

| Hata | Sebep | Çözüm |
|---|---|---|
| Sonsuz yönlendirme döngüsü | Giriş sayfası da `[Authorize]` | `[AllowAnonymous]` ekle |
| Giriş yapılıyor ama sayfa hâlâ engelli | `UseAuthentication` yanlış sırada | `UseAuthorization`'dan **önce** olmalı |
| `@User.Identity.Name` boş | Claim eklenmemiş | `ClaimTypes.Name` claim'ini ekle |
| Şifre doğru ama giriş olmuyor | Hash farklı üretiliyor | Aynı metodu kullandığından emin ol; büyük/küçük harf |
| `SignInAsync` bulunamıyor | using eksik | `using Microsoft.AspNetCore.Authentication;` |
| Çıkış yapıyor ama geri dönünce hâlâ girişli | Tarayıcı önbelleği | Ctrl+F5 |
| IIS'te 500.19 hatası | Hosting Bundle kurulu değil | Kur ve IIS'i yeniden başlat |
| IIS'te 502.5 hatası | Uygulama havuzu ayarı | "No Managed Code" seç |

---

## ✏️ Öğrenci alıştırması

**A. Rol tabanlı yetki**
Sadece `Yonetici` rolündeki kullanıcılar silme yapabilsin:
```csharp
[Authorize(Roles = "Yonetici")]
public IActionResult DeleteConfirmed(long id) { ... }
```
Ve butonu diğer kullanıcılara hiç gösterme:
```html
@if (User.IsInRole("Yonetici")) { <a ...>Sil</a> }
```

**B. Kullanıcı yönetimi ekranı**
Kullanıcılar için CRUD yaz. (Artık kalıbı biliyorsun!) Şifre alanı düzenlemede boş bırakılırsa değişmesin.

**C. Şifre değiştirme**
Kullanıcı kendi şifresini değiştirebilsin. Mevcut şifre + yeni şifre + yeni şifre tekrar.
İpucu: `[Compare("YeniSifre")]` özniteliği iki alanın eşitliğini kontrol eder.

**D. Kim ne yaptı? (zorlayıcı)**
`created_by` ve `updated_by` sütunları ekle. Kaydı kimin oluşturduğunu/güncellediğini sakla.
```csharp
var kullaniciId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
```

**E. Düşünme soruları**
1. Şifreleri düz metin saklasaydık ve veritabanı sızsaydı hangi zararlar oluşurdu? Sadece bu site mi etkilenirdi?
2. SHA256 neden şifre hash'lemek için yeterli değil? "Yavaş olması iyidir" ne demek?
3. Çerez çalınırsa ne olur? Nasıl korunulur? (İpucu: HTTPS, HttpOnly, SameSite, kısa süre)

---

## 🎓 Kurs sonu

Öğrenciler artık şunları yapabiliyor:

- ✅ Veritabanı tasarımını okuyabiliyor ve sorgulayabiliyor
- ✅ ASP.NET Core MVC projesi kurabiliyor
- ✅ ADO.NET ile güvenli veritabanı işlemleri yazabiliyor
- ✅ Tam bir CRUD ekranı geliştirebiliyor
- ✅ Bootstrap ile düzgün bir arayüz yapabiliyor
- ✅ Form doğrulaması ve hata yönetimi kurabiliyor
- ✅ Arama, filtreleme, sayfalama ekleyebiliyor
- ✅ SQL injection ve CSRF'in ne olduğunu biliyor
- ✅ Basit bir kimlik doğrulama kurabiliyor

### Son ders: sunum günü

Her öğrenci 5 dakikada kendi projesini gösterir. Sorular:
- En zorlandığın kısım neydi?
- Baştan yapsan neyi farklı yapardın?
- Bir özellik daha eklesen ne eklerdin?

### Bundan sonra ne öğrenmeliler?

Tahtaya bir yol haritası çiz:

```
ŞU AN BURADASINIZ
      │
      ├──▶ Entity Framework Core     (SQL'i sizin yerinize yazar)
      │
      ├──▶ ASP.NET Core Identity     (hazır kullanıcı sistemi)
      │
      ├──▶ Web API + JavaScript      (mobil uygulamalar da bağlanabilir)
      │
      ├──▶ Git ve GitHub             (takım çalışması)
      │
      └──▶ Katmanlı mimari, Dependency Injection, testler
```

> **Kapanış cümlesi önerisi:** *"Bugün yazdığınız uygulama, dünyadaki milyonlarca kurumsal uygulamanın temel iskeletiyle aynı. Bundan sonrası daha iyi araçlar öğrenmekten ibaret — mantığı zaten biliyorsunuz."*

---

## Ekler

- [`EK-A-sik-hatalar.md`](EK-A-sik-hatalar.md) — Tüm hataların birleşik listesi
- [`EK-B-odevler-ve-degerlendirme.md`](EK-B-odevler-ve-degerlendirme.md) — Ödev listesi ve rubrikler
- [`EK-C-test-verisi.sql`](EK-C-test-verisi.sql) — Örnek veriler
