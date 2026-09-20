SOURCE: backend/docs/spec_methodology/03_HARD_SPECIFICATION.md
ADAPTATION: OMP Specification Skill v0.1
ENTRY POINT: Etapa 03 (directo). Etapas 01/02 no se generaron como documentos formales; su contenido equivalente
(discovery técnico + análisis de proyecto con decisiones cerradas) fue producido en la misma conversación mediante
`technical-discovery` y `project-management` y se referencia aquí como evidencia de origen en vez de duplicarse.

# 03 — Hard Specification: corrección de funciones fzf en `zsh_functions`

## Resumen ejecutivo

Corrige 9 comportamientos defectuosos o inconsistentes en las funciones de historial, navegación/visor de archivos
y git de `zsh_functions`, identificados mediante discovery técnico y priorizados mediante análisis de proyecto.
Alcance acotado: no rediseña arquitectura del archivo, no unifica funciones, no toca clusters no revisados.

## Objetivo funcional

Que cada función/widget corregido produzca el resultado correcto y observable esperado por su propio nombre y uso
declarado (preview completo, checkout de una rama, extracción correcta de ruta de archivo, navegación al directorio
correcto, remoto configurable, sin colisión de teclas, sin código muerto duplicado) — sin cambiar su forma de
invocación salvo donde una decisión humana ya cerrada lo autoriza explícitamente (BR-006, BR-007).

## Problema que se resuelve

Referencia: discovery técnico de esta conversación (clusters historial / visor de archivos / git) y el
`project-management` posterior que clasificó cada hallazgo como `ISSUE` confirmado y cerró 3 `DECISION_REQUIRED`
(keybindings, alcance de unificación de navegación, override de `cd`). Los 9 `ISSUE` en alcance:

| Issue original | BR derivado |
|---|---|
| `preview_file_finder` descarta el primer resultado (`--header-lines=1`) | BR-001 |
| `git_add_patch_file` rompe con estados de `git status` de dos palabras | BR-002 |
| `git_change_branch` ofrece multi-selección incompatible con `git checkout` | BR-003 |
| `git_fetch_all_branch` falla silenciosamente al forzar la rama activa | BR-004 |
| `git_activiy` tiene el remoto `azure` hardcodeado | BR-005 |
| `finder_edit` duplica exactamente `finder`, sin uso | BR-006 |
| `^e`/`^f` pisan `end-of-line`/`forward-char` nativos de zsh | BR-007 |
| `cdt` no reconstruye la ruta completa en profundidad ≥2 | BR-008 |
| `cdf` anuncia "directorios recientes" que no lista | BR-009 |

## Contexto de negocio

Dotfiles personales de un único usuario/mantenedor. Sin stakeholders externos, sin SLA, sin compromiso de fecha.
Repositorio `zsh_config`, rama `master`, sincronizado con `origin/master`.

## Alcance funcional

Exactamente las 9 reglas de negocio (BR-001..BR-009) sobre las funciones: `preview_file_finder`,
`git_add_patch_file`, `git_change_branch`, `git_fetch_all_branch`, `git_activiy`, `finder_edit` (eliminación),
`search_history` y `finder` (sólo el binding, no su lógica interna), `cdt`, `cdf`.

## Fuera de alcance

- Unificación de `cd`/`cdf`/`cdt` en una sola función (decisión humana cerrada: mantener las 3 por separado).
- Cambiar que `cd()` sin argumentos abra el navegador fzf en vez de ir a `$HOME` (decisión humana cerrada: mantener).
- Historial multi-línea con `\n` literal sin revertir (Fase 3, no autorizada en este contrato).
- Robustez de `git_search_log` ante `core.abbrev` variable (Fase 3, no autorizada).
- Cualquier otra función del archivo no listada arriba (`docker_*`, `man_finder`, `kill_finder`,
  `count_files_by_exstension`, `list_enviroments`, `apt_finder_installer`, `droidcam_up`, `kill_adb_server`,
  `docker_remove_volumens`, `ctagReferences`, `git_pull_current_branch`, `git_push_current_branch`,
  `git_search_log`, `cd()` internals).
- Cambios ya presentes en el working tree no relacionados con estas 9 reglas (ver `BASELINE` en el futuro
  Execution Contract) — se preservan tal cual, no se revierten ni se re-narran.

## Actores

- **Usuario del shell**: único actor humano, dueño y único consumidor de estas funciones.

## Entidades involucradas

- **HistorialDeComandos**: lista de comandos accesible vía `fc`, gobernada por las opciones de historial de
  oh-my-zsh (`extended_history`, `hist_ignore_dups`, `share_history`, etc.), fuera de este archivo.
- **EntradaDeSistemaDeArchivos**: archivo o directorio del filesystem local, candidato de selección fzf.
- **RepositorioGit**: working tree, index, ramas locales/remotas y remotos de un repositorio git en el cwd.
- **WidgetZLE**: función registrada con `zle -N` y asociada a una combinación de teclas vía `bindkey`.
- **SesiónInteractivaZsh**: la sesión de shell donde los bindings y funciones están activos.

## Reglas de negocio

