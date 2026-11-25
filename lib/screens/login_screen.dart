import 'package:flutter/material.dart';

import '../services/auth.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/glass.dart';

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
      if (mounted && !e.cancelled) _showError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String msg) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const Text('Google girişi olmadı', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(msg, style: const TextStyle(fontSize: 14, height: 1.5, color: GL.muted)),
              const SizedBox(height: 16),
              GreenButton(
                label: 'E-posta ile devam et',
                onTap: () {
                  Navigator.pop(ctx);
                  _email();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _email() async {
    final res = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _EmailSheet(),
    );
    if (res == null || !mounted) return;
    await StoreScope.read(context).signIn(name: res.$1, email: res.$2);
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return Scaffold(
      body: LeafBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: FloatY(
                    child: Hero(
                      tag: 'login-plant',
                      child: Image.asset('assets/plants/incir.webp', height: h * .42, fit: BoxFit.contain,
                          semanticLabel: 'Beyaz saksıda keman yapraklı incir'),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Rise(
                  child: Glass(
                    radius: 30,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.eco_rounded, size: 18, color: GL.greenDark),
                            SizedBox(width: 6),
                            Text('Green Life',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: GL.greenDark)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(fontFamily: GL.font, fontSize: 27, height: 1.15, color: GL.ink, letterSpacing: -.4),
                            children: [
                              TextSpan(text: 'Bitkilerin seni\n', style: TextStyle(fontWeight: FontWeight.w500)),
                              TextSpan(text: 'çok sevecek.', style: TextStyle(fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sulama gününü hatırlatır, bakımı öğretir, büyümesini kaydeder.',
                          style: TextStyle(fontSize: 13, height: 1.5, color: GL.muted),
                        ),
                        const SizedBox(height: 16),
                        GreenButton(
                          key: const ValueKey('google-login'),
                          label: 'Google ile devam et',
                          busy: _busy,
                          onTap: _google,
                          leading: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: const Text('G',
                                style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.w900, fontSize: 15)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Glass(
                          key: const ValueKey('email-login'),
                          radius: 18,
                          padding: EdgeInsets.zero,
                          onTap: _busy ? () {} : _email,
                          child: const SizedBox(
                            height: 48,
                            width: double.infinity,
                            child: Center(
                              child: Text('E-posta ile giriş yap',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Center(
                          child: Text('Tamamen ücretsiz', style: TextStyle(fontSize: 12, color: GL.muted)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    if (n.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(m)) {
      setState(() => _error = 'Adını ve geçerli bir e-posta adresini yaz.');
      return;
    }
    Navigator.pop(context, (n, m));
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: GlassSheet(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const Text('E-posta ile giriş', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Hesabın şimdilik bu telefonda saklanır.', style: TextStyle(color: GL.muted, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('name-field'),
                controller: _name,
                decoration: _dec('Adın'),
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey('mail-field'),
                controller: _mail,
                decoration: _dec('E-posta'),
                keyboardType: TextInputType.emailAddress,
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: GL.danger, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              GreenButton(key: const ValueKey('email-continue'), label: 'Devam et', onTap: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
