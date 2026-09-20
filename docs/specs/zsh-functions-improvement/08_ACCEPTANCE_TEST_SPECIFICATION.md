SOURCE: backend/docs/spec_methodology/08_ACCEPTANCE_TEST_SPECIFICATION.md
ADAPTATION: OMP Specification Skill v0.1

# 08 — Acceptance Test Specification: corrección de funciones fzf en `zsh_functions`

## Resumen ejecutivo

21 pruebas de aceptación, una por escenario de `05_BEHAVIOR_SPECIFICATION.md`. AT-021 se agregó tras
`09_IMPLEMENTATION_REVIEW.md` (DEV-002) para cerrar un gap de cobertura de BR-002 detectado en revisión.
Contexto técnico: zsh 5.9, fzf 0.74.3, GNU findutils/sed/awk/grep, `tree`, `bat`, `wl-copy` — todo ya presente en
el entorno. La mayoría son
automatizables mediante scripts de shell aislados (zsh no interactivo con `print -s`/`history -s` para poblar
estado, y funciones invocadas con entrada simulada de fzf vía `--filter` o invocación directa de la lógica sin
fzf); las que dependen de una sesión ZLE interactiva real (bindings) se marcan como no automatizables por script
simple y requieren verificación manual o un harness de terminal (p. ej. `tmux send-keys`).

## Estrategia general de aceptación

Cada prueba reproduce primero el comportamiento defectuoso (falla contra el código actual) y luego confirma el
comportamiento corregido (pasa contra el código corregido) — sirve como regresión, no sólo como demostración.

## Matriz de trazabilidad

| Hard Spec | Caso de uso | Escenario | Prueba |
|---|---|---|---|
| BR-001 | UC-001 | SC-001 | AT-001 |
| BR-001 | UC-001 | SC-002 | AT-002 |
| BR-002 | UC-002 | SC-003 | AT-003 |
| BR-002 | UC-002 | SC-004 | AT-004 |
| BR-002 | UC-002 | SC-005 | AT-005 |
| BR-002 | UC-002 | SC-021 | AT-021 |
| BR-003 | UC-003 | SC-006 | AT-006 |
| BR-003 | UC-003 | SC-007 | AT-007 |
| BR-004 | UC-004 | SC-008 | AT-008 |
| BR-004 | UC-004 | SC-009 | AT-009 |
| BR-005 | UC-005 | SC-010 | AT-010 |
| BR-005 | UC-005 | SC-011 | AT-011 |
| BR-006 | UC-006 | SC-012 | AT-012 |
| BR-007 | UC-007 | SC-013 | AT-013 |
| BR-007 | UC-007 | SC-014 | AT-014 |
| BR-007 | UC-007 | SC-015 | AT-015 |
| BR-007 | UC-007 | SC-016 | AT-016 |
| BR-008 | UC-008 | SC-017 | AT-017 |
| BR-008 | UC-008 | SC-018 | AT-018 |
| BR-008 | UC-008 | SC-019 | AT-019 |
| BR-009 | UC-009 | SC-020 | AT-020 |

## Pruebas

### AT-001 — Primer resultado seleccionable en `preview_file_finder`
- **Clasificación**: Positiva. **Escenario**: SC-001. **Caso de uso**: UC-001. **Reglas**: BR-001.
- **Precondiciones**: directorio de prueba con `a.txt`, `b.txt`, `c.txt`.
- **Datos requeridos**: patrón que coincida con los 3.
- **Acción**: invocar `find` con el mismo patrón que usa `preview_file_finder` y verificar, sin `--header-lines`,
  que fzf recibe las 3 líneas como seleccionables (fzf `--filter` sobre la salida cruda, o inspección directa del
  comando fzf construido).
- **Resultado esperado**: 3 líneas seleccionables, incluida la de `a.txt`.
- **Evidencia esperada**: salida de `find` sin pérdida de la primera línea al pasar por las opciones de fzf
  usadas.
