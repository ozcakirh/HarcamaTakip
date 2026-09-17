import 'package:flutter/material.dart';

import '../bilesenler/hareket_karti.dart';
import '../modeller/hareket.dart';
import '../modeller/hareket_turu.dart';
import '../tema/ekran_paleti.dart';
import '../tema/uygulama_temasi.dart';
import '../veritabani/veritabani_yardimcisi.dart';
import '../yardimci/bicim.dart';
import '../yardimci/veri_yenile.dart';
import 'hareket_form_ekrani.dart';

/// Ana ekran — mavi tonlarda dashboard.
///
/// Elde kalan rakamları ve son 5 hareketi gösterir.
class AnaEkran extends StatefulWidget {
  const AnaEkran({
    super.key,
    this.onSekmeSec,
    this.sonHareketAdedi = 5,
  });

  /// Gelir / gider sekmelerine geçiş için kabuktan gelen geri çağırma.
  final ValueChanged<int>? onSekmeSec;

  final int sonHareketAdedi;

  @override
  State<AnaEkran> createState() => _AnaEkranDurumu();
}

class _AnaEkranDurumu extends State<AnaEkran> {
  static const EkranPaleti _palet = EkranPaleti.mavi;

  double _toplamGelir = 0;
  double _toplamGider = 0;
  List<Hareket> _sonHareketler = <Hareket>[];
  int _gelirAdet = 0;
  int _giderAdet = 0;
  bool _yukleniyor = true;

  double get _kalan => _toplamGelir - _toplamGider;

  @override
  void initState() {
    super.initState();
    VeriYenile.surum.addListener(_yukle);
    _yukle();
  }

  @override
  void dispose() {
    VeriYenile.surum.removeListener(_yukle);
    super.dispose();
  }

  Future<void> _yukle() async {
    final VeritabaniYardimcisi vt = VeritabaniYardimcisi.ornek;

    final double gelir = await vt.toplam(HareketTuru.gelir);
    final double gider = await vt.toplam(HareketTuru.gider);
    final List<Hareket> son = await vt.sonHareketler(widget.sonHareketAdedi);
    final List<Hareket> tumGelirler = await vt.hareketleriGetir(
      HareketTuru.gelir,
    );
    final List<Hareket> tumGiderler = await vt.hareketleriGetir(
      HareketTuru.gider,
    );

    if (!mounted) return;
    setState(() {
      _toplamGelir = gelir;
      _toplamGider = gider;
      _sonHareketler = son;
      _gelirAdet = tumGelirler.length;
      _giderAdet = tumGiderler.length;
      _yukleniyor = false;
    });
  }

