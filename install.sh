
#!/usr/bin/env bash

# ============================================================
# macOS Tahoe Installer for Linux
# Instalador principal
#
# Escritorios admitidos:
#   - GNOME
#   - Cinnamon
#   - XFCE
#
# Distribuciones admitidas según README:
#   - Ubuntu
#   - Zorin OS
#   - Fedora
#   - Linux Mint
#   - Debian
#   - Arch Linux
#   - Manjaro
#   - Pop!_OS
#   - openSUSE (soporte con ajustes)
# ============================================================

set -Eeuo pipefail

# ------------------------------------------------------------
# Rutas y configuración
# ------------------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

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
    printf '%b[INFO]%b %s\n' "$CYAN" "$NC" "$*"
}

success() {
    printf '%b[OK]%b %s\n' "$GREEN" "$NC" "$*"
}

warning() {
    printf '%b[AVISO]%b %s\n' "$YELLOW" "$NC" "$*"
}

error() {
    printf '%b[ERROR]%b %s\n' "$RED" "$NC" "$*" >&2
}

# ------------------------------------------------------------
# Manejo de errores
# ------------------------------------------------------------

on_error() {
    local status=$?
    error "Ocurrió un error en la línea ${BASH_LINENO[0]:-desconocida}."
    error "Código de salida: $status"
    exit "$status"
}

trap on_error ERR

# ------------------------------------------------------------
# Verificar sistema operativo
# ------------------------------------------------------------

if [[ ! -r /etc/os-release ]]; then
    error "No se encontró /etc/os-release."
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

DISTRO_ID="${ID,,}"
DISTRO_NAME="${PRETTY_NAME:-$ID}"

if [[ -z "$DISTRO_ID" ]]; then
    error "No se pudo identificar la distribución."
    exit 1
fi

info "Distribución detectada: $DISTRO_NAME"

# ------------------------------------------------------------
# Validar distribución admitida
# ------------------------------------------------------------

case "$DISTRO_ID" in
    ubuntu|zorin|fedora|linuxmint|debian|arch|manjaro|pop)
        DISTRO_SUPPORTED=true
        ;;

    opensuse*|suse)
        DISTRO_SUPPORTED=true
        OPEN_SUSE=true
        ;;

    *)
        DISTRO_SUPPORTED=false
        ;;
esac

if [[ "$DISTRO_SUPPORTED" != true ]]; then
    error "Esta distribución no figura entre las compatibles."
    warning "Distribuciones indicadas en el README:"
    echo "  - Ubuntu"
    echo "  - Zorin OS"
    echo "  - Fedora"
    echo "  - Linux Mint"
    echo "  - Debian"
    echo "  - Arch Linux"
    echo "  - Manjaro"
    echo "  - Pop!_OS"
    echo "  - openSUSE"
    exit 1
fi

if [[ "${OPEN_SUSE:-false}" == true ]]; then
    warning "openSUSE requiere ajustes adicionales, según el README."
fi

# ------------------------------------------------------------
# Identificar usuario real
# ------------------------------------------------------------

if [[ "$EUID" -eq 0 ]]; then
    if [[ -z "${SUDO_USER:-}" || "$SUDO_USER" == "root" ]]; then
        error "No ejecutes este instalador desde una sesión root directa."
        warning "Inicia sesión en tu escritorio y ejecuta:"
        echo "  sudo ./install.sh"
        exit 1
    fi

    REAL_USER="$SUDO_USER"
else
    REAL_USER="$(id -un)"
fi

if ! id "$REAL_USER" >/dev/null 2>&1; then
    error "No se pudo identificar al usuario original."
    exit 1
fi

REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"

if [[ -z "$REAL_HOME" || ! -d "$REAL_HOME" ]]; then
    error "No se pudo identificar el directorio personal de $REAL_USER."
    exit 1
fi

# ------------------------------------------------------------
# Elevar privilegios conservando variables de sesión
# ------------------------------------------------------------

if [[ "$EUID" -ne 0 ]]; then

    if ! command -v sudo >/dev/null 2>&1; then
        error "Sudo no está instalado."
        exit 1
    fi

    info "Se necesitan permisos de administrador."
    sudo -v

    exec sudo --preserve-env=\
DISPLAY,\
WAYLAND_DISPLAY,\
XDG_SESSION_TYPE,\
XDG_CURRENT_DESKTOP,\
XDG_SESSION_DESKTOP,\
DESKTOP_SESSION,\
DBUS_SESSION_BUS_ADDRESS,\
XAUTHORITY,\
XDG_RUNTIME_DIR \
        bash "$SCRIPT_DIR/install.sh" "$@"
fi

# ------------------------------------------------------------
# Detectar escritorio
# ------------------------------------------------------------