- **Riesgos cubiertos**: pérdida silenciosa del primer resultado.
- **Prioridad**: Alta. **Automatizable**: Sí (verificando ausencia de `--header-lines` y conteo de líneas
  seleccionables vía `fzf --filter ''`).
- **Observaciones**: ninguna.

### AT-002 — Elemento intermedio sigue seleccionable (regresión)
- **Clasificación**: Regresión. **Escenario**: SC-002. **Caso de uso**: UC-001. **Reglas**: BR-001.
- **Precondiciones/Datos**: igual a AT-001.
- **Acción**: verificar que `b.txt` también es seleccionable tras el fix.
- **Resultado esperado**: comportamiento sin cambios para elementos no-primeros.
- **Evidencia esperada**: `b.txt` presente en la salida filtrable de fzf.
- **Riesgos cubiertos**: regresión al corregir AT-001.
- **Prioridad**: Media. **Automatizable**: Sí.

### AT-003 — Ruta correcta para estado de una palabra
- **Clasificación**: Positiva. **Escenario**: SC-003. **Caso de uso**: UC-002. **Reglas**: BR-002.
- **Precondiciones**: repositorio git de prueba con `src/app.sh` modificado y trackeado.
- **Datos requeridos**: salida real de `git status --untracked-files=no` para ese archivo.
- **Acción**: ejecutar la lógica de extracción de ruta de `git_add_patch_file` sobre esa línea (sin llegar a
  invocar `git add -p` en la prueba, o invocándolo en un repo desechable y verificando el archivo afectado).
- **Resultado esperado**: la ruta extraída es exactamente `src/app.sh`.
- **Evidencia esperada**: comparación de string exacta.
- **Riesgos cubiertos**: ninguno nuevo (caso ya funcionaba, verifica que sigue funcionando).
- **Prioridad**: Alta. **Automatizable**: Sí.

### AT-004 — Ruta correcta para estado "new file:"
- **Clasificación**: Negativa→Positiva (bug fix). **Escenario**: SC-004. **Caso de uso**: UC-002.
  **Reglas**: BR-002.
- **Precondiciones**: repositorio git de prueba con `src/new_module.sh` agregado al índice (nuevo archivo).
- **Datos requeridos**: línea real `        new file:   src/new_module.sh`.
- **Acción**: ejecutar la lógica de extracción sobre esa línea.
- **Resultado esperado**: la ruta extraída es exactamente `src/new_module.sh` (no `file:`).
- **Evidencia esperada**: comparación de string exacta; falla contra el código actual (`awk '{print $2}'`
  produce `file:`).
- **Riesgos cubiertos**: bug confirmado de mayor severidad del lote de git.
- **Prioridad**: Alta. **Automatizable**: Sí.

### AT-005 — Ruta correcta para estado "both modified:"
- **Clasificación**: Caso límite. **Escenario**: SC-005. **Caso de uso**: UC-002. **Reglas**: BR-002.
- **Precondiciones**: repositorio git de prueba con un conflicto de merge sin resolver en `src/conflict.sh`.
- **Datos requeridos**: línea real `        both modified:   src/conflict.sh`.
- **Acción**: ejecutar la lógica de extracción sobre esa línea.
- **Resultado esperado**: la ruta extraída es exactamente `src/conflict.sh`.
- **Evidencia esperada**: comparación de string exacta.
- **Riesgos cubiertos**: otros estados de dos palabras no cubiertos por AT-004.
- **Prioridad**: Media. **Automatizable**: Sí.

### AT-021 — Ruta vigente para estado "renamed:"/"copied:" (no el string con flecha)
- **Clasificación**: Negativa→Positiva (bug fix, detectado en Implementation Review DEV-001).
  **Escenario**: SC-021. **Caso de uso**: UC-002. **Reglas**: BR-002.
- **Precondiciones**: repositorio git desechable con un archivo renombrado (`git mv old.sh new.sh`) y, para
  demostrar el efecto sobre `git add -p`, una modificación adicional no trackeada sobre la ruta nueva.
