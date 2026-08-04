# Modül 11 — Cila: Mesajlar, Onaylar, Hata Yönetimi

**Süre:** 1 ders saati
**Ön koşul:** Modül 10
**Kim yazıyor:** Beraber

---

## 🎯 Bu derste ne yapacağız

Uygulama çalışıyor ama "bitmiş" hissi vermiyor. Bu derste onu profesyonelleştireceğiz:

1. Mesaj sistemini tek yerden yönetmek (partial view)
2. Silme onayını modal pencereyle almak
3. Beklenmedik hataları güzelce yakalamak
4. Tekrar eden kodu azaltmak
5. Küçük kullanıcı deneyimi dokunuşları

---

## ⌨️ Adım 1: Mesaj sistemini merkezileştir

**Sorun:** Her `Index.cshtml` dosyasında aynı `TempData["Basarili"]` bloğunu tekrar yazdık. Dört kez.

**Çözüm: Partial View** — HTML parçalarını yeniden kullanmanın yolu.

`Views/Shared/_Mesajlar.cshtml` oluştur:

```html
@if (TempData["Basarili"] != null)
{
    <div class="alert alert-success alert-dismissible fade show">
        <i class="bi bi-check-circle-fill me-1"></i> @TempData["Basarili"]
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
}

@if (TempData["Hata"] != null)
{
    <div class="alert alert-danger alert-dismissible fade show">
        <i class="bi bi-exclamation-triangle-fill me-1"></i> @TempData["Hata"]
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
}

@if (TempData["Uyari"] != null)
{
    <div class="alert alert-warning alert-dismissible fade show">
        <i class="bi bi-info-circle-fill me-1"></i> @TempData["Uyari"]
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
}
```

Şimdi `_Layout.cshtml`'de, `@RenderBody()`'nin **hemen üstüne** ekle:

```html
<partial name="_Mesajlar" />

@RenderBody()
```

**Sonuç:** Artık her view'daki mesaj bloklarını **silebilirsin**. Tek yerde duruyor ve tüm sayfalarda otomatik çalışıyor.

