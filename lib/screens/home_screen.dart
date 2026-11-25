import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../services/store.dart';
import '../services/weather.dart';
import '../theme.dart';
import '../widgets/animated_plant.dart';
import '../widgets/common.dart';
import 'plant_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onOpenPlants;
  final VoidCallback onScan;
  const HomeScreen({super.key, required this.onOpenPlants, required this.onScan});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Günaydın';
    if (h < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final featured = store.featured;
    final due = store.dueToday;
    final doneToday = store.wateredTodayList.where((p) => !p.needsWaterToday).toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
        children: [
          Rise(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: Color(0xFFD6EADB), shape: BoxShape.circle),
                  child: const Icon(Icons.eco_rounded, color: GL.forest, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting(), style: const TextStyle(fontSize: 13, color: GL.muted)),
                      Text(store.firstName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                RoundIconButton(
                  icon: Icons.notifications_none_rounded,
                  tooltip: 'Bildirimler',
                  onTap: () => showGLSnack(
                    context,
                    due.isEmpty ? 'Bugün sulanacak bitki yok.' : 'Bugün ${due.length} bitki sulanacak.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (featured == null)
            Rise(delay: 120, child: _EmptyCard(onScan: onScan))
          else
            Rise(delay: 120, child: _FeaturedCard(plant: featured)),
          const SizedBox(height: 14),
          Rise(
            delay: 180,
            child: _WeatherTip(
              key: ValueKey('${store.cityLat},${store.cityLon}'),
              city: store.cityName,
              lat: store.cityLat,
              lon: store.cityLon,
            ),
          ),
          const SizedBox(height: 14),
          Rise(
            delay: 240,
            child: GLCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Bugünün görevleri', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      ),
                      Text(
                        '${due.length + doneToday.length} görev',
                        style: const TextStyle(fontSize: 12, color: GL.forestMid, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (due.isEmpty && doneToday.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Bugün dinlenme günü. Bitkilerin keyifte.', style: TextStyle(color: GL.muted)),
                    ),
                  for (final p in doneToday) _TaskRow(plant: p, done: true),
                  for (final p in due) _TaskRow(plant: p, done: false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Rise(delay: 360, child: _AlarmCard(store: store)),
          const SizedBox(height: 14),
          Rise(
            delay: 480,
            child: SectionTitle('Bitkilerim', action: 'Tümü', onAction: onOpenPlants),
          ),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: store.plants.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                if (i == store.plants.length) return _AddTile(onTap: onScan);
                return Rise(delay: 500 + i * 90, child: _MiniPlantCard(plant: store.plants[i]));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Plant plant;
  const _FeaturedCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    final p = plant;
    return GLCard(
      padding: EdgeInsets.zero,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, GL.mintPale],
      ),
      onTap: () => Navigator.of(context).push(glRoute(PlantDetailScreen(plantId: p.id))),
      child: SizedBox(
        height: 262,
        child: Stack(
          children: [
            Positioned(
              right: -14,
              bottom: 0,
              child: Hero(
                tag: 'plant-${p.id}',
                child: AnimatedPlant(kind: p.kind, leaves: 5, size: 190, potColor: const Color(0xFFEEF0EB)),
              ),
            ),
            Positioned(
              top: 18,
              left: 18,
              right: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                  Text(p.room, style: const TextStyle(fontSize: 12, color: GL.muted)),
                ],
              ),
            ),
            const Positioned(top: 14, right: 16, child: Icon(Icons.more_horiz_rounded, color: GL.muted)),
            Positioned(
              left: 18,
              top: 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bitki sağlığı',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: GL.muted)),
                  const SizedBox(height: 6),
                  HealthRing(score: p.health),
                ],
              ),
            ),
            Positioned(
              left: 14,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: GL.softShadow,
                ),
                child: Row(
                  children: [
                    const BouncingDrop(),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sulama', style: TextStyle(fontSize: 11, color: GL.muted)),
                        Text(
                          p.waterLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: p.daysUntilWater < 0 ? GL.warn : GL.ink,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final Plant plant;
  final bool done;
  const _TaskRow({required this.plant, required this.done});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.read(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: done
          ? null
          : () {
              store.water(plant);
              showGLSnack(context, '${plant.name} sulandı. Sonraki sulama ${plant.waterEveryDays} gün sonra.');
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: done ? GL.forest : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: done ? GL.forest : const Color(0xFF9CC4A8), width: 2),
              ),
              child: done ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${plant.name} bitkisini sula',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: done ? FontWeight.w500 : FontWeight.w700,
                  color: done ? GL.muted : GL.ink,
                  decoration: done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (!done)
              Text(
                plant.daysUntilWater < 0 ? plant.waterLabel : 'Dokun: sulandı',
                style: const TextStyle(fontSize: 12, color: GL.warn, fontWeight: FontWeight.w700),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final AppStore store;
  const _AlarmCard({required this.store});

  Future<void> _pickTime(BuildContext context) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: store.alarmHour, minute: store.alarmMinute),
      helpText: 'Sulama alarmı saati',
    );
    if (t != null) store.setAlarmTime(t.hour, t.minute);
  }

  @override
  Widget build(BuildContext context) {
    return GLCard(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      child: Row(
        children: [
          const Icon(Icons.alarm_rounded, color: GL.forest),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => _pickTime(context),
              borderRadius: BorderRadius.circular(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sulama alarmı', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(
                    '${store.alarmTimeText} · ${store.alarmOn ? 'Açık' : 'Kapalı'} · saati değiştirmek için dokun',
                    style: const TextStyle(fontSize: 12, color: GL.muted),
                  ),
                ],
              ),
            ),
          ),
          Switch(value: store.alarmOn, onChanged: store.setAlarm),
        ],
      ),
    );
  }
}

class _MiniPlantCard extends StatelessWidget {
  final Plant plant;
  const _MiniPlantCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    final late = plant.needsWaterToday;
    return SizedBox(
      width: 138,
      child: GLCard(
        padding: const EdgeInsets.all(10),
        onTap: () => Navigator.of(context).push(glRoute(PlantDetailScreen(plantId: plant.id))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 92,
              width: double.infinity,
              decoration: BoxDecoration(color: GL.mintPale, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.bottomCenter,
              child: AnimatedPlant(kind: plant.kind, leaves: 4, size: 74),
            ),
            const SizedBox(height: 8),
            Text(plant.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: late ? GL.warnDot : GL.leaf, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    plant.waterLabel,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: late ? GL.warn : GL.muted, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: GLCard(
        color: GL.mintSoft,
        onTap: onTap,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, color: GL.forest, size: 30),
            SizedBox(height: 8),
            Text('Bitki ekle', style: TextStyle(fontWeight: FontWeight.w700, color: GL.forest)),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final VoidCallback onScan;
  const _EmptyCard({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return GLCard(
      gradient: const LinearGradient(colors: [Colors.white, GL.mintPale]),
      child: Row(
        children: [
          const AnimatedPlant(kind: PlantKind.leafy, leaves: 3, size: 96),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('İlk bitkini ekle', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Fotoğrafını çek, gerisini Green Life halletsin.',
                    style: TextStyle(fontSize: 13, color: GL.muted)),
                const SizedBox(height: 10),
                PrimaryButton(label: 'Bitki tara', onTap: onScan, height: 44),
              ],
            ),
          ),
        ],
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
        return AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          child: GLCard(
            color: GL.mintPale,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  alignment: Alignment.center,
                  child: w == null
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: GL.forest),
                        )
                      : Text('${w.temp.round()}°',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: GL.forest)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${widget.city} · bugünün ipucu',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: GL.forestMid)),
                      const SizedBox(height: 2),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          w?.tip ?? 'Hava durumu alınıyor…',
                          key: ValueKey(w?.tip),
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
