import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Beyaz yuvarlak kart (Konsept 2'nin temel yüzeyi).
class GLCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const GLCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(GL.radius),
        boxShadow: GL.softShadow,
      ),
      child: child,
    );
    if (onTap == null) return box;
    return _Pressable(onTap: onTap!, child: box);
  }
}

/// Basınca hafifçe küçülen dokunma efekti.
class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Pressable({required this.child, required this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Yuvarlak ikon düğmesi (geri, bildirim, takvim).
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color bg;
  final Color fg;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.bg = Colors.white,
    this.fg = GL.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        elevation: 0,
        shadowColor: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 20, color: fg)),
        ),
      ),
    );
  }
}

/// Koyu yeşil ana düğme.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? leading;
  final bool busy;
  final Color bg;
  final Color fg;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.leading,
    this.busy = false,
    this.bg = GL.forest,
    this.fg = Colors.white,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withOpacity(.7),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: busy
              ? SizedBox(
                  key: const ValueKey('busy'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leading != null) ...[leading!, const SizedBox(width: 10)],
                    Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Animasyonla dolan sağlık puanı halkası.
class HealthRing extends StatelessWidget {
  final int score;
  final double size;
  const HealthRing({super.key, required this.score, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score.toDouble()),
      duration: const Duration(milliseconds: 1600),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(v / 100),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  v.round().toString(),
                  style: TextStyle(fontSize: size * .27, fontWeight: FontWeight.w800, height: 1),
                ),
                Text('/100', style: TextStyle(fontSize: size * .115, color: GL.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double t;
  _RingPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * .094;
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = GL.mintSoft
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * t.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = t < .5 ? GL.warnDot : GL.leaf
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.t != t;
}

/// Yukarı süzülerek beliren içerik (sıralı giriş animasyonu için [delay]).
class Rise extends StatefulWidget {
  final Widget child;
  final int delay; // ms
  const Rise({super.key, required this.child, this.delay = 0});

  @override
  State<Rise> createState() => _RiseState();
}

class _RiseState extends State<Rise> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, .12), end: Offset.zero).animate(a),
        child: widget.child,
      ),
    );
  }
}

/// Yukarı aşağı hafifçe zıplayan su damlası.
class BouncingDrop extends StatefulWidget {
  final double size;
  final Color color;
  const BouncingDrop({super.key, this.size = 18, this.color = GL.water});

  @override
  State<BouncingDrop> createState() => _BouncingDropState();
}

class _BouncingDropState extends State<BouncingDrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -5 * math.sin(_c.value * math.pi * 2).abs()),
        child: child,
      ),
      child: Icon(Icons.water_drop_rounded, size: widget.size, color: widget.color),
    );
  }
}

/// Bölüm başlığı + sağda bağlantı.
class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: GL.forestMid),
            child: Text(action!, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

void showGLSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
}
