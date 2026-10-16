#!/bin/bash
# =============================================================================
# macOS Tahoe Auto-Installer - Versión Modular (Ultimate Edition)
# Compatible con: GNOME / Zorin OS / Cinnamon / XFCE
# =============================================================================
set -e
set +u

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# =============================================================================
# DETECCIÓN DEL USUARIO REAL
# =============================================================================
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(eval echo "~$SUDO_USER")
    REAL_UID=$(id -u "$SUDO_USER")
    REAL_GID=$(id -g "$SUDO_USER")
else
    REAL_USER="$USER"
    REAL_HOME="$HOME"
    REAL_UID=$(id -u)
    REAL_GID=$(id -g)
fi

run_as_user() {
    if [ -n "$SUDO_USER" ]; then
        sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$REAL_UID/bus" "$@" 2>/dev/null || true
    else
        "$@" 2>/dev/null || true
    fi
}

# =============================================================================
# VARIABLES DE CONFIGURACIÓN
# =============================================================================
export MACOS_VERSION="Tahoe"
export GTK_THEME="MacTahoe-Dark"
export SHELL_THEME="MacTahoe-Dark"
export ICON_THEME="MacTahoe-dark"
export CURSOR_THEME="MacTahoe-dark"
export SOUND_THEME="bigsur"
export WALLPAPER_PATH="$WORKDIR/wallpapers/macos_tahoe_default.jpg"
export ABOUT_SCRIPT="$WORKDIR/about_this_mac.sh"
export SOUND_INSTALLED="false"

export WORKDIR="$REAL_HOME/.macos-theme-setup"
export LOG_FILE="$WORKDIR/install.log"
mkdir -p "$WORKDIR"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Iniciando instalación" > "$LOG_FILE"

echo -e "${CYAN}══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🍎 macOS Tahoe Theme Installer - Ultimate Edition     ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# =============================================================================
# 🛡️ MECANISMO DE SEGURIDAD: ROLLBACK
# =============================================================================
INSTALLATION_SUCCESS=false
ROLLBACK_SCRIPT="$WORKDIR/uninstall_rollback.sh"
UNINSTALL_URL="https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/uninstall.sh"

echo -e "${BLUE}🛡️  [0/24] Descargando script de restauración...${NC}"
if curl -sSL "$UNINSTALL_URL" -o "$ROLLBACK_SCRIPT" 2>/dev/null; then
    chmod +x "$ROLLBACK_SCRIPT"
    echo -e "${GREEN}✅ Script de restauración guardado.${NC}"
else
    echo -e "${YELLOW}⚠️  No se pudo descargar el script de restauración.${NC}"
fi

cleanup_on_error() {
    local exit_code=$?
    local failed_command="${BASH_COMMAND:-Comando desconocido}"
    echo -e "${RED}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   ❌ EL SCRIPT SE DETUVO INESPERADAMENTE                ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}"
    echo -e "${YELLOW}📍 Último comando: ${RED}$failed_command${NC} (Código: $exit_code)${NC}"
    echo -e "${YELLOW}🔄 Ejecutando restauración del sistema...${NC}"
    if [ -f "$ROLLBACK_SCRIPT" ]; then
        bash "$ROLLBACK_SCRIPT" --auto
    fi
    exit 1
}
trap cleanup_on_error ERR

# =============================================================================
# DETECCIÓN DEL ENTORNO
# =============================================================================
export DESKTOP_ENV=$(echo "${XDG_CURRENT_DESKTOP:-unknown}" | tr '[:upper:]' '[:lower:]')
export DISTRO=""
[ -f /etc/os-release ] && . /etc/os-release && export DISTRO=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')

export IS_GNOME=false
export IS_CINNAMON=false
export IS_XFCE=false

[[ "$DESKTOP_ENV" == *"gnome"* ]] || [[ "$DISTRO" == *"zorin"* ]] && export IS_GNOME=true
[[ "$DESKTOP_ENV" == *"cinnamon"* ]] || [[ "$DISTRO" == *"mint"* && "$DESKTOP_ENV" != *"xfce"* ]] && export IS_CINNAMON=true
[[ "$DESKTOP_ENV" == *"xfce"* ]] && export IS_XFCE=true

