# Plantillas — change-docs

Agnósticas de stack. Rellena solo los campos que apliquen.

## Plan (`docs/plans/<slug>.md`)

```markdown
# <Título del plan>

- Estado: open | in_progress | done
- Componentes: <lista>
- Versión / destino: <si aplica>
- Actualizado: YYYY-MM-DD

## Objetivo
<1-3 frases>

## Alcance
- Incluye:
- No incluye:

## Pasos
- [ ] …

## Riesgos / migración
- …

## Open
- …
```

## Solution (`docs/solutions/<slug>.md`)

```markdown
# <Componente>: <título corto>

- Componente: <nombre>
- Fecha: YYYY-MM-DD
- Tipo: logic_error | runtime | integration | decision
- Severidad: low | medium | high | critical
- Estado: open | fixed
- Tags: [..]

## Síntoma
Qué se veía mal (ejemplo si ayuda).

## Causa
Dónde en el código / por qué (archivo + función si aplica).

## Decisión
Qué debe pasar / qué no; regla de negocio en una frase.

## Resolución
(si fixed) qué se cambió; (si open) qué falta.

## Migración
Qué revisar al portar a otra versión.
```

## Decision / ADR (`docs/decisions/NNNN-<slug>.md`)

```markdown
# ADR NNNN: <título>

- Fecha: YYYY-MM-DD
- Estado: accepted | superseded
- Componentes: …

## Contexto
Por qué hace falta decidir.

## Decisión
Qué hacemos.

## Consecuencias
Implica / no implica; impacto aguas abajo.

## Migración
…
```

## Componente (`docs/components/<nombre>.md`)

```markdown
# <nombre>

- Versión / base: …
- Depends: …

## Propósito
…

## Límites (qué NO hace)
…

## Archivos clave
- …

## Decisiones relacionadas
- docs/decisions/…
- docs/solutions/…

## Riesgos de migración
- …
```

## Migration seed (`docs/migration/<from>-to-<to>.md`)

```markdown
# Migración <from> → <to>

## Checklist componentes
- [ ] <componente> — ver docs/components/<nombre>.md

## Riesgos conocidos
- …

## Decisiones que no se pueden "adivinar" del código
- …
```

## Security finding (`docs/security/TEMPLATE.md`)

```markdown
# S-NNN: <título>

- Componente: …
- Vector: <cómo se alcanza>
- Severidad: low | medium | high | critical
- Exposición: <interna | red | internet>  ← verificar por separado del vector
- Estado: open | mitigated | fixed
- Fecha: YYYY-MM-DD

## Qué
Qué permite y bajo qué condición.

## Evidencia
Archivo + líneas. No reclamar como probado lo que no se ejecutó.

## Mitigación
Qué la cierra.
```
