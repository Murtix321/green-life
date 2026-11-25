import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../services/store.dart';
import '../services/weather.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import '../widgets/plant_visual.dart';
import 'plant_detail_screen.dart';
import 'plants_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onScan;
  final VoidCallback onOpenPlants;
  final VoidCallback onOpenCare;
  const HomeScreen({super.key, required this.onScan, required this.onOpenPlants, required this.onOpenCare});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Günaydın,';
    if (h < 18) return 'İyi günler,';
    return 'İyi akşamlar,';
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final due = store.dueToday;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
        children: [
          Row(
            children: [
              GlassIconButton(icon: Icons.center_focus_strong_rounded, tooltip: 'Bitki tara', onTap: onScan),
              const Spacer(),
              GlassIconButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Bildirimler',
                onTap: () => showGLSnack(
                  context,
                  due.isEmpty ? 'Bugün sulanacak bitki yok.' : 'Bugün ${due.length} bitki su istiyor.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Rise(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: GL.font, fontSize: 27, height: 1.15, color: GL.ink, letterSpacing: -.4),
                children: [
                  TextSpan(text: '${_greeting()}\n', style: const TextStyle(fontWeight: FontWeight.w500)),
                  TextSpan(text: store.firstName, style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Rise(
            delay: 60,
            child: Text('Bitkilerine iyi bak, onlar da sana.', style: TextStyle(fontSize: 13, color: GL.muted)),
          ),
          const SizedBox(height: 14),
          Rise(
            delay: 120,
            child: Glass(
              key: const ValueKey('home-search'),
              radius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              onTap: () => showAddPlantSheet(context),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: GL.muted, size: 20),
                  SizedBox(width: 10),
                  Text('Bitki ara ve ekle…', style: TextStyle(fontSize: 14, color: GL.muted)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Rise(
            delay: 180,
            child: Row(
              children: [
                const Expanded(child: Text('Bitkilerim', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                TextButton(
                  onPressed: onOpenPlants,
                  style: TextButton.styleFrom(foregroundColor: GL.greenDark),
                  child: const Text('Tümü', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: store.plants.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                if (i == store.plants.length) {
                  return SizedBox(
                    width: 104,
                    child: Glass(
                      onTap: () => showAddPlantSheet(context),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline_rounded, color: GL.greenDark, size: 30),
                          SizedBox(height: 8),
                          Text('Bitki ekle', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: GL.greenDark)),
                        ],
                      ),
                    ),
                  );
                }
                return Rise(delay: 220 + i * 70, child: _PlantCard(plant: store.plants[i]));
              },
            ),
          ),
          const SizedBox(height: 18),
          const Rise(delay: 300, child: Text('Bugünkü bakım', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
          const SizedBox(height: 10),
          Rise(
            delay: 340,
            child: Glass(
              key: const ValueKey('home-today'),
              padding: const EdgeInsets.all(12),
              onTap: onOpenCare,
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: GL.green, borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.water_drop_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(due.isEmpty ? 'Bugün sulanacak bitki yok' : '${due.length} bitkiyi sula',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        Text(
                          due.isEmpty ? 'Bitkilerin keyifte.' : due.map((p) => p.name).join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: GL.muted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: GL.ink),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Rise(
            delay: 400,
            child: _WeatherTip(
              key: ValueKey('${store.cityLat},${store.cityLon}'),
              city: store.cityName,
              lat: store.cityLat,
              lon: store.cityLon,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantCard extends StatelessWidget {
  final Plant plant;
  const _PlantCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    final p = plant;
    final thirsty = p.needsWaterToday;
    return SizedBox(
      width: 128,
      child: Glass(
        padding: const EdgeInsets.all(8),
        onTap: () => Navigator.of(context).push(glRoute(PlantDetailScreen(plantId: p.id))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Hero(tag: 'plant-${p.id}', child: PlantVisual(p, height: 124)),
              ),
            ),
            const SizedBox(height: 6),
            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: thirsty ? GL.warnDot : GL.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(p.statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: thirsty ? GL.warn : GL.greenDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Open-Meteo hava durumuna göre günün bakım ipucu.
class _WeatherTip extends StatefulWidget {
  final String city;
  final double lat;
  final double lon;
  const _WeatherTip({super.key, required this.city, required this.lat, required this.lon});

  @override
  State<_WeatherTip> createState() => _WeatherTipState();
}

class _WeatherTipState extends State<_WeatherTip> {
  late final Future<WeatherNow?> _f = WeatherService.now(widget.lat, widget.lon);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeatherNow?>(
      future: _f,
      builder: (context, snap) {
        final w = snap.data;
        if (snap.connectionState == ConnectionState.done && w == null) return const SizedBox.shrink();
        return Glass(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: GL.glassStrong, borderRadius: BorderRadius.circular(15)),
                alignment: Alignment.center,
                child: w == null
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: GL.green))
                    : Text('${w.temp.round()}°', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: GL.greenDark)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${widget.city} · bugünün ipucu',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: GL.greenDark)),
                    const SizedBox(height: 2),
                    Text(w?.tip ?? 'Hava durumu alınıyor…', style: const TextStyle(fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
