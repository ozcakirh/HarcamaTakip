import 'package:flutter/foundation.dart';

/// Veritabanında bir değişiklik olduğunda tüm ekranların kendini
/// yenilemesini sağlayan basit bildirim merkezi.
class VeriYenile {
  VeriYenile._();

  static final ValueNotifier<int> surum = ValueNotifier<int>(0);

  /// Kayıt eklendiğinde / güncellendiğinde / silindiğinde çağrılır.
  static void bildir() {
    surum.value++;
  }
}
