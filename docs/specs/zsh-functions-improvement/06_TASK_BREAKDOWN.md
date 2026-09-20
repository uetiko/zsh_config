SOURCE: backend/docs/spec_methodology/06_TASK_BREAKDOWN.md
ADAPTATION: OMP Specification Skill v0.1

# 06 — Task Breakdown: corrección de funciones fzf en `zsh_functions`

## Resumen ejecutivo

9 tareas, todas pequeñas, independientes entre sí a nivel de comportamiento, agrupadas en 2 fases que reflejan la
priorización ya cerrada en el análisis de proyecto (Fase 1 = bugs puros sin decisión pendiente; Fase 2 = cambios
de diseño ya decididos). Todas operan sobre el mismo archivo `zsh_functions`, en rangos de líneas disjuntos.

## Estrategia de implementación

Cambios quirúrgicos por función, sin refactor estructural del archivo. Cada tarea se valida con un smoke test
manual (reproducir el comportamiento previo, aplicar el cambio, confirmar el comportamiento esperado) — no se
introduce infraestructura de testing automatizado nueva; se documentan los pasos de verificación manual
derivados de `08_ACCEPTANCE_TEST_SPECIFICATION.md`. Todas las tareas pueden ejecutarse en el orden que se
prefiera; se agrupan por fase únicamente por la procedencia de la decisión que las autoriza, no por dependencia
técnica real.

## Grafo de dependencias

Ninguna tarea depende de otra a nivel de comportamiento. Todas comparten el mismo archivo fuente
(`zsh_functions`), por lo que la única coordinación necesaria es mecánica (aplicar los cambios sin pisar líneas
de otra tarea en la misma pasada de edición) — no es una dependencia de planificación.

```
FASE 1 (bugs puros)              FASE 2 (decisiones ya cerradas)
TASK-001 preview_file_finder     TASK-007 rebind Alt-r/Alt-f
TASK-002 git_add_patch_file      TASK-008 fix cdt
TASK-003 git_change_branch       TASK-009 fix header cdf
TASK-004 git_fetch_all_branch
TASK-005 git_activiy
TASK-006 eliminar finder_edit
```
Ambas fases son paralelizables entre sí; dentro de cada fase, todas las tareas son paralelizables entre sí.

## Fases

### Fase 1 — Bugfixes puros
- **Objetivo**: corregir BR-001..BR-006, sin decisiones de diseño pendientes.
- **Dependencias**: ninguna.
- **Entregables**: `zsh_functions` con TASK-001..TASK-006 aplicadas.

### Fase 2 — Cambios de diseño ya decididos
- **Objetivo**: corregir BR-007..BR-009, aplicando las 3 decisiones humanas ya cerradas.
- **Dependencias**: ninguna técnica (paralelizable con Fase 1); depende de las decisiones ya cerradas
  (`keybindings`=Alt-r/Alt-f, `nav_scope`=fix mínimo) documentadas en `07_EXECUTION_CONTRACT.md` §`AUTHORIZED_DECISIONS`.
- **Entregables**: `zsh_functions` con TASK-007..TASK-009 aplicadas.

## Tareas

### TASK-001 — Corregir `preview_file_finder`
- **Objetivo**: que el primer resultado de `find` sea seleccionable.
- **Descripción**: quitar `--header-lines=1` de la invocación de fzf en `preview_file_finder`.
- **Alcance**: línea de opciones de fzf dentro de `preview_file_finder`. **Fuera de alcance**: preview con `cat`
  vs `bat` (no forma parte de ningún BR de este contrato).
- **Artefactos de entrada**: `zsh_functions` (función `preview_file_finder`). **Salida**: misma función corregida.
- **Casos de uso relacionados**: UC-001. **Escenarios relacionados**: SC-001, SC-002. **Reglas**: BR-001.
- **Dependencias**: ninguna. **Paralelizable**: Sí.
- **Riesgos**: ninguno material.
- **Validación esperada**: reproducir SC-001 y SC-002 manualmente.
- **Definición de terminado**: `--header-lines` ya no aparece en `preview_file_finder`; SC-001 y SC-002 pasan.
- **Preparada para ejecución**: Sí.

### TASK-002 — Corregir `git_add_patch_file`
- **Objetivo**: extraer la ruta correcta para estados de una y dos palabras.
- **Descripción**: reemplazar el parsing por `awk '{print $2}'` sobre `git status` humano por una extracción que
  tome todo lo posterior a los dos-puntos del estado (por ejemplo, cortar por el primer `:` y recortar
  espacios), o migrar a `git status --porcelain` con parsing por posición fija de columna. Preservar el filtro
  `--untracked-files=no` ya existente.
- **Alcance**: lógica de extracción de ruta en `git_add_patch_file`. **Fuera de alcance**: manejo de nombres de
  archivo con caracteres especiales fuera de los ya cubiertos por los escenarios (SC-003..SC-005).
