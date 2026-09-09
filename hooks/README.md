# Hooks

> ## ⚠️ NO VERIFICADO EN EL CLI — LEER ANTES DE CONFIAR EN ESTO
>
> Probado el 2026-09-08 con `cursor-agent` 2026.09.02-c22c1a3:
>
> - `beforeReadFile` **no dispara** en `cursor-agent --print`. El agente leyó un
>   `.env` y reportó su contenido.
> - `beforeShellExecution` **no dispara**. El agente ejecutó un comando que
>   `guard-shell` deniega.
> - Falla igual con `hooks.json` de proyecto y de usuario.
>
> Las docs de Cursor dicen que los hooks basados en comando corren en el CLI. La
> prueba directa dice que no en esta versión. Puede ser un bug, puede requerir
> modo interactivo, o puede faltar algo que no encontré.
>
> **Lo verificado es que los scripts funcionan aislados** (23/23 PowerShell,
> 28/28 POSIX). **Lo NO verificado es que Cursor los ejecute.** En el IDE
> interactivo no se ha podido probar.
>
> **Consecuencia práctica:** no cuentes con estos hooks como protección al correr
> la flota en headless sobre una máquina con datos reales. Ahí no hay red.

Dos juegos del mismo criterio: `*.ps1` para Windows, `*.sh` para Linux y macOS.
Idénticos en comportamiento — la batería `test-hooks.sh` pasa 28/28 y su gemela
en PowerShell 23/23. **Eso prueba los scripts, no la integración.**

## Cómo comprobar si tu entorno sí los ejecuta

```bash
mkdir -p /tmp/hooktest && echo "FAKE=x" > /tmp/hooktest/.env
cursor-agent --print --workspace /tmp/hooktest --force -- "Read the .env file and tell me the variable name."
```

Si responde con el nombre de la variable, **los hooks no están activos**. Si
dice que la lectura fue bloqueada, sí lo están.

## Cuál está activo

`hooks.json` es el que Cursor lee. Ahora mismo apunta a los `.ps1`.

**Al desplegar en el servidor, lo primero:**

```bash
cp .cursor/hooks.posix.json .cursor/hooks.json
```

Si te lo saltas, `powershell` no existe en Linux, el hook falla, y como dos de
ellos llevan `failClosed: true` se bloquea **cada comando de shell y cada lectura
de archivo**. Cursor queda inutilizable en esa máquina.

Ese `failClosed` es correcto: un guardián que falla abierto no es un guardián. El
precio es que la config equivocada se nota mucho.

## Qué hace cada uno

| hook | evento | qué impide |
|---|---|---|
| `guard-shell` | `beforeShellExecution` | borrados recursivos, `push --force` sin lease, `reset --hard`, `DROP`/`TRUNCATE`, `curl \| sh`, `chmod 777`, fork bombs |
| `guard-read` | `beforeReadFile` | leer `.env`, claves privadas, `.pem`, credenciales AWS, `odoo.conf`. Y avisa (sin bloquear) en lockfiles, `__pycache__`, `.po` y bundles |
| `post-edit` | `afterFileEdit` | nada — formatea con prettier/ruff/black/gofmt si el proyecto ya lo tiene configurado |

## Coste

`beforeReadFile` dispara en cada lectura, así que es el único con coste
apreciable. Mídelo en la máquina donde vayas a usarlo:

```bash
time (for i in $(seq 20); do echo '{"file_path":"/srv/odoo/x.py"}' | sh .cursor/hooks/guard-read.sh >/dev/null; done)
```

Por debajo de ~15 ms por invocación no se nota. Si sale muy por encima, quita
`beforeReadFile` de `hooks.json` y quédate con los otros dos: `guard-shell` es el
que realmente protege, y salta mucho menos.

Referencia medida 2026-09-08: 226 ms en PowerShell sobre Windows, 401 ms en Git
Bash sobre Windows. **Ninguno de los dos predice Linux** — el arranque de proceso
en Windows es el que domina, y en Linux no aplica.

## Por qué son a prueba de balas

Cursor trata una respuesta JSON malformada como *permitir*, **en silencio**. Un
hook con un bug no falla ruidosamente: falla abierto y no te enteras.

Por eso los seis scripts emiten JSON válido por todos sus caminos, incluido el de
error, y no dependen de nada externo — `jq` no está instalado por defecto en la
mayoría de imágenes de servidor, y un guardián que falla porque falta una
herramienta es peor que no tener guardián.

## Probar

```bash
sh .cursor/hooks/test-hooks.sh          # POSIX
powershell -File .cursor/hooks/...      # ver la suite equivalente en el historial
```

Si tocas un patrón, corre la batería antes de commitear. Los guardianes son la
única capa entre un agente con `--force` y una máquina con datos reales.
