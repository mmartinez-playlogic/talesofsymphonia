# Guion del juego (texto 1:1)

- `_template_es.json`: TODAS las escenas de cutscene con su id (`mapa.evento.nn`) y las líneas provisionales
  (reescritas). Lo genera el código; no editar a mano.
- Para usar el texto exacto del juego: copia `_template_es.json` a `es.json` (o `en.json`) y sustituye cada
  `"text"` por la línea original del volcado de tu copia del juego. Puedes añadir o quitar líneas por escena.
- Cualquier `*.json` de esta carpeta que no empiece por `_` se carga al arrancar (`DB.script`) y sustituye el
  texto de la escena con ese id. Si una escena no está en el archivo, se usa el texto del código.
- Los skits viven en `src/data/skits.json`; las líneas de NPC siguen en cada mapa (pendiente de sacar aquí).
