# Tales of Symphonia: Remake fan (Godot 4)

## Qué es este proyecto
Remake fan completo de Tales of Symphonia (GameCube, 2003) construido desde cero en Godot 4,
con estética 3D cel-shaded inspirada en Tales of Vesperia. El objetivo es la historia 1:1
(mismos personajes, lugares y eventos, con los nombres originales) y las mecánicas 1:1
(combate LMBS, artes, Unison Attack, Ex Skills, Grado, títulos, cocina, skits, afinidad), a 60 fps.
Se construye sesión a sesión, "día a día, poco a poco". Cada sesión debe dejar el juego ejecutable.

## Reglas fijadas con el usuario (Mateo)
- No preguntar: tomar decisiones y avanzar. El usuario lo dijo explícitamente ("tío no me preguntes, hazlo tú").
- Los tokens no importan; la calidad y la completitud sí.
- Nada de assets ni guion copiados de Bandai Namco. Diálogos reescritos siguiendo la trama real.
  Modelos y animaciones de bibliotecas CC0 (Quaternius) o generados por script en Blender.
- Guardar contexto en archivos (este CLAUDE.md, docs/DEVLOG.md, docs/ROADMAP.md) para no perder el hilo.
- Idioma con el usuario: español. Código y nombres de archivos en inglés.
- Estilo de respuesta: seguir la skill `i-have-adhd` (~/.claude/plugins/cache/i-have-adhd/.../SKILL.md): acción primero, pasos numerados, estado restatado, una sola acción siguiente al final.

## Decisiones técnicas
- Motor: Godot 4.7.2 (instalado con `brew install --cask godot`, binario `godot`). GDScript.
- Arte: Blender 5.2.3 (`blender -b --python script.py`) para generar/retargetear modelos. Sin editor abierto.
- Harness: Claude Code 2.1.287, modelo Claude Fable 5.1 (claude-fable-5-1). Anotar la versión en cada entrada del DEVLOG.
- Animaciones: Quaternius Universal Animation Library 1 y 2 (CC0) en `assets/anim/`.
  - `ual1.glb`: rig Rigify (`DEF-*`, 53 huesos). Locomoción, Sword_Attack, Sword_Idle, Hit, Death01, Spell_Simple_*, Roll, Jump.
  - `ual2.glb`: rig nombres UE5 (`pelvis`, `spine_01`..., 65 huesos). Sword_Regular_A/B/C, Sword_Combo, Sword_Block, Hit_Knockback, Sword_Dash.
  - Mismo mannequin y proporciones; se unifican renombrando huesos en Blender (tools/).
- Render: Forward+, 60 fps fijos (physics_ticks 60, vsync), shader toon propio en `assets/shaders/`.
- Las escenas se construyen por código siempre que se pueda (los .tscn se escriben a mano como texto).
- Comprobar que el proyecto arranca con: `godot --headless --path . --quit` (importa y valida scripts).

## Estructura
- `project.godot`, `CLAUDE.md`, `docs/ROADMAP.md` (hitos del juego entero), `docs/DEVLOG.md` (diario por sesión)
- `assets/` anim, characters (glb generados), shaders, audio
- `src/autoload/` Game (estado global, party, flags), Router (cambio de escenas), DB (carga de datos)
- `src/data/` JSON: characters, artes, enemies, items, titles, recipes
- `src/field/` exploración; `src/battle/` combate; `src/ui/` HUD y menús; `src/story/` eventos y skits
- `tools/` scripts de Blender y utilidades

## Cómo retomar una sesión
1. Leer `docs/DEVLOG.md` (última entrada = dónde quedamos) y la lista de tareas en `docs/ROADMAP.md`.
2. Ejecutar `godot --headless --path . --quit` para confirmar que todo carga.
3. Continuar con el siguiente hito pendiente. Al terminar: actualizar DEVLOG, ROADMAP y hacer commit.
