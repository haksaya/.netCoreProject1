# Modül 0 — Ortam Kurulumu

**Süre:** 1 ders saati
**Ön koşul:** Yok

---

## 🎯 Bu derste ne yapacağız

Bilgisayarlara gerekli araçları kuracağız ve "merhaba dünya" seviyesinde ilk web sayfasını çalıştırıp herkesin ortamının hazır olduğunu doğrulayacağız.

> **Eğitmen notu:** Bu dersi laboratuvarda **dersten önce** bir kez kendin baştan sona yap. Kurulumlar internet hızına bağlı olarak 20-40 dakika sürebilir. Mümkünse kurulum dosyalarını USB'ye veya ortak ağ klasörüne önceden indir.

---

## 📖 Kavram: Neye ihtiyacımız var?

Öğrencilere tahtaya şunu çiz:

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   KOD YAZMAK     │     │  KODU ÇALIŞTIR   │     │   VERİ SAKLAMAK  │
│  Visual Studio   │ ──▶ │    .NET SDK      │ ──▶ │    SQL Server    │
│   (editör)       │     │   (derleyici)    │     │  (veritabanı)    │
└──────────────────┘     └──────────────────┘     └──────────────────┘
```

**Anlatım:**
- **Visual Studio** → Kodu yazdığımız program. Word'ün programcı versiyonu gibi düşünün, ama hatalarınızı da söylüyor.
- **.NET SDK** → Yazdığımız C# kodunu bilgisayarın anlayacağı hâle çeviren araç seti.
- **SQL Server** → Verileri saklayan program. Excel gibi ama çok daha güçlü ve aynı anda binlerce kişi kullanabilir.
- **SSMS** → SQL Server'a bakmak için kullandığımız pencere. SQL Server'ın kendisi görünmez bir servistir; SSMS onun gözüdür.

---

## ⌨️ Adım adım kurulum

### Adım 1 — Visual Studio 2022 Community

1. https://visualstudio.microsoft.com/tr/downloads/ adresine git
2. **Community 2022** sürümünü indir (ücretsiz, öğrenciler için tamamen yeterli)
3. Kurulum sihirbazında **iş yükü (workload)** seçimi ekranı gelecek. Şunu işaretle:
   - ☑️ **ASP.NET ve web geliştirme**
4. Diğer iş yüklerine gerek yok. (Hepsini seçerse 50 GB yer kaplar — uyar!)
5. Kur'a bas ve bekle.

> **Alternatif:** Öğrencilerde Mac veya Linux varsa **Visual Studio Code + C# Dev Kit eklentisi** kullanabilirler. Rehberdeki tüm kodlar aynıdır, yalnızca menü konumları değişir. VS Code kullanacaklar için terminal komutları her modülde ayrıca verilmiştir.

### Adım 2 — .NET SDK

Visual Studio kurulumu .NET SDK'yı zaten getirir. Yine de doğrulayalım.

Windows'ta **Komut İstemi**'ni (cmd) aç ve şunu yaz:

```bash
dotnet --version
```

Ekranda şuna benzer bir şey görmelisin:

```
10.0.100
```

Görmüyorsan https://dotnet.microsoft.com/download adresinden **.NET 10 SDK**'yı ayrıca indir.

> **Sürüm notu:** Rehber .NET 10 (LTS, Kasım 2028'e kadar destekli) için yazıldı. Laboratuvarda .NET 8 varsa da sorun yok — tüm kodlar aynen çalışır.

### Adım 3 — SQL Server Express

1. https://www.microsoft.com/tr-tr/sql-server/sql-server-downloads adresine git
2. **Express** sürümünü indir (ücretsiz)
3. Kurulum tipi olarak **Temel (Basic)** seç
4. Kurulum bitince ekranda çıkan **bağlantı dizesini (connection string)** bir yere not et. Şuna benzer:
   ```
   Server=localhost\SQLEXPRESS;Database=master;Trusted_Connection=True;
   ```

### Adım 4 — SSMS (SQL Server Management Studio)

1. https://learn.microsoft.com/tr-tr/ssms/download-sql-server-management-studio-ssms
2. İndir, kur, aç
3. Açılışta bağlantı penceresi gelecek:
   - **Server name:** `localhost\SQLEXPRESS`  (veya sadece `.\SQLEXPRESS`)
   - **Authentication:** Windows Authentication
   - **Connect** butonuna bas

Sol tarafta ağaç yapısı göründüyse başarılı. 🎉

---

## ▶️ Çalıştır ve gör: İlk proje

Herkesin ortamı çalışıyor mu, 5 dakikada test edelim.

### Visual Studio ile

1. Visual Studio'yu aç → **Yeni proje oluştur**
2. Arama kutusuna `ASP.NET Core Web App (Model-View-Controller)` yaz, seç
3. **Proje adı:** `DenemeProje`
4. **Framework:** .NET 10.0
5. Oluştur
6. Yeşil ▶️ butonuna bas

Tarayıcı açılıp "Welcome" yazan bir sayfa gösterirse **ortam hazır demektir**.

### VS Code / terminal ile

```bash
dotnet new mvc -n DenemeProje
cd DenemeProje
dotnet run
```

Terminalde çıkan `http://localhost:5xxx` adresine tarayıcıdan git.

