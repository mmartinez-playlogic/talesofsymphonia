# Animaciones

Las animaciones del original no se extraen (igual que modelos y texto). Se reproduce su COREOGRAFÍA con las 75
animaciones CC0 del rig (Quaternius UAL 1+2, unificadas) + movimiento real del personaje (embestidas, saltos, giros).

## Coreografía de artes (`src/data/artes.json`, campo `moves`)
Cada paso: `anim`, `speed`, `t` (s), `dx` (embestida, m), `jump` (altura al final del paso, m), `crouch` (agacharse),
`spin` (grados), `hits` + `hit_at` (golpes del paso), `knock`, `launch`, `projectile_at`, `flash`.
Ejecutor: `PlayerBattler._start_choreo/_choreo_tick` (fotograma a fotograma en físicas; se cancela si te golpean y
devuelve el modelo al suelo y a su orientación).

| Arte | Original | Remake |
|---|---|---|
| Demon Fang | Tajo al suelo que lanza una onda | Tajo descendente rápido agachándose + onda (proyectil) |
| Sonic Thrust | Embestida con estocada | Carga breve + Sword_Dash 3,2 m hacia delante, golpe con retroceso |
| Tiger Blade | Tajo ascendente (lanza) + tajo descendente | Sube 1,6 m con tajo que lanza, cae con tajo descendente |
| Sword Rain | Ráfaga de estocadas | 4 estocadas alternas rápidas avanzando + remate |
| Tempest | Salto girando | Salto 1,6 m, dos vueltas (720°) con 3 golpes avanzando, aterrizaje |
| Beast | Golpe con onda de león | Guardia/carga + tajo enorme con destello y retroceso 7 |
| Pow Hammer / Ray Thrust | Lanzamiento | OverhandThrow + proyectil |
| Hechizos (Genis, Raine, Kratos) | Círculo + lanzamiento | Entrada de hechizo, círculo giratorio, disparo |

## Combate
Retroceso (Hit_Knockback) con golpes fuertes o que lanzan; KO (Death01); revivir (LayToIdle).
Victoria: pose por personaje (Lloyd gira las espadas y celebra; Colette salta; Genis; Raine; Kratos se cruza de brazos)
y una frase de victoria aleatoria de un personaje vivo.

## Escenas
Tropiezo de Colette (`cs.trip`), Raine pega a Genis y patea a Lloyd, Dirk golpea a Lloyd, Lloyd se agacha ante la
tumba, Colette se arrodilla en el altar, Remiel desciende volando, Genis lanza la bola de fuego en el rancho y Lloyd
salta del acantilado.

## Test
`tools/ArteTest.tscn`: nombres de animación existen, cada arte de los 5 personajes termina, hace daño/cura/buff,
aterriza en el suelo, mira al frente, no sale de la arena, salta de verdad cuando debe; arte interrumpido en el aire;
poses y frase de victoria. 201/201.
