# Modül 2 — İlk MVC Projesi

**Süre:** 1 ders saati
**Ön koşul:** Modül 1 (veritabanı hazır)

---

## 🎯 Bu derste ne yapacağız

Asıl projemizi oluşturacağız, klasör yapısını tanıyacağız ve MVC'nin ne demek olduğunu **kendi yazdığımız bir sayfayla** göreceğiz.

**Ders sonunda öğrenci:** Bir web isteğinin Controller → View yolculuğunu anlatabilecek.

---

## 📖 Kavram 1: Web nasıl çalışır?

Tahtaya çiz:

```
   TARAYICI                              SUNUCU
  (öğrencinin                        (bizim yazdığımız
   bilgisayarı)                        .NET uygulaması)

   ┌────────┐    "/Fakulte sayfasını    ┌──────────┐
   │        │ ───── istiyorum" ───────▶ │          │
   │ Chrome │                           │  .NET    │
   │        │ ◀──── "buyur, HTML" ───── │          │
   └────────┘                           └──────────┘
```

**Anlat:** Tarayıcı sadece **soru sorar**. Sunucu **cevap üretir**. Bizim işimiz, sunucu tarafında "hangi soruya ne cevap verileceğini" yazmak.

---

## 📖 Kavram 2: MVC nedir?

MVC = **M**odel – **V**iew – **C**ontroller. Bir restoran benzetmesi kur:

```
🧑 MÜŞTERİ (kullanıcı)
    │  "Bir tabak öğrenci listesi lütfen"
    ▼
👨‍🍳 GARSON = CONTROLLER
    │  Siparişi alır, mutfağa iletir, tabağı getirir
    │  Kendisi yemek pişirmez, sadece yönlendirir
    ▼
🍳 MUTFAK / DEPO = MODEL
    │  Veriyi tutar ve getirir (veritabanı işi burada)
    ▼
🍽️ TABAK SUNUMU = VIEW
       Veriyi kullanıcıya güzel gösterir (HTML)
```

| Katman | Görevi | Bizim projede |
|---|---|---|
| **Model** | Veriyi temsil eder | `Models/Fakulte.cs` — bir fakültenin ad, adres, telefon bilgisi |
| **View** | Ekranda görüneni üretir | `Views/Fakulte/Index.cshtml` — HTML tablo |
| **Controller** | İstekleri karşılar, ikisini bağlar | `Controllers/FakulteController.cs` |

> **Altın kural (tahtaya yaz, dersin sonuna kadar silme):**
> **Controller ince olmalı, View aptal olmalı.**
> Controller'da uzun uzun iş mantığı yazma. View'da hesap yapma. View sadece gösterir.

---

## ⌨️ Adım adım: Projeyi oluştur

### Visual Studio ile

1. **Dosya → Yeni → Proje**
2. Şablon: `ASP.NET Core Web App (Model-View-Controller)`
   ⚠️ Dikkat: "Web App" (Razor Pages) veya "Web API" **değil**. Parantez içinde MVC yazan.
3. **Proje adı:** `OkulYonetim`
4. **Konum:** `C:\Projeler\` (Türkçe karakter ve boşluk içermeyen bir yol seç!)
5. **Framework:** .NET 10.0
6. **Configure for HTTPS:** ☑️ işaretli kalsın
7. Oluştur

### Terminal / VS Code ile

```bash
dotnet new mvc -n OkulYonetim
cd OkulYonetim
code .
```

---

## 📖 Kavram 3: Klasörleri tanıyalım

Solution Explorer'ı aç ve **her klasöre tek tek tıklayarak** anlat. Öğrenci ilk kez bu kadar çok klasör görüyor, kaybolması normal.

```
OkulYonetim/
│
├── 📄 Program.cs           ⭐ Uygulama buradan başlar. En önemli dosya.
├── 📄 appsettings.json     ⭐ Ayarlar. Veritabanı adresini buraya yazacağız.
├── 📄 OkulYonetim.csproj   Proje ayarları ve kurulu paketler
│
├── 📁 Controllers/         ⭐ İstekleri karşılayan sınıflar
│   └── HomeController.cs
│
├── 📁 Models/              ⭐ Veri sınıfları
│   └── ErrorViewModel.cs
│
├── 📁 Views/               ⭐ HTML şablonları
│   ├── Home/
│   │   ├── Index.cshtml    (ana sayfa)
│   │   └── Privacy.cshtml
│   ├── Shared/
│   │   └── _Layout.cshtml  (tüm sayfaların ortak iskeleti)
│   └── _ViewImports.cshtml
│
├── 📁 wwwroot/             Tarayıcının doğrudan erişebildiği dosyalar
│   ├── css/
│   ├── js/
│   └── lib/                (bootstrap, jquery burada hazır gelir)
│
└── 📁 Properties/
    └── launchSettings.json (hangi portta çalışacağı)
