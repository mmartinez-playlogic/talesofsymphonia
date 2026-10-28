# Sistemas de juego (estado actual)

| Sistema | Dónde | Cómo se usa | Test |
|---|---|---|---|
| Tienda (comprar/vender) | `src/ui/ShopMenu.gd`, `src/data/shops.json` | Hablar con un mercader. Izq/Der cambia cantidad. Vender a mitad de precio; objetos clave no se venden. | SystemsTest: shop + UI |
| Posada | `Field.inn(price)`, `add_inn_npc` | Elegir Sí: cobra, funde a negro, cura al grupo. Casa de la Salvación: gratis. | Playthrough |
| Equipo (6 huecos) | `Game.equip/unequip/can_equip`, menú → Equipo | Arma, cuerpo, cabeza, brazos, 2 accesorios. Restricción por personaje (`users`). Muestra diferencia de ATK/DEF. | SystemsTest: equipment |
| Objetos | `Game.use_item`, menú → Objetos; en combate tecla I | Geles, Life Bottle (revivir), Panacea. En combate pausa la pelea. | SystemsTest: items + battle |
| Cocina | `Game.cook`, `src/data/recipes.json`, menú → Cocina | Receta + cocinero. Probabilidad según dificultad, práctica y especialidad del personaje. Cura a todo el grupo. 10 éxitos → título de Genis. | SystemsTest: cooking + UI |
| Maestro Cocinero | Iselia (tortilla), olla de Dirk (bola de arroz), Genis (sándwich) | Encontrarlo enseña una receta. | — |
| Títulos | `src/data/titles.json`, menú → Títulos | Se ganan por flags (desterrado, manual, 10 golpes, 10 platos...). Modifican stats. Aviso en pantalla al ganarlos. | SystemsTest: titles |
| EX Skills / EX Gems | `src/data/ex_skills.json`, menú → EX Skills | 4 huecos por nivel; cada gema se consume al usarla y vuelve al quitarla. Efectos: HP, ATK, DEF, crítico, coste TP, lanzamiento rápido, súper armadura, combo de 4, Over Limit rápido, +EXP/Gald, objetos +50%. | SystemsTest: EX |
| Atajos de artes | menú → Artes | 3 atajos: K, ↑+K, ↓+K. | — |
| Anillo del Hechicero | `src/field/RingShot.gd` | K en el campo: bola de fuego que aturde 4 s a un monstruo (brilla azul). Tocarlo aturdido = ventaja. | SystemsTest: UI ring |
| Over Limit | `Battler.add_ol` | La barra naranja bajo cada personaje se llena al recibir daño. Llena: 8 s sin tambalearse y +30% ATK/INT. | SystemsTest: battle |
| Unison Attack | `BattleManager.try_unison` | La barra azul se llena con los golpes del grupo. N: todos lanzan su arte principal a la vez. | SystemsTest: battle |
| Grado | `BattleManager._win` | Rapidez y daño recibido suman Grado tras cada combate. | — |
| Guardado (3 ranuras) | `src/ui/SaveMenu.gd`, `Game.save/load_save/slot_info` | Como en el original: sobre un Círculo de Memoria (Iselia, templo fuera y dentro, casa de Dirk, puerta de Triet) o en el mapa del mundo. Menú → Guardar o Confirmar sobre el círculo. Cada ranura muestra lugar, grupo y niveles, tiempo, Gald, fecha y ★ si la demo está completada. Sobrescribir pide confirmar dos veces. Se guarda la posición exacta. | FlowTest |
| Título | `src/Main.gd` | Nueva partida · Continuar (abre las ranuras; gris si no hay partidas; el cursor empieza ahí si las hay) · Salir. | FlowTest |
| Game Over | `BattleManager._lose` | Derrota → pantalla Game Over → Confirmar → título. | FlowTest |
| Fin de la demo | `src/ui/DemoEnd.tscn` | En la puerta de Triet: "¿Entrar en Triet?" → fundido → resumen (tiempo, Grado, Gald, niveles, títulos, skits, recetas) → Guardar (al continuar, apareces junto a la puerta) o Volver al título. | FlowTest, Playthrough |
| Skits | U cuando aparece el aviso | 11 skits del capítulo 1. | Smoke |
| Manual | menú → Manual | Todos los controles de campo y combate. | — |

## Controles
Campo: WASD/flechas · Shift andar · J confirmar · K Anillo del Hechicero · I menú · U skit.
Combate: A/D · W/S · J atacar · K arte (↑/↓+K) · L guardia · Tab objetivo · Shift carrera libre · I objetos · N Unison.

## Pendiente (siguientes capítulos)
Figurinas, afinidad visible, estrategias de IA editables, Compound EX Skills, artes de nivel Master/Unison combinadas, Grade Shop (NG+).
