import 'package:flutter/material.dart';

/// Uygulamanın renk paleti.
///
/// Ana ekran mavi, gelir ekranı yeşil, gider ekranı gri tonlarındadır.
class UygulamaRenkleri {
  UygulamaRenkleri._();

  // --- Ana ekran: mavi tonlar ---
  static const Color maviKoyu = Color(0xFF0B2E66);
  static const Color mavi = Color(0xFF14509E);
  static const Color maviOrta = Color(0xFF2C79D0);
  static const Color maviAcik = Color(0xFF6FA9E8);
  static const Color maviZemin = Color(0xFFEAF2FC);
  static const Color maviKart = Color(0xFF1B62B8);

  // --- Gelir ekranı: yeşil tonlar ---
  static const Color yesilKoyu = Color(0xFF0E5B31);
  static const Color yesil = Color(0xFF1E8A4C);
  static const Color yesilOrta = Color(0xFF35AC6A);
  static const Color yesilAcik = Color(0xFF8FD9AC);
  static const Color yesilZemin = Color(0xFFE7F6EC);
  static const Color yesilKart = Color(0xFF25955A);

  // --- Gider ekranı: gri tonlar ---
  static const Color griKoyu = Color(0xFF37474F);
  static const Color gri = Color(0xFF5C6B73);
  static const Color griOrta = Color(0xFF8494A0);
  static const Color griAcik = Color(0xFFB8C3CA);
  static const Color griZemin = Color(0xFFECEFF1);
  static const Color griKart = Color(0xFF546E7A);

  // --- Durum renkleri ---
  static const Color giderVurgu = Color(0xFFC0392B);
  static const Color gelirVurgu = Color(0xFF1E8A4C);

  static const List<Color> maviGecis = <Color>[maviKoyu, mavi, maviOrta];
  static const List<Color> yesilGecis = <Color>[yesilKoyu, yesil, yesilOrta];
  static const List<Color> griGecis = <Color>[griKoyu, gri, griOrta];
}

class UygulamaTemasi {
  UygulamaTemasi._();

  static ThemeData olustur() {
    final ColorScheme renkSemasi = ColorScheme.fromSeed(
      seedColor: UygulamaRenkleri.mavi,
      primary: UygulamaRenkleri.mavi,
      secondary: UygulamaRenkleri.maviOrta,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: renkSemasi,
      scaffoldBackgroundColor: UygulamaRenkleri.maviZemin,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: UygulamaRenkleri.mavi,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: UygulamaRenkleri.griAcik),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: UygulamaRenkleri.griAcik),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: UygulamaRenkleri.mavi, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
