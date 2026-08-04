/* ============================================================
   OKUL YÖNETİM SİSTEMİ — TEST VERİSİ
   ------------------------------------------------------------
   İçerik:  3 fakülte, 6 bölüm, 15 öğrenci, 8 akademisyen

   KULLANIM:
     1. Önce tabloların oluşturulmuş olduğundan emin ol
     2. Bu script'i SSMS'te aç, Ctrl+A ile tümünü seç, F5
     3. En alttaki doğrulama sorguları sonucu gösterir

   NOTLAR:
     - Türkçe karakterler için metinlerin başında N' öneki var.
       N olmadan "Mühendislik" → "Mhendislik" olabilir.
     - ID'leri elle yazmıyoruz; IDENTITY otomatik veriyor.
       Bu yüzden yabancı anahtarları isimle arayarak buluyoruz.
     - TC kimlik numaraları UYDURMADIR ama gerçek doğrulama
       algoritmasına uygundur (Modül 7'deki TcKimlikAttribute
       alıştırması bu verilerle test edilebilsin diye).
     - Script tekrar tekrar çalıştırılabilir: her seferinde
       önce mevcut veriyi siler.
   ============================================================ */

USE OkulDB;
GO

/* ------------------------------------------------------------
   TEMİZLİK — Sıra önemli! Önce çocuk tablolar silinir,
   yoksa yabancı anahtar kısıtı hata verir.
   ------------------------------------------------------------ */
DELETE FROM ogrenci;
DELETE FROM akademisyen;
DELETE FROM bolum;
DELETE FROM fakulte;
GO

-- Kimlik sayaçlarını sıfırla (id'ler yine 1'den başlasın)
DBCC CHECKIDENT ('ogrenci',     RESEED, 0);
DBCC CHECKIDENT ('akademisyen', RESEED, 0);
DBCC CHECKIDENT ('bolum',       RESEED, 0);
DBCC CHECKIDENT ('fakulte',     RESEED, 0);
GO


/* ============================================================
   1) FAKÜLTELER
   ============================================================ */
INSERT INTO fakulte
    (fakulte_ad, fakulte_adres, fakulte_telefon, fakulte_eposta,
     created_date, updated_date, is_active)
VALUES
    (N'Mühendislik Fakültesi',
     N'Merkez Kampüs A Blok, Esenler / İstanbul',
     '02124440101', 'muhendislik@ornekuni.edu.tr', GETDATE(), NULL, '1'),

    (N'Fen-Edebiyat Fakültesi',
     N'Merkez Kampüs B Blok, Esenler / İstanbul',
     '02124440102', 'fenedebiyat@ornekuni.edu.tr', GETDATE(), NULL, '1'),

    (N'İktisadi ve İdari Bilimler Fakültesi',
     N'Güney Kampüs C Blok, Bahçelievler / İstanbul',
     '02124440103', 'iibf@ornekuni.edu.tr', GETDATE(), NULL, '1');
GO


/* ============================================================
   2) BÖLÜMLER
   Fakülte id'lerini isimle arıyoruz — böylece id'ler
   değişse bile script doğru çalışır.
   ============================================================ */
INSERT INTO bolum
    (fakulte_id, bolum_adi, bolum_adres, bolum_telefon, bolum_eposta,
     created_date, updated_date, is_active)
VALUES
    ((SELECT fakulte_id FROM fakulte WHERE fakulte_ad = N'Mühendislik Fakültesi'),
     N'Bilgisayar Mühendisliği', N'A Blok 3. Kat',
     '02124440201', 'bilgisayar@ornekuni.edu.tr', GETDATE(), NULL, '1'),

    ((SELECT fakulte_id FROM fakulte WHERE fakulte_ad = N'Mühendislik Fakültesi'),
     N'Makine Mühendisliği', N'A Blok 2. Kat',
     '02124440202', 'makine@ornekuni.edu.tr', GETDATE(), NULL, '1'),

    ((SELECT fakulte_id FROM fakulte WHERE fakulte_ad = N'Mühendislik Fakültesi'),
     N'Elektrik-Elektronik Mühendisliği', N'A Blok 4. Kat',
     '02124440203', 'elektrik@ornekuni.edu.tr', GETDATE(), NULL, '1'),

    ((SELECT fakulte_id FROM fakulte WHERE fakulte_ad = N'Fen-Edebiyat Fakültesi'),
     N'Türk Dili ve Edebiyatı', N'B Blok 1. Kat',
     '02124440204', 'tde@ornekuni.edu.tr', GETDATE(), NULL, '1'),

    ((SELECT fakulte_id FROM fakulte WHERE fakulte_ad = N'Fen-Edebiyat Fakültesi'),
     N'Matematik', N'B Blok 2. Kat',
     '02124440205', 'matematik@ornekuni.edu.tr', GETDATE(), NULL, '1'),

    ((SELECT fakulte_id FROM fakulte WHERE fakulte_ad = N'İktisadi ve İdari Bilimler Fakültesi'),
     N'İşletme', N'C Blok 1. Kat',
     '02124440206', 'isletme@ornekuni.edu.tr', GETDATE(), NULL, '1');
