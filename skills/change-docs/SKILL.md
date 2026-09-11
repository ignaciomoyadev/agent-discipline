---
name: change-docs
description: >-
  Documenta y traza cambios no obvios en cualquier repo — reglas de negocio,
  comportamiento custom vs estándar, riesgos de migración, hallazgos de
  seguridad — en un árbol docs/ (plans, solutions, decisions, migration,
  security). Úsala al implementar, corregir o planificar un cambio cuyo
  razonamiento se perdería si solo vive en el commit o en el chat.
color: green
---

# Change docs

Fuente de verdad: `docs/` en la **raíz del repo activo**. Si no existe, créala al
primer cambio que merezca traza.

Es agnóstica de stack. Para reglas de un dominio concreto (Odoo, un framework,
un servicio), añade una skill o regla específica de ese repo; esta cubre el
esqueleto y la disciplina de cuándo documentar.

## Cuándo aplicar

Todo cambio de lógica, regla de negocio, comportamiento custom vs estándar de la
librería/framework, o riesgo de migración. **No** hace falta ficha para typo,
rename, bump de versión o fix trivial sin decisión.

La prueba: si dentro de tres meses alguien preguntaría "¿por qué está esto así?"
y el commit no lo responde, hay ficha.

## Estructura

```text
docs/
  plans/       # trabajo en curso (planes vivos)
  solutions/   # ya resuelto / aprendizaje reutilizable
  decisions/   # ADR corto: por qué se hizo X
  migration/   # riesgos y checklist de cambios de versión (opcional)
  security/    # registro de hallazgos (README + TEMPLATE + findings/) (opcional)
  components/  # nota por módulo/servicio relevante (opcional)
  archive/     # planes cerrados (opcional)
```

No uses carpetas paralelas `issues/` + `fixes/` (duplican y envejecen mal). Issue
abierto = ticket o sección Open en el plan; al cerrar → `solutions/` o
`decisions/`.

## Flujo por tipo de trabajo

1. **Plan / feature en curso** → `docs/plans/<slug>.md`. Actualiza el mismo
   archivo mientras avanza. Al terminar: mueve a `archive/` o marca cerrado, y si
   dejó aprendizaje → ficha en `solutions/` o `decisions/`.
2. **Bug / lógica de negocio descubierta o corregida** → `docs/solutions/<area>-<slug>.md`.
3. **Decisión estable** (qué cuenta como X, qué no tocar en otro sitio) →
   `docs/decisions/NNNN-<slug>.md`. Numeración opcional `0001`, `0002`…
4. **Impacto en un upgrade** → bullet en `docs/migration/<from>-to-<to>.md`
   (créalo si no existe) y/o nota en `docs/components/<nombre>.md`.
5. **Componente nuevo o poco documentado** → esqueleto en
   `docs/components/<nombre>.md` (propósito, límites, dependencias, riesgos).
6. **Hallazgo de seguridad** → fila en `docs/security/README.md` (id `S-NNN`,
   componente, vector, severidad, exposición, estado) y, si merece detalle, ficha
   con `docs/security/TEMPLATE.md`. El detalle puede vivir en `solutions/` y
   enlazarse; lo que no puede faltar es la fila en el registro.

## Qué documentar

| Sí | No |
|----|----|
| Reglas no obvias ("ajuste ≠ consumo") | Typo / rename / bump versión |
| Custom vs estándar de la librería | Fix trivial sin decisión |
| Riesgo de API/contrato en migración | Planes descartados sin aprendizaje |
| Decisiones de dominio en código | Duplicar lo que el commit ya dice solo |
| Hallazgo de seguridad (→ `security/`) | Detalle ya cubierto por otra ficha |

Esta tabla es una taxonomía, no una guía vaga — criterios concretos deciden
mejor que "documenta lo importante". No la recortes a la mitad.

Idioma de las fichas: el del equipo. Nombres de archivo: kebab-case, consistentes.

## Durante el cambio de código

1. Lee el `docs/` relacionado antes de inventar reglas.
2. Si el cambio altera semántica de negocio o exclusiones, actualiza o crea ficha
   **en el mismo trabajo** — no "después".
3. En la respuesta al usuario: menciona la ruta del doc tocado (una línea).
4. No commitees docs a menos que el usuario pida commit.

## Anti-patrones

- Plan solo en una rama/servidor sin copia en `docs/plans/`.
- Documentar antes de tener claridad y nunca actualizar.
- Carpetas demasiado finas (`bugs/`, `fixes/`, `patches/`).
- Novelas: media página útil le gana a tres de relleno.

## Plantillas

En [templates.md](templates.md). Ficha mínima si el cambio es pequeño: síntoma,
causa, decisión, estado, nota de migración.