# Resolución para iconos
if command -v xrandr &> /dev/null; then
    SCREEN_WIDTH=$(xrandr --current | grep '*' | head -1 | awk '{print $1}' | cut -d'x' -f1)
    [ -n "$SCREEN_WIDTH" ] && {
        if [ "$SCREEN_WIDTH" -ge 3840 ]; then export SCREEN_VARIANT="4k"; export ICON_BOLD_FLAG="-b"
        elif [ "$SCREEN_WIDTH" -ge 2560 ]; then export SCREEN_VARIANT="2k"; export ICON_BOLD_FLAG=""
        else export SCREEN_VARIANT="1080p"; export ICON_BOLD_FLAG=""; fi
    } || { export SCREEN_VARIANT="4k"; export ICON_BOLD_FLAG="-b"; }
else
    export SCREEN_VARIANT="4k"; export ICON_BOLD_FLAG="-b"
fi

# =============================================================================
# PASO 0.5: DESCARGA DE MÓDULOS
# =============================================================================
echo -e "${BLUE}📦 [0.5/24] Descargando módulos de entornos de escritorio...${NC}"
MODULES_DIR="$WORKDIR/modules"
mkdir -p "$MODULES_DIR"

curl -sSL "https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/gnome.sh" -o "$MODULES_DIR/gnome.sh"
curl -sSL "https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/xfce.sh" -o "$MODULES_DIR/xfce.sh"
curl -sSL "https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/cinnamon.sh" -o "$MODULES_DIR/cinnamon.sh"

chmod +x "$MODULES_DIR/"*.sh

if [ ! -f "$MODULES_DIR/gnome.sh" ] || [ ! -f "$MODULES_DIR/xfce.sh" ] || [ ! -f "$MODULES_DIR/cinnamon.sh" ]; then
    echo -e "${RED}❌ Error crítico: No se pudieron descargar los módulos.${NC}"
    exit 1
fi

source "$MODULES_DIR/gnome.sh"
source "$MODULES_DIR/xfce.sh"
source "$MODULES_DIR/cinnamon.sh"
echo -e "${GREEN}✅ Módulos cargados. Entorno detectado: $DESKTOP_ENV${NC}\n"

# =============================================================================
# FUNCIÓN DE INSTALACIÓN SEGURA DE PAQUETES
# =============================================================================
install_packages_safely() {
    local pkgs=("$@")
    echo -e "${BLUE}   → Instalando: ${pkgs[*]}${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y -qq "${pkgs[@]}" 2>/dev/null || return 1
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y -q "${pkgs[@]}" 2>/dev/null || return 1
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm --needed "${pkgs[@]}" &>/dev/null || return 1
    else
        return 1
    fi
    return 0
}

# =============================================================================
# PASO 1: DEPENDENCIAS DEL SISTEMA (SEPARADAS POR ENTORNO)
# =============================================================================
echo -e "${YELLOW}📦 [1/24] Preparando dependencias del sistema...${NC}"
export DEBIAN_FRONTEND=noninteractive

COMMON_PKGS=(git sassc fontconfig curl unzip wget jq ffmpeg sox rofi fd-find xdotool wmctrl x11-utils util-linux qt5ct qt6ct ruby libinput-tools clipit)

if [ "$IS_GNOME" = true ]; then
    SPECIFIC_PKGS=(gnome-tweaks gnome-shell-extension-manager dconf-cli gnome-sushi gnome-backgrounds plymouth-themes firefox plank x11-xserver-utils python3-pil python3-requests zenity)
elif [ "$IS_XFCE" = true ]; then
    SPECIFIC_PKGS=(xfce4-clipman-plugin xfce4-whiskermenu-plugin xfce4-terminal xfce4-notifyd xfce4-pulseaudio-plugin thunar plymouth-themes firefox plank x11-xserver-utils python3-pil python3-requests zenity)
elif [ "$IS_CINNAMON" = true ]; then
    SPECIFIC_PKGS=(cinnamon-tweaks dconf-cli plymouth-themes firefox plank x11-xserver-utils python3-pil python3-requests zenity)
