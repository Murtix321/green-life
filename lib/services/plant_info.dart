import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// public-apis listesinden seçilen, anahtar istemeyen ücretsiz kaynaklar:
///  - iNaturalist  (api.inaturalist.org): Türkçe ad, gerçek fotoğraf, bitki arama
///  - Wikipedia    (tr / en .wikipedia.org): kısa tanıtım metni
/// Sonuçlar telefonda önbelleğe alınır; aynı bitki için tekrar istek atılmaz.

const _ua = {'User-Agent': 'GreenLife/0.2 (ev bitkisi bakim uygulamasi)'};
const _plantae = 47126; // iNaturalist'te "Bitkiler" alemi

class PlantInfo {
  final String scientific;
  final String? trName;
  final String? photoUrl;
  final String? photoCredit;
  final String? summary;
  final bool summaryIsTurkish;
  final String? wikiUrl;

  const PlantInfo({
    required this.scientific,
    this.trName,
    this.photoUrl,
    this.photoCredit,
    this.summary,
    this.summaryIsTurkish = true,
    this.wikiUrl,
  });

  bool get isEmpty => photoUrl == null && summary == null && trName == null;

  Map<String, dynamic> toJson() => {
        's': scientific,
        'tr': trName,
        'p': photoUrl,
        'pc': photoCredit,
        'sum': summary,
        'sumTr': summaryIsTurkish,
        'w': wikiUrl,
      };

  factory PlantInfo.fromJson(Map<String, dynamic> j) => PlantInfo(
        scientific: j['s'] as String,
        trName: j['tr'] as String?,
        photoUrl: j['p'] as String?,
        photoCredit: j['pc'] as String?,
        summary: j['sum'] as String?,
        summaryIsTurkish: j['sumTr'] != false,
        wikiUrl: j['w'] as String?,
      );
}

/// Arama sonucu (Listeden ekle ekranı).
class TaxonHit {
  final int id;
  final String scientific;
  final String? trName;
  final String? thumbUrl;
  final String rank;
  const TaxonHit(this.id, this.scientific, this.trName, this.thumbUrl, this.rank);

  String get title => (trName == null || trName!.isEmpty) ? scientific : _cap(trName!);
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class PlantInfoService {
  static final Map<String, PlantInfo> _mem = {};

  static String _key(String sci) => 'pinfo_v2_${sci.toLowerCase().trim()}';

  /// Bitkinin Türkçe adı, fotoğrafı ve özeti. İnternet yoksa önbellekten döner.
  static Future<PlantInfo?> fetch(String scientific) async {
    final sci = scientific.trim();
    if (sci.isEmpty) return null;
    if (_mem.containsKey(sci)) return _mem[sci];

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_key(sci));
    if (cached != null) {
      try {
        final info = PlantInfo.fromJson(Map<String, dynamic>.from(jsonDecode(cached) as Map));
        _mem[sci] = info;
        return info;
      } catch (_) {}
    }

    final taxon = await _inatTaxon(sci);
    final title = (taxon?['name'] as String?) ?? sci;
    final common = taxon?['preferred_common_name'] as String?;
    // Vikipedi: önce bilimsel ad, sonra Türkçe ad, en son İngilizce
    var wikiTr = await _wiki('tr', title);
    if (wikiTr == null && common != null && common.isNotEmpty) {
      wikiTr = await _wiki('tr', '${common[0].toUpperCase()}${common.substring(1).toLowerCase()}');
    }
    final wiki = wikiTr ?? await _wiki('en', title);

    final photo = taxon?['default_photo'] is Map ? Map<String, dynamic>.from(taxon!['default_photo'] as Map) : null;
    final info = PlantInfo(
      scientific: sci,
      trName: (common == null || common.isEmpty) ? null : _cap(common),
      photoUrl: (photo?['medium_url'] as String?) ?? wiki?.thumb,
      photoCredit: photo?['attribution'] as String?,
      summary: wiki?.extract,
      summaryIsTurkish: wikiTr != null,
      wikiUrl: wiki?.url ?? taxon?['wikipedia_url'] as String?,
    );
    if (info.isEmpty) return null;
    _mem[sci] = info;
    await prefs.setString(_key(sci), jsonEncode(info.toJson()));
    return info;
  }

  /// Her bitkiyi Türkçe veya bilimsel adla ara (yalnızca bitkiler).
  static Future<List<TaxonHit>> search(String q) async {
    final query = q.trim();
    if (query.length < 3) return [];
    try {
      final uri = Uri.https('api.inaturalist.org', '/v1/taxa/autocomplete', {
        'q': query,
        'taxon_id': '$_plantae',
        'locale': 'tr',
        'per_page': '12',
        'is_active': 'true',
      });
      final res = await http.get(uri, headers: _ua).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return [];
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final out = <TaxonHit>[];
      for (final r in (body['results'] as List? ?? [])) {
        final m = Map<String, dynamic>.from(r as Map);
        final rank = (m['rank'] ?? '').toString();
        if (rank != 'species' && rank != 'genus' && rank != 'variety' && rank != 'hybrid') continue;
        final photo = m['default_photo'] is Map ? Map<String, dynamic>.from(m['default_photo'] as Map) : null;
        out.add(TaxonHit(
          (m['id'] as num).toInt(),
          (m['name'] ?? '').toString(),
          m['preferred_common_name'] as String?,
          photo?['square_url'] as String?,
          rank,
        ));
      }
      return out;
    } catch (e) {
      debugPrint('iNaturalist araması başarısız: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> _inatTaxon(String sci) async {
    try {
      final uri = Uri.https('api.inaturalist.org', '/v1/taxa', {
        'q': sci,
        'taxon_id': '$_plantae',
        'locale': 'tr',
        'per_page': '5',
        'is_active': 'true',
      });
      final res = await http.get(uri, headers: _ua).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final list = (body['results'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (list.isEmpty) return null;
      final lower = sci.toLowerCase();
      return list.firstWhere(
        (t) => (t['name'] ?? '').toString().toLowerCase() == lower,
        orElse: () => list.first,
      );
    } catch (e) {
      debugPrint('iNaturalist bilgisi alınamadı: $e');
      return null;
    }
  }

  static Future<_Wiki?> _wiki(String lang, String title) async {
    try {
      final t = Uri.encodeComponent(title.replaceAll(' ', '_'));
      final uri = Uri.parse('https://$lang.wikipedia.org/api/rest_v1/page/summary/$t?redirect=true');
      final res = await http.get(uri, headers: _ua).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (j['type'] == 'disambiguation') return null;
      final extract = (j['extract'] ?? '').toString().trim();
      if (extract.isEmpty) return null;
      final thumb = j['thumbnail'] is Map ? (j['thumbnail'] as Map)['source'] as String? : null;
      String? url;
      final cu = j['content_urls'];
      if (cu is Map && cu['mobile'] is Map) url = (cu['mobile'] as Map)['page'] as String?;
      return _Wiki(extract, thumb, url);
    } catch (_) {
      return null;
    }
  }
}

class _Wiki {
  final String extract;
  final String? thumb;
  final String? url;
  const _Wiki(this.extract, this.thumb, this.url);
}