GO


/* ============================================================
   3) ÖĞRENCİLER (15 kayıt)
   ============================================================ */
INSERT INTO ogrenci
    (bolum_id, ogrenci_ad, ogrenci_soyad, ogrenci_sinif, ogrenci_dogum_tarihi,
     ogrenci_cinsiyet, ogrenci_adres, ogrenci_telefon, ogrenci_eposta, ogrenci_tc,
     created_date, updated_date, is_active)
VALUES
    -- Bilgisayar Mühendisliği (5 öğrenci)
    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'Bilgisayar Mühendisliği'),
     N'Ayşe', N'Yılmaz', 3, '2003-04-12', N'Kadın',
     N'Bağcılar / İstanbul', '05321110001', 'ayse.yilmaz@ogr.ornekuni.edu.tr',
     '42950115298', GETDATE(), NULL, '1'),

    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'Bilgisayar Mühendisliği'),
     N'Mehmet', N'Demir', 2, '2004-09-25', N'Erkek',
     N'Kadıköy / İstanbul', '05321110002', 'mehmet.demir@ogr.ornekuni.edu.tr',
     '21199630090', GETDATE(), NULL, '1'),

    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'Bilgisayar Mühendisliği'),
     N'Zeynep', N'Kaya', 4, '2002-01-30', N'Kadın',
     N'Üsküdar / İstanbul', '05321110003', 'zeynep.kaya@ogr.ornekuni.edu.tr',
     '26706917794', GETDATE(), NULL, '1'),

    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'Bilgisayar Mühendisliği'),
     N'Emre', N'Şahin', 1, '2005-06-08', N'Erkek',
     N'Beylikdüzü / İstanbul', '05321110004', 'emre.sahin@ogr.ornekuni.edu.tr',
     '39294742426', GETDATE(), NULL, '1'),

    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'Bilgisayar Mühendisliği'),
     N'Gülşah', N'Öztürk', 3, '2003-11-17', N'Kadın',
     N'Ataşehir / İstanbul', '05321110005', 'gulsah.ozturk@ogr.ornekuni.edu.tr',
     '30202008634', GETDATE(), NULL, '1'),

    -- Makine Mühendisliği (3 öğrenci)
    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'Makine Mühendisliği'),
     N'Burak', N'Çelik', 2, '2004-03-03', N'Erkek',
     N'Bakırköy / İstanbul', '05321110006', 'burak.celik@ogr.ornekuni.edu.tr',
     '24731991444', GETDATE(), NULL, '1'),

    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'Makine Mühendisliği'),
     N'İrem', N'Arslan', 4, '2002-07-21', N'Kadın',
     N'Maltepe / İstanbul', '05321110007', 'irem.arslan@ogr.ornekuni.edu.tr',
     '15752183192', GETDATE(), NULL, '1'),

    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'Makine Mühendisliği'),
     N'Onur', N'Doğan', 1, '2005-12-05', N'Erkek',
     N'Esenyurt / İstanbul', '05321110008', 'onur.dogan@ogr.ornekuni.edu.tr',
     '99940282508', GETDATE(), NULL, '1'),

    -- Elektrik-Elektronik Mühendisliği (2 öğrenci)
    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'Elektrik-Elektronik Mühendisliği'),
     N'Selin', N'Aydın', 3, '2003-02-14', N'Kadın',
     N'Şişli / İstanbul', '05321110009', 'selin.aydin@ogr.ornekuni.edu.tr',
     '44655689142', GETDATE(), NULL, '1'),

    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'Elektrik-Elektronik Mühendisliği'),
     N'Kerem', N'Koç', 2, '2004-05-19', N'Erkek',
     N'Pendik / İstanbul', '05321110010', 'kerem.koc@ogr.ornekuni.edu.tr',
     '72827869054', GETDATE(), NULL, '1'),

    -- Türk Dili ve Edebiyatı (2 öğrenci)
    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'Türk Dili ve Edebiyatı'),
     N'Elif', N'Kurt', 1, '2005-08-30', N'Kadın',
     N'Fatih / İstanbul', '05321110011', 'elif.kurt@ogr.ornekuni.edu.tr',
     '75399574784', GETDATE(), NULL, '1'),

    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'Türk Dili ve Edebiyatı'),
     N'Ahmet', N'Özdemir', 4, '2002-10-11', N'Erkek',
     N'Zeytinburnu / İstanbul', '05321110012', 'ahmet.ozdemir@ogr.ornekuni.edu.tr',
     '77232543834', GETDATE(), NULL, '1'),

    -- Matematik (2 öğrenci)
    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'Matematik'),
     N'Deniz', N'Yıldız', 3, '2003-06-27', N'Kadın',
     N'Beşiktaş / İstanbul', '05321110013', 'deniz.yildiz@ogr.ornekuni.edu.tr',
     '50328735160', GETDATE(), NULL, '1'),

    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'Matematik'),
     N'Can', N'Erdoğan', 2, '2004-04-09', N'Erkek',
     N'Kartal / İstanbul', '05321110014', 'can.erdogan@ogr.ornekuni.edu.tr',
     '51515240856', GETDATE(), NULL, '1'),

    -- İşletme (1 öğrenci)
    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'İşletme'),
     N'Merve', N'Aksoy', 1, '2005-01-22', N'Kadın',
     N'Avcılar / İstanbul', '05321110015', 'merve.aksoy@ogr.ornekuni.edu.tr',
     '29950512722', GETDATE(), NULL, '1');