- **Artefactos de entrada/salida**: `zsh_functions` (función `git_add_patch_file`).
- **Casos de uso relacionados**: UC-002. **Escenarios relacionados**: SC-003, SC-004, SC-005. **Reglas**: BR-002.
- **Dependencias**: ninguna. **Paralelizable**: Sí.
- **Riesgos**: elegir una extracción que rompa con rutas que contienen `:` (poco común, no cubierto por los
  escenarios actuales — reportar si se detecta durante implementación, no resolver en silencio).
- **Validación esperada**: reproducir SC-003, SC-004, SC-005 manualmente con un repositorio de prueba.
- **Definición de terminado**: los 3 escenarios pasan.
- **Preparada para ejecución**: Sí.

### TASK-003 — Corregir `git_change_branch`
- **Objetivo**: que la función opere sobre una única rama por invocación.
- **Descripción**: quitar el flag `-m` de la invocación de fzf en `git_change_branch`.
- **Alcance**: opciones de fzf dentro de `git_change_branch`. **Fuera de alcance**: cambiar el formato de listado
  de ramas.
- **Artefactos de entrada/salida**: `zsh_functions` (función `git_change_branch`).
- **Casos de uso relacionados**: UC-003. **Escenarios relacionados**: SC-006, SC-007. **Reglas**: BR-003.
- **Dependencias**: ninguna. **Paralelizable**: Sí.
- **Riesgos**: ninguno material.
- **Validación esperada**: reproducir SC-006 y SC-007 manualmente.
- **Definición de terminado**: `-m` ya no aparece; ambos escenarios pasan.
- **Preparada para ejecución**: Sí.

### TASK-004 — Corregir `git_fetch_all_branch`
- **Objetivo**: omitir la rama activa del bucle de `branch --force` y reportarlo.
- **Descripción**: obtener la rama activa (`git symbolic-ref --short HEAD` o equivalente) antes del bucle;
  dentro del bucle, si `"${branch##*/}"` coincide con la rama activa, omitir el `git branch --track --force` y
  emitir un mensaje explícito de omisión.
- **Alcance**: cuerpo del bucle `for branch in ...` dentro de `git_fetch_all_branch`. **Fuera de alcance**: lógica
  de stash ya existente (se preserva sin cambios).
- **Artefactos de entrada/salida**: `zsh_functions` (función `git_fetch_all_branch`).
- **Casos de uso relacionados**: UC-004. **Escenarios relacionados**: SC-008, SC-009. **Reglas**: BR-004.
- **Dependencias**: ninguna. **Paralelizable**: Sí.
- **Riesgos**: ninguno material.
- **Validación esperada**: reproducir SC-008 y SC-009 en un repositorio de prueba con un remoto local.
- **Definición de terminado**: ambos escenarios pasan; el stash/pop existente sigue funcionando igual.
- **Preparada para ejecución**: Sí.

### TASK-005 — Corregir `git_activiy`
- **Objetivo**: que el remoto sea un argumento obligatorio, sin valor hardcodeado.
- **Descripción**: reemplazar el literal `azure` por `"$1"`; agregar una validación temprana que falle con
  mensaje explícito si `$1` está ausente o vacío, antes de ejecutar `git for-each-ref`.
- **Alcance**: cuerpo de `git_activiy`. **Fuera de alcance**: corregir el typo del nombre de la función (no
  forma parte de ningún BR de este contrato; se reporta como hallazgo, no se corrige aquí).
- **Artefactos de entrada/salida**: `zsh_functions` (función `git_activiy`).
- **Casos de uso relacionados**: UC-005. **Escenarios relacionados**: SC-010, SC-011. **Reglas**: BR-005.
- **Dependencias**: ninguna. **Paralelizable**: Sí.
- **Riesgos**: ninguno material.
- **Validación esperada**: reproducir SC-010 y SC-011 manualmente.
- **Definición de terminado**: ambos escenarios pasan.
- **Preparada para ejecución**: Sí.

### TASK-006 — Eliminar `finder_edit`
- **Objetivo**: quitar código muerto duplicado.
- **Descripción**: eliminar la declaración completa de la función `finder_edit`.
- **Alcance**: declaración de `finder_edit`. **Fuera de alcance**: `finder` (se preserva intacta).
- **Artefactos de entrada/salida**: `zsh_functions`.
- **Casos de uso relacionados**: UC-006. **Escenarios relacionados**: SC-012. **Reglas**: BR-006.
- **Dependencias**: ninguna. **Paralelizable**: Sí.
- **Riesgos**: ninguno (sin referencias externas confirmadas en el discovery previo).
- **Validación esperada**: `grep` de `finder_edit` sin resultados; `finder` sigue funcionando igual.
- **Definición de terminado**: SC-012 pasa.
- **Preparada para ejecución**: Sí.

### TASK-007 — Rebind de `search_history` y `finder`
- **Objetivo**: mover los widgets a `Alt-r`/`Alt-f` y liberar `^e`/`^f`.
- **Descripción**: cambiar `bindkey '^f' search_history'` → `bindkey '^[r' search_history` y
  `bindkey '^e' finder` → `bindkey '^[f' finder` (`^[` = secuencia de escape de `Alt` en zsh).