  Future<void> _yeniKayit(HareketTuru tur) async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => HareketFormEkrani(tur: tur),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _palet.zemin,
      appBar: AppBar(
        backgroundColor: _palet.koyu,
        foregroundColor: Colors.white,
        title: const Text('Harcama Takip'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Yenile',
            onPressed: _yukle,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              UygulamaRenkleri.maviZemin,
              Color(0xFFDCE9F9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _yukleniyor
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _yukle,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: <Widget>[
                    _bakiyeKarti(),
                    const SizedBox(height: 14),
                    _ozetSatiri(),
                    const SizedBox(height: 18),
                    _hizliIslemler(),
                    const SizedBox(height: 22),
                    _sonHareketBasligi(),
                    const SizedBox(height: 10),
                    _sonHareketListesi(),
                  ],
                ),
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Kalan bakiye
  // ---------------------------------------------------------------------------

  Widget _bakiyeKarti() {
    final bool negatif = _kalan < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _palet.gecis,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: UygulamaRenkleri.maviKoyu.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Elde Kalan Bakiye',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              paraYaz(_kalan),
              style: TextStyle(
                color: negatif ? const Color(0xFFFFCDD2) : Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            negatif
                ? 'Giderler gelirleri aşmış durumda'
                : 'Gelir - Gider farkı',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _bakiyeAltBilgi(
                  etiket: 'Gelir',
                  deger: _toplamGelir,
                  adet: _gelirAdet,
                  ikon: Icons.south_west_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 44,
                color: Colors.white.withValues(alpha: 0.25),
              ),
              Expanded(
                child: _bakiyeAltBilgi(
                  etiket: 'Gider',
                  deger: _toplamGider,
                  adet: _giderAdet,
                  ikon: Icons.north_east_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bakiyeAltBilgi({
    required String etiket,
    required double deger,
    required int adet,
    required IconData ikon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(ikon, color: Colors.white.withValues(alpha: 0.9), size: 16),
              const SizedBox(width: 6),
              Text(
                etiket,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              paraYaz(deger),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$adet kayıt',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Özet kutuları
  // ---------------------------------------------------------------------------

  Widget _ozetSatiri() {
    return Row(
      children: <Widget>[
        Expanded(
          child: _ozetKutusu(
            baslik: 'Toplam Gelir',
            deger: _toplamGelir,
            ikon: Icons.trending_up,
            renk: UygulamaRenkleri.yesil,
            zemin: UygulamaRenkleri.yesilZemin,
            dokunma: () => widget.onSekmeSec?.call(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ozetKutusu(
            baslik: 'Toplam Gider',
            deger: _toplamGider,
            ikon: Icons.trending_down,
            renk: UygulamaRenkleri.griKoyu,
            zemin: UygulamaRenkleri.griZemin,
            dokunma: () => widget.onSekmeSec?.call(2),
          ),
        ),
      ],
    );
  }

  Widget _ozetKutusu({
    required String baslik,
    required double deger,
    required IconData ikon,
    required Color renk,
    required Color zemin,
    required VoidCallback dokunma,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: dokunma,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: renk.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: zemin,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(ikon, color: renk, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                baslik,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: UygulamaRenkleri.gri,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  paraYaz(deger),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: renk,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hızlı işlemler
  // ---------------------------------------------------------------------------

  Widget _hizliIslemler() {
    return Row(
      children: <Widget>[
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: UygulamaRenkleri.yesil,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => _yeniKayit(HareketTuru.gelir),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Gelir Ekle'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: UygulamaRenkleri.griKoyu,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => _yeniKayit(HareketTuru.gider),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Gider Ekle'),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Son hareketler
  // ---------------------------------------------------------------------------

  Widget _sonHareketBasligi() {
    return Row(
      children: <Widget>[
        const Icon(Icons.history, color: UygulamaRenkleri.mavi, size: 22),
        const SizedBox(width: 8),
        Text(
          'Son ${widget.sonHareketAdedi} Hareket',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: UygulamaRenkleri.maviKoyu,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => widget.onSekmeSec?.call(1),
          child: const Text('Gelirler'),
        ),
        TextButton(
          onPressed: () => widget.onSekmeSec?.call(2),
          child: const Text('Giderler'),
        ),
      ],
    );
  }

  Widget _sonHareketListesi() {
    if (_sonHareketler.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: UygulamaRenkleri.maviAcik.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: <Widget>[
            Icon(
              Icons.receipt_long_outlined,
              size: 52,
              color: UygulamaRenkleri.maviOrta.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            const Text(
              'Henüz hareket kaydı yok',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: UygulamaRenkleri.maviKoyu,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Gelir veya gider ekleyerek başlayın.',
              style: TextStyle(fontSize: 12.5, color: UygulamaRenkleri.gri),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: _sonHareketler.map((Hareket hareket) {
        final bool gelirMi = hareket.tur == HareketTuru.gelir;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: HareketKarti(
            hareket: hareket,
            vurguRengi:
                gelirMi ? UygulamaRenkleri.yesil : UygulamaRenkleri.griKoyu,
            dokunma: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<bool>(
                  builder: (_) => HareketFormEkrani(
                    tur: hareket.tur,
                    hareket: hareket,
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}
