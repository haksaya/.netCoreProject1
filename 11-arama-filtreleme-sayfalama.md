# Modül 10 — Arama, Filtreleme, Sayfalama

**Süre:** 1 ders saati
**Ön koşul:** Modül 9
**Kim yazıyor:** Beraber

---

## 🎯 Bu derste ne yapacağız

Öğrenci listesine arama kutusu, filtreler ve sayfalama ekleyeceğiz.

**Neden gerekli?** 10.000 öğrencilik bir listede kullanıcı aradığını nasıl bulacak? Ve tarayıcı 10.000 satırı nasıl kaldıracak?

---

## 📖 Kavram 1: Sorgu dizesi (query string)

Adres çubuğunda `?` sonrası gelen kısım:

```
/Ogrenci?arama=ayse&bolumId=3&sayfa=2
         └──────┬─────────────────────┘
              sorgu dizesi
```

Bu değerler doğrudan controller metodunun parametrelerine gelir:

```csharp
public IActionResult Index(string? arama, long? bolumId, int sayfa = 1)
```

| Adres | `arama` | `bolumId` | `sayfa` |
|---|---|---|---|
| `/Ogrenci` | null | null | 1 |
| `/Ogrenci?arama=ayse` | "ayse" | null | 1 |
| `/Ogrenci?arama=ayse&sayfa=3` | "ayse" | null | 3 |

> **`?` işareti (`string?`, `long?`)** = "bu değer gelmeyebilir". `int sayfa = 1` = "gelmezse 1 kabul et".

---

## 📖 Kavram 2: Dinamik SQL kurmak

Filtreler isteğe bağlı olduğu için SQL'i **parça parça** kurmamız gerekiyor.

```csharp
string sql = "SELECT ... FROM ogrenci o INNER JOIN bolum b ON ... WHERE o.is_active = '1'";

if (arama dolu)     sql += " AND (o.ogrenci_ad LIKE @arama OR ...)";
if (bolum seçili)   sql += " AND o.bolum_id = @bolumId";
if (sinif seçili)   sql += " AND o.ogrenci_sinif = @sinif";
```

> ⚠️ **Kritik ayrım:** SQL **metnini** parça parça kuruyoruz — bu güvenli.
> **Değerleri** hâlâ parametre olarak veriyoruz — asla metne birleştirmiyoruz.
>
> ```csharp
> sql += " AND o.bolum_id = @bolumId";                          // ✅ metin, sabit
> komut.Parameters.AddWithValue("@bolumId", bolumId.Value);     // ✅ değer, parametre
>
> sql += " AND o.bolum_id = " + bolumId;                        // ❌ ASLA
> ```

---

## ⌨️ Adım 1: Repository — arama metodu

`OgrenciRepository`'ye ekle:

