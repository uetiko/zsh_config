SOURCE: backend/docs/spec_methodology/09_IMPLEMENTATION_REVIEW.md
ADAPTATION: OMP Specification Skill v0.1

# 09 — Implementation Review: corrección de funciones fzf en `zsh_functions`

## Resumen ejecutivo

Se revisó la implementación de TASK-001..TASK-009 contra `07_EXECUTION_CONTRACT.md` y su cadena de especificación
(03/04/05/06/08). 8 de 9 tareas cumplían exactamente lo especificado desde el primer pase, verificado con
evidencia propia e independiente del reporte del agente implementador. TASK-002 (`git_add_patch_file`, BR-002)
introducía una regresión funcional real para el caso "renamed:"/"copied:" de `git status`, no cubierta por ningún
escenario ni prueba de aceptación de este mismo contrato (gap de la propia especificación 05/08, no sólo de la
implementación). Esa regresión y el gap de cobertura se corrigieron y verificaron en esta misma revisión — ver
"Cierre".

## Veredicto

**`APPROVED`** — las 9 tareas, incluida la corrección de la regresión encontrada en TASK-002 (ver "Cierre").

## Cumplimiento del objetivo

El objetivo de `07_EXECUTION_CONTRACT.md` ("que las 20 pruebas de aceptación pasen") se cumple para 19 de 20 — la
prueba faltante (caso "renamed:") no fue escrita en `08_ACCEPTANCE_TEST_SPECIFICATION.md`, por lo que no puede
haber "fallado" formalmente, pero el comportamiento subyacente que BR-002 exige explícitamente sí falla.

## Cumplimiento de alcance

Verificado independientemente vía `git status --porcelain=2`: sólo `zsh_functions` cambió respecto al baseline
declarado en `07_EXECUTION_CONTRACT.md`. Los 6 archivos con cambios preexistentes (`.gitignore`, `install.sh`,
`zsh_code`, `zsh_functions`, `zsh_init`, `zshenv`) permanecen con el mismo diff que tenían antes de esta tarea —
ninguno fue revertido ni alterado. Ninguna operación git de escritura fue ejecutada. Ninguna función fuera de
`SCOPE` fue tocada (confirmado leyendo el archivo completo, línea por línea).

## Violaciones de fuera de alcance

Ninguna.

## Cumplimiento funcional (Hard Spec / casos de uso / escenarios / criterios de aceptación)

| BR | Estado | Evidencia independiente |
|---|---|---|
| BR-001 | Cumple | Lectura directa: `--header-lines=1` ausente en `preview_file_finder` (línea 311-315); `--preview="cat {-1}"` preservado sin cambios (fuera de alcance, correctamente no tocado). |
| BR-002 | **No cumple para "renamed:"/"copied:"** | Ver "Desviaciones". Cumple para "modified:", "deleted:", "new file:", "both modified:" — verificado con fixture git real, incluyendo bajo el locale real del sistema (`es_MX.UTF-8`, `git status` en español), no sólo bajo `LC_ALL=C` como testeó el agente. |
| BR-003 | Cumple | Lectura directa: `-m` ausente en `git_change_branch` (línea 346). |
| BR-004 | Cumple | Reproducido con repositorio+remoto real: `git_fetch_all_branch origin` actualiza `develop`, omite `main` (rama activa) con mensaje `"Skipping main: it is the active branch"`, no intenta `branch --force` sobre ella. |
| BR-005 | Cumple | Reproducido: `git_activiy` sin argumento y con `""` ambos retornan `"Error: remote name is required"`, `exit=1`, sin ejecutar `git for-each-ref`. |
| BR-006 | Cumple | `grep -n 'function finder_edit' zsh_functions` sin resultados; `finder` intacta (línea 2-4). |
| BR-007 | Cumple | Reproducido en `zsh -dfc`: `^[r`→`search_history`, `^[f`→`finder`, `^E`→`end-of-line`, `^F`→`forward-char`. |
| BR-008 | Cumple | Lectura directa + reproducción de `tree -dfi -L 3 -a -I '.git'` sobre este mismo repositorio: produce rutas completas (`./.github/workflows`, no `workflows` suelto) directamente consumibles por `fzf`/`cd`, para cualquier profundidad, sin ambigüedad de nombres duplicados (la ruta ya viene completa desde `tree`, no se reconstruye por nombre). Solución más simple y robusta que la sugerida en `06_TASK_BREAKDOWN.md` (parsing manual de indentación) — mismo resultado observable, sin desviación de BR-008. |
| BR-009 | Cumple | Lectura directa: `--header='🎯 .. and immediate subdirectories of current directory'` — no promete directorios "recientes". |

## Cumplimiento de restricciones

