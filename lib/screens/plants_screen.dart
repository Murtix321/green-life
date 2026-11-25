import 'dart:async';

import 'package:flutter/material.dart';

import '../data/care_db.dart';
import '../models/plant.dart';
import '../services/plant_id.dart';
import '../services/plant_info.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import '../widgets/plant_visual.dart';
import 'plant_detail_screen.dart';

class PlantsScreen extends StatelessWidget {
  final VoidCallback onScan;
  const PlantsScreen({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final list = [...store.plants]..sort((a, b) => a.daysUntilWater.compareTo(b.daysUntilWater));
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bitkilerim', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -.5)),
                  Text('${store.plants.length} bitki · ${store.dueToday.length} tanesi bugün su istiyor',
                      style: const TextStyle(fontSize: 13, color: GL.muted)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: GreenButton(label: 'Tara', icon: Icons.center_focus_strong_rounded, height: 48, onTap: onScan)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Glass(
                          key: const ValueKey('plants-add'),
                          radius: 18,
                          padding: EdgeInsets.zero,
                          onTap: () => showAddPlantSheet(context),
                          child: const SizedBox(
                            height: 46,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_rounded, size: 19),
                                SizedBox(width: 6),
                                Text('Bitki ara', style: TextStyle(fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (list.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Henüz bitki yok. Tara ya da ara.', style: TextStyle(color: GL.muted))),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: .74,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Rise(delay: 60 * i, child: _GridCard(plant: list[i])),
                  childCount: list.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  final Plant plant;
  const _GridCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    final p = plant;
    final thirsty = p.needsWaterToday;
    return Glass(
      padding: const EdgeInsets.all(10),
      onTap: () => Navigator.of(context).push(glRoute(PlantDetailScreen(plantId: p.id))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Center(child: PlantVisual(p))),
          const SizedBox(height: 8),
          Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          Text(p.room, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: GL.muted)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.water_drop_rounded, size: 14, color: thirsty ? GL.warnDot : GL.green),
              const SizedBox(width: 4),
              Expanded(
                child: Text(p.waterLabel,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: thirsty ? GL.warn : GL.greenDark)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tarama yapmadan bitki ekleme: hazır Türkçe liste + iNaturalist'te tüm bitkiler.
Future<void> showAddPlantSheet(BuildContext context) async {
  final picked = await showModalBottomSheet<(CareInfo, String?, String?)>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _CarePicker(),
  );
  if (picked == null || !context.mounted) return;
  final p = StoreScope.read(context).addFromCare(picked.$1, name: picked.$2, photo: picked.$3);
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
  int? _adding;

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
    final photo = h.thumbUrl?.replaceAll('/square.', '/medium.');
    Navigator.pop(context, (care, local == null ? h.title : null, local?.image == null ? photo : null));
  }

  @override
  Widget build(BuildContext context) {
    final local = CareDb.all
        .where((c) => _q.isEmpty || c.trName.toLowerCase().contains(_q) || c.scientific.toLowerCase().contains(_q))
        .toList();
    final localSci = local.map((c) => c.scientific.toLowerCase()).toSet();
    final remote = _remote.where((h) => !localSci.contains(h.scientific.toLowerCase())).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .85,
        child: GlassSheet(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetHandle(),
                const Text('Bitki ekle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                const Text('Hazır listeden seç ya da en az 3 harf yazıp tüm bitkilerde ara.',
                    style: TextStyle(fontSize: 12, color: GL.muted)),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('add-search'),
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    hintText: 'Örn. orkide, lavanta, begonya…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: GL.green)),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView(
                    children: [
                      if (local.isNotEmpty) const _Header('Türkçe bakım rehberi hazır'),
                      for (final c in local)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                          leading: SizedBox(
                            width: 48,
                            height: 48,
                            child: c.image != null
                                ? Image.asset(c.image!, fit: BoxFit.contain)
                                : leafPlaceholder(width: 48, height: 48, radius: 14),
                          ),
                          title: Text(c.trName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${c.scientific} · Su: ${c.waterText}', style: const TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.add_circle_rounded, color: GL.green),
                          onTap: () => Navigator.pop(context, (c, null, null)),
                        ),
                      if (remote.isNotEmpty) const _Header('Tüm bitkiler · iNaturalist'),
                      for (final h in remote)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                          leading: h.thumbUrl == null
                              ? leafPlaceholder(width: 48, height: 48, radius: 14)
                              : photoOrAsset(h.thumbUrl!, width: 48, height: 48, radius: 14),
                          title: Text(h.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(h.scientific, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                          trailing: _adding == h.id
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: GL.green))
                              : const Icon(Icons.add_circle_outline_rounded, color: GL.green),
                          onTap: _adding == null ? () => _pickRemote(h) : null,
                        ),
                      if (_q.length >= 3 && !_searching && local.isEmpty && remote.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 30),
                          child: Text('Sonuç yok. Başka bir ad dene ya da internet bağlantını kontrol et.',
                              textAlign: TextAlign.center, style: TextStyle(color: GL.muted)),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
        padding: const EdgeInsets.fromLTRB(2, 12, 2, 4),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: GL.greenDark)),
      );
}