```csharp
/// <summary>
/// Öğrencileri filtreleyerek ve sayfalayarak getirir.
/// </summary>
/// <param name="arama">Ad, soyad, e-posta veya TC içinde aranacak metin</param>
/// <param name="bolumId">Belirli bir bölüm filtresi (null = hepsi)</param>
/// <param name="sinif">Belirli bir sınıf filtresi (null = hepsi)</param>
/// <param name="sayfa">Kaçıncı sayfa (1'den başlar)</param>
/// <param name="sayfaBoyutu">Sayfa başına kayıt</param>
/// <param name="toplamKayit">Filtreye uyan toplam kayıt sayısı (dışarı verilir)</param>
public List<Ogrenci> Ara(string? arama, long? bolumId, int? sinif,
                         int sayfa, int sayfaBoyutu, out int toplamKayit)
{
    var liste = new List<Ogrenci>();

    // ── 1. WHERE koşullarını topla ────────────────────────────────
    string kosullar = " WHERE o.is_active = '1' ";

    if (!string.IsNullOrWhiteSpace(arama))
    {
        kosullar += @" AND ( o.ogrenci_ad     LIKE @arama
                          OR o.ogrenci_soyad  LIKE @arama
                          OR o.ogrenci_eposta LIKE @arama
                          OR o.ogrenci_tc     LIKE @arama ) ";
    }

    if (bolumId.HasValue && bolumId.Value > 0)
        kosullar += " AND o.bolum_id = @bolumId ";

    if (sinif.HasValue && sinif.Value > 0)
        kosullar += " AND o.ogrenci_sinif = @sinif ";

    // ── 2. Önce TOPLAM kayıt sayısını öğren (sayfa sayısı için) ───
    string sayimSql = @"SELECT COUNT(*)
                        FROM ogrenci o
                        INNER JOIN bolum b ON o.bolum_id = b.bolum_id"
                      + kosullar;

    // ── 3. Sonra o sayfadaki kayıtları getir ──────────────────────
    string veriSql = @"SELECT o.ogrenci_id, o.bolum_id, o.ogrenci_ad, o.ogrenci_soyad,
                              o.ogrenci_sinif, o.ogrenci_dogum_tarihi, o.ogrenci_cinsiyet,
                              o.ogrenci_adres, o.ogrenci_telefon, o.ogrenci_eposta,
                              o.ogrenci_tc, o.created_date, o.updated_date, o.is_active,
                              b.bolum_adi
                       FROM ogrenci o
                       INNER JOIN bolum b ON o.bolum_id = b.bolum_id"
                     + kosullar +
                     @" ORDER BY o.ogrenci_ad, o.ogrenci_soyad
                        OFFSET @atla ROWS FETCH NEXT @al ROWS ONLY";

    using (SqlConnection baglanti = new SqlConnection(_baglantiMetni))
    {
        baglanti.Open();

        // Parametreleri iki komuta da eklemek gerekiyor —
        // tekrar yazmamak için küçük bir yardımcı fonksiyon
        void ParametreleriEkle(SqlCommand k)
        {
            if (!string.IsNullOrWhiteSpace(arama))
                k.Parameters.AddWithValue("@arama", "%" + arama.Trim() + "%");

            if (bolumId.HasValue && bolumId.Value > 0)
                k.Parameters.AddWithValue("@bolumId", bolumId.Value);

            if (sinif.HasValue && sinif.Value > 0)
                k.Parameters.AddWithValue("@sinif", sinif.Value);
        }

        // Sayım
        using (SqlCommand sayimKomut = new SqlCommand(sayimSql, baglanti))
        {
            ParametreleriEkle(sayimKomut);
            toplamKayit = Convert.ToInt32(sayimKomut.ExecuteScalar());
        }

        // Veri
        using (SqlCommand veriKomut = new SqlCommand(veriSql, baglanti))
        {
            ParametreleriEkle(veriKomut);
            veriKomut.Parameters.AddWithValue("@atla", (sayfa - 1) * sayfaBoyutu);
            veriKomut.Parameters.AddWithValue("@al", sayfaBoyutu);

            using (SqlDataReader okuyucu = veriKomut.ExecuteReader())
            {
                while (okuyucu.Read())
                {
                    var o = SatiriNesneyeCevir(okuyucu);
                    o.BolumAdi = okuyucu.GetString(okuyucu.GetOrdinal("bolum_adi"));
                    liste.Add(o);
                }
            }
        }
    }

    return liste;
}
```

### Yeni kavramlar

**1. `LIKE` ve `%`**
```sql
WHERE ogrenci_ad LIKE '%ays%'
```

| Desen | Eşleşir |
|---|---|
| `'ays%'` | ays ile **başlayan** |
| `'%ays'` | ays ile **biten** |
| `'%ays%'` | ays **içeren** |
| `'a_s'` | a, herhangi bir karakter, s (tam 3 karakter) |

`%` işaretini **parametre değerine** koyuyoruz, SQL metnine değil:
```csharp
k.Parameters.AddWithValue("@arama", "%" + arama.Trim() + "%");
```

