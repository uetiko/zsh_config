SOURCE: backend/docs/spec_methodology/07_CODEX_IMPLEMENTATION_TASK.md
ADAPTATION: OMP Specification Skill v0.1 (executor-neutral)

# 07 — Execution Contract: corrección de funciones fzf en `zsh_functions`

## OBJECTIVE

Aplicar las 9 correcciones especificadas (BR-001..BR-009 / TASK-001..TASK-009) a `zsh_functions`, de forma que
cada una de las 20 pruebas de aceptación de `08_ACCEPTANCE_TEST_SPECIFICATION.md` pase, sin alterar ningún
comportamiento fuera del alcance declarado.

## BASELINE

Repositorio: `/home/abarrientos/Público/zsh_config` (`zsh_config`), rama `master`, tracking `origin/master`,
`+0/-0` respecto al remoto.

`HEAD` = `f589f6a1a45bacb09c7b6c0d173c9205dfa6208e` (2025-06-18 13:11:54 -0600).

**Working tree sucio al momento de este contrato — preexistente, no producido por esta tarea.** `git diff --stat`
muestra cambios sin commitear en 6 archivos: `.gitignore`, `install.sh`, `zsh_code`, `zsh_functions`, `zsh_init`,
`zshenv`. Además hay dos entradas no rastreadas: `.github/workflows/`, `zshenv.local.example`. Los cambios
pendientes en `zsh_functions` específicamente son: port de `pbcopy` → `wl-copy` (Linux), refactor del guardado
temporal en `search_history` (uso de `$__SEARCH_HISTORY_EDIT_FILE` vía `mktemp` en vez de `/tmp/cmd.sh` fijo, y
`zsh -c` en vez de `bash -c` en `ctrl-x`), y guardia de stash condicional ya agregada en `git_fetch_all_branch`
(`if [[ -n "$(git status --porcelain)" ]]; then git stash; ...`).

**El contenido de `zsh_functions` leído y analizado en `03_HARD_SPECIFICATION.md` y en las etapas siguientes es
el contenido actual del working tree (incluye ya esos cambios pendientes)** — no el de `HEAD`. Este contrato
edita ese mismo contenido; no revierte, no re-narra ni toca ninguna línea de esos cambios preexistentes salvo
donde una tarea de este contrato coincide exactamente con la línea a corregir (ninguna coincide: las 9 tareas
tocan `preview_file_finder`, `git_add_patch_file`, `git_change_branch`, el bucle de `git_fetch_all_branch` fuera
del bloque de stash ya modificado, `git_activiy`, `finder_edit`, los dos `bindkey` finales, `cdt`, `cdf` — ninguna
de estas líneas figura en el diff preexistente listado arriba).

## CURRENT_BEHAVIOR

Ver `03_HARD_SPECIFICATION.md` §"Problema que se resuelve" (tabla issue → BR) para el comportamiento defectuoso
actual de cada una de las 9 funciones/widgets en alcance.

## DESIRED_BEHAVIOR

Exactamente BR-001..BR-009 de `03_HARD_SPECIFICATION.md`, verificable mediante AT-001..AT-020 de
`08_ACCEPTANCE_TEST_SPECIFICATION.md`.

## SCOPE

Las funciones: `preview_file_finder`, `git_add_patch_file`, `git_change_branch`, `git_fetch_all_branch` (sólo el
cuerpo del bucle `for branch in ...`), `git_activiy`, `finder_edit` (eliminación completa), los dos `bindkey`
finales de `search_history`/`finder`, `cdt`, `cdf`. Archivo único: `zsh_functions`.

## OUT_OF_SCOPE

