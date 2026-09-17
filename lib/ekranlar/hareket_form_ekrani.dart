import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modeller/hareket.dart';
import '../modeller/hareket_turu.dart';
import '../modeller/kategori.dart';
import '../tema/ekran_paleti.dart';
import '../tema/uygulama_temasi.dart';
import '../veritabani/veritabani_yardimcisi.dart';
import '../yardimci/bicim.dart';
import '../yardimci/veri_yenile.dart';
import 'kategori_liste_ekrani.dart';

/// Gelir veya gider kaydı ekleme / düzenleme formu.
///
/// Alanlar: Tarih, Belge No, Kategori, Tutar ve Açıklama.
class HareketFormEkrani extends StatefulWidget {
  const HareketFormEkrani({
    super.key,
    required this.tur,
    this.hareket,
  });

  final HareketTuru tur;

  /// Dolu ise kayıt düzenlenir, boş ise yeni kayıt eklenir.
  final Hareket? hareket;

  @override
  State<HareketFormEkrani> createState() => _HareketFormEkraniDurumu();
}

class _HareketFormEkraniDurumu extends State<HareketFormEkrani> {
  final GlobalKey<FormState> _formAnahtari = GlobalKey<FormState>();
  final TextEditingController _belgeNoKontrolcusu = TextEditingController();
  final TextEditingController _tutarKontrolcusu = TextEditingController();
  final TextEditingController _aciklamaKontrolcusu = TextEditingController();

  late DateTime _tarih;
  int? _kategoriId;
  List<Kategori> _kategoriler = <Kategori>[];
  bool _yukleniyor = true;
  bool _kaydediliyor = false;

  EkranPaleti get _palet => EkranPaleti.turIcin(widget.tur);
  bool get _duzenlemeMi => widget.hareket != null;

  @override
  void initState() {
    super.initState();
    final Hareket? mevcut = widget.hareket;
    _tarih = mevcut?.tarih ?? DateTime.now();
    _belgeNoKontrolcusu.text = mevcut?.belgeNo ?? '';
    _aciklamaKontrolcusu.text = mevcut?.aciklama ?? '';
    _kategoriId = mevcut?.kategoriId;
    if (mevcut != null) {
      _tutarKontrolcusu.text = mevcut.tutar
          .toStringAsFixed(2)
          .replaceAll('.', ',')
          .replaceAll(RegExp(r',00$'), ',00');
    }
    _kategorileriYukle();
  }

  @override
  void dispose() {
    _belgeNoKontrolcusu.dispose();
    _tutarKontrolcusu.dispose();
    _aciklamaKontrolcusu.dispose();
    super.dispose();
  }

  Future<void> _kategorileriYukle() async {
    final List<Kategori> kategoriler =
        await VeritabaniYardimcisi.ornek.kategorileriGetir(widget.tur);
    if (!mounted) return;
    setState(() {
      _kategoriler = kategoriler;
      // Seçili kategori silinmişse seçimi temizle.
      if (_kategoriId != null &&
          !kategoriler.any((Kategori k) => k.id == _kategoriId)) {
        _kategoriId = null;
      }
      _yukleniyor = false;
    });
  }

