import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Open-Meteo (public-apis listesinden): anahtar istemez, ticari olmayan kullanım için ücretsiz.
class WeatherNow {
  final double temp;
  final double tMax;
  final int humidity;
  const WeatherNow(this.temp, this.tMax, this.humidity);

  /// Ev bitkileri için günün ipucu.
  String get tip {
    if (tMax >= 30) {
      return 'Bugün ${tMax.round()}° ve sıcak: toprak her zamankinden hızlı kurur. Akşamüstü toprağı yokla.';
    }
    if (humidity < 35) {
      return 'Hava kuru (nem %$humidity): Monstera, Kalatya gibi tropikal bitkilerin yapraklarına su püskürt.';
    }
    if (tMax <= 5) {
      return 'Hava soğuk (${tMax.round()}°): bitkileri soğuk cam ve kapı aralıklarından uzak tut, sulamayı azalt.';
    }
    if (humidity > 80) {
      return 'Nem yüksek (%$humidity): toprak geç kurur, sulamadan önce mutlaka kontrol et.';
    }
    return 'Bugün bitkilerin için ideal bir gün (${temp.round()}°, nem %$humidity).';
  }
}

class City {
  final String name;
  final double lat;
  final double lon;
  const City(this.name, this.lat, this.lon);
}

class WeatherService {
  static WeatherNow? _cache;
  static DateTime? _cacheAt;
  static String? _cacheFor;

  static Future<WeatherNow?> now(double lat, double lon) async {
    final key = '$lat,$lon';
    if (_cache != null && _cacheFor == key && DateTime.now().difference(_cacheAt!).inMinutes < 30) {
      return _cache;
    }
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '$lat',
        'longitude': '$lon',
        'current': 'temperature_2m,relative_humidity_2m',
        'daily': 'temperature_2m_max',
        'timezone': 'auto',
        'forecast_days': '1',
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final cur = Map<String, dynamic>.from(j['current'] as Map);
      final daily = Map<String, dynamic>.from(j['daily'] as Map);
      final w = WeatherNow(
        (cur['temperature_2m'] as num).toDouble(),
        ((daily['temperature_2m_max'] as List).first as num).toDouble(),
        (cur['relative_humidity_2m'] as num).round(),
      );
      _cache = w;
      _cacheAt = DateTime.now();
      _cacheFor = key;
      return w;
    } catch (e) {
      debugPrint('Hava durumu alınamadı: $e');
      return null;
    }
  }

  /// Şehir adından konum bulur (Open-Meteo Geocoding).
  static Future<City?> findCity(String name) async {
    try {
      final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': name.trim(),
        'count': '1',
        'language': 'tr',
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final list = j['results'] as List?;
      if (list == null || list.isEmpty) return null;
      final m = Map<String, dynamic>.from(list.first as Map);
      return City(
        (m['name'] ?? name).toString(),
        (m['latitude'] as num).toDouble(),
        (m['longitude'] as num).toDouble(),
      );
    } catch (e) {
      debugPrint('Şehir bulunamadı: $e');
      return null;
    }
  }
}