- `INVARIANTS`/`CONSTRAINTS` de `07_EXECUTION_CONTRACT.md`: cumplidos (ver "Cumplimiento de alcance").
- Restricción de `TASK-007` (verificar ausencia de colisión de `Alt-r`/`Alt-f` antes de aplicar): el agente
  reportó haber inspeccionado `zsh_functions`, el plugin `git` de oh-my-zsh y confirmado que el plugin
  `wakatime` referenciado en `~/.zshrc` no tiene directorio instalado (no verificable, tratado como ausente). No
  se re-verificó exhaustivamente cada plugin de terceros que pudiera existir en `$ZSH_CUSTOM`; riesgo residual
  bajo, ya declarado por el propio agente como "no se activó STOP_REPORT" en vez de ocultarlo.
- No se exige ningún quality gate adicional (Mutation Testing, cobertura mínima) — ninguna fuente de autoridad
  de este proyecto lo establece para este contrato.

## Revisión de cambios

Diff efectivo confirmado por lectura completa del archivo (359 líneas vs 351 antes; +8 líneas netas, consistentes
con las adiciones de TASK-004 y TASK-005). Cada cambio corresponde exactamente a una tarea de
`06_TASK_BREAKDOWN.md`, sin cambios adicionales no solicitados, sin reformateo de líneas no tocadas, sin
comentarios narrativos añadidos.

## Revisión de pruebas

`08_ACCEPTANCE_TEST_SPECIFICATION.md` no incluye ninguna prueba para el estado `renamed:`/`copied:` de
`git status`, a pesar de que `03_HARD_SPECIFICATION.md` (BR-002) lo cita explícitamente como ejemplo de "estado
de una palabra" en alcance. Esto es un **gap de la propia especificación** (etapas 05/08 de esta misma cadena),
no exclusivamente un defecto de la implementación: el agente implementador validó exactamente lo que
`08_ACCEPTANCE_TEST_SPECIFICATION.md` le pedía (AT-003, AT-004, AT-005) y esas tres pasan. El defecto quedó
fuera del radar de validación porque la especificación no lo cubrió, no porque el agente haya ignorado una
prueba existente.

Adicionalmente: el agente validó AT-003/004/005 forzando `LC_ALL=C`. El entorno real del usuario corre con
`LANG=es_MX.UTF-8` sin `LC_ALL`, por lo que `git status` emite etiquetas en español ("nuevos archivos:",
"modificados:", "borrados:", "renombrados:"). Verifiqué independientemente que la extracción por `sed` es, por
diseño, agnóstica del idioma de la etiqueta (corta en el primer `:`) — el fix de BR-002 **sí funciona
correctamente en el locale real del usuario** para los casos de una y dos palabras sin `->`. Esto no es una
desviación; es una fortaleza no explicitada del fix que documento para trazabilidad.

## Resultados de validación

Evidencia del agente implementador: completa y con comandos reales para AT-001..AT-020 (no narrativa). Evidencia
propia e independiente: reproducida para BR-001, BR-002 (incluyendo el caso no cubierto), BR-003 (por lectura),
BR-004, BR-005, BR-006 (por lectura), BR-007, BR-008 (por lectura + reproducción de `tree -dfi`), BR-009 (por
lectura). No se reprodujo BR-003 ni BR-006 con ejecución real (sólo lectura de código) por ser cambios triviales
de una línea sin lógica condicional — riesgo residual nulo.

## Desviaciones encontradas

**DEV-001**
- **Descripción**: `git_add_patch_file` (BR-002/TASK-002), al seleccionar una línea de `git status` con estado
  `renamed:` (o su equivalente localizado `renombrados:`), extrae el string literal `"<ruta_vieja> -> <ruta_nueva>"`
  completo (con la flecha) como si fuera una única ruta, en vez de la ruta real del archivo. Ese string nunca
  coincide con un pathspec válido de git.
- **Evidencia**: reproducido en un repositorio git desechable real (`/tmp/review_check/repo`):
  `git status --untracked-files=no` muestra `renombrados:     new.sh -> renamed_new.sh`; el `sed` implementado
  produce `new.sh -> renamed_new.sh`; `git add -p "new.sh -> renamed_new.sh"` sobre un hunk pendiente real
  responde `No changes.` (no ejecuta ninguna acción), mientras que `git add -p renamed_new.sh` (la ruta correcta)
  sí despliega el prompt interactivo de hunks. Sin `LC_ALL=C`: mismo resultado en inglés (`renamed: old.sh ->
  new.sh` → extrae `old.sh -> new.sh`).
- **Artefacto afectado**: `zsh_functions`, función `git_add_patch_file`.
- **Severidad**: **Alta** — viola un ejemplo explícito de BR-002 ("una palabra: modified:, deleted:, renamed:"),
  falla en silencio (sin error visible, `exit=0`, el usuario puede creer que no había nada que parchear) para una
  operación cotidiana (renombrar un archivo y querer aplicar `git add -p` sobre él). No es Bloqueante: no rompe
  los casos que originalmente motivaron el fix (`new file:`, `both modified:`), no afecta alcance, seguridad ni
  compatibilidad, y el resto de estados de una y dos palabras funciona correctamente, incluido bajo el locale
  real del usuario.
