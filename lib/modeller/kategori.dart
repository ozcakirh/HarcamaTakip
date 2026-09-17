import 'hareket_turu.dart';

/// Gelir ve gider kategorilerini temsil eder.
class Kategori {
  const Kategori({
    this.id,
    required this.ad,
    required this.tur,
    this.aktif = true,
  });

  final int? id;
  final String ad;
  final HareketTuru tur;
  final bool aktif;

  Kategori kopyala({
    int? id,
    String? ad,
    HareketTuru? tur,
    bool? aktif,
  }) {
    return Kategori(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      tur: tur ?? this.tur,
      aktif: aktif ?? this.aktif,
    );
  }

  Map<String, Object?> haritaya() {
    return <String, Object?>{
      'id': id,
      'ad': ad,
      'tur': tur.kod,
      'aktif': aktif ? 1 : 0,
    };
  }

  factory Kategori.haritadan(Map<String, Object?> harita) {
    return Kategori(
      id: harita['id'] as int?,
      ad: (harita['ad'] as String?) ?? '',
      tur: HareketTuru.koddan(harita['tur'] as String?),
      aktif: ((harita['aktif'] as int?) ?? 1) == 1,
    );
  }
}
