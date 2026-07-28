# OSINT Cheat Sheet — Red Team Recon

Red team engagement'ların çoğu, hedefe hiç paket atmadan başlar. **OSINT (Open Source Intelligence)**, halka açık kaynaklardan (arama motorları, sosyal medya, DNS kayıtları, sızıntı veritabanları, kod deposu vb.) hedef hakkında bilgi toplama sürecidir — tamamen pasif olduğu için genelde "rules of engagement" içinde en güvenli aşamadır ve sonraki aşamaları (phishing pretexting, initial access, wordlist üretimi) doğrudan besler.

---

## İçindekiler

1. [OSINT Metodolojisi](#1-osint-metodolojisi)
2. [Domain & DNS OSINT](#2-domain--dns-osint)
3. [Search Engine & Dorking](#3-search-engine--dorking)
4. [Email & Username OSINT](#4-email--username-osint)
5. [Sosyal Medya & Kişi OSINT'i](#5-sosyal-medya--kişi-osinti)
6. [Görsel & Metadata OSINT](#6-görsel--metadata-osint)
7. [Website / Infrastructure OSINT](#7-website--infrastructure-osint)
8. [Şirket / Kurumsal OSINT](#8-şirket--kurumsal-osint)
9. [Otomatik OSINT Framework'leri](#9-otomatik-osint-frameworkleri)
10. [OPSEC & Legal/Etik Sınırlar](#10-opsec--legaletik-sınırlar)
11. [Hızlı Komut Referansı](#11-hızlı-komut-referansı)
12. [Red Team Engagement'a Entegrasyon](#12-red-team-engagementa-entegrasyon)

---

## 1. OSINT Metodolojisi

Rastgele araç denemek yerine standart bir akış izle:

```
Requirements → Source Identification → Collection → Processing → Analysis → Reporting
```

| Aşama | Ne yapılır |
|---|---|
| **Requirements** | Ne öğrenmek istiyorsun? (çalışan listesi, teknoloji stack'i, sızmış credential, subdomain haritası) |
| **Source Identification** | Hangi kaynaklar bu bilgiyi verir? (LinkedIn, Shodan, GitHub, WHOIS...) |
| **Collection** | Araçlarla veriyi topla (aşağıdaki bölümler) |
| **Processing** | Ham veriyi normalize et (email formatı çıkar, subdomain'leri dedup et) |
| **Analysis** | Verideki örüntüleri/ilişkileri bul (aynı şifre birden fazla sızıntıda mı, hangi çalışan hangi teknolojiyi kullanıyor) |
| **Reporting** | Bulguları red team raporuna/pretexting senaryosuna dönüştür |

> **Pasif vs Aktif Recon:** OSINT esas olarak **pasif** recon'dur — hedefin altyapısına doğrudan paket/istek göndermezsin (WHOIS, arşiv sitesi, arama motoru sorgusu gibi üçüncü taraf kaynaklar kullanılır). Hedefin DNS sunucusuna doğrudan sorgu atmak (`dig @target-ns`) veya port taramak gibi işlemler **aktif** recon sayılır ve genelde scope/rules of engagement onayı gerektirir.

---

## 2. Domain & DNS OSINT

| Araç/Kaynak | Ne işe yarar |
|---|---|
| `whois domain.com` | Domain kayıt tarihi, registrar, kayıt sahibi (privacy protection yoksa) |
| **crt.sh** (crt.sh) | Certificate Transparency logları üzerinden subdomain keşfi — pasif, hedefe hiç dokunmaz |
| `subfinder -d domain.com` | Pasif kaynaklardan (API'ler) subdomain toplama |
| `amass enum -passive -d domain.com` | Çoklu kaynaktan (crt.sh, DNS, API) kapsamlı subdomain enumeration |
| `assetfinder domain.com` | Hızlı, basit subdomain/related domain listesi |
| `dnsrecon -d domain.com` | DNS kayıt türlerini (MX, TXT, NS) sorgulama, zone transfer denemesi |
| **SecurityTrails / DNSDumpster** | Web tabanlı pasif DNS geçmişi, subdomain haritası |

```bash
# Certificate Transparency ile pasif subdomain keşfi
curl -s "https://crt.sh/?q=%25.domain.com&output=json" | jq -r '.[].name_value' | sort -u

# Subfinder + httpx ile canlı subdomain'leri filtreleme
subfinder -d domain.com -silent | httpx -silent -title -status-code
```

> **Neden önemli:** Her subdomain potansiyel bir giriş noktası. Unutulmuş bir `dev.domain.com` veya `old-vpn.domain.com`, ana siteden çok daha zayıf korunuyor olabilir.

---

## 3. Search Engine & Dorking

### Google Dorking operatörleri

| Operatör | Kullanım | Örnek |
|---|---|---|
| `site:` | Belirli bir domain içinde ara | `site:domain.com filetype:pdf` |
| `filetype:` | Dosya türüne göre filtrele | `filetype:xlsx "password"` |
| `intitle:` | Sayfa başlığında ara | `intitle:"index of" backup` |
| `inurl:` | URL içinde ara | `inurl:admin site:domain.com` |
| `intext:` | Sayfa içeriğinde ara | `intext:"internal use only"` |
| `-` | Sonuçlardan hariç tut | `site:domain.com -www` |
| `"..."` | Tam ifade araması | `"confidential" site:domain.com` |

```
site:domain.com filetype:pdf OR filetype:docx OR filetype:xlsx
site:domain.com inurl:login OR inurl:admin OR inurl:portal
site:pastebin.com "domain.com"
site:github.com "domain.com" password OR api_key OR secret
```

### Shodan / Censys dorking

| Sorgu | Ne bulur |
|---|---|
| `hostname:domain.com` | Domain'e bağlı tüm indekslenmiş cihazlar |
| `org:"Company Name"` | Şirket adına kayıtlı IP bloklarındaki cihazlar |
| `ssl:"domain.com"` | Domain'in SSL sertifikasını kullanan tüm IP'ler (subdomain keşfi için de işe yarar) |
| `port:3389 country:"TR"` | Belirli ülkede açık RDP portları |
| `http.title:"Login"` | Belirli bir login sayfası başlığına sahip sistemler |

> **GHDB (Google Hacking Database)** — exploit-db.com üzerindeki hazır dork koleksiyonu; kategori bazlı (login sayfaları, hassas dosyalar, açık kameralar vb.) hazır sorgular içerir.

---

## 4. Email & Username OSINT

| Araç | Ne işe yarar |
|---|---|
| `theHarvester -d domain.com -b all` | Arama motorları, PGP sunucuları, Shodan gibi kaynaklardan email/subdomain/isim toplama |
| **Hunter.io** | Domain'e ait email formatını tahmin etme (`ad.soyad@domain.com` gibi) ve doğrulama |
| **Sherlock** (`sherlock username`) | Bir kullanıcı adının 300+ platformda (GitHub, Instagram, Reddit...) var olup olmadığını tarama |
| **WhatsMyName** | Sherlock'a benzer, web tabanlı username enumeration |
| **Have I Been Pwned (HIBP)** | Bir email adresinin hangi veri sızıntılarında geçtiğini kontrol etme |
| **Dehashed** | Sızmış credential veritabanlarında arama (ücretli, yasal kullanım) |

```bash
theHarvester -d domain.com -b google,bing,linkedin,crtsh -f output

sherlock target_username --output results.txt
```

> **Email format tahmini:** Bir şirketin 2-3 gerçek email adresini bulursan (LinkedIn, basın bültenleri, GitHub commit'leri), formatı çıkarıp (`ilkharf.soyad@domain.com` gibi) çalışan listesinden (LinkedIn) tüm organizasyonun email listesini üretebilirsin — phishing hedef listesi için kritik.

---

## 5. Sosyal Medya & Kişi OSINT'i

- **LinkedIn** — çalışan listesi, org chart, kullanılan teknolojiler (iş ilanlarından), yönetici isimleri (whaling/BEC hedefleri için).
- **X (Twitter) / Instagram / Facebook** — kişisel bilgi sızıntısı (doğum tarihi, evcil hayvan adı, konum etiketleri — şifre tahmini/güvenlik sorusu için).
- **GitHub** — çalışanların kişisel repo'larında yanlışlıkla commit edilmiş API key, internal hostname, config dosyaları.
- **Maltego** — görsel bağlantı analizi; email → sosyal medya → domain → IP gibi transform zincirleriyle ilişki haritası çıkarır.
- **social-analyzer** — bir kişinin farklı platformlardaki varlığını otomatik tarayan araç.

```
GitHub dorking örnekleri:
"domain.com" password
"domain.com" api_key
org:company-name filename:.env
```

> **Pretexting için altın kaynak:** LinkedIn'deki "şu an X şirketinde çalışıyor, önceden Y'de çalıştı, Z üniversitesinden mezun" gibi bilgiler, phishing senaryosunu inandırıcı kılmak için doğrudan kullanılır.

---

## 6. Görsel & Metadata OSINT

| Araç | Ne işe yarar |
|---|---|
| `exiftool image.jpg` | Fotoğrafın EXIF verisini çıkarma (GPS koordinatı, çekim tarihi, cihaz modeli) |
| **Google Images / TinEye / Yandex** | Ters görsel arama — bir fotoğrafın başka nerede kullanıldığını bulma |
| **Google Earth / Street View** | Fotoğraftaki arka plan ipuçlarından (tabela, bina) konum doğrulama (geolocation) |

```bash
exiftool -gps:all photo.jpg     # GPS koordinatlarını çıkar
exiftool -all photo.jpg         # Tüm metadata (kamera modeli, yazılım, tarih)
```

> **Ofis fotoğrafları:** Şirketlerin "ofisimizden" diye paylaştığı sosyal medya fotoğraflarında genelde arka planda monitör ekranları, badge'ler, whiteboard yazıları görülebilir — fiziksel güvenlik/badge cloning senaryoları için kullanılır.

---

## 7. Website / Infrastructure OSINT

| Araç/Kaynak | Ne işe yarar |
|---|---|
| **Wayback Machine** (web.archive.org) | Sitenin geçmiş versiyonlarını görme — kaldırılmış sayfalar, eski admin panel linkleri, sızmış içerik |
| **BuiltWith / Wappalyzer** | Sitenin kullandığı CMS, framework, analytics, CDN gibi teknoloji stack'ini tespit etme |
| `robots.txt` / `sitemap.xml` | Sitenin "gizlemeye çalıştığı" ama aslında listelediği path'ler |
| **Netlas / FOFA** | Shodan'a alternatif, altyapı/asset arama motorları |

```bash
# Wayback Machine'deki tüm bilinen URL'leri çekme
curl -s "http://web.archive.org/cdx/search/cdx?url=domain.com/*&output=text&fl=original&collapse=urlkey"
```

> **Teknoloji stack'i neden önemli:** Hedefin WordPress + eski bir plugin kullandığını öğrenirsen, doğrudan o plugin'in bilinen CVE'lerine yönelebilirsin (DC-1'de Drupal versiyonunu tespit edip Drupalgeddon2'ye gitmenle aynı mantık).

---

## 8. Şirket / Kurumsal OSINT

- **İş ilanları** (LinkedIn, Indeed, şirket kariyer sayfası) — "5+ yıl Cisco ASA deneyimi", "AWS ortamı yönetimi" gibi ilanlar, kullanılan teknoloji/ürünleri doğrudan ele verir.
- **Basın bültenleri / yıllık raporlar** — satın almalar, yeni ofisler, üst düzey personel değişiklikleri (whaling/BEC senaryosu için güncel isim bilgisi).
- **SEC/ticaret sicili kayıtları** — şirket yapısı, yan kuruluşlar, yönetici isimleri (halka açık kurumlarda).
- **Şirket blog/GitHub organizasyonu** — açık kaynak katkıları, kullanılan iç araçlar, geliştirici isimleri.

---

## 9. Otomatik OSINT Framework'leri

| Araç | Ne işe yarar |
|---|---|
| **SpiderFoot** | 200+ modülle otomatik OSINT toplama (domain, IP, email, kişi) — GUI/CLI, sonuçları grafik olarak gösterir |
| **Recon-ng** | Modüler, Metasploit benzeri arayüze sahip CLI OSINT framework'ü |
| **Maltego** | Görsel transform tabanlı ilişki/graph analizi — en güçlü kişi/organizasyon haritalama aracı |
| **OSINT Framework** (osintframework.com) | Araç değil, kategori bazlı OSINT kaynak/araç dizini — "nereden başlamalıyım" sorusuna cevap |

```bash
spiderfoot -s domain.com -m sfp_dnsresolve,sfp_crt,sfp_hackertarget -o csv
```

---

## 10. OPSEC & Legal/Etik Sınırlar

- [ ] **Scope'u yaz ve buna bağlı kal** — sadece yetkili olduğun domain/kişiler hakkında bilgi topla, engagement kapsamı dışına çıkma.
- [ ] **Sock puppet hesapları kullan** — sosyal medya/LinkedIn araştırmasını gerçek kişisel hesabınla değil, ayrı, iz sürülemeyen hesaplarla yap.
- [ ] **Aktif recon'u ayırt et** — pasif kaynak kullanımı (crt.sh, WHOIS, arşiv) ile hedef altyapısına doğrudan istek gönderme (port scan, DNS zone transfer denemesi) arasındaki farkı bil; ikincisi genelde ayrı onay gerektirir.
- [ ] **Kişisel veriyi (PII) sorumlu şekilde işle** — toplanan veriyi sadece rapor kapsamında kullan, gereksiz saklama.
- [ ] **Rules of Engagement (RoE) belgesini** her zaman engagement öncesi imzalat/oku.

---

## 11. Hızlı Komut Referansı

| İhtiyaç | Komut |
|---|---|
| Subdomain (pasif) | `subfinder -d domain.com -silent` |
| Subdomain (çoklu kaynak) | `amass enum -passive -d domain.com` |
| Canlı subdomain filtreleme | `httpx -l subs.txt -silent -title -status-code` |
| Email/isim toplama | `theHarvester -d domain.com -b all` |
| Username enumeration | `sherlock username` |
| WHOIS | `whois domain.com` |
| DNS kayıtları | `dnsrecon -d domain.com` |
| Certificate Transparency | `curl -s "https://crt.sh/?q=%25.domain.com&output=json"` |
| EXIF metadata | `exiftool image.jpg` |
| Wayback URL listesi | `curl "http://web.archive.org/cdx/search/cdx?url=domain.com/*&output=text"` |

---

## 12. Red Team Engagement'a Entegrasyon

OSINT tek başına bir amaç değil — topladığın veri sonraki fazları besler:

1. **Subdomain/teknoloji haritası** → saldırı yüzeyi önceliklendirme (hangi sistem en zayıf/en eski).
2. **Çalışan listesi + email formatı** → phishing/spear phishing hedef listesi ve pretexting senaryosu.
3. **Sızmış credential (HIBP/Dehashed)** → password spraying / credential stuffing için başlangıç noktası.
4. **İş ilanları/GitHub** → kullanılan yazılım stack'i → bilinen CVE araştırması (searchsploit, Exploit-DB).
5. **Fiziksel/ofis fotoğrafları** → badge/rozet klonlama, tailgating senaryoları için fiziksel pentest desteği.

> Tıpkı DC-1'de nmap/nikto ile başlayıp Drupal versiyonunu bulup Drupalgeddon2'ye gittiğin gibi — OSINT fazında topladığın her bilgi parçası, sonraki adımı doğrudan şekillendirir. İyi bir OSINT raporu, red team engagement'ının geri kalanının verimliliğini belirler.

---

*Red team engagement'ları ve OSINT çalışmaları için referans olarak hazırlanmıştır. Tüm teknikler yalnızca yazılı yetkilendirme (scope/RoE) dahilinde kullanılmalıdır.*
