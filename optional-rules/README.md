# Reglas opcionales

No se cargan solas. `plugin.json` solo declara `rules/` como reglas del plugin,
así que lo de aquí está disponible pero apagado hasta que tú lo actives en un
repo concreto.

## `tdd.mdc` — cubre cada cambio con un test

Regla condicional: test-primero al arreglar un bug, construir-y-cubrir al crear
algo nuevo. Medida el 2026-09-11 (ver `lab/FINDINGS-plan-eval.md`, puntos 11-13):

- deja un test válido en el **100%** de los cambios, en bugfix y en greenfield
- **no** produce el anti-patrón de testear una interfaz inexistente (0/6)
- coste ~+20% de tiempo; la calidad del código no cambia

Es opcional a propósito: en bugfix cede algo de rigor de orden (0.83 vs 1.00 de
la versión estricta) a cambio de funcionar en greenfield, donde la estricta es un
no-op. Actívala donde quieras la disciplina, no globalmente.

## Activar en un repo

```bash
cp ~/.cursor/plugins/local/agent-discipline/optional-rules/tdd.mdc <repo>/.cursor/rules/
```

O copia la carpeta `cursor-fleet/.cursor/`, que ya la trae.
