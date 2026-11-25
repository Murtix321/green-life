import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/plant.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/animated_plant.dart';
import '../widgets/common.dart';
import '../widgets/plant_info_card.dart';

/// Bakım içgörüleri: gün gün büyüme animasyonu, boy grafiği, sulama.
class PlantDetailScreen extends StatefulWidget {
  final String plantId;
  const PlantDetailScreen({super.key, required this.plantId});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  int? _sel; // seçili büyüme kaydı (null = en son)

  static const _notes = [
    'İlk ölçüm. Bitkin yeni evine alışıyor.',
    'Yeni yaprak hazırlığı var. Toprağı hafif nemli tut.',
    'Kökler güçleniyor, büyüme hızlandı.',
    'Gür ve sağlıklı görünüyor. Böyle devam!',
  ];

  Future<void> _addHeight(Plant p) async {
    final ctrl = TextEditingController(text: p.currentHeight > 0 ? p.currentHeight.toStringAsFixed(0) : '');
    final cm = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: const Text('Bugünkü boy', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          decoration: const InputDecoration(suffixText: 'cm', hintText: 'Örn. 24'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GL.forest),
            onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text.replaceAll(',', '.'))),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (cm == null || cm <= 0 || !mounted) return;
    StoreScope.read(context).addHeight(p, cm);
    setState(() => _sel = null);
    showGLSnack(context, 'Boy kaydedildi: ${cm.toStringAsFixed(0)} cm');
  }

  Future<void> _more(Plant p) async {
    final store = StoreScope.read(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.schedule_rounded, color: GL.forest),
              title: Text('Sulama aralığı: ${p.waterEveryDays} gün'),
              subtitle: const Text('Değiştirmek için dokun'),
              onTap: () => Navigator.pop(ctx, 'interval'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFB3261E)),
              title: const Text('Bitkiyi sil', style: TextStyle(color: Color(0xFFB3261E))),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'delete') {
      store.remove(p);
      Navigator.pop(context);
    } else if (action == 'interval') {
      var days = p.waterEveryDays;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, set) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Kaç günde bir sulansın?'),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => set(() => days = (days - 1).clamp(1, 60)),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$days gün', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                IconButton(
                  onPressed: () => set(() => days = (days + 1).clamp(1, 60)),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: GL.forest),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      );
      if (ok == true) store.updatePlant(p, waterEveryDays: days);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final p = store.byId(widget.plantId);
    if (p == null) return const Scaffold(body: SizedBox.shrink());

    // Son 4 ölçüm "Gün N" sekmeleri olur.
    final entries = p.growth.length > 4 ? p.growth.sublist(p.growth.length - 4) : p.growth;
    final maxCm = p.growth.fold<double>(0, (m, g) => g.cm > m ? g.cm : m);
    final sel = entries.isEmpty ? -1 : (_sel ?? entries.length - 1).clamp(0, entries.length - 1);
    final cur = sel < 0 ? null : entries[sel];
    final scale = cur == null || maxCm == 0 ? 1.0 : (0.55 + 0.45 * (cur.cm / maxCm));
    final leaves = cur == null ? 3 : Plant.leavesFor(cur.cm, maxCm);
    final note = cur == null
        ? 'Henüz boy ölçümü yok. Cetvelle ölç ve "Boy ekle"ye dokun; büyümesini gün gün izleyelim.'
        : _notes[(sel * _notes.length ~/ entries.length).clamp(0, _notes.length - 1)];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Row(
              children: [
                RoundIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Geri',
                  onTap: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const Text('Bakım içgörüleri', style: TextStyle(fontSize: 12, color: GL.muted)),
                    ],
                  ),
                ),
                RoundIconButton(icon: Icons.more_horiz_rounded, tooltip: 'Diğer', onTap: () => _more(p)),
              ],
            ),
            const SizedBox(height: 14),

            // Gün seçici
            if (entries.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: GL.mintSoft, borderRadius: BorderRadius.circular(24)),
                child: Row(
                  children: [
                    for (var i = 0; i < entries.length; i++)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _sel = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 380),
                            curve: Curves.easeOutCubic,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: i == sel ? GL.forest : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Gün ${p.dayOf(entries[i])}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: i == sel ? Colors.white : const Color(0xFF2C4636),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // Boy + büyüyen bitki
            GLCard(
              child: SizedBox(
                height: 190,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Boy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: GL.muted)),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: cur?.cm ?? 0.0),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, __) => Text(
                              cur == null ? '–' : '${v.toStringAsFixed(0)} cm',
                              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, height: 1.1),
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: Text(
                              note,
                              key: ValueKey(note),
                              style: const TextStyle(fontSize: 12, height: 1.45, color: GL.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Hero(
                      tag: 'plant-${p.id}',
                      child: AnimatedPlant(kind: p.kind, leaves: leaves, scale: scale, size: 140),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Büyüme grafiği
            GLCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Büyüme (cm)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                      ),
                      if (p.growth.length >= 2)
                        Text(
                          '+${(p.growth.last.cm - p.growth.first.cm).toStringAsFixed(0)} cm',
                          style: const TextStyle(color: GL.forestMid, fontWeight: FontWeight.w800),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (entries.isEmpty)
                    const Text('Grafik için en az bir ölçüm ekle.', style: TextStyle(color: GL.muted, fontSize: 13))
                  else
                    _Bars(entries: entries, maxCm: maxCm, selected: sel, dayOf: p.dayOf, onTap: (i) => setState(() => _sel = i)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    icon: Icons.wb_sunny_rounded,
                    color: GL.sun,
                    label: 'Işık',
                    value: p.light,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.water_drop_rounded,
                    color: GL.water,
                    label: 'Sonraki su',
                    value: p.waterLabel,
                    sub: '${store.alarmTimeText} alarm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GLCard(
              color: GL.mintPale,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: GL.forest),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${p.tip}\nSıcaklık: ${p.temperature} · ${p.waterEveryDays} günde bir sulama',
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PlantAboutCard(scientific: p.scientific),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: p.wateredToday ? 'Bugün sulandı' : 'Sulandı',
                    leading: const Icon(Icons.water_drop_rounded, size: 20),
                    onTap: p.wateredToday
                        ? null
                        : () {
                            store.water(p);
                            showGLSnack(context, 'Harika! Sonraki sulama ${p.waterEveryDays} gün sonra.');
                          },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'Boy ekle',
                    bg: GL.mintSoft,
                    fg: GL.forest,
                    leading: const Icon(Icons.straighten_rounded, size: 20),
                    onTap: () => _addHeight(p),
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

class _Bars extends StatelessWidget {
  final List<GrowthEntry> entries;
  final double maxCm;
  final int selected;
  final int Function(GrowthEntry) dayOf;
  final ValueChanged<int> onTap;

  const _Bars({
    required this.entries,
    required this.maxCm,
    required this.selected,
    required this.dayOf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < entries.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        entries[i].cm.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: i == selected ? GL.ink : GL.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: maxCm == 0 ? 0.0 : entries[i].cm / maxCm),
                        duration: Duration(milliseconds: 700 + i * 150),
                        curve: Curves.easeOutBack,
                        builder: (_, t, __) => AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          height: (86 * t).clamp(4.0, 96.0),
                          decoration: BoxDecoration(
                            color: i == selected
                                ? GL.forest
                                : (i < selected ? const Color(0xFF8FC7A1) : const Color(0xFFD6E8DB)),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10), bottom: Radius.circular(4)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Gün ${dayOf(entries[i])}', style: const TextStyle(fontSize: 11, color: GL.muted)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? sub;

  const _MiniStat({required this.icon, required this.color, required this.label, required this.value, this.sub});

  @override
  Widget build(BuildContext context) {
    return GLCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12, color: GL.muted)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, maxLines: 2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.2)),
          if (sub != null) Text(sub!, style: const TextStyle(fontSize: 11, color: GL.muted)),
        ],
      ),
    );
  }
}
