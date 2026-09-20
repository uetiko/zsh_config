SOURCE: backend/docs/spec_methodology/05_BEHAVIOR_SPECIFICATION.md
ADAPTATION: OMP Specification Skill v0.1

# 05 — Behavior Specification: corrección de funciones fzf en `zsh_functions`

## Resumen ejecutivo

21 escenarios de comportamiento observable (Specification by Example) que cubren los 9 casos de uso de
`04_USE_CASE_DEFINITION.md`. SC-021 se agregó tras `09_IMPLEMENTATION_REVIEW.md` (DEV-002) para cerrar un gap de
cobertura de BR-002 detectado en revisión. Cada escenario es independiente y verificable sin depender del
estado producido por otro.

## Matriz de cobertura

| Hard Spec | Caso de uso | Escenarios |
|---|---|---|
| BR-001 | UC-001 | SC-001, SC-002 |
| BR-002 | UC-002 | SC-003, SC-004, SC-005, SC-021 |
| BR-003 | UC-003 | SC-006, SC-007 |
| BR-004 | UC-004 | SC-008, SC-009 |
| BR-005 | UC-005 | SC-010, SC-011 |
| BR-006 | UC-006 | SC-012 |
| BR-007 | UC-007 | SC-013, SC-014, SC-015, SC-016 |
| BR-008 | UC-008 | SC-017, SC-018, SC-019 |
| BR-009 | UC-009 | SC-020 |

## Feature: Visor de archivos

### SC-001 — El primer archivo encontrado es seleccionable
**Derivado de**: UC-001, BR-001, CF-01.
**Objetivo**: demostrar que `--header-lines=1` ya no descarta el primer resultado.
- Given un directorio con 3 archivos que coinciden con el patrón de búsqueda, ordenados por `find` como
  `a.txt`, `b.txt`, `c.txt`
- When el usuario invoca `preview_file_finder` con ese patrón y selecciona en fzf la línea correspondiente a
  `a.txt` (el primer resultado)
- Then el visor configurado abre `a.txt`
- **Estados involucrados**: ninguno. **Casos límite cubiertos**: primer elemento de la lista.
  **Reglas cubiertas**: BR-001. **Restricciones**: ninguna. **Criterios de aceptación asociados**: AT-001.
  **Escenarios relacionados**: SC-002.

### SC-002 — Un archivo intermedio sigue siendo seleccionable (regresión)
**Derivado de**: UC-001, BR-001, CF-01.
- Given la misma lista de 3 archivos (`a.txt`, `b.txt`, `c.txt`)
- When el usuario selecciona `b.txt`
- Then el visor configurado abre `b.txt`
- **Casos límite cubiertos**: elemento no-primero (regresión del comportamiento ya correcto).
  **Reglas cubiertas**: BR-001. **Criterios de aceptación asociados**: AT-002. **Relacionados**: SC-001.

## Feature: Git — patch por archivo

### SC-003 — Estado de una palabra extrae la ruta correcta
**Derivado de**: UC-002, BR-002, CF-02.
- Given `git status --untracked-files=no` muestra la línea `        modified:   src/app.sh`
- When el usuario selecciona esa línea en `git_add_patch_file`
- Then el sistema ejecuta `git add -p src/app.sh`
- **Reglas cubiertas**: BR-002. **Criterios**: AT-003. **Relacionados**: SC-004, SC-005.

### SC-004 — Estado de dos palabras ("new file:") extrae la ruta correcta
**Derivado de**: UC-002, BR-002, CF-02.
- Given `git status --untracked-files=no` muestra la línea `        new file:   src/new_module.sh`
- When el usuario selecciona esa línea en `git_add_patch_file`
- Then el sistema ejecuta `git add -p src/new_module.sh` (no `git add -p file:`)
- **Casos límite cubiertos**: estado de dos palabras. **Reglas cubiertas**: BR-002. **Criterios**: AT-004.
  **Relacionados**: SC-003, SC-005.

### SC-005 — Estado de conflicto de dos palabras ("both modified:") extrae la ruta correcta
**Derivado de**: UC-002, BR-002, CF-02.
- Given `git status --untracked-files=no` muestra la línea `        both modified:   src/conflict.sh`
- When el usuario selecciona esa línea en `git_add_patch_file`
- Then el sistema ejecuta `git add -p src/conflict.sh`
- **Casos límite cubiertos**: estado de conflicto de dos palabras. **Reglas cubiertas**: BR-002.
  **Criterios**: AT-005. **Relacionados**: SC-003, SC-004, SC-021.

