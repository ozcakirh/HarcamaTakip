import '../modeller/hareket_turu.dart';
import 'hareket_liste_ekrani.dart';

/// Gider ekranı — gri ton zeminli, sadece gider kayıtlarını listeler.
class GiderEkrani extends HareketListeEkrani {
  const GiderEkrani({super.key}) : super(tur: HareketTuru.gider);
}
