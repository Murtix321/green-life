import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/glass.dart';
import 'care_screen.dart';
import 'home_screen.dart';
import 'plants_screen.dart';
import 'profile_screen.dart';
import 'scan_screen.dart';

/// Alt menülü iskelet: Ana sayfa · Bitkilerim · Bakım · Profil
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  void _scan() => Navigator.of(context).push(glRoute(const ScanScreen(), fullscreen: true));

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onScan: _scan, onOpenPlants: () => setState(() => _tab = 1), onOpenCare: () => setState(() => _tab = 2)),
      PlantsScreen(onScan: _scan),
      const CareScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      extendBody: true,
      body: LeafBackground(
        asset: _tab == 1 || _tab == 3 ? 'assets/bg/dua.jpg' : 'assets/bg/yaprak.jpg',
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, .025), end: Offset.zero).animate(a),
              child: child,
            ),
          ),
          child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Glass(
          radius: 26,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Ana sayfa', active: _tab == 0, onTap: () => setState(() => _tab = 0)),
              _NavItem(icon: Icons.eco_outlined, label: 'Bitkilerim', active: _tab == 1, onTap: () => setState(() => _tab = 1)),
              _NavItem(icon: Icons.water_drop_outlined, label: 'Bakım', active: _tab == 2, onTap: () => setState(() => _tab = 2)),
              _NavItem(icon: Icons.person_outline_rounded, label: 'Profil', active: _tab == 3, onTap: () => setState(() => _tab = 3)),
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
    final color = active ? GL.greenDark : GL.muted;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: 34,
          child: SizedBox(
            height: 50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: active ? 1.12 : 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: Icon(icon, size: 23, color: color),
                ),
                const SizedBox(height: 3),
                Text(label,
                    style: TextStyle(fontSize: 10.5, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