### SC-021 — Estado "renamed:"/"copied:" extrae la ruta vigente, no el string con flecha
**Derivado de**: UC-002, BR-002, CF-02.
- Given `git status --untracked-files=no` muestra la línea `        renamed:    old.sh -> new.sh` (o su
  equivalente localizado `renombrados:     old.sh -> new.sh`)
- When el usuario selecciona esa línea en `git_add_patch_file`
- Then el sistema ejecuta `git add -p new.sh` (la ruta vigente tras el renombre), nunca
  `git add -p "old.sh -> new.sh"` como pathspec literal
- **Casos límite cubiertos**: estado cuyo valor contiene ` -> ` (`renamed:`, `copied:`). **Reglas cubiertas**:
  BR-002. **Criterios**: AT-021. **Relacionados**: SC-003, SC-004, SC-005.

## Feature: Git — cambio de rama

### SC-006 — Selección única hace checkout exitoso
**Derivado de**: UC-003, BR-003, CF-03.
- Given un repositorio con ramas locales `main` y `feature/x`
- When el usuario selecciona únicamente `feature/x` en `git_change_branch`
- Then el sistema ejecuta `git checkout feature/x` y `HEAD` queda en `feature/x`
- **Reglas cubiertas**: BR-003. **Criterios**: AT-006. **Relacionados**: SC-007.

### SC-007 — fzf no permite confirmar más de una rama
**Derivado de**: UC-003, BR-003, CF-03.
- Given un repositorio con ramas locales `main` y `feature/x`
- When el usuario intenta marcar más de una línea antes de confirmar en `git_change_branch`
- Then fzf no ofrece un mecanismo de multi-marcado (no está el flag `-m`) y sólo una línea puede confirmarse
  por invocación
- **Casos límite cubiertos**: intento de selección múltiple. **Reglas cubiertas**: BR-003. **Criterios**: AT-007.
  **Relacionados**: SC-006.

## Feature: Git — sincronización de ramas remotas

### SC-008 — Ramas remotas distintas a la activa se actualizan
**Derivado de**: UC-004, BR-004, CF-04.
- Given un repositorio con `HEAD` en `main` y remoto `origin` con ramas `main` y `develop`
- When el usuario invoca `git_fetch_all_branch origin`
- Then la rama local `develop` queda actualizada por `git branch --track --force develop origin/develop`
- **Reglas cubiertas**: BR-004. **Criterios**: AT-008. **Relacionados**: SC-009.

### SC-009 — La rama activa se omite y se reporta, no falla en silencio
**Derivado de**: UC-004, BR-004, CF-04.
- Given un repositorio con `HEAD` en `main` y remoto `origin` con rama `main`
- When el usuario invoca `git_fetch_all_branch origin`
- Then el sistema no ejecuta `git branch --force main origin/main` y muestra un mensaje explícito indicando que
  `main` fue omitida por ser la rama activa
- **Casos límite cubiertos**: la rama activa es procesada por el bucle. **Reglas cubiertas**: BR-004.
  **Criterios**: AT-009. **Relacionados**: SC-008.

## Feature: Git — actividad de remoto

### SC-010 — Remoto pasado por argumento se usa para listar actividad
**Derivado de**: UC-005, BR-005, CF-05.
- Given un repositorio con remoto `upstream` con historial de commits
- When el usuario invoca `git_activiy upstream`
- Then el sistema lista hasta 20 refs de `refs/remotes/upstream`
- **Reglas cubiertas**: BR-005. **Criterios**: AT-010. **Relacionados**: SC-011.

### SC-011 — Argumento ausente produce error explícito
**Derivado de**: UC-005, BR-005, CF-05.
- Given cualquier repositorio git
- When el usuario invoca `git_activiy` sin argumentos
- Then el sistema no ejecuta `git for-each-ref` y muestra un mensaje de error indicando que falta el nombre del
  remoto
- **Casos límite cubiertos**: argumento ausente. **Reglas cubiertas**: BR-005. **Criterios**: AT-011.
  **Relacionados**: SC-010.

## Feature: Mantenimiento del código fuente

### SC-012 — `finder_edit` ya no existe
**Derivado de**: UC-006, BR-006, CF-06.
- Given el archivo `zsh_functions` corregido
- When se busca la declaración `function finder_edit`
- Then no se encuentra ninguna coincidencia, y `finder` sigue declarado y sin cambios de comportamiento
- **Reglas cubiertas**: BR-006. **Criterios**: AT-012. **Relacionados**: ninguno.

## Feature: Bindings de historial y archivos

