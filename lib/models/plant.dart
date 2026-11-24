import 'dart:math' as math;

/// Çizim stili: animasyonlu bitki hangi yaprak tipiyle çizilecek.
enum PlantKind { monstera, snake, leafy }

PlantKind kindFromName(String? s) =>
    PlantKind.values.firstWhere((k) => k.name == s, orElse: () => PlantKind.leafy);

class GrowthEntry {
  final DateTime date;
  final double cm;
  const GrowthEntry(this.date, this.cm);

  Map<String, dynamic> toJson() => {'d': date.toIso8601String(), 'cm': cm};
  factory GrowthEntry.fromJson(Map<String, dynamic> j) =>
      GrowthEntry(DateTime.parse(j['d'] as String), (j['cm'] as num).toDouble());
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class Plant {
  final String id;
  String name;
  String scientific;
  String room;
  PlantKind kind;
  int waterEveryDays;
  DateTime lastWatered;
  DateTime addedAt;
  String light;
  String temperature;
  String tip;
  List<GrowthEntry> growth;

  Plant({
    required this.id,
    required this.name,
    required this.scientific,
    required this.room,
    required this.kind,
    required this.waterEveryDays,
    required this.lastWatered,
    required this.addedAt,
    required this.light,
    required this.temperature,
    required this.tip,
    List<GrowthEntry>? growth,
  }) : growth = growth ?? [];

  DateTime get nextWater {
    final l = dateOnly(lastWatered);
    return DateTime(l.year, l.month, l.day + waterEveryDays);
  }

  /// Negatif: gecikmiş gün sayısı.
  int get daysUntilWater {
    final today = dateOnly(DateTime.now());
    return (nextWater.difference(today).inHours / 24).round();
  }

  bool get needsWaterToday => daysUntilWater <= 0;

  bool get wateredToday => dateOnly(lastWatered) == dateOnly(DateTime.now());

  String get waterLabel {
    final d = daysUntilWater;
    if (d < 0) return '${-d} gün gecikti';
    if (d == 0) return 'Bugün sula';
    if (d == 1) return 'Yarın';
    return '$d gün sonra';
  }

  /// Basit sağlık puanı: zamanında sulama ve düzenli ölçüm puanı yükseltir.
  int get health {
    var score = 96;
    final d = daysUntilWater;
    if (d < 0) score -= (-d) * 12;
    if (d == 0) score -= 4;
    if (growth.length >= 2 && growth.last.cm > growth.first.cm) score += 2;
    return score.clamp(15, 100);
  }

  int get ageDays => DateTime.now().difference(dateOnly(addedAt)).inDays + 1;

  double get currentHeight => growth.isEmpty ? 0 : growth.last.cm;

  /// Büyüme günlüğündeki bir kaydın "Gün N" etiketi.
  int dayOf(GrowthEntry e) => dateOnly(e.date).difference(dateOnly(addedAt)).inDays + 1;

  /// Yaprak sayısı (çizim için) — boy arttıkça yeni yapraklar açılır.
  static int leavesFor(double cm, double maxCm) {
    if (maxCm <= 0) return 3;
    final r = cm / maxCm;
    return math.max(1, (r * 5).round()).clamp(1, 5);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'scientific': scientific,
        'room': room,
        'kind': kind.name,
        'water': waterEveryDays,
        'lastWatered': lastWatered.toIso8601String(),
        'addedAt': addedAt.toIso8601String(),
        'light': light,
        'temp': temperature,
        'tip': tip,
        'growth': growth.map((g) => g.toJson()).toList(),
      };

  factory Plant.fromJson(Map<String, dynamic> j) => Plant(
        id: j['id'] as String,
        name: j['name'] as String,
        scientific: (j['scientific'] ?? '') as String,
        room: (j['room'] ?? '') as String,
        kind: kindFromName(j['kind'] as String?),
        waterEveryDays: (j['water'] as num).toInt(),
        lastWatered: DateTime.parse(j['lastWatered'] as String),
        addedAt: DateTime.parse(j['addedAt'] as String),
        light: (j['light'] ?? '') as String,
        temperature: (j['temp'] ?? '') as String,
        tip: (j['tip'] ?? '') as String,
        growth: ((j['growth'] ?? []) as List)
            .map((e) => GrowthEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
