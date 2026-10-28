# Guion del juego (texto 1:1)

- `_template_es.json`: TODAS las escenas de cutscene con su id (`mapa.evento.nn`) y las líneas provisionales
  (reescritas). Lo genera el código; no editar a mano.
- Para usar el texto exacto del juego: copia `_template_es.json` a `es.json` (o `en.json`) y sustituye cada
  `"text"` por la línea original del volcado de tu copia del juego. Puedes añadir o quitar líneas por escena.
- Cualquier `*.json` de esta carpeta que no empiece por `_` se carga al arrancar (`DB.script`) y sustituye el
  texto de la escena con ese id. Si una escena no está en el archivo, se usa el texto del código.
- Los skits viven en `src/data/skits.json`; las líneas de NPC siguen en cada mapa (pendiente de sacar aquí).

## Importar una transcripción
1. Prepara un `.txt` con marcadores `## id_de_escena` y líneas `Hablante: texto` (ids en `_template_es.json`).
2. `python3 tools/import_script.py transcript.txt es --check` → genera `es.json` y lista las escenas que aún faltan.
3. Las escenas que no estén en `es.json` siguen usando el texto del código.
Fuentes donde hay transcripciones en inglés: FAQs de guion en GameFAQs (GameCube), "Z-Skit Scripts" de tamashii
(todos los skits), Let's Play con capturas en lparchive.org. En español no hay transcripción completa publicada;
la versión PS3/PC (Chronicles / Remastered) lleva subtítulos en español: de ahí sale el texto oficial.
