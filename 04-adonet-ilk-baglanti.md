# Modül 3 — ADO.NET ile İlk Veritabanı Bağlantısı

**Süre:** 2 ders saati
**Ön koşul:** Modül 2 (proje hazır)

---

## 🎯 Bu derste ne yapacağız

Uygulamayı SQL Server'a bağlayacağız ve **veritabanındaki gerçek fakülteleri ekranda listeleyeceğiz.**

**Ders sonunda öğrenci:** Bir SQL sorgusunun C# kodundan çalıştırılıp ekrana nasıl geldiğini adım adım anlatabilecek.

> **Bu, kursun en kritik modülü.** Buradaki kalıp, kalan tüm modüllerde tekrarlanacak. Acele etme, 2 ders saatini tam kullan.

---

## 📖 Kavram 1: ADO.NET nedir?

**ADO.NET**, .NET'in veritabanıyla konuşma aracıdır. Üç ana parça:

```
   C# KODU                                    SQL SERVER
      │                                            │
      │  1️⃣ SqlConnection                          │
      │  ─────── "Bağlanmak istiyorum" ──────────▶ │
      │  ◀────── "Tamam, bağlandık" ────────────── │
      │                                            │
      │  2️⃣ SqlCommand                             │
      │  ─── "SELECT * FROM fakulte" ────────────▶ │
      │                                            │
      │  3️⃣ SqlDataReader                          │
      │  ◀───── satır, satır, satır... ─────────── │
      │                                            │
      │  4️⃣ Bağlantıyı kapat                       │
      │  ─────── "Görüşürüz" ───────────────────▶ │
```

| Sınıf | Görevi | Benzetme |
|---|---|---|
| `SqlConnection` | Veritabanına bağlantı kurar | Telefon hattı |
| `SqlCommand` | Çalıştırılacak SQL komutu | Söylediğin cümle |
| `SqlDataReader` | Dönen satırları tek tek okur | Karşıdakinin cevabını dinlemek |

**Neden ADO.NET, neden Entity Framework değil?**

> *"Entity Framework, sizin yerinize SQL yazan bir araç. Ama SQL yazmayı bilmeden onu kullanırsanız, bir şey ters gittiğinde ne olduğunu anlayamazsınız. Önce elle yazacağız, sonra kolaylaştıracak araçları öğreneceksiniz."*

---

## ⌨️ Adım 1: Gerekli paketi kur

ADO.NET'in SQL Server sürücüsü ayrı bir pakettir.

**Visual Studio ile:** Projeye sağ tık → **NuGet Paketlerini Yönet** → **Gözat** sekmesi → `Microsoft.Data.SqlClient` ara → **Yükle**

**Terminal ile:**
```bash
dotnet add package Microsoft.Data.SqlClient
```

> ⚠️ **Dikkat:** `System.Data.SqlClient` diye eski bir paket de var. **Onu kullanma.** Yeni ve desteklenen olan `Microsoft.Data.SqlClient`. İsim benzerliği en sık yaşanan karışıklıklardan biri.

---

## ⌨️ Adım 2: Bağlantı bilgisini ayarla

`appsettings.json` dosyasını aç ve `ConnectionStrings` bölümünü ekle:

```json
{
  "ConnectionStrings": {
    "OkulDb": "Server=localhost\\SQLEXPRESS;Database=OkulDB;Trusted_Connection=True;TrustServerCertificate=True;"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

**Bağlantı dizesini parça parça açıkla:**

| Parça | Anlamı |
|---|---|
| `Server=localhost\\SQLEXPRESS` | Hangi SQL Server'a bağlanacağız. `\\` çift çünkü JSON'da tek `\` özel karakter. |
| `Database=OkulDB` | Hangi veritabanı |
| `Trusted_Connection=True` | Windows kullanıcı hesabımla bağlan (şifre gerekmez) |
| `TrustServerCertificate=True` | Yerel geliştirmede sertifika doğrulamasını atla |

> **Güvenlik notu — mutlaka söyle:** Gerçek projelerde bağlantı dizesi kullanıcı adı ve şifre içerir. Bu dosya **asla** GitHub'a yüklenmez. Gerçek projelerde ortam değişkeni veya "user secrets" kullanılır. Şimdilik yerel çalıştığımız için sorun yok.

**SQL Server kullanıcı adı/şifre ile bağlanılıyorsa:**
```
Server=localhost;Database=OkulDB;User Id=sa;Password=SifreniziBurayaYazin;TrustServerCertificate=True;
```

---

## ⌨️ Adım 3: Model sınıfını yaz

Model = veritabanındaki bir satırın C# karşılığı.

`Models` klasörüne yeni sınıf: **`Fakulte.cs`**

```csharp
namespace OkulYonetim.Models;

