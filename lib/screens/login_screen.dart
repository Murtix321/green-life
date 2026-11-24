import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../services/auth.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/animated_plant.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;

  Future<void> _google() async {
    setState(() => _busy = true);
    try {
      final u = await AuthService.signInWithGoogle();
      if (!mounted) return;
      await StoreScope.read(context).signIn(name: u.name, email: u.email, photo: u.photoUrl);
    } on AuthException catch (e) {
      if (mounted) showGLSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _email() async {
    final res = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (_) => const _EmailSheet(),
    );
    if (res == null || !mounted) return;
    await StoreScope.read(context).signIn(name: res.$1, email: res.$2);
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return Scaffold(
      body: Column(
        children: [
          // Üst nane panel + animasyonlu bitki
          Container(
            height: h * .55,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: GL.mint,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(44)),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned.fill(
                    top: h * .06,
                    child: Center(
                      child: Container(
                        width: h * .34,
                        height: h * .34,
                        decoration: const BoxDecoration(color: Color(0xFFE3F1E6), shape: BoxShape.circle),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AnimatedPlant(kind: PlantKind.monstera, leaves: 5, size: h * .3),
                    ),
                  ),
                  const Positioned(
                    left: 24,
                    top: 16,
                    child: Rise(child: _Logo()),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Rise(
                      delay: 250,
                      child: Text(
                        'Her bitkiye\nkendi bakım planı.',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -.5),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Rise(
                      delay: 400,
                      child: Text(
                        'Tara, tanı, hatırlat. Sağlık puanını ve büyümesini tek ekrandan izle.',
                        style: TextStyle(fontSize: 14, height: 1.5, color: GL.muted),
                      ),
                    ),
                    const Spacer(),
                    Rise(
                      delay: 550,
                      child: Column(
                        children: [
                          PrimaryButton(
                            label: 'Google ile devam et',
                            busy: _busy,
                            onTap: _google,
                            leading: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: const Text(
                                'G',
                                style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 50,
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _busy ? null : _email,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: GL.ink,
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: GL.line, width: 1.5),
                                shape: const StadiumBorder(),
                                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              child: const Text('E-posta ile giriş yap'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text('Tamamen ücretsiz', style: TextStyle(fontSize: 12, color: GL.muted)),
                        ],
                      ),
                    ),
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

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: GL.forest, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        const Text('Green Life', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: GL.forest)),
      ],
    );
  }
}

class _EmailSheet extends StatefulWidget {
  const _EmailSheet();

  @override
  State<_EmailSheet> createState() => _EmailSheetState();
}

class _EmailSheetState extends State<_EmailSheet> {
  final _name = TextEditingController();
  final _mail = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _mail.dispose();
    super.dispose();
  }

  void _submit() {
    final n = _name.text.trim();
    final m = _mail.text.trim();
    if (n.isEmpty || !m.contains('@')) {
      setState(() => _error = 'Adını ve geçerli bir e-posta adresini yaz.');
      return;
    }
    Navigator.pop(context, (n, m));
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: GL.bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFD3DED6), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          const Text('E-posta ile giriş', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            'Şimdilik hesabın sadece bu telefonda tutulur.',
            style: TextStyle(color: GL.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(controller: _name, decoration: _dec('Adın'), textInputAction: TextInputAction.next),
          const SizedBox(height: 10),
          TextField(
            controller: _mail,
            decoration: _dec('E-posta'),
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Color(0xFFB3261E), fontSize: 13)),
          ],
          const SizedBox(height: 16),
          PrimaryButton(label: 'Devam et', onTap: _submit),
        ],
      ),
    );
  }
}
