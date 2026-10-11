#!/usr/bin/env python3
"""Builds Shared/Resources/circuits.json from the bacinger/f1-circuits GeoJSON.

Source data: https://github.com/bacinger/f1-circuits (MIT License, (c) Tomislav Bacinger).

Each circuit is projected to a flat plane, rotated so it sits as wide as possible
(widgets are mostly landscape), normalised so its longest side is 1.0 and stored as a
flat [x0, y0, x1, y1, ...] list. Keys are mapped to Jolpica/Ergast circuit IDs.

Usage: python3 tools/build_circuits.py /path/to/f1-circuits.geojson
"""
import json
import math
import sys
from pathlib import Path

# bacinger id -> Jolpica circuitId aliases
ID_MAP = {
    "au-1953": ["albert_park"],
    "bh-2002": ["bahrain"],
    "cn-2004": ["shanghai"],
    "es-1991": ["catalunya"],
    "mc-1929": ["monaco"],
    "ca-1978": ["villeneuve"],
    "fr-1969": ["ricard"],
    "at-1969": ["red_bull_ring"],
    "gb-1948": ["silverstone"],
    "de-1932": ["hockenheimring"],
    "hu-1986": ["hungaroring"],
    "be-1925": ["spa"],
    "it-1922": ["monza"],
    "sg-2008": ["marina_bay"],
    "ru-2014": ["sochi"],
    "jp-1962": ["suzuka"],
    "us-2012": ["americas"],
    "mx-1962": ["rodriguez"],
    "br-1940": ["interlagos"],
    "ae-2009": ["yas_marina"],
    "it-1953": ["imola"],
    "de-1927": ["nurburgring"],
    "pt-2008": ["portimao"],
    "it-1914": ["mugello"],
    "my-1999": ["sepang"],
    "tr-2005": ["istanbul"],
    "nl-1948": ["zandvoort"],
    "fr-1960": ["magny_cours"],
    "pt-1972": ["estoril"],
    "br-1977": ["jacarepagua"],
    "sa-2021": ["jeddah"],
    "us-2022": ["miami"],
    "qa-2004": ["losail"],
    "es-2026": ["madring", "madrid"],
    "az-2016": ["baku"],
    "us-2023": ["vegas"],
    "us-1909": ["indianapolis"],
    "ar-1952": ["galvez"],
    "za-1961": ["kyalami"],
    "us-1956": ["watkins_glen"],
}


def project(coords):
    lat0 = sum(c[1] for c in coords) / len(coords)
    lon0 = sum(c[0] for c in coords) / len(coords)
    k = math.cos(math.radians(lat0))
    # Screen space: x to the right, y downwards.
    return [((lon - lon0) * k, -(lat - lat0)) for lon, lat in coords]


def rotate(points, degrees):
    a = math.radians(degrees)
    ca, sa = math.cos(a), math.sin(a)
    return [(x * ca - y * sa, x * sa + y * ca) for x, y in points]


def bounds(points):
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    return min(xs), min(ys), max(xs), max(ys)


def widest(points):
    best = None
    for deg in range(0, 180, 1):
        r = rotate(points, deg)
        x0, y0, x1, y1 = bounds(r)
        ratio = (x1 - x0) / max(y1 - y0, 1e-9)
        if best is None or ratio > best[0]:
            best = (ratio, deg, r)
    return best[2]


def main(path):
    data = json.loads(Path(path).read_text())
    out = []
    for feature in data["features"]:
        props = feature["properties"]
        key = props["id"]
        if key not in ID_MAP:
            print(f"skipping unmapped circuit {key}", file=sys.stderr)
            continue
        coords = feature["geometry"]["coordinates"]
        if coords[0] == coords[-1]:
            coords = coords[:-1]
        pts = widest(project(coords))
        x0, y0, x1, y1 = bounds(pts)
        span = max(x1 - x0, y1 - y0)
        norm = [((x - x0) / span, (y - y0) / span) for x, y in pts]
        flat = []
        for x, y in norm:
            flat.extend([round(x, 4), round(y, 4)])
        out.append({
            "key": key,
            "ids": ID_MAP[key],
            "name": props["Name"],
            "locality": props["Location"],
            "length": props.get("length"),
            "firstGP": props.get("firstgp"),
            "w": round((x1 - x0) / span, 4),
            "h": round((y1 - y0) / span, 4),
            "p": flat,
        })
    out.sort(key=lambda c: c["key"])
    payload = {
        "source": "bacinger/f1-circuits (MIT License, (c) Tomislav Bacinger)",
        "circuits": out,
    }
    dest = Path(__file__).resolve().parent.parent / "Shared" / "Resources" / "circuits.json"
    dest.write_text(json.dumps(payload, separators=(",", ":")))
    print(f"wrote {len(out)} circuits to {dest} ({dest.stat().st_size} bytes)")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "f1-circuits.geojson")
