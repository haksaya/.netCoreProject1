# Modül 1 — Veritabanını Kurma ve Tanıma

**Süre:** 1 ders saati
**Ön koşul:** Modül 0 (ortam kurulumu)

---

## 🎯 Bu derste ne yapacağız

Uygulamanın veritabanını oluşturacağız, tabloları ve aralarındaki ilişkileri inceleyeceğiz, örnek veri girip SQL sorguları yazacağız.

**Ders sonunda öğrenci:** Tabloların neden bu şekilde tasarlandığını açıklayabilecek, basit SELECT sorguları yazabilecek.

---

## 📖 Kavram 1: Neden veritabanı?

**Tahtaya sor:** *"Bir üniversitenin 30.000 öğrencisinin bilgisini nerede saklarsınız?"*

Gelen cevaplar genelde "Excel" olur. Sonra sorunları say:

| Excel ile | Veritabanı ile |
|---|---|
| Aynı anda 1 kişi düzenleyebilir | Binlerce kişi aynı anda |
| Aynı öğrenci 3 kez girilebilir | Kısıtlar (constraint) engeller |
| "Bölümü silinen öğrenciler ne olacak?" belirsiz | İlişkiler bunu yönetir |
| 100.000 satırda donar | Milyonlarca satırda hızlı |
| Kim ne zaman değiştirdi bilinmez | `created_date`, `updated_date` |

---

## 📖 Kavram 2: Tablolar ve ilişkiler

Bizim sistemde 4 tablo var. Tahtaya çiz:

```
┌───────────────────────┐
│       fakulte         │
│───────────────────────│
│ 🔑 fakulte_id         │
│    fakulte_ad         │
│    fakulte_adres      │
│    fakulte_telefon    │
│    fakulte_eposta     │
└───────────┬───────────┘
            │ 1
            │
            │ N
┌───────────▼───────────┐
│        bolum          │
│───────────────────────│
│ 🔑 bolum_id           │
│ 🔗 fakulte_id         │
│    bolum_adi          │
│    ...                │
└─────┬────────────┬────┘
      │ 1        1 │
      │            │
    N │            │ N
┌─────▼──────┐ ┌───▼──────────────┐
│  ogrenci   │ │  akademisyen     │
│────────────│ │──────────────────│
│🔑 ogrenci_id│ │🔑 akademisyen_id │
│🔗 bolum_id  │ │🔗 bolum_id       │
│  ogrenci_ad │ │  akademisyen_ad  │
│  ...        │ │  ...             │
└────────────┘ └──────────────────┘
```

**Anlatım:**

🔑 **Birincil anahtar (Primary Key)** — Her satırı benzersiz yapan numara. Öğrenci numarası gibi. İki farklı öğrencinin numarası aynı olamaz.

🔗 **Yabancı anahtar (Foreign Key)** — Başka bir tablodaki satırı işaret eden alan. `ogrenci` tablosundaki `bolum_id`, o öğrencinin hangi bölümde olduğunu söyler.

**1-N ilişkisi (bir-çok)** — Bir fakültenin **birçok** bölümü olabilir, ama bir bölüm **tek bir** fakülteye aittir.

> **Sınıfta sor:** *"Bir öğrenci iki bölümde birden olabilir mi bizim tasarımda?"*
> Cevap: Hayır, çünkü `ogrenci` tablosunda tek bir `bolum_id` var. Çift anadal yapmak isteseydik ayrı bir tablo gerekirdi. Bu, tasarımın bilinçli bir sınırıdır.

---

## 📖 Kavram 3: Ortak alanlar

Dört tabloda da tekrar eden üç alan var. Bunlar tesadüf değil, **kasıtlı bir tasarım kararı**:

```sql
"created_date" DATETIME NOT NULL,   -- Kayıt ne zaman oluşturuldu
"updated_date" DATETIME NULL,       -- En son ne zaman değiştirildi (hiç değişmediyse NULL)
"is_active"    NVARCHAR(255) NOT NULL -- Kayıt aktif mi?
```

### `is_active` ve "yumuşak silme" (soft delete)

Bu, dersin en önemli kavramlarından biri. Anlat:

> *"Bir öğrenciyi sistemden sildiniz. Ertesi gün 'yanlışlıkla sildim' dediniz. Veriyi gerçekten sildiyseniz geri getiremezsiniz. Üstelik o öğrencinin notları, ödemeleri, mezuniyet kaydı da vardı — hepsi bozulur."*

**Çözüm:** Veriyi silmeyiz, "pasif" işaretleriz.

```sql
-- ❌ Gerçek silme (hard delete) — bizim yapmayacağımız
DELETE FROM ogrenci WHERE ogrenci_id = 5;

-- ✅ Yumuşak silme (soft delete) — bizim yapacağımız
UPDATE ogrenci SET is_active = '0' WHERE ogrenci_id = 5;
```

Sonra listelerken sadece aktif olanları getiririz:

```sql
SELECT * FROM ogrenci WHERE is_active = '1';
```

Kullanıcı açısından kayıt silinmiş görünür, ama veri hâlâ durur.

