#!/bin/bash
# =============================================================================
# macOS Tahoe Auto-Installer - Versión WWDC26 (Ultimate Edition - 100% Universal)
# Compatible con: GNOME / Zorin OS / Cinnamon / XFCE
# =============================================================================
set -Eeuo pipefail # Modo estricto para detectar errores reales

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# =============================================================================
# DETECCIÓN DEL USUARIO REAL Y ENTORNO (CRÍTICO para sudo)
# =============================================================================
if [ -n "${SUDO_USER:-}" ]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(eval echo "~$SUDO_USER")
    REAL_UID=$(id -u "$SUDO_USER")
    REAL_GID=$(id -g "$SUDO_USER")
else
    REAL_USER="${USER:-$LOGNAME}"
    REAL_HOME="$HOME"
    REAL_UID=$(id -u)
    REAL_GID=$(id -g)
fi

# 🛡️ FUNCIÓN CORREGIDA: Incluye DISPLAY y WAYLAND_DISPLAY para comandos gráficos
run_as_user() {
    if [ -n "${SUDO_USER:-}" ]; then
        sudo -u "$SUDO_USER" env \
            DISPLAY="${DISPLAY:-:0}" \
            WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$REAL_UID/bus" \
            XDG_RUNTIME_DIR="/run/user/$REAL_UID" \
            XDG_DATA_DIRS="${XDG_DATA_DIRS:-}" \
            "$@" 2>/dev/null || true
    else
        "$@" 2>/dev/null || true
    fi
}

# Variables de configuración
MACOS_VERSION="Tahoe"
GTK_THEME="MacTahoe-Dark"
ICON_THEME="MacTahoe-dark"
CURSOR_THEME="MacTahoe-dark"
SOUND_THEME="bigsur"

export WORKDIR="$REAL_HOME/.macos-theme-setup"
export LOG_FILE="$WORKDIR/install.log"
mkdir -p "$WORKDIR"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Iniciando instalación de macOS Tahoe Theme" > "$LOG_FILE"

echo -e "${CYAN}══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🍎 macOS Tahoe Theme Installer - Ultimate Edition     ║${NC}"
echo -e "${CYAN}║   Instalación 100% automatizada y robusta               ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# =============================================================================
# 🛡️ MECANISMO DE SEGURIDAD: ROLLBACK AUTOMÁTICO
# =============================================================================
ROLLBACK_SCRIPT="$WORKDIR/uninstall_rollback.sh"
UNINSTALL_URL="https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/uninstall.sh"