else
    SPECIFIC_PKGS=(plymouth-themes firefox plank x11-xserver-utils python3-pil python3-requests zenity)
fi

ALL_PKGS=("${COMMON_PKGS[@]}" "${SPECIFIC_PKGS[@]}")

if command -v apt-get &> /dev/null; then
    echo "gdm3 shared/default-x-display-manager select gdm3" | sudo debconf-set-selections 2>/dev/null || true
    sudo apt-get update -qq || { echo -e "${RED}✗ Error al actualizar repositorios.${NC}"; exit 1; }
fi

if ! install_packages_safely "${ALL_PKGS[@]}"; then
    echo -e "${RED}🔄 Activando restauración por fallo de dependencias...${NC}"
    cleanup_on_error
fi
unset DEBIAN_FRONTEND
echo -e "${GREEN}✅ Dependencias listas.${NC}\n"

# =============================================================================
# PASO 2: FUENTES OFICIALES DE APPLE
# =============================================================================
echo -e "${YELLOW}🔤 [2/24] Instalando fuentes oficiales de Apple...${NC}"
FONTS_DIR="$REAL_HOME/.local/share/fonts"
mkdir -p "$FONTS_DIR"
git clone --depth=1 https://github.com/bradleyhodges/SFWindows.git "$WORKDIR/SFWindows" -q 2>/dev/null || true
[ -d "$WORKDIR/SFWindows" ] && find "$WORKDIR/SFWindows" -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec cp {} "$FONTS_DIR/" \; 2>/dev/null
fc-cache -f "$FONTS_DIR" > /dev/null 2>&1
export SF_INSTALLED=true
echo -e "${GREEN}✅ Fuentes instaladas.${NC}\n"

# =============================================================================
# PASOS 3 a 6: TEMAS Y CONFIGURACIONES ESPECÍFICAS
# =============================================================================
[ "$IS_GNOME" = true ] && gnome_step_3
[ "$IS_CINNAMON" = true ] && cinnamon_step_4

echo -e "${YELLOW}🎨 [5/24] Instalando tema, iconos y cursores macOS Tahoe...${NC}"
[ ! -d "$WORKDIR/MacTahoe-gtk-theme" ] && git clone --depth=1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git "$WORKDIR/MacTahoe-gtk-theme" -q
[ ! -d "$WORKDIR/MacTahoe-icon-theme" ] && git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git "$WORKDIR/MacTahoe-icon-theme" -q

INSTALL_FLAGS="-c dark --silent-mode --round --darker"
[ "$IS_GNOME" = true ] && INSTALL_FLAGS="$INSTALL_FLAGS -l"
( cd "$WORKDIR/MacTahoe-gtk-theme" && ./install.sh $INSTALL_FLAGS > /dev/null 2>&1 )
[ -n "$ICON_BOLD_FLAG" ] && ( cd "$WORKDIR/MacTahoe-icon-theme" && ./install.sh $ICON_BOLD_FLAG > /dev/null 2>&1 ) || ( cd "$WORKDIR/MacTahoe-icon-theme" && ./install.sh > /dev/null 2>&1 )
echo -e "${GREEN}✅ Tema GTK, Iconos y Cursores instalados.${NC}\n"

[ "$IS_GNOME" = true ] && gnome_step_6

# =============================================================================
# PASO 7: WALLPAPERS MACOS
# =============================================================================
echo -e "${YELLOW}🖼️  [7/24] Instalando colección de Wallpapers macOS...${NC}"
WP_DIR="$WORKDIR/macOS-Wallpapers"
[ ! -d "$WP_DIR" ] && git clone --depth=1 https://github.com/acer51-doctom/macOS-Wallpapers.git "$WP_DIR" -q 2>/dev/null || true

if [ -d "$WP_DIR/Wallpapers/All Combined" ]; then
    sudo mkdir -p /usr/share/backgrounds/macOS
    sudo cp -r "$WP_DIR/Wallpapers/All Combined/"* /usr/share/backgrounds/macOS/ 2>/dev/null || true
    sudo chmod -R 755 /usr/share/backgrounds/macOS 2>/dev/null || true
    sudo chown -R root:root /usr/share/backgrounds/macOS 2>/dev/null || true
    echo -e "${GREEN}   ✅ Wallpapers instalados en /usr/share/backgrounds/macOS${NC}"
