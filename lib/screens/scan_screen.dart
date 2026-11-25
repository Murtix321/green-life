import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
import 'plants_screen.dart';

enum _Phase { idle, scanning, result, error }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  late final AnimationController _breath =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
  late final AnimationController _line =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

  _Phase _phase = _Phase.idle;
  File? _image;
  List<IdCandidate> _candidates = [];
  int _selected = 0;
  CareInfo? _care;
  PlantInfo? _info;
  String _error = '';

  @override
  void dispose() {
    _breath.dispose();
    _line.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource src) async {
    try {
      final x = await ImagePicker().pickImage(source: src, maxWidth: 1280, imageQuality: 85);
      if (x == null) return;
      setState(() {
        _image = File(x.path);
        _phase = _Phase.scanning;
      });
      final list = await PlantIdService.identify(_image!);
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
    setState(() => _selected = i);
    setState(() => _info = null);
    _loadInfo(_candidates[i].scientific);
    final care = await PlantIdService.careFor(_candidates[i]);
    if (mounted) setState(() => _care = care);
  }

  /// iNaturalist + Wikipedia: Türkçe ad ve karşılaştırma fotoğrafı (arka planda).
  Future<void> _loadInfo(String sci) async {
    final info = await PlantInfoService.fetch(sci);
    if (!mounted || _candidates.isEmpty || _candidates[_selected].scientific != sci) return;
    setState(() => _info = info);
  }

  void _add() {
    final c = _candidates[_selected];
    final care = _care!;
    final store = StoreScope.read(context);
    final local = CareDb.match(c.scientific, family: c.family);
    final p = store.addFromCare(
      care,
      name: local == null ? (_info?.trName ?? c.commonName ?? c.scientific) : null,
    );
    Navigator.of(context).pushReplacement(glRoute(PlantDetailScreen(plantId: p.id)));
    showGLSnack(context, '${p.name} bahçene eklendi. Sulama alarmı kuruldu.');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final frameH = size.height * .40;
    return Scaffold(
      backgroundColor: GL.ink,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -.35),
                  radius: 1.0,
                  colors: [Color(0xFF4E8D63), Color(0xFF2A5B3C), GL.ink],
                  stops: [0, .45, .85],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                  child: Row(
                    children: [
                      RoundIconButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Kapat',
                        bg: Colors.white24,
                        fg: Colors.white,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Bitki tanıma',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Tarama çerçevesi
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: _breath, curve: Curves.easeInOut)),
                  child: Container(
                    height: frameH,
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white54, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: _image == null
                                ? const Align(
                                    key: ValueKey('ph'),
                                    alignment: Alignment.bottomCenter,
                                    child: AnimatedPlant(
                                      kind: PlantKind.monstera,
                                      size: 200,
                                      potColor: Color(0xFFE6E9E2),
                                    ),
                                  )
                                : Image.file(_image!, key: ValueKey(_image!.path), fit: BoxFit.cover),
                          ),
                          if (_phase == _Phase.scanning)
                            AnimatedBuilder(
                              animation: _line,
                              builder: (_, __) => Align(
                                alignment: Alignment(0, -0.9 + 1.8 * Curves.easeInOut.transform(_line.value)),
                                child: Container(
                                  height: 3,
                                  margin: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC9F2D3),
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: const [
                                      BoxShadow(color: Color(0xB3C9F2D3), blurRadius: 18, spreadRadius: 6),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    switch (_phase) {
                      _Phase.idle => 'Yaprakları çerçevenin içinde tut',
                      _Phase.scanning => 'Yapraklar inceleniyor…',
                      _Phase.result => 'Tanındı!',
                      _Phase.error => 'Bir sorun oldu',
                    },
                    key: ValueKey(_phase),
                    style: const TextStyle(color: Color(0xFFD8EEDD), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          // Alttaki panel: aşağıdan kayarak gelir
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 550),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, a) => SlideTransition(
                position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(a),
                child: child,
              ),
              child: KeyedSubtree(key: ValueKey(_phase), child: _sheet()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheet() {
    Widget wrap(List<Widget> children) => Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.paddingOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFD3DED6), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              ...children,
            ],
          ),
        );

    switch (_phase) {
      case _Phase.idle:
        return wrap([
          const Text('Bitkini tanıyalım', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text(
            'Net, aydınlık bir yaprak fotoğrafı en iyi sonucu verir.',
            style: TextStyle(color: GL.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Fotoğraf çek',
            leading: const Icon(Icons.photo_camera_rounded, size: 20),
            onTap: () => _pick(ImageSource.camera),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Galeriden seç',
            bg: GL.mintSoft,
            fg: GL.forest,
            height: 50,
            leading: const Icon(Icons.photo_library_rounded, size: 20),
            onTap: () => _pick(ImageSource.gallery),
          ),
        ]);
      case _Phase.scanning:
        return wrap([
          const Row(
            children: [
              SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: GL.forest)),
              SizedBox(width: 12),
              Expanded(child: Text('Bitkin tanınıyor…', style: TextStyle(fontWeight: FontWeight.w700))),
            ],
          ),
        ]);
      case _Phase.error:
        return wrap([
          Text(_error, style: const TextStyle(fontSize: 14, height: 1.5)),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Tekrar dene', onTap: () => setState(() => _phase = _Phase.idle)),
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Listeden seç',
            bg: GL.mintSoft,
            fg: GL.forest,
            height: 50,
            onTap: () async {
              final nav = Navigator.of(context);
              await showAddFromListSheet(context);
              if (mounted) nav.pop();
            },
          ),
        ]);
      case _Phase.result:
        final c = _candidates[_selected];
        final care = _care;
        return wrap([
          Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                child: _info?.photoUrl == null
                    ? const SizedBox(key: ValueKey('np'), width: 0)
                    : Padding(
                        key: ValueKey(_info!.photoUrl),
                        padding: const EdgeInsets.only(right: 12),
                        child: NetPhoto(_info!.photoUrl!, width: 58, height: 58, radius: 16),
                      ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _info?.trName ?? c.commonName ?? c.scientific,
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      [c.scientific, if (c.family != null) c.family!].join(' · '),
                      style: const TextStyle(fontSize: 13, color: GL.muted),
                    ),
                  ],
                ),
              ),
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: GL.mintSoft, borderRadius: BorderRadius.circular(15)),
                child: Text('%${c.percent}',
                    style: const TextStyle(color: GL.forest, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ],
          ),
          if (_candidates.length > 1) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (var i = 0; i < _candidates.length; i++)
                  ChoiceChip(
                    label: Text('${_candidates[i].scientific} %${_candidates[i].percent}'),
                    selected: i == _selected,
                    onSelected: (_) => _choose(i),
                    selectedColor: GL.mint,
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (care != null) ...[
            _careRow(Icons.water_drop_rounded, GL.water, 'Sulama', care.waterText),
            _careRow(Icons.wb_sunny_rounded, GL.sun, 'Işık', care.light),
            _careRow(Icons.thermostat_rounded, GL.temp, 'Sıcaklık', care.temperature),
          ],
          const SizedBox(height: 14),
          PrimaryButton(label: 'Bitkilerime ekle ve hatırlatıcı kur', onTap: care == null ? null : _add),
        ]);
    }
  }

  Widget _careRow(IconData icon, Color color, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            SizedBox(width: 70, child: Text(label, style: const TextStyle(color: GL.muted, fontSize: 13))),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
          ],
        ),
      );
}