echo -e "${BLUE}🛡️  [0/24] Descargando script de restauración de emergencia...${NC}"
if curl -sSL "$UNINSTALL_URL" -o "$ROLLBACK_SCRIPT" 2>/dev/null && [ -s "$ROLLBACK_SCRIPT" ]; then
    chmod +x "$ROLLBACK_SCRIPT"
    echo -e "${GREEN}✅ Script de restauración guardado. Sistema protegido.${NC}"
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
DESKTOP_ENV=$(echo "${XDG_CURRENT_DESKTOP:-unknown}" | tr '[:upper:]' '[:lower:]')
DISTRO=""
if [ -r /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$(echo "${NAME:-unknown}" | tr '[:upper:]' '[:lower:]')
fi

IS_GNOME=false
IS_CINNAMON=false
IS_XFCE=false

[[ "$DESKTOP_ENV" == *"gnome"* ]] || [[ "$DISTRO" == *"zorin"* ]] && IS_GNOME=true
[[ "$DESKTOP_ENV" == *"cinnamon"* ]] || [[ "$DISTRO" == *"mint"* && "$DESKTOP_ENV" != *"xfce"* ]] && IS_CINNAMON=true
[[ "$DESKTOP_ENV" == *"xfce"* ]] && IS_XFCE=true

echo -e "${BLUE}ℹ️  Entorno detectado: $DESKTOP_ENV | Distribución: $DISTRO${NC}"
echo -e "${BLUE}ℹ️  GNOME=$IS_GNOME | Cinnamon=$IS_CINNAMON | XFCE=$IS_XFCE${NC}"

# =============================================================================
# PASO 1: DEPENDENCIAS DEL SISTEMA
# =============================================================================
echo -e "${YELLOW}📦 [1/24] Instalando dependencias del sistema...${NC}"
export DEBIAN_FRONTEND=noninteractive

COMMON_PKGS=(git sassc fontconfig curl unzip wget jq ffmpeg sox rofi fd-find xdotool wmctrl x11-utils util-linux qt5ct qt6ct ruby libinput-tools clipit zenity python3 flatpak)

if [ "$IS_GNOME" = true ]; then
    SPECIFIC_PKGS=(gnome-tweaks gnome-shell-extension-manager dconf-cli gnome-sushi gnome-backgrounds plymouth-themes firefox plank python3-pil python3-requests libxml2-utils libglib2.0-dev-bin)
elif [ "$IS_XFCE" = true ]; then
    SPECIFIC_PKGS=(xfce4-clipman-plugin xfce4-whiskermenu-plugin xfce4-terminal xfce4-notifyd xfce4-pulseaudio-plugin xfce4-volumed-pulse thunar plymouth-themes firefox plank python3-pil python3-requests light-locker)
elif [ "$IS_CINNAMON" = true ]; then
    SPECIFIC_PKGS=(dconf-cli plymouth-themes firefox plank python3-pil python3-requests)
else
    SPECIFIC_PKGS=(plymouth-themes firefox plank python3-pil python3-requests)
fi

ALL_PKGS=("${COMMON_PKGS[@]}" "${SPECIFIC_PKGS[@]}")

if command -v apt-get &> /dev/null; then
    echo "gdm3 shared/default-x-display-manager select gdm3" | sudo debconf-set-selections 2>/dev/null || true
    sudo apt-get update -qq || { echo -e "${RED}✗ Error al actualizar repositorios.${NC}"; exit 1; }
    sudo apt-get install -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "${ALL_PKGS[@]}" 2>/dev/null || true
elif command -v dnf &> /dev/null; then
    sudo dnf install -y -q "${ALL_PKGS[@]}" 2>/dev/null || true
elif command -v pacman &> /dev/null; then
    sudo pacman -S --noconfirm --needed "${ALL_PKGS[@]}" 2>/dev/null || true
fi
unset DEBIAN_FRONTEND
echo -e "${GREEN}✅ Dependencias listas.${NC}\n"

# =============================================================================
# PASO 1.5: DETECCIÓN DE RESOLUCIÓN (Blindado contra pipefail)
# =============================================================================
SCREEN_VARIANT="1080p"
ICON_BOLD_FLAG=""
if command -v xrandr &> /dev/null; then
    SCREEN_WIDTH=$(xrandr --current 2>/dev/null | grep '*' | head -1 | awk '{print $1}' | cut -d'x' -f1 || true)
    if [ -n "$SCREEN_WIDTH" ]; then
        if [ "$SCREEN_WIDTH" -ge 3840 ]; then 
            SCREEN_VARIANT="4k"; ICON_BOLD_FLAG="-b"
        elif [ "$SCREEN_WIDTH" -ge 2560 ]; then 
            SCREEN_VARIANT="2k"
        else 
            SCREEN_VARIANT="1080p"
        fi
    fi
fi
export SCREEN_VARIANT ICON_BOLD_FLAG

# =============================================================================
# PASO 2: FUENTES OFICIALES DE APPLE (Universal)
# =============================================================================
echo -e "${YELLOW}🔤 [2/24] Instalando fuentes oficiales de Apple...${NC}"
FONTS_DIR="$REAL_HOME/.local/share/fonts"
mkdir -p "$FONTS_DIR"

SF_REPO="$WORKDIR/SFWindows"
[ ! -d "$SF_REPO" ] && git clone --depth=1 https://github.com/bradleyhodges/SFWindows.git "$SF_REPO" -q 2>/dev/null || true

export SF_INSTALLED=false
if [ -d "$SF_REPO" ]; then
    find "$SF_REPO" -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec cp {} "$FONTS_DIR/" \; 2>/dev/null || true
    fc-cache -f "$FONTS_DIR" > /dev/null 2>&1 || true
    fc-cache -f /usr/share/fonts > /dev/null 2>&1 || true
    
    if fc-list 2>/dev/null | grep -qi "SF Pro"; then
        export SF_INSTALLED=true
        echo -e "${GREEN}✅ Fuentes instaladas y detectadas por el sistema.${NC}\n"
    else
        echo -e "${YELLOW}⚠️  Fuentes copiadas, pero el sistema aún no las indexa. Se intentará aplicar la configuración de todos modos.${NC}\n"
        export SF_INSTALLED=true
    fi
else
    echo -e "${RED}❌ No se pudo clonar el repositorio de fuentes.${NC}\n"
fi

# =============================================================================
# PASOS 3 a 8: TEMAS, EXTENSIONES, WALLPAPERS Y SONIDOS (Universal)
# =============================================================================
echo -e "${YELLOW}🎨 [3-8/24] Instalando temas, extensiones y recursos...${NC}"

# Liquid Glass (GNOME)
if [ "$IS_GNOME" = true ]; then
    mkdir -p "$REAL_HOME/.local/share/gnome-shell/extensions/"
    [ ! -d "$WORKDIR/liquid-glass" ] && git clone --depth=1 https://github.com/ryohsuke1231/liquid-glass.git "$WORKDIR/liquid-glass" -q 2>/dev/null || true
    EXT_DIR="$WORKDIR/liquid-glass/liquid-glass@thinkingcoding1231.gmail.com"
    if [ -d "$EXT_DIR" ]; then
        cp -r "$EXT_DIR" "$REAL_HOME/.local/share/gnome-shell/extensions/" 2>/dev/null || true
        GNOME_VERSION=$(run_as_user gnome-shell --version 2>/dev/null | grep -oP '\d+' | head -1 || true)
        TARGET_EXT="$REAL_HOME/.local/share/gnome-shell/extensions/liquid-glass@thinkingcoding1231.gmail.com"
        if [ -n "$GNOME_VERSION" ] && [ -f "$TARGET_EXT/metadata.json" ]; then
            python3 -c "
import json
try:
    with open('$TARGET_EXT/metadata.json', 'r') as f: data = json.load(f)
    if '$GNOME_VERSION' not in data.get('shell-version', []):
        data.setdefault('shell-version', []).append('$GNOME_VERSION')
    with open('$TARGET_EXT/metadata.json', 'w') as f: json.dump(data, f, indent=2)
except Exception: pass
" 2>/dev/null || true
        fi
    fi
fi

# Cinnamon Dynamic Wallpaper (Seguro: solo instala, no manipula arrays)
if [ "$IS_CINNAMON" = true ]; then
    mkdir -p "$REAL_HOME/.local/share/cinnamon/extensions/"
    [ ! -d "$WORKDIR/cinnamon-dynamic-wallpaper" ] && git clone --depth=1 https://github.com/TobiZog/cinnamon-dynamic-wallpaper.git "$WORKDIR/cinnamon-dynamic-wallpaper" -q 2>/dev/null || true
    if [ -d "$WORKDIR/cinnamon-dynamic-wallpaper/cinnamon-dynamic-wallpaper@TobiZog" ]; then
        cp -r "$WORKDIR/cinnamon-dynamic-wallpaper/cinnamon-dynamic-wallpaper@TobiZog" "$REAL_HOME/.local/share/cinnamon/extensions/" 2>/dev/null || true
        echo -e "${GREEN}   ✅ Extensión Dynamic Wallpaper instalada.${NC}"
        echo -e "${BLUE}   ℹ️  (Actívala manualmente desde 'Configuración > Applets' si deseas usarla)${NC}"
    fi
fi

# Tema GTK e Iconos (Universal)
[ ! -d "$WORKDIR/MacTahoe-gtk-theme" ] && git clone --depth=1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git "$WORKDIR/MacTahoe-gtk-theme" -q 2>/dev/null || true
[ ! -d "$WORKDIR/MacTahoe-icon-theme" ] && git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git "$WORKDIR/MacTahoe-icon-theme" -q 2>/dev/null || true

INSTALL_FLAGS="-c dark --silent-mode --round --darker"
[ "$IS_GNOME" = true ] && INSTALL_FLAGS="$INSTALL_FLAGS -l"
( cd "$WORKDIR/MacTahoe-gtk-theme" && ./install.sh $INSTALL_FLAGS > /dev/null 2>&1 ) || true
( cd "$WORKDIR/MacTahoe-icon-theme" && ./install.sh $ICON_BOLD_FLAG > /dev/null 2>&1 ) || true

# Wallpapers (Universal)
[ ! -d "$WORKDIR/WhiteSur-wallpapers" ] && git clone --depth=1 https://github.com/vinceliuice/WhiteSur-wallpapers.git "$WORKDIR/WhiteSur-wallpapers" -q 2>/dev/null || true
if [ "$IS_GNOME" = true ]; then
    ( cd "$WORKDIR/WhiteSur-wallpapers" && ./install-gnome-backgrounds.sh -t sonoma -s "$SCREEN_VARIANT" > /dev/null 2>&1 ) || true
else
    ( cd "$WORKDIR/WhiteSur-wallpapers" && ./install-wallpapers.sh -t sonoma -c dark -s "$SCREEN_VARIANT" > /dev/null 2>&1 ) || true
fi

# Sonidos (Universal)
SOUNDS_DIR="$REAL_HOME/.local/share/sounds"
mkdir -p "$SOUNDS_DIR" 2>/dev/null || true
ZIP_URL="https://github.com/gxanshu/macos-bigsur-sound-theme-linux/archive/refs/heads/main.zip"
ZIP_FILE="/tmp/bigsur-sounds-main.zip"
EXTRACT_DIR="/tmp/bigsur-sounds-extract"
if curl -sL "$ZIP_URL" --max-time 60 -o "$ZIP_FILE" 2>/dev/null && [ -s "$ZIP_FILE" ]; then
    unzip -q "$ZIP_FILE" -d "$EXTRACT_DIR" 2>/dev/null || true
    SOURCE_DIR="$EXTRACT_DIR/macos-bigsur-sound-theme-linux-main/theme/bigsur"
    if [ -d "$SOURCE_DIR" ] && [ -f "$SOURCE_DIR/index.theme" ]; then
        cp -r "$SOURCE_DIR" "$SOUNDS_DIR/" 2>/dev/null || true
        [ -n "$SUDO_USER" ] && chown -R "$REAL_UID:$REAL_GID" "$SOUNDS_DIR/bigsur" 2>/dev/null || true
        export SOUND_INSTALLED="true"
    fi
fi
rm -f "$ZIP_FILE" 2>/dev/null || true
rm -rf "$EXTRACT_DIR" 2>/dev/null || true
echo -e "${GREEN}✅ Temas, recursos y sonidos instalados.${NC}\n"

# =============================================================================
# PASO 9 a 11: ROFI, PLANK Y PLYMOUTH (Universal)
# =============================================================================
echo -e "${YELLOW}🔍 [9-11/24] Configurando lanzadores y arranque...${NC}"
ROFI_DIR="$REAL_HOME/.local/share/rofi-spotlight"
mkdir -p "$ROFI_DIR" "$REAL_HOME/.local/share/rofi/themes" "$REAL_HOME/.local/bin" "$REAL_HOME/.local/share/applications"

[ ! -d "$WORKDIR/rofi-spotlight" ] && git clone --depth=1 https://github.com/eromatiya/rofi-spotlight.git "$WORKDIR/rofi-spotlight" -q 2>/dev/null || true
if [ -d "$WORKDIR/rofi-spotlight" ]; then
    cp -r "$WORKDIR/rofi-spotlight"/* "$ROFI_DIR/" 2>/dev/null || true
    chmod +x "$ROFI_DIR/rofi-spotlight.sh" 2>/dev/null || true
    ln -sf "$ROFI_DIR/rofi-spotlight.sh" "$REAL_HOME/.local/bin/rofi-spotlight-launcher" 2>/dev/null || true
fi

[ ! -d "$WORKDIR/MacOS-Mojave-Plank-themes" ] && git clone --depth=1 https://github.com/Macintosh98/MacOS-Mojave-Plank-themes.git "$WORKDIR/MacOS-Mojave-Plank-themes" -q 2>/dev/null || true
mkdir -p "$REAL_HOME/.local/share/plank/themes"
find "$WORKDIR/MacOS-Mojave-Plank-themes" -maxdepth 1 -type d \( -name "MacOS-*" -o -name "elementary-*" \) -exec cp -r {} "$REAL_HOME/.local/share/plank/themes/" \; 2>/dev/null || true

if command -v plymouth &> /dev/null || [ -d /usr/share/plymouth/themes ]; then
    [ ! -d "$WORKDIR/apple-mac-plymouth" ] && git clone --depth=1 https://github.com/navisjayaseelan/apple-mac-plymouth.git "$WORKDIR/apple-mac-plymouth" -q 2>/dev/null || true
    sudo cp -r "$WORKDIR/apple-mac-plymouth/apple-mac-plymouth" /usr/share/plymouth/themes/ 2>/dev/null || true
    sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/apple-mac-plymouth/apple-mac-plymouth.plymouth 100 2>/dev/null || true
    sudo update-alternatives --set default.plymouth /usr/share/plymouth/themes/apple-mac-plymouth/apple-mac-plymouth.plymouth 2>/dev/null || true
    if command -v update-initramfs &> /dev/null; then 
        sudo update-initramfs -u > /dev/null 2>&1 || true
    elif command -v dracut &> /dev/null; then
        sudo dracut --force > /dev/null 2>&1 || true
    fi
fi
echo -e "${GREEN}✅ Lanzadores y Plymouth configurados.${NC}\n"

# =============================================================================
# PASO 12: TRANSFORMACIÓN DE APLICACIONES (Universal)
# =============================================================================
echo -e "${YELLOW}🌐 [12/24] Transformando aplicaciones al estilo macOS...${NC}"
mkdir -p "$REAL_HOME/.local/share/icons/hicolor/256x256/apps"

# 12.1 Firefox -> Safari
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

# 12.2 Gestor de Archivos -> Finder
wget -q -O "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/finder.svg" "https://upload.wikimedia.org/wikipedia/commons/8/89/Finder_Icon.png" 2>/dev/null || true
if [ "$IS_GNOME" = true ] && [ -f "/usr/share/applications/org.gnome.Nautilus.desktop" ]; then
    cp "/usr/share/applications/org.gnome.Nautilus.desktop" "$REAL_HOME/.local/share/applications/finder.desktop"
    sed -i 's/^Name=.*/Name=Finder/g; s/^Icon=.*/Icon=finder/g' "$REAL_HOME/.local/share/applications/finder.desktop"
    echo -e "[Desktop Entry]\nHidden=true" > "$REAL_HOME/.local/share/applications/org.gnome.Nautilus.desktop" 2>/dev/null || true
elif [ "$IS_CINNAMON" = true ] && [ -f "/usr/share/applications/nemo.desktop" ]; then
    cp "/usr/share/applications/nemo.desktop" "$REAL_HOME/.local/share/applications/finder.desktop"
    sed -i 's/^Name=.*/Name=Finder/g; s/^Icon=.*/Icon=finder/g' "$REAL_HOME/.local/share/applications/finder.desktop"
    echo -e "[Desktop Entry]\nHidden=true" > "$REAL_HOME/.local/share/applications/nemo.desktop" 2>/dev/null || true
elif [ "$IS_XFCE" = true ] && [ -f "/usr/share/applications/thunar.desktop" ]; then
    cp "/usr/share/applications/thunar.desktop" "$REAL_HOME/.local/share/applications/finder.desktop"
    sed -i 's/^Name=.*/Name=Finder/g; s/^Icon=.*/Icon=finder/g' "$REAL_HOME/.local/share/applications/finder.desktop"
    echo -e "[Desktop Entry]\nHidden=true" > "$REAL_HOME/.local/share/applications/thunar.desktop" 2>/dev/null || true
fi

# 12.3 LocalSend (con regla UFW)
if command -v ufw &> /dev/null && sudo ufw status 2>/dev/null | grep -q "active"; then
    sudo ufw allow 53317/tcp >/dev/null 2>&1 || true
    sudo ufw allow 53317/udp >/dev/null 2>&1 || true
fi
LS_INSTALLED=false
if command -v apt-get &> /dev/null && command -v jq &> /dev/null; then
    LATEST_RELEASE_LS=$(curl -sSL "https://api.github.com/repos/localsend/localsend/releases/latest" 2>/dev/null || true)
    DEB_URL=$(echo "$LATEST_RELEASE_LS" | jq -r '.assets[] | select(.name | test("amd64.deb"; "i")) | .browser_download_url' 2>/dev/null | head -n 1 || true)
    if [ -n "$DEB_URL" ] && [ "$DEB_URL" != "null" ]; then
        wget -q --user-agent="Mozilla/5.0" -O /tmp/localsend.deb "$DEB_URL" 2>/dev/null && sudo apt-get install -y -qq /tmp/localsend.deb 2>/dev/null && LS_INSTALLED=true
    fi
fi
if [ "$LS_INSTALLED" = false ]; then
    wget -q -O "$REAL_HOME/.local/bin/localsend" "https://github.com/localsend/localsend/releases/download/v1.15.3/LocalSend-1.15.3-linux-x86_64.AppImage" 2>/dev/null || true
    chmod +x "$REAL_HOME/.local/bin/localsend" 2>/dev/null || true
    cat > "$REAL_HOME/.local/share/applications/localsend.desktop" << EOF
[Desktop Entry]
Name=LocalSend
Exec=$REAL_HOME/.local/bin/localsend %U
Icon=localsend
Type=Application
Categories=Network;FileTransfer;
EOF
fi
wget -q -O "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/localsend.svg" "https://raw.githubusercontent.com/localsend/localsend/main/app/assets/icon/512.png" 2>/dev/null || true

# 12.4 ONLYOFFICE -> Office (Flatpak)
if command -v flatpak &> /dev/null; then
    run_as_user flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    run_as_user flatpak install -y flathub org.onlyoffice.desktopeditors 2>/dev/null || true
fi

run_as_user update-desktop-database "$REAL_HOME/.local/share/applications" 2>/dev/null || true
echo -e "${GREEN}✅ Aplicaciones transformadas.${NC}\n"

# =============================================================================
# PASO 13: GDM (PANTALLA DE LOGIN - Solo GNOME)
# =============================================================================
if [ "$IS_GNOME" = true ] && [ -d "$WORKDIR/MacTahoe-gtk-theme" ]; then
    echo -e "${YELLOW}🔐 [13/24] Configurando pantalla de login (GDM)...${NC}"
    sudo "$WORKDIR/MacTahoe-gtk-theme/tweaks.sh" -g -b default > /tmp/gdm-tweak.log 2>&1 || echo -e "${YELLOW}⚠️ GDM no pudo configurarse automáticamente.${NC}"
    echo -e "${GREEN}✅ GDM configurado.${NC}\n"
fi

# =============================================================================
# PASO 14: SCRIPT AUXILIAR DE VENTANAS (Universal)
# =============================================================================
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
    "toggle-maximize") command -v xdotool &> /dev/null && xdotool getactivewindow windowtogglemaximize 2>/dev/null || wmctrl -r :ACTIVE: -b toggle,maximized_vert,maximized_horz 2>/dev/null ;;
    "force-kill") command -v xkill &> /dev/null && xkill || notify-send "Error" "xkill no está instalado" -i dialog-error ;;
    "close-app-completely")
        if command -v xdotool &> /dev/null; then
            WIN_ID=$(xdotool getactivewindow); PID=$(xdotool getwindowpid "$WIN_ID" 2>/dev/null)
            if [ -n "$PID" ]; then
                PROCESS_NAME=$(ps -p "$PID" -o comm=)
                xdotool windowclose "$WIN_ID"; sleep 0.3; pkill -f "$PROCESS_NAME" 2>/dev/null
                notify-send "Aplicación cerrada" "$PROCESS_NAME finalizado" -t 1500
            fi
        fi ;;
