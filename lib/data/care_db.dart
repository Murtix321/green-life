import '../models/plant.dart';

/// Evde en sık beslenen bitkilerin Türkçe bakım bilgisi.
/// Tarama sonucu bu listede bulunursa API'ye hiç gidilmez (kota harcanmaz).
/// Değerler genel rehber niteliğindedir; ortam, mevsim ve saksıya göre değişir.
class CareInfo {
  final List<String> keys; // bilimsel ad / cins önekleri (küçük harf)
  final String trName;
  final String scientific;
  final int waterDays;
  final String waterText;
  final String light;
  final String temperature;
  final String tip;
  final PlantKind kind;

  /// Arka planı silinmiş gerçek fotoğraf (assets/plants/...), varsa.
  final String? image;
  final String humidity;

  const CareInfo({
    required this.keys,
    required this.trName,
    required this.scientific,
    required this.waterDays,
    required this.waterText,
    required this.light,
    required this.temperature,
    required this.tip,
    this.kind = PlantKind.leafy,
    this.image,
    this.humidity = '%40–60',
  });
}

class CareDb {
  static const List<CareInfo> all = [
    CareInfo(
      keys: ['monstera'],
      trName: 'Deve Tabanı (Monstera)',
      scientific: 'Monstera deliciosa',
      waterDays: 8,
      waterText: '7–10 günde bir',
      light: 'Parlak, dolaylı',
      temperature: '18–27 °C',
      tip: 'Toprağın üst 3–5 cm\'i kuruyunca sula. Yapraklarını ayda bir nemli bezle sil.',
      kind: PlantKind.monstera,
    ),
    CareInfo(
      keys: ['sansevieria', 'dracaena trifasciata'],
      trName: 'Paşa Kılıcı',
      scientific: 'Dracaena trifasciata',
      waterDays: 18,
      waterText: '2–3 haftada bir',
      light: 'Az ışıktan parlak ışığa',
      temperature: '15–29 °C',
      tip: 'Fazla sudan hiç hoşlanmaz; toprak tamamen kurumadan sulama.',
      kind: PlantKind.snake,
      image: 'assets/plants/pasa2.webp',
    ),
    CareInfo(
      keys: ['spathiphyllum'],
      trName: 'Barış Çiçeği',
      scientific: 'Spathiphyllum wallisii',
      waterDays: 6,
      waterText: '5–7 günde bir',
      light: 'Yarı gölge, dolaylı',
      temperature: '18–26 °C',
      tip: 'Yapraklar hafif sarkınca su istiyordur. Nemli ortamı sever.',
      image: 'assets/plants/baris.webp',
    ),
    CareInfo(
      keys: ['epipremnum', 'scindapsus'],
      trName: 'Salon Sarmaşığı (Pothos)',
      scientific: 'Epipremnum aureum',
      waterDays: 7,
      waterText: '7–10 günde bir',
      light: 'Dolaylı, az ışığa dayanıklı',
      temperature: '17–29 °C',
      tip: 'Uzayan dalları budarsan daha gür olur; kesilen dallar suda köklenir.',
      image: 'assets/plants/pothos.webp',
    ),
    CareInfo(
      keys: ['philodendron'],
      trName: 'Filodendron',
      scientific: 'Philodendron hederaceum',
      waterDays: 7,
      waterText: 'Haftada bir',
      light: 'Parlak, dolaylı',
      temperature: '18–27 °C',
      tip: 'Üst toprak kuruyunca sula, kışın aralığı aç.',
      kind: PlantKind.monstera,
    ),
    CareInfo(
      keys: ['ficus elastica'],
      trName: 'Kauçuk Bitkisi',
      scientific: 'Ficus elastica',
      waterDays: 8,
      waterText: '7–10 günde bir',
      light: 'Parlak, dolaylı',
      temperature: '16–27 °C',
      tip: 'Yer değiştirmeyi sevmez; sabit ve aydınlık bir köşe seç.',
    ),
    CareInfo(
      keys: ['ficus lyrata'],
      trName: 'Keman Yapraklı İncir',
      scientific: 'Ficus lyrata',
      waterDays: 8,
      waterText: '7–10 günde bir',
      light: 'Bol, dolaylı ışık',
      temperature: '18–27 °C',
      tip: 'Soğuk hava akımından uzak tut, yapraklarını tozdan arındır.',
      image: 'assets/plants/incir.webp',
    ),
    CareInfo(
      keys: ['zamioculcas'],
      trName: 'Zamia (ZZ Bitkisi)',
      scientific: 'Zamioculcas zamiifolia',
      waterDays: 14,
      waterText: '2 haftada bir',
      light: 'Az ışığa dayanıklı',
      temperature: '15–26 °C',
      tip: 'Kökleri su depolar; az sulamak çok sulamaktan iyidir.',
      kind: PlantKind.snake,
      image: 'assets/plants/zamia.webp',
    ),
    CareInfo(
      keys: ['chlorophytum'],
      trName: 'Kurdele Çiçeği',
      scientific: 'Chlorophytum comosum',
      waterDays: 6,
      waterText: '5–7 günde bir',
      light: 'Parlak, dolaylı',
      temperature: '13–27 °C',
      tip: 'Uçlardaki yavruları ayırıp yeni saksılara dikebilirsin.',
      kind: PlantKind.snake,
      image: 'assets/plants/kurdele.webp',
    ),
    CareInfo(
      keys: ['aloe'],
      trName: 'Aloe Vera',
      scientific: 'Aloe vera',
      waterDays: 18,
      waterText: '2–3 haftada bir',
      light: 'Bol güneş',
      temperature: '13–27 °C',
      tip: 'Kaktüs toprağı kullan; saksının dibinde su birikmesin.',
      kind: PlantKind.snake,
      image: 'assets/plants/aloe.webp',
    ),
    CareInfo(
      keys: ['crassula'],
      trName: 'Para Ağacı (Yeşim)',
      scientific: 'Crassula ovata',
      waterDays: 14,
      waterText: '2 haftada bir',
      light: 'Bol ışık, sabah güneşi',
      temperature: '10–24 °C',
      tip: 'Toprak tamamen kuruyunca sula; kışın daha da seyrek.',
    ),
    CareInfo(
      keys: ['phalaenopsis'],
      trName: 'Orkide',
      scientific: 'Phalaenopsis',
      waterDays: 7,
      waterText: 'Haftada bir',
      light: 'Parlak, doğrudan güneş yok',
      temperature: '18–28 °C',
      tip: 'Kökleri gümüşi renge dönünce sula; saksıyı suya 10 dk batırıp süz.',
      image: 'assets/plants/orkide.webp',
    ),
    CareInfo(
      keys: ['dracaena'],
      trName: 'Ejderha Ağacı',
      scientific: 'Dracaena marginata',
      waterDays: 10,
      waterText: '10 günde bir',
      light: 'Orta, dolaylı',
      temperature: '16–27 °C',
      tip: 'Musluk suyunu bir gece bekletip kullanmak yaprak uçlarını korur.',
      kind: PlantKind.snake,
    ),
    CareInfo(
      keys: ['calathea', 'goeppertia', 'maranta'],
      trName: 'Dua Çiçeği (Kalatya)',
      scientific: 'Goeppertia',
      waterDays: 5,
      waterText: '4–6 günde bir',
      light: 'Yarı gölge',
      temperature: '18–27 °C',
      tip: 'Toprağı hep hafif nemli tut, yüksek nem sever.',
    ),
    CareInfo(
      keys: ['aglaonema'],
      trName: 'Çin Her Dem Yeşili',
      scientific: 'Aglaonema',
      waterDays: 8,
      waterText: '7–10 günde bir',
      light: 'Az ve orta ışık',
      temperature: '18–27 °C',
      tip: 'Az ışığa dayanıklıdır, yeni başlayanlar için ideal.',
    ),
    CareInfo(
      keys: ['kalanchoe'],
      trName: 'Kalanşo',
      scientific: 'Kalanchoe blossfeldiana',
      waterDays: 12,
      waterText: '10–14 günde bir',
      light: 'Bol ışık',
      temperature: '13–26 °C',
      tip: 'Solan çiçekleri kopar, yeni çiçeklenmeyi teşvik eder.',
    ),
    CareInfo(
      keys: ['schlumbergera'],
      trName: 'Yılbaşı Kaktüsü',
      scientific: 'Schlumbergera',
      waterDays: 10,
      waterText: '7–12 günde bir',
      light: 'Parlak, dolaylı',
      temperature: '15–24 °C',
      tip: 'Çiçek tomurcuğu varken yerini değiştirme.',
    ),
    CareInfo(
      keys: ['hedera'],
      trName: 'Duvar Sarmaşığı',
      scientific: 'Hedera helix',
      waterDays: 6,
      waterText: '5–7 günde bir',
      light: 'Parlak, dolaylı',
      temperature: '10–21 °C',
      tip: 'Serin ortamları sever; kalorifer yanında kurur.',
    ),
    CareInfo(
      keys: ['ocimum'],
      trName: 'Fesleğen',
      scientific: 'Ocimum basilicum',
      waterDays: 2,
      waterText: '1–2 günde bir',
      light: 'Bol güneş',
      temperature: '18–30 °C',
      tip: 'Uçları koparınca daha gür büyür; toprağı nemli tut.',
    ),
  ];

