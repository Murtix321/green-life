"""Wikimedia Commons'tan saksıda ev bitkisi fotoğrafları indirir (serbest lisans).

Yalnızca CC0, Public domain, CC BY ve CC BY-SA lisanslı dosyalar alınır;
sahip ve lisans design-assets/commons/credits.json'a yazılır.
"""
import json
import pathlib
import re
import time
import urllib.parse
import urllib.request

QUERIES = [
    ("monstera", "Monstera deliciosa pot"),
    ("monstera", "Monstera deliciosa houseplant"),
    ("pasa-kilici", "Sansevieria pot"),
    ("baris-cicegi", "Spathiphyllum pot"),
    ("zamia", "Zamioculcas zamiifolia pot"),
    ("dua-cicegi", "Calathea pot"),
    ("pilea", "Pilea peperomioides pot"),
    ("kaucuk", "Ficus elastica pot"),
    ("orkide", "Phalaenopsis pot"),
    ("pothos", "Epipremnum aureum pot"),
    ("kurdele", "Chlorophytum comosum pot"),
    ("aloe", "Aloe vera pot"),
    ("ev-bitkisi", "houseplant white pot"),
    ("ev-bitkisi", "potted plant white background"),
]
OK = re.compile(r"^(cc0|public domain|pd|cc by(-sa)? [0-9.]+|cc-by(-sa)?-[0-9.]+)", re.I)
PER_QUERY = 8
OUT = pathlib.Path("design-assets/commons")
OUT.mkdir(parents=True, exist_ok=True)
H = {"User-Agent": "GreenLife-design/0.1 (https://github.com/Murtix321/green-life)"}
API = "https://commons.wikimedia.org/w/api.php"


def get_json(params):
    url = API + "?" + urllib.parse.urlencode(params)
    with urllib.request.urlopen(urllib.request.Request(url, headers=H), timeout=30) as r:
        return json.load(r)


def strip_html(s):
    return re.sub(r"<[^>]+>", "", s or "").strip()


credits, seen = [], set()
for slug, q in QUERIES:
    try:
        res = get_json({
            "action": "query", "format": "json", "generator": "search", "gsrsearch": f"{q} filetype:bitmap",
            "gsrnamespace": 6, "gsrlimit": 25, "prop": "imageinfo",
            "iiprop": "url|extmetadata|size", "iiurlwidth": 1000,
        })
        pages = sorted(res.get("query", {}).get("pages", {}).values(), key=lambda p: p.get("index", 0))
        n = 0
        for p in pages:
            if n >= PER_QUERY:
                break
            ii = (p.get("imageinfo") or [{}])[0]
            meta = ii.get("extmetadata", {})
            lic = strip_html(meta.get("LicenseShortName", {}).get("value"))
            if not OK.match(lic) or p["title"] in seen or ii.get("width", 0) < 600:
                continue
            seen.add(p["title"])
            n += 1
            dest = OUT / f"{slug}-c{len([c for c in credits if c['slug'] == slug]) + 1}.jpg"
            with urllib.request.urlopen(urllib.request.Request(ii["thumburl"], headers=H), timeout=60) as r:
                dest.write_bytes(r.read())
            credits.append({
                "file": dest.name, "slug": slug, "title": p["title"],
                "artist": strip_html(meta.get("Artist", {}).get("value"))[:120],
                "license": lic, "source": ii.get("descriptionurl"),
            })
            time.sleep(0.3)
        print(f"{q}: {n} foto")
    except Exception as e:
        print(f"{q}: HATA {e}")
    time.sleep(1)

(OUT / "credits.json").write_text(json.dumps(credits, ensure_ascii=False, indent=1))
print("toplam", len(credits))