- Unificación de `cd`/`cdf`/`cdt` (decisión humana cerrada: mantener separadas).
- Comportamiento de `cd()` sin argumentos abriendo el navegador fzf (decisión humana cerrada: mantener).
- Escapado literal `\n` en selección de historial multi-línea (issue #12, Fase 3, no autorizada).
- Robustez de `git_search_log` ante `core.abbrev` variable (issue #13, Fase 3, no autorizada).
- Corrección del typo "git_activiy" → "git_activity" (no forma parte de ningún BR; renombrar la función
  rompería la interfaz de invocación sin que ningún BR lo exija — se reporta como hallazgo, no se ejecuta).
- Preview con `cat` vs `bat` en `preview_file_finder`/`finder` (inconsistencia de estilo detectada en discovery,
  no convertida en BR por decisión de alcance del análisis de proyecto).
- Cualquier otra función del archivo no listada en `SCOPE`.
- Los 6 archivos con cambios preexistentes no relacionados listados en `BASELINE` — no se tocan.

## INVARIANTS

- Ninguna función fuera de `SCOPE` cambia de comportamiento observable.
- Ningún cambio preexistente del working tree (ver `BASELINE`) se revierte, pisa o re-narra.
- El nombre de invocación de cada función se preserva, excepto `finder_edit` (eliminada por BR-006) — ningún
  otro rename.
- No se introduce ninguna dependencia externa nueva (todas las herramientas usadas ya están presentes:
  zsh 5.9, fzf 0.74.3, git, findutils, sed, awk, grep, tree, bat, wl-copy).
- No se ejecuta ninguna operación Git de escritura (`commit`, `push`, etc.) sobre este repositorio como parte de
  la implementación — sólo edición de archivos en el working tree.

## AUTHORIZED_DECISIONS

Cerradas explícitamente por el usuario en el análisis de proyecto previo de esta misma conversación:

1. **`keybindings`** = `Alt-r` para `search_history`, `Alt-f` para `finder` (libera `^E`/`^F` nativos).
2. **`nav_scope`** = mantener `cd`/`cdf`/`cdt` separadas; sólo fix mínimo de `cdt` (reconstrucción de ruta) y
   ajuste de cabecera de `cdf` — sin unificación.
3. **`cd_override`** = mantener `cd()` como override del builtin (sin args abre el navegador fzf).

Ninguna otra decisión de diseño está autorizada más allá de estas 3 y de las reglas BR-001..BR-009.

## ASSUMPTIONS

- **SUP-01** (de `03_HARD_SPECIFICATION.md`): `git_activiy` no adopta un remoto por defecto; el argumento es
  obligatorio. Si se determina falso (el usuario prefiere un default), es un `DECISION_REQUIRED` nuevo, no una
  corrección de este contrato.
- Existe al menos un repositorio git desechable disponible para el ejecutor con el que validar AT-003..AT-011
  sin afectar `zsh_config` ni ningún repositorio real del usuario.

## DEPENDENCIES

Ninguna externa a este repositorio. Ninguna dependencia entre las 9 tareas (ver `06_TASK_BREAKDOWN.md`
§"Grafo de dependencias").

## CONSTRAINTS

- Editar únicamente `zsh_functions`, únicamente los rangos de líneas de las funciones en `SCOPE`.
- Preservar estilo existente del archivo (indentación, convención de nombres en español/inglés mixto ya
  presente, no reformatear líneas no tocadas).
- TASK-007 (rebind) debe verificar ausencia de colisión de `Alt-r`/`Alt-f` con bindings ya activos (oh-my-zsh,
  plugin `git`, plugin `wakatime`, o el resto de `zsh_functions`) antes de aplicar; si hay colisión, detener esa
  tarea puntual y reportar (`STOP_REPORT`) en vez de sobreescribir en silencio.

## INPUTS

- `03_HARD_SPECIFICATION.md` (este mismo directorio) — reglas de negocio BR-001..BR-009.
- `04_USE_CASE_DEFINITION.md` — UC-001..UC-009.
- `05_BEHAVIOR_SPECIFICATION.md` — SC-001..SC-020.
- `06_TASK_BREAKDOWN.md` — TASK-001..TASK-009.
- `08_ACCEPTANCE_TEST_SPECIFICATION.md` — AT-001..AT-020, fuente directa de `ACCEPTANCE_CRITERIA` abajo.
- Contexto técnico verificado en esta conversación: zsh 5.9, fzf 0.74.3, oh-my-zsh (`plugins=(git wakatime)`),
  `bat`/`fd`/`tree`/`wl-copy` presentes.
- Decisiones humanas cerradas: ver `AUTHORIZED_DECISIONS`.

## IMPLEMENTATION_GUIDELINES

Por cada TASK-001..TASK-009, aplicar exactamente la descripción de `06_TASK_BREAKDOWN.md` §"Tareas" (no
reinterpretar). Orden de ejecución libre (todas paralelizables); si se ejecutan en una sola pasada sobre el
archivo, aplicar de la línea de mayor número a la de menor número para evitar invalidar offsets de línea ya
calculados, o releer el archivo entre cada edición.

## VALIDATION

Para cada tarea, ejecutar la prueba de aceptación correspondiente (tabla `08_ACCEPTANCE_TEST_SPECIFICATION.md`
§"Matriz de trazabilidad") como smoke test manual: reproducir el comportamiento previo contra el código sin
modificar (confirmar que efectivamente falla/está roto), aplicar el cambio, repetir la prueba (confirmar que
ahora pasa). AT-013/AT-014 (disparo real de `Alt-r`/`Alt-f`) pueden validarse por inspección de `bindkey` más
prueba manual del propio ejecutor humano en su sesión — no requieren harness de terminal automatizado si se deja
constancia de la verificación manual.

## ACCEPTANCE_CRITERIA

Las 20 pruebas AT-001..AT-020 de `08_ACCEPTANCE_TEST_SPECIFICATION.md` pasan. Ninguna prueba existente de otro
comportamiento no relacionado se ve afectada (no hay suite de tests preexistente en el repositorio: verificación
por smoke test manual de las funciones colindantes que comparten archivo).

## DEFINITION_OF_DONE

- Las 9 tareas aplicadas exactamente según `06_TASK_BREAKDOWN.md`.
- Las 20 pruebas de aceptación (`08_ACCEPTANCE_TEST_SPECIFICATION.md`) verificadas y documentadas como
  pasando (evidencia concreta: comando ejecutado + resultado, no narración).
- `git diff -- zsh_functions` muestra únicamente cambios dentro del `SCOPE` declarado, más los cambios
  preexistentes ya presentes en `BASELINE` sin alteración.
- Ningún archivo fuera de `zsh_functions` modificado.
- Sin operaciones Git de escritura ejecutadas (commit/push quedan para autorización humana posterior y separada).

## DELIVERABLES

- `zsh_functions` corregido según `SCOPE`.
- Evidencia de verificación de las 20 pruebas de aceptación (comandos + resultados).
- Reporte de cualquier hallazgo fuera de alcance detectado durante la implementación (p. ej. colisión de
  binding en TASK-007), sin corregirlo.

## REPORTING_FORMAT

Al finalizar: lista de TASK-001..TASK-009 con estado (`DONE`/`BLOCKED`/`STOP_REPORT` por tarea), evidencia de
cada AT-001..AT-020, y cualquier `DECISION_REQUIRED` o `STOP_REPORT` nuevo que haya surgido durante la
implementación (p. ej. colisión de binding, comportamiento de `tree` distinto al asumido).

## STOP_CONDITIONS

- Colisión detectada entre `Alt-r`/`Alt-f` y un binding ya activo (TASK-007) → detener esa tarea, reportar,
  continuar con el resto.
- Cualquier edición que requiera tocar una línea ya modificada por el working tree preexistente (`BASELINE`) →
  detener, reportar la colisión, no resolverla en silencio.
- Cualquier necesidad de tocar una función fuera de `SCOPE` para lograr el comportamiento deseado → detener esa
  tarea puntual, reportar como `DECISION_REQUIRED` (posible expansión de alcance no autorizada).
- Información insuficiente para reproducir un escenario de `05_BEHAVIOR_SPECIFICATION.md` → detener esa tarea,
  reportar qué falta.

---

## STATUS: EXECUTION_READY

Las 9 tareas están completamente especificadas, trazadas a reglas de negocio verificables, con criterios de
aceptación concretos y un baseline real del repositorio. `EXECUTION_READY` es un juicio de madurez de la
especificación — **no es autorización para implementar**.

### MANDATORY_EXECUTION_GATE

Me detengo aquí. No implemento, no modifico `zsh_functions`, no ejecuto ninguna de las 9 tareas. Esperando
instrucción humana explícita que autorice específicamente la ejecución (total o parcial, por fase o por tarea).
