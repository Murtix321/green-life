import 'dart:math' as math;

/// Eski sürümden kalan tür bilgisi (kayıtlarla uyum için tutuluyor).
enum PlantKind { monstera, snake, leafy }

PlantKind kindFromName(String? s) =>
    PlantKind.values.firstWhere((k) => k.name == s, orElse: () => PlantKind.leafy);

class GrowthEntry {
  final DateTime date;
  final double cm;

  /// Bu günün fotoğrafı: telefondaki dosya yolu ya da 'assets/...' (örnek veriler).
  final String? photo;
  const GrowthEntry(this.date, this.cm, {this.photo});

  Map<String, dynamic> toJson() => {'d': date.toIso8601String(), 'cm': cm, if (photo != null) 'p': photo};
  factory GrowthEntry.fromJson(Map<String, dynamic> j) => GrowthEntry(
        DateTime.parse(j['d'] as String),
        (j['cm'] as num).toDouble(),
        photo: j['p'] as String?,
      );
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
  String humidity;
  String tip;

  /// Arka planı silinmiş katalog görseli (assets/plants/...), varsa.
  String? image;

  /// Kullanıcının kendi çektiği fotoğraf (tarama sırasında), varsa.
  String? photo;
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
    this.humidity = '%40–60',
    this.image,
    this.photo,
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

  /// Kısa hâl etiketi (kartlarda).
  String get statusLabel => needsWaterToday ? 'Su istiyor' : 'Sağlıklı';

  int get health {
    var score = 96;
    final d = daysUntilWater;
    if (d < 0) score -= (-d) * 12;
    if (d == 0) score -= 4;
    if (growth.length >= 2 && growth.last.cm > growth.first.cm) score += 2;
    return score.clamp(15, 100);
  }

  double get currentHeight => growth.isEmpty ? 0 : growth.last.cm;

  /// Büyüme günlüğündeki bir kaydın "Gün N" etiketi.
  int dayOf(GrowthEntry e) => dateOnly(e.date).difference(dateOnly(addedAt)).inDays + 1;

  static int leavesFor(double cm, double maxCm) {
    if (maxCm <= 0) return 3;
    return math.max(1, (cm / maxCm * 5).round()).clamp(1, 5);
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
        'hum': humidity,
        'tip': tip,
        'image': image,
        'photo': photo,
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
        humidity: (j['hum'] ?? '%40–60') as String,
        tip: (j['tip'] ?? '') as String,
        image: j['image'] as String?,
        photo: j['photo'] as String?,
        growth: ((j['growth'] ?? []) as List)
            .map((e) => GrowthEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