### SC-013 — Alt-r dispara `search_history`
**Derivado de**: UC-007, BR-007, CF-07.
- Given una sesión zsh interactiva con `zsh_functions` cargado
- When el usuario presiona `Alt-r`
- Then se dispara el widget `search_history`
- **Reglas cubiertas**: BR-007. **Criterios**: AT-013. **Relacionados**: SC-014, SC-015, SC-016.

### SC-014 — Alt-f dispara `finder`
**Derivado de**: UC-007, BR-007, CF-07.
- Given una sesión zsh interactiva con `zsh_functions` cargado
- When el usuario presiona `Alt-f`
- Then se dispara el widget `finder`
- **Reglas cubiertas**: BR-007. **Criterios**: AT-014. **Relacionados**: SC-013, SC-015, SC-016.

### SC-015 — Ctrl-E ejecuta `end-of-line` nativo
**Derivado de**: UC-007, BR-007, CF-07.
- Given una sesión zsh interactiva con `zsh_functions` cargado y el cursor a mitad de una línea con texto
- When el usuario presiona `Ctrl-E`
- Then el cursor se mueve al final de la línea (widget nativo `end-of-line`), y no se dispara `search_history`
- **Reglas cubiertas**: BR-007. **Criterios**: AT-015. **Relacionados**: SC-013, SC-014, SC-016.

### SC-016 — Ctrl-F ejecuta `forward-char` nativo
**Derivado de**: UC-007, BR-007, CF-07.
- Given una sesión zsh interactiva con `zsh_functions` cargado y el cursor al inicio de una línea con texto
- When el usuario presiona `Ctrl-F`
- Then el cursor avanza un carácter (widget nativo `forward-char`), y no se dispara `finder`
- **Reglas cubiertas**: BR-007. **Criterios**: AT-016. **Relacionados**: SC-013, SC-014, SC-015.

## Feature: Navegación de directorios — árbol

### SC-017 — Selección en profundidad 1 navega correctamente (regresión)
**Derivado de**: UC-008, BR-008, CF-08.
- Given un cwd con subdirectorio directo `src/`
- When el usuario invoca `cdt` y selecciona la línea correspondiente a `src`
- Then el cwd resultante es `<directorio original>/src`
- **Reglas cubiertas**: BR-008. **Criterios**: AT-017. **Relacionados**: SC-018, SC-019.

### SC-018 — Selección en profundidad 2 navega al directorio correcto
**Derivado de**: UC-008, BR-008, CF-08.
- Given un cwd con la estructura `.github/workflows/`
- When el usuario invoca `cdt` y selecciona la línea correspondiente a `workflows` (anidada bajo `.github`)
- Then el cwd resultante es `<directorio original>/.github/workflows`, no un intento fallido de `cd workflows`
  desde el directorio original
- **Casos límite cubiertos**: profundidad 2. **Reglas cubiertas**: BR-008. **Criterios**: AT-018.
  **Relacionados**: SC-017, SC-019.

### SC-019 — Selección en profundidad 3 con nombre duplicado navega al directorio correcto
**Derivado de**: UC-008, BR-008, CF-08.
- Given un cwd con dos subárboles distintos que contienen un directorio con el mismo nombre en profundidad 3
  (p. ej. `a/b/tmp/` y `x/y/tmp/`)
- When el usuario selecciona la línea `tmp` anidada bajo `a/b`
- Then el cwd resultante es `<directorio original>/a/b/tmp`, no `<directorio original>/x/y/tmp`
- **Casos límite cubiertos**: profundidad 3, nombre duplicado entre ramas. **Reglas cubiertas**: BR-008.
  **Criterios**: AT-019. **Relacionados**: SC-017, SC-018.

## Feature: Navegación de directorios — subdirectorios del cwd

### SC-020 — Cabecera de `cdf` describe exactamente lo que lista
**Derivado de**: UC-009, BR-009, CF-09.
- Given un cwd con subdirectorios `a/` y `b/`
- When el usuario invoca `cdf`
- Then la cabecera mostrada en fzf describe la lista de `..` + subdirectorios inmediatos del cwd, sin mencionar
  directorios "recientes" u otro comportamiento no implementado
- **Reglas cubiertas**: BR-009. **Criterios**: AT-020. **Relacionados**: ninguno.

## Cobertura

Todo actor y objetivo (Usuario del shell, por cada UC) tiene al menos un escenario de ruta exitosa. Toda
interacción, excepción y caso límite identificado en `04_USE_CASE_DEFINITION.md` tiene escenario. Toda regla de
negocio (BR-001..BR-009) está cubierta por al menos un escenario. Sin escenarios duplicados. Preparado para
Etapa 08 (Acceptance Test Specification).
