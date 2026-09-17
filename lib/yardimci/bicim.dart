import 'package:intl/intl.dart';

final DateFormat _tarihBicimi = DateFormat('dd.MM.yyyy', 'tr_TR');
final DateFormat _uzunTarihBicimi = DateFormat('d MMMM yyyy, EEEE', 'tr_TR');
final NumberFormat _paraBicimi = NumberFormat.currency(
  locale: 'tr_TR',
  symbol: '₺',
  decimalDigits: 2,
);

/// 12.03.2026 biçiminde tarih metni üretir.
String tarihYaz(DateTime tarih) => _tarihBicimi.format(tarih);

/// 12 Mart 2026, Perşembe biçiminde uzun tarih metni üretir.
String uzunTarihYaz(DateTime tarih) => _uzunTarihBicimi.format(tarih);

/// 1.250,50 ₺ biçiminde para metni üretir.
String paraYaz(double tutar) => _paraBicimi.format(tutar);