detect_desktop() {
    local current_desktop=""
    local session_desktop=""
    local desktop_session=""
    local detected=""

    current_desktop="${XDG_CURRENT_DESKTOP:-}"
    session_desktop="${XDG_SESSION_DESKTOP:-}"
    desktop_session="${DESKTOP_SESSION:-}"

    # Priorizar las variables de la sesión gráfica.
    for value in "$current_desktop" "$session_desktop" "$desktop_session"; do

        value="${value,,}"

        case "$value" in
            *gnome*|*zorin*)
                detected="gnome"
                break
                ;;

            *cinnamon*)
                detected="cinnamon"
                break
                ;;

            *xfce*)
                detected="xfce"
                break
                ;;

            *plasma*|*kde*)
                detected="unsupported"
                break
                ;;

            *lxqt*)
                detected="unsupported"
                break
                ;;
        esac
    done

    if [[ -n "$detected" ]]; then
        echo "$detected"
        return 0
    fi

    # Fallback: comprobar procesos del usuario original.
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

    echo "unknown"
}

DESKTOP="$(detect_desktop)"

# ------------------------------------------------------------
# Validar escritorio
# ------------------------------------------------------------

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

    unsupported)
        error "El escritorio detectado no es compatible."
        warning "Escritorios admitidos: GNOME, Cinnamon y XFCE."
        exit 1
        ;;

    *)
        error "No se pudo detectar un escritorio compatible."
        warning "Escritorios admitidos:"
        echo "  - GNOME"
        echo "  - Cinnamon"
        echo "  - XFCE"
        exit 1
        ;;
esac

# ------------------------------------------------------------
# Validar combinaciones indicadas en README
# ------------------------------------------------------------

case "$DISTRO_ID:$DESKTOP" in

    ubuntu:gnome|\
    zorin:gnome|\
    fedora:gnome|\
    linuxmint:cinnamon|\
    linuxmint:xfce|\
    debian:gnome|\
    debian:cinnamon|\
    debian:xfce|\
    arch:*|\
    manjaro:*|\
    pop:gnome|\
    opensuse*:*)
        ;;
    suse:*)
        ;;
    *)
        error "La combinación de distribución y escritorio no figura como compatible en el README."
        echo "Distribución: $DISTRO_NAME"
        echo "Escritorio: $DESKTOP_NAME"
        exit 1
        ;;
esac

# ------------------------------------------------------------
# Verificar que los archivos estén disponibles
# ------------------------------------------------------------

INSTALLER_PATH="$SCRIPT_DIR/$INSTALLER"

if [[ ! -f "$INSTALLER_PATH" || ! -r "$INSTALLER_PATH" ]]; then
    error "No se encontró el instalador requerido: $INSTALLER"
    echo
    warning "Debes clonar el repositorio completo."
    echo
    echo "git clone https://github.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux.git"
    echo "cd Them-macOS-Tahoe-Installer-for-Linux"
    echo "sudo ./install.sh"
    exit 1
fi

# ------------------------------------------------------------
# Comprobar sesión gráfica
# ------------------------------------------------------------

if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
    warning "No se detectó DISPLAY ni WAYLAND_DISPLAY."
    warning "El instalador necesita ejecutarse desde una sesión gráfica."
    exit 1
fi

# ------------------------------------------------------------
# Información de instalación
# ------------------------------------------------------------

clear 2>/dev/null || true

echo -e "${CYAN}"
echo "============================================================"
echo "          macOS Tahoe Installer for Linux"
echo "============================================================"
echo -e "${NC}"

info "Usuario: $REAL_USER"
info "Directorio personal: $REAL_HOME"
info "Distribución: $DISTRO_NAME"
info "Escritorio: $DESKTOP_NAME"
info "Instalador seleccionado: $INSTALLER"

# ------------------------------------------------------------
# Confirmación
# ------------------------------------------------------------

echo
warning "La instalación modificará configuraciones del usuario y del sistema."
warning "Asegúrate de haber realizado una copia de seguridad."
echo

read -r -p "¿Deseas continuar con la instalación? [s/N]: " CONFIRM

if [[ ! "$CONFIRM" =~ ^[sS]$ ]]; then
    warning "Instalación cancelada por el usuario."
    exit 0
fi

# ------------------------------------------------------------
# Ejecutar instalador
# ------------------------------------------------------------

echo
info "Iniciando instalación para $DESKTOP_NAME..."
echo

if bash "$INSTALLER_PATH"; then
    echo
    success "El instalador terminó su ejecución."
    info "Distribución: $DISTRO_NAME"
    info "Escritorio: $DESKTOP_NAME"

    echo
    warning "Consulta las instrucciones del README para aplicar los cambios."
else
    STATUS=$?

    error "La instalación terminó con errores."
    error "Código de salida: $STATUS"

    exit "$STATUS"
fi

exit 0