> **Ders çıkarımı:** *"Aynı kodu üçüncü kez yazıyorsanız, durup düşünün. Muhtemelen tek yere taşınabilir."* Yazılımda buna **DRY** (Don't Repeat Yourself) denir.

---

## ⌨️ Adım 2: Silme onayını modal ile al

Şu an silme için ayrı bir sayfaya gidiyoruz. Modal (açılır pencere) daha hızlı bir deneyim sunar.

`Views/Ogrenci/Index.cshtml`'de sil butonunu değiştir:

```html
<button type="button" class="btn btn-sm btn-outline-danger"
        data-bs-toggle="modal"
        data-bs-target="#silModal"
        data-id="@ogrenci.OgrenciId"
        data-ad="@ogrenci.TamAd">
    <i class="bi bi-trash"></i> Sil
</button>
```

Sayfanın en altına modal'ı ekle:

```html
<div class="modal fade" id="silModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">

            <div class="modal-header">
                <h5 class="modal-title">Öğrenciyi sil</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>

            <div class="modal-body">
                <p><strong id="modalAd"></strong> adlı öğrenci silinecek.</p>
                <p class="text-muted small mb-0">
                    Kayıt veritabanından tamamen silinmez, pasif duruma alınır.
                </p>
            </div>

            <div class="modal-footer">
                <button type="button" class="btn btn-outline-secondary"
                        data-bs-dismiss="modal">Vazgeç</button>

                <form id="silForm" asp-action="Delete" method="post" class="d-inline">
                    @Html.AntiForgeryToken()
                    <input type="hidden" name="id" id="modalId" />
                    <button type="submit" class="btn btn-danger">
                        <i class="bi bi-trash"></i> Sil
                    </button>
                </form>
            </div>

        </div>
    </div>
</div>

@section Scripts {
    <partial name="_ValidationScriptsPartial" />
    <script>
        // Modal açılırken, tıklanan butonun bilgilerini modal'a taşı
        document.getElementById('silModal').addEventListener('show.bs.modal', function (event) {
            var buton = event.relatedTarget;                      // tıklanan buton
            document.getElementById('modalId').value = buton.getAttribute('data-id');
            document.getElementById('modalAd').textContent = buton.getAttribute('data-ad');
        });
    </script>
}
```

### JavaScript'i açıkla

| Parça | Anlamı |
|---|---|
| `data-id="@ogrenci.OgrenciId"` | HTML'e kendi verimizi iliştiriyoruz. `data-` ile başlayan her nitelik serbesttir. |
| `addEventListener('show.bs.modal', ...)` | Bootstrap'in "modal açılıyor" olayını dinle |
| `event.relatedTarget` | Modal'ı açan butonun kendisi |
| `getAttribute('data-id')` | O butondan veriyi oku |
| `@Html.AntiForgeryToken()` | Formu Tag Helper ile yazmadığımız için güvenlik anahtarını elle ekliyoruz |

> **Bu, öğrencinin gördüğü ilk gerçek JavaScript.** Küçük tut, korkutma. *"Sunucu HTML üretir, JavaScript o HTML'i tarayıcıda canlandırır. İkisi farklı yerlerde çalışır."*

> **Tartışma sorusu:** *"Ayrı silme sayfası mı, modal mı? Hangisi daha iyi?"*
> Modal daha hızlı ve sayfa değişimi yok. Ama ayrı sayfa daha erişilebilir, adres çubuğunda görünür ve JavaScript kapalıysa da çalışır. Doğru cevap yok — bağlama göre değişir. **`Delete.cshtml` sayfasını silmeyin**, ikisi bir arada dursun.

---

## ⌨️ Adım 3: Global hata yönetimi

**Sor:** *"Veritabanı sunucusu kapalıyken uygulamayı açsak ne olur?"*

Deneyin: SQL Server servisini durdurun, sayfayı açın → çirkin sarı hata sayfası, teknik detaylar, dosya yolları.

### Özel hata sayfası

`Views/Home/Error.cshtml`:

```html
@{
    ViewData["Title"] = "Bir sorun oluştu";
    Layout = "_Layout";
}

<div class="text-center py-5">
    <i class="bi bi-exclamation-octagon text-danger" style="font-size: 4rem;"></i>

    <h3 class="mt-3">Bir sorun oluştu</h3>

    <p class="text-muted">
        İşlem tamamlanamadı. Lütfen tekrar deneyin.<br />
        Sorun devam ederse sistem yöneticisine bildirin.
    </p>

    @if (ViewBag.HataKodu != null)
    {
        <p class="text-muted small">Referans kodu: <code>@ViewBag.HataKodu</code></p>
    }

    <a asp-controller="Home" asp-action="Index" class="btn btn-primary mt-2">
        <i class="bi bi-house"></i> Ana sayfaya dön
    </a>
</div>
```

`HomeController`'a:

```csharp
[ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
public IActionResult Error()
{
    // Kullanıcıya verilecek kısa bir referans kodu.
    // Kullanıcı bunu size söyler, siz log'larda ararsınız.
    ViewBag.HataKodu = Activity.Current?.Id ?? HttpContext.TraceIdentifier;
    return View();
}
```
(`using System.Diagnostics;` eklemeyi unutma.)

`Program.cs`'te bu satırın zaten var olduğunu göster:

```csharp
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
}
```

> **Neden `if (!IsDevelopment())`?**
> - **Geliştirme ortamında** ayrıntılı hata sayfası **isteriz** — hangi satırda hata var görmemiz lazım.
> - **Canlı ortamda** kullanıcıya asla teknik detay göstermeyiz — hem anlamaz, hem saldırgana bilgi verir.
>
> Bunu tarayıcıda test etmek için `Properties/launchSettings.json`'da `ASPNETCORE_ENVIRONMENT` değerini geçici olarak `"Production"` yap.

### 404 sayfası

`Program.cs`'e ekle (`app.UseRouting()`'den sonra):

```csharp
app.UseStatusCodePagesWithReExecute("/Home/HataKodu/{0}");
```

`HomeController`'a:

```csharp
public IActionResult HataKodu(int id)
{
    if (id == 404)
    {
        ViewBag.Baslik = "Sayfa bulunamadı";
        ViewBag.Mesaj = "Aradığınız sayfa taşınmış veya silinmiş olabilir.";
    }
    else
    {
        ViewBag.Baslik = "Bir sorun oluştu";
        ViewBag.Mesaj = "İşlem tamamlanamadı.";
    }

    ViewBag.Kod = id;
    return View("HataKodu");
}
```

`Views/Home/HataKodu.cshtml`:

```html
@{
    ViewData["Title"] = ViewBag.Baslik;
}

<div class="text-center py-5">
    <div class="display-1 fw-bold text-muted">@ViewBag.Kod</div>
    <h4>@ViewBag.Baslik</h4>
    <p class="text-muted">@ViewBag.Mesaj</p>
    <a asp-controller="Home" asp-action="Index" class="btn btn-primary">
        <i class="bi bi-house"></i> Ana sayfaya dön
    </a>
</div>
```

Test: `/Fakulte/Edit/99999` → 404 sayfası çıkmalı.