public class Fakulte
{
    // Veritabanındaki her sütun için bir özellik (property) yazıyoruz.

    public long FakulteId { get; set; }              // fakulte_id  (BIGINT → long)
    public string FakulteAd { get; set; } = "";      // fakulte_ad
    public string FakulteAdres { get; set; } = "";   // fakulte_adres
    public string FakulteTelefon { get; set; } = ""; // fakulte_telefon
    public string FakulteEposta { get; set; } = "";  // fakulte_eposta

    public DateTime CreatedDate { get; set; }        // created_date
    public DateTime? UpdatedDate { get; set; }       // updated_date — NULL olabilir!
    public string IsActive { get; set; } = "1";      // is_active
}
```

**Öğrencinin takılacağı üç nokta — mutlaka açıkla:**

**1. `{ get; set; }` nedir?**
Bu bir **özellik (property)**. `get` = okunabilir, `set` = yazılabilir. Kısaca "bu sınıfın bir bilgisi" demek.

**2. `DateTime?` sonundaki soru işareti ne?**
`?` = "bu değer **boş (null)** olabilir". Veritabanında `updated_date NULL` olarak tanımlıydı, C# tarafında da bunu belirtiyoruz. `CreatedDate`'te `?` yok çünkü o `NOT NULL`.

**3. `= ""` neden var?**
C#, metin özellikleri için "boş kalırsa null olur, null hataya yol açar" diye uyarır. `= ""` yazarak "başlangıçta boş metin olsun" diyoruz. Sarı uyarı çizgilerinden kurtuluyoruz.

### Tip eşleştirme tablosu (öğrenciye dağıt, çok işlerine yarayacak)

| SQL Server tipi | C# tipi | Not |
|---|---|---|
| `BIGINT` | `long` | |
| `INT` | `int` | |
| `NVARCHAR(255)`, `TEXT` | `string` | |
| `DATETIME` | `DateTime` | |
| `DATE` | `DateTime` | Saat kısmı 00:00 olur |
| `BIT` | `bool` | |
| **NULL olabilen her tip** | Sonuna `?` ekle | `DateTime?`, `int?` |

> **Not:** `string` zaten null olabilir, ayrıca `?` gerekmez.

---

## ⌨️ Adım 4: Repository sınıfını yaz

**Kavram — Repository nedir?**

> *"Veritabanı işlerini yapan sınıfa Repository (depo) diyoruz. Neden ayrı bir sınıf? Çünkü Controller'ın işi trafiği yönetmek, SQL yazmak değil. SQL'i tek bir yerde toplarsak, ileride değiştirmemiz gerektiğinde tek yere bakarız."*

Projede **`Data`** adında yeni bir klasör oluştur. İçine **`FakulteRepository.cs`**:

```csharp
using Microsoft.Data.SqlClient;   // ADO.NET sınıfları buradan geliyor
using OkulYonetim.Models;

namespace OkulYonetim.Data;

public class FakulteRepository
{
    // Bağlantı dizesini burada saklayacağız
    private readonly string _baglantiMetni;

    // Yapıcı metot (constructor):
    // ASP.NET Core, appsettings.json'ı okuyan "configuration" nesnesini
    // bize otomatik verir. Buna "Dependency Injection" denir (Adım 5'te açıklayacağız).
    public FakulteRepository(IConfiguration configuration)
    {
        _baglantiMetni = configuration.GetConnectionString("OkulDb")!;
    }