  Future<void> _tarihSec() async {
    final DateTime? secilen = await showDatePicker(
      context: context,
      initialDate: _tarih,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5, 12, 31),
      locale: const Locale('tr', 'TR'),
      helpText: 'Tarih Seçin',
      cancelText: 'Vazgeç',
      confirmText: 'Tamam',
    );
    if (secilen != null) {
      setState(() => _tarih = secilen);
    }
  }

  /// "1.250,50", "1250,50" ve "1250.50" biçimlerini sayıya çevirir.
  double? _tutariCoz(String metin) {
    String temiz = metin.trim().replaceAll(' ', '').replaceAll('₺', '');
    if (temiz.isEmpty) return null;
    if (temiz.contains(',') && temiz.contains('.')) {
      temiz = temiz.replaceAll('.', '').replaceAll(',', '.');
    } else if (temiz.contains(',')) {
      temiz = temiz.replaceAll(',', '.');
    }
    return double.tryParse(temiz);
  }

  Future<void> _kaydet() async {
    if (!(_formAnahtari.currentState?.validate() ?? false)) return;
    if (_kategoriId == null) {
      _mesajGoster('Lütfen bir kategori seçin.', hata: true);
      return;
    }

    final double? tutar = _tutariCoz(_tutarKontrolcusu.text);
    if (tutar == null || tutar <= 0) {
      _mesajGoster('Geçerli bir tutar girin.', hata: true);
      return;
    }

    setState(() => _kaydediliyor = true);

    final String belgeNo = _belgeNoKontrolcusu.text.trim();
    final String aciklama = _aciklamaKontrolcusu.text.trim();

    final Hareket kayit = Hareket(
      id: widget.hareket?.id,
      tur: widget.tur,
      tarih: _tarih,
      belgeNo: belgeNo.isEmpty ? null : belgeNo,
      kategoriId: _kategoriId,
      tutar: tutar,
      aciklama: aciklama.isEmpty ? null : aciklama,
    );

    try {
      if (_duzenlemeMi) {
        await VeritabaniYardimcisi.ornek.hareketGuncelle(kayit);
      } else {
        await VeritabaniYardimcisi.ornek.hareketEkle(kayit);
      }
      VeriYenile.bildir();
      if (!mounted) return;
      _mesajGoster(
        _duzenlemeMi
            ? '${widget.tur.etiket} kaydı güncellendi.'
            : '${widget.tur.etiket} kaydı eklendi.',
      );
      Navigator.of(context).pop(true);
    } catch (hata) {
      if (!mounted) return;
      setState(() => _kaydediliyor = false);
      _mesajGoster('Kayıt sırasında hata oluştu: $hata', hata: true);
    }
  }

  Future<void> _sil() async {
    final Hareket? mevcut = widget.hareket;
    if (mevcut?.id == null) return;

    final bool onay =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext baglam) => AlertDialog(
            title: const Text('Kaydı sil'),
            content: const Text('Bu kaydı silmek istediğinize emin misiniz?'),
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

    await VeritabaniYardimcisi.ornek.hareketSil(mevcut!.id!);
    VeriYenile.bildir();
    if (!mounted) return;
    _mesajGoster('Kayıt silindi.');
    Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    final bool gelirMi = widget.tur == HareketTuru.gelir;

    return Scaffold(
      backgroundColor: _palet.zemin,
      appBar: AppBar(
        backgroundColor: _palet.koyu,
        foregroundColor: Colors.white,
        title: Text(
          _duzenlemeMi
              ? '${widget.tur.etiket} Kaydını Düzenle'
              : 'Yeni ${widget.tur.etiket} Kaydı',
        ),
        actions: <Widget>[
          if (_duzenlemeMi)
            IconButton(
              tooltip: 'Sil',
              onPressed: _sil,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _turBasligi(gelirMi),
                    const SizedBox(height: 16),
                    _formKarti(),
                    const SizedBox(height: 20),
                    _kaydetButonu(gelirMi),
                    if (_duzenlemeMi) ...<Widget>[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _kaydediliyor ? null : _sil,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: UygulamaRenkleri.giderVurgu,
                          side: const BorderSide(
                            color: UygulamaRenkleri.giderVurgu,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Kaydı Sil'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _turBasligi(bool gelirMi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _palet.gecis,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            gelirMi ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: Colors.white,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              gelirMi
                  ? 'Gelir bilgilerini eksiksiz doldurun'
                  : 'Gider bilgilerini eksiksiz doldurun',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formKarti() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formAnahtari,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- Tarih ---
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: tarihYaz(_tarih)),
                onTap: _tarihSec,
                decoration: const InputDecoration(
                  labelText: 'Tarih',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
              ),
              const SizedBox(height: 14),

              // --- Belge No ---
              TextFormField(
                controller: _belgeNoKontrolcusu,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Belge No',
                  hintText: 'Örn: FTR-2026-0001',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                ),
              ),
              const SizedBox(height: 14),

              // --- Kategori ---
              _kategoriAlani(),
              const SizedBox(height: 14),

              // --- Tutar ---
              TextFormField(
                controller: _tutarKontrolcusu,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Tutar',
                  hintText: 'Örn: 1.250,50',
                  prefixIcon: Icon(Icons.payments_outlined),
                  suffixText: '₺',
                ),
                validator: (String? deger) {
                  final double? tutar = _tutariCoz(deger ?? '');
                  if (tutar == null || tutar <= 0) {
                    return 'Geçerli bir tutar girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // --- Açıklama ---
              TextFormField(
                controller: _aciklamaKontrolcusu,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'İsteğe bağlı not',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kategoriAlani() {
    if (_kategoriler.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${widget.tur.etiket} kategorisi tanımlı değil. Kayıt girmeden önce '
              'kategori eklemelisiniz.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
              ),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => KategoriListeEkrani(tur: widget.tur),
                  ),
                );
                await _kategorileriYukle();
              },
              icon: const Icon(Icons.category_outlined, size: 18),
              label: const Text('Kategori Tanımla'),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: _kategoriId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Kategori',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            hint: const Text('Kategori seçin'),
            items: _kategoriler
                .map(
                  (Kategori kategori) => DropdownMenuItem<int>(
                    value: kategori.id,
                    child: Text(
                      kategori.aktif ? kategori.ad : '${kategori.ad} (pasif)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (int? deger) => setState(() => _kategoriId = deger),
            validator: (int? deger) =>
                deger == null ? 'Kategori seçin' : null,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: IconButton.filledTonal(
            tooltip: 'Kategori yönet',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => KategoriListeEkrani(tur: widget.tur),
                ),
              );
              await _kategorileriYukle();
            },
            icon: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _kaydetButonu(bool gelirMi) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: gelirMi
            ? UygulamaRenkleri.yesil
            : UygulamaRenkleri.griKoyu,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: _kaydediliyor ? null : _kaydet,
      icon: _kaydediliyor
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.save_outlined),
      label: Text(_duzenlemeMi ? 'Güncelle' : 'Kaydet'),
    );
  }
}
