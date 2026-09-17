import 'package:flutter/material.dart';

import '../bilesenler/kategori_govdesi.dart';
import '../modeller/hareket_turu.dart';
import '../tema/ekran_paleti.dart';

/// Tek bir tür için (gelir ya da gider) kategori tanımlama ekranı.
///
/// Gelir / gider ekranlarından doğrudan açılır.
class KategoriListeEkrani extends StatelessWidget {
  const KategoriListeEkrani({super.key, required this.tur});

  final HareketTuru tur;

  @override
  Widget build(BuildContext context) {
    final EkranPaleti palet = EkranPaleti.turIcin(tur);

    return Scaffold(
      backgroundColor: palet.zemin,
      appBar: AppBar(
        backgroundColor: palet.koyu,
        foregroundColor: Colors.white,
        title: Text('${tur.etiket} Kategori Tanımlama'),
      ),
      body: KategoriGovdesi(tur: tur),
    );
  }
}
