import 'package:flutter/material.dart';

import '../tema/ekran_paleti.dart';
import 'ana_ekran.dart';
import 'gelir_ekrani.dart';
import 'gider_ekrani.dart';
import 'kategori_ekrani.dart';

/// Uygulamanın alt menü kabuğu.
///
/// Sekmeler: Ana Ekran (mavi), Gelir (yeşil), Gider (gri), Kategoriler (mavi).
class AnaCerceve extends StatefulWidget {
  const AnaCerceve({super.key});

  @override
  State<AnaCerceve> createState() => _AnaCerceveDurumu();
}

class _AnaCerceveDurumu extends State<AnaCerceve> {
  int _seciliSekme = 0;

  static const List<EkranPaleti> _sekmePaletleri = <EkranPaleti>[
    EkranPaleti.mavi,
    EkranPaleti.yesil,
    EkranPaleti.gri,
    EkranPaleti.mavi,
  ];

  void _sekmeSec(int index) {
    if (index == _seciliSekme) return;
    setState(() => _seciliSekme = index);
  }

  @override
  Widget build(BuildContext context) {
    final EkranPaleti palet = _sekmePaletleri[_seciliSekme];

    return Scaffold(
      body: IndexedStack(
        index: _seciliSekme,
        children: <Widget>[
          AnaEkran(onSekmeSec: _sekmeSec),
          const GelirEkrani(),
          const GiderEkrani(),
          const KategoriEkrani(),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: palet.koyu,
          indicatorColor: palet.orta,
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
            (Set<WidgetState> durumlar) => TextStyle(
              fontSize: 11.5,
              fontWeight: durumlar.contains(WidgetState.selected)
                  ? FontWeight.bold
                  : FontWeight.w500,
              color: Colors.white,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
            (Set<WidgetState> durumlar) => IconThemeData(
              color: Colors.white.withValues(
                alpha: durumlar.contains(WidgetState.selected) ? 1.0 : 0.8,
              ),
              size: 24,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _seciliSekme,
          onDestinationSelected: _sekmeSec,
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Ana Ekran',
            ),
            NavigationDestination(
              icon: Icon(Icons.south_west_rounded),
              selectedIcon: Icon(Icons.south_west_rounded),
              label: 'Gelirler',
            ),
            NavigationDestination(
              icon: Icon(Icons.north_east_rounded),
              selectedIcon: Icon(Icons.north_east_rounded),
              label: 'Giderler',
            ),
            NavigationDestination(
              icon: Icon(Icons.category_outlined),
              selectedIcon: Icon(Icons.category),
              label: 'Kategoriler',
            ),
          ],
        ),
      ),
    );
  }
}
