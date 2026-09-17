import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:harcama_takip/ekranlar/ana_ekran.dart';
import 'package:harcama_takip/ekranlar/gelir_ekrani.dart';
import 'package:harcama_takip/ekranlar/gider_ekrani.dart';
import 'package:harcama_takip/main.dart';
import 'package:harcama_takip/modeller/hareket.dart';
import 'package:harcama_takip/modeller/hareket_turu.dart';
import 'package:harcama_takip/modeller/kategori.dart';
import 'package:harcama_takip/tema/uygulama_temasi.dart';
import 'package:harcama_takip/veritabani/veritabani_yardimcisi.dart';
import 'package:harcama_takip/yardimci/bicim.dart';

/// Test sırasında eklenen kayıtları veritabanından temizler.
Future<void> testKaydiniSil(String belgeNo) async {
  final VeritabaniYardimcisi vt = VeritabaniYardimcisi.ornek;
  for (final HareketTuru tur in HareketTuru.values) {
    final List<Hareket> kayitlar = await vt.hareketleriGetir(
      tur,
      arama: belgeNo,
    );
    for (final Hareket hareket in kayitlar) {
      if (hareket.belgeNo == belgeNo && hareket.id != null) {
        await vt.hareketSil(hareket.id!);
      }
    }
  }
}

