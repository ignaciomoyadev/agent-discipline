# Agent Discipline

Harness personal para Cursor: contrato de salida, flota de subagentes anclada por
coste, y guía de enrutado. **Cada afirmación de aquí está medida**, no supuesta —
las mediciones son del 2026-09-08 al 2026-09-11, sobre un fixture con defectos
plantados. Cuando una medición nueva desmiente una vieja, se dice cuál y por qué.

## Instalar

```bash
git clone <este-repo> ~/.cursor/plugins/local/agent-discipline
```

Reinicia Cursor. Aparece como "Agent Discipline" en Rules, Subagents y Skills.

Eso es todo: no hay instalador, no hay archivos sueltos que copiar, y Cursor no
lo sobrescribe (a diferencia de la caché de plugins del marketplace, que sí
redescarga).

## Qué trae

### `rules/core.mdc` — contrato de salida, siempre activa

Contrato de salida, honestidad en la verificación, control de alcance. 20 líneas,
porque se cobra en cada turno de cada sesión.

### `rules/route.mdc` — enrutar a la flota, siempre activa

Cinco líneas que mandan localizar a `scout` y barrer defectos a `hunter`. Está
aquí, y no en la skill, porque se midió (punto 8): la skill de enrutado produjo
**0 de 8** delegaciones; esta regla, **8 de 8**. Lo que importa no se deja al 58%.

### `agents/` — siete especializados + dos flexibles

| rol | modelo | escribe | forma |
|---|---|---|---|
| `scout` | `composer-2.5[fast=false]` | no | localizar |
| `hunter` | `composer-2.5[fast=false]` | no | barrer defectos |
| `builder` | `composer-2.5[fast=false]` | **sí** | implementar diseño fijado |
| `auditor` | `composer-2.5[fast=false]` | no | verificar/refutar |
| `scribe` | `composer-2.5[fast=false]` | no | comprimir |
| `researcher` | `grok-4.6[effort=medium,fast=false]` | no | docs/web externas |
| `surgeon` | `grok-4.6[effort=xhigh,fast=false]` | **sí** | bug difícil |
| `investigator` | `composer-2.5[fast=false]` | no | **investigar lo que sea** (flexible) |
| `implementer` | `composer-2.5[fast=false]` | **sí** | **construir lo que sea** (flexible) |

Todos en primer plano: por la ruta del CLI, `is_background: true` no devuelve
nada (punto 9). Los dos flexibles son agnósticos de dominio: el orquestador les
da la forma en el brief. Específicos de disciplina (readonly/escribe, contrato,
verificación), generales de tarea — así conservan el andamiaje que mide bien sin
atarse a un dominio.

### `skills/token-discipline/` — la tabla completa de enrutado

Qué tier merece cada tarea, escalar por evidencia (`severity: high`), no encadenar
un agente que ya abre archivos, prefijo cacheable estable, descargar a disco en
vez de truncar. El disparo de las dos rutas comunes vive en `route.mdc`; esto es
el detalle que se consulta, no la orden que se ejecuta.

### `skills/change-docs/` — traza de cambios no obvios

Árbol `docs/` (plans, solutions, decisions, migration, security) y la disciplina
de cuándo documentar. Agnóstica de stack: para reglas de un dominio concreto,
añade una skill de ese repo. Es la versión general de un `odoo-change-docs`, sin
lo específico de Odoo.

### `optional-rules/tdd.mdc` — cubre cada cambio con un test (opcional)

No se carga sola (`plugin.json` solo declara `rules/`). Regla condicional:
test-primero al arreglar, construir-y-cubrir al crear. Medida (puntos 11-13): test
válido en el 100% de los cambios en bugfix y greenfield, sin testear interfaces
inexistentes, ~+20% de tiempo. Actívala por repo, ver `optional-rules/README.md`.

### `commands/orchestrate.md` — planifica y delega (invocado)

Preámbulo de orquestación: planifica, delega cada paso al subagente adecuado,
integra, decide. Medido (punto 14): una **regla** siempre activa de "sé
orquestador" no induce delegación (**0/6**); el mismo texto **explícito** en el
prompt la induce siempre (**6/6**). Por eso es un command que invocas, no una
regla ambiente. Instálalo por repo (`.cursor/commands/`) o global
(`~/.cursor/commands/`) — `plugin.json` no declara `commands/`, así que no se
auto-carga.

Expectativa medida: delega un paso de investigación, no un ejército. El fan-out
amplio depende del modelo orquestador (Opus sin medir).

## Las diez cosas medidas que explican el diseño

**1. El andamiaje del rol es la palanca grande.** Andamiar un agente único subió
el recall +26.6 pp. Y el prompt malo era **el más caro**: no hace escribir más,
hace buscar más.

**2. El andamiaje depende de la capacidad del modelo.** El mismo texto dio +6.7 pp
en Composer, 0 en Opus y **−11 pp en Grok**. Por eso `surgeon` no lleva checklist
y `hunter` sí. No copies el patrón de uno al otro sin medir.

**3. Podar destruye — y fusionar también.** Un verificador usado como puerta bajó
el recall de 0.916 a 0.750, y un orquestador filtrando de 0.778 a 0.611: el
modelo *más* potente borró *más*. Por eso `auditor` anota y no elimina. Y al
unir varios agentes, toda clave de similitud que comprime la unión pierde
defectos; la única que no pierde ninguno no fusiona nada. Dos defectos distintos
en el mismo símbolo son léxicamente indistinguibles de una repetición.