- **Alcance**: las dos líneas de `bindkey` al final del archivo. **Fuera de alcance**: lógica interna de
  `search_history`/`finder`.
- **Artefactos de entrada/salida**: `zsh_functions`.
- **Casos de uso relacionados**: UC-007. **Escenarios relacionados**: SC-013, SC-014, SC-015, SC-016.
  **Reglas**: BR-007.
- **Dependencias**: ninguna. **Paralelizable**: Sí.
- **Riesgos**: verificar que `Alt-r`/`Alt-f` no colisionen con otro binding ya presente en el archivo o en
  oh-my-zsh/plugins activos (`plugins=(git wakatime)`) antes de aplicar — si existe colisión, reportar como
  hallazgo antes de continuar, no sobreescribir en silencio.
- **Validación esperada**: reproducir SC-013..SC-016 en una sesión zsh interactiva real.
- **Definición de terminado**: los 4 escenarios pasan.
- **Preparada para ejecución**: Sí, condicionado a la verificación de colisión del riesgo anterior durante la
  propia ejecución.

### TASK-008 — Corregir reconstrucción de ruta en `cdt`
- **Objetivo**: que la selección en cualquier profundidad navegue al directorio exacto.
- **Descripción**: reemplazar el parsing por `sed 's/.*─ //'` (que sólo captura el nombre hoja) por una lógica
  que reconstruya la ruta completa acumulando el nombre de cada nivel según su indentación en la salida de
  `tree`, o sustituir la fuente de datos por una que ya produzca rutas completas (p. ej. `fd -t d -d 3` con
  rutas relativas, manteniendo el preview y estilo ya existentes en `cdt`).
- **Alcance**: bloque `if command -v tree` dentro de `cdt`. **Fuera de alcance**: las ramas `fd`/`find` del mismo
  `if/elif/else` (ya producen rutas completas, no tienen el defecto de BR-008).
- **Artefactos de entrada/salida**: `zsh_functions` (función `cdt`).
- **Casos de uso relacionados**: UC-008. **Escenarios relacionados**: SC-017, SC-018, SC-019. **Reglas**: BR-008.
- **Dependencias**: ninguna. **Paralelizable**: Sí.
- **Riesgos**: es la tarea de mayor complejidad relativa del lote (única que requiere lógica nueva, no sólo
  eliminar/mover una opción existente) — validar los 3 escenarios de profundidad antes de dar por terminada.
- **Validación esperada**: reproducir SC-017, SC-018, SC-019 sobre este mismo repositorio (que ya tiene
  `.github/workflows/` en profundidad 2, útil como caso real).
- **Definición de terminado**: los 3 escenarios pasan, incluida la profundidad 3 con nombre duplicado.
- **Preparada para ejecución**: Sí.

### TASK-009 — Corregir cabecera de `cdf`
- **Objetivo**: que el texto de `cdf` sea consistente con lo que lista.
- **Descripción**: ajustar el `--header` de `cdf` para describir exactamente "subdirectorios del directorio
  actual", quitando la mención a "Recent" directories que no se implementa en este contrato. El comentario
  interno sobre `z`/`fasd` (líneas 205-206) se preserva o se elimina según decida quien ejecute, siempre que el
  texto visible al usuario dejе de prometer comportamiento inexistente.
- **Alcance**: línea `--header=...` de `cdf`. **Fuera de alcance**: implementar historial de directorios
  recientes (explícitamente fuera de alcance por decisión humana `nav_scope`).
- **Artefactos de entrada/salida**: `zsh_functions` (función `cdf`).
- **Casos de uso relacionados**: UC-009. **Escenarios relacionados**: SC-020. **Reglas**: BR-009.
- **Dependencias**: ninguna. **Paralelizable**: Sí.
- **Riesgos**: ninguno material.
- **Validación esperada**: reproducir SC-020 manualmente (inspección del texto mostrado).
- **Definición de terminado**: SC-020 pasa.
- **Preparada para ejecución**: Sí.

## Cobertura

Los 20 escenarios de `05_BEHAVIOR_SPECIFICATION.md` en alcance pertenecen a al menos una tarea. Los 9 casos de
uso de `04_USE_CASE_DEFINITION.md` están cubiertos. Las 9 reglas de negocio de `03_HARD_SPECIFICATION.md` en
alcance tienen trabajo asociado. Ninguna tarea introduce comportamiento ausente en la especificación. Sin gaps
de cobertura detectados.

## Cierre

9 tareas, 2 fases, sin ruta crítica real (todas paralelizables entre sí; la única coordinación es evitar pisar
líneas del mismo archivo en la misma pasada de edición). Riesgo principal: TASK-008 (complejidad relativa) y
TASK-007 (verificar ausencia de colisión de los nuevos bindings antes de aplicar). Preparadas para convertirse en
Execution Contract (Etapa 07).
