"""Tasarım ve uygulama için gerçek bitki fotoğraflarını indirir.

Kaynak: iNaturalist. Yalnızca serbest kullanım lisansları alınır (CC0, CC-BY, CC-BY-SA);
her fotoğrafın sahibi ve lisansı design-assets/photos/credits.json dosyasına yazılır.
"""
import json
import pathlib
import time
import urllib.parse
import urllib.request

SPECIES = [
    ("monstera", "Monstera deliciosa"),
    ("pasa-kilici", "Dracaena trifasciata"),
    ("baris-cicegi", "Spathiphyllum"),
    ("pothos", "Epipremnum aureum"),
    ("kaucuk", "Ficus elastica"),
    ("keman-yaprakli-incir", "Ficus lyrata"),
    ("orkide", "Phalaenopsis"),
    ("zamia", "Zamioculcas zamiifolia"),
    ("dua-cicegi", "Goeppertia orbifolia"),
    ("lavanta", "Lavandula angustifolia"),
    ("aloe", "Aloe vera"),
    ("kurdele", "Chlorophytum comosum"),
    ("antoryum", "Anthurium andraeanum"),
    ("begonya", "Begonia maculata"),
    ("pilea", "Pilea peperomioides"),
]
OK = {"cc0", "cc-by", "cc-by-sa"}
PER_SPECIES = 6
OUT = pathlib.Path("design-assets/photos")
OUT.mkdir(parents=True, exist_ok=True)
H = {"User-Agent": "GreenLife-design (github.com/Murtix321/green-life)"}


def get_json(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers=H), timeout=30) as r:
        return json.load(r)


credits = []
for slug, name in SPECIES:
    try:
        q = urllib.parse.urlencode({"q": name, "taxon_id": 47126, "per_page": 3, "locale": "tr"})
        res = get_json(f"https://api.inaturalist.org/v1/taxa?{q}")["results"]
        taxon = next((t for t in res if t["name"].lower() == name.lower()), res[0])
        full = get_json(f"https://api.inaturalist.org/v1/taxa/{taxon['id']}?locale=tr")["results"][0]
        photos = [tp["photo"] for tp in full.get("taxon_photos", [])]
        # Evde/saksıda yetiştirilen (captive) gözlemler: gerçek ev bitkisi görüntüsü
        oq = urllib.parse.urlencode({
            "taxon_id": taxon["id"], "captive": "true", "photo_license": "cc0,cc-by,cc-by-sa",
            "order_by": "votes", "per_page": 12, "photos": "true",
        })
        for o in get_json(f"https://api.inaturalist.org/v1/observations?{oq}")["results"]:
            photos.extend(o.get("photos", [])[:1])
        seen, good = set(), []
        for p in photos:
            if (p.get("license_code") or "").lower() in OK and p["id"] not in seen:
                seen.add(p["id"])
                good.append(p)
        print(f"{name}: {len(photos)} foto, {len(good)} serbest lisanslı")
        for i, p in enumerate(good[:PER_SPECIES]):
            url = p["url"].replace("/square.", "/large.").replace("/medium.", "/large.")
            dest = OUT / f"{slug}-{i + 1}.jpg"
            with urllib.request.urlopen(urllib.request.Request(url, headers=H), timeout=60) as r:
                dest.write_bytes(r.read())
            credits.append({
                "file": dest.name,
                "species": name,
                "tr": full.get("preferred_common_name"),
                "attribution": p.get("attribution"),
                "license": p.get("license_code"),
                "source": f"https://www.inaturalist.org/photos/{p['id']}",
            })
            time.sleep(0.4)
    except Exception as e:  # tek tür hatası diğerlerini durdurmasın
        print(f"{name}: HATA {e}")
    time.sleep(1)

(OUT / "credits.json").write_text(json.dumps(credits, ensure_ascii=False, indent=1))
print("toplam", len(credits), "foto")