```

> **Öğrenciye vurgula:** `wwwroot` özel bir klasör. İçine koyduğun her şeyi tarayıcı doğrudan görebilir. Gizli hiçbir şeyi oraya koyma!

### Adlandırma kuralı — çok önemli!

ASP.NET Core'da klasör ve dosya isimleri **sihirli değil, kurallı**. Bunu net anlat:

```
FakulteController.cs  içindeki  Index()  metodu
        │                          │
        ▼                          ▼
Views/ Fakulte /                 Index .cshtml
```

**Kural:** `XController` içindeki `Y()` metodu → `Views/X/Y.cshtml` dosyasını arar.

İsim uyuşmazsa uygulama "view bulunamadı" hatası verir. Derste bu hatayı **kasten** yaptır (aşağıda alıştırma var).

---

## ⌨️ Adım adım: Program.cs'i inceleyelim

`Program.cs` dosyasını aç. Şuna benzer bir şey göreceksin:

```csharp
var builder = WebApplication.CreateBuilder(args);

// 1. BÖLÜM: Servisleri tanıt
builder.Services.AddControllersWithViews();

var app = builder.Build();

// 2. BÖLÜM: İstek boru hattını kur
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.UseAuthorization();

// 3. BÖLÜM: Adres kuralı
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
```

**Satır satır açıklama:**

| Satır | Ne yapıyor |
|---|---|
| `CreateBuilder(args)` | Uygulamayı kurmaya başla |
| `AddControllersWithViews()` | "Bu bir MVC uygulaması, Controller ve View kullanacağım" |
| `UseHttpsRedirection()` | `http://` ile gelen isteği `https://`'e yönlendir (güvenlik) |
| `UseStaticFiles()` | `wwwroot` klasöründeki dosyaları servis et |
| `UseRouting()` | Gelen adresi çözümle |
| `MapControllerRoute` | ⭐ Adres kuralı — aşağıda ayrıntılı |
| `app.Run()` | Uygulamayı başlat ve istekleri dinlemeye başla |

> **.NET 10 notu:** Yeni şablonlar `app.UseStaticFiles()` yerine `app.MapStaticAssets()` kullanabilir. İkisi de çalışır; bu ders için `UseStaticFiles()` yeterli ve anlaşılması daha kolay. Şablonun getirdiği hâli değiştirmene gerek yok.

### Adres kuralını (routing) mutlaka anlat

```
pattern: "{controller=Home}/{action=Index}/{id?}"
```

Bu tek satır, tüm uygulamanın adres mantığını belirler:

| Yazılan adres | Çalışan kod |
|---|---|
| `/` | `HomeController` → `Index()` *(varsayılanlar devreye girer)* |
| `/Fakulte` | `FakulteController` → `Index()` |
| `/Fakulte/Create` | `FakulteController` → `Create()` |
| `/Fakulte/Edit/5` | `FakulteController` → `Edit(5)` |
| `/Ogrenci/Details/12` | `OgrenciController` → `Details(12)` |

**Dikkat:**
- `=Home` ve `=Index` → **varsayılan** değer. Yazılmazsa bunlar kullanılır.
- `id?` sonundaki `?` → **isteğe bağlı**. Olmayabilir.
- Adreste `Controller` kelimesi **yazılmaz**. `/Fakulte` yazarsın, `/FakuleController` değil.

---

## ⌨️ Adım adım: İlk kendi sayfamız

Şimdi öğrenciye MVC akışını **canlı gösteriyoruz**. Bu 5 dakika, 1 saatlik teoriden daha etkili.

### 1. Controller oluştur

`Controllers` klasörüne sağ tık → **Ekle → Sınıf** → `DenemeController.cs`

```csharp
using Microsoft.AspNetCore.Mvc;   // MVC araçlarını kullanabilmek için

namespace OkulYonetim.Controllers;

public class DenemeController : Controller
{
    // ↑ "Controller" sınıfından türetiyoruz.
    //   Bu sayede View(), RedirectToAction() gibi hazır metotlar geliyor.

    public IActionResult Merhaba()
    {
        // ViewBag: Controller'dan View'a küçük veri taşımanın en kolay yolu
        ViewBag.Mesaj = "Merhaba! Bu benim ilk sayfam.";
        ViewBag.Tarih = DateTime.Now;

        return View();   // Views/Deneme/Merhaba.cshtml dosyasını arar
    }
}
```

> **Kritik nokta:** Sınıf adı `DenemeController`, ama adres `/Deneme`. ASP.NET Core sondaki "Controller" kelimesini otomatik atar.

### 2. View oluştur

`Views` klasörüne sağ tık → **Ekle → Yeni Klasör** → `Deneme`
`Deneme` klasörüne sağ tık → **Ekle → Yeni Öğe → Razor View - Empty** → `Merhaba.cshtml`

```html
@{
    ViewData["Title"] = "Deneme Sayfası";
}

<h1>@ViewBag.Mesaj</h1>

<p>Şu anki tarih ve saat: @ViewBag.Tarih</p>

<p>2 + 3 = @(2 + 3)</p>
```

### 3. Çalıştır