    /// <summary>
    /// Aktif tüm fakülteleri veritabanından okur ve liste olarak döner.
    /// </summary>
    public List<Fakulte> TumunuGetir()
    {
        // 1️⃣ Boş bir liste hazırla — verileri buraya dolduracağız
        List<Fakulte> liste = new List<Fakulte>();

        // 2️⃣ Çalıştıracağımız SQL sorgusu
        //    @"..." → çok satırlı metin yazmayı sağlar (verbatim string)
        string sql = @"SELECT fakulte_id, fakulte_ad, fakulte_adres,
                              fakulte_telefon, fakulte_eposta,
                              created_date, updated_date, is_active
                       FROM fakulte
                       WHERE is_active = '1'
                       ORDER BY fakulte_ad";

        // 3️⃣ Bağlantıyı aç
        //    using → iş bitince bağlantıyı OTOMATİK kapatır. Çok önemli!
        using (SqlConnection baglanti = new SqlConnection(_baglantiMetni))
        {
            // 4️⃣ Komutu hazırla: hangi SQL, hangi bağlantı üzerinden
            using (SqlCommand komut = new SqlCommand(sql, baglanti))
            {
                baglanti.Open();   // 5️⃣ Bağlantıyı fiilen aç

                // 6️⃣ Sorguyu çalıştır ve okuyucuyu al
                using (SqlDataReader okuyucu = komut.ExecuteReader())
                {
                    // 7️⃣ Satır satır oku
                    //     Read() → sıradaki satıra geç. Satır kalmadıysa false döner.
                    while (okuyucu.Read())
                    {
                        Fakulte f = new Fakulte();

                        // 8️⃣ Sütunları C# nesnesine kopyala
                        f.FakulteId      = okuyucu.GetInt64(okuyucu.GetOrdinal("fakulte_id"));
                        f.FakulteAd      = okuyucu.GetString(okuyucu.GetOrdinal("fakulte_ad"));
                        f.FakulteAdres   = okuyucu.GetString(okuyucu.GetOrdinal("fakulte_adres"));
                        f.FakulteTelefon = okuyucu.GetString(okuyucu.GetOrdinal("fakulte_telefon"));
                        f.FakulteEposta  = okuyucu.GetString(okuyucu.GetOrdinal("fakulte_eposta"));
                        f.CreatedDate    = okuyucu.GetDateTime(okuyucu.GetOrdinal("created_date"));
                        f.IsActive       = okuyucu.GetString(okuyucu.GetOrdinal("is_active"));

                        // updated_date NULL olabilir — önce kontrol et!
                        int sutunNo = okuyucu.GetOrdinal("updated_date");
                        if (okuyucu.IsDBNull(sutunNo))
                            f.UpdatedDate = null;
                        else
                            f.UpdatedDate = okuyucu.GetDateTime(sutunNo);

                        // 9️⃣ Nesneyi listeye ekle
                        liste.Add(f);
                    }
                }
            }
        }   // 🔟 using blokları biter → bağlantı otomatik kapanır

        return liste;
    }
}
```

### Kodun kritik noktalarını anlat

**`using` bloğu neden var?**
> *"Bağlantı açmak, telefonu açmak gibidir. Kapatmayı unutursanız hat meşgul kalır. Yüzlerce kullanıcı olduğunda veritabanı 'boş hat kalmadı' der ve uygulama çöker. `using` bloğu, kod nasıl biterse bitsin — hata bile alsa — bağlantıyı kapatır."*

Tahtaya karşılaştırma yaz:
```csharp
// ❌ Riskli
SqlConnection b = new SqlConnection(...);
b.Open();
// ... burada hata olursa b.Close() hiç çalışmaz!
b.Close();

// ✅ Güvenli
using (SqlConnection b = new SqlConnection(...))
{
    b.Open();
    // ... hata olsa bile kapanır
}
```

**`GetOrdinal` ne yapıyor?**
Sütun adını sütun numarasına çevirir. `okuyucu.GetString(1)` de yazabilirdik ama sütun sırası değişirse kod bozulur. İsimle almak daha güvenlidir.

**`IsDBNull` neden gerekli?**
Veritabanındaki `NULL` değeri doğrudan `GetDateTime` ile okumaya çalışırsan **uygulama çöker**. Önce "boş mu?" diye sormalıyız.

> **Eğitmen numarası:** Bu satırı bilerek sil, `updated_date`'i NULL olan bir kayıt oluştur ve çöktüğünü göster. Sonra geri ekle. Öğrenci bu hatayı bir daha unutmaz.

### Kısa yazım (isteğe bağlı — ileri seviye öğrenciler için)

C# 8'den sonra `using` bloğunu süslü parantezsiz yazabiliyoruz:

```csharp
using SqlConnection baglanti = new SqlConnection(_baglantiMetni);
using SqlCommand komut = new SqlCommand(sql, baglanti);
baglanti.Open();
using SqlDataReader okuyucu = komut.ExecuteReader();
// ...metot bitince hepsi otomatik kapanır
```

> **Öneri:** İlk derste **uzun hâlini** kullan. Süslü parantezler iç içe yapıyı görsel olarak gösterir. Öğrenci alıştıktan sonra (Modül 6 civarı) kısa yazıma geç ve "aynı şey" olduğunu söyle.

---

## ⌨️ Adım 5: Repository'yi tanıt (Dependency Injection)

`Program.cs` dosyasını aç, `builder.Build()` satırının **üstüne** ekle:

```csharp
using OkulYonetim.Data;   // ← dosyanın en üstüne

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllersWithViews();

// 👇 YENİ SATIR: Repository'yi sisteme tanıt
builder.Services.AddScoped<FakulteRepository>();

