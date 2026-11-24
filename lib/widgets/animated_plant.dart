import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../theme.dart';

/// Canlı bitki çizimi:
/// - hafif rüzgârda sallanma (sürekli),
/// - yaprakların sırayla "pıt" diye açılması (ilk görünüşte),
/// - [leaves] veya [scale] değişince yumuşak büyüme/küçülme.
class AnimatedPlant extends StatefulWidget {
  final PlantKind kind;
  final int leaves; // 1..5
  final double scale; // 0.4..1
  final double size; // genişlik (yükseklik = 1.2x)
  final bool sway;
  final Color potColor;
  final Color rimColor;

  const AnimatedPlant({
    super.key,
    this.kind = PlantKind.monstera,
    this.leaves = 5,
    this.scale = 1,
    this.size = 200,
    this.sway = true,
    this.potColor = GL.potShade,
    this.rimColor = Colors.white,
  });

  @override
  State<AnimatedPlant> createState() => _AnimatedPlantState();
}

class _AnimatedPlantState extends State<AnimatedPlant> with SingleTickerProviderStateMixin {
  late final AnimationController _sway = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.sway) _sway.repeat();
  }

  @override
  void dispose() {
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.size;
    final h = w * 1.2;
    return SizedBox(
      width: w,
      height: h,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: widget.leaves.toDouble()),
        duration: Duration(milliseconds: 500 + widget.leaves * 260),
        curve: Curves.easeInOut,
        builder: (context, growth, _) => TweenAnimationBuilder<double>(
          tween: Tween(begin: widget.scale * 0.85, end: widget.scale),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutBack,
          builder: (context, scale, _) => AnimatedBuilder(
            animation: _sway,
            builder: (context, _) => CustomPaint(
              painter: _PlantPainter(
                kind: widget.kind,
                growth: growth,
                scale: scale,
                sway: math.sin(_sway.value * 2 * math.pi),
                pot: widget.potColor,
                rim: widget.rimColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Leaf {
  final double angle; // derece
  final double stem;
  final double size;
  final Color color;
  const _Leaf(this.angle, this.stem, this.size, this.color);
}

class _PlantPainter extends CustomPainter {
  final PlantKind kind;
  final double growth;
  final double scale;
  final double sway;
  final Color pot;
  final Color rim;

  _PlantPainter({
    required this.kind,
    required this.growth,
    required this.scale,
    required this.sway,
    required this.pot,
    required this.rim,
  });

  static const _monstera = [
    _Leaf(-4, 62, 1, GL.forest),
    _Leaf(-38, 46, 1, GL.leafDark),
    _Leaf(36, 50, 1, GL.leaf),
    _Leaf(-72, 40, .8, GL.leafLight),
    _Leaf(70, 40, .8, GL.leafDark),
  ];

  static const _snake = [
    _Leaf(0, 0, 1.0, GL.forestMid),
    _Leaf(-13, 0, .86, GL.leaf),
    _Leaf(14, 0, .9, GL.leafDark),
    _Leaf(-25, 0, .66, GL.leafLight),
    _Leaf(26, 0, .7, GL.leaf),
  ];

  static const _leafy = [
    _Leaf(0, 58, .9, GL.leafDark),
    _Leaf(-34, 44, .85, GL.leaf),
    _Leaf(32, 46, .85, GL.forestMid),
    _Leaf(-62, 34, .7, GL.leafLight),
    _Leaf(60, 34, .7, GL.leaf),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / 200, size.height / 240);
    canvas.save();
    canvas.translate((size.width - 200 * s) / 2, size.height - 240 * s);
    canvas.scale(s);

    // gölge
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 234), width: 116, height: 12),
      Paint()..color = GL.ink.withOpacity(0.12),
    );

    // bitki (saksının içinden çıkar, tabandan ölçeklenir)
    canvas.save();
    canvas.translate(100, 172);
    canvas.scale(scale);
    canvas.rotate(sway * 0.04);
    final leaves = switch (kind) {
      PlantKind.monstera => _monstera,
      PlantKind.snake => _snake,
      PlantKind.leafy => _leafy,
    };
    for (var i = 0; i < leaves.length; i++) {
      final g = (growth - i).clamp(0.0, 1.0);
      if (g <= 0) continue;
      final t = Curves.easeOutBack.transform(g);
      final l = leaves[i];
      canvas.save();
      // her yaprak kendi ritminde hafifçe salınır
      canvas.rotate((l.angle + sway * (2 + i)) * math.pi / 180);
      canvas.scale(l.size * t);
      if (kind == PlantKind.snake) {
        _blade(canvas, l.color);
      } else {
        _stemLeaf(canvas, l, kind == PlantKind.monstera);
      }
      canvas.restore();
    }
    canvas.restore();

    // saksı
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(56, 164, 88, 16), const Radius.circular(8)),
      Paint()..color = rim,
    );
    final body = Path()
      ..moveTo(62, 178)
      ..lineTo(138, 178)
      ..lineTo(130, 230)
      ..quadraticBezierTo(129, 234, 125, 234)
      ..lineTo(75, 234)
      ..quadraticBezierTo(71, 234, 70, 230)
      ..close();
    canvas.drawPath(body, Paint()..color = pot);
    canvas.restore();
  }

  void _stemLeaf(Canvas c, _Leaf l, bool slits) {
    c.drawLine(
      Offset.zero,
      Offset(0, -l.stem),
      Paint()
        ..color = GL.forestMid
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
    c.save();
    c.translate(0, -l.stem + 2);
    final leaf = Path()
      ..moveTo(0, 0)
      ..cubicTo(-26, -14, -30, -52, 0, -74)
      ..cubicTo(30, -52, 26, -14, 0, 0)
      ..close();
    c.drawPath(leaf, Paint()..color = l.color);
    final rib = Paint()
      ..color = GL.mint
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawLine(const Offset(0, -4), const Offset(0, -66), rib);
    if (slits) {
      for (final y in [-22.0, -40.0]) {
        c.drawLine(Offset(0, y), Offset(-13, y - 8), rib);
        c.drawLine(Offset(0, y), Offset(13, y - 8), rib);
      }
    }
    c.restore();
  }

  void _blade(Canvas c, Color color) {
    const len = 118.0;
    final p = Path()
      ..moveTo(-7, 6)
      ..cubicTo(-16, -len * .35, -12, -len * .75, 0, -len)
      ..cubicTo(12, -len * .75, 16, -len * .35, 7, 6)
      ..close();
    c.drawPath(p, Paint()..color = color);
    final band = Paint()
      ..color = GL.mint.withOpacity(.45)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final y in [-30.0, -55.0, -80.0]) {
      c.drawLine(Offset(-8, y), Offset(8, y - 4), band);
    }
  }

  @override
  bool shouldRepaint(_PlantPainter o) =>
      o.growth != growth || o.scale != scale || o.sway != sway || o.kind != kind;
}
