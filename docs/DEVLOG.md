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

## 2026-10-28 — Sesión 3c (harness: Claude Code 2.1.287, Claude Fable 5.1)
- Mateo: "crea modelos parecidos a todos los personajes de Symphonia". Hecho con Blender en background (sin ventana).
- `tools/build_characters.py` reescrito: ojos anime (blanco + iris de color + pupila + ceja + boca), 9 peinados
  (spiky, spiky_back, long, bob, short, ponytail, twintails, bun, bald), rasgos de vestuario (collar, cinturón,
  tirantes de Lloyd, flequillo, falda en cono, abrigo largo en medio cono, capa, lazo de Sheena, alas de Remiel,
  grilletes de Regal, barba, brazo cañón de Forcystus, hombreras, grebas), armas (espadas, chakrams x2, kendama,
  bastón, cartas, hacha, martillo, látigo). Args opcionales: `-- . [--no-anim] [ids...]` para regenerar solo algunos.
- 23 modelos humanoides en `assets/characters/`: 9 jugables + NPC (dirk, phaidra, frank, marble, mayor, remiel,
  forcystus, botta, yuan, mithos) + enemigos (zombie, desian, desian_whip, vidarr). Hoja de contacto en
  `docs/images/characters_sheet.png` (generada con `tools/render_sheet.py`, Workbench, sin ventana).
- Mapas actualizados para usar los NPC propios; `Npc.MODEL_SCALE` escala a Dirk (0.78), Genis, Presea, Forcystus, Vidarr.
- PENDIENTE: Godot aún no ha importado los .glb nuevos (sin .import). Lo hace el `godot --headless --path . --quit` de la próxima sesión.

## 2026-10-28 — Sesión 3d (harness: Claude Code 2.1.287, Claude Fable 5.1)
- Mateo: textos e historia 1:1 con Symphonia, "sin reparos". No tengo el guion verbatim; solución: guion en datos.
- `c.script(id, fallback)` + `DB.script` (carga `src/data/script/*.json` que no empiecen por `_`). Todas las cutscenes
  (43 escenas, ~180 líneas) ya usan ids `mapa.evento.nn`; plantilla en `src/data/script/_template_es.json`.
  Para texto exacto: volcar el guion del juego en `src/data/script/es.json` con esos ids (ver README de la carpeta).
- Fidelidad de trama C1: añadido Botta (Renegados) retirándose tras Vidarr; Juramentos Enanos nº 1, 2 y 7; Dirk golpea a Lloyd.
- Desviaciones conocidas pendientes: puzle de gólems/Anillo del Hechicero del templo (ahora un sello), posada/tienda de Iselia,
  Noishe acompañando en el mapa del mundo, cartel de "se busca" de Lloyd en Triet (C2).

## 2026-10-28 — Sesión 3e (harness: Claude Code 2.1.287, Claude Fable 5.1) — "al dedillo"
- Mateo: todo comprobable y perfecto. Validación headless activada: `godot --headless --path . --import` (regenera la caché
  de clases) y `godot --headless --path . res://tools/CheckScripts.tscn` (carga TODOS los scripts con autoloads activos).
  Errores corregidos: `DB.script` chocaba con `Node.script` (→ `story_script`), `sc` duplicada en PlayerBattler, inferencias
  de tipo con `Game.get_flag` (→ `: bool`).
- Investigado el capítulo 1 real escena por escena (lparchive + Wikiquote) → `docs/STORY_C1.md` (tabla de cotejo).
- Reescritos con la secuencia real: iselia_school, iselia_village (Frank, casa de Colette, casa de Genis, puerta/Noishe,
  carta, ataque, Forcystus, Exbelua, destierro), iselia_forest (tutoriales tras peleas, Noishe huye), martel_temple_ext
  (pastor, Botta, Vidarr, Kratos, elección), martel_temple (manual, gólems, anillo, Remiel completo, Raine), iselia_ranch
  (Marble, acantilado, Lloyd solo, Forcystus). Nuevo: `Field.on_return(cs)` tras batallas normales, `cs.battle(..., party_override)`,
  `cs.restore_party()`, `cs.affection()`, enemigos golem/ghost (modelo golem generado), ítems clave, 11 skits reales.
- Pendiente en esta sesión: dirks_house, world_sylvarant (Casa de la Salvación, carta de Dirk, renegados), triet_desert (cartel).
- (3e, cont.) Reescritos dirks_house (discusión, visitantes, terraza, noche, mañana), world_sylvarant (Casa de la Salvación,
  carta de Dirk, cordón de renegados) y triet_desert (cartel de se busca). C1 completo según `docs/STORY_C1.md`.
- Nuevo `tools/SmokeTest.tscn`: carga cada mapa en cada estado de la historia (21 escenarios, incluidos los `on_resume` tras
  batalla y dos combates), pulsa Confirmar automáticamente y registra errores. Resultado final: 0 SCRIPT ERROR.
  Cómo ejecutarlo (sin ventana): `godot --headless --path . res://tools/SmokeTest.tscn`.
  Corregidos: DialogueBox/SkitBox escribiendo tras cambiar de escena; Cutscene._walk_impl sobre actor eliminado.
- Trazas `[EV] <id>` en consola por cada escena de guion ejecutada (útil para seguir la historia en los logs).
- Plantilla de guion regenerada: `src/data/script/_template_es.json`.
- Queda por probar CON VENTANA (cuando Mateo pueda): posiciones de cámara/actores, legibilidad de HUD, sensación de combate.

