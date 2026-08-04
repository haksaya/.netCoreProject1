# Modül 4 — Bootstrap Dashboard İskeleti

**Süre:** 1 ders saati
**Ön koşul:** Modül 3 (fakülte listesi çalışıyor)

---

## 🎯 Bu derste ne yapacağız

Uygulamaya sol menülü, üst çubuklu profesyonel bir yönetim paneli görünümü kazandıracağız. Bundan sonraki tüm sayfalar bu iskeletin içine oturacak.

**Ders sonunda öğrenci:** Layout kavramını ve Bootstrap grid sistemini kullanabilecek.

---

## 📖 Kavram 1: Layout (ortak sayfa iskeleti) nedir?

**Sor:** *"10 sayfalık bir siteniz var. Menüye yeni bir link eklemek istiyorsunuz. 10 dosyayı da tek tek mi açacaksınız?"*

Çözüm: Ortak kısımları **tek bir dosyada** yazmak.

```
┌─────────────────────────────────────────┐
│  _Layout.cshtml                         │
│  ┌───────────────────────────────────┐  │
│  │  ÜST ÇUBUK (her sayfada aynı)     │  │
│  ├─────────┬─────────────────────────┤  │
│  │         │                         │  │
│  │  SOL    │   @RenderBody()         │  │
│  │  MENÜ   │   ↑ Buraya her sayfanın │  │
│  │ (aynı)  │     kendi içeriği gelir │  │
│  │         │                         │  │
│  ├─────────┴─────────────────────────┤  │
│  │  ALT BİLGİ (her sayfada aynı)     │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

`@RenderBody()` = "buraya sayfanın kendi içeriğini koy" demek. Layout'un kalbi bu tek satırdır.

**Layout nasıl otomatik uygulanıyor?**
`Views/_ViewStart.cshtml` dosyasına bak:
```csharp
@{
    Layout = "_Layout";
}
```
Bu dosya, her view çalışmadan önce çalışır ve "layout olarak `_Layout` kullan" der. Sihir burada.

> **Alt çizgi (`_`) ne demek?** Başında `_` olan view dosyaları "yardımcı" dosyalardır, tek başına bir sayfa değildir. Bir isimlendirme geleneği.

---

## 📖 Kavram 2: Bootstrap nedir?

> *"CSS yazmak zaman alır. Bootstrap, hazır CSS sınıfları veren bir kütüphane. `class="btn btn-primary"` yazarsınız, karşınıza düzgün bir mavi buton çıkar."*

En çok kullanacağımız sınıflar — bu tabloyu öğrenciye dağıt:

| Sınıf | Ne yapar |
|---|---|
| `container`, `container-fluid` | İçeriği ortalar / tam genişlik yapar |
| `row`, `col-md-6` | Satır ve sütun (grid sistemi) |
| `btn btn-primary` | Mavi buton |
| `btn btn-success` / `btn-danger` / `btn-warning` | Yeşil / kırmızı / sarı buton |
| `btn-sm` / `btn-lg` | Küçük / büyük buton |
| `table table-striped table-hover` | Çizgili, üzerine gelince renklenen tablo |
| `card` + `card-body` | Kutu / kart |
| `alert alert-success` / `alert-danger` | Yeşil / kırmızı bildirim kutusu |
| `form-control` | Metin kutusu |
| `form-label` | Etiket |
| `form-select` | Açılır liste |
| `badge bg-primary` | Küçük renkli etiket |
| `mt-3` `mb-2` `p-4` | Boşluk (margin-top:3, margin-bottom:2, padding:4) |
| `d-flex` `justify-content-between` | Yan yana dizme, iki uca yaslama |
| `text-center` `text-muted` `fw-bold` | Ortala, soluk renk, kalın yazı |

### Bootstrap grid sistemi

Ekran **12 sütuna** bölünmüştür:

```
|--1--|--2--|--3--|--4--|--5--|--6--|--7--|--8--|--9--|--10--|--11--|--12--|

