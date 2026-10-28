"""Extract Tales of Vesperia DE character meshes/textures for STYLE RESEARCH using VesperiaTools' Python API.
Nothing here ships with the game; output goes to assets/ref/vesperia/ (gitignored).

Usage (from this project root, NOT inside Blender):
  python3 tools/vesperia_extract.py --tools /path/to/VesperiaTools --svo /path/to/PACKAGE.SVO [--out assets/ref/vesperia]
Steps performed: SVO -> DAT (TLZC) -> .dec -> FPS4 pieces -> SPM/SPV to OBJ + TXM/TXV to DDS.
Requires: git clone https://github.com/hueyyeng/vesperiatools (branch develop), Python 3.10+.
Only the parser/exporter modules are imported (no PySide2 GUI needed).
"""
import argparse, os, sys, glob, traceback

ap = argparse.ArgumentParser()
ap.add_argument("--tools", required=True, help="path to the VesperiaTools checkout")
ap.add_argument("--svo", required=True, help="an .SVO package from the game's data folder")
ap.add_argument("--out", default="assets/ref/vesperia")
ap.add_argument("--verbose", action="store_true")
args = ap.parse_args()

sys.path.insert(0, os.path.abspath(args.tools))
from parsers.parser import parse_svo, parse_dat, parse_dec, parse_dec_ext  # noqa: E402
from utils.exporter import export_wavefront_obj, export_dds_textures      # noqa: E402

os.makedirs(args.out, exist_ok=True)
svo = os.path.abspath(args.svo)
svo_dir = os.path.join(os.path.dirname(svo), os.path.splitext(os.path.basename(svo))[0])

print("[1/4] SVO ->", svo_dir)
parse_svo(svo, verbose=args.verbose)

print("[2/4] DAT -> .dec")
for dat in glob.glob(os.path.join(svo_dir, "**", "*.DAT"), recursive=True) + glob.glob(os.path.join(svo_dir, "**", "*.dat"), recursive=True):
    try:
        parse_dat(dat, verbose=args.verbose)
    except Exception as e:
        print("   skip", dat, e)

print("[3/4] .dec -> pieces")
for dec in glob.glob(os.path.join(svo_dir, "**", "*.dec"), recursive=True):
    try:
        parse_dec(dec, verbose=args.verbose)
    except Exception as e:
        print("   skip", dec, e)
for piece in glob.glob(os.path.join(svo_dir, "**", "*.dec.ext", "*"), recursive=True):
    if os.path.isfile(piece):
        try:
            parse_dec_ext(piece, verbose=args.verbose)
        except Exception as e:
            print("   skip", piece, e)

print("[4/4] SPM/SPV -> OBJ, TXM/TXV -> DDS")
n_obj = n_tex = 0
for spm in glob.glob(os.path.join(svo_dir, "**", "*.SPM"), recursive=True):
    name = os.path.splitext(os.path.basename(spm))[0]
    out_dir = os.path.join(args.out, name)
    os.makedirs(out_dir, exist_ok=True)
    try:
        export_wavefront_obj(spm, out_dir, verbose=args.verbose)
        n_obj += 1
    except Exception:
        print("   mesh failed:", spm)
        traceback.print_exc()
for txm in glob.glob(os.path.join(svo_dir, "**", "*.TXM"), recursive=True):
    name = os.path.splitext(os.path.basename(txm))[0]
    out_dir = os.path.join(args.out, name)
    os.makedirs(out_dir, exist_ok=True)
    try:
        export_dds_textures(txm, out_dir, verbose=args.verbose)
        n_tex += 1
    except Exception:
        print("   textures failed:", txm)
        traceback.print_exc()
print("done: %d mesh packages, %d texture packages -> %s" % (n_obj, n_tex, args.out))
