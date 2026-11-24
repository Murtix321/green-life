import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../data/care_db.dart';
import '../models/plant.dart';

/// API anahtarları kodun içine yazılmaz; çalıştırırken verilir:
/// flutter run --dart-define=PLANTNET_KEY=xxx --dart-define=PERENUAL_KEY=yyy
const plantNetKey = String.fromEnvironment('PLANTNET_KEY');
const perenualKey = String.fromEnvironment('PERENUAL_KEY');

class IdCandidate {
  final String scientific;
  final String? commonName;
  final String? family;
  final double score; // 0..1
  const IdCandidate(this.scientific, this.commonName, this.family, this.score);

  int get percent => (score * 100).round();
}

class PlantIdException implements Exception {
  final String message;
  PlantIdException(this.message);
  @override
  String toString() => message;
}

class PlantIdService {
  static bool get hasPlantNet => plantNetKey.isNotEmpty;

  /// Pl@ntNet ile fotoğraftan tanıma (ücretsiz: günde 500 tanıma).
  static Future<List<IdCandidate>> identify(File image) async {
    if (!hasPlantNet) {
      throw PlantIdException(
        'Pl@ntNet API anahtarı eklenmemiş. my.plantnet.org adresinden ücretsiz anahtar alıp '
        '--dart-define=PLANTNET_KEY=... ile çalıştır.',
      );
    }
    final uri = Uri.parse(
      'https://my-api.plantnet.org/v2/identify/all'
      '?api-key=$plantNetKey&lang=tr&nb-results=3',
    );
    final req = http.MultipartRequest('POST', uri)
      ..fields['organs'] = 'auto'
      ..files.add(await http.MultipartFile.fromPath('images', image.path));

    final http.Response res;
    try {
      res = await http.Response.fromStream(
        await req.send().timeout(const Duration(seconds: 30)),
      );
    } on SocketException {
      throw PlantIdException('İnternet bağlantısı yok gibi görünüyor.');
    } catch (_) {
      throw PlantIdException('Tanıma servisine ulaşılamadı. Biraz sonra tekrar dene.');
    }

    if (res.statusCode == 404) {
      throw PlantIdException('Bitki tanınamadı. Yaprakları yakından ve net çekmeyi dene.');
    }
    if (res.statusCode == 429) {
      throw PlantIdException('Günlük tanıma kotası doldu. Yarın tekrar dene.');
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw PlantIdException('Pl@ntNet API anahtarı geçersiz.');
    }
    if (res.statusCode != 200) {
      throw PlantIdException('Tanıma başarısız (hata ${res.statusCode}).');
    }

    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final results = (body['results'] as List? ?? []);
    final out = <IdCandidate>[];
    for (final r in results) {
      final m = Map<String, dynamic>.from(r as Map);
      final sp = Map<String, dynamic>.from((m['species'] ?? {}) as Map);
      final names = (sp['commonNames'] as List? ?? []).cast<dynamic>();
      final fam = sp['family'] is Map ? (sp['family'] as Map)['scientificNameWithoutAuthor'] : null;
      out.add(IdCandidate(
        (sp['scientificNameWithoutAuthor'] ?? '').toString(),
        names.isEmpty ? null : names.first.toString(),
        fam?.toString(),
        (m['score'] as num?)?.toDouble() ?? 0,
      ));
    }
    if (out.isEmpty) {
      throw PlantIdException('Bitki tanınamadı. Başka bir açıdan tekrar dene.');
    }
    return out;
  }

  /// Bakım bilgisini bulur: önce yerel Türkçe veritabanı, yoksa (anahtar varsa) Perenual,
  /// o da yoksa genel bakım önerisi.
  static Future<CareInfo> careFor(IdCandidate c) async {
    final local = CareDb.match(c.scientific, family: c.family);
    if (local != null) return local;
    final name = c.commonName ?? c.scientific;
    if (perenualKey.isNotEmpty) {
      final remote = await _perenual(c.scientific, name);
      if (remote != null) return remote;
    }
    return CareDb.generic(c.scientific, name);
  }

  static Future<CareInfo?> _perenual(String scientific, String name) async {
    try {
      final q = Uri.encodeQueryComponent(scientific);
      final uri = Uri.parse('https://perenual.com/api/v2/species-list?key=$perenualKey&q=$q');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final data = (body['data'] as List? ?? []);
      if (data.isEmpty) return null;
      final first = Map<String, dynamic>.from(data.first as Map);
      final watering = (first['watering'] ?? '').toString().toLowerCase();
      final sunlight = first['sunlight'];
      final days = switch (watering) {
        'frequent' => 4,
        'average' => 7,
        'minimum' => 14,
        'none' => 21,
        _ => 7,
      };
      final waterText = switch (watering) {
        'frequent' => '3–5 günde bir',
        'average' => 'Haftada bir',
        'minimum' => '2 haftada bir',
        'none' => '3 haftada bir',
        _ => 'Haftada bir (genel öneri)',
      };
      String light = 'Parlak, dolaylı';
      if (sunlight is List && sunlight.isNotEmpty) {
        final s = sunlight.first.toString().toLowerCase();
        if (s.contains('full sun')) {
          light = 'Bol güneş';
        } else if (s.contains('shade')) {
          light = 'Yarı gölge';
        }
      }
      return CareInfo(
        keys: const [],
        trName: name,
        scientific: scientific,
        waterDays: days,
        waterText: waterText,
        light: light,
        temperature: '18–25 °C',
        tip: 'Sulamadan önce toprağı yokla: üst 2–3 cm kuruysa sula.',
        kind: PlantKind.leafy,
      );
    } catch (_) {
      return null;
    }
  }
}
