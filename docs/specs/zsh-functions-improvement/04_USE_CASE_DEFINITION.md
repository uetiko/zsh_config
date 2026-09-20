SOURCE: backend/docs/spec_methodology/04_USE_CASE_DEFINITION.md
ADAPTATION: OMP Specification Skill v0.1

# 04 — Use Case Definition: corrección de funciones fzf en `zsh_functions`

## Resumen ejecutivo

9 casos de uso, un actor único (Usuario del shell), cada uno modelando la interacción con una de las 9
capacidades funcionales de `03_HARD_SPECIFICATION.md`. Sin comportamiento nuevo respecto a la Hard Specification.

## Matriz de cobertura

| Capacidad funcional | Caso de uso |
|---|---|
| CF-01 | UC-001 |
| CF-02 | UC-002 |
| CF-03 | UC-003 |
| CF-04 | UC-004 |
| CF-05 | UC-005 |
| CF-06 | UC-006 |
| CF-07 | UC-007 |
| CF-08 | UC-008 |
| CF-09 | UC-009 |

## UC-001 — Previsualizar y abrir el primer archivo encontrado

- **Objetivo**: el usuario quiere abrir cualquier archivo encontrado por `find`, incluido el primero de la lista.
- **Interacción**: usuario invoca `preview_file_finder <patrón>` → sistema lista y previsualiza candidatos → usuario selecciona uno (incluido el primero) → sistema lo abre.
- **Capacidades funcionales**: CF-01.
- **Actor principal**: Usuario del shell. **Actores secundarios**: ninguno.
- **Evento disparador**: invocación de `preview_file_finder` con argumentos de patrón.
- **Precondiciones**: existe al menos un archivo que coincide con el patrón.
- **Flujo principal**: 1) usuario ejecuta la función; 2) `find` produce N candidatos; 3) fzf los presenta todos como seleccionables, incluido el primero; 4) usuario selecciona uno; 5) el visor configurado lo abre.
- **Flujos alternativos**: cancelación en fzf → ninguna acción.
- **Excepciones**: cero candidatos → fzf no presenta selección, no se abre nada.
- **Postcondiciones**: el archivo seleccionado queda abierto en el visor configurado.
- **Estados involucrados**: ninguno persistente.
- **Reglas de negocio aplicables**: BR-001.
- **Restricciones aplicables**: ninguna nueva.
- **Criterios de aceptación**: el primer archivo de la lista es seleccionable y abre correctamente.
- **Casos límite relevantes**: exactamente un candidato (el primero y único).
- **Dependencias funcionales**: ninguna.
- **Derivado de**: Hard Specification BR-001, CF-01.
- **Utilizado posteriormente por**: SC-001, SC-002 (Etapa 05); AT-001, AT-002 (Etapa 08).

## UC-002 — Agregar por patch el archivo correcto

- **Objetivo**: el usuario quiere ejecutar `git add -p` sobre el archivo que seleccionó en la lista de `git status`, sin importar el tipo de estado.
- **Interacción**: usuario invoca `git_add_patch_file` → sistema lista archivos con cambios (excluye no-trackeados) → usuario selecciona una línea → sistema ejecuta `git add -p` sobre la ruta correcta extraída de esa línea.
- **Capacidades funcionales**: CF-02.
- **Actor principal**: Usuario del shell. **Secundarios**: `git` (repositorio local).
- **Evento disparador**: invocación de `git_add_patch_file` con cambios pendientes en el working tree.
- **Precondiciones**: repositorio git válido con al menos un archivo modificado/nuevo/renombrado.
- **Flujo principal**: 1) `git status` humano lista archivos con su estado; 2) fzf presenta las líneas; 3) usuario selecciona una; 4) el sistema extrae la ruta (no el estado) de la línea seleccionada; 5) ejecuta `git add -p <ruta>`.
- **Flujos alternativos**: cancelación en fzf → no se ejecuta `git add -p`.
- **Excepciones**: ninguna línea seleccionable (sin cambios) → no hay acción.
- **Postcondiciones**: `git add -p` se invocó sobre la ruta exacta del archivo seleccionado.
- **Estados involucrados**: estado de índice/working tree del archivo seleccionado.
- **Reglas de negocio aplicables**: BR-002.
- **Restricciones aplicables**: ninguna nueva.
- **Criterios de aceptación**: la ruta extraída coincide con el archivo mostrado, para estados de una y dos palabras.
- **Casos límite relevantes**: estado "new file:", estado "both modified:".
- **Dependencias funcionales**: ninguna.
- **Derivado de**: Hard Specification BR-002, CF-02.
- **Utilizado posteriormente por**: SC-003, SC-004, SC-005; AT-003, AT-004, AT-005.