**BR-001** — `preview_file_finder` debe tratar cada línea de `find` como un candidato seleccionable, incluida la
primera. No debe usar una opción de fzf que reserve la primera línea como cabecera no seleccionable.
*Trazabilidad*: Issue "preview_file_finder descarta el primer resultado".

**BR-002** — `git_add_patch_file` debe extraer la ruta de archivo correctamente para cualquier línea de
`git status` (formato humano, sin `--porcelain`), incluyendo estados de una palabra (`modified:`, `deleted:`,
`renamed:`) y de dos palabras (`new file:`, `both modified:`, `both added:`, `copied:`). No debe capturar la
segunda palabra del estado como si fuera la ruta.
*Trazabilidad*: Issue "git_add_patch_file rompe con estados de dos palabras".

**BR-003** — `git_change_branch` debe operar sobre exactamente una rama seleccionada por invocación. No debe
ofrecer un modo de selección cuyo resultado no pueda consumir `git checkout` en una sola invocación.
*Trazabilidad*: Issue "git_change_branch ofrece multi-selección incompatible con git checkout".

**BR-004** — `git_fetch_all_branch` no debe intentar forzar (`git branch --force`) la rama actualmente activa
(`HEAD` simbólico). Debe omitirla del bucle de actualización y reportar explícitamente cuál rama fue omitida y
por qué, en vez de dejar que el comando falle en silencio hacia stderr.
*Trazabilidad*: Issue "git_fetch_all_branch falla silenciosamente al forzar la rama activa".

**BR-005** — `git_activiy` debe recibir el nombre del remoto como argumento posicional obligatorio (`$1`),
siguiendo el mismo patrón ya usado por `git_fetch_all_branch`. No debe contener ningún nombre de remoto
hardcodeado. Si no se provee el argumento, debe fallar con un mensaje explícito y no ejecutar `git for-each-ref`
sobre un remoto inexistente o incorrecto.
*Trazabilidad*: Issue "git_activiy tiene el remoto azure hardcodeado". Alcance mínimo elegido (argumento
obligatorio, sin default implícito) para no introducir una decisión de negocio nueva (qué remoto usar por
defecto) no solicitada.

**BR-006** — No debe existir en `zsh_functions` ninguna función cuyo cuerpo sea una duplicación exacta y sin uso
de otra función activa. Específicamente, `finder_edit` debe eliminarse.
*Trazabilidad*: Issue "finder_edit duplica exactamente finder, sin uso".

**BR-007** — Los widgets ZLE `search_history` y `finder` deben invocarse mediante combinaciones de teclas que no
colisionen con bindings nativos de zsh en modo emacs. `search_history` se invoca con `Alt-r`; `finder` se invoca
con `Alt-f`. `Ctrl-E` y `Ctrl-F` deben quedar libres para su comportamiento nativo (`end-of-line`,
`forward-char`).
*Trazabilidad*: Issue "^e/^f pisan end-of-line/forward-char nativos de zsh". Decisión humana cerrada
(`keybindings` = Alt-r/Alt-f) en el análisis de proyecto previo.

**BR-008** — `cdt` debe navegar exactamente al directorio correspondiente a la línea seleccionada del árbol
mostrado por `tree`, para cualquier profundidad dentro del límite configurado (`-L 3`), reconstruyendo la ruta
completa desde la raíz del árbol (no sólo el nombre de la última línea).
*Trazabilidad*: Issue "cdt no reconstruye la ruta completa en profundidad ≥2". Decisión humana cerrada
(`nav_scope` = fix mínimo, mantener `cd`/`cdf`/`cdt` separadas).

**BR-009** — El texto de cabecera (`--header`) de `cdf` debe describir exactamente lo que la función lista. Si
`cdf` sólo lista subdirectorios inmediatos del directorio actual más `..`, su cabecera no debe anunciar
"directorios recientes" u otro comportamiento no implementado.
*Trazabilidad*: Issue "cdf anuncia directorios recientes que no lista". Decisión humana cerrada (`nav_scope` =
fix mínimo, sin implementar historial de directorios recientes).

## Capacidades funcionales

| ID | Capacidad | BR asociada |
|---|---|---|
| CF-01 | Previsualizar y abrir archivos encontrados por `find`, incluido el primero | BR-001 |
| CF-02 | Agregar cambios por patch (`git add -p`) sobre el archivo correcto | BR-002 |
| CF-03 | Cambiar a una única rama local vía selección fzf | BR-003 |
| CF-04 | Sincronizar ramas remotas sin fallar sobre la rama activa | BR-004 |
| CF-05 | Ver actividad de un remoto configurable por argumento | BR-005 |
| CF-06 | Mantener el código de búsqueda de archivos sin duplicación muerta | BR-006 |
| CF-07 | Invocar widgets de historial/búsqueda sin colisión de teclas | BR-007 |
| CF-08 | Navegar a un directorio exacto seleccionado en un árbol multi-nivel | BR-008 |
| CF-09 | Navegar a subdirectorios del cwd con expectativas consistentes en el texto mostrado | BR-009 |

## Flujo funcional principal