## 2026-10-28 — Sesión 3f (harness: Claude Code 2.1.287, Claude Fable 5.1) — "asegúrate de que funciona"
- Nuevo `tools/Playthrough.tscn`: bot que JUEGA la demo entera en headless (físicas reales): camina con el input del
  jugador hacia waypoints, avanza diálogos y elecciones, interactúa con puertas/NPC/objetos, gana los combates (mata a
  los enemigos tras 1 s) y comprueba mapa y flags en cada paso. `godot --headless --path . res://tools/Playthrough.tscn`.
  Log: `[STEP]`, `[OK]`, `[FAIL]`, `[FALLBACK]`. Tarda ~6-8 min.
- Bugs REALES del juego que ha destapado y se han corregido:
  1. Al entrar en un mapa sin evento de entrada el jugador quedaba congelado para siempre (run_event salía mientras
     el fundido de Router seguía activo). Ahora espera a que termine el fundido.
  2. Al coger el Anillo del Hechicero se creaba una caja con colisión encima del jugador → atrapado. El pedestal ya no
     se sustituye por una caja.
  3. Los .glb generados después del último `--import` (golem) no existían para Godot. Regla: tras generar modelos,
     `godot --headless --path . --import`.
  4. Spawn `from_school` en la aldea estaba pegado a la puerta de la escuela: al andar hacia el norte volvías a entrar.
- Ajustes del bot (no del juego): cada "ir a" termina al cambiar de mapa; reinicio del detector de atasco al recuperar
  el control; waypoints por los caminos para no cruzar edificios.
  5. El altar (y cualquier interactuable) que se borraba a sí mismo en mitad de su interacción dejaba al jugador
     bloqueado: la corrutina del nodo borrado nunca reanudaba. Ahora `Field._on_interact` ejecuta el manejador desde el
     propio Field (vale para Interactable y para `Npc.on_interact`).
  6. Monstruos de campo que se quedaban empujando contra una pared para siempre: `FieldMonster` ahora detecta atasco
     (0,8 s sin avanzar) y elige otro destino. Segundo grupo del ataque a Iselia recolocado en zona despejada (4, -20).
  7. Radio de interacción del jugador ampliado (1,5 m, 0,9 m por delante) para que puertas y NPC respondan sin pegarse.
- Resultado del bot (`tools/Playthrough.tscn`): de la escuela al desierto de Triet, 110 pasos, 0 fallos del juego.
  74 escenas de guion ejecutadas, ~13 min de partida simulada. Presets para empezar a mitad: `-- --from raid` / `--from exile`.
- Lo que el bot NO cubre: cámara/encuadre, legibilidad, equilibrio de combate (gana por trampa), animaciones en pantalla.

## 2026-10-28 — Sesión 3g (harness: Claude Code 2.1.287, Claude Fable 5.1) — texto completo
- Mateo pidió el guion completo. Decisión: NO se copia el texto verbatim de Bandai Namco. En su lugar, guion propio a
  longitud real para las 83 escenas de C1 (357 líneas) siguiendo `docs/STORY_C1.md`, en `docs/script/c1_es.txt`
  (fuente editable) → `src/data/script/es.json` vía `tools/import_script.py`. Cargado por `DB.story_script`.
- Si algún día se importa el texto oficial (subtítulos ES de Chronicles/Remastered), basta sustituir `es.json`.
- Fuentes en inglés localizadas: FAQs de guion (GameFAQs / espejo video-games-museum), "Z-Skit Scripts" (tamashii).

## 2026-10-28 — Sesión 3h (harness: Claude Code 2.1.287, modelo Opus 5.5 desde aquí) — "todos los sistemas"
- Mateo cambió el modelo a Opus 5.5 (`/model`); atribución de commits actualizada.
- Datos nuevos: 20 ingredientes, armas/armaduras/accesorios, EX Gems Nv1-4 (`items.json`, 77 objetos), `recipes.json` (10),
  `titles.json` (15), `ex_skills.json` (8 comunes + propias), `shops.json` (Iselia, Triet, Casa de la Salvación).
- `Game.gd` reescrito: equipo por huecos, títulos por flags (señal `title_earned`), EX Skills con gemas, cocina con
  habilidad por personaje, compra/venta, guardado de todo lo anterior.
- UI: `PauseMenu` con 10 secciones (Objetos, Equipo, Artes, Cocina, Títulos, EX Skills, Estado, Manual, Guardar, Cerrar),
  `ShopMenu` nuevo, posada (`Field.inn`), menú de objetos en combate (tecla I).
- Campo: Anillo del Hechicero real (`RingShot`, aturde monstruos → ventaja). Maestros Cocineros en Iselia y casa de Dirk.
- Combate: Over Limit (barra naranja), Unison Attack (barra azul, tecla N), efectos de EX Skills (combo 4, TP, lanzamiento,
  súper armadura, crítico, EXP/Gald), título por combo de 10.
- Bug real encontrado por el test: niveles de EX del JSON llegan como float y no casaban con el hueco.
- Nuevo `tools/SystemsTest.tscn`: 146 aserciones, incluidas pulsaciones reales en tienda, menú (cocinar) y anillo. 146/146.
- Referencia: `docs/SYSTEMS.md`.
