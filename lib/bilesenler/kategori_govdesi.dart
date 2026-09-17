import 'package:flutter/material.dart';

import '../modeller/hareket_turu.dart';
import '../modeller/kategori.dart';
import '../tema/ekran_paleti.dart';
import '../tema/uygulama_temasi.dart';
import '../veritabani/veritabani_yardimcisi.dart';
import '../yardimci/bicim.dart';
import '../yardimci/veri_yenile.dart';

/// Kategori tanımlama ekranının gövdesi.
///
/// Hem tek başına açılan kategori ekranında hem de sekmeli
/// kategori yönetimi ekranında kullanılır.
class KategoriGovdesi extends StatefulWidget {
  const KategoriGovdesi({super.key, required this.tur});

  final HareketTuru tur;

  @override
  State<KategoriGovdesi> createState() => _KategoriGovdesiDurumu();
}

class _KategoriGovdesiDurumu extends State<KategoriGovdesi> {
  /// kategori_id -> hareket sayısı
  Map<int, int> _kullanim = <int, int>{};
  List<Kategori> _kategoriler = <Kategori>[];
  List<Map<String, Object?>> _ozet = <Map<String, Object?>>[];
  bool _yukleniyor = true;

  EkranPaleti get _palet => EkranPaleti.turIcin(widget.tur);
  bool get _gelirMi => widget.tur == HareketTuru.gelir;

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

    final List<Kategori> kategoriler =
        await vt.kategorileriGetir(widget.tur);
    final List<Map<String, Object?>> ozet = await vt.kategoriToplamlari(
      widget.tur,
    );

    final Map<int, int> kullanim = <int, int>{};
    final Map<int, double> tutarlar = <int, double>{};
    for (final Map<String, Object?> satir in ozet) {
      final int? id = satir['kategori_id'] as int?;
      if (id == null) continue;
      kullanim[id] = ((satir['adet'] as num?) ?? 0).toInt();
      tutarlar[id] = ((satir['toplam'] as num?) ?? 0).toDouble();
    }