Patrón común a CF-01..CF-05, CF-08, CF-09: Usuario invoca la función/widget → el sistema recolecta candidatos
(archivos, ramas, remotos, directorios) → el sistema los presenta vía fzf → el usuario selecciona exactamente un
candidato → el sistema ejecuta la acción asociada (abrir, checkout, add -p, listar actividad, cd) sobre ese
candidato → resultado observable.

CF-06 y CF-07 no siguen este patrón: son correcciones estructurales del propio archivo (eliminar código muerto,
reasignar teclas), verificables por inspección/ejecución directa sin flujo de selección.

## Flujos alternativos

- Cancelación en fzf (`ESC`/`Ctrl-C`) en cualquier CF con selección → ninguna acción se ejecuta, el sistema
  retorna al estado previo.
- Cero candidatos disponibles (ninguna rama remota nueva, ningún archivo modificado, etc.) → la función no debe
  ejecutar la acción final sobre una selección vacía.

## Casos límite

- BR-002: ruta de archivo con espacios cuando `git status` la muestra sin comillas adicionales.
- BR-003: exactamente una rama disponible (caso trivial, debe seguir funcionando).
- BR-004: la rama activa es la única rama remota rastreada (el bucle completo se omite, no falla).
- BR-005: argumento vacío (`""`) se trata igual que argumento ausente.
- BR-008: nombres de directorio repetidos en ramas distintas del árbol (debe resolver a la ruta correcta, no a
  la primera coincidencia por nombre).

## Estados

`RepositorioGit` tiene un estado relevante para BR-004: rama actualmente activa (`HEAD`) vs. resto de ramas
locales/remotas. No hay otros estados persistentes relevantes a las demás BR (invocaciones sin estado).

## Eventos

Tecla presionada (`Alt-r`, `Alt-f`, `Ctrl-E`, `Ctrl-F`), selección confirmada en fzf (`Enter`), selección
cancelada (`ESC`/`Ctrl-C`).

## Transiciones

Prohibida: BR-004 no debe transicionar la rama activa mediante `git branch --force` sobre sí misma.

## Restricciones funcionales

- Ninguna corrección debe modificar el nombre de invocación de una función salvo BR-006 (elimina `finder_edit`)
  y BR-007 (cambia el `bindkey`, no el nombre de la función).
- Ninguna corrección debe tocar líneas de `zsh_functions` fuera de las funciones listadas en "Alcance funcional".
- Los cambios ya presentes en el working tree (no relacionados con estas 9 reglas) se preservan sin alteración.

## Restricciones no funcionales conocidas

Debe funcionar con zsh 5.9, fzf 0.74.3, GNU findutils/sed/awk/grep, `tree`, `bat`, `wl-copy` — todas ya presentes
en el entorno verificado. No se introduce ninguna dependencia nueva.

## Excepciones funcionales

- BR-005: argumento ausente → error explícito, sin ejecutar `git for-each-ref`.
- BR-004: rama activa detectada → se omite del bucle con mensaje explícito, el resto de ramas se procesa
  normalmente.

## Criterios de aceptación

Uno por BR, observable:
- BR-001: el primer archivo listado por `find` puede seleccionarse y abrirse.
- BR-002: `git add -p <ruta>` recibe la ruta correcta para estados de una y dos palabras.
- BR-003: `git checkout <rama>` recibe exactamente una rama, cualquiera sea el número de líneas resaltadas en
  fzf.
- BR-004: la rama activa nunca aparece en un intento de `git branch --force` fallido; se reporta como omitida.
- BR-005: sin argumento, la función falla explícitamente antes de ejecutar `git for-each-ref`.
- BR-006: `finder_edit` no existe como declaración de función en `zsh_functions`.
- BR-007: `Alt-r` dispara `search_history`, `Alt-f` dispara `finder`; `Ctrl-E`/`Ctrl-F` ejecutan los widgets
  nativos de zsh.
- BR-008: seleccionar una entrada en profundidad 2 o 3 del árbol de `cdt` deja al usuario en el directorio
  exacto seleccionado.
- BR-009: el texto de cabecera de `cdf` es consistente con la lista que efectivamente produce.

## Riesgos funcionales

- BR-007: cambio de hábito del usuario al usar los nuevos atajos (riesgo aceptado, decisión ya cerrada).
- BR-008: la reescritura de la lógica de parsing de `tree` es la corrección de mayor complejidad relativa del
  lote; riesgo de introducir una regresión en la lista de candidatos si la reconstrucción de ruta por
  indentación no es exacta — mitigable con los escenarios de profundidad 1/2/3 en la Etapa 05/08.

## Ambigüedades remanentes

Ninguna material. Las 3 decisiones de diseño relevantes (keybindings, alcance de unificación de navegación,
override de `cd`) ya fueron cerradas explícitamente por el usuario en el análisis de proyecto previo.

## Supuestos documentados

- SUP-01: BR-005 no introduce un remoto por defecto; el argumento es obligatorio. Alternativa (usar `origin` por
  defecto) fue descartada por ser una decisión de negocio nueva no solicitada — ver "Restricciones funcionales".

## Preguntas abiertas

Ninguna bloqueante para continuar a Etapa 04.
