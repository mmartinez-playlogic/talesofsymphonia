# QA: cómo se prueba el juego (todo headless, sin ventana)

Añade `--max-fps 0 --fixed-fps 60` para que corra más rápido que el tiempo real.

| Batería | Comando | Qué comprueba | Último resultado |
|---|---|---|---|
| Compilación | `godot --headless --path . res://tools/CheckScripts.tscn` | Carga los 47 scripts con autoloads | 0 errores |
| Smoke | `... res://tools/SmokeTest.tscn` | Cada mapa en cada estado de la historia y los `on_resume` tras batalla | 0 errores |
| Recorrido | `... res://tools/Playthrough.tscn` | Juega la historia de la escuela a Triet con físicas reales (110 pasos) e imprime los niveles por tramo | 0 fallos |
| Sistemas | `... res://tools/SystemsTest.tscn` | 146 aserciones: tienda, equipo, objetos, cocina, títulos, EX, guardado, Over Limit, Unison, objetos en combate, y pulsaciones reales en tienda/menú/anillo | 146/146 |
| Combate real | `... res://tools/CombatTest.tscn -- --runs 5 [--only NOMBRE] [--debug]` | Bot que pelea con las teclas (ataca, artes, gel al 35%, Unison) en los 13 combates del capítulo al nivel real del recorrido | 65/65 victorias |
| QA | `... res://tools/QATest.tscn` | Interactúa con TODO lo interactuable de 15 estados, fuzz de 6×400 teclas en menú y tienda, 3000 teclas en combate, guardar y Continuar desde el título | 128 ok, 0 fallos |

## Curva de combate (bot, 5 rondas, niveles del recorrido real)
| Combate | Nivel | Victorias | Duración | Vida restante |
|---|---|---|---|---|
| Lobos del bosque | 1 | 5/5 | 20 s | 51% |
| Fantasma y zombi | 2 | 5/5 | 19 s | 61% |
| Soldados del templo | 3 | 5/5 | 25 s | 46% |
| **Vidarr** (con Kratos) | 4 | 5/5 | 58 s | 56% |
| Gólem | 5 | 5/5 | 12 s | 82% |
| Rancho (Lloyd solo) | 6 | 5/5 | 19 s | 62% |
| Ataque a Iselia | 7 | 5/5 | 19-28 s | 59-79% |
| **Exbelua** | 7 | 5/5 | 63 s | 64% |
| Desierto | 8-9 | 5/5 | 15-16 s | 76-87% |

Niveles reales al pasar por la historia: Vidarr 4→5, rancho 6, noche de Dirk 7, Exbelua 7, destierro 8, Triet 9.