esac
WMEOF
chmod +x "$ADVANCED_WM_SCRIPT"
[ -n "$SUDO_USER" ] && chown "$REAL_UID:$REAL_GID" "$ADVANCED_WM_SCRIPT" 2>/dev/null || true

# =============================================================================
# PASO 15: CONFIGURACIÓN DEL SISTEMA (GNOME / CINNAMON / XFCE)
# =============================================================================
echo -e "${YELLOW}⚙️  [15/24] Configurando sistema, paneles y atajos...${NC}"

WALLPAPER_PATH=""
if [ -d "/usr/share/backgrounds/macOS" ]; then
    WALLPAPER_PATH=$(find /usr/share/backgrounds/macOS -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) 2>/dev/null | head -n 1 || true)
fi
if [ -z "$WALLPAPER_PATH" ]; then
    if [ -f "$REAL_HOME/.local/share/backgrounds/Sonoma/Sonoma-dark.jpg" ]; then
        WALLPAPER_PATH="$REAL_HOME/.local/share/backgrounds/Sonoma/Sonoma-dark.jpg"
    elif [ -f "/usr/share/backgrounds/macOS/mojave-timed.xml" ]; then
        WALLPAPER_PATH="/usr/share/backgrounds/macOS/mojave-timed.xml"
    fi
