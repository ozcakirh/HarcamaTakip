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
import 'kategori_liste_ekrani.dart';

/// Gelir ve gider ekranlarının ortak liste altyapısı.
///
/// Renk paleti [tur] değerine göre belirlenir:
/// gelir için yeşil, gider için gri tonlar.
class HareketListeEkrani extends StatefulWidget {
  const HareketListeEkrani({super.key, required this.tur});

  final HareketTuru tur;

  @override
  State<HareketListeEkrani> createState() => HareketListeEkraniDurumu();
}

class HareketListeEkraniDurumu extends State<HareketListeEkrani> {
  final TextEditingController _aramaKontrolcusu = TextEditingController();

  List<Hareket> _hareketler = <Hareket>[];
  double _toplam = 0;
  bool _yukleniyor = true;

  EkranPaleti get palet => EkranPaleti.turIcin(widget.tur);
  bool get gelirMi => widget.tur == HareketTuru.gelir;

  @override
  void initState() {
    super.initState();
    VeriYenile.surum.addListener(_yukle);
    _yukle();
  }

  @override
  void dispose() {
    VeriYenile.surum.removeListener(_yukle);
    _aramaKontrolcusu.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    final VeritabaniYardimcisi vt = VeritabaniYardimcisi.ornek;
    final List<Hareket> hareketler = await vt.hareketleriGetir(
      widget.tur,
      arama: _aramaKontrolcusu.text,
    );
    final double toplam = await vt.toplam(widget.tur);

    if (!mounted) return;
    setState(() {
      _hareketler = hareketler;
      _toplam = toplam;
      _yukleniyor = false;
    });
  }

  Future<void> _yeniEkle() async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => HareketFormEkrani(tur: widget.tur),
      ),
    );
  }

  Future<void> _duzenle(Hareket hareket) async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => HareketFormEkrani(tur: widget.tur, hareket: hareket),
      ),
    );
  }

  Future<bool> _silmeyiOnayla(Hareket hareket) async {
    final bool onay =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext baglam) => AlertDialog(
            title: Text('${widget.tur.etiket} kaydını sil'),
            content: Text(
              '${hareket.kategoriAd ?? 'Kategorisiz'} - '
              '${paraYaz(hareket.tutar)}\n'
              '${tarihYaz(hareket.tarih)}\n\n'
              'Bu kaydı silmek istediğinize emin misiniz?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(baglam).pop(false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: UygulamaRenkleri.giderVurgu,
                ),
                onPressed: () => Navigator.of(baglam).pop(true),
                child: const Text('Sil'),
              ),
            ],
          ),
        ) ??
        false;

    if (!onay) return false;

    await VeritabaniYardimcisi.ornek.hareketSil(hareket.id!);
    VeriYenile.bildir();
    if (!mounted) return false;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Kayıt silindi.'),
          backgroundColor: palet.koyu,
        ),
      );
    return true;
  }

  Future<void> _kategorilereGit() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KategoriListeEkrani(tur: widget.tur),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: palet.zemin,
      appBar: AppBar(
        backgroundColor: palet.koyu,
        foregroundColor: Colors.white,
        title: Text('${widget.tur.etiket}ler'),
        actions: <Widget>[
          IconButton(
            tooltip: '${widget.tur.etiket} Kategori Tanımlama',
            onPressed: _kategorilereGit,
            icon: const Icon(Icons.category_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _yeniEkle,
        backgroundColor: palet.ana,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('${widget.tur.etiket} Ekle'),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                _ozetKarti(),
                _aramaAlani(),
                Expanded(
                  child: _hareketler.isEmpty
                      ? _bosGorunum()
                      : RefreshIndicator(
                          onRefresh: _yukle,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                            itemCount: _hareketler.length,
                            separatorBuilder:
                                (BuildContext baglam, int sira) =>
                                    const SizedBox(height: 10),
                            itemBuilder: (BuildContext baglam, int sira) {
                              final Hareket hareket = _hareketler[sira];
                              return Dismissible(
                                key: ValueKey<int>(hareket.id ?? sira),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) => _silmeyiOnayla(hareket),
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: UygulamaRenkleri.giderVurgu,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                  ),
                                ),
                                child: HareketKarti(
                                  hareket: hareket,
                                  vurguRengi: palet.ana,
                                  dokunma: () => _duzenle(hareket),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _ozetKarti() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palet.gecis,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                gelirMi ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Toplam ${widget.tur.etiket}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            paraYaz(_toplam),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Listelenen kayıt: ${_hareketler.length}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aramaAlani() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _aramaKontrolcusu,
        textInputAction: TextInputAction.search,
        onChanged: (_) => _yukle(),
        decoration: InputDecoration(
          hintText: 'Belge no, açıklama veya kategori ara',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _aramaKontrolcusu.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Temizle',
                  onPressed: () {
                    _aramaKontrolcusu.clear();
                    _yukle();
                  },
                  icon: const Icon(Icons.close),
                ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _bosGorunum() {
    final bool aramaVar = _aramaKontrolcusu.text.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              aramaVar ? Icons.search_off : Icons.receipt_long_outlined,
              size: 64,
              color: palet.orta.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              aramaVar
                  ? 'Arama sonucu bulunamadı'
                  : 'Henüz ${widget.tur.etiket.toLowerCase()} kaydı yok',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: palet.koyuYazi,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              aramaVar
                  ? 'Farklı bir kelime ile aramayı deneyin.'
                  : 'Sağ alttaki butondan ilk kaydınızı ekleyin.',
              style: TextStyle(fontSize: 13, color: palet.ana),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