elif [ -d "$WP_DIR/Wallpapers" ]; then
    sudo mkdir -p /usr/share/backgrounds/macOS
    sudo cp -r "$WP_DIR/Wallpapers/"* /usr/share/backgrounds/macOS/ 2>/dev/null || true
    sudo chmod -R 755 /usr/share/backgrounds/macOS 2>/dev/null || true
    echo -e "${GREEN}   ✅ Wallpapers instalados (estructura alternativa).${NC}"
fi
echo ""

# =============================================================================
# PASO 8: SONIDOS
# =============================================================================
echo -e "${YELLOW}🔊 [8/24] Instalando sonidos macOS Big Sur...${NC}"
SOUNDS_DIR="$REAL_HOME/.local/share/sounds"
mkdir -p "$SOUNDS_DIR" 2>/dev/null || true
ZIP_URL="https://github.com/gxanshu/macos-bigsur-sound-theme-linux/archive/refs/heads/main.zip"
ZIP_FILE="/tmp/bigsur-sounds-main.zip"
EXTRACT_DIR="/tmp/bigsur-sounds-extract"
rm -f "$ZIP_FILE" 2>/dev/null; rm -rf "$EXTRACT_DIR" 2>/dev/null

if curl -sL "$ZIP_URL" --max-time 60 -o "$ZIP_FILE" 2>/dev/null && [ -s "$ZIP_FILE" ]; then
    if unzip -q "$ZIP_FILE" -d "$EXTRACT_DIR" 2>/dev/null; then
        SOURCE_DIR="$EXTRACT_DIR/macos-bigsur-sound-theme-linux-main/theme/bigsur"
        if [ -d "$SOURCE_DIR" ] && [ -f "$SOURCE_DIR/index.theme" ]; then
            cp -r "$SOURCE_DIR" "$SOUNDS_DIR/" 2>/dev/null
            [ -d "$SOUNDS_DIR/bigsur" ] && export SOUND_INSTALLED="true" && [ -n "$SUDO_USER" ] && chown -R "$REAL_UID:$REAL_GID" "$SOUNDS_DIR/bigsur" 2>/dev/null || true
        fi
    fi
fi
rm -f "$ZIP_FILE" 2>/dev/null; rm -rf "$EXTRACT_DIR" 2>/dev/null
echo ""