> **Not:** Bizim şemamızda `is_active` metin (`NVARCHAR`) tipinde, o yüzden `'1'` ve `'0'` **tırnak içinde** yazılır. Bu rehberde `'1'` = aktif, `'0'` = pasif kabul edilmiştir.

---

## ⌨️ Adım adım: Veritabanını oluştur

### Adım 1 — Veritabanı oluştur

SSMS'i aç → **New Query** butonuna bas → şunu yaz ve çalıştır (F5):

```sql
CREATE DATABASE OkulDB;
GO

USE OkulDB;
GO
```

**Açıklama:**
- `CREATE DATABASE` → Boş bir veritabanı oluşturur (içinde henüz tablo yok)
- `GO` → SSMS'e "buraya kadarki komutları çalıştır, sonra devam et" der
- `USE OkulDB` → "Bundan sonraki komutlar bu veritabanında çalışsın"

### Adım 2 — Tabloları oluştur

Elindeki `drawSQL-sqlsrv-export.sql` dosyasının içeriğini yeni bir sorgu penceresine yapıştır ve çalıştır.

Script'i **parça parça** çalıştırmanı öneririm, her tablodan sonra durup açıkla:

```sql
CREATE TABLE "fakulte"(
    "fakulte_id" BIGINT NOT NULL IDENTITY(1, 1) PRIMARY KEY,
    "fakulte_ad" NVARCHAR(255) NOT NULL,
    "fakulte_adres" TEXT NOT NULL,
    "fakulte_telefon" NVARCHAR(255) NOT NULL,
    "fakulte_eposta" NVARCHAR(255) NOT NULL,
    "created_date" DATETIME NOT NULL,
    "updated_date" DATETIME NULL,
    "is_active" NVARCHAR(255) NOT NULL
);
```

**Satır satır anlat:**

| Parça | Anlamı |
|---|---|
| `BIGINT` | Çok büyük tam sayı (9 kentilyona kadar). `INT` de yeterdi ama zararı yok. |
| `IDENTITY(1,1)` | **Otomatik artan sayı.** 1'den başla, her yeni kayıtta 1 artır. Biz `fakulte_id` yazmayacağız, SQL Server kendi verecek. |
| `PRIMARY KEY` | Bu alan benzersiz ve boş olamaz. Tablonun kimliği. |
| `NVARCHAR(255)` | En fazla 255 karakterlik metin. Baştaki **N**, Unicode demek → **Türkçe karakterler (ç, ğ, ş, ı, ö, ü) düzgün saklanır.** |
| `NOT NULL` | Bu alan boş bırakılamaz. |
| `NULL` | Bu alan boş bırakılabilir. (`updated_date` kayıt hiç güncellenmediyse boştur.) |
| `DATETIME` | Tarih **ve** saat. |
| `DATE` | Sadece tarih (doğum tarihi için yeterli, saat gereksiz). |

> **Türkçe karakter uyarısı:** Öğrencilere `VARCHAR` ile `NVARCHAR` farkını mutlaka göster. `VARCHAR` kullanıp "Gülşah" yazarsan "Gülsah" veya "G?ls?h" olarak kaydedilebilir. Baştaki `N` hayat kurtarır.

### Adım 3 — Benzersizlik kısıtları

```sql
CREATE UNIQUE INDEX "fakulte_fakulte_eposta_unique" ON
    "fakulte"("fakulte_eposta");
```

**Anlat:** Bu satır, aynı e-posta adresinin iki kez girilmesini engeller. Veritabanı seviyesinde bir güvenlik önlemi.

> **Önemli — Modül 7'de buraya geri döneceğiz:** Öğrenci formda zaten kayıtlı bir e-posta girerse uygulama **çökecek**. Bunu nasıl güzelce yakalayacağımızı Modül 7'de öğreneceğiz. Şimdilik "veritabanı bize kalkan görevi görüyor" demek yeterli.

### Adım 4 — İlişkileri kur

```sql
ALTER TABLE
    "bolum" ADD CONSTRAINT "bolum_fakulte_id_foreign"
    FOREIGN KEY("fakulte_id") REFERENCES "fakulte"("fakulte_id");
```

**Anlat:** Bu satır şunu garanti eder: `bolum` tablosuna, var olmayan bir fakültenin numarası yazılamaz.

**Canlı deney yap** — bu deney öğrencide kalıcı iz bırakır:

```sql
-- Olmayan bir fakülteye bölüm eklemeyi dene
INSERT INTO bolum (fakulte_id, bolum_adi, bolum_adres, bolum_telefon, bolum_eposta, created_date, is_active)
VALUES (999, 'Hayalet Bölüm', 'Adres', '0000', 'hayalet@okul.edu.tr', GETDATE(), '1');
```

Hata alacaksın:
```
The INSERT statement conflicted with the FOREIGN KEY constraint...
```

*"İşte veritabanı bizi kendi hatamızdan koruyor."*

---

## ▶️ Çalıştır ve gör: Örnek veri

`EK-C-test-verisi.sql` dosyasını çalıştır. İçinde 3 fakülte, 6 bölüm, 15 öğrenci ve 8 akademisyen var.