  static const CareInfo _cactus = CareInfo(
    keys: [],
    trName: 'Kaktüs',
    scientific: 'Cactaceae',
    waterDays: 21,
    waterText: '3 haftada bir',
    light: 'Bol güneş',
    temperature: '15–30 °C',
    tip: 'Toprak tamamen kurumadan sulama, kışın ayda bir yeterli.',
    kind: PlantKind.snake,
  );

  /// Bilimsel ad ve aileye göre eşleşme arar.
  static CareInfo? match(String scientific, {String? family}) {
    final s = scientific.toLowerCase().trim();
    CareInfo? best;
    var bestLen = 0;
    for (final c in all) {
      for (final k in c.keys) {
        if (s.startsWith(k) && k.length > bestLen) {
          best = c;
          bestLen = k.length;
        }
      }
    }
    if (best != null) return best;
    if ((family ?? '').toLowerCase() == 'cactaceae') return _cactus;
    return null;
  }

  /// Hiç eşleşme yoksa kullanılacak genel bakım.
  static CareInfo generic(String scientific, String name) => CareInfo(
        keys: const [],
        trName: name,
        scientific: scientific,
        waterDays: 7,
        waterText: 'Haftada bir (genel öneri)',
        light: 'Parlak, dolaylı',
        temperature: '18–25 °C',
        tip: 'Sulamadan önce parmağınla toprağı yokla: üst 2–3 cm kuruysa sula.',
      );
}