col-md-6 + col-md-6      →  |------ yarım ------|------ yarım ------|
col-md-4 x 3             →  |--- 1/3 ---|--- 1/3 ---|--- 1/3 ---|
col-md-3 + col-md-9      →  |-- çeyrek --|-------- dörtte üç --------|
```

`md` = "medium ve üstü ekranlarda". Telefonda otomatik alt alta gelir. **Duyarlı (responsive) tasarım** budur.

---

## ⌨️ Adım adım: Layout'u yaz

`Views/Shared/_Layout.cshtml` dosyasını aç ve **içeriğini tamamen sil**, yerine şunu yaz:

```html
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>@ViewData["Title"] - Okul Yönetim Sistemi</title>

    <!-- Bootstrap 5 CSS (internetten geliyor) -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons (menü ikonları için) -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">

    <style>
        /* Sol menü stilleri */
        .sidebar {
            min-height: 100vh;          /* Ekran boyu kadar uzun */
            background-color: #1e293b;   /* Koyu lacivert */
        }
        .sidebar a {
            color: #cbd5e1;
            text-decoration: none;
            padding: 12px 20px;
            display: block;
            border-left: 3px solid transparent;
        }
        .sidebar a:hover {
            background-color: #334155;
            color: #ffffff;
        }
        .sidebar a.active {
            background-color: #334155;
            color: #ffffff;
            border-left: 3px solid #3b82f6;  /* Aktif sayfada mavi çizgi */
        }
        .sidebar-baslik {
            color: #ffffff;
            padding: 20px;
            font-size: 1.1rem;
            font-weight: bold;
            border-bottom: 1px solid #334155;
        }
    </style>
</head>
<body class="bg-light">

    <div class="container-fluid">
        <div class="row">

            <!-- ============ SOL MENÜ ============ -->
            <nav class="col-md-3 col-lg-2 sidebar p-0">
                <div class="sidebar-baslik">
                    <i class="bi bi-mortarboard-fill"></i> Okul Yönetim
                </div>

                <a asp-controller="Home" asp-action="Index">
                    <i class="bi bi-speedometer2"></i> Panel
                </a>
                <a asp-controller="Fakulte" asp-action="Index">
                    <i class="bi bi-building"></i> Fakülteler
                </a>
                <a asp-controller="Bolum" asp-action="Index">
                    <i class="bi bi-diagram-3"></i> Bölümler
                </a>
                <a asp-controller="Ogrenci" asp-action="Index">
                    <i class="bi bi-people"></i> Öğrenciler
                </a>
                <a asp-controller="Akademisyen" asp-action="Index">
                    <i class="bi bi-person-badge"></i> Akademisyenler
                </a>
            </nav>

            <!-- ============ SAĞ İÇERİK ALANI ============ -->
            <main class="col-md-9 col-lg-10 px-4 py-3">

                <!-- Üst çubuk -->
                <div class="d-flex justify-content-between align-items-center
                            border-bottom pb-2 mb-4">
                    <h4 class="mb-0">@ViewData["Title"]</h4>
                    <span class="text-muted small">
                        <i class="bi bi-calendar3"></i> @DateTime.Now.ToString("dd MMMM yyyy")
                    </span>
                </div>

                <!-- ⭐ HER SAYFANIN KENDİ İÇERİĞİ BURAYA GELİR -->
                @RenderBody()

                <!-- Alt bilgi -->
                <footer class="mt-5 pt-3 border-top text-muted small text-center">
                    &copy; @DateTime.Now.Year — Okul Yönetim Sistemi | Web Programlama Dersi
                </footer>
            </main>

        </div>
    </div>

    <!-- Bootstrap JavaScript (modal, dropdown gibi şeyler için gerekli) -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

    @* Sayfaya özel script varsa buraya eklenir *@
    @await RenderSectionAsync("Scripts", required: false)
</body>
</html>
```

### 📖 Kavram 3: Tag Helper nedir?

Menüde şu satıra dikkat çek:

```html
<a asp-controller="Fakulte" asp-action="Index">Fakülteler</a>
```

`asp-controller` ve `asp-action` normal HTML değil — bunlara **Tag Helper** denir. ASP.NET Core bunları görünce arka planda şuna çevirir:

```html
<a href="/Fakulte/Index">Fakülteler</a>
```

**Neden `href` yazmıyoruz?**
> *"Yarın adres yapısını değiştirdiğinizde, elle yazdığınız tüm `href`'ler kırılır. Tag Helper kullanırsanız ASP.NET Core adresi kendisi hesaplar, hep doğru olur."*

Tarayıcıda **sağ tık → Sayfa kaynağını görüntüle** yapıp dönüşmüş hâlini göster. Bu, "sunucu HTML üretiyor" fikrini somutlaştırır.

> Tag Helper'ların çalışması için `Views/_ViewImports.cshtml` dosyasında şu satır olmalı (şablonla birlikte hazır gelir):
> ```csharp
> @addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers
> ```

---

## ⌨️ Adım: Aktif menüyü vurgula

Kullanıcı hangi sayfada olduğunu görmeli. Küçük bir Razor kodu ekliyoruz.

`_Layout.cshtml` içinde, `<nav>` etiketinin **hemen üstüne**:

```csharp
@{
    // Şu an hangi controller'dayız?
    var aktifSayfa = ViewContext.RouteData.Values["controller"]?.ToString() ?? "";
}
```

Sonra menü linklerini şöyle güncelle:

```html
<a asp-controller="Fakulte" asp-action="Index"
   class="@(aktifSayfa == "Fakulte" ? "active" : "")">
    <i class="bi bi-building"></i> Fakülteler