Sonra beraber sorgular yazın:

```sql
-- 1. Tüm aktif fakülteler
SELECT * FROM fakulte WHERE is_active = '1';

-- 2. Bölümler ve ait oldukları fakülte (JOIN!)
SELECT b.bolum_adi, f.fakulte_ad
FROM bolum b
INNER JOIN fakulte f ON b.fakulte_id = f.fakulte_id
WHERE b.is_active = '1';

-- 3. Her bölümde kaç öğrenci var?
SELECT b.bolum_adi, COUNT(o.ogrenci_id) AS ogrenci_sayisi
FROM bolum b
LEFT JOIN ogrenci o ON o.bolum_id = b.bolum_id AND o.is_active = '1'
WHERE b.is_active = '1'
GROUP BY b.bolum_adi;

-- 4. 3. sınıf öğrencileri
SELECT ogrenci_ad, ogrenci_soyad FROM ogrenci
WHERE ogrenci_sinif = 3 AND is_active = '1';
```

> **Eğitmen notu:** 3. sorgudaki `LEFT JOIN` farkını göster. `INNER JOIN` kullanırsan hiç öğrencisi olmayan bölüm listede **hiç görünmez**. `LEFT JOIN` ile 0 yazarak görünür. Bu ayrım Modül 9'da (dashboard) tekrar karşımıza çıkacak.

---

## 💬 Sınıf tartışması: Bu tasarım kusursuz mu?

Öğrencileri düşündür. Tahtaya üç soru yaz:

**1. `is_active` alanı neden `NVARCHAR(255)`?**
İçine sadece "1" veya "0" yazacağız. 255 karakterlik alan israf. Dahası, biri yanlışlıkla `'evet'` yazarsa veritabanı buna izin verir.
👉 Daha doğrusu: `is_active BIT NOT NULL DEFAULT 1`

**2. `fakulte_adres` neden `TEXT`?**
`TEXT` tipi SQL Server'da artık kullanılmıyor (deprecated), yeni projelerde önerilmiyor.
👉 Daha doğrusu: `NVARCHAR(MAX)`

**3. `ogrenci_tc` neden `NVARCHAR(255)`?**
TC kimlik numarası **her zaman** 11 hane. Değişken uzunluk gereksiz.
👉 Daha doğrusu: `CHAR(11)`

> **Bu dersin en değerli 10 dakikası bu olabilir.** Öğrenci "verilen şemayı sorgulamayı" öğreniyor. Ama sonra ekle: *"Biz yine de bu şemayla devam edeceğiz, çünkü gerçek hayatta size hazır bir veritabanı verilir ve onunla çalışırsınız."*

---

## ⚠️ Sık yapılan hatalar

| Hata | Sebep | Çözüm |
|---|---|---|
| `Invalid object name 'fakulte'` | Yanlış veritabanındasın | Sorgunun başına `USE OkulDB;` ekle veya SSMS'in üstündeki açılır listeden OkulDB'yi seç |
| `Cannot insert explicit value for identity column` | `INSERT`'te `fakulte_id` yazılmış | ID alanını INSERT'e hiç yazma, SQL Server otomatik verir |
| Türkçe karakterler `?` görünüyor | `VARCHAR` kullanılmış veya `N'...'` öneki yok | `NVARCHAR` kullan; INSERT'te `N'Gülşah'` yaz |
| `Cannot insert the value NULL into column` | `NOT NULL` alan boş bırakılmış | O alana değer ver |
| `Violation of UNIQUE KEY constraint` | Aynı e-posta/telefon/TC ikinci kez giriliyor | Farklı bir değer kullan |
| Script'i çalıştırdım hiçbir şey olmadı | Tüm metin seçili değildi | Ctrl+A ile hepsini seç, sonra F5 |

---

## ✏️ Öğrenci alıştırması

**A. Kurulum (herkes yapmalı)**
1. `OkulDB` veritabanını oluştur.
2. Tablo script'ini çalıştır.
3. Test verisini yükle.
4. SSMS'te `ogrenci` tablosuna sağ tık → *Select Top 1000 Rows* → sonucun ekran görüntüsünü al.

**B. SQL sorguları**
Aşağıdaki soruların SQL karşılığını yaz:
1. Kadın öğrencilerin ad ve soyadını listele.
2. "Mühendislik Fakültesi"ne bağlı bölümlerin adlarını listele.
3. En çok akademisyeni olan bölümü bul.
4. 2000 yılından sonra doğan öğrencileri listele.
5. Hiç öğrencisi olmayan bölüm var mı? Bul.

**C. Düşünme sorusu (yazılı, yarım sayfa)**
> Bu sisteme "ders" ve "not" bilgisi eklemek isteseydik kaç yeni tablo gerekirdi? Hangi alanları içerirdi? Çiz ve anlat.

*(Bu soru, dönem sonunda proje genişletmek isteyen öğrenciler için de zemin hazırlar.)*

---

## Sonraki adım

👉 [`03-proje-olusturma-mvc.md`](03-proje-olusturma-mvc.md) — Artık kod yazmaya başlıyoruz.