---

## ⌨️ Adım 4: İlişkili kayıt kontrolü

Modül 6'da tartıştığımız sorunu şimdi çözelim: **bağlı bölümü olan fakülte silinmesin.**

`FakulteRepository`'ye:

```csharp
public int AktifBolumSayisi(long fakulteId)
{
    string sql = @"SELECT COUNT(*) FROM bolum
                   WHERE fakulte_id = @id AND is_active = '1'";

    using (SqlConnection baglanti = new SqlConnection(_baglantiMetni))
    using (SqlCommand komut = new SqlCommand(sql, baglanti))
    {
        komut.Parameters.AddWithValue("@id", fakulteId);
        baglanti.Open();
        return Convert.ToInt32(komut.ExecuteScalar());
    }
}
```

`FakulteController`'da:

```csharp
[HttpPost, ActionName("Delete")]
[ValidateAntiForgeryToken]
public IActionResult DeleteConfirmed(long id)
{
    int bolumSayisi = _repo.AktifBolumSayisi(id);

    if (bolumSayisi > 0)
    {
        TempData["Uyari"] = $"Bu fakültede {bolumSayisi} aktif bölüm var. " +
                             "Fakülteyi silmeden önce bölümleri silmelisiniz.";
        return RedirectToAction("Index");
    }

    _repo.PasifYap(id);
    TempData["Basarili"] = "Fakülte silindi.";
    return RedirectToAction("Index");
}
```

**`$"..."` nedir?** String interpolation. Metin içine değişken gömmenin kısa yolu:

```csharp
$"Bu fakültede {bolumSayisi} aktif bölüm var."
// eskisi: "Bu fakültede " + bolumSayisi + " aktif bölüm var."
```

### Sil butonunu da gizle

Listede, silinemeyecek kayıtlarda butonu pasifleştir. Önce controller'da sayıları hazırla:

```csharp
public IActionResult Index()
{
    var liste = _repo.TumunuGetir();

    var bolumSayilari = new Dictionary<long, int>();
    foreach (var f in liste)
        bolumSayilari[f.FakulteId] = _repo.AktifBolumSayisi(f.FakulteId);

    ViewBag.BolumSayilari = bolumSayilari;
    return View(liste);
}
```

View'da:

```html
@{
    var sayilar = ViewBag.BolumSayilari as Dictionary<long, int>;
    int bolumAdet = sayilar != null && sayilar.ContainsKey(fakulte.FakulteId)
                    ? sayilar[fakulte.FakulteId] : 0;
}

@if (bolumAdet > 0)
{
    <button class="btn btn-sm btn-outline-secondary" disabled
            title="Bu fakültede @bolumAdet bölüm var">
        <i class="bi bi-lock"></i> Sil
    </button>
}
else
{
    <a asp-action="Delete" asp-route-id="@fakulte.FakulteId"
       class="btn btn-sm btn-outline-danger">
        <i class="bi bi-trash"></i> Sil
    </a>
}
```

> **Kullanıcı deneyimi ilkesi:** Yapılamayacak bir işlemi kullanıcıya **denemeden önce** göster. Butona basıp hata almak, butonun kilitli olduğunu görmekten daha sinir bozucudur.

> ⚠️ Ama dikkat: bu kod her fakülte için ayrı sorgu çalıştırıyor — **N+1 problemi**. 100 fakülte = 101 sorgu. Öğrenciye bunu fark ettir ve alıştırmada tek sorguyla çözdür.

---

## ⌨️ Adım 5: Küçük dokunuşlar

### Silme onayı için basit JavaScript (modal alternatifi)

```html
<a asp-action="Delete" asp-route-id="@item.Id"
   onclick="return confirm('Bu kaydı silmek istediğinize emin misiniz?');"
   class="btn btn-sm btn-outline-danger">Sil</a>
```

Tek satır, ama modal kadar şık değil. İkisini karşılaştırın.

### Form gönderilirken butonu kilitle

Kullanıcı sabırsızlanıp iki kez tıklarsa çift kayıt oluşur.

```html
<form asp-action="Create" method="post" onsubmit="butonuKilitle(this)">
    ...
</form>

@section Scripts {
    <script>
        function butonuKilitle(form) {
            var btn = form.querySelector('button[type=submit]');
            btn.disabled = true;
            btn.innerHTML = 'Kaydediliyor...';
        }
    </script>
}
```

### Tabloda satır sayısı

```html
<td>@(((ViewBag.Sayfa - 1) * 10) + Model.IndexOf(item) + 1)</td>
```
Veritabanı id'si yerine sıra numarası göstermek daha okunaklı.

### Tarih formatı — tek yerden