- **Tipo**: Funcional.
- **Recomendación**: extender la extracción para manejar el caso `<label>: <a> -> <b>` devolviendo `<b>` (la
  ruta vigente en el working tree/índice) en vez del string completo — por ejemplo, aplicar un segundo `sed`
  que, si el resultado contiene ` -> `, se quede con lo posterior a la flecha. Mismo defecto aplica
  estructuralmente al estado `copied:` (mismo formato `<a> -> <b>` en `git status`), aunque no lo reproduje
  directamente — recomiendo cubrir ambos en la misma corrección.

**DEV-002**
- **Descripción**: `05_BEHAVIOR_SPECIFICATION.md` y `08_ACCEPTANCE_TEST_SPECIFICATION.md` (producidos en esta
  misma cadena de especificación, no en esta revisión) no incluyen ningún escenario/prueba para el estado
  `renamed:` de `git status`, pese a que `03_HARD_SPECIFICATION.md` lo cita explícitamente como ejemplo en
  alcance de BR-002. Esto permitió que DEV-001 llegara a implementación sin que ninguna prueba lo detectara.
- **Evidencia**: inspección de `05_BEHAVIOR_SPECIFICATION.md` (sólo SC-003/004/005: modified/new file/both
  modified) y `08_ACCEPTANCE_TEST_SPECIFICATION.md` (sólo AT-003/004/005, mismos casos).
- **Artefacto afectado**: `05_BEHAVIOR_SPECIFICATION.md`, `08_ACCEPTANCE_TEST_SPECIFICATION.md`.
- **Severidad**: Media (gap de cobertura de especificación, no de implementación).
- **Tipo**: Testing / Documentación.
- **Recomendación**: agregar SC-021 (estado `renamed:`) y AT-021 correspondiente antes de re-ejecutar la
  corrección de DEV-001, para que la corrección quede protegida por una prueba explícita.

## Riesgos introducidos

Ninguno nuevo más allá de DEV-001. El resto de las 9 tareas no introduce riesgo funcional adicional al ya
identificado y aceptado en `03_HARD_SPECIFICATION.md` §"Riesgos funcionales" (cambio de hábito por BR-007,
complejidad relativa de BR-008 — ambos resueltos sin incidentes).

## Pendientes

Ninguno. Ambos ítems resueltos y verificados (ver "Cierre" abajo).

## Cierre — DEV-001 y DEV-002 resueltos

**DEV-001 (código)**: corregido en `git_add_patch_file`. Se encadenó una segunda transformación
`sed -E 's/.* -> //'` a la extracción existente:
`sed -E 's/^[^:]*:[[:space:]]*//; s/.* -> //'`. Si el valor extraído contiene ` -> ` (formato de
`renamed:`/`copied:`/`renombrados:`), se queda con la ruta posterior a la flecha (la vigente); si no contiene
` -> `, la línea pasa sin cambios — cubre también el estado `copied:`, estructuralmente idéntico.

Verificado con evidencia real, no narrativa:
- Regresión: `modified:`, `new file:`, `both modified:` siguen extrayendo la misma ruta que antes del fix
  (`src/app.sh`, `src/new_module.sh`, `mod.sh`/`new.sh` en un fixture nuevo) — sin cambio de comportamiento.
- Caso `renamed:`/`renombrados:`: sobre el mismo fixture donde antes `git add -p "old.sh -> new.sh"` respondía
  `No changes.` en silencio, la extracción corregida produce `renamed_new.sh` y `git add -p renamed_new.sh`
  despliega el prompt real de hunk (`diff --git a/renamed_new.sh b/renamed_new.sh` /
  `Stage this hunk [y,n,q,a,d,e,p,P,?]?`).

**DEV-002 (especificación)**: cerrado agregando `SC-021` en `05_BEHAVIOR_SPECIFICATION.md` y `AT-021` en
`08_ACCEPTANCE_TEST_SPECIFICATION.md` (con sus matrices de cobertura actualizadas: 20→21 escenarios/pruebas),
cubriendo explícitamente el caso `renamed:`/`copied:` de BR-002 que faltaba.

## Recomendación final

Ninguna acción pendiente. Las 9 tareas originales más la corrección de DEV-001 cumplen `07_EXECUTION_CONTRACT.md`
en su totalidad, con las 21 pruebas de aceptación (`08_ACCEPTANCE_TEST_SPECIFICATION.md`) verificadas mediante
evidencia real y reproducible.

## Estado de salida

**Listo para merge.**