/// Bir ekranın (Scaffold) zemin ve AppBar rengini okur.
({Color zemin, Color appBar}) ekranRenkleri(WidgetTester tester, Type ekran) {
  final Finder scaffoldBulucu = find.descendant(
    of: find.byType(ekran),
    matching: find.byType(Scaffold),
  );
  final Scaffold scaffold = tester.widget<Scaffold>(scaffoldBulucu);
  final AppBar appBar = tester.widget<AppBar>(
    find.descendant(of: scaffoldBulucu, matching: find.byType(AppBar)),
  );
  return (zemin: scaffold.backgroundColor!, appBar: appBar.backgroundColor!);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    await initializeDateFormatting('tr_TR', null);
    // Veritabanını gerçek (test dışı) zaman döngüsünde açıp önbelleğe alır;
    // böylece widget testleri içinde (FakeAsync) takılmadan kullanılabilir.
    await VeritabaniYardimcisi.ornek.veritabani;
  });

  test('Türkçe tarih ve para biçimlendirmesi çalışıyor', () {
    expect(tarihYaz(DateTime(2026, 3, 12)), '12.03.2026');
    expect(paraYaz(1250.5), contains('1.250,50'));
  });

  test('Varsayılan gelir ve gider kategorileri tanımlı geliyor', () async {
    final List<Kategori> gelirler = await VeritabaniYardimcisi.ornek
        .kategorileriGetir(HareketTuru.gelir);
    final List<Kategori> giderler = await VeritabaniYardimcisi.ornek
        .kategorileriGetir(HareketTuru.gider);

    expect(gelirler, isNotEmpty);
    expect(giderler, isNotEmpty);
    expect(gelirler.every((Kategori k) => k.tur == HareketTuru.gelir), isTrue);
    expect(giderler.every((Kategori k) => k.tur == HareketTuru.gider), isTrue);
  });

  test('Gelir kaydı toplamları doğru güncelliyor', () async {
    final VeritabaniYardimcisi vt = VeritabaniYardimcisi.ornek;
    final List<Kategori> gelirler = await vt.kategorileriGetir(
      HareketTuru.gelir,
      sadeceAktif: true,
    );

    final double oncekiToplam = await vt.toplam(HareketTuru.gelir);

    final int id = await vt.hareketEkle(
      Hareket(
        tur: HareketTuru.gelir,
        tarih: DateTime(2026, 3, 12),
        belgeNo: 'BIRIM-TEST-0001',
        kategoriId: gelirler.first.id,
        tutar: 100,
        aciklama: 'Birim test kaydı',
      ),
    );

    expect(
      await vt.toplam(HareketTuru.gelir),
      closeTo(oncekiToplam + 100, 0.001),
    );

    final Hareket? kayit = await vt.hareketGetir(id);
    expect(kayit, isNotNull);
    expect(kayit!.belgeNo, 'BIRIM-TEST-0001');
    expect(kayit.kategoriAd, gelirler.first.ad);
    expect(Hareket.tarihiMetne(kayit.tarih), '2026-03-12');

    await vt.hareketSil(id);
    expect(await vt.toplam(HareketTuru.gelir), closeTo(oncekiToplam, 0.001));
  });

  testWidgets('Ana ekran mavi tonlarda ve dashboard alanları görünüyor', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HarcamaTakipUygulamasi());
    await tester.pumpAndSettle();

    expect(find.text('Harcama Takip'), findsOneWidget);
    expect(find.text('Elde Kalan Bakiye'), findsOneWidget);
    expect(find.text('Son 5 Hareket'), findsOneWidget);

    final ({Color zemin, Color appBar}) renkler = ekranRenkleri(
      tester,
      AnaEkran,
    );
    expect(renkler.zemin, UygulamaRenkleri.maviZemin);
    expect(renkler.appBar, UygulamaRenkleri.maviKoyu);
  });

  testWidgets('Gelir ekranı yeşil, Gider ekranı gri tonlarda', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HarcamaTakipUygulamasi());
    await tester.pumpAndSettle();

    // Gelir sekmesi
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Gelirler'),
      ),
    );
    await tester.pumpAndSettle();

    final ({Color zemin, Color appBar}) gelirRenkleri = ekranRenkleri(
      tester,
      GelirEkrani,
    );
    expect(gelirRenkleri.zemin, UygulamaRenkleri.yesilZemin);
    expect(gelirRenkleri.appBar, UygulamaRenkleri.yesilKoyu);

    // Gider sekmesi
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Giderler'),
      ),
    );
    await tester.pumpAndSettle();

    final ({Color zemin, Color appBar}) giderRenkleri = ekranRenkleri(
      tester,
      GiderEkrani,
    );
    expect(giderRenkleri.zemin, UygulamaRenkleri.griZemin);
    expect(giderRenkleri.appBar, UygulamaRenkleri.griKoyu);
  });

  testWidgets(
    'Form ile gelir kaydı ekleniyor ve ana ekranda son hareketlerde görünüyor',
    (WidgetTester tester) async {
      const String belgeNo = 'UI-TEST-0001';
      await testKaydiniSil(belgeNo);

      await tester.pumpWidget(const HarcamaTakipUygulamasi());
      await tester.pumpAndSettle();

      // Dashboard'daki "Gelir Ekle" butonu forma götürür.
      await tester.tap(
        find.descendant(
          of: find.byType(AnaEkran),
          matching: find.widgetWithText(FilledButton, 'Gelir Ekle'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Yeni Gelir Kaydı'), findsOneWidget);

      // Tarih, Belge No, Kategori, Tutar ve Açıklama alanları mevcut.
      expect(find.text('Tarih'), findsOneWidget);
      expect(find.text('Belge No'), findsOneWidget);
      expect(find.text('Kategori'), findsOneWidget);
      expect(find.text('Tutar'), findsOneWidget);
      expect(find.text('Açıklama'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Belge No'),
        belgeNo,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tutar'),
        '1500,75',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Açıklama'),
        'UI testi açıklaması',
      );

      // Kategori seçimi
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Maaş').last);
      await tester.pumpAndSettle();

      // "Kaydet" butonu formun altında kalabilir; kaydırmadan sonra tıklanır.
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Kaydet'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Kaydet'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // Kayıt veritabanına yazıldı.
      final List<Hareket> kayitlar = await VeritabaniYardimcisi.ornek
          .hareketleriGetir(HareketTuru.gelir, arama: belgeNo);
      expect(kayitlar, hasLength(1));
      expect(kayitlar.first.tutar, closeTo(1500.75, 0.001));
      expect(kayitlar.first.kategoriAd, 'Maaş');
      expect(kayitlar.first.aciklama, 'UI testi açıklaması');

      // Son hareketler listesi de bu kaydı içermeli.
      final List<Hareket> sonHareketler =
          await VeritabaniYardimcisi.ornek.sonHareketler(5);
      expect(
        sonHareketler.any((Hareket h) => h.aciklama == 'UI testi açıklaması'),
        isTrue,
      );

      // Form kapanıp ana ekrana dönüldü ve kayıt son hareketler listesinde.
      expect(find.text('Harcama Takip'), findsOneWidget);
      // Son hareket kartı görünüm alanının dışında kalabilir; görünür yap.
      await tester.scrollUntilVisible(
        find.text('UI testi açıklaması'),
        80,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('UI testi açıklaması'), findsOneWidget);
      expect(find.textContaining(belgeNo), findsOneWidget);

      await testKaydiniSil(belgeNo);
    },
  );
}
