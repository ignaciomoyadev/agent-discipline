# Agent Discipline

Harness personal para Cursor: contrato de salida, flota de subagentes anclada por
coste, y guía de enrutado. **Cada afirmación de aquí está medida**, no supuesta —
las mediciones son del 2026-09-08, sobre un fixture con defectos plantados.

## Instalar

```bash
git clone <este-repo> ~/.cursor/plugins/local/agent-discipline
```

Reinicia Cursor. Aparece como "Agent Discipline" en Rules, Subagents y Skills.

Eso es todo: no hay instalador, no hay archivos sueltos que copiar, y Cursor no
lo sobrescribe (a diferencia de la caché de plugins del marketplace, que sí
redescarga).

## Qué trae

### `rules/core.mdc` — la única regla siempre activa

Contrato de salida, honestidad en la verificación, control de alcance. 20 líneas,
porque se cobra en cada turno de cada sesión.

### `agents/` — siete roles de producción

| rol | modelo | modo | escribe |
|---|---|---|---|
| `scout` | `composer-2.5[fast=false]` | 1er plano | no |
| `hunter` | `composer-2.5[fast=false]` | fondo | no |
| `builder` | `composer-2.5[fast=false]` | 1er plano | **sí** |
| `auditor` | `composer-2.5[fast=false]` | 1er plano | no |
| `scribe` | `composer-2.5[fast=false]` | fondo | no |
| `researcher` | `grok-4.6[effort=medium,fast=false]` | fondo | no |
| `surgeon` | `grok-4.6[effort=xhigh,fast=false]` | 1er plano | **sí** |

### `skills/token-discipline/` — cómo enrutar

Escalar por evidencia, mantener estable el prefijo cacheable, descargar a disco
en vez de truncar.

## Las cuatro cosas medidas que explican el diseño

**1. El andamiaje del rol le gana a añadir agentes, por un orden de magnitud.**
Andamiar un agente único subió el recall +28 pp; añadir agentes lo movió entre 0
y −16.6 pp. Y el prompt malo era **el más caro**: no hace escribir más, hace
buscar más.

**2. El andamiaje depende de la capacidad del modelo.** El mismo texto dio +6.7 pp
en Composer, 0 en Opus y **−11 pp en Grok**. Por eso `surgeon` no lleva checklist
y `hunter` sí. No copies el patrón de uno al otro sin medir.

**3. Podar destruye.** Un verificador usado como puerta bajó el recall de 0.916 a
0.750, y un orquestador filtrando de 0.778 a 0.611 — el modelo *más* potente
borró *más*, incluido un defecto inequívoco de severidad alta en las tres
corridas. Por eso `auditor` anota y no elimina.

**4. Lo determinista le gana a lo pedido.** Un contrato de salida por prompt logró
0% de cumplimiento; el mismo criterio en código, 100%.

## Anclar el modelo: la trampa

Un slug pelado no basta. Con `model: composer-2.5` la interfaz resuelve a
**Composer 2.5 Fast** — $3/$15 por millón en vez de $0.50/$2.50, unas 6x. Fast es
el tier por defecto en Pro y superiores.

Y cada familia usa sintaxis distinta:

| familia | funciona | no funciona |
|---|---|---|
| Composer | `composer-2.5[fast=false]` | — |
| Grok | `grok-4.6[effort=xhigh,fast=false]` | `cursor-grok-4.6-xhigh[fast=false]` |

Grok solo acepta corchetes sobre el nombre base parametrizado, no sobre el slug
resuelto.

## Lo que este diseño no sabe

Un fixture, tres archivos, defectos plantados a mano — menos representativos que
los reales. n entre 2 y 5, cuando hacen falta ~9 corridas para detectar 2 pp.
`builder` y `surgeon` nunca se midieron: su andamiaje es analogía, no resultado.

Los hooks quedaron fuera a propósito: se registran pero no se ejecutan en
`cursor-agent` 2026.09.02, comprobado en IDE y CLI.
