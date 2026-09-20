# Manual de uso

Referencia completa de las funciones y widgets definidos en `zsh_functions`. Todas requieren que el archivo esté
cargado en la sesión (lo hace `zsh_init` automáticamente tras `./install.sh`).

Convención de esta guía: `Uso` muestra la forma de invocación; `[...]` indica argumento opcional. En las
funciones basadas en fzf, `ESC`/`Ctrl-C` cancela sin ejecutar ninguna acción, salvo que se indique lo contrario.

## Índice

- [Historial](#historial)
- [Navegación y archivos](#navegación-y-archivos)
- [Git](#git)
- [Docker](#docker)
- [Procesos y sistema](#procesos-y-sistema)
- [Limitaciones conocidas](#limitaciones-conocidas)

---

## Historial

### `search_history` — `Alt-r`

Busca en el historial de comandos de la sesión (deduplicado) y, al confirmar, inserta el comando elegido en la
línea de edición actual (no lo ejecuta).

- **Uso**: presionar `Alt-r` en cualquier momento.
- **Preview**: el comando resaltado como bash vía `bat`.
- `Ctrl-Y`: copia el comando seleccionado al portapapeles (`wl-copy`), sin insertarlo en la línea.
- `Ctrl-E`: abre el comando seleccionado en `$EDITOR` (o `vim`) para editarlo antes de insertarlo en la línea.
- `Ctrl-X`: ejecuta inmediatamente el comando seleccionado (sin insertarlo en la línea primero).
- `Enter`: inserta el comando en la línea de edición actual, con el cursor al final.

---

## Navegación y archivos

### `finder` — `Alt-f`

Busca archivos por nombre bajo el directorio actual con `find`, muestra preview del contenido y abre el
seleccionado con `vim` (hardcodeado, no respeta `$EDITOR`).

- **Uso**: `Alt-f` (busca todo) o `finder <patrón>` desde la línea de comandos.

### `preview_file_finder`

Similar a `finder`, pero como función de línea de comandos (no widget), con más atajos de navegación del preview.

- **Uso**: `preview_file_finder [ruta...]`
- `Alt-J`/`Alt-K`: mover el preview una línea abajo/arriba.
- `Ctrl-F`/`Ctrl-B`: mover el preview una página abajo/arriba.
- **Nota**: no abre el archivo automáticamente; fzf sólo devuelve la selección a stdout.

### `cd` (redefine el builtin)

Reemplaza el `cd` de zsh. Con argumentos se comporta exactamente igual que el `cd` nativo. **Sin argumentos**,
en vez de ir a `$HOME`, abre un navegador interactivo de directorios que permite moverse en loop (entrar,
volver con `..`) hasta salir con `ESC`.

- **Uso**: `cd` (navegador interactivo) · `cd <ruta>` (comportamiento nativo, sin cambios).
- `Ctrl-H`: mostrar/ocultar el preview. `Ctrl-U`/`Ctrl-D`: paginar el preview.
- `Ctrl-Y`: copiar la query actual de fzf al portapapeles.
- **Nota de diseño**: este comportamiento (perder el "cd sin argumentos va a `$HOME`" estándar) es intencional,
  no un descuido — si preferís el `cd` nativo sin argumentos, usá `builtin cd`.

### `cdf` — Quick CD

Lista `..` más los subdirectorios inmediatos del directorio actual y navega al seleccionado.

- **Uso**: `cdf`
- `Tab`: mostrar/ocultar preview. `Ctrl-Y`: copiar la selección al portapapeles.
- **Nota**: sólo lista el nivel inmediato del directorio actual — no es un historial de directorios recientes
  (pese a versiones anteriores de este mismo header, que sí lo insinuaban).

### `cdt` — Tree navigation

Muestra un árbol de directorios de hasta 3 niveles de profundidad (incluye ocultos, excluye `.git`) y navega al
directorio exacto seleccionado, en cualquier profundidad.

- **Uso**: `cdt`
- Usa `tree` si está disponible (con `-f` para rutas completas); si no, cae a `fd -t d -d 3`; si tampoco, a
  `find . -type d -maxdepth 3`.

### `kill_finder [señal]`

Selector interactivo (multi-selección) de procesos para terminar, con preview de detalles del proceso, archivos
abiertos y árbol de procesos. Pide confirmación antes de enviar la señal.

- **Uso**: `kill_finder` (señal `9` por defecto) · `kill_finder 15`
- `Tab`: marcar/desmarcar múltiples procesos. `Ctrl-R`: refrescar la lista.

### `man_finder`

Busca en todas las páginas de manual (`man -k .`) y abre la seleccionada.

- **Uso**: `man_finder`

### `list_enviroments`

Lista las variables de entorno actuales en un selector fzf (sólo consulta, no hace nada con la selección).

- **Uso**: `list_enviroments`

### `count_files_by_exstension [ruta...]`

Cuenta archivos por extensión bajo la(s) ruta(s) dada(s) y muestra el resultado en un selector fzf.

- **Uso**: `count_files_by_exstension .`

### `ctagReferences`

Genera tags con `ctags -R`, excluyendo `.git`, en el directorio actual.

- **Uso**: `ctagReferences`

---

## Git

### `git_change_branch`

Lista las ramas locales (ordenadas por fecha de autoría, con el asunto del último commit) y hace `checkout` de
la rama seleccionada.

- **Uso**: `git_change_branch`
- Selección única — no soporta elegir varias ramas.

### `git_add_patch_file`

Lista los archivos con cambios (`git status`, sin no-trackeados) y corre `git add -p` sobre el seleccionado.

- **Uso**: `git_add_patch_file`
- Funciona con cualquier estado de `git status` (`modified`, `new file`, `renamed`, `both modified`, etc.), en
  cualquier idioma de salida de git (no depende de que las etiquetas estén en inglés).

### `git_fetch_all_branch <remoto>`

Actualiza el remoto indicado y fuerza el tracking local de todas sus ramas remotas, salvo la rama actualmente
activa (que se omite y se reporta por stdout). Si el working tree tiene cambios sin commitear, los guarda con
`git stash` antes y los restaura al final.

- **Uso**: `git_fetch_all_branch origin`
- **Requiere** el nombre del remoto como argumento.

### `git_activiy <remoto>`

Muestra los últimos 20 refs del remoto indicado, ordenados por fecha de commit.

- **Uso**: `git_activiy origin`
- **Requiere** el nombre del remoto como argumento — falla explícitamente si falta.
- El nombre de la función conserva un typo histórico (`activiy`, no `activity`) por decisión de mantener la
  interfaz de invocación existente.

### `git_search_log`

Navegador interactivo del log de git (sin merges), con preview del commit y la posibilidad de abrirlo en `less`.

- **Uso**: `git_search_log`
- `j`/`k`: moverse entre commits. `Alt-J`/`Alt-K`: mover el preview. `Ctrl-F`/`Ctrl-B`: paginar el preview.
  `Enter`: abrir el commit completo en `less`. `q`: salir.

### `git_pull_current_branch [args de git pull]`

`git pull` sobre la rama actualmente activa.

- **Uso**: `git_pull_current_branch` · `git_pull_current_branch --rebase`

### `git_push_current_branch [args de git push]`

`git push` sobre la rama actualmente activa.

- **Uso**: `git_push_current_branch` · `git_push_current_branch -u origin`

---

## Docker

### `docker_stop_all`

Detiene todos los contenedores en ejecución.

- **Uso**: `docker_stop_all`

### `docker_stop [filtro]`

Selector fzf de contenedores en ejecución (`docker ps`); detiene el seleccionado.

- **Uso**: `docker_stop` · `docker_stop nombre_parcial`

### `docker_remove_image [filtro]`

Selector fzf de imágenes; elimina la seleccionada con `docker rmi -f`.

- **Uso**: `docker_remove_image` · `docker_remove_image nombre_parcial`

### `docker_remove_volumens`

Elimina todos los volúmenes de Docker marcados como "dangling" (sin uso).

- **Uso**: `docker_remove_volumens`

---

## Procesos y sistema

### `apt_finder_installer <término>`

Busca paquetes con `apt-cache search`, permite selección múltiple y los instala con `apt-get install -y`.

- **Uso**: `apt_finder_installer nombre`
- **Requiere** una distro basada en APT (Debian/Ubuntu) y privilegios de root. No funciona en Fedora, Arch u
  otras distros sin `apt`/`apt-cache`.

### `droidcam_up`

Inicia el servidor `adb` y lanza `droidcam-cli` sobre adb en el puerto 4747.

- **Uso**: `droidcam_up`
- **Requiere** `adb` y `droidcam-cli` instalados, y el dispositivo conectado.

### `kill_adb_server`

Detiene el servidor `adb`.

- **Uso**: `kill_adb_server`

---

## Limitaciones conocidas

- **`search_history` con comandos multilínea**: si un comando del historial contiene saltos de línea reales
  (por ejemplo, una función pegada completa), al seleccionarlo el salto se inserta como los dos caracteres
  literales `\n`, no como un salto de línea real. `Ctrl-X` en ese caso no reproduce el comando original.
- **`git_search_log`**: asume hashes abreviados de 7 caracteres al extraer el commit para preview/`Enter`. En
  repositorios muy grandes, si `core.abbrev` (modo `auto` por defecto en git ≥ 2.11) crece más allá de 7
  caracteres, esa extracción puede no encontrar el commit.
- **`preview_file_finder` y `finder`**: usan `cat` para el preview, sin resaltado de sintaxis y sin protección
  ante archivos binarios grandes (a diferencia de `search_history`, que usa `bat`).
- **`apt_finder_installer`**: sólo funciona en distros basadas en APT — no valida la distro antes de intentar
  ejecutarse.
- **`cd` sin argumentos no va a `$HOME`**: ver nota de diseño en la sección correspondiente — es intencional,
  documentado acá para que no sorprenda.

Para el detalle de qué se corrigió, cómo se verificó, y la especificación formal detrás de las funciones de
historial, navegación y git, ver `docs/specs/zsh-functions-improvement/`.