    if (!mounted) return;
    setState(() {
      _kategoriler = kategoriler;
      _kullanim = kullanim;
      _tutarlar = tutarlar;
      _ozet = ozet;
      _yukleniyor = false;
    });
  }

  Map<int, double> _tutarlar = <int, double>{};

  // ---------------------------------------------------------------------------
  // İşlemler
  // ---------------------------------------------------------------------------

  Future<void> _kategoriEkle() async {
    final String? ad = await _adDiyalogu(
      baslik: 'Yeni ${widget.tur.etiket} Kategorisi',
    );
    if (ad == null) return;

    final bool varMi = await VeritabaniYardimcisi.ornek.kategoriAdiVarMi(
      ad,
      widget.tur,
    );
    if (varMi) {
      _mesajGoster('"$ad" kategorisi zaten tanımlı.', hata: true);
      return;
    }

    await VeritabaniYardimcisi.ornek.kategoriEkle(
      Kategori(ad: ad, tur: widget.tur),
    );
    VeriYenile.bildir();
    _mesajGoster('"$ad" kategorisi eklendi.');
  }

  Future<void> _kategoriDuzenle(Kategori kategori) async {
    final String? ad = await _adDiyalogu(
      baslik: 'Kategoriyi Düzenle',
      baslangicDegeri: kategori.ad,
    );
    if (ad == null) return;

    final bool varMi = await VeritabaniYardimcisi.ornek.kategoriAdiVarMi(
      ad,
      widget.tur,
      haricId: kategori.id,
    );
    if (varMi) {
      _mesajGoster('"$ad" kategorisi zaten tanımlı.', hata: true);
      return;
    }

    await VeritabaniYardimcisi.ornek.kategoriGuncelle(
      kategori.kopyala(ad: ad),
    );
    VeriYenile.bildir();
    _mesajGoster('Kategori güncellendi.');
  }

  Future<void> _kategoriSil(Kategori kategori) async {
    final int adet = _kullanim[kategori.id] ?? 0;

    final bool onay =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext baglam) => AlertDialog(
            title: const Text('Kategoriyi sil'),
            content: Text(
              adet == 0
                  ? '"${kategori.ad}" kategorisi silinecek. Onaylıyor musunuz?'
                  : '"${kategori.ad}" kategorisine bağlı $adet hareket var. '
                        'Bu hareketler "Kategorisiz" olarak görünecek. '
                        'Silmek istediğinize emin misiniz?',
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

    if (!onay) return;

    await VeritabaniYardimcisi.ornek.kategoriSil(kategori.id!);
    VeriYenile.bildir();
    _mesajGoster('Kategori silindi.');
  }

  Future<void> _durumDegistir(Kategori kategori) async {
    await VeritabaniYardimcisi.ornek.kategoriGuncelle(
      kategori.kopyala(aktif: !kategori.aktif),
    );
    VeriYenile.bildir();
  }

  Future<String?> _adDiyalogu({
    required String baslik,
    String baslangicDegeri = '',
  }) {
    final TextEditingController kontrolcu = TextEditingController(
      text: baslangicDegeri,
    );
    final GlobalKey<FormState> formAnahtari = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (BuildContext baglam) => AlertDialog(
        title: Text(baslik),
        content: Form(
          key: formAnahtari,
          child: TextFormField(
            controller: kontrolcu,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Kategori Adı',
              hintText: 'Örn: Market',
            ),
            validator: (String? deger) {
              if (deger == null || deger.trim().isEmpty) {
                return 'Kategori adı boş olamaz';
              }
              if (deger.trim().length < 2) {
                return 'En az 2 karakter girin';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              if (formAnahtari.currentState?.validate() ?? false) {
                Navigator.of(baglam).pop(kontrolcu.text.trim());
              }
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(baglam).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _palet.ana),
            onPressed: () {
              if (formAnahtari.currentState?.validate() ?? false) {
                Navigator.of(baglam).pop(kontrolcu.text.trim());
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    ).whenComplete(kontrolcu.dispose);
  }

  void _mesajGoster(String mesaj, {bool hata = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mesaj),
          backgroundColor:
              hata ? UygulamaRenkleri.giderVurgu : _palet.koyu,
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // Görünüm
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: <Widget>[
        _ozetBasligi(),
        Expanded(
          child: _kategoriler.isEmpty
              ? _bosGorunum()
              : RefreshIndicator(
                  onRefresh: _yukle,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    itemCount: _kategoriler.length,
                    separatorBuilder: (BuildContext baglam, int sira) =>
                        const SizedBox(height: 10),
                    itemBuilder: (BuildContext baglam, int sira) =>
                        _kategoriKarti(_kategoriler[sira]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _ozetBasligi() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _palet.gecis,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            _gelirMi ? Icons.category_outlined : Icons.label_outline,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${widget.tur.etiket} Kategorileri',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_kategoriler.length} kategori tanımlı  •  '
                  '${_kategoriler.where((Kategori k) => k.aktif).length} aktif',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Toplam: ${paraYaz(_ozet.fold<double>(0, (double t, Map<String, Object?> s) => t + (((s['toplam'] as num?) ?? 0).toDouble())))}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _palet.koyu,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onPressed: _kategoriEkle,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Yeni'),
          ),
        ],
      ),
    );
  }

  Widget _bosGorunum() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.category_outlined,
              size: 64,
              color: _palet.orta.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.tur.etiket} kategorisi tanımlı değil',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _palet.koyuYazi,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Kayıt girebilmek için önce kategori ekleyin.',
              style: TextStyle(fontSize: 13, color: _palet.ana),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _palet.ana),
              onPressed: _kategoriEkle,
              icon: const Icon(Icons.add),
              label: const Text('Kategori Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kategoriKarti(Kategori kategori) {
    final int adet = _kullanim[kategori.id] ?? 0;
    final double tutar = _tutarlar[kategori.id] ?? 0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _palet.ana.withValues(alpha: kategori.aktif ? 0.14 : 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _gelirMi ? Icons.trending_up : Icons.trending_down,
                color: kategori.aktif ? _palet.ana : UygulamaRenkleri.griOrta,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    kategori.ad,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kategori.aktif
                          ? const Color(0xFF1F2A33)
                          : UygulamaRenkleri.griOrta,
                      decoration: kategori.aktif
                          ? null
                          : TextDecoration.lineThrough,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    adet == 0
                        ? 'Hareket yok'
                        : '$adet hareket  •  ${paraYaz(tutar)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: UygulamaRenkleri.gri,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: kategori.aktif ? 'Pasife al' : 'Aktif yap',
              onPressed: () => _durumDegistir(kategori),
              icon: Icon(
                kategori.aktif
                    ? Icons.toggle_on
                    : Icons.toggle_off_outlined,
                color: kategori.aktif ? _palet.ana : UygulamaRenkleri.griOrta,
                size: 28,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'İşlemler',
              onSelected: (String deger) {
                if (deger == 'duzenle') _kategoriDuzenle(kategori);
                if (deger == 'sil') _kategoriSil(kategori);
              },
              itemBuilder: (BuildContext baglam) =>
                  const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'duzenle',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Düzenle'),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'sil',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.delete_outline,
                      color: UygulamaRenkleri.giderVurgu,
                    ),
                    title: Text(
                      'Sil',
                      style: TextStyle(color: UygulamaRenkleri.giderVurgu),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