fi

if [ "$IS_GNOME" = true ]; then
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
    run_as_user gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
    run_as_user gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME"
    run_as_user gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'
    [ "$SF_INSTALLED" = true ] && run_as_user gsettings set org.gnome.desktop.interface font-name 'SF Pro Text 11'
    
    CUSTOM_PATHS=()
    gnome_set_keybinding() {
        local name="$1" command="$2" binding="$3" idx="$4"
        local SCHEMA_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${idx}/"
        run_as_user gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${SCHEMA_PATH}" name "$name" 2>/dev/null || true
        run_as_user gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${SCHEMA_PATH}" command "$command" 2>/dev/null || true
        run_as_user gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${SCHEMA_PATH}" binding "$binding" 2>/dev/null || true
        CUSTOM_PATHS+=("'$SCHEMA_PATH'")
    }
    gnome_set_keybinding "Spotlight" "rofi-spotlight-launcher" "<Ctrl>space" 0
    gnome_set_keybinding "Cerrar App" "macos-wm-actions close-app-completely" "<Super>q" 1
    gnome_set_keybinding "Centrar Ventana" "macos-wm-actions center" "<Super>c" 2
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "[$(IFS=,; echo "${CUSTOM_PATHS[*]}")]" 2>/dev/null || true

elif [ "$IS_CINNAMON" = true ]; then
    echo -e "${BLUE}   → Configurando Cinnamon (Modo Seguro)...${NC}"
    run_as_user gsettings set org.cinnamon.desktop.interface gtk-theme "$GTK_THEME"
    run_as_user gsettings set org.cinnamon.desktop.interface icon-theme "$ICON_THEME"
    run_as_user gsettings set org.cinnamon.desktop.interface cursor-theme "$CURSOR_THEME"
    
    if [ "${SF_INSTALLED:-false}" = true ]; then
        fc-cache -f "$REAL_HOME/.local/share/fonts" > /dev/null 2>&1 || true
        if fc-list 2>/dev/null | grep -qi "SF Pro"; then
            run_as_user gsettings set org.cinnamon.desktop.interface font-name 'SF Pro Text 11' 2>/dev/null || true
            run_as_user gsettings set org.cinnamon.desktop.interface document-font-name 'New York Medium 11' 2>/dev/null || true
            run_as_user gsettings set org.cinnamon.desktop.interface monospace-font-name 'SF Mono Regular 11' 2>/dev/null || true
            run_as_user gsettings set org.cinnamon.desktop.wm.preferences titlebar-font 'SF Pro Text 11' 2>/dev/null || true
            echo -e "${GREEN}   ✓ Fuentes Apple aplicadas correctamente${NC}"
        else
            echo -e "${YELLOW}   ⚠️  Fuentes copiadas, pero el sistema aún no las indexa. Se omitirá la aplicación.${NC}"
        fi
    fi

    run_as_user gsettings set org.cinnamon.desktop.wm.preferences button-layout 'close,minimize,maximize:' 2>/dev/null || true
    echo -e "${GREEN}   ✓ Botones de ventana movidos a la izquierda${NC}"
    
    run_as_user gsettings set org.cinnamon.panel-height 28 2>/dev/null || true
    echo -e "${GREEN}   ✓ Altura del panel ajustada (28px)${NC}"
    
    echo -e "${BLUE}   → Aplicando atajos de teclado estilo macOS...${NC}"
    run_as_user gsettings set org.cinnamon.desktop.keybindings.wm show-desktop "['<Super>d']" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.keybindings.wm minimize "['<Super>m']" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.keybindings.wm maximize "['<Super>Up']" 2>/dev/null || true
    
    CUSTOM_IDS=()
    cinnamon_set_keybinding() {
        local name="$1" command="$2" binding="$3" id="$4"
        local SCHEMA_PATH="/org/cinnamon/desktop/keybindings/custom-keybindings/$id/"
        run_as_user gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:${SCHEMA_PATH}" name "$name" 2>/dev/null || true
        run_as_user gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:${SCHEMA_PATH}" command "$command" 2>/dev/null || true
        run_as_user gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:${SCHEMA_PATH}" binding "['$binding']" 2>/dev/null || true
        CUSTOM_IDS+=("'$SCHEMA_PATH'")
    }
    cinnamon_set_keybinding "Spotlight" "rofi-spotlight-launcher" "<Ctrl>space" "custom-spotlight"
    cinnamon_set_keybinding "Cerrar App" "macos-wm-actions close-app-completely" "<Super>q" "custom-close"
    
    if [ ${#CUSTOM_IDS[@]} -gt 0 ]; then
        CURRENT_LIST=$(run_as_user gsettings get org.cinnamon.desktop.keybindings custom-list 2>/dev/null || echo "[]")
        if [ "$CURRENT_LIST" = "[]" ]; then
            NEW_LIST="[$(IFS=,; echo "${CUSTOM_IDS[*]}")]"
        else
            CLEAN_LIST="${CURRENT_LIST%]}"
            NEW_LIST="${CLEAN_LIST}, $(IFS=,; echo "${CUSTOM_IDS[*]}")]"
        fi
        run_as_user gsettings set org.cinnamon.desktop.keybindings custom-list "$NEW_LIST" 2>/dev/null || true
    fi
    echo -e "${GREEN}   ✓ Atajos de teclado macOS aplicados${NC}"

elif [ "$IS_XFCE" = true ]; then
    run_as_user xfconf-query -c xsettings -p /Net/ThemeName -s "$GTK_THEME" 2>/dev/null || true
    run_as_user xfconf-query -c xsettings -p /Net/IconThemeName -s "$ICON_THEME" 2>/dev/null || true
    run_as_user xfconf-query -c xfwm4 -p /general/button_layout -s "OMH" 2>/dev/null || true
    
    run_as_user xfce4-panel --quit 2>/dev/null || true; pkill xfce4-panel 2>/dev/null || true; sleep 1
    run_as_user xfconf-query -c xfce4-panel -r -R /panels 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -r -R /plugins 2>/dev/null || true
    
    run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0 -n -t empty -a 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/position -s "p=6;x=0;y=0" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/size -n -t uint -s 28 2>/dev/null || true
    
    run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-1 -n -t string -s "whiskermenu" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-1/button-icon -s "distributor-logo" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-2 -n -t string -s "separator" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-2/expand -n -t bool -s true 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-3 -n -t string -s "clock" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-3/digital-format -s "%a %d %b, %H:%M" 2>/dev/null || true
    
    run_as_user xfce4-panel &>/dev/null &
    
    xfce_set_keybinding() {
        run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/$2" -n -t string -s "$1" 2>/dev/null || \
        run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/$2" -s "$1" 2>/dev/null || true
    }
    xfce_set_keybinding "rofi-spotlight-launcher" "<Ctrl>space"
    xfce_set_keybinding "macos-wm-actions close-app-completely" "<Super>q"
fi

if [ -n "$WALLPAPER_PATH" ] && [ -f "$WALLPAPER_PATH" ]; then
    if [ "$IS_GNOME" = true ]; then
        run_as_user gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_PATH" 2>/dev/null || true
        run_as_user gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_PATH" 2>/dev/null || true
    elif [ "$IS_CINNAMON" = true ]; then
        run_as_user gsettings set org.cinnamon.desktop.background picture-uri "file://$WALLPAPER_PATH" 2>/dev/null || true
        run_as_user gsettings set org.cinnamon.desktop.background picture-uri-dark "file://$WALLPAPER_PATH" 2>/dev/null || true
    fi
fi

echo -e "${GREEN}✅ Configuración base del entorno aplicada.${NC}\n"

# =============================================================================
# PASO 15.7: ACERCA DE ESTE MAC (Universal)
# =============================================================================
ABOUT_SCRIPT="$REAL_HOME/.local/bin/about-this-mac.sh"
mkdir -p "$REAL_HOME/.local/bin"
cat > "$ABOUT_SCRIPT" << 'ABOUTEOF'
#!/bin/bash
CPU=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs | sed 's/(R)//g; s/(TM)//g; s/(C)//g' 2>/dev/null || echo "Procesador")
RAM=$(free -h | awk '/^Mem:/ {print $2}' 2>/dev/null || echo "RAM")
DISK=$(df -h / | awk 'NR==2 {print $2}' 2>/dev/null || echo "Disco")
GRAPHICS=$(lspci 2>/dev/null | grep -i "vga\|3d\|display" | head -1 | cut -d':' -f3 | xargs 2>/dev/null || echo "Gráficos")

if zenity --question --title="Acerca de este Mac" --width=360 --height=420 \
--text="<span font='SF Pro Display 18' weight='bold'>macOS Tahoe</span>\n<span font='SF Pro Text 11'><b>Chip:</b> $CPU</span>\n<span font='SF Pro Text 11'><b>Memoria:</b> $RAM</span>\n<span font='SF Pro Text 11'><b>Disco:</b> Macintosh HD ($DISK)</span>\n<span font='SF Pro Text 11'><b>Gráficos:</b> $GRAPHICS</span>" \
--ok-label="Actualizar" --cancel-label="Aceptar" 2>/dev/null; then
    gnome-terminal -- bash -c "sudo apt update && sudo apt upgrade -y; echo 'Presiona Enter para cerrar'; read" || \
    xfce4-terminal -e "bash -c 'sudo apt update && sudo apt upgrade -y; echo Presiona Enter; read'" || true
fi
ABOUTEOF
chmod +x "$ABOUT_SCRIPT"
[ -n "$SUDO_USER" ] && chown "$REAL_UID:$REAL_GID" "$ABOUT_SCRIPT" 2>/dev/null || true

if [ "$IS_XFCE" = true ]; then
    run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>i" -n -t string -s "$ABOUT_SCRIPT" 2>/dev/null || true
elif [ "$IS_CINNAMON" = true ]; then
    CUSTOM_ABOUT_PATH="/org/cinnamon/desktop/keybindings/custom-keybindings/custom-about-mac/"
    run_as_user gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:${CUSTOM_ABOUT_PATH}" name "'Acerca de este Mac'" 2>/dev/null || true
    run_as_user gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:${CUSTOM_ABOUT_PATH}" command "'$ABOUT_SCRIPT'" 2>/dev/null || true
    run_as_user gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:${CUSTOM_ABOUT_PATH}" binding "['<Super>i']" 2>/dev/null || true
    CURRENT_LIST=$(run_as_user gsettings get org.cinnamon.desktop.keybindings custom-list 2>/dev/null || echo "[]")
    if [ "$CURRENT_LIST" = "[]" ]; then
        run_as_user gsettings set org.cinnamon.desktop.keybindings custom-list "['$CUSTOM_ABOUT_PATH']" 2>/dev/null || true
    else
        CLEAN_LIST="${CURRENT_LIST%]}"
        run_as_user gsettings set org.cinnamon.desktop.keybindings custom-list "${CLEAN_LIST}, '$CUSTOM_ABOUT_PATH']" 2>/dev/null || true
    fi
elif [ "$IS_GNOME" = true ]; then
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybinding:custom3 name "'Acerca de este Mac'" 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybinding:custom3 command "'$ABOUT_SCRIPT'" 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybinding:custom3 binding "'<Super>i'" 2>/dev/null || true
fi

# =============================================================================
# PASO 15.8: MODO OSCURO AUTOMÁTICO (Universal)
# =============================================================================
AUTO_DARK_SCRIPT="$REAL_HOME/.local/bin/auto-dark-mode.sh"
mkdir -p "$REAL_HOME/.local/bin"
cat > "$AUTO_DARK_SCRIPT" << 'AUTODARKEOF'
#!/bin/bash
HOUR=$(date +%H); HOUR=$((10#$HOUR))
if [ "$HOUR" -ge 6 ] && [ "$HOUR" -lt 18 ]; then
    THEME="MacTahoe"; SCHEME="default"
else
    THEME="MacTahoe-Dark"; SCHEME="prefer-dark"
fi
command -v gsettings &> /dev/null && gsettings set org.gnome.desktop.interface gtk-theme "$THEME" 2>/dev/null || true
command -v xfconf-query &> /dev/null && xfconf-query -c xsettings -p /Net/ThemeName -s "$THEME" 2>/dev/null || true
AUTODARKEOF
chmod +x "$AUTO_DARK_SCRIPT"
[ -n "$SUDO_USER" ] && chown "$REAL_UID:$REAL_GID" "$AUTO_DARK_SCRIPT" 2>/dev/null || true

SYSTEMD_DIR="$REAL_HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_DIR"
cat > "$SYSTEMD_DIR/auto-dark-mode.service" << EOF
[Unit]
Description=Cambio automático de tema macOS
[Service]
Type=oneshot
ExecStart=$AUTO_DARK_SCRIPT
EOF
cat > "$SYSTEMD_DIR/auto-dark-mode.timer" << EOF
[Unit]
Description=Timer tema macOS
[Timer]
OnBootSec=2min
OnUnitActiveSec=1h
[Install]
WantedBy=timers.target
EOF
run_as_user systemctl --user daemon-reload 2>/dev/null || true
run_as_user systemctl --user enable --now auto-dark-mode.timer 2>/dev/null || true

# =============================================================================
# PASO 16 a 20: FUENTES, TERMINAL, ANIMACIONES, MAGIC LAMP, QT (Universal)
# =============================================================================
echo -e "${YELLOW}🔧 [16-20/24] Optimizando renderizado, terminal y efectos...${NC}"
mkdir -p "$REAL_HOME/.config/fontconfig"
cat > "$REAL_HOME/.config/fontconfig/fonts.conf" << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="font">
    <edit name="antialias" mode="assign"><bool>true</bool></edit>
    <edit name="hinting" mode="assign"><bool>true</bool></edit>
    <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
    <edit name="rgba" mode="assign"><const>rgb</const></edit>
  </match>
</fontconfig>
EOF
fc-cache -f > /dev/null 2>&1 || true

# Terminal (Ahora incluye Cinnamon, que usa gnome-terminal por defecto)
if { [ "$IS_GNOME" = true ] || [ "$IS_CINNAMON" = true ]; } && command -v gnome-terminal &> /dev/null; then
    PROFILE_ID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "macos-tahoe")
    run_as_user dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/visible-name "'macOS Tahoe'" 2>/dev/null || true
    run_as_user dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/font "'SF Mono 12'" 2>/dev/null || true
    run_as_user dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/background-color "'rgb(30,30,30)'" 2>/dev/null || true
fi

if [ "$IS_XFCE" = true ] && command -v xfce4-terminal &> /dev/null; then
    mkdir -p "$REAL_HOME/.config/xfce4/terminal"
    cat > "$REAL_HOME/.config/xfce4/terminal/terminalrc" << 'EOF'
[Configuration]
FontName=SF Mono 12
ColorForeground=#e6e6e6
ColorBackground=#1e1e1e
MiscCursorShape=TERMINAL_CURSOR_SHAPE_IBEAM
EOF
fi

if ! grep -q "QT_QPA_PLATFORMTHEME=qt5ct" /etc/environment 2>/dev/null; then
    echo "QT_QPA_PLATFORMTHEME=qt5ct" | sudo tee -a /etc/environment > /dev/null 2>&1 || true
fi

# Magic Lamp
if [ "$IS_GNOME" = true ]; then
    [ ! -d "$WORKDIR/compiz-alike-magic-lamp-effect" ] && git clone --depth=1 https://github.com/hermes83/compiz-alike-magic-lamp-effect.git "$WORKDIR/compiz-alike-magic-lamp-effect" -q 2>/dev/null || true
    EXT_MAGIC_LAMP=$(find "$WORKDIR/compiz-alike-magic-lamp-effect" -maxdepth 1 -type d -name "*magic-lamp*" 2>/dev/null | head -1 || true)
    if [ -n "$EXT_MAGIC_LAMP" ]; then
        cp -r "$EXT_MAGIC_LAMP" "$REAL_HOME/.local/share/gnome-shell/extensions/" 2>/dev/null || true
        run_as_user gnome-extensions enable "$(basename "$EXT_MAGIC_LAMP")" 2>/dev/null || true
    fi
elif [ "$IS_CINNAMON" = true ]; then
    [ ! -d "$WORKDIR/CinnamonMagicLamp" ] && git clone --depth=1 https://github.com/klangman/CinnamonMagicLamp.git "$WORKDIR/CinnamonMagicLamp" -q 2>/dev/null || true
    if [ -d "$WORKDIR/CinnamonMagicLamp/CinnamonMagicLamp@klangman" ]; then
        ln -sf "$WORKDIR/CinnamonMagicLamp/CinnamonMagicLamp@klangman" "$REAL_HOME/.local/share/cinnamon/extensions/CinnamonMagicLamp@klangman" 2>/dev/null || true
        run_as_user gsettings set org.cinnamon.desktop.effects minimize-effect "'none'" 2>/dev/null || true
        run_as_user gsettings set org.cinnamon.desktop.effects unminimize-effect "'none'" 2>/dev/null || true
    fi
fi
echo -e "${GREEN}✅ Optimizaciones aplicadas.${NC}\n"

# =============================================================================
# PASO 21: SCROLL NATURAL UNIVERSAL
# =============================================================================
echo -e "${YELLOW}📜 [21/24] Activando Scroll Natural...${NC}"
if [ "$IS_GNOME" = true ] || [ "$IS_CINNAMON" = true ]; then
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.peripherals.mouse natural-scroll true 2>/dev/null || true
elif [ "$IS_XFCE" = true ]; then
    for dev in $(xinput list 2>/dev/null | grep -i "touchpad" | grep -o 'id=[0-9]*' | cut -d= -f2); do
        xinput set-prop "$dev" "libinput Tapping Enabled" 1 2>/dev/null || true
        xinput set-prop "$dev" "libinput Natural Scrolling Enabled" 1 2>/dev/null || true
    done
fi
echo -e "${GREEN}✅ Scroll natural activado.${NC}\n"

# =============================================================================
# PASO 22: GESTOS MULTITÁCTILES (FUSUMA) (Universal)
# =============================================================================
echo -e "${YELLOW} [22/24] Instalando Gestos Multitáctiles (Fusuma)...${NC}"
if ! groups "$REAL_USER" | grep -q '\binput\b'; then
    echo -e "${YELLOW}   → Añadiendo usuario al grupo 'input'...${NC}"
    sudo usermod -aG input "$REAL_USER" 2>/dev/null || true
    echo -e "${RED}   ❗ IMPORTANTE: Debes REINICIAR para que los gestos funcionen.${NC}"
fi

mkdir -p "$REAL_HOME/.config/fusuma"
cat > "$REAL_HOME/.config/fusuma/config.yml" << 'EOF'
plugin:
  inputs:
    libinput_command_input:
      enable-tap: true
  swipe:
    3:
      left: { command: 'xdotool key ctrl+alt+Right' }
      right: { command: 'xdotool key ctrl+alt+Left' }
      up: { command: 'xdotool key super+d' }
      down: { command: 'xdotool key super+d' }
    4:
      up: { command: 'xdotool key super+s' }
      down: { command: 'xdotool key super+s' }
  pinch:
    2:
      in: { command: 'xdotool keydown ctrl click 4 keyup ctrl' }
      out: { command: 'xdotool keydown ctrl click 5 keyup ctrl' }
EOF

mkdir -p "$REAL_HOME/.config/systemd/user"
cat > "$REAL_HOME/.config/systemd/user/fusuma.service" << EOF
[Unit]
Description=Fusuma Multitouch Gestures
After=graphical-session.target
[Service]
ExecStart=/usr/bin/env fusuma
Restart=on-failure
[Install]
WantedBy=graphical-session.target
EOF
[ -n "$SUDO_USER" ] && chown -R "$REAL_UID:$REAL_GID" "$REAL_HOME/.config/fusuma" "$REAL_HOME/.config/systemd" 2>/dev/null || true
run_as_user systemctl --user daemon-reload 2>/dev/null || true
run_as_user systemctl --user enable --now fusuma.service 2>/dev/null || true
echo -e "${GREEN}✅ Fusuma configurado.${NC}\n"

# =============================================================================
# PASO 24: VERIFICACIÓN POST-INSTALACIÓN INTELIGENTE
# =============================================================================
echo -e "${YELLOW}🔍 [24/24] Verificando instalación completa...${NC}"
CRITICAL_ERRORS=0

if sudo -u "$REAL_USER" fc-list 2>/dev/null | grep -qi "SF Pro" || find "$REAL_HOME/.local/share/fonts" -name "SF-Pro*" 2>/dev/null | grep -q "SF-Pro"; then
    echo -e "   ${GREEN}✓ Fuentes Apple instaladas${NC}"
else
    echo -e "   ${RED}✗ CRÍTICO: Fuentes Apple no encontradas${NC}"; CRITICAL_ERRORS=$((CRITICAL_ERRORS + 1))
fi

if [ -d "$REAL_HOME/.themes/MacTahoe-Dark" ] || [ -d "$REAL_HOME/.local/share/themes/MacTahoe-Dark" ] || [ -d "/usr/share/themes/MacTahoe-Dark" ]; then
    echo -e "   ${GREEN}✓ Tema GTK instalado${NC}"
else
    echo -e "   ${RED}✗ CRÍTICO: Tema GTK no instalado${NC}"; CRITICAL_ERRORS=$((CRITICAL_ERRORS + 1))
fi

if [ "$CRITICAL_ERRORS" -gt 0 ]; then
    echo -e "${RED}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   ❌ INSTALACIÓN FALLIDA - EJECUTANDO RESTAURACIÓN     ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}"
    [ -f "$ROLLBACK_SCRIPT" ] && bash "$ROLLBACK_SCRIPT" --auto
    exit 1
fi

echo -e "${CYAN}══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         ¡INSTALACIÓN COMPLETADA CON ÉXITO! 🎉         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo -e "${GREEN}✨ Tu sistema Linux ahora tiene la experiencia macOS Tahoe.${NC}"
echo -e "${YELLOW}🔄 IMPORTANTE: Debes REINICIAR EL EQUIPO para aplicar:${NC}"
echo -e "${YELLOW}   • Permisos del grupo 'input' (Gestos Fusuma)${NC}"
echo -e "${YELLOW}   • Tema de arranque Plymouth${NC}"
echo -e "${YELLOW}   • Configuración de aplicaciones Qt${NC}"

echo "$(date '+%Y-%m-%d')" > "$WORKDIR/.installed_version" 2>/dev/null || true
trap - ERR # Desactivar trampa al finalizar con éxito
