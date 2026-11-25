import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/plant.dart';
import '../services/photos.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import '../widgets/plant_visual.dart';

/// Büyüme günlüğü: her kaydın fotoğrafı ve boyu; seçilen güne yumuşak geçiş.
class GrowthScreen extends StatefulWidget {
  final String plantId;
  const GrowthScreen({super.key, required this.plantId});

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen> {
  int? _sel;

  Future<void> _addPhoto(Plant p) async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => GlassSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded, color: GL.greenDark),
              title: const Text('Fotoğraf çek'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: GL.greenDark),
              title: const Text('Galeriden seç'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (src == null) return;
    try {
      final path = await PhotoService.pick(src);
      if (path == null || !mounted) return;
      StoreScope.read(context).addGrowth(p, photo: path);
      setState(() => _sel = null);
      showGLSnack(context, 'Bugünün fotoğrafı günlüğe eklendi.');
    } catch (e) {
      if (mounted) showGLSnack(context, 'Fotoğraf alınamadı: $e');
    }
  }

  Future<void> _addHeight(Plant p) async {
    final ctrl = TextEditingController(text: p.currentHeight > 0 ? p.currentHeight.toStringAsFixed(0) : '');
    final cm = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: GlassSheet(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetHandle(),
                const Text('Bugünkü boy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('height-field'),
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  decoration: InputDecoration(
                    suffixText: 'cm',
                    hintText: 'Örn. 24',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                GreenButton(
                  key: const ValueKey('height-save'),
                  label: 'Kaydet',
                  onTap: () => Navigator.pop(ctx, double.tryParse(ctrl.text.replaceAll(',', '.'))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (cm == null || cm <= 0 || !mounted) return;
    StoreScope.read(context).addGrowth(p, cm: cm);
    setState(() => _sel = null);
    showGLSnack(context, 'Boy kaydedildi: ${cm.toStringAsFixed(0)} cm');
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final p = store.byId(widget.plantId);
    if (p == null) return const Scaffold(body: SizedBox.shrink());
    final entries = p.growth.length > 4 ? p.growth.sublist(p.growth.length - 4) : p.growth;
    final sel = entries.isEmpty ? -1 : (_sel ?? entries.length - 1).clamp(0, entries.length - 1);
    final cur = sel < 0 ? null : entries[sel];
    final maxCm = p.growth.fold<double>(0, (m, g) => g.cm > m ? g.cm : m);
    final gain = p.growth.length >= 2 ? p.growth.last.cm - p.growth.first.cm : 0.0;

    return Scaffold(
      body: LeafBackground(
        asset: 'assets/bg/dua.jpg',
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Row(
                children: [
                  GlassIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Geri', onTap: () => Navigator.pop(context)),
                  const Expanded(
                    child: Text('Büyüme günlüğü',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 12),
              Glass(
                padding: const EdgeInsets.all(14),
                child: SizedBox(
                  height: 250,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        right: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(fontSize: 13, color: GL.muted)),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: cur?.cm ?? 0.0),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeOutCubic,
                              builder: (_, v, __) => Text(
                                cur == null || cur.cm == 0 ? '–' : '${v.toStringAsFixed(0)} cm',
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -.5),
                              ),
                            ),
                            Text(cur == null ? 'Henüz kayıt yok' : 'Gün ${p.dayOf(cur)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: GL.greenDark)),
                          ],
                        ),
                      ),
                      Positioned.fill(
                        left: 90,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 700),
                          switchInCurve: Curves.easeOutCubic,
                          transitionBuilder: (child, a) => FadeTransition(
                            opacity: a,
                            child: ScaleTransition(
                              scale: Tween(begin: .9, end: 1.0).animate(a),
                              alignment: Alignment.bottomCenter,
                              child: child,
                            ),
                          ),
                          child: KeyedSubtree(
                            key: ValueKey('${cur?.date.toIso8601String()}-${cur?.photo}'),
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: cur?.photo != null
                                  ? photoOrAsset(cur!.photo!, height: 236, radius: 18)
                                  : PlantVisual(p, height: 236),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (entries.isNotEmpty)
                GlassSegmented(
                  labels: [for (final e in entries) 'Gün ${p.dayOf(e)}'],
                  index: sel,
                  onChanged: (i) => setState(() => _sel = i),
                ),
              const SizedBox(height: 12),
              Glass(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: Text('Boy (cm)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                        if (gain > 0)
                          Text('+${gain.toStringAsFixed(0)} cm',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: GL.greenDark)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (entries.isEmpty || maxCm == 0)
                      const Text('Grafik için "Boy gir" ile ilk ölçümü ekle.', style: TextStyle(fontSize: 13, color: GL.muted))
                    else
                      SizedBox(
                        height: 120,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var i = 0; i < entries.length; i++)
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => setState(() => _sel = i),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(entries[i].cm.toStringAsFixed(0),
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: i == sel ? GL.ink : GL.muted)),
                                        const SizedBox(height: 4),
                                        TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0, end: entries[i].cm / maxCm),
                                          duration: Duration(milliseconds: 700 + i * 140),
                                          curve: Curves.easeOutBack,
                                          builder: (_, t, __) => AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            height: (84 * t).clamp(4.0, 96.0),
                                            decoration: BoxDecoration(
                                              color: i == sel ? GL.green : const Color(0xBFFFFFFF),
                                              borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(10), bottom: Radius.circular(4)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: GreenButton(
                      key: const ValueKey('add-photo'),
                      label: 'Fotoğraf ekle',
                      icon: Icons.photo_camera_rounded,
                      onTap: () => _addPhoto(p),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Glass(
                      key: const ValueKey('add-height'),
                      radius: 18,
                      padding: EdgeInsets.zero,
                      onTap: () => _addHeight(p),
                      child: const SizedBox(
                        height: 52,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.straighten_rounded, size: 19),
                            SizedBox(width: 6),
                            Text('Boy gir', style: TextStyle(fontWeight: FontWeight.w700)),
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
    );
  }
}
