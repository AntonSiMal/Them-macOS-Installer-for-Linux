
#!/usr/bin/env bash

# ============================================================
# macOS Tahoe Installer for Linux
# Instalador principal con detección automática del escritorio
# ============================================================

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

# ------------------------------------------------------------
# Funciones
# ------------------------------------------------------------

info() {
    echo -e "${CYAN}[INFO]${NC} $*"
}

success() {
    echo -e "${GREEN}[OK]${NC} $*"
}

warning() {
    echo -e "${YELLOW}[AVISO]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# ------------------------------------------------------------
# Verificar sistema operativo
# ------------------------------------------------------------

if [[ ! -f /etc/os-release ]]; then
    error "No se pudo identificar la distribución Linux."
    exit 1
fi

source /etc/os-release

if [[ "${ID:-}" == "" ]]; then
    error "No se pudo identificar la distribución."
    exit 1
fi

info "Distribución detectada: ${PRETTY_NAME:-$ID}"

# ------------------------------------------------------------
# Detectar entorno gráfico
# ------------------------------------------------------------

detect_desktop() {

    local desktop=""

    # Primero comprobar variables de sesión.
    desktop="${XDG_CURRENT_DESKTOP:-} ${XDG_SESSION_DESKTOP:-} ${DESKTOP_SESSION:-}"

    desktop="${desktop,,}"

    # GNOME
    if [[ "$desktop" == *gnome* ]] || [[ "$desktop" == *zorin* ]]; then
        echo "gnome"
        return 0
    fi

    # Cinnamon
    if [[ "$desktop" == *cinnamon* ]]; then
        echo "cinnamon"
        return 0
    fi

    # XFCE
    if [[ "$desktop" == *xfce* ]]; then
        echo "xfce"
        return 0
    fi

    # Si las variables no permiten identificarlo,
    # comprobar los procesos de la sesión.

    if pgrep -u "$REAL_USER" -x gnome-shell >/dev/null 2>&1; then
        echo "gnome"
        return 0
    fi

    if pgrep -u "$REAL_USER" -x cinnamon >/dev/null 2>&1; then
        echo "cinnamon"
        return 0
    fi

    if pgrep -u "$REAL_USER" -x xfce4-session >/dev/null 2>&1; then
        echo "xfce"
        return 0
    fi

    if pgrep -u "$REAL_USER" -x plasmashell >/dev/null 2>&1; then
        echo "kde"
        return 0
    fi

    if pgrep -u "$REAL_USER" -x lxqt-session >/dev/null 2>&1; then
        echo "lxqt"
        return 0
    fi

    echo "unknown"
}

# ------------------------------------------------------------
# Identificar usuario real
# ------------------------------------------------------------

if [[ -n "${SUDO_USER:-}" ]]; then
    REAL_USER="$SUDO_USER"
else
    REAL_USER="$(id -un)"
fi

if ! id "$REAL_USER" >/dev/null 2>&1; then
    error "No se pudo identificar al usuario original."
    exit 1
fi

# ------------------------------------------------------------
# Comprobar permisos
# ------------------------------------------------------------

if [[ "$EUID" -ne 0 ]]; then

    info "Se necesitan permisos de administrador."

    if ! command -v sudo >/dev/null 2>&1; then
        error "Sudo no está instalado."
        exit 1
    fi

    sudo -v || exit 1

    exec sudo --preserve-env=DISPLAY,WAYLAND_DISPLAY,XDG_SESSION_TYPE \
        bash "$0" "$@"
fi

# ------------------------------------------------------------
# Mostrar información
# ------------------------------------------------------------

clear 2>/dev/null || true

echo -e "${CYAN}"
echo "============================================================"
echo "       macOS Tahoe Installer for Linux"
echo "============================================================"
echo -e "${NC}"

info "Usuario: $REAL_USER"
info "Sistema: ${PRETTY_NAME:-$ID}"

# ------------------------------------------------------------
# Detectar entorno
# ------------------------------------------------------------

DESKTOP="$(detect_desktop)"

echo

case "$DESKTOP" in

    gnome)
        INSTALLER="gnome.sh"
        DESKTOP_NAME="GNOME"
        ;;

    cinnamon)
        INSTALLER="cinnamon.sh"
        DESKTOP_NAME="Cinnamon"
        ;;

    xfce)
        INSTALLER="xfce.sh"
        DESKTOP_NAME="XFCE"
        ;;

    kde)
        error "KDE Plasma no es compatible actualmente."
        warning "No se realizará ninguna modificación."
        exit 1
        ;;

    lxqt)
        error "LXQt no es compatible actualmente."
        warning "No se realizará ninguna modificación."
        exit 1
        ;;

    *)
        error "No se pudo detectar un entorno gráfico compatible."
        echo
        warning "Entornos compatibles:"
        echo "  - GNOME"
        echo "  - Cinnamon"
        echo "  - XFCE"
        echo
        warning "Entorno detectado: desconocido."
        exit 1
        ;;

esac

# ------------------------------------------------------------
# Verificar instalador
# ------------------------------------------------------------

INSTALLER_PATH="$SCRIPT_DIR/$INSTALLER"

if [[ ! -f "$INSTALLER_PATH" ]]; then
    error "No se encontró el instalador: $INSTALLER"
    exit 1
fi

if [[ ! -r "$INSTALLER_PATH" ]]; then
    error "No se puede leer el archivo: $INSTALLER"
    exit 1
fi

# ------------------------------------------------------------
# Confirmación
# ------------------------------------------------------------

echo
echo -e "${BLUE}Entorno gráfico detectado:${NC} $DESKTOP_NAME"
echo -e "${BLUE}Instalador seleccionado:${NC} $INSTALLER"
echo

warning "Se iniciará la personalización del escritorio."
warning "Se realizarán modificaciones en la configuración del sistema."

echo

read -r -p "¿Deseas continuar con la instalación? [s/N]: " CONFIRM

if [[ ! "$CONFIRM" =~ ^[sS]$ ]]; then
    warning "Instalación cancelada por el usuario."
    exit 0
fi

# ------------------------------------------------------------
# Ejecutar instalador correspondiente
# ------------------------------------------------------------

echo
info "Iniciando instalación para $DESKTOP_NAME..."
echo

chmod +x "$INSTALLER_PATH"

if bash "$INSTALLER_PATH"; then

    echo
    success "La ejecución del instalador ha finalizado."
    info "Entorno: $DESKTOP_NAME"

    echo
    warning "Revisa las instrucciones del instalador para aplicar"
    warning "los cambios que requieran cerrar sesión o reiniciar."

else

    STATUS=$?

    error "La instalación terminó con errores."
    error "Código de salida: $STATUS"

    exit "$STATUS"

fi

exit 0
