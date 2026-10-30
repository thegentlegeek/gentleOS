"""Build the launcher's emoji/glyph data (LauncherEmoji.qml) as JSON.

usage: emoji.py EMOJI_TEST ANNOTATIONS ANNOTATIONS_DERIVED GLYPHNAMES > out.json

EMOJI_TEST is Unicode's emoji-test.txt (names and groups), ANNOTATIONS* are
CLDR's English annotation files (search keywords), GLYPHNAMES is Nerd Fonts'
glyphnames.json. Output: {"emoji": [{c, n, k, g}], "nerd": [{c, n}],
"symbols": [{c, n}]} with c the character, n its name, k keywords, g group.
"""

import json
import re
import sys
import unicodedata
import xml.etree.ElementTree as ET

# Typographic and UI symbols worth having one search away.
SYMBOLS = (
    "→←↑↓↔↕⇒⇐⇔⇧⇥⏎⌫⌘⌥⌃⎋⏻"
    "×÷±≈≠≤≥∞√∑∏∫∂∆πµΩ°′″‰"
    "€£¥¢₿§¶†‡•·…—–«»‹›‘’“”¡¿"
    "©®™✓✗✔✘★☆♥♦♣♠⚠⚡☀☁☂☃♪♫"
    "½⅓⅔¼¾⁰¹²³⁴⁵⁶⁷⁸⁹₀₁₂₃"
    "─│┌┐└┘├┤┬┴┼═║╔╗╚╝"
)


def emoji(test_path):
    out = []
    group = ""
    line_re = re.compile(r"^([0-9A-F ]+?)\s*;\s*fully-qualified\s*#\s*(\S+)\s+E[\d.]+\s+(.+)$")
    with open(test_path, encoding="utf-8") as f:
        for line in f:
            if line.startswith("# group:"):
                group = line.split(":", 1)[1].strip()
                continue
            m = line_re.match(line.strip())
            # Skin-tone and hair variants would multiply the list; the base
            # emoji is what people search for.
            if not m or group == "Component" or "skin tone" in m.group(3):
                continue
            out.append({"c": m.group(2), "n": m.group(3), "g": group})
    return out


def keywords(paths):
    words = {}
    for path in paths:
        for a in ET.parse(path).getroot().iter("annotation"):
            if a.get("type") == "tts" or not a.text:
                continue
            words.setdefault(a.get("cp"), [])
            words[a.get("cp")] += [w.strip() for w in a.text.split("|") if w.strip()]
    return words


def nerd(glyphnames_path):
    with open(glyphnames_path, encoding="utf-8") as f:
        data = json.load(f)
    return [
        {"c": v["char"], "n": k.replace("-", " ").replace("_", " ")}
        for k, v in data.items()
        if k != "METADATA" and isinstance(v, dict) and "char" in v
    ]


def main():
    test, ann, derived, glyphs = sys.argv[1:5]
    words = keywords([ann, derived])
    em = emoji(test)
    for e in em:
        # CLDR keys annotations by the emoji without the VS16 selector.
        k = words.get(e["c"]) or words.get(e["c"].replace("️", "")) or []
        e["k"] = " ".join(w for w in dict.fromkeys(k) if w != e["n"])
    symbols = [{"c": c, "n": unicodedata.name(c, "").lower()} for c in dict.fromkeys(SYMBOLS)]
    json.dump({"emoji": em, "nerd": nerd(glyphs), "symbols": symbols},
              sys.stdout, ensure_ascii=False, separators=(",", ":"))


if __name__ == "__main__":
    main()
