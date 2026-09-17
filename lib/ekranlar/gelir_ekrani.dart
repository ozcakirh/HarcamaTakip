import '../modeller/hareket_turu.dart';
import 'hareket_liste_ekrani.dart';

/// Gelir ekranı — yeşil ton zeminli, sadece gelir kayıtlarını listeler.
class GelirEkrani extends HareketListeEkrani {
  const GelirEkrani({super.key}) : super(tur: HareketTuru.gelir);
}