## UC-003 — Cambiar a una única rama seleccionada

- **Objetivo**: el usuario quiere hacer checkout de una rama local elegida por fzf.
- **Interacción**: usuario invoca `git_change_branch` → sistema lista ramas locales → usuario selecciona una → sistema hace checkout de esa rama.
- **Capacidades funcionales**: CF-03.
- **Actor principal**: Usuario del shell. **Secundarios**: `git`.
- **Evento disparador**: invocación de `git_change_branch`.
- **Precondiciones**: al menos una rama local existe.
- **Flujo principal**: 1) `git for-each-ref` lista ramas locales; 2) fzf presenta selección única; 3) usuario selecciona una; 4) `git checkout` recibe exactamente esa rama.
- **Flujos alternativos**: cancelación en fzf → sin checkout.
- **Excepciones**: ninguna rama disponible → no hay selección posible.
- **Postcondiciones**: `HEAD` apunta a la rama seleccionada.
- **Estados involucrados**: rama activa antes/después.
- **Reglas de negocio aplicables**: BR-003.
- **Restricciones aplicables**: fzf no debe habilitar selección múltiple para este flujo.
- **Criterios de aceptación**: `git checkout` recibe un único argumento de rama.
- **Casos límite relevantes**: exactamente una rama local existente.
- **Dependencias funcionales**: ninguna.
- **Derivado de**: Hard Specification BR-003, CF-03.
- **Utilizado posteriormente por**: SC-006, SC-007; AT-006, AT-007.

## UC-004 — Sincronizar ramas remotas sin afectar la rama activa

- **Objetivo**: el usuario quiere actualizar los trackers locales de todas las ramas de un remoto, sin que la operación falle silenciosamente sobre la rama que tiene activa.
- **Interacción**: usuario invoca `git_fetch_all_branch <remoto>` → sistema actualiza el remoto → sistema recorre las ramas remotas omitiendo la activa → reporta la omisión.
- **Capacidades funcionales**: CF-04.
- **Actor principal**: Usuario del shell. **Secundarios**: `git`, remoto configurado.
- **Evento disparador**: invocación de `git_fetch_all_branch` con nombre de remoto.
- **Precondiciones**: el remoto indicado existe y es alcanzable.
- **Flujo principal**: 1) guarda cambios locales si hay working tree sucio (ya implementado); 2) `git remote update`; 3) para cada rama remota distinta de la rama activa, `git branch --track --force`; 4) para la rama activa, se omite y se reporta; 5) restaura el stash si aplicó.
- **Flujos alternativos**: ninguna rama coincide con la activa → el bucle procesa todas normalmente.
- **Excepciones**: la rama activa es la única rama remota → el bucle se omite completo, se reporta.
- **Postcondiciones**: todas las ramas remotas salvo la activa quedan actualizadas; la rama activa no sufre un intento fallido silencioso.
- **Estados involucrados**: rama activa (`HEAD`).
- **Reglas de negocio aplicables**: BR-004.
- **Restricciones aplicables**: no se fuerza la rama activa.
- **Criterios de aceptación**: ningún `git branch --force` se ejecuta sobre la rama activa; se reporta cuál se omitió.
- **Casos límite relevantes**: la rama activa es la única rama rastreada del remoto.
- **Dependencias funcionales**: ninguna.
- **Derivado de**: Hard Specification BR-004, CF-04.
- **Utilizado posteriormente por**: SC-008, SC-009; AT-008, AT-009.

## UC-005 — Ver actividad de un remoto configurable

