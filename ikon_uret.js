// Harcama Takip — uygulama ikonu üretici
// Uygulamanın mavi temasına uygun, cüzdan + gelir/gider oklu ikon üretir.
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const BOYUT = 1024;
const CIKTI_KLASORU = path.join(__dirname, 'ikon_uretim');

// Uygulama temasındaki mavi tonlar (lib/tema/uygulama_temasi.dart)
const MAVI_KOYU = '#0B2E66';
const MAVI = '#14509E';
const MAVI_ORTA = '#2C79D0';
const YESIL = '#35AC6A';
const GRI_ACIK = '#B8C3CA';

// ---------------------------------------------------------------------------
// SVG ikon tasarımı
// ---------------------------------------------------------------------------
function svgOlustur() {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${BOYUT}" height="${BOYUT}" viewBox="0 0 1024 1024">
  <defs>
    <linearGradient id="zemin" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="${MAVI_KOYU}"/>
      <stop offset="55%" stop-color="${MAVI}"/>
      <stop offset="100%" stop-color="${MAVI_ORTA}"/>
    </linearGradient>
    <linearGradient id="cuzdan" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#FFFFFF"/>
      <stop offset="100%" stop-color="#E3EDFA"/>
    </linearGradient>
    <linearGradient id="yesilOk" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#4FD08A"/>
      <stop offset="100%" stop-color="${YESIL}"/>
    </linearGradient>
    <filter id="golge" x="-30%" y="-30%" width="160%" height="160%">
      <feDropShadow dx="0" dy="18" stdDeviation="22" flood-color="#04173A" flood-opacity="0.45"/>
    </filter>
  </defs>

  <!-- Arka plan -->
  <rect width="1024" height="1024" fill="url(#zemin)"/>

  <!-- Hafif doku: köşe parlaması -->
  <circle cx="880" cy="150" r="300" fill="#FFFFFF" opacity="0.06"/>
  <circle cx="140" cy="900" r="260" fill="#FFFFFF" opacity="0.05"/>

  <!-- Cüzdan gövdesi -->
  <g filter="url(#golge)">
    <rect x="196" y="300" width="632" height="424" rx="72" fill="url(#cuzdan)"/>
    <!-- Cüzdan kapağı (üst şerit) -->
    <path d="M196 372 a72 72 0 0 1 72 -72 h488 a72 72 0 0 1 72 72 v40 H196 z" fill="${MAVI_ORTA}" opacity="0.22"/>
    <!-- Kilit / toka -->
    <rect x="640" y="452" width="188" height="120" rx="60" fill="${MAVI}"/>
    <circle cx="734" cy="512" r="26" fill="#FFFFFF"/>
  </g>

  <!-- Gelir oku (yeşil, yukarı-sağ) -->
  <g transform="translate(300 250)">
    <path d="M0 150 L150 0" stroke="url(#yesilOk)" stroke-width="46" stroke-linecap="round"/>
    <path d="M150 0 L150 96 M150 0 L54 0" stroke="url(#yesilOk)" stroke-width="46" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
  </g>

  <!-- Gider oku (gri, aşağı-sol) -->
  <g transform="translate(560 560)">
    <path d="M0 0 L150 150" stroke="${GRI_ACIK}" stroke-width="46" stroke-linecap="round"/>
    <path d="M150 150 L150 54 M150 150 L54 150" stroke="${GRI_ACIK}" stroke-width="46" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
  </g>
</svg>`;
}

// ---------------------------------------------------------------------------
// Yazı tipi yükleme (Windows sistem fontları)
// ---------------------------------------------------------------------------
function yaziTipiBul() {
  const adaylar = [
    'C:\\Windows\\Fonts\\segoeuib.ttf',
    'C:\\Windows\\Fonts\\arialbd.ttf',
    'C:\\Windows\\Fonts\\segoeui.ttf',
    'C:\\Windows\\Fonts\\arial.ttf',
  ];
  for (const aday of adaylar) {
    if (fs.existsSync(aday)) return aday;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Ana üretim
// ---------------------------------------------------------------------------
async function main() {
  fs.mkdirSync(CIKTI_KLASORU, { recursive: true });

  const svg = svgOlustur();
  const svgYolu = path.join(CIKTI_KLASORU, 'ikon.svg');
  fs.writeFileSync(svgYolu, svg, 'utf8');

  // Ana ikon (1024x1024)
  const anaPng = path.join(CIKTI_KLASORU, 'ikon_1024.png');
  await sharp(Buffer.from(svg)).png().toFile(anaPng);
  console.log('Ana ikon:', anaPng);

  // --- Android mipmap boyutları ---
  const androidBoyutlari = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  const androidKok = path.join(__dirname, 'android', 'app', 'src', 'main', 'res');
  for (const [klasor, boyut] of Object.entries(androidBoyutlari)) {
    const hedefKlasor = path.join(androidKok, klasor);
    fs.mkdirSync(hedefKlasor, { recursive: true });
    const hedef = path.join(hedefKlasor, 'ic_launcher.png');
    await sharp(Buffer.from(svg)).resize(boyut, boyut).png().toFile(hedef);
    console.log(`  ${klasor}/ic_launcher.png (${boyut}x${boyut})`);
  }

  // --- iOS AppIcon boyutları ---
  const iosBoyutlari = [20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024];
  const iosKok = path.join(
    __dirname, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset'
  );
  if (fs.existsSync(iosKok)) {
    for (const boyut of iosBoyutlari) {
      const hedef = path.join(iosKok, `Icon-App-${boyut}x${boyut}@1x.png`);
      await sharp(Buffer.from(svg)).resize(boyut, boyut).png().toFile(hedef);
    }
    console.log(`  iOS AppIcon: ${iosBoyutlari.length} boyut güncellendi`);
  }

  // --- Windows ikonu ---
  const windowsIkon = path.join(__dirname, 'windows', 'runner', 'resources', 'app_icon.ico');
  if (fs.existsSync(path.dirname(windowsIkon))) {
    const pngBuffer = await sharp(Buffer.from(svg)).resize(256, 256).png().toBuffer();
    fs.writeFileSync(path.join(CIKTI_KLASORU, 'windows_256.png'), pngBuffer);
    console.log('  Windows için 256x256 PNG hazır (ICO dönüşümü ayrı adım)');
  }

  // --- Google Play mağaza ikonu (512x512) ---
  const playIkon = path.join(CIKTI_KLASORU, 'play_store_512.png');
  await sharp(Buffer.from(svg)).resize(512, 512).png().toFile(playIkon);
  console.log('Google Play ikonu:', playIkon);

  // --- Google Play öne çıkan görsel (1024x500) ---
  const yaziTipi = yaziTipiBul();
  const bannerSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="500" viewBox="0 0 1024 500">
  <defs>
    <linearGradient id="bz" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="${MAVI_KOYU}"/>
      <stop offset="60%" stop-color="${MAVI}"/>
      <stop offset="100%" stop-color="${MAVI_ORTA}"/>
    </linearGradient>
  </defs>
  <rect width="1024" height="500" fill="url(#bz)"/>
  <circle cx="900" cy="80" r="220" fill="#FFFFFF" opacity="0.06"/>
  <circle cx="120" cy="440" r="180" fill="#FFFFFF" opacity="0.05"/>
  <text x="512" y="250" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif"
        font-size="86" font-weight="700" fill="#FFFFFF">Harcama Takip</text>
  <text x="512" y="330" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif"
        font-size="38" font-weight="400" fill="#CFE0F7">Gelir ve giderlerinizi kolayca takip edin</text>
</svg>`;
  const bannerYolu = path.join(CIKTI_KLASORU, 'play_feature_1024x500.png');
  await sharp(Buffer.from(bannerSvg)).png().toFile(bannerYolu);
  console.log('Google Play öne çıkan görsel:', bannerYolu);

  console.log('\nTamamlandı.');
}

main().catch((hata) => {
  console.error('Hata:', hata);
  process.exit(1);
});
