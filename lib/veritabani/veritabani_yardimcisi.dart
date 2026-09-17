import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../modeller/hareket.dart';
import '../modeller/hareket_turu.dart';
import '../modeller/kategori.dart';

/// SQLite veritabanı erişim katmanı.
///
/// Tüm okuma/yazma işlemleri bu sınıf üzerinden yapılır.
class VeritabaniYardimcisi {
  VeritabaniYardimcisi._();

  static final VeritabaniYardimcisi ornek = VeritabaniYardimcisi._();

  static const String kategoriTablosu = 'kategori';
  static const String hareketTablosu = 'hareket';

  static Database? _veritabani;

  Future<Database> get veritabani async {
    return _veritabani ??= await _ac();
  }

  Future<Database> _ac() async {
    final String klasor = await getDatabasesPath();
    final String dosyaYolu = p.join(klasor, 'harcama_takip.db');

    return openDatabase(
      dosyaYolu,
      version: 1,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database db, int surum) async {
        await db.execute('''
          CREATE TABLE $kategoriTablosu (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ad TEXT NOT NULL,
            tur TEXT NOT NULL,
            aktif INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE $hareketTablosu (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tur TEXT NOT NULL,
            tarih TEXT NOT NULL,
            belge_no TEXT,
            kategori_id INTEGER,
            tutar REAL NOT NULL DEFAULT 0,
            aciklama TEXT,
            FOREIGN KEY (kategori_id) REFERENCES $kategoriTablosu (id) ON DELETE SET NULL
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_hareket_tur_tarih ON $hareketTablosu (tur, tarih DESC)',
        );

        await _varsayilanKategorileriEkle(db);
      },
    );
  }

  /// Uygulama ilk açıldığında hazır gelen örnek kategoriler.
  Future<void> _varsayilanKategorileriEkle(Database db) async {
    const List<String> gelirler = <String>[
      'Maaş',
      'Ek İş / Serbest Çalışma',
      'Kira Geliri',
      'Faiz / Yatırım Geliri',
      'Diğer Gelir',
    ];
    const List<String> giderler = <String>[
      'Market',
      'Kira',
      'Faturalar',
      'Ulaşım',
      'Yemek',
      'Sağlık',
      'Eğitim',
      'Giyim',
      'Diğer Gider',
    ];

    final Batch batch = db.batch();
    for (final String ad in gelirler) {
      batch.insert(kategoriTablosu, <String, Object?>{
        'ad': ad,
        'tur': HareketTuru.gelir.kod,
        'aktif': 1,
      });
    }
    for (final String ad in giderler) {
      batch.insert(kategoriTablosu, <String, Object?>{
        'ad': ad,
        'tur': HareketTuru.gider.kod,
        'aktif': 1,
      });
    }
    await batch.commit(noResult: true);
  }

  // ---------------------------------------------------------------------------
  // Kategoriler
  // ---------------------------------------------------------------------------

  Future<int> kategoriEkle(Kategori kategori) async {
    final Database db = await veritabani;
    return db.insert(
      kategoriTablosu,
      kategori.haritaya()..remove('id'),
    );
  }

  Future<int> kategoriGuncelle(Kategori kategori) async {
    final Database db = await veritabani;
    return db.update(
      kategoriTablosu,
      kategori.haritaya(),
      where: 'id = ?',
      whereArgs: <Object?>[kategori.id],
    );
  }

  Future<int> kategoriSil(int id) async {
    final Database db = await veritabani;
    return db.delete(kategoriTablosu, where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<List<Kategori>> kategorileriGetir(
    HareketTuru tur, {
    bool sadeceAktif = false,
  }) async {
    final Database db = await veritabani;
    final List<Map<String, Object?>> kayitlar = await db.query(
      kategoriTablosu,
      where: sadeceAktif ? 'tur = ? AND aktif = 1' : 'tur = ?',
      whereArgs: <Object?>[tur.kod],
      orderBy: 'ad COLLATE NOCASE ASC',
    );
    return kayitlar.map(Kategori.haritadan).toList();
  }

  /// Kategoriye bağlı hareket sayısını döndürür.
  Future<int> kategoriHareketSayisi(int kategoriId) async {
    final Database db = await veritabani;
    final List<Map<String, Object?>> sonuc = await db.rawQuery(
      'SELECT COUNT(*) AS adet FROM $hareketTablosu WHERE kategori_id = ?',
      <Object?>[kategoriId],
    );
    return (sonuc.first['adet'] as int?) ?? 0;
  }

  /// Aynı türde aynı isimde kategori var mı?
  Future<bool> kategoriAdiVarMi(
    String ad,
    HareketTuru tur, {
    int? haricId,
  }) async {
    final Database db = await veritabani;
    final List<Map<String, Object?>> sonuc = await db.rawQuery(
      'SELECT COUNT(*) AS adet FROM $kategoriTablosu '
      'WHERE tur = ? AND LOWER(ad) = LOWER(?) ${haricId != null ? 'AND id <> ?' : ''}',
      <Object?>[
        tur.kod,
        ad.trim(),
        ?haricId,
      ],
    );
    return ((sonuc.first['adet'] as int?) ?? 0) > 0;
  }

  // ---------------------------------------------------------------------------
  // Hareketler
  // ---------------------------------------------------------------------------

  Future<int> hareketEkle(Hareket hareket) async {
    final Database db = await veritabani;
    return db.insert(
      hareketTablosu,
      hareket.haritaya()..remove('id'),
    );
  }

  Future<int> hareketGuncelle(Hareket hareket) async {
    final Database db = await veritabani;
    return db.update(
      hareketTablosu,
      hareket.haritaya(),
      where: 'id = ?',
      whereArgs: <Object?>[hareket.id],
    );
  }

  Future<int> hareketSil(int id) async {
    final Database db = await veritabani;
    return db.delete(hareketTablosu, where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<Hareket?> hareketGetir(int id) async {
    final Database db = await veritabani;
    final List<Map<String, Object?>> kayitlar = await db.rawQuery('''
      SELECT h.*, k.ad AS kategori_ad
      FROM $hareketTablosu h
      LEFT JOIN $kategoriTablosu k ON k.id = h.kategori_id
      WHERE h.id = ?
    ''', <Object?>[id]);
    if (kayitlar.isEmpty) return null;
    return Hareket.haritadan(kayitlar.first);
  }

  /// Tür bazında (gelir/gider) hareketleri listeler.
  Future<List<Hareket>> hareketleriGetir(
    HareketTuru tur, {
    String? arama,
    DateTime? baslangic,
    DateTime? bitis,
  }) async {
    final Database db = await veritabani;

    final List<String> kosullar = <String>['h.tur = ?'];
    final List<Object?> parametreler = <Object?>[tur.kod];

    if (arama != null && arama.trim().isNotEmpty) {
      kosullar.add('(h.belge_no LIKE ? OR h.aciklama LIKE ? OR k.ad LIKE ?)');
      final String kalip = '%${arama.trim()}%';
      parametreler.addAll(<Object?>[kalip, kalip, kalip]);
    }
    if (baslangic != null) {
      kosullar.add('h.tarih >= ?');
      parametreler.add(Hareket.tarihiMetne(baslangic));
    }
    if (bitis != null) {
      kosullar.add('h.tarih <= ?');
      parametreler.add(Hareket.tarihiMetne(bitis));
    }

    final List<Map<String, Object?>> kayitlar = await db.rawQuery('''
      SELECT h.*, k.ad AS kategori_ad
      FROM $hareketTablosu h
      LEFT JOIN $kategoriTablosu k ON k.id = h.kategori_id
      WHERE ${kosullar.join(' AND ')}
      ORDER BY h.tarih DESC, h.id DESC
    ''', parametreler);

    return kayitlar.map(Hareket.haritadan).toList();
  }

  /// Ana ekrandaki "Son N Hareket" listesi için gelir + gider karışık döner.
  Future<List<Hareket>> sonHareketler(int adet) async {
    final Database db = await veritabani;
    final List<Map<String, Object?>> kayitlar = await db.rawQuery('''
      SELECT h.*, k.ad AS kategori_ad
      FROM $hareketTablosu h
      LEFT JOIN $kategoriTablosu k ON k.id = h.kategori_id
      ORDER BY h.tarih DESC, h.id DESC
      LIMIT ?
    ''', <Object?>[adet]);
    return kayitlar.map(Hareket.haritadan).toList();
  }

  /// Belirtilen türdeki toplam tutarı döndürür.
  Future<double> toplam(HareketTuru tur) async {
    final Database db = await veritabani;
    final List<Map<String, Object?>> sonuc = await db.rawQuery(
      'SELECT COALESCE(SUM(tutar), 0) AS toplam FROM $hareketTablosu WHERE tur = ?',
      <Object?>[tur.kod],
    );
    return ((sonuc.first['toplam'] as num?) ?? 0).toDouble();
  }

  /// Kategori bazında toplamları döndürür (özet kartları için).
  Future<List<Map<String, Object?>>> kategoriToplamlari(HareketTuru tur) async {
    final Database db = await veritabani;
    return db.rawQuery('''
      SELECT k.id AS kategori_id,
             COALESCE(k.ad, 'Kategorisiz') AS kategori_ad,
             COALESCE(SUM(h.tutar), 0) AS toplam,
             COUNT(h.id) AS adet
      FROM $hareketTablosu h
      LEFT JOIN $kategoriTablosu k ON k.id = h.kategori_id
      WHERE h.tur = ?
      GROUP BY k.id, k.ad
      ORDER BY toplam DESC
    ''', <Object?>[tur.kod]);
  }
}