var app = builder.Build();
```

### 📖 Kavram: Dependency Injection (Bağımlılık Enjeksiyonu)

Bu, öğrencinin ilk kez duyacağı ve kafasını karıştıracak bir kavram. Basit anlat:

> *"Bir controller'ın FakulteRepository'ye ihtiyacı var. İki yol var:*
> *1. Controller kendisi `new FakulteRepository(...)` yazar. Ama o zaman bağlantı bilgisini de kendisi bulmalı. Karışır.*
> *2. Controller sadece 'bana bir FakulteRepository lazım' der, sistem hazır olanı elinize verir.*
>
> *İkincisi Dependency Injection. `AddScoped` satırı sisteme diyor ki: 'Biri FakulteRepository isterse, sen yap ve ver.'"*

Restoran benzetmesine devam edilebilir: *"Garson mutfağa gidip kendisi yemek pişirmez, 'bana bir tabak' der."*

| Metot | Ne zaman yeni nesne üretilir |
|---|---|
| `AddScoped` | **Her HTTP isteği için bir kez** ← bizim kullanacağımız |
| `AddSingleton` | Uygulama boyunca tek bir kez |
| `AddTransient` | Her istendiğinde yeniden |

> Bu tabloyu göster ama üzerinde durma. "Şimdilik `AddScoped` kullanıyoruz, veritabanı işlerinde doğru tercih bu" demek yeterli.

---

## ⌨️ Adım 6: Controller'ı yaz

`Controllers` klasörüne **`FakulteController.cs`**:

```csharp
using Microsoft.AspNetCore.Mvc;
using OkulYonetim.Data;
using OkulYonetim.Models;

namespace OkulYonetim.Controllers;

public class FakulteController : Controller
{
    private readonly FakulteRepository _repo;

    // Yapıcı metot: sistem bize hazır bir FakulteRepository veriyor
    public FakulteController(FakulteRepository repo)
    {
        _repo = repo;
    }

    // GET: /Fakulte
    public IActionResult Index()
    {
        // 1. Repository'den veriyi al
        List<Fakulte> fakulteler = _repo.TumunuGetir();

        // 2. View'a gönder
        return View(fakulteler);
    }
}
```

**Dikkat çek:** Controller'da **tek bir satır bile SQL yok.** İşte katman ayrımı bu. Controller sadece "veriyi al, view'a ver" diyor.

---

## ⌨️ Adım 7: View'ı yaz

`Views` altına `Fakulte` klasörü oluştur, içine **`Index.cshtml`**:

```html
@model List<OkulYonetim.Models.Fakulte>
@*  ↑ Bu satır çok önemli:
    "Bu sayfaya Fakulte listesi gelecek" diyoruz.
    Bu sayede @Model yazdığımızda Visual Studio bize yardım eder.  *@

@{
    ViewData["Title"] = "Fakülteler";
}

<h1>Fakülteler</h1>

<p>Toplam <strong>@Model.Count</strong> fakülte kayıtlı.</p>

<table class="table table-striped table-bordered">
    <thead class="table-dark">
        <tr>
            <th>#</th>
            <th>Fakülte Adı</th>
            <th>Telefon</th>
            <th>E-posta</th>
            <th>Kayıt Tarihi</th>
        </tr>
    </thead>
    <tbody>
        @foreach (var fakulte in Model)
        {
            <tr>
                <td>@fakulte.FakulteId</td>
                <td>@fakulte.FakulteAd</td>
                <td>@fakulte.FakulteTelefon</td>
                <td>@fakulte.FakulteEposta</td>
                <td>@fakulte.CreatedDate.ToString("dd.MM.yyyy")</td>
            </tr>
        }
    </tbody>