# =============================================================================
# PASOS 9 a 12: APLICACIONES Y HERRAMIENTAS (Resumidos por brevedad pero funcionales)
# =============================================================================
echo -e "${YELLOW}🔍 [9/24] Configurando Rofi Spotlight...${NC}"
ROFI_DIR="$REAL_HOME/.local/share/rofi-spotlight"
mkdir -p "$ROFI_DIR" "$REAL_HOME/.local/share/rofi/themes" "$REAL_HOME/.local/bin" "$REAL_HOME/.local/share/applications"
[ ! -d "$WORKDIR/rofi-spotlight" ] && git clone --depth=1 https://github.com/eromatiya/rofi-spotlight.git "$WORKDIR/rofi-spotlight" -q 2>/dev/null || true
[ -d "$WORKDIR/rofi-spotlight" ] && cp -r "$WORKDIR/rofi-spotlight"/* "$ROFI_DIR/" 2>/dev/null && chmod +x "$ROFI_DIR/rofi-spotlight.sh" 2>/dev/null || true
echo -e "${GREEN}✅ Rofi configurado.${NC}\n"

echo -e "${YELLOW}🚀 [10/24] Instalando temas de Plank...${NC}"
[ ! -d "$WORKDIR/MacOS-Mojave-Plank-themes" ] && git clone --depth=1 https://github.com/Macintosh98/MacOS-Mojave-Plank-themes.git "$WORKDIR/MacOS-Mojave-Plank-themes" -q
mkdir -p "$REAL_HOME/.local/share/plank/themes"
find "$WORKDIR/MacOS-Mojave-Plank-themes" -maxdepth 1 -type d \( -name "MacOS-*" -o -name "elementary-*" \) | while read -r theme_dir; do [ -d "$theme_dir" ] && cp -r "$theme_dir" "$REAL_HOME/.local/share/plank/themes/"; done
echo -e "${GREEN}✅ Plank configurado.${NC}\n"

echo -e "${YELLOW}🖥️  [11/24] Instalando tema Plymouth...${NC}"
if command -v plymouth &> /dev/null || [ -d /usr/share/plymouth/themes ]; then
    [ ! -d "$WORKDIR/apple-mac-plymouth" ] && git clone --depth=1 https://github.com/navisjayaseelan/apple-mac-plymouth.git "$WORKDIR/apple-mac-plymouth" -q
    sudo cp -r "$WORKDIR/apple-mac-plymouth/apple-mac-plymouth" /usr/share/plymouth/themes/ 2>/dev/null
    sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/apple-mac-plymouth/apple-mac-plymouth.plymouth 100 2>/dev/null
    sudo update-alternatives --set default.plymouth /usr/share/plymouth/themes/apple-mac-plymouth/apple-mac-plymouth.plymouth 2>/dev/null || true
    command -v update-initramfs &> /dev/null && sudo update-initramfs -u > /dev/null 2>&1
    echo -e "${GREEN}✅ Plymouth configurado.${NC}"
else
    echo -e "${YELLOW}⏭️  Plymouth no disponible.${NC}"
fi
echo ""

echo -e "${YELLOW}🌐 [12/24] Transformando aplicaciones (Safari, Finder, etc.)...${NC}"
set +e
# Safari (Firefox)
if ! command -v firefox &> /dev/null; then command -v apt-get &> /dev/null && sudo apt-get install -y -qq firefox || true; fi
wget -q -O "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/safari.svg" "https://upload.wikimedia.org/wikipedia/commons/5/52/Safari_browser_logo.svg" 2>/dev/null || true
cat > "$REAL_HOME/.local/share/applications/safari.desktop" << 'EOF'
[Desktop Entry]
Name=Safari
GenericName=Navegador Web Safari
Exec=firefox %u
Icon=safari
Terminal=false
Type=Application
Categories=Network;WebBrowser;
EOF

# Finder (Thunar/Nautilus/Nemo)
wget -q -O "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/finder.svg" "https://upload.wikimedia.org/wikipedia/commons/8/89/Finder_Icon.png" 2>/dev/null || true
if [ "$IS_XFCE" = true ] && [ -f "/usr/share/applications/thunar.desktop" ]; then
    cp "/usr/share/applications/thunar.desktop" "$REAL_HOME/.local/share/applications/finder.desktop"
    sed -i 's/^Name=.*/Name=Finder/g; s/^Icon=.*/Icon=finder/g' "$REAL_HOME/.local/share/applications/finder.desktop"
    echo -e "[Desktop Entry]\nHidden=true" > "$REAL_HOME/.local/share/applications/thunar.desktop"
    echo -e "${GREEN}   ✅ Thunar renombrado a 'Finder'.${NC}"
fi
run_as_user update-desktop-database "$REAL_HOME/.local/share/applications" 2>/dev/null || true
set -e
echo ""

# =============================================================================
# PASO 13: GDM (SOLO GNOME PURO)
# =============================================================================
echo -e "${YELLOW}🔐 [13/24] Configurando pantalla de login...${NC}"
set +e
# Condición estricta: Solo GNOME, NO XFCE, NO CINNAMON
if [ "$IS_GNOME" = true ] && [ "$IS_XFCE" = false ] && [ "$IS_CINNAMON" = false ] && [ -d "$WORKDIR/MacTahoe-gtk-theme" ]; then
    echo -e "${BLUE}   → Aplicando tema a GDM...${NC}"
    sudo "$WORKDIR/MacTahoe-gtk-theme/tweaks.sh" -g -b default > /tmp/gdm-tweak.log 2>&1 || echo -e "${YELLOW}   ⚠️  GDM omitido por políticas del sistema.${NC}"
