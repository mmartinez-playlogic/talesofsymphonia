#!/usr/bin/env python3
"""Convert a game-script transcript into src/data/script/<lang>.json keyed by our scene ids.

Input: a UTF-8 text file you prepare from your own transcript, with scene markers and "Speaker: line" rows:

    ## iselia_school.intro.01
    Raine: ...Lloyd Irving.
    Lloyd: ¿Eh? ¿Ya se ha acabado la clase?
    (narración sin hablante)

    ## iselia_school.intro.02
    ...

Lines without "Speaker:" become narration (speaker ""). Blank lines are ignored.
Scene ids are listed in src/data/script/_template_es.json (generated from the maps).

Usage:
  python3 tools/import_script.py transcript.txt es          # writes src/data/script/es.json
  python3 tools/import_script.py transcript.txt es --check  # also reports ids missing/unknown vs the template
"""
import json, os, re, sys

if len(sys.argv) < 3:
    print(__doc__)
    sys.exit(1)
src, lang = sys.argv[1], sys.argv[2]
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out_path = os.path.join(root, "src/data/script", lang + ".json")
template_path = os.path.join(root, "src/data/script/_template_es.json")

scenes, cur = {}, None
for raw in open(src, encoding="utf-8"):
    line = raw.rstrip("\n").strip()
    if not line:
        continue
    m = re.match(r"^##\s*([A-Za-z0-9_.]+)\s*$", line)
    if m:
        cur = m.group(1)
        scenes.setdefault(cur, [])
        continue
    if cur is None:
        continue
    m = re.match(r"^([^:：]{1,32})[:：]\s*(.+)$", line)
    if m and not line.startswith("("):
        scenes[cur].append({"speaker": m.group(1).strip(), "text": m.group(2).strip()})
    else:
        scenes[cur].append({"speaker": "", "text": line})

existing = {}
if os.path.exists(out_path):
    existing = json.load(open(out_path, encoding="utf-8"))
existing.update(scenes)
json.dump(existing, open(out_path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("wrote %s: %d scenes (%d new/updated), %d lines" % (out_path, len(existing), len(scenes), sum(len(v) for v in scenes.values())))

if "--check" in sys.argv and os.path.exists(template_path):
    tpl = json.load(open(template_path, encoding="utf-8"))
    missing = [k for k in tpl if k not in existing]
    unknown = [k for k in existing if k not in tpl]
    print("missing (still using fallback text): %d" % len(missing))
    for k in missing:
        print("   ", k)
    if unknown:
        print("unknown ids (check spelling):", unknown)
