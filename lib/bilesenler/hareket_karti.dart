import 'package:flutter/material.dart';

import '../modeller/hareket.dart';
import '../modeller/hareket_turu.dart';
import '../tema/uygulama_temasi.dart';
import '../yardimci/bicim.dart';

/// Gelir / gider listelerinde kullanılan hareket kartı.
class HareketKarti extends StatelessWidget {
  const HareketKarti({
    super.key,
    required this.hareket,
    required this.vurguRengi,
    this.yogunZemin = false,
    this.dokunma,
  });

  final Hareket hareket;

  /// Kartın sol şeridi ve tutar rengi.
  final Color vurguRengi;

  /// Dashboard gibi koyu zeminlerde kullanılacak açık görünüm.
  final bool yogunZemin;

  final VoidCallback? dokunma;

  @override
  Widget build(BuildContext context) {
    final bool gelirMi = hareket.tur == HareketTuru.gelir;
    final Color tutarRengi = yogunZemin
        ? Colors.white
        : (gelirMi ? UygulamaRenkleri.gelirVurgu : UygulamaRenkleri.giderVurgu);

    final String kategori = hareket.kategoriAd ?? 'Kategorisiz';
    final String belgeNo = (hareket.belgeNo ?? '').trim();
    final String aciklama = (hareket.aciklama ?? '').trim();

    final List<String> altSatirlar = <String>[
      tarihYaz(hareket.tarih),
      if (belgeNo.isNotEmpty) 'Belge No: $belgeNo',
    ];

    return Material(
      color: yogunZemin ? Colors.white.withValues(alpha: 0.14) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: dokunma,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: vurguRengi.withValues(alpha: yogunZemin ? 0.35 : 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  gelirMi ? Icons.south_west_rounded : Icons.north_east_rounded,
                  color: yogunZemin ? Colors.white : vurguRengi,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      kategori,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: yogunZemin ? Colors.white : const Color(0xFF1F2A33),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      altSatirlar.join('  •  '),
                      style: TextStyle(
                        fontSize: 12,
                        color: yogunZemin
                            ? Colors.white.withValues(alpha: 0.85)
                            : UygulamaRenkleri.gri,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (aciklama.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        aciklama,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: yogunZemin
                              ? Colors.white.withValues(alpha: 0.75)
                              : UygulamaRenkleri.griOrta,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '${gelirMi ? '+' : '-'}${paraYaz(hareket.tutar)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: tutarRengi,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
