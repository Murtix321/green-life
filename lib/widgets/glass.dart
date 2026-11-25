import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Buzlu cam yüzey: arkadaki görüntüyü bulanıklaştırır, üstüne yarı saydam beyaz koyar.
class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color fill;
  final VoidCallback? onTap;
  final double blur;

  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 22,
    this.fill = GL.glassFill,
    this.onTap,
    this.blur = 18,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    Widget box = ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: r,
            border: Border.all(color: GL.glassBorder),
          ),
          child: child,
        ),
      ),
    );
    box = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(color: GL.ink.withOpacity(.10), blurRadius: 26, offset: const Offset(0, 10), spreadRadius: -10),
        ],
      ),
      child: box,
    );
    if (onTap == null) return box;
    return Pressable(onTap: onTap!, child: box);
  }
}

/// Basınca hafifçe küçülen dokunma efekti.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const Pressable({super.key, required this.child, required this.onTap});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
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
        duration: const Duration(milliseconds: 150),
        child: widget.child,
      ),
    );
  }
}

/// Arkada yavaşça kayan, bulanık gerçek yaprak fotoğrafı.
class LeafBackground extends StatefulWidget {
  final String asset;
  final Widget child;
  const LeafBackground({super.key, this.asset = 'assets/bg/yaprak.jpg', required this.child});

  @override
  State<LeafBackground> createState() => _LeafBackgroundState();
}

class _LeafBackgroundState extends State<LeafBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 22));

  @override
  void initState() {
    super.initState();
    _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: GL.mint),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, child) {
              final t = Curves.easeInOut.transform(_c.value);
              return Transform.translate(
                offset: Offset(-14 * t, 10 * t),
                child: Transform.scale(scale: 1.08 + .06 * t, child: child),
              );
            },
            child: Image.asset(widget.asset, fit: BoxFit.cover),
          ),
        ),
        widget.child,
      ],
    );
  }
}

/// Yuvarlak cam ikon düğmesi.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;
  const GlassIconButton({super.key, required this.icon, required this.tooltip, required this.onTap, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Glass(
          radius: size / 2,
          padding: EdgeInsets.zero,
          onTap: onTap,
          child: SizedBox(width: size - 2, height: size - 2, child: Icon(icon, size: 20, color: GL.ink)),
        ),
      ),
    );
  }
}

/// Yeşil ana düğme.
class GreenButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Widget? leading;
  final bool busy;
  final double height;
  final Color color;

  const GreenButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.leading,
    this.busy = false,
    this.height = 54,
    this.color = GL.green,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(.65),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontFamily: GL.font, fontWeight: FontWeight.w700, fontSize: 15),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: busy
              ? const SizedBox(
                  key: ValueKey('busy'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                )
              : Row(
                  key: ValueKey(label),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leading != null) ...[leading!, const SizedBox(width: 10)],
                    if (icon != null) ...[Icon(icon, size: 19), const SizedBox(width: 8)],
                    Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Yukarı süzülerek beliren içerik.
class Rise extends StatefulWidget {
  final Widget child;
  final int delay;
  const Rise({super.key, required this.child, this.delay = 0});

  @override
  State<Rise> createState() => _RiseState();
}

class _RiseState extends State<Rise> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

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
        position: Tween(begin: const Offset(0, .1), end: Offset.zero).animate(a),
        child: widget.child,
      ),
    );
  }
}

/// Hafifçe yukarı aşağı süzülme (bitki görselleri için).
class FloatY extends StatefulWidget {
  final Widget child;
  final double amount;
  const FloatY({super.key, required this.child, this.amount = 6});

  @override
  State<FloatY> createState() => _FloatYState();
}

class _FloatYState extends State<FloatY> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void initState() {
    super.initState();
    _c.repeat();
  }

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
        offset: Offset(0, -widget.amount * (0.5 - 0.5 * math.cos(_c.value * 2 * math.pi))),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Kayan seçili hap ile cam sekme seçici (Bugün / Yaklaşan / Tamamlanan gibi).
class GlassSegmented extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const GlassSegmented({super.key, required this.labels, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(4),
      radius: 22,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / labels.length;
          return SizedBox(
            height: 40,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  left: w * index,
                  top: 0,
                  bottom: 0,
                  width: w,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: GL.green, borderRadius: BorderRadius.circular(18)),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: i == index,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => onChanged(i),
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: TextStyle(
                                  fontFamily: GL.font,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: i == index ? Colors.white : GL.ink,
                                ),
                                child: Text(labels[i]),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Animasyonlu tik kutusu (bakım görevleri).
class CheckCircle extends StatelessWidget {
  final bool done;
  final VoidCallback? onTap;
  final String label;
  const CheckCircle({super.key, required this.done, required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: done,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? GL.green : const Color(0x66FFFFFF),
            border: Border.all(color: done ? GL.green : GL.ink.withOpacity(.35), width: 2),
          ),
          child: AnimatedScale(
            scale: done ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

void showGLSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text, style: const TextStyle(fontFamily: GL.font)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
}

/// Alt sayfa (bottom sheet) için cam kap.
class GlassSheet extends StatelessWidget {
  final Widget child;
  const GlassSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xE6F4F8F4),
            border: Border(top: BorderSide(color: Colors.white)),
          ),
          child: SafeArea(top: false, child: child),
        ),
      ),
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 10, bottom: 12),
          decoration: BoxDecoration(color: GL.ink.withOpacity(.2), borderRadius: BorderRadius.circular(2)),
        ),
      );
}