else
    echo -e "${BLUE}   ⏭️  GDM omitido (Entorno no compatible o híbrido).${NC}"
fi
set -e
echo ""

# =============================================================================
# PASO 14: SCRIPT AUXILIAR PARA VENTANAS AVANZADAS (100% COMPLETO Y CERRADO)
# =============================================================================
echo -e "${YELLOW}🪟 [14/24] Instalando script auxiliar de gestión de ventanas...${NC}"
ADVANCED_WM_SCRIPT="$REAL_HOME/.local/bin/macos-wm-actions"
mkdir -p "$REAL_HOME/.local/bin"

cat > "$ADVANCED_WM_SCRIPT" << 'WMEOF'
#!/bin/bash
ACTION="${1:-}"
case "$ACTION" in
    "center")
        if command -v xdotool &> /dev/null; then
            WIN_ID=$(xdotool getactivewindow)
            WIN_W=$(xdotool getwindowgeometry --shell "$WIN_ID" | grep WIDTH | cut -d= -f2)
            WIN_H=$(xdotool getwindowgeometry --shell "$WIN_ID" | grep HEIGHT | cut -d= -f2)
            SCREEN_W=$(xdpyinfo | grep dimensions | awk '{print $2}' | cut -dx -f1)
            SCREEN_H=$(xdpyinfo | grep dimensions | awk '{print $2}' | cut -dx -f2)
            xdotool windowmove "$WIN_ID" $(( (SCREEN_W - WIN_W) / 2 )) $(( (SCREEN_H - WIN_H) / 2 ))
        fi ;;
    "toggle-maximize")
        command -v xdotool &> /dev/null && xdotool getactivewindow windowtogglemaximize 2>/dev/null || wmctrl -r :ACTIVE: -b toggle,maximized_vert,maximized_horz 2>/dev/null ;;
    "toggle-fullscreen")
        command -v wmctrl &> /dev/null && wmctrl -r :ACTIVE: -b toggle,fullscreen 2>/dev/null ;;
    "toggle-always-on-top")
        command -v wmctrl &> /dev/null && wmctrl -r :ACTIVE: -b toggle,above 2>/dev/null ;;
    "opacity-decrease")
        if command -v xprop &> /dev/null; then
            CURRENT=$(xprop -id $(xdotool getactivewindow) _NET_WM_WINDOW_OPACITY 2>/dev/null | awk '{print $3}')
            CURRENT=${CURRENT:-0xffffffff}; CURRENT=$((CURRENT)); NEW=$((CURRENT - 427819008))
            [ "$NEW" -lt 858993459 ] && NEW=858993459
            xprop -id $(xdotool getactivewindow) -f _NET_WM_WINDOW_OPACITY 32c -set _NET_WM_WINDOW_OPACITY "$NEW" 2>/dev/null
        fi ;;
    "opacity-increase")
        if command -v xprop &> /dev/null; then
            CURRENT=$(xprop -id $(xdotool getactivewindow) _NET_WM_WINDOW_OPACITY 2>/dev/null | awk '{print $3}')
            CURRENT=${CURRENT:-0xffffffff}; CURRENT=$((CURRENT)); NEW=$((CURRENT + 427819008))
            [ "$NEW" -gt 4294967295 ] && NEW=4294967295
            xprop -id $(xdotool getactivewindow) -f _NET_WM_WINDOW_OPACITY 32c -set _NET_WM_WINDOW_OPACITY "$NEW" 2>/dev/null
        fi ;;
    "opacity-reset")
        command -v xprop &> /dev/null && xprop -id $(xdotool getactivewindow) -remove _NET_WM_WINDOW_OPACITY 2>/dev/null ;;
    "force-kill")
        command -v xkill &> /dev/null && xkill || notify-send "Error" "xkill no está instalado" -i dialog-error ;;
    "close-app-completely")
        if command -v xdotool &> /dev/null; then
            WIN_ID=$(xdotool getactivewindow); PID=$(xdotool getwindowpid "$WIN_ID" 2>/dev/null)
            if [ -n "$PID" ]; then
                PROCESS_NAME=$(ps -p "$PID" -o comm=)
                xdotool windowclose "$WIN_ID"; sleep 0.3; pkill -f "$PROCESS_NAME" 2>/dev/null
                notify-send "Aplicación cerrada" "$PROCESS_NAME finalizado" -t 1500
            fi
        fi ;;
    "restart-cinnamon")
        if [ "${XDG_CURRENT_DESKTOP:-}" = "X-Cinnamon" ] || [ "${XDG_CURRENT_DESKTOP:-}" = "cinnamon" ]; then
            dbus-send --session --dest=org.Cinnamon.LookingGlass --type=method_call /org/Cinnamon/LookingGlass org.Cinnamon.LookingGlass.ExecuteCommand string:"global.reexec_self()" 2>/dev/null
        fi ;;
