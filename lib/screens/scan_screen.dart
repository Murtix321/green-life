import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/care_db.dart';
import '../services/photos.dart';
import '../services/plant_id.dart';
import '../services/plant_info.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import '../widgets/plant_visual.dart';
import 'plant_detail_screen.dart';
import 'plants_screen.dart';

enum _Phase { idle, scanning, result, error }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  late final AnimationController _line;

  @override
  void initState() {
    super.initState();
    _line = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
  }

  _Phase _phase = _Phase.idle;
  String? _image;
  List<IdCandidate> _candidates = [];
  int _selected = 0;
  CareInfo? _care;
  PlantInfo? _info;
  String _error = '';

  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource src) async {
    try {
      final path = await PhotoService.pick(src);
      if (path == null) return;
      setState(() {
        _image = path;
        _phase = _Phase.scanning;
      });
      final list = await PlantIdService.identify(File(path));
      final care = await PlantIdService.careFor(list.first);
      if (!mounted) return;
      setState(() {
        _candidates = list;
        _selected = 0;
        _care = care;
        _info = null;
        _phase = _Phase.result;
      });
      _loadInfo(list.first.scientific);
    } on PlantIdException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail('Fotoğraf alınamadı: $e');
    }
  }

  void _fail(String msg) {
    if (!mounted) return;
    setState(() {
      _error = msg;
      _phase = _Phase.error;
    });
  }

  Future<void> _choose(int i) async {
    setState(() {
      _selected = i;
      _info = null;
    });
    _loadInfo(_candidates[i].scientific);
    final care = await PlantIdService.careFor(_candidates[i]);
    if (mounted) setState(() => _care = care);
  }

  Future<void> _loadInfo(String sci) async {
    final info = await PlantInfoService.fetch(sci);
    if (!mounted || _candidates.isEmpty || _candidates[_selected].scientific != sci) return;
    setState(() => _info = info);
  }

  void _add() {
    final c = _candidates[_selected];
    final local = CareDb.match(c.scientific, family: c.family);
    final p = StoreScope.read(context).addFromCare(
      _care!,
      name: local == null ? (_info?.trName ?? c.commonName ?? c.scientific) : null,
      photo: _image,
    );
    Navigator.of(context).pushReplacement(glRoute(PlantDetailScreen(plantId: p.id)));
    showGLSnack(context, '${p.name} bahçene eklendi. Sulama alarmı kuruldu.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LeafBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    GlassIconButton(icon: Icons.close_rounded, tooltip: 'Kapat', onTap: () => Navigator.pop(context)),
                    const Expanded(
                      child: Text('Bitkini tanıyalım',
                          textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(child: _frame()),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(position: Tween(begin: const Offset(0, .15), end: Offset.zero).animate(a), child: child),
                  ),
                  child: KeyedSubtree(key: ValueKey(_phase), child: _panel()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _frame() {
    return Glass(
      radius: 34,
      padding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _image == null
                ? Padding(
                    key: const ValueKey('ph'),
                    padding: const EdgeInsets.all(36),
                    child: FloatY(child: Image.asset('assets/plants/pothos.webp', fit: BoxFit.contain)),
                  )
                : ClipRRect(
                    key: ValueKey(_image),
                    borderRadius: BorderRadius.circular(33),
                    child: Image.file(File(_image!), fit: BoxFit.cover),
                  ),
          ),
          for (final a in const [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight])
            Align(alignment: a, child: Padding(padding: const EdgeInsets.all(14), child: _Corner(alignment: a))),
          if (_phase == _Phase.scanning)
            AnimatedBuilder(
              animation: _line,
              builder: (_, __) => Align(
                alignment: Alignment(0, -0.85 + 1.7 * Curves.easeInOut.transform(_line.value)),
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: const [BoxShadow(color: Color(0xCCFFFFFF), blurRadius: 16, spreadRadius: 4)],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _panel() {
    switch (_phase) {
      case _Phase.idle:
        return Column(
          children: [
            const Text('Net ve aydınlık bir yaprak fotoğrafı en iyi sonucu verir.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: GL.muted)),
            const SizedBox(height: 12),
            GreenButton(
              key: const ValueKey('scan-camera'),
              label: 'Fotoğraf çek',
              icon: Icons.photo_camera_rounded,
              onTap: () => _pick(ImageSource.camera),
            ),
            const SizedBox(height: 10),
            Glass(
              radius: 18,
              padding: EdgeInsets.zero,
              onTap: () => _pick(ImageSource.gallery),
              child: const SizedBox(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library_rounded, size: 19),
                    SizedBox(width: 8),
                    Text('Galeriden seç', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        );
      case _Phase.scanning:
        return const Glass(
          child: Row(
            children: [
              SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: GL.green)),
              SizedBox(width: 12),
              Expanded(child: Text('Yapraklar inceleniyor…', style: TextStyle(fontWeight: FontWeight.w700))),
            ],
          ),
        );
      case _Phase.error:
        return Column(
          children: [
            Glass(child: Text(_error, style: const TextStyle(fontSize: 14, height: 1.5))),
            const SizedBox(height: 10),
            GreenButton(label: 'Tekrar dene', onTap: () => setState(() => _phase = _Phase.idle)),
            const SizedBox(height: 10),
            Glass(
              radius: 18,
              padding: EdgeInsets.zero,
              onTap: () async {
                final nav = Navigator.of(context);
                await showAddPlantSheet(context);
                if (mounted) nav.pop();
              },
              child: const SizedBox(height: 50, child: Center(child: Text('Listeden seç', style: TextStyle(fontWeight: FontWeight.w700)))),
            ),
          ],
        );
      case _Phase.result:
        final c = _candidates[_selected];
        final care = _care;
        return Column(
          children: [
            Glass(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_info?.photoUrl != null) ...[
                        photoOrAsset(_info!.photoUrl!, width: 50, height: 50, radius: 14),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_info?.trName ?? c.commonName ?? c.scientific,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                            Text(c.scientific, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: GL.muted)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: GL.green, borderRadius: BorderRadius.circular(12)),
                        child: Text('%${c.percent}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ],
                  ),
                  if (_candidates.length > 1) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (var i = 0; i < _candidates.length; i++)
                          ChoiceChip(
                            label: Text('${_candidates[i].scientific} %${_candidates[i].percent}'),
                            selected: i == _selected,
                            onSelected: (_) => _choose(i),
                            selectedColor: const Color(0xFFCFE6D5),
                            labelStyle: const TextStyle(fontSize: 11),
                          ),
                      ],
                    ),
                  ],
                  if (care != null) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Chip('Su · ${care.waterText}'),
                        _Chip(care.light),
                        _Chip(care.temperature),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            GreenButton(label: 'Bitkilerime ekle · alarm kur', onTap: care == null ? null : _add),
          ],
        );
    }
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);

  @override
  Widget build(BuildContext context) => Glass(
        radius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(text, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
      );
}

class _Corner extends StatelessWidget {
  final Alignment alignment;
  const _Corner({required this.alignment});

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: Colors.white, width: 3);
    final top = alignment.y < 0, left = alignment.x < 0;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border(
          top: top ? side : BorderSide.none,
          bottom: top ? BorderSide.none : side,
          left: left ? side : BorderSide.none,
          right: left ? BorderSide.none : side,
        ),
      ),
    );
  }
}