GO


/* ============================================================
   4) AKADEMİSYENLER (8 kayıt)
   ============================================================ */
INSERT INTO akademisyen
    (bolum_id, akademisyen_ad, akademisyen_soyad, akademisyen_dogum_tarihi,
     akademisyen_cinsiyet, akademisyen_adres, akademisyen_telefon,
     akademisyen_eposta, akademisyen_tc,
     created_date, updated_date, is_active)
VALUES
    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'Bilgisayar Mühendisliği'),
     N'Hakan', N'Güneş', '1978-03-15', N'Erkek',
     N'Beşiktaş / İstanbul', '05339990001', 'hakan.gunes@ornekuni.edu.tr',
     '24449676978', GETDATE(), NULL, '1'),

    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'Bilgisayar Mühendisliği'),
     N'Ebru', N'Tekin', '1985-11-02', N'Kadın',
     N'Sarıyer / İstanbul', '05339990002', 'ebru.tekin@ornekuni.edu.tr',
     '42492946718', GETDATE(), NULL, '1'),

    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'Makine Mühendisliği'),
     N'Serkan', N'Polat', '1972-07-28', N'Erkek',
     N'Kadıköy / İstanbul', '05339990003', 'serkan.polat@ornekuni.edu.tr',
     '44517346756', GETDATE(), NULL, '1'),

    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'Elektrik-Elektronik Mühendisliği'),
     N'Nurcan', N'Bilgin', '1981-09-06', N'Kadın',
     N'Bakırköy / İstanbul', '05339990004', 'nurcan.bilgin@ornekuni.edu.tr',
     '67233260212', GETDATE(), NULL, '1'),

    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'Elektrik-Elektronik Mühendisliği'),
     N'Tolga', N'Ateş', '1976-02-19', N'Erkek',
     N'Ümraniye / İstanbul', '05339990005', 'tolga.ates@ornekuni.edu.tr',
     '46016205206', GETDATE(), NULL, '1'),

    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'Türk Dili ve Edebiyatı'),
     N'Şule', N'Karaca', '1969-12-30', N'Kadın',
     N'Fatih / İstanbul', '05339990006', 'sule.karaca@ornekuni.edu.tr',
     '52085162920', GETDATE(), NULL, '1'),

    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'Matematik'),
     N'Cem', N'Yavuz', '1983-05-24', N'Erkek',
     N'Maltepe / İstanbul', '05339990007', 'cem.yavuz@ornekuni.edu.tr',
     '75359841260', GETDATE(), NULL, '1'),

    ((SELECT bolum_id FROM bolum WHERE bolum_adi = N'İşletme'),
     N'Pınar', N'Sönmez', '1987-10-13', N'Kadın',
     N'Ataşehir / İstanbul', '05339990008', 'pinar.sonmez@ornekuni.edu.tr',
     '89569989520', GETDATE(), NULL, '1');
GO


/* ============================================================
   DOĞRULAMA — Beklenen çıktı: 3 / 6 / 15 / 8
   ============================================================ */
SELECT 'fakulte' AS tablo, COUNT(*) AS kayit_sayisi FROM fakulte
UNION ALL SELECT 'bolum',       COUNT(*) FROM bolum
UNION ALL SELECT 'ogrenci',     COUNT(*) FROM ogrenci
UNION ALL SELECT 'akademisyen', COUNT(*) FROM akademisyen;
GO

-- Bölümlere göre dağılım (dashboard'da göreceğimiz veriyle aynı olmalı)
SELECT
    f.fakulte_ad                                        AS fakulte,
    b.bolum_adi                                         AS bolum,
    (SELECT COUNT(*) FROM ogrenci o
     WHERE o.bolum_id = b.bolum_id AND o.is_active='1')  AS ogrenci_sayisi,
    (SELECT COUNT(*) FROM akademisyen a
     WHERE a.bolum_id = b.bolum_id AND a.is_active='1')  AS akademisyen_sayisi
FROM bolum b
INNER JOIN fakulte f ON b.fakulte_id = f.fakulte_id
WHERE b.is_active = '1'
ORDER BY f.fakulte_ad, b.bolum_adi;
GO


/* ============================================================
   İSTEĞE BAĞLI — Soft delete testi
   Modül 5'te "silinen kayıt duruyor mu?" göstermek için.

   UPDATE ogrenci SET is_active = '0'
   WHERE ogrenci_eposta = 'merve.aksoy@ogr.ornekuni.edu.tr';

   Uygulamada Merve listeden kaybolur ama şu sorgu onu bulur:
   SELECT * FROM ogrenci WHERE is_active = '0';

   Geri getirmek için:
   UPDATE ogrenci SET is_active = '1'
   WHERE ogrenci_eposta = 'merve.aksoy@ogr.ornekuni.edu.tr';
   ============================================================ */
