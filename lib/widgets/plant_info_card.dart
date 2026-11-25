import 'package:flutter/material.dart';

import '../services/plant_info.dart';
import '../theme.dart';
import 'common.dart';

/// Ağdan yumuşakça beliren fotoğraf; yüklenemezse sessizce boş kalır.
class NetPhoto extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final double radius;
  const NetPhoto(this.url, {super.key, this.width, this.height, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, sync) => AnimatedOpacity(
          opacity: frame == null && !sync ? 0 : 1,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: child,
        ),
        loadingBuilder: (context, child, p) =>
            p == null ? child : Container(width: width, height: height, color: GL.mintSoft),
        errorBuilder: (_, __, ___) => Container(width: width, height: height, color: GL.mintSoft),
      ),
    );
  }
}

/// Bitki detayındaki "Hakkında" kartı: iNaturalist fotoğrafı + Wikipedia özeti.
class PlantAboutCard extends StatefulWidget {
  final String scientific;
  const PlantAboutCard({super.key, required this.scientific});

  @override
  State<PlantAboutCard> createState() => _PlantAboutCardState();
}

class _PlantAboutCardState extends State<PlantAboutCard> {
  late Future<PlantInfo?> _f = PlantInfoService.fetch(widget.scientific);
  bool _open = false;

  @override
  void didUpdateWidget(PlantAboutCard old) {
    super.didUpdateWidget(old);
    if (old.scientific != widget.scientific) _f = PlantInfoService.fetch(widget.scientific);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlantInfo?>(
      future: _f,
      builder: (context, snap) {
        final loading = snap.connectionState != ConnectionState.done;
        final info = snap.data;
        Widget body;
        if (loading) {
          body = const SizedBox(
            key: ValueKey('l'),
            height: 72,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: GL.forest)),
          );
        } else if (info == null) {
          body = const Padding(
            key: ValueKey('e'),
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Bu bitki hakkında ek bilgi bulunamadı ya da internet bağlantısı yok.',
              style: TextStyle(color: GL.muted, fontSize: 13),
            ),
          );
        } else {
          body = Column(
            key: const ValueKey('d'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (info.photoUrl != null) ...[
                NetPhoto(info.photoUrl!, width: double.infinity, height: 180),
                if (info.photoCredit != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Fotoğraf: ${info.photoCredit} · iNaturalist',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: GL.muted)),
                  ),
                const SizedBox(height: 10),
              ],
              if (info.trName != null)
                Text(info.trName!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text(widget.scientific,
                  style: const TextStyle(fontSize: 12, color: GL.muted, fontStyle: FontStyle.italic)),
              if (info.summary != null) ...[
                const SizedBox(height: 8),
                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: Text(
                    info.summary!,
                    maxLines: _open ? null : 4,
                    overflow: _open ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _open = !_open),
                  style: TextButton.styleFrom(foregroundColor: GL.forestMid, padding: EdgeInsets.zero),
                  child: Text(_open ? 'Daha az göster' : 'Devamını oku',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                Text(
                  info.summaryIsTurkish ? 'Kaynak: Vikipedi' : 'Kaynak: Wikipedia (Türkçe sayfa yok, İngilizce)',
                  style: const TextStyle(fontSize: 10, color: GL.muted),
                ),
              ],
            ],
          );
        }
        return GLCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: GL.forest, size: 20),
                  SizedBox(width: 8),
                  Text('Hakkında', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(duration: const Duration(milliseconds: 400), child: body),
            ],
          ),
        );
      },
    );
  }
}
