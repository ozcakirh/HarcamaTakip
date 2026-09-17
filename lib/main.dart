import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'ekranlar/ana_cerceve.dart';
import 'tema/uygulama_temasi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Telefon dışındaki platformlarda (Windows / macOS / Linux) SQLite FFI ile açılır.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Türkçe tarih biçimlendirmesi için yerel verileri yükler.
  await initializeDateFormatting('tr_TR', null);

  runApp(const HarcamaTakipUygulamasi());
}

class HarcamaTakipUygulamasi extends StatelessWidget {
  const HarcamaTakipUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harcama Takip',
      debugShowCheckedModeBanner: false,
      theme: UygulamaTemasi.olustur(),
      locale: const Locale('tr', 'TR'),
      supportedLocales: const <Locale>[Locale('tr', 'TR')],
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AnaCerceve(),
    );
  }
}