esac
WMEOF

chmod +x "$ADVANCED_WM_SCRIPT"
[ -n "$SUDO_USER" ] && chown "$REAL_UID:$REAL_GID" "$ADVANCED_WM_SCRIPT" 2>/dev/null || true
echo -e "${GREEN}✅ Script auxiliar de ventanas creado correctamente.${NC}\n"

# =============================================================================
# PASOS 15 a 23: CONFIGURACIÓN DEL SISTEMA (LLAMADAS A MÓDULOS)
# =============================================================================
echo -e "${YELLOW}⚙️  [15/24] Configurando sistema, paneles y atajos...${NC}"
[ "$IS_GNOME" = true ] && gnome_step_15
[ "$IS_CINNAMON" = true ] && cinnamon_step_15
[ "$IS_XFCE" = true ] && xfce_step_15
echo ""

[ "$IS_GNOME" = true ] && gnome_step_15_5
[ "$IS_CINNAMON" = true ] && cinnamon_step_15_5
[ "$IS_XFCE" = true ] && xfce_step_15_5
echo ""

[ "$IS_GNOME" = true ] && gnome_step_15_6
[ "$IS_CINNAMON" = true ] && cinnamon_step_15_6
[ "$IS_XFCE" = true ] && xfce_step_15_6
echo ""

[ "$IS_GNOME" = true ] && gnome_step_15_7
[ "$IS_CINNAMON" = true ] && cinnamon_step_15_7
[ "$IS_XFCE" = true ] && xfce_step_15_7
echo ""

echo -e "${YELLOW}💻 [15.8/24] Configurando identidad del equipo...${NC}"
if [ "$IS_GNOME" = true ]; then NEW_HOSTNAME="MacBook-Pro"
elif [ "$IS_CINNAMON" = true ]; then NEW_HOSTNAME="MacBook-Air"
elif [ "$IS_XFCE" = true ]; then NEW_HOSTNAME="MacBook-Neo"
else NEW_HOSTNAME="MacBook"; fi
sudo hostnamectl set-hostname "$NEW_HOSTNAME" 2>/dev/null || true
echo -e "${GREEN}   ✓ Nombre del equipo: $NEW_HOSTNAME${NC}\n"

[ "$IS_GNOME" = true ] && gnome_step_15_9
[ "$IS_CINNAMON" = true ] && cinnamon_step_15_9
[ "$IS_XFCE" = true ] && xfce_step_15_9
echo ""

[ "$IS_GNOME" = true ] && gnome_step_15_10

[ "$IS_GNOME" = true ] && gnome_step_15_10b
[ "$IS_CINNAMON" = true ] && cinnamon_step_15_10b
[ "$IS_XFCE" = true ] && xfce_step_15_10b
echo ""

[ "$IS_GNOME" = true ] && gnome_step_15_10c
[ "$IS_CINNAMON" = true ] && cinnamon_step_15_10c
[ "$IS_XFCE" = true ] && xfce_step_15_10c
echo ""

echo -e "${YELLOW}🔤 [16/24] Optimizando renderizado de fuentes...${NC}"
set +e
mkdir -p "$REAL_HOME/.config/fontconfig/" 2>/dev/null || true
cat > "$REAL_HOME/.config/fontconfig/fonts.conf" << 'EOF' 2>/dev/null || true
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="font">
    <edit name="antialias" mode="assign"><bool>true</bool></edit>
    <edit name="hinting" mode="assign"><bool>true</bool></edit>
    <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
    <edit name="rgba" mode="assign"><const>rgb</const></edit>
    <edit name="lcdfilter" mode="assign"><const>lcddefault</const></edit>
  </match>
