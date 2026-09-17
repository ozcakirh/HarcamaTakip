import 'package:flutter/material.dart';

import '../modeller/hareket_turu.dart';
import '../tema/uygulama_temasi.dart';

/// Ekranların renk paletini tek yerden yönetir.
class EkranPaleti {
  const EkranPaleti({
    required this.koyu,
    required this.ana,
    required this.orta,
    required this.zemin,
    required this.kart,
    required this.gecis,
    required this.koyuYazi,
  });

  final Color koyu;
  final Color ana;
  final Color orta;
  final Color zemin;
  final Color kart;
  final List<Color> gecis;

  /// Zemin üzerindeki koyu yazı rengi.
  final Color koyuYazi;

  static const EkranPaleti mavi = EkranPaleti(
    koyu: UygulamaRenkleri.maviKoyu,
    ana: UygulamaRenkleri.mavi,
    orta: UygulamaRenkleri.maviOrta,
    zemin: UygulamaRenkleri.maviZemin,
    kart: UygulamaRenkleri.maviKart,
    gecis: UygulamaRenkleri.maviGecis,
    koyuYazi: UygulamaRenkleri.maviKoyu,
  );

  static const EkranPaleti yesil = EkranPaleti(
    koyu: UygulamaRenkleri.yesilKoyu,
    ana: UygulamaRenkleri.yesil,
    orta: UygulamaRenkleri.yesilOrta,
    zemin: UygulamaRenkleri.yesilZemin,
    kart: UygulamaRenkleri.yesilKart,
    gecis: UygulamaRenkleri.yesilGecis,
    koyuYazi: UygulamaRenkleri.yesilKoyu,
  );

  static const EkranPaleti gri = EkranPaleti(
    koyu: UygulamaRenkleri.griKoyu,
    ana: UygulamaRenkleri.gri,
    orta: UygulamaRenkleri.griOrta,
    zemin: UygulamaRenkleri.griZemin,
    kart: UygulamaRenkleri.griKart,
    gecis: UygulamaRenkleri.griGecis,
    koyuYazi: UygulamaRenkleri.griKoyu,
  );

  /// Türüne göre ilgili paleti döndürür.
  static EkranPaleti turIcin(HareketTuru tur) {
    return tur == HareketTuru.gelir ? yesil : gri;
  }
}