</a>
```

**Açıklama:** `? :` işareti C#'ın kısa if'idir.
`koşul ? doğruysa : yanlışsa`
Yani: "aktif sayfa Fakulte ise `active` sınıfını ekle, değilse hiçbir şey ekleme."

Aynısını her menü linki için yap (`Home`, `Bolum`, `Ogrenci`, `Akademisyen`).

---

## ⌨️ Adım: Dashboard ana sayfası (şimdilik statik)

`Views/Home/Index.cshtml` dosyasını temizle:

```html
@{
    ViewData["Title"] = "Panel";
}

<div class="row g-3">

    <div class="col-md-3">
        <div class="card border-0 shadow-sm">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="text-muted small">Fakülte</div>
                        <div class="fs-3 fw-bold">3</div>
                    </div>
                    <i class="bi bi-building fs-1 text-primary opacity-25"></i>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-3">
        <div class="card border-0 shadow-sm">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="text-muted small">Bölüm</div>
                        <div class="fs-3 fw-bold">6</div>
                    </div>
                    <i class="bi bi-diagram-3 fs-1 text-success opacity-25"></i>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-3">
        <div class="card border-0 shadow-sm">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="text-muted small">Öğrenci</div>
                        <div class="fs-3 fw-bold">15</div>
                    </div>
                    <i class="bi bi-people fs-1 text-warning opacity-25"></i>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-3">
        <div class="card border-0 shadow-sm">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="text-muted small">Akademisyen</div>
                        <div class="fs-3 fw-bold">8</div>
                    </div>
                    <i class="bi bi-person-badge fs-1 text-info opacity-25"></i>
                </div>
            </div>
        </div>
    </div>

</div>

<div class="card border-0 shadow-sm mt-4">
    <div class="card-body">
        <h5 class="card-title">Hoş geldiniz</h5>
        <p class="card-text text-muted">
            Sol menüden yönetmek istediğiniz kaydı seçin.
        </p>
    </div>
</div>
```

> **⚠️ Öğrenciye açıkça söyle:** Bu sayılar şu an **elle yazılmış sahte veriler**. Modül 9'da bunları veritabanından gerçek verilerle dolduracağız. "Şimdilik görünüm çalışsın diye böyle" demeyi ihmal etme, yoksa öğrenci sayıların gerçek sandığını düşünür.

---

## ⌨️ Adım: Fakülte listesini güzelleştir

`Views/Fakulte/Index.cshtml` dosyasını kart içine al:

```html
@model List<OkulYonetim.Models.Fakulte>
@{
    ViewData["Title"] = "Fakülteler";
}

<div class="card border-0 shadow-sm">
    <div class="card-header bg-white d-flex justify-content-between align-items-center">
        <span class="fw-semibold">Kayıtlı fakülteler (@Model.Count)</span>
        <a href="#" class="btn btn-primary btn-sm">
            <i class="bi bi-plus-lg"></i> Yeni fakülte
        </a>
    </div>

    <div class="card-body p-0">
        <table class="table table-hover align-middle mb-0">
            <thead class="table-light">
                <tr>
                    <th>#</th>
                    <th>Fakülte adı</th>
                    <th>Telefon</th>
                    <th>E-posta</th>
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
                        <td class="text-end">
                            <a href="#" class="btn btn-sm btn-outline-secondary">Düzenle</a>
                            <a href="#" class="btn btn-sm btn-outline-danger">Sil</a>
                        </td>
                    </tr>
                }
            </tbody>
        </table>
    </div>
</div>

