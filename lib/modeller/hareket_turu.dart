/// Gelir / Gider ayrımını tutan temel tür.
enum HareketTuru {
  gelir('gelir', 'Gelir'),
  gider('gider', 'Gider');

  const HareketTuru(this.kod, this.etiket);

  /// Veritabanında saklanan kısa kod.
  final String kod;

  /// Ekranda gösterilen okunabilir ad.
  final String etiket;

  /// Veritabanından gelen kodu türe çevirir.
  static HareketTuru koddan(String? kod) {
    return HareketTuru.values.firstWhere(
      (tur) => tur.kod == kod,
      orElse: () => HareketTuru.gider,
    );
  }
}