**4. Lo determinista le gana a lo pedido.** Un contrato de salida por prompt logró
0% de cumplimiento; el mismo criterio en código, 100%.

**5. `severity: high` es la evidencia.** Acierta el 96% de las veces sobre 206
hallazgos; todo lo demás ronda el 73%. Una barrida llega con orden de lectura, no
solo con lista. Pedir además un campo de confianza no discrimina nada (0.894
contra 0.846, con dispersión 0.086) y cuesta **11.5 pp de recall** — con el
formato saliendo perfecto 95 veces de 95. Un contrato más rico no falla por salir
mal formado: falla por llevarse la atención del código al formato.

**6. Un ensemble compra varianza, no reparto de trabajo.** Tres `hunter`
idénticos, unión sin borrar nada, agrupada por `file::symbol`: **0.95 de recall
contra 0.80** de uno solo, fiable 10 de 10 corridas contra 4 de 10, por 14.5
unidades de lectura contra 11.5. Darles superficies distintas no ayuda aunque se
especialicen (y se especializan: 0.925 en la propia, ~0.07 en las ajenas) —
cada superficie se vuelve un punto único de fallo. La versión anterior de este
README decía que añadir agentes movía el recall "entre 0 y −16.6 pp"; el −16.6
era del brazo que poda, y el resto era un artefacto de la función de unión, que
colapsaba dos defectos distintos del mismo símbolo en uno.

**7. El kernel comprime, no mejora.** Recall idéntico a tres decimales con y sin
él; la salida baja un **20%** (t = 2.74, p < 0.05). Vive en el prefijo cacheado,
así que es una rebaja gratis sobre el componente más caro de la factura — poco
en Composer, bastante en cualquier modelo de la bolsa de créditos.

**8. El enrutado va en una regla, no en la skill.** Con la skill `token-discipline`
como única guía, el agente principal delegó **0 de 8** veces — hizo la barrida a
mano, con 8 comandos shell y 4.5x más tokens en su propio contexto. Con una regla
`alwaysApply` de cinco líneas: **8 de 8**, al subagente correcto. La skill se
activa el 58% y su tabla vive en el párrafo cuarto de un documento de economía;
la orden corta y siempre activa es lo que dispara.

**9. `is_background: true` no devuelve nada por CLI.** El task tool responde
vacío, los `await` vuelven con cero bytes, y el principal acaba leyendo el
transcript del subagente del disco: 195 s y 5x los tokens. Con `false`: una
llamada, 39 s, resultado por la vía normal. Toda la flota pasó a primer plano.
No medido en la ruta de subagentes de la UI, que es otro código.

**10. Orquestar se pide, no se ambienta.** Una regla siempre activa de "sé
orquestador, planifica y delega" no indujo delegación (**0/6**, y hasta hizo más
trabajo propio). El mismo texto explícito en el prompt: **6/6**. Es el patrón del
punto 8 llevado al límite — lo abierto por regla no se cumple; lo concreto y
explícito sí. Por eso la orquestación es un command (`/orchestrate`), no una
regla. Y aun pedida, Composer delega **un** paso, no un fan-out: repartir de
verdad puede exigir un orquestador más capaz (Opus, sin medir).

## Anclar el modelo: la trampa

Un slug pelado no basta **en la interfaz**. Con `model: composer-2.5` el selector
resuelve a **Composer 2.5 Fast** — $3/$15 por millón en vez de $0.50/$2.50, unas
6x. Fast es el tier por defecto en Pro y superiores.

En el CLI es al revés: `composer-2.5` y `composer-2.5-fast` son slugs separados
en `--list-models`, y el pelado se comporta como no-Fast. Y `[fast=false]` **se
honra**: sale un 33% más lento que `composer-2.5-fast` (t = 3.08). Un modelo que
se autorreporta como Fast no es evidencia de nada — no sabe su tier, y el
envelope del CLI no lleva campo de modelo con el que contrastarlo.

Y cada familia usa sintaxis distinta:

| familia | funciona | no funciona |
|---|---|---|
| Composer | `composer-2.5[fast=false]` | — |
| Grok | `grok-4.6[effort=xhigh,fast=false]` | `cursor-grok-4.6-xhigh[fast=false]` |

Grok solo acepta corchetes sobre el nombre base parametrizado, no sobre el slug
resuelto.

## Lo que este diseño no sabe

Un fixture, tres archivos, defectos plantados a mano — menos representativos que
los reales. n entre 8 y 10 en lo medido el 2026-09-10, entre 2 y 5 en lo
anterior. `builder` y `surgeon` nunca se midieron: su andamiaje es analogía, no
resultado. `researcher` no se ha comparado entre Composer y Grok.

El ensemble agrupado (punto 6) está medido pero no empaquetado como comando. Y
el agregador que fusionara repeticiones sin perder defectos no existe: se barrió
el espacio de umbrales y no hay ninguno que lo consiga.

El pin `[fast=false]` está verificado por CLI, no por la ruta de subagentes de la
interfaz, que es otro código.

Los hooks quedaron fuera a propósito: se registran pero no se ejecutan en
`cursor-agent` 2026.09.02, comprobado en IDE y CLI.