▶️ butonuna bas, adres çubuğuna `/Deneme/Merhaba` yaz.

---

## 📖 Kavram 4: Razor sözdizimi

View dosyalarının uzantısı `.cshtml` = **C**# + **HTML**. Bunlara **Razor** denir.

Tek kural: **`@` işareti gördüğün yerde C# başlar.**

```html
<!-- Tek değer yazdırma -->
<p>@ViewBag.Mesaj</p>

<!-- İfade — parantez içine al -->
<p>@(2 + 3)</p>
<p>@(ogrenci.Ad + " " + ogrenci.Soyad)</p>

<!-- Kod bloğu -->
@{
    var bugun = DateTime.Now;
    var selamlama = bugun.Hour < 12 ? "Günaydın" : "İyi günler";
}
<p>@selamlama</p>

<!-- Koşul -->
@if (ViewBag.Sayi > 10)
{
    <p>Sayı büyük</p>
}
else
{
    <p>Sayı küçük</p>
}

<!-- Döngü — en çok kullanacağımız -->
@foreach (var isim in new[] { "Ali", "Ayşe", "Mehmet" })
{
    <li>@isim</li>
}

<!-- E-posta yazarken @ sorunu: iki kez yaz -->
<p>info@@okul.edu.tr</p>
```

> **Sık hata uyarısı:** HTML içine e-posta yazarken `@` işareti Razor'ı tetikler. `info@okul.edu.tr` yazarsan hata alırsın. `info@@okul.edu.tr` yazacaksın.

---

## ▶️ Çalıştır ve gör — canlı deney

Öğrenciler izlerken şu üç deneyi **kasten** yap. Hata mesajı okumayı öğretmenin en iyi yolu bu.

### Deney 1: View'ın adını yanlış yaz
`Merhaba.cshtml` dosyasının adını `Merhaba2.cshtml` yap, çalıştır.

```
InvalidOperationException: The view 'Merhaba' was not found.
Searched locations:
  /Views/Deneme/Merhaba.cshtml
  /Views/Shared/Merhaba.cshtml
```

*"Bakın, hata mesajı nereye baktığını bile söylüyor. Hata mesajları düşman değil, harita."*

### Deney 2: Yanlış adrese git
`/Deneme/Selam` yaz → 404 hatası. Çünkü `Selam()` diye bir metot yok.

### Deney 3: Klasör adını yanlış yaz
`Views/Deneme` klasörünün adını `Views/Denemeler` yap → yine view bulunamadı hatası.

---

## ⚠️ Sık yapılan hatalar

| Hata | Sebep | Çözüm |
|---|---|---|
| `The view 'X' was not found` | Klasör/dosya adı metot adıyla uyuşmuyor | `Views/[ControllerAdı]/[MetotAdı].cshtml` kuralını kontrol et |
| 404 Not Found | Metot yok veya `public` değil | Metodun `public` olduğundan emin ol |
| `The name 'View' does not exist` | Sınıf `Controller`'dan türetilmemiş | `: Controller` ekle |
| `using Microsoft.AspNetCore.Mvc` eksik hatası | Kütüphane çağrılmamış | Dosyanın en üstüne `using` satırını ekle |
| Sayfa açılmıyor, boş beyaz | View dosyası boş | View'a en az bir HTML etiketi yaz |
| Razor'da `@` yüzünden hata | E-posta veya CSS içindeki `@` | `@@` şeklinde çift yaz |
| Değişiklik yaptım ama sayfa eskisini gösteriyor | Tarayıcı önbelleği | Ctrl+F5 ile sert yenileme yap |

---

## ✏️ Öğrenci alıştırması

**A. Tekrar (herkes)**
`OkulYonetim` projesini kendi bilgisayarında oluştur, `DenemeController` ve `Merhaba` sayfasını yaz, çalıştır.

**B. Kendi sayfan**
`TanitimController` adında yeni bir controller oluştur. İçinde `Ben()` adında bir metot olsun. Bu metot `ViewBag` ile kendi adını, numaranı ve bölümünü View'a göndersin. View bunları bir Bootstrap kartı içinde göstersin.

İpucu — Bootstrap kartı:
```html
<div class="card" style="width: 20rem;">
    <div class="card-body">
        <h5 class="card-title">@ViewBag.AdSoyad</h5>
        <p class="card-text">@ViewBag.Numara</p>
    </div>
</div>
```

**C. Hata avı**
`Merhaba.cshtml` dosyasının adını bilerek yanlış yaz, aldığın hata mesajının ekran görüntüsünü al ve **kendi cümlelerinle** ne demek istediğini yaz.

**D. Düşünme sorusu**
> `/Ogrenci/Detay/7` adresi yazıldığında hangi controller, hangi metot çalışır ve `7` sayısı nereye gider?

---

## Sonraki adım

👉 [`04-adonet-ilk-baglanti.md`](04-adonet-ilk-baglanti.md) — Veritabanına bağlanıp gerçek veriyi ekrana basacağız.
