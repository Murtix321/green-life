import 'package:flutter/material.dart';

import '../services/plant_info.dart';
import '../theme.dart';
import 'glass.dart';
import 'plant_visual.dart';

/// Bitki detayındaki "Hakkında" kartı: Vikipedi özeti (+ bitkinin iNaturalist fotoğrafı).
class PlantAboutCard extends StatefulWidget {
  final String scientific;
  final bool showPhoto;
  const PlantAboutCard({super.key, required this.scientific, this.showPhoto = false});

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
        final info = snap.data;
        if (snap.connectionState == ConnectionState.done && (info == null || info.summary == null)) {
          return const SizedBox.shrink();
        }
        return Glass(
          padding: const EdgeInsets.all(14),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: info == null
                ? const SizedBox(
                    height: 48,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2.2, color: GL.green)),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hakkında', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      if (widget.showPhoto && info.photoUrl != null) ...[
                        photoOrAsset(info.photoUrl!, width: double.infinity, height: 160, radius: 16),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        info.summary!,
                        maxLines: _open ? null : 4,
                        overflow: _open ? TextOverflow.visible : TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, height: 1.5),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _open = !_open),
                        style: TextButton.styleFrom(foregroundColor: GL.greenDark, padding: EdgeInsets.zero),
                        child: Text(_open ? 'Daha az göster' : 'Devamını oku', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      Text(
                        info.summaryIsTurkish ? 'Kaynak: Vikipedi' : 'Kaynak: Wikipedia (Türkçe sayfası yok, İngilizce)',
                        style: const TextStyle(fontSize: 10.5, color: GL.muted),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