</table>
```

**Açıklamalar:**

| Satır | Anlamı |
|---|---|
| `@model List<...>` | Bu view'a hangi tip veri geleceğini bildirir. **Küçük harfle** `@model`. |
| `@Model` | Controller'dan gelen verinin kendisi. **Büyük harfle** `@Model`. |
| `@foreach` | Listedeki her eleman için satır üret |
| `.ToString("dd.MM.yyyy")` | Tarihi Türkçe formatta göster (15.09.2026) |
| `class="table table-striped"` | Bootstrap'in hazır tablo stilleri |

> **Sık karışan:** `@model` (tanımlama, küçük m) ve `@Model` (kullanım, büyük M). Tahtaya iki kez yaz, altını çiz.

---

## ▶️ Çalıştır ve gör

▶️ butonuna bas, `/Fakulte` adresine git.

Veritabanındaki fakülteler bir tabloda listeleniyorsa **başardık!** 🎉

Şimdi öğrenciye 8 adımlık akışı tekrar hatırlat (Modül 0'daki şema) ve **hangi kodun hangi adım olduğunu** parmakla göster:

```
1. Tarayıcı /Fakulte ister
2. Program.cs → routing → FakulteController.Index()
3. Controller → _repo.TumunuGetir()
4. Repository → SqlCommand → "SELECT * FROM fakulte"
5. SQL Server veriyi döner → SqlDataReader
6. while(Read()) → List<Fakulte> doldurulur
7. return View(fakulteler)
8. Index.cshtml → @foreach → HTML tablo
```

### Canlı doğrulama deneyi

SSMS'i aç, yeni bir fakülte ekle:
```sql
INSERT INTO fakulte (fakulte_ad, fakulte_adres, fakulte_telefon, fakulte_eposta, created_date, is_active)
VALUES (N'Güzel Sanatlar Fakültesi', N'Kampüs D Blok', '02121234599', 'gsf@okul.edu.tr', GETDATE(), '1');
```
Sonra tarayıcıda sayfayı yenile → yeni kayıt görünüyor.

*"İşte bu, gerçek bir web uygulaması. Veritabanı değişti, ekran değişti."*

---

## ⚠️ Sık yapılan hatalar

| Hata mesajı | Sebep | Çözüm |
|---|---|---|
| `A network-related or instance-specific error occurred` | SQL Server çalışmıyor veya sunucu adı yanlış | Hizmetler'den SQL Server'ı başlat; `Server=` değerini kontrol et |
| `Cannot open database "OkulDB"` | Veritabanı adı yanlış yazılmış | Büyük/küçük harf ve yazımı kontrol et |
| `The certificate chain was not issued by a trusted authority` | Sertifika ayarı eksik | Bağlantı dizesine `TrustServerCertificate=True;` ekle |
| `Unable to resolve service for type 'FakulteRepository'` | `Program.cs`'e `AddScoped` eklenmemiş | `builder.Services.AddScoped<FakulteRepository>();` ekle |
| `Value cannot be null. (Parameter 'connectionString')` | `appsettings.json`'da isim uyuşmuyor | `GetConnectionString("OkulDb")` ile JSON'daki anahtar birebir aynı olmalı |
| `Data is Null. This method or property cannot be called on Null values` | NULL sütun kontrolsüz okunuyor | `IsDBNull()` kontrolü ekle |
| `Invalid column name 'fakulteAd'` | SQL'de sütun adı yanlış | Veritabanındaki gerçek ad `fakulte_ad` (alt çizgili) |
| `Specified cast is not valid` | Yanlış Get metodu (`GetInt32` yerine `GetInt64` olmalı) | Tip eşleştirme tablosuna bak |
| Sayfa boş, tablo yok ama hata da yok | Veritabanında `is_active='1'` olan kayıt yok | SSMS'ten kontrol et |
| `The type or namespace 'SqlConnection' could not be found` | Paket kurulmamış veya `using` eksik | NuGet'ten `Microsoft.Data.SqlClient` kur, `using` ekle |

---

## ✏️ Öğrenci alıştırması

**A. Tekrar (herkes)**
Bu modülün tamamını kendi projende baştan yaz. Kopyalama, bakarak yaz.

**B. Kendi repository'n**
`BolumRepository` sınıfını oluştur ve `TumunuGetir()` metodunu yaz.
Sonra `BolumController` ve `Views/Bolum/Index.cshtml` ekleyerek bölümleri listele.

⚠️ Not: `bolum` tablosunda sütun adı `bolum_adi` (fakültede `fakulte_ad`, bölümde `bolum_adi` — sonlar farklı!). Dikkatli oku.

**C. Sorgu değiştirme**
`TumunuGetir()` içindeki SQL'i değiştirerek:
1. Fakülteleri **kayıt tarihine göre yeniden eskiye** sırala.
2. Sadece adı "M" harfiyle başlayan fakülteleri getir. *(İpucu: `WHERE fakulte_ad LIKE 'M%'`)*

**D. Gözlem ödevi**
`using` bloğunu kaldır, bağlantıyı `Close()` etmeden bırak. Sayfayı 50 kez yenile. Ne oluyor? Gözlemini yaz.

**E. Düşünme sorusu**
> `IsDBNull` kontrolünü neden `created_date` için değil de sadece `updated_date` için yaptık?

---

## Sonraki adım

👉 [`05-bootstrap-dashboard-layout.md`](05-bootstrap-dashboard-layout.md) — Uygulamaya profesyonel bir görünüm kazandıracağız.
