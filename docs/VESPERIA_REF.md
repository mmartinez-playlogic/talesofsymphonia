# Investigación de estilo: Tales of Vesperia (Definitive Edition)

Decisión de Mateo (2026-10-28): los modelos de Vesperia se extraen **solo como material de investigación**
para imitar su estilo (proporciones, sombreado en bandas, contornos, paleta). Viven en `assets/ref/`
(gitignored) y **nunca** entran en el repo ni en el build. El reparto de Symphonia se genera con
`tools/build_characters.py` imitando ese look.

## 1. Conseguir las herramientas (una vez)
```
git clone -b develop https://github.com/hueyyeng/vesperiatools ~/dev/VesperiaTools
cd ~/dev/VesperiaTools && python3 -m venv env && source env/bin/activate.fish
pip install trimesh==3.9.10 typing-extensions   # sin PySide2: no usamos la GUI
```
VesperiaTools no tiene CLI; `tools/vesperia_extract.py` llama a su API Python
(`parse_svo`, `parse_dat`, `parse_dec`, `parse_dec_ext`, `export_wavefront_obj`, `export_dds_textures`).

## 2. Archivos del juego
Hace falta una copia de Tales of Vesperia DE (PC). Copiar los `.SVO` de personajes (carpeta de datos del juego)
a `assets/ref/vesperia/src/`. Formatos: `.SVO` (FPS4) → `.DAT` (TLZC/zlib) → `.dec` → piezas FPS4 →
`.SPM/.SPV` (malla) y `.TXM/.TXV` (texturas DDS). Sin esqueleto ni animaciones: solo OBJ estático.

## 3. Extraer
```
python3 tools/vesperia_extract.py --tools ~/dev/VesperiaTools --svo assets/ref/vesperia/src/<PAQUETE>.SVO
```
Salida: `assets/ref/vesperia/<nombre>/all.obj` + `*.DDS`.

## 4. Convertir a referencia visual y medir proporciones
```
blender -b --python tools/vesperia_ref.py -- . 
```
Salida: `assets/ref/vesperia/glb/<nombre>.glb` (ver con `tools/Preview.tscn`) y
`assets/ref/vesperia_style.json` (cabezas de alto, anchura de hombros, texturas).
Siguiente paso: usar esos números en `build_characters.py` (proporciones) y en `assets/shaders/toon.gdshader`
(bandas, contorno) para Lloyd, Colette, Genis, Raine, Kratos, Sheena, Zelos, Presea y Regal.

## Limitaciones conocidas de VesperiaTools
- Mallas de personaje OK; UVs de escenarios inutilizables. Sin materiales (MTR→MTL sin probar). Sin huesos.
- Probado en Windows 11 / Python 3.10. En macOS arm64 la GUI (PySide2) no instala; por eso vamos por API.
- Sin licencia declarada en el repo de la herramienta.
