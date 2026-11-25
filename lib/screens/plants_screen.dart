import 'dart:async';

import 'package:flutter/material.dart';

import '../data/care_db.dart';
import '../models/plant.dart';
import '../services/plant_id.dart';
import '../services/plant_info.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/animated_plant.dart';
import '../widgets/common.dart';
import '../widgets/plant_info_card.dart';
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
                    label: 'Bitki ara',
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

/// Tarama yapmadan bitki ekleme: hazır Türkçe liste + iNaturalist'te tüm bitkiler.
Future<void> showAddFromListSheet(BuildContext context) async {
  final picked = await showModalBottomSheet<(CareInfo, String?)>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    builder: (_) => const _CarePicker(),
  );
  if (picked == null || !context.mounted) return;
  final store = StoreScope.read(context);
  final p = store.addFromCare(picked.$1, name: picked.$2);
  showGLSnack(context, '${p.name} eklendi. Sulama alarmı kuruldu.');
}

class _CarePicker extends StatefulWidget {
  const _CarePicker();

  @override
  State<_CarePicker> createState() => _CarePickerState();
}

class _CarePickerState extends State<_CarePicker> {
  String _q = '';
  Timer? _debounce;
  bool _searching = false;
  List<TaxonHit> _remote = [];
  int? _adding; // eklenmekte olan iNaturalist kaydı

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String v) {
    setState(() => _q = v.trim().toLowerCase());
    _debounce?.cancel();
    if (_q.length < 3) {
      setState(() {
        _remote = [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      final q = _q;
      setState(() => _searching = true);
      final hits = await PlantInfoService.search(q);
      if (!mounted || q != _q) return;
      setState(() {
        _remote = hits;
        _searching = false;
      });
    });
  }

  Future<void> _pickRemote(TaxonHit h) async {
    setState(() => _adding = h.id);
    final care = await PlantIdService.careFor(IdCandidate(h.scientific, h.trName, null, 1));
    if (!mounted) return;
    final local = CareDb.match(h.scientific);
    Navigator.pop(context, (care, local == null ? h.title : null));
  }

  @override
  Widget build(BuildContext context) {
    final local = CareDb.all
        .where((c) => _q.isEmpty || c.trName.toLowerCase().contains(_q) || c.scientific.toLowerCase().contains(_q))
        .toList();
    final localSci = local.map((c) => c.scientific.toLowerCase()).toSet();
    final remote = _remote.where((h) => !localSci.contains(h.scientific.toLowerCase())).toList();

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .85,
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
              child: Text('Bitki ekle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Hazır listeden seç ya da en az 3 harf yazıp tüm bitkilerde ara.',
                style: TextStyle(fontSize: 12, color: GL.muted),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              autofocus: false,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Örn. orkide, lavanta, begonya…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: GL.forest),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: GL.bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  if (local.isNotEmpty) const _Header('Türkçe bakım rehberi hazır'),
                  for (final c in local)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: SizedBox(
                        width: 44,
                        child: AnimatedPlant(kind: c.kind, leaves: 3, size: 40, sway: false),
                      ),
                      title: Text(c.trName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${c.scientific} · Su: ${c.waterText}', style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.add_circle_rounded, color: GL.forest),
                      onTap: () => Navigator.pop(context, (c, null)),
                    ),
                  if (remote.isNotEmpty) const _Header('Tüm bitkiler · iNaturalist'),
                  for (final h in remote)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: h.thumbUrl == null
                          ? const SizedBox(
                              width: 44,
                              child: AnimatedPlant(kind: PlantKind.leafy, leaves: 3, size: 40, sway: false),
                            )
                          : NetPhoto(h.thumbUrl!, width: 44, height: 44, radius: 12),
                      title: Text(h.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(h.scientific,
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                      trailing: _adding == h.id
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: GL.forest),
                            )
                          : const Icon(Icons.add_circle_outline_rounded, color: GL.forest),
                      onTap: _adding == null ? () => _pickRemote(h) : null,
                    ),
                  if (_q.length >= 3 && !_searching && local.isEmpty && remote.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: Center(
                        child: Text('Sonuç yok. Başka bir ad dene ya da internet bağlantını kontrol et.',
                            textAlign: TextAlign.center, style: TextStyle(color: GL.muted)),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
        child: Text(text.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .8, color: GL.forestMid)),
      );
}
