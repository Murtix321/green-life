import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/login_screen.dart';
import 'screens/shell.dart';
import 'services/notifications.dart';
import 'services/store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
  ));
  await WaterAlarms.init();
  final store = AppStore();
  await store.load();
  runApp(GreenLifeApp(store: store));
}

class GreenLifeApp extends StatelessWidget {
  final AppStore store;
  const GreenLifeApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'Green Life',
        debugShowCheckedModeBanner: false,
        theme: GL.theme(),
        home: const _Root(),
      ),
    );
  }
}

/// Giriş yapılmışsa ana ekran, değilse giriş ekranı; aralarında yumuşak geçiş.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 650),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: .97, end: 1.0).animate(a), child: child),
      ),
      child: store.signedIn ? const Shell(key: ValueKey('shell')) : const LoginScreen(key: ValueKey('login')),
    );
  }
}