- **Datos requeridos**: línea real `renamed:    old.sh -> new.sh` (o su equivalente localizado
  `renombrados:     old.sh -> new.sh`, según `LANG`/`LC_MESSAGES` del sistema).
- **Acción**: ejecutar la lógica de extracción sobre esa línea y luego `git add -p <resultado>`.
- **Resultado esperado**: la ruta extraída es exactamente `new.sh`; `git add -p new.sh` despliega el prompt
  interactivo de hunks (`Stage this hunk [y,n,q,a,d,e,p,P,?]?`).
- **Evidencia esperada**: comparación de string exacta de la ruta extraída; salida de `git add -p` mostrando
  `diff --git a/new.sh b/new.sh` en vez de `No changes.`.
- **Riesgos cubiertos**: DEV-001 (regresión confirmada en `09_IMPLEMENTATION_REVIEW.md`): sin este fix, la
  extracción produce `"old.sh -> new.sh"` como pathspec literal, que nunca coincide con un archivo real y hace
  que `git add -p` responda `No changes.` en silencio.
- **Prioridad**: Alta. **Automatizable**: Sí.

### AT-006 — Checkout exitoso con una rama seleccionada
- **Clasificación**: Positiva. **Escenario**: SC-006. **Caso de uso**: UC-003. **Reglas**: BR-003.
- **Precondiciones**: repositorio de prueba con ramas `main`, `feature/x`.
- **Datos requeridos**: ninguno adicional.
- **Acción**: simular la selección de `feature/x` (vía `--filter` o invocación directa de
  `git checkout feature/x`) y verificar `git branch --show-current`.
- **Resultado esperado**: `feature/x`.
- **Evidencia esperada**: salida de `git branch --show-current`.
- **Riesgos cubiertos**: ninguno nuevo.
- **Prioridad**: Alta. **Automatizable**: Sí.

### AT-007 — Selección múltiple ya no está disponible
- **Clasificación**: Negativa→Positiva (bug fix). **Escenario**: SC-007. **Caso de uso**: UC-003.
  **Reglas**: BR-003.
- **Precondiciones**: código fuente de `git_change_branch` corregido.
- **Acción**: inspeccionar la invocación de fzf dentro de `git_change_branch` y confirmar la ausencia del flag
  `-m`.
- **Resultado esperado**: `-m` no presente.
- **Evidencia esperada**: grep del cuerpo de la función.
- **Riesgos cubiertos**: bug de multi-selección incompatible con `git checkout`.
- **Prioridad**: Alta. **Automatizable**: Sí.

### AT-008 — Rama remota no activa se actualiza
- **Clasificación**: Positiva. **Escenario**: SC-008. **Caso de uso**: UC-004. **Reglas**: BR-004.
- **Precondiciones**: repositorio de prueba con remoto local (`git init --bare` en otro directorio), `HEAD` en
  `main`, rama remota `develop` con commits nuevos.
- **Acción**: invocar `git_fetch_all_branch <remoto>`.
- **Resultado esperado**: `develop` local actualizado a `origin/develop` (o el nombre del remoto de prueba).
- **Evidencia esperada**: `git rev-parse develop` coincide con `git rev-parse <remoto>/develop`.
- **Riesgos cubiertos**: ninguno nuevo.
- **Prioridad**: Alta. **Automatizable**: Sí.

### AT-009 — Rama activa omitida y reportada
- **Clasificación**: Negativa→Positiva (bug fix). **Escenario**: SC-009. **Caso de uso**: UC-004.
  **Reglas**: BR-004.
- **Precondiciones**: mismo repositorio de prueba que AT-008, `HEAD` en `main`, remoto con rama `main`.
- **Acción**: invocar `git_fetch_all_branch <remoto>` y capturar stdout/stderr.
- **Resultado esperado**: ningún error de "Cannot force update the current branch"; mensaje explícito indicando
  que `main` fue omitida.
