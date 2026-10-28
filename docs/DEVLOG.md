# Diario de desarrollo

## 2026-10-28 — Sesión 1
- Mateo pidió el remake completo de Symphonia, 1:1, gráficos tipo Vesperia, 60 fps, "la cosa completa, día a día".
- Decidido: Godot 4 + GDScript, 3D cel-shaded, assets CC0, sin preguntar más.
- Instalados Godot 4.7.2 y Blender 5.2.3 por Homebrew.
- Descargadas las Universal Animation Library 1 y 2 de Quaternius (CC0) desde OpenGameArt. Copiadas a assets/anim/.
- Hallazgo: los dos rigs usan nombres de hueso distintos (Rigify DEF-* vs UE5). Hay que unificar en Blender.
- Creados CLAUDE.md, ROADMAP.md, este diario. Repo git iniciado.

## 2026-10-28 — Sesión 2 (harness: Claude Code 2.1.287, Claude Fable 5.1)
- Creado src/battle/ (BattleManager, Battler, PlayerBattler, EnemyBattler, BattleCamera, BattleHUD, Effects, Projectile, Battle.tscn) y tools/RunBattle.tscn para lanzarlo.
- project.godot: activados warnings de inferencia en Variant.
- Pendiente: NO se ha probado el combate en ventana (Mateo pidió no probarlo). Próxima sesión: lanzar tools/RunBattle.tscn y corregir lo que falle.

## 2026-10-28 — Sesión 3 (harness: Claude Code 2.1.287, Claude Fable 5.1)
Mateo en reunión: NADA se ha ejecutado (ni Godot headless). Todo escrito a ciegas; la próxima sesión empieza validando.
- Sistema de eventos: `src/story/Cutscene.gd` (say/line/choice/caption, walk/run_to/face/anim, spawn/despawn/hide,
  fade/flash/shake/look_at, flag/give_item/join/set_party, skit, goto, battle con reanudación).
- `Field.gd` reescrito: `on_enter(cs)`, `on_resume(cs, event)` tras batallas de historia (flags `resume_event`/`resume_map`),
  `run_event`, triggers, salidas condicionales, `add_building/add_box/add_patch/add_palm/add_cactus/add_chest/add_interactable/add_light`,
  aviso de skit disponible (tecla U / botón 5) y menú de pausa (tecla I).
- `DialogueBox`: elecciones (`show_choice`) y subtítulos (`show_caption`). `SkitBox` + `src/data/skits.json` (10 skits) + `Skits.gd`.
- `PauseMenu`: Objetos (usar geles), Artes (atajos 1/↑/↓ guardados en `members[id].shortcuts`), Estado, Guardar.
- `Game`: `set_party`, `use_item`, `seen_skits`, `save_exists`; nueva partida arranca en `iselia_school`.
- Mapas nuevos (todos en `src/field/maps/`): iselia_school, iselia_village, martel_temple_ext, martel_temple, iselia_ranch,
  dirks_house (noche/día por flags), world_sylvarant, triet_desert. iselia_forest conectado (sur aldea, norte templo, este rancho).
- Historia C1 completa en eventos: clase de Raine → oráculo → templo (desianos, Vidarr con Kratos invitado) → interior
  (Anillo del Hechicero, sello, Raine, Remiel) → Genis al rancho (Marble, Forcystus) → casa de Dirk (tumba, Kratos, Colette, collar)
  → día 2: Colette se ha ido, ataque desiano, Exbelua (Marble), destierro → Dirk (Cresta Clave, Iron Sword) → desierto de Triet.
- Flags de progreso en orden: oracle_seen, temple_arrived, vidarr_defeated, got_ring, seal_open, temple_done, genis_ran_off,
  ranch_visited, kratos_grave_scene, night_dirk, exiled, left_for_journey, triet_arrived.
- Datos: enemigos desian_whip, exbelua, sand_wolf, desert_hornet, hare; ítems clave; encuentros rancho/mundo/desierto.
- Modelos NPC reutilizados (Dirk/alcalde=regal, Phaidra=raine, Frank/mercader/Remiel=zelos, Marble=sheena, Forcystus=desian, Noishe=wolf).
  Pendiente generar modelos propios en Blender.
- Supuesto no verificado: Godot importa "Idle_Loop" como "Idle" (el código de la sesión 1 ya lo asumía).

### Próxima sesión (en este orden)
1. `godot --headless --path . --quit` y arreglar errores de parseo.
2. `godot --path . res://tools/RunField.gd`… usar `tools/RunField.tscn -- --map iselia_school` y recorrer la historia entera hasta Triet.
   Atajos: `--flags temple_done,ranch_visited --party lloyd,genis --map dirks_house`.
3. Probar el combate (RunBattle) y los jefes Vidarr/Exbelua; ajustar números.

## 2026-10-28 — Sesión 3b (harness: Claude Code 2.1.287, Claude Fable 5.1)
- Mateo: los modelos de Vesperia son "por investigación". Acordado: extraer con VesperiaTools a `assets/ref/` (gitignored),
  nunca al repo/build; nuestros personajes imitan el estilo. Regla actualizada en CLAUDE.md.
- Investigado hueyyeng/VesperiaTools: app PySide2 sin CLI; API Python parse_svo/parse_dat/parse_dec/parse_dec_ext,
  export_wavefront_obj (OBJ sin huesos), export_dds_textures. `rowanG077/Resonance` no localizado (pedir enlace).
- Escritos (sin ejecutar): `tools/vesperia_extract.py` (wrapper CLI de la API), `tools/vesperia_ref.py` (Blender:
  OBJ+DDS → GLB de referencia + `vesperia_style.json` con proporciones), `docs/VESPERIA_REF.md`.
- Hace falta: copia de Vesperia DE (PC) para los .SVO. Sin ella no hay nada que extraer.
