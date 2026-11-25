import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_life/main.dart' as app;
import 'package:integration_test/integration_test.dart';

/// Gerçek Android emülatöründe uçtan uca senaryo + her adımda ekran görüntüsü.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> wait(WidgetTester t, int ms) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester t, String name) async {
    await wait(t, 300);
    await binding.takeScreenshot(name);
  }

  testWidgets('Green Life uçtan uca', (t) async {
    app.main();
    await wait(t, 4000);
    await binding.convertFlutterSurfaceToImage();
    await wait(t, 800);
    await shot(t, '01-giris');

    // Google ile giriş: emülatörde Google hesabı yok → anlaşılır hata göstermeli, çökmemeli.
    await t.tap(find.text('Google ile devam et'));
    await wait(t, 6000);
    await shot(t, '02-google-giris-sonucu');
    if (find.text('E-posta ile devam et').evaluate().isNotEmpty) {
      await t.tap(find.text('E-posta ile devam et'));
    } else {
      // Hata sayfası açılmadıysa (ör. Google ekranı açıldı) geri dönüp e-posta ile devam et
      final back = find.byTooltip('Back');
      if (back.evaluate().isNotEmpty) await t.tap(back);
      await wait(t, 1000);
      await t.tap(find.byKey(const ValueKey('email-login')));
    }
    await wait(t, 1200);

    await t.enterText(find.byKey(const ValueKey('name-field')), 'Ayşe');
    await t.enterText(find.byKey(const ValueKey('mail-field')), 'ayse@ornek.com');
    await shot(t, '03-eposta');
    await t.tap(find.byKey(const ValueKey('email-continue')));
    await wait(t, 4000);
    await shot(t, '04-ana-sayfa');

    // Bitki detayı
    await t.tap(find.text('Keman Yapraklı İncir').first);
    await wait(t, 2500);
    await shot(t, '05-detay');
    await t.tap(find.byKey(const ValueKey('log-water')));
    await wait(t, 1200);
    await shot(t, '06-detay-sulandi');
    await t.tap(find.byTooltip('Geri'));
    await wait(t, 1500);

    // Paşa kılıcının büyüme günlüğü (gerçek fotoğraflar)
    await t.tap(find.text('Paşa Kılıcı').first);
    await wait(t, 2000);
    await t.ensureVisible(find.byKey(const ValueKey('open-growth')));
    await wait(t, 600);
    await t.tap(find.byKey(const ValueKey('open-growth')));
    await wait(t, 2500);
    await shot(t, '07-buyume-gun240');
    await t.tap(find.text('Gün 1').first);
    await wait(t, 1800);
    await shot(t, '08-buyume-gun1');
    await t.tap(find.byTooltip('Geri'));
    await wait(t, 1200);
    await t.tap(find.byTooltip('Geri'));
    await wait(t, 1500);

    // Bakım
    await t.tap(find.text('Bakım').last);
    await wait(t, 2000);
    await shot(t, '09-bakim');
    await t.tap(find.byKey(const ValueKey('check-ornek-baris')));
    await wait(t, 1000);
    await shot(t, '10-bakim-tik');
    await t.tap(find.text('Yaklaşan'));
    await wait(t, 1200);
    await shot(t, '11-bakim-yaklasan');

    // Bitkilerim + internetten arama (iNaturalist)
    await t.tap(find.text('Bitkilerim').last);
    await wait(t, 2000);
    await shot(t, '12-bitkilerim');
    await t.tap(find.byKey(const ValueKey('plants-add')));
    await wait(t, 1200);
    await t.enterText(find.byKey(const ValueKey('add-search')), 'lavanta');
    await wait(t, 7000);
    await shot(t, '13-arama-lavanta');
    await t.tapAt(const Offset(20, 60));
    await wait(t, 1500);

    // Profil
    await t.tap(find.text('Profil').last);
    await wait(t, 2000);
    await shot(t, '14-profil');

    // Tarama ekranı
    await t.tap(find.text('Ana sayfa').last);
    await wait(t, 2000);
    await shot(t, '15-ana-sayfa-hava');
    await t.tap(find.byTooltip('Bitki tara'));
    await wait(t, 2000);
    await shot(t, '16-tara');
  });
}
