import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import '../widgets/plant_info_card.dart';
import '../widgets/plant_visual.dart';
import 'growth_screen.dart';

/// Bitki detayı (3. referansın orta ekranı): büyük görsel, bakım özeti, ipucu, sulamayı kaydet.
class PlantDetailScreen extends StatelessWidget {
  final String plantId;
  const PlantDetailScreen({super.key, required this.plantId});

  Future<void> _interval(BuildContext context, Plant p) async {
    var days = p.waterEveryDays;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => GlassSheet(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SheetHandle(),
                const Text('Kaç günde bir sulansın?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Azalt',
                      onPressed: () => set(() => days = (days - 1).clamp(1, 60)),
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    SizedBox(
                      width: 110,
                      child: Text('$days gün',
                          textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    ),
                    IconButton.filled(
                      tooltip: 'Arttır',
                      style: IconButton.styleFrom(backgroundColor: GL.green),
                      onPressed: () => set(() => days = (days + 1).clamp(1, 60)),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GreenButton(label: 'Kaydet', onTap: () => Navigator.pop(ctx, true)),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok == true && context.mounted) StoreScope.read(context).updatePlant(p, waterEveryDays: days);
  }

  Future<void> _more(BuildContext context, Plant p) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => GlassSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            ListTile(
              leading: const Icon(Icons.schedule_rounded, color: GL.greenDark),
              title: Text('Sulama aralığı: ${p.waterEveryDays} gün'),
              onTap: () => Navigator.pop(ctx, 'interval'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: GL.danger),
              title: const Text('Bitkiyi sil', style: TextStyle(color: GL.danger)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'delete') {
      StoreScope.read(context).remove(p);
      Navigator.pop(context);
    } else if (action == 'interval') {
      await _interval(context, p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final p = store.byId(plantId);
    if (p == null) return const Scaffold(body: SizedBox.shrink());
    final watered = p.wateredToday;

    return Scaffold(
      body: LeafBackground(
        asset: 'assets/bg/dua.jpg',
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    Row(
                      children: [
                        GlassIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Geri', onTap: () => Navigator.pop(context)),
                        const Spacer(),
                        GlassIconButton(icon: Icons.more_horiz_rounded, tooltip: 'Diğer', onTap: () => _more(context, p)),
                      ],
                    ),
                    SizedBox(
                      height: 270,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 2,
                            top: 10,
                            right: 150,
                            child: Rise(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name,
                                      style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -.5)),
                                  const SizedBox(height: 4),
                                  Text(p.scientific,
                                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: GL.muted)),
                                  const SizedBox(height: 10),
                                  Glass(
                                    radius: 14,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: p.needsWaterToday ? GL.warnDot : GL.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(p.statusLabel,
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: p.needsWaterToday ? GL.warn : GL.greenDark)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(p.room, style: const TextStyle(fontSize: 12, color: GL.muted)),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 8,
                            bottom: 0,
                            width: 170,
                            child: FloatY(
                              child: Hero(tag: 'plant-${p.id}', child: PlantVisual(p, preferPhoto: false)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Rise(
                      delay: 80,
                      child: Glass(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Bakım özeti', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _Tile(icon: Icons.water_drop_outlined, label: 'Su', value: p.waterLabel),
                                const SizedBox(width: 6),
                                _Tile(icon: Icons.wb_sunny_outlined, label: 'Işık', value: p.light),
                                const SizedBox(width: 6),
                                _Tile(icon: Icons.thermostat_rounded, label: 'Sıcaklık', value: p.temperature),
                                const SizedBox(width: 6),
                                _Tile(icon: Icons.water_outlined, label: 'Nem', value: p.humidity),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Rise(
                      delay: 140,
                      child: Glass(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Bakım ipucu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(p.tip, style: const TextStyle(fontSize: 13, height: 1.5, color: GL.muted)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Rise(
                      delay: 200,
                      child: Glass(
                        key: const ValueKey('open-growth'),
                        padding: const EdgeInsets.all(12),
                        onTap: () => Navigator.of(context).push(glRoute(GrowthScreen(plantId: p.id))),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: GL.glassStrong, borderRadius: BorderRadius.circular(14)),
                              child: const Icon(Icons.trending_up_rounded, color: GL.greenDark),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Büyüme günlüğü', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                  Text(
                                    p.growth.isEmpty
                                        ? 'Fotoğraf ekleyerek büyümesini gün gün izle'
                                        : '${p.growth.length} kayıt · şu an ${p.currentHeight.toStringAsFixed(0)} cm',
                                    style: const TextStyle(fontSize: 12, color: GL.muted),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    PlantAboutCard(scientific: p.scientific),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: GreenButton(
                        key: const ValueKey('log-water'),
                        label: watered ? 'Sulandı · ${p.waterEveryDays} gün sonra tekrar' : 'Sulamayı kaydet',
                        icon: watered ? Icons.check_rounded : Icons.water_drop_rounded,
                        color: watered ? GL.greenDark : GL.green,
                        onTap: watered
                            ? null
                            : () {
                                store.water(p);
                                showGLSnack(context, '${p.name} sulandı. Sonraki sulama ${p.waterEveryDays} gün sonra.');
                              },
                      ),
                    ),
                    const SizedBox(width: 10),
                    GlassIconButton(
                      icon: Icons.calendar_month_rounded,
                      tooltip: 'Sulama aralığı',
                      size: 54,
                      onTap: () => _interval(context, p),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Tile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Column(
          children: [
            Icon(icon, size: 19, color: GL.greenDark),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: GL.muted)),
            Text(value,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, height: 1.2)),
          ],
        ),
      ),
    );
  }
}
