import 'package:flutter/material.dart';

import '../bilesenler/kategori_govdesi.dart';
import '../modeller/hareket_turu.dart';
import '../tema/ekran_paleti.dart';
import '../tema/uygulama_temasi.dart';

/// Kategori tanımlama ekranı.
///
/// İki sekmeden oluşur: Gelir Kategorileri ve Gider Kategorileri.
class KategoriEkrani extends StatelessWidget {
  const KategoriEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    const EkranPaleti palet = EkranPaleti.mavi;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: UygulamaRenkleri.maviZemin,
        appBar: AppBar(
          backgroundColor: palet.koyu,
          foregroundColor: Colors.white,
          title: const Text('Kategori Tanımlama'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: UygulamaRenkleri.maviAcik,
            tabs: <Widget>[
              Tab(
                icon: Icon(Icons.trending_up),
                text: 'Gelir Kategorileri',
              ),
              Tab(
                icon: Icon(Icons.trending_down),
                text: 'Gider Kategorileri',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            KategoriGovdesi(tur: HareketTuru.gelir),
            KategoriGovdesi(tur: HareketTuru.gider),
          ],
        ),
      ),
    );
  }
}
