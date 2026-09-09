# Plantilla `.claude/`

Copia la carpeta `.claude/` a la raíz de cualquier repo. Nada más.

```bash
cp -r claude-template/.claude /ruta/al/repo/
```

## Por qué aquí y no en el plugin

Medido el 2026-09-09 con un canario anclado a `glm-5.2-high`, sesión en Grok:

| ubicación | ¿registra? | ¿respeta el pin? |
|---|---|---|
| `.claude/agents/` | ✅ | ✅ **devolvió GLM 5.2** |
| `.cursor/agents/` | ✅ | ✅ |
| plugin `agents/` | ✅ | ❌ devolvió Grok |
| `~/.cursor/agents/` | ❌ ni aparece en el enum | — |

El pin importa: con el default de esta cuenta en `grok-4.6`, los cinco roles
anclados a Composer correrían ~7x más caros desde el plugin. `scout` pasaría de
$0.027 a $0.189 por llamada, siendo el que más corre.

`.claude/` además es la ubicación nativa de Claude Code, así que la misma carpeta
sirve para las dos herramientas.

## Qué lleva

**7 agentes** — `scout`, `hunter`, `builder`, `auditor`, `scribe`, `researcher`,
`surgeon`. Solo `builder` y `surgeon` pueden escribir.

**La skill `token-discipline`** la sirve el plugin a nivel global — no se copia aquí para
no tenerla dos veces.

## Qué NO lleva, y dónde está

**La regla `core`** va en el plugin `agent-discipline`, que sí funciona a nivel
global. No hace falta copiarla por repo.

**Los hooks** no se ejecutan en `cursor-agent` 2026.09.02 — se registran pero su
log queda vacío. Los scripts están en el plugin, probados en aislado, listos
para cuando Cursor los ejecute.

## Al crear o editar un agente

El modelo va con `[fast=false]`. Un slug pelado resuelve a la variante Fast:
mismo modelo, mismo esfuerzo, unas 6x el precio.

Y cada familia usa sintaxis distinta:

| familia | funciona | no funciona |
|---|---|---|
| Composer | `composer-2.5[fast=false]` | — |
| Grok | `grok-4.6[effort=xhigh,fast=false]` | `cursor-grok-4.6-xhigh[fast=false]` |