`Program.cs`'in en üstüne:

```csharp
var kultur = new System.Globalization.CultureInfo("tr-TR");
System.Globalization.CultureInfo.DefaultThreadCurrentCulture = kultur;
System.Globalization.CultureInfo.DefaultThreadCurrentUICulture = kultur;
```

Artık tarihler ve sayılar Türkçe formatta gelir.

> ⚠️ **Dikkat:** Bu ayar ondalık ayracını da `,` yapar. Veritabanına sayı gönderirken sorun çıkarabilir. Bu ders kapsamında ondalıklı sayı kullanmadığımız için güvenli, ama öğrenciye "kültür ayarları beklenmedik yerlerde karşınıza çıkar" diye not düş.

---

## ▶️ Çalıştır ve gör

| Test | Beklenen |
|---|---|
| Kayıt ekle | Yeşil mesaj (partial'dan geliyor) |
| Bölümü olan fakülteyi sil | Sarı uyarı, silinmiyor |
| Listede o fakültenin sil butonu | Kilitli, açıklama ipucu var |
| Öğrenci sil | Modal açılıyor, isim doğru |
| `/Fakulte/Edit/99999` | 404 sayfası |
| SQL Server'ı durdur, sayfa aç | Düzgün hata sayfası (Production modunda) |
| Kaydet butonuna hızlı iki tık | Buton kilitleniyor, tek kayıt |

---

## ⚠️ Sık yapılan hatalar

| Hata | Sebep | Çözüm |
|---|---|---|
| Modal açılmıyor | Bootstrap JS yüklenmemiş | `bootstrap.bundle.min.js` layout'ta olmalı |
| Modal açılıyor ama id boş | JavaScript `data-id` okumuyor | Buton üzerindeki `data-id` niteliğini kontrol et |
| Modal'dan silme çalışmıyor: `400 Bad Request` | AntiForgery token yok | `@Html.AntiForgeryToken()` ekle |
| Mesajlar iki kez görünüyor | Hem layout'ta hem view'da partial var | View'dakini sil |
| Özel hata sayfası çıkmıyor | Development ortamındasın | `launchSettings.json`'da `Production` yap |
| `Activity` tanınmıyor | using eksik | `using System.Diagnostics;` |
| Fakülte listesi çok yavaş | N+1 problemi | Tek sorguda COUNT çek (alıştırma D) |
| Tarihler İngilizce | Kültür ayarı yok | `CultureInfo("tr-TR")` ekle |

---

## ✏️ Öğrenci alıştırması

**A. Modal'ı yaygınlaştır**
Silme modal'ını `Fakulte`, `Bolum` ve `Akademisyen` listelerine de ekle.

**B. Bölüm silme kontrolü**
Aktif öğrencisi veya akademisyeni olan bölüm silinemesin. Uyarı mesajında ikisinin de sayısı yazsın:
> "Bu bölümde 12 öğrenci ve 3 akademisyen kayıtlı."

**C. Geri alma**
Silme mesajına "Geri al" linki ekle:
> "Öğrenci silindi. [Geri al]"

`AktifYap(long id)` metodu yaz ve linke bağla. `TempData` ile silinen kaydın id'sini taşı.

**D. N+1 problemini çöz (zorlayıcı)**
Fakülte listesindeki bölüm sayılarını **tek sorguda** getir:

```sql
SELECT f.*,
       (SELECT COUNT(*) FROM bolum b
        WHERE b.fakulte_id = f.fakulte_id AND b.is_active = '1') AS bolum_sayisi
FROM fakulte f
WHERE f.is_active = '1'
```

`Fakulte` model'ine `BolumSayisi` alanı ekle. 100 fakültede kaç sorgudan kaça düştü?

**E. Onay yazısı (zorlayıcı)**
Kritik silmelerde kullanıcıya kayıt adını **yazdır**. GitHub'ın depo silme onayı gibi:
> "Silmek için fakülte adını yazın: `Mühendislik Fakültesi`"

Yazılan metin eşleşmedikçe sil butonu aktif olmasın.

**F. Düşünme soruları**
1. Hata sayfasında kullanıcıya "referans kodu" göstermenin faydası nedir?
2. `TempData` yerine `Session` kullansaydık ne değişirdi?
3. Silme işlemini neden GET ile yapmıyoruz? (İpucu: Google'ın tarayıcı botu sitenizdeki tüm linkleri ziyaret ederse ne olur?)

---

## Sonraki adım

👉 [`13-opsiyonel-login-ve-yayinlama.md`](13-opsiyonel-login-ve-yayinlama.md) — Opsiyonel bitirme modülü.
