# zsh_config

Configuración personal de zsh: funciones, alias y variables de entorno centradas en [fzf](https://github.com/junegunn/fzf)
para historial, navegación/búsqueda de archivos y flujos de git. Pensado para uso individual, sobre
[oh-my-zsh](https://ohmyz.sh/).

Para el detalle de cada función, atajo de teclado y limitación conocida, ver **[MANUAL.md](MANUAL.md)**.

## Requisitos

| Herramienta | Uso | Obligatoria |
|---|---|---|
| `zsh` | shell | Sí |
| `fzf` | selector interactivo usado por casi todas las funciones | Sí |
| `git` | funciones `git_*` | Sí, para ese grupo |
| GNU `findutils`, `sed`, `awk`, `grep` | procesamiento de texto en la mayoría de las funciones | Sí |
| `bat` | preview con resaltado de sintaxis en `search_history` | Recomendada |
| `wl-copy` (wl-clipboard) | copiar al portapapeles en varios `ctrl-y` (Wayland) | Recomendada |
| `tree` | navegación en árbol de `cdt` (si falta, usa `fd` o `find` como respaldo) | Opcional |
| `fd` | respaldo de `cdt` si no hay `tree`; usada también en otros scripts | Opcional |
| `docker` | funciones `docker_*` | Opcional |
| `ctags` | `ctagReferences` | Opcional |
| `man-db` | `man_finder` | Opcional |
| `apt`/`apt-cache` | `apt_finder_installer` (sólo distros basadas en Debian/Ubuntu) | Opcional |
| `adb`, `droidcam-cli` | `droidcam_up`, `kill_adb_server` | Opcional |

Probado sobre zsh 5.9 y fzf 0.74.3.

## Instalación

```sh
git clone <url-de-este-repo> zsh_config
cd zsh_config
./install.sh
```

`install.sh` hace dos cosas:

1. Crea symlinks en `$HOME` hacia `zsh_init`, `zshenv`, `zsh_functions`, `zsh_code`, `zsh_alias` (y `zshenv.local`,
   si ya existe en el repo).
2. Agrega `source ~/.zsh_init` a `~/.zshrc` si todavía no está.

Después, abrí una terminal nueva (o `source ~/.zshrc`).

### Configuración local por máquina (opcional)

Si necesitás variables de entorno específicas de esta máquina (rutas, threads, GPU, etc.), copiá el ejemplo y
volvé a correr `install.sh` para que se symlinkee:

```sh
cp zshenv.local.example zshenv.local
$EDITOR zshenv.local
./install.sh
```

`zshenv.local` no se versiona (ver `.gitignore`) — es local a cada máquina.

## Estructura del repositorio

| Archivo | Contenido |
|---|---|
| `zsh_init` | Punto de entrada: sourcea el resto de los archivos, en orden, desde `~/.zshrc`. |
| `zshenv` | Variables de entorno compartidas (p. ej. `FZF_DEFAULT_OPTS`, `NVM_DIR`, `PATH`). |
| `zsh_code` | Inicialización de herramientas externas (nvm, ssh-agent). |
| `zsh_alias` | Alias de shell. |
| `zsh_functions` | Todas las funciones y widgets ZLE descritos en `MANUAL.md`. |
| `zshenv.local.example` | Plantilla para `zshenv.local` (no versionado). |
| `install.sh` | Instalador (symlinks + hook en `.zshrc`). |
| `docs/specs/zsh-functions-improvement/` | Especificación formal (Hard Spec, casos de uso, escenarios, pruebas de aceptación, Execution Contract y revisión) del trabajo de corrección de `zsh_functions`. |

## Atajos de teclado

| Atajo | Acción |
|---|---|
| `Alt-r` | Buscar en el historial de comandos (`search_history`) |
| `Alt-f` | Buscar archivos con preview (`finder`) |

`Ctrl-E`/`Ctrl-F` quedan disponibles para su comportamiento nativo de zsh (fin de línea / avanzar un carácter).

## CI

`.github/workflows/lint.yml` valida sintaxis (`zsh -n`) de todos los archivos de shell en cada push/PR.

## Contribuir

Ver `.github/ISSUE_TEMPLATE/` para reportar bugs o pedir features, y `CODE_OF_CONDUCT.md`.

## Licencia

MIT — ver `LICENSE`.