> Bu deneme projesini sonra sileceğiz. Asıl projeyi Modül 2'de oluşturacağız.

---

## 📁 Proje yedekleme alışkanlığı

Öğrencilere ilk günden şunu söyle: **"Her hafta sonunda projenizi yedekleyin."**

**En basit yöntem (herkes yapabilir):**
Proje klasörünü kopyala, adına tarih ekle:
```
OkulYonetim_2026-09-15
OkulYonetim_2026-09-22
```

**Daha iyi yöntem (yapabilenler için):**
```bash
git init
git add .
git commit -m "Modul 3 tamamlandi"
```

> **Eğitmen notu:** Git'i zorunlu tutma. İlk web uygulaması yapan öğrenciye aynı anda git öğretmek bilişsel yükü ikiye katlar. İsteyen öğrenciye ayrıca göster.

---

## ⚠️ Sık yapılan hatalar

| Hata | Sebep | Çözüm |
|---|---|---|
| `dotnet` komutu tanınmıyor | SDK kurulmamış veya PATH'e eklenmemiş | Bilgisayarı yeniden başlat. Düzelmezse SDK'yı yeniden kur. |
| SSMS bağlanamıyor: "network-related error" | SQL Server servisi çalışmıyor | Windows → Hizmetler → `SQL Server (SQLEXPRESS)` → Başlat |
| SSMS'te sunucu adı bilinmiyor | Instance adı farklı olabilir | Sunucu adı kutusuna sadece `.` (nokta) veya `localhost` dene |
| Visual Studio'da "ASP.NET Core Web App" şablonu yok | İş yükü seçilmemiş | Visual Studio Installer → Değiştir → "ASP.NET ve web geliştirme" işaretle |
| Proje çalışıyor ama tarayıcı "güvenli değil" diyor | HTTPS geliştirme sertifikası | Terminalde: `dotnet dev-certs https --trust` |
| Port zaten kullanımda | Önceki çalıştırma kapanmamış | Visual Studio'yu kapat-aç, veya Görev Yöneticisi'nden `dotnet.exe` süreçlerini sonlandır |

---

## ✏️ Öğrenci alıştırması

1. Kurulumları tamamla, `dotnet --version` çıktısının ekran görüntüsünü al.
2. Deneme projesini çalıştır, açılan sayfanın ekran görüntüsünü al.
3. SSMS'te bağlantı kurduğun ekranın görüntüsünü al.
4. Üç görüntüyü tek bir belgeye koyup teslim et.

*(Bu, herkesin ortamının hazır olduğunu ders dışında doğrulamanın en hızlı yolu.)*

---

## Sonraki adım

👉 [`02-veritabani.md`](02-veritabani.md) — Veritabanını kuralım ve tabloları tanıyalım.