- **Objetivo**: el usuario quiere ver la actividad reciente de cualquier remoto del repositorio, no sólo uno fijo.
- **Interacción**: usuario invoca `git_activiy <remoto>` → sistema lista los últimos 20 refs de ese remoto ordenados por fecha de commit.
- **Capacidades funcionales**: CF-05.
- **Actor principal**: Usuario del shell. **Secundarios**: `git`.
- **Evento disparador**: invocación de `git_activiy` con nombre de remoto.
- **Precondiciones**: ninguna (el caso sin argumento es una excepción, no una precondición de éxito).
- **Flujo principal**: 1) usuario provee `$1`; 2) sistema ejecuta `git for-each-ref` sobre `refs/remotes/$1`; 3) muestra hasta 20 entradas.
- **Flujos alternativos**: ninguno.
- **Excepciones**: `$1` ausente o vacío → error explícito, sin ejecutar `git for-each-ref`.
- **Postcondiciones**: ninguna (operación de sólo lectura).
- **Estados involucrados**: ninguno.
- **Reglas de negocio aplicables**: BR-005.
- **Restricciones aplicables**: sin remoto por defecto.
- **Criterios de aceptación**: sin argumento, la función falla antes de ejecutar git; con argumento, usa exactamente ese remoto.
- **Casos límite relevantes**: argumento vacío (`""`).
- **Dependencias funcionales**: ninguna.
- **Derivado de**: Hard Specification BR-005, CF-05.
- **Utilizado posteriormente por**: SC-010, SC-011; AT-010, AT-011.

## UC-006 — Mantener el código de búsqueda de archivos sin duplicación

- **Objetivo**: el usuario (como mantenedor) quiere que el archivo no contenga código muerto duplicado.
- **Interacción**: no hay interacción runtime; es una verificación estructural del archivo fuente.
- **Capacidades funcionales**: CF-06.
- **Actor principal**: Usuario del shell (como mantenedor). **Secundarios**: ninguno.
- **Evento disparador**: revisión/carga del archivo `zsh_functions`.
- **Precondiciones**: ninguna.
- **Flujo principal**: 1) `zsh_functions` se carga sin declarar `finder_edit`; 2) `finder` sigue disponible y sin cambios de comportamiento.
- **Flujos alternativos**: ninguno.
- **Excepciones**: ninguna.
- **Postcondiciones**: `finder_edit` no existe; ninguna referencia a `finder_edit` queda huérfana en el archivo.
- **Estados involucrados**: ninguno.
- **Reglas de negocio aplicables**: BR-006.
- **Restricciones aplicables**: ninguna.
- **Criterios de aceptación**: `grep` de `finder_edit` en `zsh_functions` no produce resultados.
- **Casos límite relevantes**: ninguno.
- **Dependencias funcionales**: ninguna.
- **Derivado de**: Hard Specification BR-006, CF-06.
- **Utilizado posteriormente por**: SC-012; AT-012.

## UC-007 — Invocar widgets sin colisión de teclas

- **Objetivo**: el usuario quiere disparar `search_history` y `finder` con atajos dedicados, conservando los atajos nativos de zsh para edición de línea.
- **Interacción**: usuario presiona `Alt-r`/`Alt-f` para disparar los widgets; `Ctrl-E`/`Ctrl-F` siguen moviendo el cursor.
- **Capacidades funcionales**: CF-07.
- **Actor principal**: Usuario del shell. **Secundarios**: ZLE (Zsh Line Editor).
- **Evento disparador**: tecla presionada en una sesión interactiva de zsh.
- **Precondiciones**: sesión zsh interactiva con `zsh_functions` cargado.
- **Flujo principal**: 1) usuario presiona `Alt-r` → se dispara `search_history`; 2) usuario presiona `Alt-f` → se dispara `finder`; 3) usuario presiona `Ctrl-E` → cursor va a fin de línea (widget nativo); 4) usuario presiona `Ctrl-F` → cursor avanza un carácter (widget nativo).
- **Flujos alternativos**: ninguno.
- **Excepciones**: ninguna.
- **Postcondiciones**: los 4 bindings quedan asignados como se describe.
- **Estados involucrados**: tabla de bindings de la sesión (`bindkey`).
- **Reglas de negocio aplicables**: BR-007.
- **Restricciones aplicables**: no reintroducir `bindkey '^e'`/`'^f'` para estos widgets.
- **Criterios de aceptación**: `bindkey` muestra `^[r`→`search_history`, `^[f`→`finder`, `^E`→`end-of-line`, `^F`→`forward-char`.
- **Casos límite relevantes**: ninguno.
- **Dependencias funcionales**: ninguna.
- **Derivado de**: Hard Specification BR-007, CF-07.
- **Utilizado posteriormente por**: SC-013, SC-014, SC-015, SC-016; AT-013..AT-016.

