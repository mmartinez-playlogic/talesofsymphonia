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