- **Evidencia esperada**: ausencia del error de git en la salida; presencia del mensaje de omisión.
- **Riesgos cubiertos**: falla silenciosa original.
- **Prioridad**: Alta. **Automatizable**: Sí.

### AT-010 — Actividad de remoto configurable
- **Clasificación**: Positiva. **Escenario**: SC-010. **Caso de uso**: UC-005. **Reglas**: BR-005.
- **Precondiciones**: repositorio de prueba con remoto `upstream` con al menos un commit.
- **Acción**: invocar `git_activiy upstream`.
- **Resultado esperado**: salida no vacía referenciando `refs/remotes/upstream`.
- **Evidencia esperada**: salida del comando.
- **Riesgos cubiertos**: ninguno nuevo.
- **Prioridad**: Media. **Automatizable**: Sí.

### AT-011 — Falla explícita sin argumento
- **Clasificación**: Negativa. **Escenario**: SC-011. **Caso de uso**: UC-005. **Reglas**: BR-005.
- **Precondiciones**: cualquier repositorio git.
- **Acción**: invocar `git_activiy` sin argumentos.
- **Resultado esperado**: mensaje de error explícito, código de salida distinto de 0, sin ejecutar
  `git for-each-ref`.
- **Evidencia esperada**: stderr y código de salida.
- **Riesgos cubiertos**: uso accidental sin remoto, hardcode `azure` eliminado.
- **Prioridad**: Alta. **Automatizable**: Sí.

### AT-012 — `finder_edit` eliminada
- **Clasificación**: Regresión/Estructural. **Escenario**: SC-012. **Caso de uso**: UC-006. **Reglas**: BR-006.
- **Precondiciones**: `zsh_functions` corregido.
- **Acción**: `grep -n 'function finder_edit' zsh_functions`.
- **Resultado esperado**: sin coincidencias; `grep -n 'function finder' zsh_functions` sigue encontrando `finder`.
- **Evidencia esperada**: salida de ambos `grep`.
- **Riesgos cubiertos**: eliminación accidental de `finder` junto con `finder_edit`.
- **Prioridad**: Baja. **Automatizable**: Sí.

### AT-013 — Alt-r dispara `search_history`
- **Clasificación**: Positiva. **Escenario**: SC-013. **Caso de uso**: UC-007. **Reglas**: BR-007.
- **Precondiciones**: sesión zsh interactiva con `zsh_functions` cargado.
- **Acción**: `bindkey -M emacs '^[r'` y confirmar el widget asociado (o enviar la secuencia de teclas real en un
  harness de terminal).
- **Resultado esperado**: `search_history`.
- **Evidencia esperada**: salida de `bindkey '^[r'`.
- **Riesgos cubiertos**: binding no aplicado o aplicado a la tecla incorrecta.
- **Prioridad**: Alta. **Automatizable**: Parcial (inspección de `bindkey` sí; disparo real de teclas requiere
  harness de terminal, ej. `tmux send-keys`).

### AT-014 — Alt-f dispara `finder`
- **Clasificación**: Positiva. **Escenario**: SC-014. **Caso de uso**: UC-007. **Reglas**: BR-007.
- **Acción/Evidencia**: análogo a AT-013 con `bindkey '^[f'`.
- **Resultado esperado**: `finder`.
- **Prioridad**: Alta. **Automatizable**: Parcial (igual que AT-013).

### AT-015 — Ctrl-E preserva `end-of-line` nativo
- **Clasificación**: Regresión crítica. **Escenario**: SC-015. **Caso de uso**: UC-007. **Reglas**: BR-007.
- **Precondiciones**: sesión zsh interactiva con `zsh_functions` cargado.
- **Acción**: `bindkey '^E'`.
- **Resultado esperado**: `end-of-line` (el widget nativo, no `search_history`).
- **Evidencia esperada**: salida de `bindkey '^E'`.
- **Riesgos cubiertos**: regresión de edición de línea básica en todo el shell.
- **Prioridad**: Alta. **Automatizable**: Sí (inspección de `bindkey`).

