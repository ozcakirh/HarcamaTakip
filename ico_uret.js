// Windows .ico dosyası üretici
// PNG'leri ICO konteynerine paketler (16, 24, 32, 48, 64, 128, 256).
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const BOYUTLAR = [16, 24, 32, 48, 64, 128, 256];
const KAYNAK = path.join(__dirname, 'ikon_uretim', 'ikon.svg');
const HEDEF = path.join(__dirname, 'windows', 'runner', 'resources', 'app_icon.ico');

/**
 * PNG görüntülerini tek bir ICO dosyasında birleştirir.
 * ICO formatı: ICONDIR + ICONDIRENTRY[] + PNG verileri
 */
function icoOlustur(pngler) {
  const ICONDIR_BOYUT = 6;
  const ENTRY_BOYUT = 16;
  const baslikBoyut = ICONDIR_BOYUT + ENTRY_BOYUT * pngler.length;

  const baslik = Buffer.alloc(ICONDIR_BOYUT);
  baslik.writeUInt16LE(0, 0); // reserved
  baslik.writeUInt16LE(1, 2); // type: 1 = icon
  baslik.writeUInt16LE(pngler.length, 4); // image count

  const girdiler = [];
  let veriOfseti = baslikBoyut;

  for (const { boyut, veri } of pngler) {
    const girdi = Buffer.alloc(ENTRY_BOYUT);
    // 256 -> 0 olarak yazılır (ICO spesifikasyonu)
    girdi.writeUInt8(boyut >= 256 ? 0 : boyut, 0); // width
    girdi.writeUInt8(boyut >= 256 ? 0 : boyut, 1); // height
    girdi.writeUInt8(0, 2); // renk paleti yok
    girdi.writeUInt8(0, 3); // reserved
    girdi.writeUInt16LE(1, 4); // color planes
    girdi.writeUInt16LE(32, 6); // bits per pixel
    girdi.writeUInt32LE(veri.length, 8); // veri boyutu
    girdi.writeUInt32LE(veriOfseti, 12); // veri ofseti
    girdiler.push(girdi);
    veriOfseti += veri.length;
  }

  return Buffer.concat([baslik, ...girdiler, ...pngler.map((p) => p.veri)]);
}

async function main() {
  const svg = fs.readFileSync(KAYNAK);

  const pngler = [];
  for (const boyut of BOYUTLAR) {
    const veri = await sharp(svg).resize(boyut, boyut).png().toBuffer();
    pngler.push({ boyut, veri });
    console.log(`  ${boyut}x${boyut} PNG hazır (${veri.length} bayt)`);
  }

  const ico = icoOlustur(pngler);
  fs.mkdirSync(path.dirname(HEDEF), { recursive: true });
  fs.writeFileSync(HEDEF, ico);
  console.log(`\nICO yazıldı: ${HEDEF} (${ico.length} bayt)`);
}

main().catch((hata) => {
  console.error('Hata:', hata);
  process.exit(1);
});
