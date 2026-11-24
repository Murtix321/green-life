import 'package:flutter/material.dart';

import '../data/care_db.dart';
import '../models/plant.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/animated_plant.dart';
import '../widgets/common.dart';
import 'plant_detail_screen.dart';

class PlantsScreen extends StatefulWidget {
  final VoidCallback onScan;
  const PlantsScreen({super.key, required this.onScan});

  @override
  State<PlantsScreen> createState() => _PlantsScreenState();
}

class _PlantsScreenState extends State<PlantsScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final list = store.plants
        .where((p) => _q.isEmpty || p.name.toLowerCase().contains(_q) || p.scientific.toLowerCase().contains(_q))
        .toList()
      ..sort((a, b) => a.daysUntilWater.compareTo(b.daysUntilWater));

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
        children: [
          const Rise(
            child: Text('Bitkilerim', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.5)),
          ),
          const SizedBox(height: 12),
          Rise(
            delay: 100,
            child: TextField(
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Bitki ara…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Rise(
            delay: 180,
            child: Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Tara',
                    height: 48,
                    leading: const Icon(Icons.center_focus_strong_rounded, size: 20),
                    onTap: widget.onScan,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'Listeden ekle',
                    height: 48,
                    bg: GL.mintSoft,
                    fg: GL.forest,
                    leading: const Icon(Icons.add_rounded, size: 20),
                    onTap: () => showAddFromListSheet(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('Henüz bitki yok.', style: TextStyle(color: GL.muted))),
            ),
          for (var i = 0; i < list.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Rise(delay: 220 + i * 80, child: _PlantRow(plant: list[i])),
            ),
        ],
      ),
    );
  }
}

class _PlantRow extends StatelessWidget {
  final Plant plant;
  const _PlantRow({required this.plant});

  @override
  Widget build(BuildContext context) {
    final p = plant;
    final late = p.needsWaterToday;
    return GLCard(
      padding: const EdgeInsets.all(10),
      onTap: () => Navigator.of(context).push(glRoute(PlantDetailScreen(plantId: p.id))),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: GL.mintPale, borderRadius: BorderRadius.circular(18)),
            alignment: Alignment.bottomCenter,
            child: AnimatedPlant(kind: p.kind, leaves: 4, size: 60),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Text(p.scientific,
                    style: const TextStyle(fontSize: 12, color: GL.muted, fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.water_drop_rounded, size: 14, color: late ? GL.warnDot : GL.water),
                    const SizedBox(width: 4),
                    Text(
                      p.waterLabel,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: late ? GL.warn : GL.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text('${p.health}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const Text('sağlık', style: TextStyle(fontSize: 10, color: GL.muted)),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

/// Tarama yapmadan, hazır listeden bitki ekleme.
Future<void> showAddFromListSheet(BuildContext context) async {
  final picked = await showModalBottomSheet<CareInfo>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    builder: (_) => const _CarePicker(),
  );
  if (picked == null || !context.mounted) return;
  final store = StoreScope.read(context);
  final p = store.addFromCare(picked);
  showGLSnack(context, '${p.name} eklendi. Sulama alarmı kuruldu.');
}

class _CarePicker extends StatefulWidget {
  const _CarePicker();

  @override
  State<_CarePicker> createState() => _CarePickerState();
}

class _CarePickerState extends State<_CarePicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final items = CareDb.all
        .where((c) => _q.isEmpty || c.trName.toLowerCase().contains(_q) || c.scientific.toLowerCase().contains(_q))
        .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .8,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFD3DED6), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Listeden bitki seç', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Örn. orkide, aloe…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: GL.bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: GL.mintSoft),
                itemBuilder: (_, i) {
                  final c = items[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    leading: SizedBox(width: 44, child: AnimatedPlant(kind: c.kind, leaves: 3, size: 40, sway: false)),
                    title: Text(c.trName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${c.scientific} · Su: ${c.waterText}', style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.add_circle_rounded, color: GL.forest),
                    onTap: () => Navigator.pop(context, c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