### AT-016 — Ctrl-F preserva `forward-char` nativo
- **Clasificación**: Regresión crítica. **Escenario**: SC-016. **Caso de uso**: UC-007. **Reglas**: BR-007.
- **Acción**: `bindkey '^F'`.
- **Resultado esperado**: `forward-char`.
- **Evidencia esperada**: salida de `bindkey '^F'`.
- **Riesgos cubiertos**: regresión de edición de línea básica en todo el shell.
- **Prioridad**: Alta. **Automatizable**: Sí.

### AT-017 — `cdt` navega correctamente en profundidad 1 (regresión)
- **Clasificación**: Regresión. **Escenario**: SC-017. **Caso de uso**: UC-008. **Reglas**: BR-008.
- **Precondiciones**: directorio de prueba con `src/`.
- **Acción**: ejecutar la lógica corregida de reconstrucción de ruta de `cdt` sobre la línea de `tree`
  correspondiente a `src` y verificar la ruta resultante.
- **Resultado esperado**: `<dir>/src`.
- **Evidencia esperada**: comparación de ruta exacta.
- **Riesgos cubiertos**: regresión del caso que ya funcionaba por coincidencia.
- **Prioridad**: Alta. **Automatizable**: Sí.

### AT-018 — `cdt` navega correctamente en profundidad 2
- **Clasificación**: Negativa→Positiva (bug fix). **Escenario**: SC-018. **Caso de uso**: UC-008.
  **Reglas**: BR-008.
- **Precondiciones**: este mismo repositorio (`.github/workflows/` ya existe en profundidad 2).
- **Acción**: ejecutar la lógica corregida sobre la línea de `tree` correspondiente a `workflows`.
- **Resultado esperado**: `<dir>/.github/workflows`.
- **Evidencia esperada**: comparación de ruta exacta; falla contra el código actual (produce `workflows` suelto).
- **Riesgos cubiertos**: bug confirmado principal del cluster de navegación.
- **Prioridad**: Alta. **Automatizable**: Sí.

### AT-019 — `cdt` resuelve nombre duplicado en profundidad 3
- **Clasificación**: Caso límite. **Escenario**: SC-019. **Caso de uso**: UC-008. **Reglas**: BR-008.
- **Precondiciones**: directorio de prueba con `a/b/tmp/` y `x/y/tmp/`.
- **Acción**: ejecutar la lógica corregida sobre la línea `tmp` anidada bajo `a/b`.
- **Resultado esperado**: `<dir>/a/b/tmp`, nunca `<dir>/x/y/tmp`.
- **Evidencia esperada**: comparación de ruta exacta.
- **Riesgos cubiertos**: resolución incorrecta por nombre en vez de por posición en el árbol.
- **Prioridad**: Alta. **Automatizable**: Sí.

### AT-020 — Cabecera de `cdf` consistente
- **Clasificación**: Positiva. **Escenario**: SC-020. **Caso de uso**: UC-009. **Reglas**: BR-009.
- **Precondiciones**: `zsh_functions` corregido.
- **Acción**: inspeccionar el string `--header` de `cdf`.
- **Resultado esperado**: no contiene "Recent" ni afirma listar directorios recientes.
- **Evidencia esperada**: grep/inspección del literal de cabecera.
- **Riesgos cubiertos**: expectativa incorrecta del usuario sobre la función.
- **Prioridad**: Baja. **Automatizable**: Sí.

## Cobertura

Los 20 escenarios tienen exactamente una prueba de aceptación. Toda regla de negocio, caso límite y excepción
material identificados en `05_BEHAVIOR_SPECIFICATION.md` tienen cobertura. Ningún comportamiento en alcance
queda sin evidencia. Pruebas sin cobertura: ninguna. Pruebas redundantes: ninguna. Preparado para alimentar
`ACCEPTANCE_CRITERIA` del Execution Contract (Etapa 07).
