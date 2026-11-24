import 'package:flutter/material.dart';

import '../theme.dart';
import 'home_screen.dart';
import 'plants_screen.dart';
import 'profile_screen.dart';
import 'scan_screen.dart';

/// Alt menülü ana iskelet: Ana sayfa · Bitkiler · Tara · Profil
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  void _go(int i) {
    if (i == 2) {
      Navigator.of(context).push(glRoute(const ScanScreen(), fullscreen: true));
      return;
    }
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenPlants: () => _go(1), onScan: () => _go(2)),
      PlantsScreen(onScan: () => _go(2)),
      const SizedBox.shrink(),
      const ProfileScreen(),
    ];
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, .03), end: Offset.zero).animate(a),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]),
      ),
      bottomNavigationBar: _NavBar(index: _tab, onTap: _go),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _NavBar({required this.index, required this.onTap});

  static const _items = [
    (Icons.home_rounded, 'Ana sayfa'),
    (Icons.eco_outlined, 'Bitkiler'),
    (Icons.center_focus_strong_rounded, 'Tara'),
    (Icons.person_outline_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: GL.ink.withOpacity(.10), blurRadius: 24, offset: const Offset(0, -8))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 78,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: _items[i].$1,
                    label: _items[i].$2,
                    active: i == index,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              width: active ? 48 : 36,
              height: active ? 48 : 36,
              decoration: BoxDecoration(color: active ? GL.forest : Colors.transparent, shape: BoxShape.circle),
              child: Icon(icon, size: 22, color: active ? Colors.white : GL.muted),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? GL.forest : GL.muted,
                fontFamily: DefaultTextStyle.of(context).style.fontFamily,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