**2. `OFFSET ... FETCH NEXT` — sayfalama**
```sql
ORDER BY o.ogrenci_ad
OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY
```
= "İlk 20 satırı atla, sonraki 10 tanesini getir" = 3. sayfa (10'arlı).

Formül: `atlanacak = (sayfa - 1) × sayfaBoyutu`

| Sayfa | OFFSET | FETCH |
|---|---|---|
| 1 | 0 | 10 |
| 2 | 10 | 10 |
| 3 | 20 | 10 |

⚠️ `OFFSET` kullanmak için `ORDER BY` **zorunludur**. SQL Server aksi hâlde hata verir. Mantıklı: sıralama olmadan "ilk 20" ne demek?

**3. `out` parametresi**
```csharp
public List<Ogrenci> Ara(..., out int toplamKayit)
```
Bir metot normalde tek değer döner. `out` ile **ikinci bir değer** daha dışarı verebiliriz. Burada hem listeyi hem toplam sayıyı döndürüyoruz.

Kullanımı:
```csharp
var liste = _repo.Ara(arama, bolumId, sinif, sayfa, 10, out int toplam);
```

> **Neden iki sorgu?** Sayfada 10 kayıt gösteriyoruz ama "toplam 247 kayıt, 25 sayfa" yazabilmek için filtreye uyan **tüm** kayıtların sayısını bilmemiz gerekiyor. Bu bilgi sayfalanmış sonuçtan çıkarılamaz.

---

## ⌨️ Adım 2: Controller

```csharp
public IActionResult Index(string? arama, long? bolumId, int? sinif, int sayfa = 1)
{
    const int sayfaBoyutu = 10;

    var liste = _ogrenciRepo.Ara(arama, bolumId, sinif, sayfa, sayfaBoyutu,
                                 out int toplamKayit);

    // Sayfalama bilgilerini View'a taşı
    ViewBag.Sayfa        = sayfa;
    ViewBag.ToplamSayfa  = (int)Math.Ceiling((double)toplamKayit / sayfaBoyutu);
    ViewBag.ToplamKayit  = toplamKayit;

    // Filtre değerlerini geri gönder — form dolu kalsın
    ViewBag.Arama    = arama;
    ViewBag.SeciliBolum = bolumId;
    ViewBag.SeciliSinif = sinif;

    BolumListesiniHazirla(bolumId);

    return View(liste);
}
```

**`Math.Ceiling` neden?**
47 kayıt, sayfa başına 10 → 4.7 sayfa. Ama yarım sayfa olmaz, **5** sayfa gerekir. `Ceiling` yukarı yuvarlar.

`(double)` dönüşümü olmadan `47 / 10 = 4` olur (tam sayı bölmesi). Bu ince ayrıntıyı öğrenciye göster.

---

## ⌨️ Adım 3: View — arama formu ve sayfalama

`Views/Ogrenci/Index.cshtml`'in üstüne:

```html
@* ============ ARAMA VE FİLTRE ============ *@
<div class="card border-0 shadow-sm mb-3">
    <div class="card-body">
        <form method="get" asp-action="Index" class="row g-2 align-items-end">

            <div class="col-md-4">
                <label class="form-label small text-muted">Ara</label>
                <input type="text" name="arama" value="@ViewBag.Arama"
                       class="form-control" placeholder="Ad, soyad, e-posta veya TC" />
            </div>

            <div class="col-md-3">
                <label class="form-label small text-muted">Bölüm</label>
                <select name="bolumId" asp-items="ViewBag.Bolumler" class="form-select">
                    <option value="">Tüm bölümler</option>
                </select>
            </div>

            <div class="col-md-2">
                <label class="form-label small text-muted">Sınıf</label>
                <select name="sinif" class="form-select">
                    <option value="">Tümü</option>
                    @for (int i = 1; i <= 6; i++)
                    {
                        <option value="@i" selected="@(ViewBag.SeciliSinif == i)">@i. sınıf</option>
                    }
                </select>
            </div>

            <div class="col-md-3">
                <button type="submit" class="btn btn-primary">
                    <i class="bi bi-search"></i> Ara
                </button>
                <a asp-action="Index" class="btn btn-outline-secondary">Temizle</a>
            </div>

        </form>
    </div>
</div>
```

> **`method="get"` neden?** Arama sonuçları paylaşılabilir ve yer imine eklenebilir olmalı. GET ile filtreler adres çubuğunda görünür: `/Ogrenci?arama=ayse&sinif=2`. POST kullansaydık bu mümkün olmazdı. Arama = GET, kaydetme = POST — genel kural bu.

### Sonuç sayısı ve sayfalama

Tablonun altına:

```html
<div class="d-flex justify-content-between align-items-center mt-3">

    <div class="text-muted small">
        Toplam <strong>@ViewBag.ToplamKayit</strong> kayıt |
        Sayfa @ViewBag.Sayfa / @ViewBag.ToplamSayfa
    </div>

    @if (ViewBag.ToplamSayfa > 1)
    {
        <nav>
            <ul class="pagination pagination-sm mb-0">

                @* Önceki *@
                <li class="page-item @(ViewBag.Sayfa == 1 ? "disabled" : "")">
                    <a class="page-link"
                       asp-action="Index"
                       asp-route-arama="@ViewBag.Arama"
                       asp-route-bolumId="@ViewBag.SeciliBolum"
                       asp-route-sinif="@ViewBag.SeciliSinif"
                       asp-route-sayfa="@(ViewBag.Sayfa - 1)">‹</a>
                </li>

                @* Sayfa numaraları *@
                @for (int i = 1; i <= ViewBag.ToplamSayfa; i++)
                {
                    <li class="page-item @(i == ViewBag.Sayfa ? "active" : "")">
                        <a class="page-link"
                           asp-action="Index"
                           asp-route-arama="@ViewBag.Arama"
                           asp-route-bolumId="@ViewBag.SeciliBolum"
                           asp-route-sinif="@ViewBag.SeciliSinif"
                           asp-route-sayfa="@i">@i</a>
                    </li>
                }

                @* Sonraki *@
                <li class="page-item @(ViewBag.Sayfa == ViewBag.ToplamSayfa ? "disabled" : "")">
                    <a class="page-link"
                       asp-action="Index"
                       asp-route-arama="@ViewBag.Arama"
                       asp-route-bolumId="@ViewBag.SeciliBolum"
                       asp-route-sinif="@ViewBag.SeciliSinif"
                       asp-route-sayfa="@(ViewBag.Sayfa + 1)">›</a>
                </li>

            </ul>
        </nav>
    }
</div>
```

### ⚠️ En kritik nokta

Her sayfalama linkinde **arama ve filtre değerlerini taşımak zorundayız**:

```html
asp-route-arama="@ViewBag.Arama"
asp-route-bolumId="@ViewBag.SeciliBolum"
asp-route-sinif="@ViewBag.SeciliSinif"
```

Bunları koymazsanız: kullanıcı "Ayşe" arar, 2. sayfaya geçer, **arama sıfırlanır ve tüm öğrenciler gelir.** Kullanıcıyı en çok sinir eden hatalardan biridir.

> **Eğitmen numarası:** Bu satırları bilerek sil, arama yapıp 2. sayfaya geçmelerini iste. Sorunu kendileri yaşasın. Sonra geri ekle.

### Boş sonuç mesajı

```html
@if (Model.Count == 0)
{
    <div class="text-center text-muted py-5">
        <i class="bi bi-search fs-1 d-block mb-2"></i>
        @if (!string.IsNullOrEmpty(ViewBag.Arama as string))
        {
            <p>"<strong>@ViewBag.Arama</strong>" için sonuç bulunamadı.</p>
            <a asp-action="Index" class="btn btn-sm btn-outline-primary">Filtreleri temizle</a>
        }
        else
        {
            <p>Henüz öğrenci eklenmemiş.</p>
            <a asp-action="Create" class="btn btn-sm btn-primary">İlk öğrenciyi ekle</a>
        }
    </div>
}
```

> **Arayüz yazısı dersi:** Boş sonuç ekranı iki farklı durumu ayırt ediyor — "arama sonuç vermedi" ile "hiç kayıt yok" farklı şeyler ve kullanıcının atacağı adım da farklı. İkisine de aynı "Kayıt bulunamadı" mesajını göstermek tembelliktir.

---

## ▶️ Çalıştır ve gör

| Test | Beklenen |
|---|---|
| Arama kutusuna bir isim yaz | Sadece o kayıtlar |
| Bölüm seç | Sadece o bölüm |
| Arama + bölüm birlikte | İkisi de uygulanmış |
| Aramadan sonra 2. sayfa | **Arama korunuyor** |
| Olmayan bir isim ara | "Sonuç bulunamadı" + temizle butonu |
| Adres çubuğuna `?arama=a&sayfa=2` yaz | Doğrudan o sonuç |
| "Temizle" | Tüm filtreler sıfır |
| Adres çubuğuna `?sayfa=999` yaz | Boş liste, uygulama çökmüyor |

---

## ⚠️ Sık yapılan hatalar

| Hata | Sebep | Çözüm |
|---|---|---|
| `Invalid usage of the option NEXT in the FETCH statement` | `ORDER BY` yok | `OFFSET` için `ORDER BY` zorunlu |
| Arama hiçbir şey bulmuyor | `%` işaretleri eksik | `"%" + arama + "%"` |
| Sayfa değişince arama sıfırlanıyor | `asp-route-*` eksik | Tüm filtreleri her linke ekle |
| `Must declare the scalar variable '@arama'` | Koşul eklendi ama parametre eklenmedi | İkisinin `if` koşulu aynı olmalı |
| Sayfa sayısı hep 1 | `Math.Ceiling` yok veya tam sayı bölmesi | `(double)` dönüşümü ekle |
| 2. sayfada aynı kayıtlar | `OFFSET` hesabı yanlış | `(sayfa - 1) * sayfaBoyutu` |
| Sayfa 0 veya negatif → hata | Kullanıcı adresi elle değiştirmiş | `if (sayfa < 1) sayfa = 1;` ekle |
| Filtre seçili kalmıyor | ViewBag'e geri gönderilmemiş | Controller'da ViewBag'e ata |
| Türkçe arama çalışmıyor (`i`/`ı`) | Veritabanı harmanlama (collation) ayarı | Genelde sorun olmaz; olursa `COLLATE Turkish_CI_AS` |

---

## ✏️ Öğrenci alıştırması

**A. Diğer listelere uygula**
Aynı arama+sayfalama yapısını `Akademisyen` listesine ekle.

**B. Sayfa boyutu seçimi**
Kullanıcı sayfa başına kaç kayıt göreceğini seçebilsin (10 / 25 / 50).

**C. Sıralama**
Tablo başlıklarına tıklanınca o sütuna göre sıralansın. İkinci tıkta ters sırala.
⚠️ **Güvenlik uyarısı:** Sıralama sütununu doğrudan SQL'e yapıştırma! Beyaz liste kullan:

```csharp
string siraSutunu = siralama switch
{
    "ad"     => "o.ogrenci_ad",
    "soyad"  => "o.ogrenci_soyad",
    "sinif"  => "o.ogrenci_sinif",
    "tarih"  => "o.created_date",
    _        => "o.ogrenci_ad"        // varsayılan
};
```
> Bu, "kullanıcı girdisini SQL'e koyma" kuralının doğru çözümü: kullanıcının değerini kullanmıyoruz, **bizim listemizden eşleşeni** seçiyoruz.

**D. Akıllı sayfalama (zorlayıcı)**
100 sayfa varsa 100 numara göstermek saçma. Şöyle göster:
```
‹  1 ... 4 [5] 6 ... 100  ›
```

**E. Düşünme soruları**
1. Neden iki ayrı sorgu (sayım + veri) çalıştırıyoruz? Tek sorguda yapılabilir mi?
2. 1 milyon öğrenci olsa `LIKE '%ayse%'` araması ne kadar sürer? Neden yavaş? (İpucu: indeks, `%` ile başlayan aramalarda kullanılamaz.)
3. Sayfa numarasını adres çubuğunda görmek iyi mi kötü mü? Artıları ve eksileri neler?

---

## Sonraki adım

👉 [`12-cila-ve-hata-yonetimi.md`](12-cila-ve-hata-yonetimi.md)