</fontconfig>
EOF
[ -n "$SUDO_USER" ] && chown -R "$REAL_UID:$REAL_GID" "$REAL_HOME/.config/fontconfig" 2>/dev/null || true
fc-cache -f > /dev/null 2>&1 || true
set -e
echo -e "${GREEN}✅ Renderizado de fuentes optimizado.${NC}\n"

echo -e "${YELLOW}💻 [17/24] Configurando terminal...${NC}"
[ "$IS_GNOME" = true ] && gnome_step_17
[ "$IS_XFCE" = true ] && xfce_step_17
echo ""

echo -e "${YELLOW} [18/24] Configurando animaciones suaves...${NC}"
[ "$IS_GNOME" = true ] && gnome_step_18
[ "$IS_XFCE" = true ] && xfce_step_18
echo ""

echo -e "${YELLOW} [19/24] Instalando efecto Magic Lamp...${NC}"
[ "$IS_GNOME" = true ] && gnome_step_19
[ "$IS_CINNAMON" = true ] && cinnamon_step_19
echo ""

echo -e "${YELLOW} [20/24] Tematizando aplicaciones Qt y Quick Look...${NC}"
set +e
if ! grep -q "QT_QPA_PLATFORMTHEME=qt5ct" /etc/environment 2>/dev/null; then
    echo "QT_QPA_PLATFORMTHEME=qt5ct" | sudo tee -a /etc/environment > /dev/null 2>&1 || true
fi
mkdir -p "$REAL_HOME/.config/qt5ct" 2>/dev/null || true
cat > "$REAL_HOME/.config/qt5ct/qt5ct.conf" << 'EOF' 2>/dev/null || true
[Appearance]
style=gtk2
icon_theme=MacTahoe-dark
EOF
[ -n "$SUDO_USER" ] && chown -R "$REAL_UID:$REAL_GID" "$REAL_HOME/.config/qt5ct" 2>/dev/null || true

if [ "$IS_GNOME" = true ]; then
    sudo apt-get install -y -qq gnome-sushi 2>/dev/null || true
elif [ "$IS_XFCE" = true ] || [ "$IS_CINNAMON" = true ]; then
    sudo apt-get install -y -qq gloobus-preview 2>/dev/null || true
fi
set -e
echo -e "${GREEN}✅ Qt y Quick Look configurados.${NC}\n"

echo -e "${YELLOW}📜 [21/24] Activando Scroll Natural...${NC}"
[ "$IS_GNOME" = true ] || [ "$IS_CINNAMON" = true ] && gnome_cinnamon_step_21
[ "$IS_XFCE" = true ] && xfce_step_21
echo ""

echo -e "${YELLOW} [22/24] Instalando Gestos Multitáctiles (Fusuma)...${NC}"
[ "$IS_GNOME" = true ] && gnome_step_22
[ "$IS_CINNAMON" = true ] && cinnamon_step_22
[ "$IS_XFCE" = true ] && xfce_step_22
echo ""

echo -e "${YELLOW}📋 [23/24] Configurando Gestor de Portapapeles...${NC}"
[ "$IS_GNOME" = true ] && gnome_step_23
[ "$IS_CINNAMON" = true ] && cinnamon_step_23
[ "$IS_XFCE" = true ] && xfce_step_23
echo ""

# =============================================================================
# PASO 24: VERIFICACIÓN POST-INSTALACIÓN
# =============================================================================
echo -e "${YELLOW}🔍 [24/24] Verificando instalación completa...${NC}"
if [ "$IS_XFCE" = true ]; then
    verify_xfce_critical_deps
fi

echo -e "${CYAN}══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         ¡INSTALACIÓN COMPLETADA CON ÉXITO! 🎉         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo -e "${YELLOW}🔄 IMPORTANTE: Debes REINICIAR EL EQUIPO para que surtan efecto todos los cambios.${NC}"
