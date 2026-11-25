import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/care_db.dart';
import '../models/plant.dart';
import 'notifications.dart';

/// Uygulamanın tüm durumu. Telefonda yerel olarak saklanır.
class AppStore extends ChangeNotifier {
  static const _key = 'green_life_state_v1';
  SharedPreferences? _prefs;

  bool signedIn = false;
  String userName = '';
  String userEmail = '';
  String? photoUrl;
  bool alarmOn = true;
  int alarmHour = 9;
  int alarmMinute = 0;
  String cityName = 'İstanbul';
  double cityLat = 41.01;
  double cityLon = 28.97;
  List<Plant> plants = [];

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      signedIn = j['signedIn'] == true;
      userName = (j['userName'] ?? '') as String;
      userEmail = (j['userEmail'] ?? '') as String;
      photoUrl = j['photoUrl'] as String?;
      alarmOn = j['alarmOn'] != false;
      alarmHour = (j['alarmHour'] ?? 9) as int;
      alarmMinute = (j['alarmMinute'] ?? 0) as int;
      cityName = (j['cityName'] ?? cityName) as String;
      cityLat = ((j['cityLat'] ?? cityLat) as num).toDouble();
      cityLon = ((j['cityLon'] ?? cityLon) as num).toDouble();
      plants = ((j['plants'] ?? []) as List)
          .map((e) => Plant.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('Kayıt okunamadı: $e');
    }
  }

  Future<void> _save({bool reschedule = false}) async {
    notifyListeners();
    await _prefs?.setString(
      _key,
      jsonEncode({
        'signedIn': signedIn,
        'userName': userName,
        'userEmail': userEmail,
        'photoUrl': photoUrl,
        'alarmOn': alarmOn,
        'alarmHour': alarmHour,
        'alarmMinute': alarmMinute,
        'cityName': cityName,
        'cityLat': cityLat,
        'cityLon': cityLon,
        'plants': plants.map((p) => p.toJson()).toList(),
      }),
    );
    if (reschedule) await _reschedule();
  }

  Future<void> _reschedule() => WaterAlarms.rescheduleAll(
        plants,
        enabled: alarmOn,
        hour: alarmHour,
        minute: alarmMinute,
      );

  String get alarmTimeText =>
      '${alarmHour.toString().padLeft(2, '0')}:${alarmMinute.toString().padLeft(2, '0')}';

  String get firstName => userName.trim().isEmpty ? 'Bitki dostu' : userName.trim().split(' ').first;

  // ---------- Hesap ----------

  Future<void> signIn({required String name, required String email, String? photo}) async {
    signedIn = true;
    userName = name;
    userEmail = email;
    photoUrl = photo;
    if (plants.isEmpty) _seedExamples();
    await WaterAlarms.requestPermission();
    await _save(reschedule: true);
  }

  Future<void> signOut() async {
    signedIn = false;
    await _save();
  }

  // ---------- Bitkiler ----------

  Plant? byId(String id) {
    for (final p in plants) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Plant> get dueToday => plants.where((p) => p.needsWaterToday).toList();
  List<Plant> get wateredTodayList => plants.where((p) => p.wateredToday).toList();

  /// Ana sayfadaki büyük kartta gösterilecek bitki: en acil olan.
  Plant? get featured {
    if (plants.isEmpty) return null;
    final sorted = [...plants]..sort((a, b) => a.daysUntilWater.compareTo(b.daysUntilWater));
    return sorted.first;
  }

  Plant addFromCare(CareInfo c, {String? name, String room = 'Salon', double? heightCm}) {
    final now = DateTime.now();
    final p = Plant(
      id: now.microsecondsSinceEpoch.toString(),
      name: name ?? _shortName(c.trName),
      scientific: c.scientific,
      room: room,
      kind: c.kind,
      waterEveryDays: c.waterDays,
      lastWatered: now,
      addedAt: now,
      light: c.light,
      temperature: c.temperature,
      tip: c.tip,
      growth: [if (heightCm != null && heightCm > 0) GrowthEntry(now, heightCm)],
    );
    plants.add(p);
    _save(reschedule: true);
    return p;
  }

  void water(Plant p) {
    p.lastWatered = DateTime.now();
    _save(reschedule: true);
  }

  void addHeight(Plant p, double cm) {
    final today = dateOnly(DateTime.now());
    p.growth.removeWhere((g) => dateOnly(g.date) == today);
    p.growth.add(GrowthEntry(DateTime.now(), cm));
    p.growth.sort((a, b) => a.date.compareTo(b.date));
    _save();
  }

  void updatePlant(Plant p, {String? name, String? room, int? waterEveryDays}) {
    if (name != null && name.trim().isNotEmpty) p.name = name.trim();
    if (room != null) p.room = room;
    if (waterEveryDays != null) p.waterEveryDays = waterEveryDays.clamp(1, 60);
    _save(reschedule: true);
  }

  void remove(Plant p) {
    plants.removeWhere((x) => x.id == p.id);
    _save(reschedule: true);
  }

  // ---------- Alarm ----------

  void setAlarm(bool on) {
    alarmOn = on;
    _save(reschedule: true);
  }

  void setAlarmTime(int h, int m) {
    alarmHour = h;
    alarmMinute = m;
    _save(reschedule: true);
  }

  // ---------- Şehir (hava durumu) ----------

  void setCity(String name, double lat, double lon) {
    cityName = name;
    cityLat = lat;
    cityLon = lon;
    _save();
  }

  // ---------- Örnek veriler ----------

  static String _shortName(String tr) {
    final i = tr.indexOf(' (');
    return i > 0 ? tr.substring(0, i) : tr;
  }

  void _seedExamples() {
    final now = DateTime.now();
    DateTime ago(int d) => now.subtract(Duration(days: d));
    final monstera = CareDb.match('monstera deliciosa')!;
    final snake = CareDb.match('dracaena trifasciata')!;
    final lily = CareDb.match('spathiphyllum')!;
    plants = [
      Plant(
        id: 'ornek-monstera',
        name: 'Monstera',
        scientific: monstera.scientific,
        room: 'Salon · Pencere önü',
        kind: PlantKind.monstera,
        waterEveryDays: monstera.waterDays,
        lastWatered: ago(6),
        addedAt: ago(29),
        light: monstera.light,
        temperature: monstera.temperature,
        tip: monstera.tip,
        growth: [
          GrowthEntry(ago(29), 6),
          GrowthEntry(ago(23), 9),
          GrowthEntry(ago(16), 14),
          GrowthEntry(now, 22),
        ],
      ),
      Plant(
        id: 'ornek-pasa',
        name: 'Paşa Kılıcı',
        scientific: snake.scientific,
        room: 'Yatak odası',
        kind: PlantKind.snake,
        waterEveryDays: snake.waterDays,
        lastWatered: ago(snake.waterDays),
        addedAt: ago(40),
        light: snake.light,
        temperature: snake.temperature,
        tip: snake.tip,
        growth: [GrowthEntry(ago(40), 30), GrowthEntry(ago(10), 34)],
      ),
      Plant(
        id: 'ornek-baris',
        name: 'Barış Çiçeği',
        scientific: lily.scientific,
        room: 'Mutfak',
        kind: PlantKind.leafy,
        waterEveryDays: lily.waterDays,
        lastWatered: now,
        addedAt: ago(12),
        light: lily.light,
        temperature: lily.temperature,
        tip: lily.tip,
        growth: [GrowthEntry(ago(12), 18), GrowthEntry(ago(2), 21)],
      ),
    ];
  }
}

/// Uygulama durumunu widget ağacına taşır: `StoreScope.of(context)`.
class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child})
      : super(notifier: store);

  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  static AppStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}
