import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_life/data/care_db.dart';
import 'package:green_life/main.dart';
import 'package:green_life/models/plant.dart';
import 'package:green_life/services/store.dart';
import 'package:green_life/services/weather.dart';
import 'package:shared_preferences/shared_preferences.dart';

Plant _plant({int every = 7, int wateredAgo = 0}) => Plant(
      id: 't',
      name: 'Test',
      scientific: 'x',
      room: '',
      kind: PlantKind.leafy,
      waterEveryDays: every,
      lastWatered: DateTime.now().subtract(Duration(days: wateredAgo)),
      addedAt: DateTime.now().subtract(const Duration(days: 30)),
      light: '',
      temperature: '',
      tip: '',
    );

/// Uygulamayı başlatıp ayarlanmış süre kadar ilerletir (sonsuz animasyonlar yüzünden pumpAndSettle kullanılmaz).
Future<void> _go(WidgetTester t, [int ms = 900]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('Bakım veritabanı', () {
    test('bilimsel adla eşleşir, en uzun anahtar kazanır', () {
      expect(CareDb.match('Monstera deliciosa')!.waterDays, 8);
      expect(CareDb.match('Dracaena trifasciata')!.trName, 'Paşa Kılıcı');
      expect(CareDb.match('Dracaena marginata')!.trName, 'Ejderha Ağacı');
      expect(CareDb.match('Opuntia ficus-indica', family: 'Cactaceae')!.trName, 'Kaktüs');
      expect(CareDb.match('Bilinmeyen bitki'), isNull);
    });

    test('gerçek fotoğraflı bitkilerin görseli tanımlı', () {
      for (final sci in ['ficus lyrata', 'epipremnum aureum', 'zamioculcas', 'aloe vera', 'spathiphyllum']) {
        expect(CareDb.match(sci)!.image, startsWith('assets/plants/'), reason: sci);
      }
    });

    test('genel bakım önerisi haftada bir sulama verir', () {
      expect(CareDb.generic('Xus yus', 'Xus').waterDays, 7);
    });
  });

  group('Sulama hesapları', () {
    test('zamanı gelen bitki bugün sulanmalı', () {
      final p = _plant(every: 7, wateredAgo: 7);
      expect(p.needsWaterToday, isTrue);
      expect(p.waterLabel, 'Bugün sula');
      expect(p.statusLabel, 'Su istiyor');
    });

    test('gecikme ve sağlık puanı', () {
      final p = _plant(every: 5, wateredAgo: 8);
      expect(p.daysUntilWater, -3);
      expect(p.waterLabel, '3 gün gecikti');
      expect(p.health, lessThan(70));
    });

    test('yarın ve ileri tarih', () {
      expect(_plant(every: 7, wateredAgo: 6).waterLabel, 'Yarın');
      expect(_plant(every: 7, wateredAgo: 2).waterLabel, '5 gün sonra');
    });

    test('JSON kayıt / okuma kayıpsız', () {
      final p = _plant()
        ..image = 'assets/plants/incir.webp'
        ..photo = '/data/foto.jpg'
        ..growth.add(GrowthEntry(DateTime(2026, 1, 1), 12, photo: 'assets/plants/pasa1.webp'));
      final back = Plant.fromJson(p.toJson());
      expect(back.image, p.image);
      expect(back.photo, p.photo);
      expect(back.growth.single.photo, 'assets/plants/pasa1.webp');
      expect(back.growth.single.cm, 12);
    });
  });

  group('Hava durumu ipucu', () {
    test('sıcak, kuru, soğuk ve ideal', () {
      expect(const WeatherNow(28, 33, 50).tip, contains('sıcak'));
      expect(const WeatherNow(20, 22, 25).tip, contains('kuru'));
      expect(const WeatherNow(2, 4, 60).tip, contains('soğuk'));
      expect(const WeatherNow(20, 22, 55).tip, contains('ideal'));
    });
  });

  group('Uygulama durumu (store)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('ilk girişte örnek bitkiler eklenir ve kaydedilir', () async {
      final s = AppStore();
      await s.load();
      await s.signIn(name: 'Ayşe Yılmaz', email: 'ayse@ornek.com');
      expect(s.firstName, 'Ayşe');
      expect(s.plants.length, 4);
      expect(s.dueToday.map((p) => p.name), containsAll(['Barış Çiçeği', 'Salon Sarmaşığı']));

      final s2 = AppStore();
      await s2.load();
      expect(s2.signedIn, isTrue);
      expect(s2.plants.length, 4);
      expect(s2.byId('ornek-pasa')!.growth.length, 3);
    });

    test('bakım görevi tikle / geri al', () async {
      final s = AppStore();
      await s.load();
      await s.signIn(name: 'Ayşe', email: 'a@b.co');
      final baris = s.byId('ornek-baris')!;
      expect(s.todayTasks.firstWhere((t) => t.plant == baris).done, isFalse);
      s.toggleTodayTask(baris);
      expect(s.todayTasks.firstWhere((t) => t.plant == baris).done, isTrue);
      expect(baris.needsWaterToday, isFalse);
      s.toggleTodayTask(baris);
      expect(baris.needsWaterToday, isTrue);
    });

    test('bitki ekleme, büyüme kaydı, silme', () async {
      final s = AppStore();
      await s.load();
      await s.signIn(name: 'Ayşe', email: 'a@b.co');
      final p = s.addFromCare(CareDb.match('aloe vera')!);
      expect(p.image, 'assets/plants/aloe.webp');
      expect(p.waterEveryDays, 18);
      s.addGrowth(p, cm: 20);
      s.addGrowth(p, photo: '/x.jpg');
      expect(p.growth.length, 1, reason: 'aynı gün tek kayıt');
      expect(p.growth.single.cm, 20);
      expect(p.growth.single.photo, '/x.jpg');
      s.remove(p);
      expect(s.byId(p.id), isNull);
    });
  });

  group('Ekranlar', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    testWidgets('giriş → e-posta ile kayıt → ana sayfa → bakım → profil', (t) async {
      t.view.physicalSize = const Size(1080, 2340);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);

      final store = AppStore();
      await store.load();
      await t.pumpWidget(GreenLifeApp(store: store));
      await _go(t);

      expect(find.text('Google ile devam et'), findsOneWidget);
      expect(find.text('E-posta ile giriş yap'), findsOneWidget);

      // Geçersiz e-posta uyarısı
      await t.tap(find.byKey(const ValueKey('email-login')));
      await _go(t);
      await t.enterText(find.byKey(const ValueKey('name-field')), 'Ayşe');
      await t.enterText(find.byKey(const ValueKey('mail-field')), 'gecersiz');
      await t.tap(find.byKey(const ValueKey('email-continue')));
      await _go(t, 300);
      expect(find.textContaining('geçerli bir e-posta'), findsOneWidget);

      await t.enterText(find.byKey(const ValueKey('mail-field')), 'ayse@ornek.com');
      await t.tap(find.byKey(const ValueKey('email-continue')));
      await _go(t, 1500);

      // Ana sayfa
      expect(store.signedIn, isTrue);
      expect(find.textContaining('Ayşe', findRichText: true), findsWidgets);
      expect(find.text('2 bitkiyi sula'), findsOneWidget);
      expect(find.text('Keman Yapraklı İncir'), findsOneWidget);

      // Bakım sekmesi
      await t.tap(find.text('Bakım').last);
      await _go(t, 1200);
      expect(find.text('Barış Çiçeği sula'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('check-ornek-baris')));
      await _go(t, 600);
      expect(store.byId('ornek-baris')!.needsWaterToday, isFalse);
      expect(find.text('Bugün sulandı'), findsOneWidget);

      await t.tap(find.text('Yaklaşan'));
      await _go(t, 800);
      expect(find.text('Paşa Kılıcı sula'), findsOneWidget);

      // Alarm anahtarı
      await t.tap(find.byKey(const ValueKey('alarm-switch')));
      await _go(t, 400);
      expect(store.alarmOn, isFalse);

      // Profil + çıkış
      await t.tap(find.text('Profil').last);
      await _go(t, 1200);
      expect(find.text('ayse@ornek.com'), findsOneWidget);
      await t.scrollUntilVisible(find.byKey(const ValueKey('sign-out')), 200, scrollable: find.byType(Scrollable).last);
      await t.tap(find.byKey(const ValueKey('sign-out')));
      await _go(t, 1500);
      expect(store.signedIn, isFalse);
      expect(find.text('Google ile devam et'), findsOneWidget);
      await _go(t, 1500);
    });

    testWidgets('bitki detayı: sulamayı kaydet ve büyüme günlüğü', (t) async {
      t.view.physicalSize = const Size(1080, 2340);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);

      final store = AppStore();
      await store.load();
      await store.signIn(name: 'Ayşe', email: 'a@b.co');
      await t.pumpWidget(GreenLifeApp(store: store));
      await _go(t, 1200);

      await t.ensureVisible(find.text('Barış Çiçeği').first);
      await _go(t, 400);
      await t.tap(find.text('Barış Çiçeği').first);
      await _go(t, 1200);
      expect(find.text('Bakım özeti'), findsOneWidget);
      expect(find.text('Su istiyor'), findsOneWidget);

      await t.tap(find.byKey(const ValueKey('log-water')));
      await _go(t, 800);
      expect(store.byId('ornek-baris')!.wateredToday, isTrue);
      expect(find.textContaining('Sulandı'), findsWidgets);

      await t.tap(find.byKey(const ValueKey('open-growth')));
      await _go(t, 1200);
      expect(find.text('Büyüme günlüğü'), findsOneWidget);
      expect(find.text('33 cm'), findsOneWidget);

      // Boy gir
      await t.tap(find.byKey(const ValueKey('add-height')));
      await _go(t, 800);
      await t.enterText(find.byKey(const ValueKey('height-field')), '35');
      await t.tap(find.byKey(const ValueKey('height-save')));
      await _go(t, 1500);
      expect(store.byId('ornek-baris')!.currentHeight, 35);
      await _go(t, 2000);
    });
  });
}
