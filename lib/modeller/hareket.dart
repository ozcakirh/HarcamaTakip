import 'hareket_turu.dart';

/// Bir gelir veya gider kaydını temsil eder.
class Hareket {
  const Hareket({
    this.id,
    required this.tur,
    required this.tarih,
    this.belgeNo,
    this.kategoriId,
    required this.tutar,
    this.aciklama,
    this.kategoriAd,
  });

  final int? id;
  final HareketTuru tur;
  final DateTime tarih;
  final String? belgeNo;
  final int? kategoriId;
  final double tutar;
  final String? aciklama;

  /// Listeleme sorgularında JOIN ile gelen kategori adı.
  final String? kategoriAd;

  Hareket kopyala({
    int? id,
    HareketTuru? tur,
    DateTime? tarih,
    String? belgeNo,
    int? kategoriId,
    double? tutar,
    String? aciklama,
    String? kategoriAd,
  }) {
    return Hareket(
      id: id ?? this.id,
      tur: tur ?? this.tur,
      tarih: tarih ?? this.tarih,
      belgeNo: belgeNo ?? this.belgeNo,
      kategoriId: kategoriId ?? this.kategoriId,
      tutar: tutar ?? this.tutar,
      aciklama: aciklama ?? this.aciklama,
      kategoriAd: kategoriAd ?? this.kategoriAd,
    );
  }

  /// Tarih, veritabanında 'yyyy-MM-dd' metni olarak saklanır.
  static String tarihiMetne(DateTime tarih) {
    final ay = tarih.month.toString().padLeft(2, '0');
    final gun = tarih.day.toString().padLeft(2, '0');
    return '${tarih.year}-$ay-$gun';
  }

  static DateTime metniTarihe(String metin) => DateTime.parse(metin);

  Map<String, Object?> haritaya() {
    return <String, Object?>{
      'id': id,
      'tur': tur.kod,
      'tarih': tarihiMetne(tarih),
      'belge_no': belgeNo,
      'kategori_id': kategoriId,
      'tutar': tutar,
      'aciklama': aciklama,
    };
  }

  factory Hareket.haritadan(Map<String, Object?> harita) {
    return Hareket(
      id: harita['id'] as int?,
      tur: HareketTuru.koddan(harita['tur'] as String?),
      tarih: metniTarihe((harita['tarih'] as String?) ?? '2000-01-01'),
      belgeNo: harita['belge_no'] as String?,
      kategoriId: harita['kategori_id'] as int?,
      tutar: ((harita['tutar'] as num?) ?? 0).toDouble(),
      aciklama: harita['aciklama'] as String?,
      kategoriAd: harita['kategori_ad'] as String?,
    );
  }
}
