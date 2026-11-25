import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/care_db.dart';
import '../models/plant.dart';
import 'notifications.dart';

/// Bakım listesindeki bir görev.
class CareTask {
  final Plant plant;
  final String title;
  final String sub;
  final bool done;
  const CareTask(this.plant, this.title, this.sub, this.done);
}

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

  /// Bugün tamamlanan görevler (bitki id'leri) — yalnızca bugün için tutulur.
  final Set<String> _doneToday = {};

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

  Future<void> _reschedule() =>
      WaterAlarms.rescheduleAll(plants, enabled: alarmOn, hour: alarmHour, minute: alarmMinute);

  String get alarmTimeText =>
      '${alarmHour.toString().padLeft(2, '0')}:${alarmMinute.toString().padLeft(2, '0')}';

  String get firstName => userName.trim().isEmpty ? 'Bitki Dostu' : userName.trim().split(' ').first;

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

  /// Bakım ekranı: bugün, yaklaşan, tamamlanan.
  List<CareTask> get todayTasks {
    final out = <CareTask>[];
    for (final p in plants) {
      final done = _doneToday.contains(p.id);
      if (p.needsWaterToday || _doneToday.contains(p.id)) {
        out.add(CareTask(p, '${p.name} sula', done ? 'Bugün sulandı' : (p.daysUntilWater < 0 ? p.waterLabel : 'Bugün'), done));
      }
    }
    return out;
  }

  List<CareTask> get upcomingTasks {
    final list = plants.where((p) => !p.needsWaterToday && !_doneToday.contains(p.id)).toList()
      ..sort((a, b) => a.daysUntilWater.compareTo(b.daysUntilWater));
    return list.map((p) => CareTask(p, '${p.name} sula', p.waterLabel, false)).toList();
  }

  List<CareTask> get completedTasks {
    final list = plants.where((p) => p.daysUntilWater < p.waterEveryDays || _doneToday.contains(p.id)).toList()
      ..sort((a, b) => b.lastWatered.compareTo(a.lastWatered));
    return list.map((p) {
      final ago = dateOnly(DateTime.now()).difference(dateOnly(p.lastWatered)).inDays;
      final when = ago == 0 ? 'Bugün' : (ago == 1 ? 'Dün' : '$ago gün önce');
      return CareTask(p, '${p.name} sulandı', when, true);
    }).toList();
  }

  void toggleTodayTask(Plant p) {
    if (_doneToday.contains(p.id)) {
      _doneToday.remove(p.id);
      // Geri al: son sulamayı bir önceki döngüye çek
      p.lastWatered = DateTime.now().subtract(Duration(days: p.waterEveryDays));
    } else {
      _doneToday.add(p.id);
      p.lastWatered = DateTime.now();
    }
    _save(reschedule: true);
  }

  Plant addFromCare(CareInfo c, {String? name, String room = 'Salon', String? photo}) {
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
      humidity: c.humidity,
      tip: c.tip,
      image: c.image,
      photo: photo,
      growth: [if (photo != null) GrowthEntry(now, 0, photo: photo)],
    );
    plants.add(p);
    _save(reschedule: true);
    return p;
  }

  void water(Plant p) {
    p.lastWatered = DateTime.now();
    _doneToday.add(p.id);
    _save(reschedule: true);
  }

  /// Bugünün boyunu ve/veya fotoğrafını kaydet.
  void addGrowth(Plant p, {double? cm, String? photo}) {
    final today = dateOnly(DateTime.now());
    GrowthEntry? old;
    for (final g in p.growth) {
      if (dateOnly(g.date) == today) old = g;
    }
    p.growth.removeWhere((g) => dateOnly(g.date) == today);
    p.growth.add(GrowthEntry(DateTime.now(), cm ?? old?.cm ?? p.currentHeight, photo: photo ?? old?.photo));
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
    _doneToday.remove(p.id);
    _save(reschedule: true);
  }

  // ---------- Alarm & şehir ----------

  void setAlarm(bool on) {
    alarmOn = on;
    _save(reschedule: true);
  }

  void setAlarmTime(int h, int m) {
    alarmHour = h;
    alarmMinute = m;
    _save(reschedule: true);
  }

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
    Plant make(String sci, String id, String room, int wateredAgo, int addedAgo, {List<GrowthEntry>? growth}) {
      final c = CareDb.match(sci)!;
      return Plant(
        id: id,
        name: _shortName(c.trName),
        scientific: c.scientific,
        room: room,
        kind: c.kind,
        waterEveryDays: c.waterDays,
        lastWatered: ago(wateredAgo),
        addedAt: ago(addedAgo),
        light: c.light,
        temperature: c.temperature,
        humidity: c.humidity,
        tip: c.tip,
        image: c.image,
        growth: growth,
      );
    }

    plants = [
      make('ficus lyrata', 'ornek-incir', 'Salon', 6, 50, growth: [GrowthEntry(ago(50), 62), GrowthEntry(ago(20), 70), GrowthEntry(now, 74)]),
      make('dracaena trifasciata', 'ornek-pasa', 'Yatak odası', 4, 239, growth: [
        GrowthEntry(ago(239), 12, photo: 'assets/plants/pasa1.webp'),
        GrowthEntry(ago(150), 38, photo: 'assets/plants/pasa2.webp'),
        GrowthEntry(now, 55, photo: 'assets/plants/pasa3.webp'),
      ]),
      make('spathiphyllum', 'ornek-baris', 'Mutfak', 6, 30, growth: [GrowthEntry(ago(30), 28), GrowthEntry(now, 33)]),
      make('epipremnum aureum', 'ornek-pothos', 'Çalışma odası', 7, 20),
    ];
  }
}

/// Uygulama durumunu widget ağacına taşır: `StoreScope.of(context)`.
class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child}) : super(notifier: store);

  static AppStore of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  static AppStore read(BuildContext context) => context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}