## UC-008 — Navegar a un directorio exacto en el árbol

- **Objetivo**: el usuario quiere navegar directamente al directorio que seleccionó en el árbol mostrado por `cdt`, sin importar su profundidad.
- **Interacción**: usuario invoca `cdt` → sistema muestra árbol de hasta 3 niveles → usuario selecciona una línea → sistema hace `cd` al directorio exacto representado por esa línea.
- **Capacidades funcionales**: CF-08.
- **Actor principal**: Usuario del shell. **Secundarios**: `tree` (o su fallback `fd`/`find`).
- **Evento disparador**: invocación de `cdt`.
- **Precondiciones**: al menos un subdirectorio existe bajo el cwd.
- **Flujo principal**: 1) `tree -d -L 3` genera el árbol; 2) fzf presenta cada línea; 3) usuario selecciona una línea en cualquier profundidad 1-3; 4) el sistema reconstruye la ruta completa desde la raíz del árbol usando la jerarquía mostrada; 5) `cd` a esa ruta.
- **Flujos alternativos**: cancelación en fzf → sin `cd`.
- **Excepciones**: `tree` no disponible → usa fallback ya existente (`fd`/`find`), fuera de esta corrección salvo que el fallback comparta el mismo defecto de reconstrucción (no aplica: los fallbacks ya listan rutas completas).
- **Postcondiciones**: cwd es el directorio exacto seleccionado.
- **Estados involucrados**: cwd de la sesión.
- **Reglas de negocio aplicables**: BR-008.
- **Restricciones aplicables**: ninguna nueva.
- **Criterios de aceptación**: seleccionar cualquier línea en profundidad 2 o 3 navega al directorio correcto, no a un homónimo.
- **Casos límite relevantes**: nombres de directorio duplicados en ramas distintas del árbol.
- **Dependencias funcionales**: ninguna.
- **Derivado de**: Hard Specification BR-008, CF-08.
- **Utilizado posteriormente por**: SC-017, SC-018, SC-019; AT-017, AT-018, AT-019.

## UC-009 — Navegar a subdirectorios del cwd con expectativa consistente

- **Objetivo**: el usuario quiere que el texto de `cdf` describa exactamente lo que la función lista.
- **Interacción**: usuario invoca `cdf` → sistema muestra `..` + subdirectorios inmediatos del cwd, con una cabecera que describe exactamente eso.
- **Capacidades funcionales**: CF-09.
- **Actor principal**: Usuario del shell. **Secundarios**: ninguno.
- **Evento disparador**: invocación de `cdf`.
- **Precondiciones**: ninguna.
- **Flujo principal**: 1) sistema lista `..` + subdirectorios inmediatos; 2) cabecera de fzf describe esa lista sin mencionar directorios recientes no implementados; 3) usuario selecciona uno; 4) `cd` al seleccionado.
- **Flujos alternativos**: cancelación en fzf → sin `cd`.
- **Excepciones**: ninguna.
- **Postcondiciones**: cwd es el subdirectorio seleccionado (o el padre si se eligió `..`).
- **Estados involucrados**: cwd de la sesión.
- **Reglas de negocio aplicables**: BR-009.
- **Restricciones aplicables**: no implementar historial de recientes en este contrato (fuera de alcance).
- **Criterios de aceptación**: el texto de cabecera no promete comportamiento no implementado.
- **Casos límite relevantes**: ninguno.
- **Dependencias funcionales**: ninguna.
- **Derivado de**: Hard Specification BR-009, CF-09.
- **Utilizado posteriormente por**: SC-020; AT-020.

## Cobertura

Todo actor (Usuario del shell) participa en los 9 casos de uso. Toda capacidad funcional de la Hard Specification
(CF-01..CF-09) está referenciada exactamente por un caso de uso. Ningún caso de uso introduce comportamiento
ausente en `03_HARD_SPECIFICATION.md`.