@* Liste boşsa kullanıcıya ne yapacağını söyle *@
@if (Model.Count == 0)
{
    <div class="text-center text-muted py-5">
        <i class="bi bi-inbox fs-1 d-block mb-2"></i>
        Henüz fakülte eklenmemiş. Yukarıdaki butondan ilk kaydı oluşturun.
    </div>
}
```

> **Arayüz yazısı üzerine kısa bir not (öğretmeye değer):** Boş liste ekranı "Kayıt bulunamadı." demekle yetinmemeli, kullanıcıya **ne yapacağını** söylemeli. Aynı şekilde buton yazıları eylemi anlatmalı: "Gönder" değil, "Fakülteyi kaydet". Küçük bir detay ama profesyonel işi amatörden ayıran şey bu.

---

## ▶️ Çalıştır ve gör

Uygulamayı başlat. Artık:
- ✅ Sol menü var
- ✅ Menüden sayfalar arası geçiş yapılıyor
- ✅ Bulunduğun sayfa menüde vurgulanıyor
- ✅ Fakülte listesi düzgün bir tablo içinde

**Duyarlılık testi:** Tarayıcı penceresini daralt veya **F12 → Toggle device toolbar** ile telefon görünümüne geç. Sol menü otomatik olarak üste taşınır. Bootstrap'in grid sistemi bunu bedava yapıyor.

---

## ⚠️ Sık yapılan hatalar

| Hata | Sebep | Çözüm |
|---|---|---|
| Sayfa stilsiz, düz beyaz | Bootstrap CDN yüklenmedi | İnternet bağlantısını kontrol et; F12 → Console'da kırmızı hata var mı bak |
| Menü linkleri çalışmıyor, `#` gösteriyor | Tag Helper aktif değil | `_ViewImports.cshtml` içinde `@addTagHelper` satırı var mı? |
| İkonlar görünmüyor, kare çıkıyor | Bootstrap Icons CSS eksik | `bootstrap-icons.css` linkini ekle |
| Sol menü kısa, ekranı doldurmuyor | `min-height` yok | `.sidebar { min-height: 100vh; }` |
| İçerik menünün altına giriyor | Sütun toplamı 12'yi aşmış | `col-md-3` + `col-md-9` = 12 olmalı |
| `RenderBody()` hatası | Layout'ta bu satır yok | `@RenderBody()` mutlaka olmalı |
| Sayfa başlığı hep aynı | View'da `ViewData["Title"]` yok | Her view'ın başına ekle |
| Değişiklik görünmüyor | Tarayıcı önbelleği | Ctrl+F5 |

---

## 🌐 İnternet bağımlılığı uyarısı

Bootstrap'i CDN'den (internetten) çekiyoruz. Laboratuvarda internet yoksa **hiçbir stil çalışmaz.**

**Çözüm — yerel dosya kullan:**
1. https://getbootstrap.com/docs/5.3/getting-started/download/ adresinden indir
2. `wwwroot/lib/bootstrap/` klasörüne kopyala
3. Layout'ta linki değiştir:
```html
<link rel="stylesheet" href="~/lib/bootstrap/css/bootstrap.min.css" />
<script src="~/lib/bootstrap/js/bootstrap.bundle.min.js"></script>
```

`~/` işareti "proje kökündeki wwwroot" demektir.

> **Öneri:** Ders öncesi laboratuvarın internet durumunu test et. Yerel kullanmak daha güvenli.

---

## ✏️ Öğrenci alıştırması

**A. Tekrar (herkes)**
Layout'u kendi projene uygula.

**B. Kişiselleştirme**
1. Sol menünün rengini değiştir (kendi seçtiğin bir renk).
2. Üst çubuğa kendi ad-soyadını ekle.
3. Alt bilgiye okulunun adını yaz.

**C. Yeni kart**
Dashboard'a 5. bir kart ekle: "Toplam Kayıt". Grid'i bozmadan yerleştir.
*(İpucu: 5 kart 12 sütuna tam bölünmez. `col-md-4` ile 3+2 düzeni dene.)*

**D. Bootstrap keşfi**
https://getbootstrap.com/docs/5.3/components/ adresini incele. Derste kullanmadığımız bir bileşen seç (accordion, progress bar, tooltip...), dashboard'a ekle ve derste 2 dakikada anlat.

**E. Düşünme sorusu**
> `_Layout.cshtml` dosyasını silseydik ne olurdu? Sayfalar çalışır mıydı, nasıl görünürdü?

---

## Sonraki adım

👉 [`06-fakulte-crud.md`](06-fakulte-crud.md) — Kursun kalbi: ilk tam CRUD.
