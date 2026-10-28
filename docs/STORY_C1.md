# Guion de referencia · Capítulo 1 (Iselia → Triet)

Desglose escena por escena del juego original (resumido con nuestras palabras; fuente: LP de wdarkk en lparchive.org,
Wikiquote para los Juramentos Enanos). Sirve para comprobar que cada evento del remake sigue el orden y el contenido real.
Columna "Remake": dónde está implementado. ✅ = implementado al dedillo, 🟨 = simplificado, ⬜ = pendiente.

| # | Escena (original) | Presentes | Remake | Estado |
|---|---|---|---|---|
| 0 | Narración de apertura (árbol gigante, guerra, héroe, diosa, Elegida) | narrador (voz de Kratos) | `Main.gd` (pendiente intro narrada) | ⬜ |
| 1 | Clase de Raine: borrador a Lloyd; Genis responde (Mithos, Kharlan); pacto con Martel; Día de la Profecía; Colette "viaje para sellar a los desianos"; maná y ranchos; luz; Raine va a la capilla, no deja ir a Colette; elección "Es por investigación"/"Vale"; Juramento Enano nº 4; Colette atraviesa la pared | Lloyd, Raine, Genis, Colette | `iselia_school.gd` on_enter | ✅ |
| 2 | Frank en la aldea vacía: desianos pasaron hacia el templo; tratado de no agresión; Phaidra en el templo; Frank deja ir a los chicos. Skit "No pasará nada" | Lloyd, Genis, Colette, Frank | `iselia_village.gd` _frank + skit k158 | ✅ |
| 3 | Camino al templo: monstruos aunque es tierra sagrada; tras la 1ª pelea Colette alaba a Lloyd, Exsfera; 2ª pelea: fantasma y zombi, magia vs espíritus, cambiar objetivo | Lloyd, Genis, Colette | `iselia_forest.gd` on_return | ✅ |
| 4 | Escaleras del templo: pastor moribundo; Juramento nº 1; soldados "¿Desianos? Ja ja"; Botta "tu vida es mía"; batalla soldados; jefe (Vidarr) gana; Kratos "apartaos"; Botta se retira; Phaidra; Exsfera de Kratos; "Kratos, mercenario"; Phaidra lo contrata; "serías un estorbo", elección; Colette "me pongo nerviosa sin Lloyd"; "esto no es una excursión" | Lloyd, Genis, Colette, pastor, Botta, soldados, Vidarr, Kratos, Phaidra | `martel_temple_ext.gd` | ✅ |
| 5 | Interior: Kratos da el Manual de entrenamiento; sello necesita el Anillo del Hechicero; puzle de gólems (bloque cae por el agujero); anillo; "eres como un niño"; skit "La prueba de la Elegida"; "te aburres enseguida" | los 4 | `martel_temple.gd` | 🟨 (bloques no se empujan: caen solos al vencer al gólem) |
| 6 | Altar: Cristal de Cruxis; Remiel (séptima Elegida, linaje del maná, Torre de la Salvación, sellos, Sello del Fuego al sur, "mi querida hija"); Kratos y Colette se adelantan; "pasaos por mi casa"; rumor de la hija del ángel | los 4, Remiel | `martel_temple.gd` _oracle | ✅ |
| 7 | Raine en modo ruinas ("¡MARAVILLOSO!"), pega a Genis y a Lloyd, los manda a casa. Skit "El viaje" | Lloyd, Genis, Raine | `martel_temple.gd` _oracle (final) + skit k001 | ✅ |
| 8 | Casa de Colette: Kratos y Phaidra acuerdan salir mañana; recompensa; Lloyd pide ir, Kratos "los niños en casa", alcalde apoya; fuera: cumpleaños de Colette, galletas de Genis, collar sin terminar, "vendré a decirte la hora" (mentira), Genis "mentiroso"; Genis va a ver a una amiga | Lloyd, Genis, Colette, Kratos, Phaidra, Frank, alcalde | `iselia_village.gd` _colette_door | ✅ |
| 9 | Casa de Genis (ingredientes, cocina); puerta: Noishe en la aldea, el alcalde pregunta por el rancho, "Noishe es un perro". Skit "Su única virtud" | Lloyd, Genis, aldeano, Noishe | `iselia_village.gd` _genis_door, _gate_talk + skit k163 | 🟨 (cocina pendiente) |
| 10 | Bosque: Noishe huye; skit "La amiga de Genis"; Genis confiesa el rancho; Lloyd va con él | Lloyd, Genis, Noishe | `iselia_forest.gd` _noishe + skit k164 | ✅ |
| 11 | Rancho: Marble (Torre, Elegido anterior muerto, Exsfera sin Cresta, mineral inhibidor, "tu padre es un enano", elección); guardia se la lleva; acantilado; plan señuelo; galletas/sándwich; Genis lanza magia; Lloyd salta; batalla (Lloyd solo); Marble agradece; "hazme los deberes"; corte a Forcystus (vigilancia). Skit "Noishe inquieto" | Lloyd, Genis, Marble, guardias, Forcystus | `iselia_ranch.gd` + skit k002 | ✅ |
| 12 | Casa de Dirk: Cresta Clave (brazalete de mineral inhibidor); mentira del mercenario; Juramento nº 11; confesión; Exsfera = recuerdo de la madre, los desianos la mataron; pelea (Dirk golpea); fuera: Colette, Genis, Raine, Kratos; Genis sobre semielfos; Kratos en la tumba ("Anna... hmm"); Raine sobre el regalo; terraza: "mañana al mediodía" (mentira), dos padres, "adiós"; noche: collar terminado; Dirk da la Cresta (nº 2), bolsa, nº 7, "¡Vamos, Noishe!"; mañana: Genis "se fueron hace mucho", Dirk "¡a la aldea, ya!" | Lloyd, Dirk, Colette, Genis, Raine, Kratos, Noishe | `dirks_house.gd` | ✅ |
| 13 | Aldea día 2: skits "Dirk, el artesano" y "¿Qué esconde Colette?"; Phaidra; carta de Colette (testamento); Frank "la Elegida ya está..."; explosión; ataque desiano; aldeano salvado (geles); skit "Ataque desiano"; casa de Genis quemada ("un lugar al que llamar hogar"); plaza: Forcystus (Cinco Grandes Cardenales, cuerpo huésped F192, "¿nosotros matar a la Elegida?"); monstruo (Exbelua); Exsfera del Proyecto Angelus; voz de Marble "como un nieto"; explosión hiere a Forcystus "siempre iremos a por ti"; Exsfera de Marble | Lloyd, Genis, Phaidra, Frank, aldeanos, Forcystus, Exbelua | `iselia_village.gd` _letter/_raid/_plaza/_marble_death + skits k159/k003/k103 | ✅ |
| 14 | Destierro: alcalde, aldeanos, Genis "los humanos sois todos iguales", "forastero criado por un enano", Genis se va también; Phaidra y Frank despiden; Lloyd da a Genis la Exsfera de Marble; Noishe se une | todos | `iselia_village.gd` _exile | ✅ |
| 15 | Casa de la Salvación: mujer deja descansar gratis; Noishe trae la carta de Dirk (Guía del viajero, 14 años, regalo futuro, P.D. EX Gems); skit "No duermo en clase"; desierto: soldados renegados, carteles de "se busca" | Lloyd, Genis, Noishe, mujer, renegados | `world_sylvarant.gd` + skit k129 | ✅ |
| 16 | Triet: cartel de se busca ("dicen que eres guapo"), skit "¿Por qué existen los desianos?", adivina, captura de Lloyd, base de los Renegados, Yuan, Botta, Raine, posada | Lloyd, Genis, Colette, Kratos, Raine, Yuan, Botta | `triet_desert.gd` (solo llegada + cartel) | ⬜ C2 |

## Juramentos Enanos usados
nº 4 (clase, Lloyd) · nº 1 (escaleras, Lloyd) · nº 11 (Dirk) · nº 2 (Dirk, Cresta Clave) · nº 7 (Dirk y Lloyd).

## Skits del capítulo (títulos reales, contenido parafraseado) en `src/data/skits.json`
k158 No pasará nada · k102 La prueba de la Elegida · k001 El viaje · k163 Su única virtud · k164 La amiga de Genis ·
k002 Noishe inquieto · k159 Dirk, el artesano · k003 ¿Qué esconde Colette? · k103 Ataque desiano · k129 No duermo en clase ·
k167 ¿Por qué existen los desianos?

## Objetos del capítulo
Manual de entrenamiento (Kratos) · Anillo del Hechicero · Gel de Naranja x2 (Phaidra) · Cresta Clave (Dirk) · bolsa de Dirk
(Guía del viajero + carta) · Gel de Manzana + Gel de Naranja (aldeano) · Exsfera de Marble (→ Genis).
