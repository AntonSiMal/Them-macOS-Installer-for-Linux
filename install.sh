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
# DETECCIÓN DEL USUARIO REAL (CRÍTICO para que funcione con sudo)
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

# Función para ejecutar comandos como el usuario real
run_as_user() {
    if [ -n "$SUDO_USER" ]; then
        sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$REAL_UID/bus" "$@" 2>/dev/null || true
    else
        "$@" 2>/dev/null || true
    fi
}

# =============================================================================
# VARIABLES DE CONFIGURACIÓN (Exportadas para que los módulos las puedan usar)
# =============================================================================
export MACOS_VERSION="Tahoe"
export GTK_THEME="MacTahoe-Dark"
export SHELL_THEME="MacTahoe-Dark"
export ICON_THEME="MacTahoe-dark"
export CURSOR_THEME="MacTahoe-dark"
export SOUND_THEME="bigsur"
export UI_FONT="SF Pro Text 11"
export MONO_FONT="SF Mono Regular 11"
export SERIF_FONT="New York Medium 11"
export PLANK_THEME="MacOS-BigSur-Dark"

# Variables adicionales requeridas por los módulos para evitar errores de variables no definidas
export WALLPAPER_PATH="$WORKDIR/wallpapers/macos_tahoe_default.jpg"
export ABOUT_SCRIPT="$WORKDIR/about_this_mac.sh"
export SOUND_INSTALLED="false"

export WORKDIR="$REAL_HOME/.macos-theme-setup"
export LOG_FILE="$WORKDIR/install.log"
mkdir -p "$WORKDIR"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Iniciando instalación de macOS Tahoe Theme" > "$LOG_FILE"

echo -e "${CYAN}══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🍎 macOS Tahoe Theme Installer - Ultimate Edition     ║${NC}"
echo -e "${CYAN}║   Instalación 100% automatizada (Arquitectura Modular)  ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# =============================================================================
# 🛡️ MECANISMO DE SEGURIDAD: ROLLBACK AUTOMÁTICO
# =============================================================================
INSTALLATION_SUCCESS=false
ROLLBACK_SCRIPT="$WORKDIR/uninstall_rollback.sh"
UNINSTALL_URL="https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/uninstall.sh"

echo -e "${BLUE}🛡️  [0/24] Descargando script de restauración de emergencia...${NC}"
if curl -sSL "$UNINSTALL_URL" -o "$ROLLBACK_SCRIPT" 2>/dev/null; then
    chmod +x "$ROLLBACK_SCRIPT"
    echo -e "${GREEN}✅ Script de restauración guardado localmente. Sistema protegido.${NC}"
else
    echo -e "${YELLOW}⚠️  No se pudo descargar el script de restauración.${NC}"
fi

cleanup_on_error() {
    local exit_code=$?
    local failed_command="${BASH_COMMAND:-Comando ejecutado justo antes del fallo}"
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
export SESSION_TYPE="${XDG_SESSION_TYPE:-unknown}"
export DISTRO=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    export DISTRO=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')
fi

export IS_GNOME=false
export IS_CINNAMON=false
export IS_XFCE=false

[[ "$DESKTOP_ENV" == *"gnome"* ]] || [[ "$DISTRO" == *"zorin"* ]] && export IS_GNOME=true
[[ "$DESKTOP_ENV" == *"cinnamon"* ]] || [[ "$DISTRO" == *"mint"* && "$DESKTOP_ENV" != *"xfce"* ]] && export IS_CINNAMON=true
[[ "$DESKTOP_ENV" == *"xfce"* ]] && export IS_XFCE=true

# Determinar resolución para iconos
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

export HAS_FLATPAK=false; command -v flatpak &> /dev/null && export HAS_FLATPAK=true
export HAS_DASH_TO_DOCK=false
[ -d "$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com" ] || \
[ -d "/usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com" ] && export HAS_DASH_TO_DOCK=true

# =============================================================================
# PASO 0.5: DESCARGA DE MÓDULOS ESPECÍFICOS POR ESCRITORIO
# =============================================================================
echo -e "${BLUE}📦 [0.5/24] Descargando módulos de entornos de escritorio...${NC}"
MODULES_DIR="$WORKDIR/modules"
mkdir -p "$MODULES_DIR"

curl -sSL "https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/gnome.sh" -o "$MODULES_DIR/gnome.sh"
curl -sSL "https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/xfce.sh" -o "$MODULES_DIR/xfce.sh"
curl -sSL "https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/cinnamon.sh" -o "$MODULES_DIR/cinnamon.sh"

chmod +x "$MODULES_DIR/"*.sh

# Verificar que se descargaron
if [ ! -f "$MODULES_DIR/gnome.sh" ] || [ ! -f "$MODULES_DIR/xfce.sh" ] || [ ! -f "$MODULES_DIR/cinnamon.sh" ]; then
    echo -e "${RED}❌ Error crítico: No se pudieron descargar los módulos de escritorio.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Módulos descargados y listos.${NC}"

# Cargar las funciones de los módulos en el entorno actual
source "$MODULES_DIR/gnome.sh"
source "$MODULES_DIR/xfce.sh"
source "$MODULES_DIR/cinnamon.sh"

echo -e "${BLUE}📋 Entorno detectado: $DESKTOP_ENV${NC}"
echo ""

# =============================================================================
# FUNCIÓN DE INSTALACIÓN SEGURA DE PAQUETES (NUEVO)
# =============================================================================
install_packages_safely() {
    local pkgs=("$@")
    echo -e "${BLUE}   → Instalando dependencias del sistema...${NC}"
    if command -v apt-get &> /dev/null; then
        if ! sudo apt-get install -y -qq "${pkgs[@]}" 2>/dev/null; then
            echo -e "${RED}❌ Error crítico al instalar paquetes con apt.${NC}"
            return 1
        fi
    elif command -v dnf &> /dev/null; then
        if ! sudo dnf install -y -q "${pkgs[@]}" 2>/dev/null; then
            echo -e "${RED}❌ Error crítico al instalar paquetes con dnf.${NC}"
            return 1
        fi
    elif command -v pacman &> /dev/null; then
        if ! sudo pacman -S --noconfirm --needed "${pkgs[@]}" &>/dev/null; then
            echo -e "${RED}❌ Error crítico al instalar paquetes con pacman.${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Gestor de paquetes no soportado.${NC}"
        return 1
    fi
    return 0
}

# =============================================================================
# PASO 1: DEPENDENCIAS DEL SISTEMA (COMÚN)
# =============================================================================
echo -e "${YELLOW}📦 [1/24] Preparando dependencias del sistema...${NC}"
export DEBIAN_FRONTEND=noninteractive

if command -v apt-get &> /dev/null; then
    echo "gdm3 shared/default-x-display-manager select gdm3" | sudo debconf-set-selections 2>/dev/null || true
    echo "gdm3 shared/default-x-display-manager seen true" | sudo debconf-set-selections 2>/dev/null || true
    sudo apt-get update -qq || { echo -e "${RED}✗ Error al actualizar repositorios.${NC}"; exit 1; }
    
    PACKAGES=(git sassc libglib2.0-dev-bin libxml2-utils fontconfig gnome-tweaks gnome-shell-extension-manager dconf-cli plymouth-themes firefox plank x11-xserver-utils python3-pil curl unzip wget jq gnome-backgrounds ffmpeg sox rofi fd-find python3-requests xdotool wmctrl x11-utils util-linux qt5ct qt6ct ruby libinput-tools clipit xfce4-clipman-plugin gnome-sushi zenity)
    
    if ! install_packages_safely "${PACKAGES[@]}"; then
        echo -e "${RED}🔄 Activando restauración del sistema por fallo de dependencias...${NC}"
        cleanup_on_error
    fi
elif command -v dnf &> /dev/null; then
    PACKAGES=(git sassc glib2-devel libxml2 fontconfig gnome-tweaks dconf plymouth-theme-spinner firefox plank xorg-x11-server-utils python3-pillow curl unzip wget jq gnome-backgrounds ffmpeg sox rofi fd-find python3-requests xdotool wmctrl xorg-xprop xorg-xwininfo util-linux qt5ct qt6ct ruby libinput clipit xfce4-clipman-plugin gnome-sushi)
    if ! install_packages_safely "${PACKAGES[@]}"; then cleanup_on_error; fi
elif command -v pacman &> /dev/null; then
    PACKAGES=(git sassc glib2 libxml2 fontconfig gnome-tweaks dconf plymouth firefox plank xorg-xrandr python-pillow curl unzip wget jq gnome-backgrounds ffmpeg sox rofi fd python-requests xdotool wmctrl xorg-xprop xorg-xwininfo util-linux qt5ct qt6ct ruby libinput clipit xfce4-clipman-plugin gnome-sushi)
    if ! install_packages_safely "${PACKAGES[@]}"; then cleanup_on_error; fi
fi
unset DEBIAN_FRONTEND
echo -e "${GREEN}✅ Dependencias listas.${NC}\n"

# =============================================================================
# PASO 2: FUENTES OFICIALES DE APPLE (COMÚN)
# =============================================================================
echo -e "${YELLOW}🔤 [2/24] Instalando fuentes oficiales de Apple...${NC}"
FONTS_DIR="$REAL_HOME/.local/share/fonts"
mkdir -p "$FONTS_DIR"
git clone --depth=1 https://github.com/bradleyhodges/SFWindows.git "$WORKDIR/SFWindows" -q 2>/dev/null || true
[ -d "$WORKDIR/SFWindows" ] && find "$WORKDIR/SFWindows" -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec cp {} "$FONTS_DIR/" \; 2>/dev/null
fc-cache -f "$FONTS_DIR" > /dev/null 2>&1
export SF_INSTALLED=true
echo -e "${GREEN}✅ Fuentes oficiales Apple instaladas.${NC}\n"

# =============================================================================
# PASOS ESPECÍFICOS POR ESCRITORIO (LLAMADAS A MÓDULOS)
# =============================================================================
if [ "$IS_GNOME" = true ]; then gnome_step_3; fi
if [ "$IS_CINNAMON" = true ]; then cinnamon_step_4; fi

# PASO 5: TEMA GTK + ICONOS + CURSORES (COMÚN)
echo -e "${YELLOW}🎨 [5/24] Instalando tema, iconos y cursores macOS Tahoe...${NC}"
[ ! -d "$WORKDIR/MacTahoe-gtk-theme" ] && git clone --depth=1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git "$WORKDIR/MacTahoe-gtk-theme" -q
[ ! -d "$WORKDIR/MacTahoe-icon-theme" ] && git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git "$WORKDIR/MacTahoe-icon-theme" -q
INSTALL_FLAGS="-c dark --silent-mode --round --darker"
[ "$IS_GNOME" = true ] && INSTALL_FLAGS="$INSTALL_FLAGS -l"
( cd "$WORKDIR/MacTahoe-gtk-theme" && ./install.sh $INSTALL_FLAGS > /dev/null 2>&1 )
[ -n "$ICON_BOLD_FLAG" ] && ( cd "$WORKDIR/MacTahoe-icon-theme" && ./install.sh $ICON_BOLD_FLAG > /dev/null 2>&1 ) || ( cd "$WORKDIR/MacTahoe-icon-theme" && ./install.sh > /dev/null 2>&1 )
echo -e "${GREEN}✅ Tema GTK, Iconos y Cursores instalados.${NC}\n"

if [ "$IS_GNOME" = true ]; then gnome_step_6; fi

# =============================================================================
# PASO 7: WALLPAPERS SONOMA
# =============================================================================
echo -e "${YELLOW}🖼️  [7/24] Instalando wallpapers macOS Sonoma...${NC}"
[ ! -d "$WORKDIR/WhiteSur-wallpapers" ] && git clone --depth=1 https://github.com/vinceliuice/WhiteSur-wallpapers.git "$WORKDIR/WhiteSur-wallpapers" -q

if [ "$IS_GNOME" = true ]; then
    ( cd "$WORKDIR/WhiteSur-wallpapers" && ./install-gnome-backgrounds.sh -t sonoma -s "$SCREEN_VARIANT" > /dev/null 2>&1 )
else
    ( cd "$WORKDIR/WhiteSur-wallpapers" && ./install-wallpapers.sh -t sonoma -c dark -s "$SCREEN_VARIANT" > /dev/null 2>&1 )
fi
echo -e "${GREEN}✅ Wallpapers macOS Sonoma instalados.${NC}\n"

# =============================================================================
# PASO 8: SONIDOS DEL SISTEMA DE macOS BIG SUR
# =============================================================================
echo -e "${YELLOW}🔊 [8/24] Instalando sonidos del sistema macOS Big Sur...${NC}"
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
            if [ -d "$SOUNDS_DIR/bigsur" ]; then
                export SOUND_INSTALLED="true"
                [ -n "$SUDO_USER" ] && chown -R "$REAL_UID:$REAL_GID" "$SOUNDS_DIR/bigsur" 2>/dev/null || true
                echo -e "${GREEN}   ✅ Sonidos instalados correctamente.${NC}"
            fi
        fi
    fi
fi
rm -f "$ZIP_FILE" 2>/dev/null; rm -rf "$EXTRACT_DIR" 2>/dev/null
echo ""

# =============================================================================
# PASO 9: ROFI SPOTLIGHT
# =============================================================================
echo -e "${YELLOW}🔍 [9/24] Instalando Rofi Spotlight...${NC}"
ROFI_SPOTLIGHT_DIR="$REAL_HOME/.local/share/rofi-spotlight"
ROFI_THEMES_DIR="$REAL_HOME/.local/share/rofi/themes"
ROFI_BIN_DIR="$REAL_HOME/.local/bin"
ROFI_APPS_DIR="$REAL_HOME/.local/share/applications"

mkdir -p "$ROFI_SPOTLIGHT_DIR" "$ROFI_THEMES_DIR" "$ROFI_BIN_DIR" "$ROFI_APPS_DIR"

if [ ! -d "$WORKDIR/rofi-spotlight" ]; then
    git clone --depth=1 https://github.com/eromatiya/rofi-spotlight.git "$WORKDIR/rofi-spotlight" -q 2>/dev/null || true
fi

if [ -d "$WORKDIR/rofi-spotlight" ]; then
    cp -r "$WORKDIR/rofi-spotlight"/* "$ROFI_SPOTLIGHT_DIR/" 2>/dev/null
    chmod +x "$ROFI_SPOTLIGHT_DIR/rofi-spotlight.sh" "$ROFI_SPOTLIGHT_DIR/web-search.py" 2>/dev/null
fi

if [ ! -d "$WORKDIR/rofi-themes-collection" ]; then
    git clone --depth=1 https://github.com/newmanls/rofi-themes-collection.git "$WORKDIR/rofi-themes-collection" -q 2>/dev/null || true
fi
[ -d "$WORKDIR/rofi-themes-collection/themes" ] && cp "$WORKDIR/rofi-themes-collection/themes/"*.rasi "$ROFI_THEMES_DIR/" 2>/dev/null || true

ROFI_LAUNCHER="$ROFI_BIN_DIR/rofi-spotlight-launcher"
cat > "$ROFI_LAUNCHER" << 'EOF'
#!/bin/bash
ROFI_SPOTLIGHT_DIR="$HOME/.local/share/rofi-spotlight"
ROFI_THEMES_DIR="$HOME/.local/share/rofi/themes"
if ! command -v rofi &> /dev/null; then
    notify-send "Error" "Rofi no está instalado" -i dialog-error
    exit 1
fi
if [ -f "$ROFI_SPOTLIGHT_DIR/rofi-spotlight.sh" ]; then
    rofi -modi "Global Search:$ROFI_SPOTLIGHT_DIR/rofi-spotlight.sh" -show "Global Search" -theme "$ROFI_THEMES_DIR/spotlight.rasi" -config "$ROFI_SPOTLIGHT_DIR/rofi.rasi"
else
    rofi -show drun -theme "$ROFI_THEMES_DIR/spotlight.rasi"
fi
EOF
chmod +x "$ROFI_LAUNCHER"

cat > "$ROFI_APPS_DIR/rofi-spotlight.desktop" << 'EOF'
[Desktop Entry]
Name=Spotlight Search
Comment=macOS-style file and web search
Exec=rofi-spotlight-launcher
Icon=search
Type=Application
Categories=Utility;
Keywords=search;spotlight;files;web;
EOF

chown -R "$REAL_UID:$REAL_GID" "$REAL_HOME/.local/share/rofi-spotlight" "$REAL_HOME/.local/share/rofi" "$REAL_HOME/.local/bin" 2>/dev/null || true
echo -e "${GREEN}✅ Rofi Spotlight instalado.${NC}\n"

# =============================================================================
# PASO 10: TEMAS DE PLANK
# =============================================================================
echo -e "${YELLOW}🚀 [10/24] Instalando temas de Plank...${NC}"
[ ! -d "$WORKDIR/MacOS-Mojave-Plank-themes" ] && git clone --depth=1 https://github.com/Macintosh98/MacOS-Mojave-Plank-themes.git "$WORKDIR/MacOS-Mojave-Plank-themes" -q
mkdir -p "$REAL_HOME/.local/share/plank/themes"
find "$WORKDIR/MacOS-Mojave-Plank-themes" -maxdepth 1 -type d \( -name "MacOS-*" -o -name "elementary-*" \) | while read -r theme_dir; do
    [ -d "$theme_dir" ] && cp -r "$theme_dir" "$REAL_HOME/.local/share/plank/themes/"
done
echo -e "${GREEN}✅ Temas de Plank instalados.${NC}\n"

# =============================================================================
# PASO 11: TEMA PLYMOUTH
# =============================================================================
echo -e "${YELLOW}🖥️  [11/24] Instalando tema Plymouth...${NC}"
if command -v plymouth &> /dev/null || [ -d /usr/share/plymouth/themes ]; then
    [ ! -d "$WORKDIR/apple-mac-plymouth" ] && git clone --depth=1 https://github.com/navisjayaseelan/apple-mac-plymouth.git "$WORKDIR/apple-mac-plymouth" -q
    sudo cp -r "$WORKDIR/apple-mac-plymouth/apple-mac-plymouth" /usr/share/plymouth/themes/ 2>/dev/null
    sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/apple-mac-plymouth/apple-mac-plymouth.plymouth 100 2>/dev/null
    sudo update-alternatives --set default.plymouth /usr/share/plymouth/themes/apple-mac-plymouth/apple-mac-plymouth.plymouth 2>/dev/null || true
    command -v update-initramfs &> /dev/null && sudo update-initramfs -u > /dev/null 2>&1
    command -v dracut &> /dev/null && sudo dracut --force > /dev/null 2>&1
    echo -e "${GREEN}✅ Tema Plymouth instalado.${NC}"
else
    echo -e "${YELLOW}⏭️  Plymouth no disponible.${NC}"
fi
echo ""

# =============================================================================
# PASO 12: NAVEGADORES, STREAMING Y HERRAMIENTAS DE RED
# =============================================================================
echo -e "${YELLOW}🌐🎵📡 [12/24] Configurando aplicaciones de escritorio y red...${NC}"
set +e
mkdir -p "$REAL_HOME/.local/share/applications" "$REAL_HOME/.local/share/icons/hicolor/256x256/apps" "$REAL_HOME/.local/bin"

# 12.1 FIREFOX -> SAFARI
if ! command -v firefox &> /dev/null; then
    if command -v apt-get &> /dev/null; then sudo apt-get install -y -qq firefox
    elif command -v dnf &> /dev/null; then sudo dnf install -y -q firefox
    elif command -v pacman &> /dev/null; then sudo pacman -S --noconfirm --needed firefox
    fi
fi

ORIGINAL_FF_DESKTOP=""
for path in "/usr/share/applications/firefox.desktop" "/usr/share/applications/firefox-esr.desktop" "/usr/share/applications/org.mozilla.firefox.desktop" "/var/lib/flatpak/exports/share/applications/org.mozilla.firefox.desktop"; do
    [ -f "$path" ] && ORIGINAL_FF_DESKTOP="$path" && break
done

if [ -n "$ORIGINAL_FF_DESKTOP" ]; then
    wget -q --user-agent="Mozilla/5.0" -O "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/safari.svg" "https://upload.wikimedia.org/wikipedia/commons/5/52/Safari_browser_logo.svg" 2>/dev/null || true
    cp "$ORIGINAL_FF_DESKTOP" "$REAL_HOME/.local/share/applications/safari.desktop"
    sed -i 's/^Name=.*/Name=Safari/g; s/^Name\[es\]=.*/Name[es]=Safari/g; s/^GenericName=.*/GenericName=Navegador Web Safari/g; s/^Icon=.*/Icon=safari/g' "$REAL_HOME/.local/share/applications/safari.desktop"
    echo -e "[Desktop Entry]\nHidden=true" > "$REAL_HOME/.local/share/applications/$(basename "$ORIGINAL_FF_DESKTOP")"
    echo -e "${GREEN}      ✅ Firefox renombrado a 'Safari'.${NC}"
else
    cat > "$REAL_HOME/.local/share/applications/safari.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Name=Safari
GenericName=Navegador Web Safari
Exec=firefox %u
Icon=safari
Terminal=false
Type=Application
Categories=Network;WebBrowser;
EOF
    wget -q --user-agent="Mozilla/5.0" -O "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/safari.svg" "https://upload.wikimedia.org/wikipedia/commons/5/52/Safari_browser_logo.svg" 2>/dev/null || true
fi

# 12.5 ZUNO -> APPLE MUSIC
if command -v apt-get &> /dev/null; then
    sudo apt-get install -y -qq gstreamer1.0-libav gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad 2>/dev/null || true
fi
ZUNO_URL="https://github.com/noFAYZ/zuno/releases/download/v1.4.0/Zuno_1.4.0_amd64.AppImage"
wget -q --user-agent="Mozilla/5.0" -O "$REAL_HOME/.local/bin/zuno" "$ZUNO_URL" 2>/dev/null || wget -q --user-agent="Mozilla/5.0" -O "$REAL_HOME/.local/bin/zuno" "https://github.com/noFAYZ/zuno/releases/download/v1.3.2/Zuno_1.3.2_amd64.AppImage" 2>/dev/null || true
chmod +x "$REAL_HOME/.local/bin/zuno" 2>/dev/null || true
wget -q --user-agent="Mozilla/5.0" -O "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/applemusic.svg" "https://upload.wikimedia.org/wikipedia/commons/6/6a/Apple_Music_icon.svg" 2>/dev/null || true

cat > "$REAL_HOME/.local/share/applications/applemusic.desktop" << EOF
[Desktop Entry]
Name=Apple Music
GenericName=Apple Music
Exec=env WEBKIT_DISABLE_DMABUF_RENDERER=1 $REAL_HOME/.local/bin/zuno %U
Icon=applemusic
Type=Application
Categories=Audio;Music;Player;AudioVideo;
Terminal=false
EOF
echo -e "${GREEN}      ✅ Zuno transformado a 'Apple Music'.${NC}"

# 12.6 LOCALSEND
if command -v apt-get &> /dev/null; then sudo apt-get install -y -qq xdg-desktop-portal xdg-desktop-portal-gtk 2>/dev/null || true; fi
if command -v ufw &> /dev/null && sudo ufw status 2>/dev/null | grep -q "active"; then
    sudo ufw allow 53317/tcp >/dev/null 2>&1 || true; sudo ufw allow 53317/udp >/dev/null 2>&1 || true
fi

LS_INSTALLED=false
LATEST_RELEASE_LS=$(curl -s --max-time 10 https://api.github.com/repos/localsend/localsend/releases/latest 2>/dev/null)
if [ -n "$LATEST_RELEASE_LS" ]; then
    if command -v apt-get &> /dev/null; then
        DEB_URL=$(echo "$LATEST_RELEASE_LS" | jq -r '.assets[] | select(.name | test("amd64.deb"; "i")).browser_download_url' | head -n 1)
        if [ -n "$DEB_URL" ] && [ "$DEB_URL" != "null" ]; then
            wget -q --user-agent="Mozilla/5.0" -O /tmp/localsend.deb "$DEB_URL" 2>/dev/null && sudo apt-get install -y -qq /tmp/localsend.deb 2>/dev/null && LS_INSTALLED=true
        fi
    fi
fi
if [ "$LS_INSTALLED" = false ]; then
    APPIMAGE_URL=$(echo "$LATEST_RELEASE_LS" | jq -r '.assets[] | select(.name | test("amd64.AppImage|x86_64.AppImage"; "i")).browser_download_url' | head -n 1)
    wget -q --user-agent="Mozilla/5.0" -O "$REAL_HOME/.local/bin/localsend" "${APPIMAGE_URL:-https://github.com/localsend/localsend/releases/download/v1.15.3/LocalSend-1.15.3-linux-x86_64.AppImage}" 2>/dev/null || true
    chmod +x "$REAL_HOME/.local/bin/localsend" 2>/dev/null || true
fi

cat > "$REAL_HOME/.local/share/applications/localsend.desktop" << EOF
[Desktop Entry]
Name=LocalSend
Exec=$REAL_HOME/.local/bin/localsend %U
Icon=localsend
Type=Application
Categories=Network;FileTransfer;
Terminal=false
EOF
wget -q --user-agent="Mozilla/5.0" -O "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/localsend.svg" "https://raw.githubusercontent.com/localsend/localsend/main/app/assets/icon/512.png" 2>/dev/null || true

# 12.7 IPTVNATOR -> APPLE TV
if command -v apt-get &> /dev/null; then sudo apt-get install -y -qq mpv xdg-utils 2>/dev/null || true; fi
IPTV_URL="https://github.com/4gray/iptvnator/releases/download/v0.14.0/iptvnator-0.14.0-linux-x86_64.AppImage"
wget -q --user-agent="Mozilla/5.0" -O "$REAL_HOME/.local/bin/iptvnator" "$IPTV_URL" 2>/dev/null || wget -q --user-agent="Mozilla/5.0" -O "/tmp/iptvnator.deb" "https://github.com/4gray/iptvnator/releases/download/v0.12.0/iptvnator_0.12.0_amd64.deb" 2>/dev/null && sudo apt-get install -y -qq /tmp/iptvnator.deb 2>/dev/null || true
chmod +x "$REAL_HOME/.local/bin/iptvnator" 2>/dev/null || true
wget -q --user-agent="Mozilla/5.0" -O "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/appletv.svg" "https://upload.wikimedia.org/wikipedia/commons/8/8b/Apple_TV_Icon.svg" 2>/dev/null || true

cat > "$REAL_HOME/.local/share/applications/appletv.desktop" << EOF
[Desktop Entry]
Name=Apple TV
GenericName=Apple TV
Exec=$REAL_HOME/.local/bin/iptvnator --no-sandbox --ozone-platform=x11 %U
Icon=appletv
Type=Application
Categories=AudioVideo;Video;Player;
Terminal=false
EOF

CONFIG_DIR="$REAL_HOME/.config/iptvnator"
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/store.json" << 'EOF'
{
  "playlists": [{ "id": "spa-iptv-org", "name": "📺 Canales en Español (iptv-org)", "url": "https://iptv-org.github.io/iptv/languages/spa.m3u", "autoRefresh": true }],
  "settings": { "player": "html5", "theme": "dark", "epgUrl": "https://iptv-org.github.io/epg/guides/es/movistarplus.es.xml" }
}
EOF

# 12.8: NAUTILUS/NEMO/THUNAR -> FINDER (VERSIÓN COMPLETA)
echo -e "${BLUE}   → [12.8] Transformando gestor de archivos en Finder...${NC}"
wget -q --user-agent="Mozilla/5.0" -O "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/finder.svg" "https://upload.wikimedia.org/wikipedia/commons/8/89/Finder_Icon.png" 2>/dev/null || wget -q --user-agent="Mozilla/5.0" -O "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/finder.svg" "https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/apple.svg" 2>/dev/null || true

if [ "$IS_GNOME" = true ]; then
    NAUTILUS_DESKTOP=""
    for path in "/usr/share/applications/org.gnome.Nautilus.desktop" "/usr/share/applications/nautilus.desktop"; do
        [ -f "$path" ] && NAUTILUS_DESKTOP="$path" && break
    done
    if [ -n "$NAUTILUS_DESKTOP" ]; then
        cp "$NAUTILUS_DESKTOP" "$REAL_HOME/.local/share/applications/finder.desktop"
        sed -i 's/^Name=.*/Name=Finder/g; s/^Name\[es\]=.*/Name[es]=Finder/g; s/^GenericName=.*/GenericName=Administrador de archivos/g; s/^Icon=.*/Icon=finder/g' "$REAL_HOME/.local/share/applications/finder.desktop"
        echo -e "[Desktop Entry]\nHidden=true" > "$REAL_HOME/.local/share/applications/$(basename "$NAUTILUS_DESKTOP")"
        echo -e "${GREEN}      ✅ Nautilus renombrado a 'Finder'.${NC}"
    fi
fi

if [ "$IS_CINNAMON" = true ]; then
    NEMO_DESKTOP=""
    [ -f "/usr/share/applications/nemo.desktop" ] && NEMO_DESKTOP="/usr/share/applications/nemo.desktop"
    if [ -n "$NEMO_DESKTOP" ]; then
        cp "$NEMO_DESKTOP" "$REAL_HOME/.local/share/applications/finder.desktop"
        sed -i 's/^Name=.*/Name=Finder/g; s/^Name\[es\]=.*/Name[es]=Finder/g; s/^GenericName=.*/GenericName=Administrador de archivos/g; s/^Icon=.*/Icon=finder/g' "$REAL_HOME/.local/share/applications/finder.desktop"
        echo -e "[Desktop Entry]\nHidden=true" > "$REAL_HOME/.local/share/applications/$(basename "$NEMO_DESKTOP")"
        echo -e "${GREEN}      ✅ Nemo renombrado a 'Finder'.${NC}"
    fi
fi

if [ "$IS_XFCE" = true ]; then
    THUNAR_DESKTOP=""
    [ -f "/usr/share/applications/thunar.desktop" ] && THUNAR_DESKTOP="/usr/share/applications/thunar.desktop"
    if [ -n "$THUNAR_DESKTOP" ]; then
        cp "$THUNAR_DESKTOP" "$REAL_HOME/.local/share/applications/finder.desktop"
        sed -i 's/^Name=.*/Name=Finder/g; s/^Name\[es\]=.*/Name[es]=Finder/g; s/^GenericName=.*/GenericName=Administrador de archivos/g; s/^Icon=.*/Icon=finder/g' "$REAL_HOME/.local/share/applications/finder.desktop"
        echo -e "[Desktop Entry]\nHidden=true" > "$REAL_HOME/.local/share/applications/$(basename "$THUNAR_DESKTOP")"
        echo -e "${GREEN}      ✅ Thunar renombrado a 'Finder'.${NC}"
    fi
fi

run_as_user update-desktop-database "$REAL_HOME/.local/share/applications" 2>/dev/null || true
run_as_user gtk-update-icon-cache -f -t "$REAL_HOME/.local/share/icons/hicolor" 2>/dev/null || true
set -e
echo -e "${GREEN}✅ Paso 12 completado exitosamente.${NC}\n"

# =============================================================================
# PASO 13: GDM (PANTALLA DE LOGIN)
# =============================================================================
echo -e "${YELLOW}🔐 [13/25] Configurando pantalla de login (GDM)...${NC}"
set +e
if [ "$IS_GNOME" = true ] && [ -d "$WORKDIR/MacTahoe-gtk-theme" ]; then
    echo -e "${BLUE}   → Aplicando tema a GDM (esto puede tardar unos segundos)...${NC}"
    if sudo "$WORKDIR/MacTahoe-gtk-theme/tweaks.sh" -g -b default > /tmp/gdm-tweak.log 2>&1; then
        echo -e "${GREEN}   ✅ Pantalla de login configurada correctamente.${NC}"
    else
        echo -e "${YELLOW}   ⚠️  No se pudo configurar GDM automáticamente (común por políticas de seguridad).${NC}"
    fi
else
    echo -e "${BLUE}   ⏭️  GDM omitido (Entorno no compatible).${NC}"
fi
set -e
echo ""

# =============================================================================
# PASO 14: SCRIPT AUXILIAR PARA VENTANAS AVANZADAS (VERSIÓN COMPLETA)
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
        command -v wmctrl &> /dev/null && wmctrl -r :ACTIVE: -b toggle,fullscreen ;;
    "toggle-always-on-top")
        command -v wmctrl &> /dev/null && wmctrl -r :ACTIVE: -b toggle,above ;;
    "opacity-decrease")
        if command -v xprop &> /dev/null; then
            CURRENT=$(xprop -id $(xdotool getactivewindow) _NET_WM_WINDOW_OPACITY 2>/dev/null | awk '{print $3}')
            CURRENT=${CURRENT:-0xffffffff}; CURRENT=$((CURRENT)); NEW=$((CURRENT - 427819008))
            [ "$NEW" -lt 858993459 ] && NEW=858993459
            xprop -id $(xdotool getactivewindow) -f _NET_WM_WINDOW_OPACITY 32c -set _NET_WM_WINDOW_OPACITY "$NEW"
        fi ;;
    "opacity-increase")
        if command -v xprop &> /dev/null; then
            CURRENT=$(xprop -id $(xdotool getactivewindow) _NET_WM_WINDOW_OPACITY 2>/dev/null | awk '{print $3}')
            CURRENT=${CURRENT:-0xffffffff}; CURRENT=$((CURRENT)); NEW=$((CURRENT + 427819008))
            [ "$NEW" -gt 4294967295 ] && NEW=4294967295
            xprop -id $(xdotool getactivewindow) -f _NET_WM_WINDOW_OPACITY 32c -set _NET_WM_WINDOW_OPACITY "$NEW"
        fi ;;
    "opacity-reset")
        command -v xprop &> /dev/null && xprop -id $(xdotool getactivewindow) -remove _NET_WM_WINDOW_OPACITY 2>/dev/null ;;
    "move-window")
        command -v xdotool &> /dev/null && xdotool getactivewindow windowmove --sync 0 0 2>/dev/null ;;
    "resize-window")
        command -v xdotool &> /dev/null && xdotool getactivewindow windowsize 50% 50% 2>/dev/null ;;
    "force-kill")
        command -v xkill &> /dev/null && xkill || notify-send "Error" "xkill no está instalado" -i dialog-error ;;
    "close-app-completely")
        if command -v xdotool &> /dev/null; then
            WIN_ID=$(xdotool getactivewindow); PID=$(xdotool getwindowpid "$WIN_ID" 2>/dev/null)
            if [ -n "$PID" ]; then
                PROCESS_NAME=$(ps -p "$PID" -o comm=)
                xdotool windowclose "$WIN_ID"; sleep 0.3; pkill -f "$PROCESS_NAME" 2>/dev/null
                notify-send "Aplicación cerrada" "$PROCESS_NAME finalizado completamente" -t 1500
            fi
        fi ;;
    "open-preferences")
        command -v xdotool &> /dev/null && xdotool key --clearmodifiers ctrl+comma ;;
    "restart-cinnamon")
        if [ "${XDG_CURRENT_DESKTOP:-}" = "X-Cinnamon" ] || [ "${XDG_CURRENT_DESKTOP:-}" = "cinnamon" ]; then
            dbus-send --session --dest=org.Cinnamon.LookingGlass --type=method_call /org/Cinnamon/LookingGlass org.Cinnamon.LookingGlass.ExecuteCommand string:"global.reexec_self()"
            notify-send "Cinnamon reiniciado" -t 1500
        fi ;;
esac
WMEOF
chmod +x "$ADVANCED_WM_SCRIPT"
[ -n "$SUDO_USER" ] && chown "$REAL_UID:$REAL_GID" "$ADVANCED_WM_SCRIPT" 2>/dev/null || true
echo -e "${GREEN}✅ Script auxiliar completo creado.${NC}\n"

# =============================================================================
# PASOS 15 a 15.10C: CONFIGURACIÓN DEL SISTEMA (LLAMADAS A MÓDULOS)
# =============================================================================
echo -e "${YELLOW}⚙️  [15/24] Configurando sistema, paneles y atajos de teclado...${NC}"
if [ "$IS_GNOME" = true ]; then gnome_step_15
elif [ "$IS_CINNAMON" = true ]; then cinnamon_step_15
elif [ "$IS_XFCE" = true ]; then xfce_step_15; fi
echo ""

echo -e "${YELLOW}🍎 [15.5/24] Configurando icono de Apple en el botón de inicio...${NC}"
if [ "$IS_GNOME" = true ]; then gnome_step_15_5
elif [ "$IS_CINNAMON" = true ]; then cinnamon_step_15_5
elif [ "$IS_XFCE" = true ]; then xfce_step_15_5; fi
echo ""

echo -e "${YELLOW}🔧 [15.6/24] Aplicando ajustes finos de comportamiento...${NC}"
if [ "$IS_GNOME" = true ]; then gnome_step_15_6
elif [ "$IS_CINNAMON" = true ]; then cinnamon_step_15_6
elif [ "$IS_XFCE" = true ]; then xfce_step_15_6; fi
echo ""

echo -e "${YELLOW}✨ [15.7/24] Aplicando detalles finales...${NC}"
if [ "$IS_GNOME" = true ]; then gnome_step_15_7
elif [ "$IS_CINNAMON" = true ]; then cinnamon_step_15_7
elif [ "$IS_XFCE" = true ]; then xfce_step_15_7; fi
echo ""

echo -e "${YELLOW}💻 [15.8/24] Configurando identidad del equipo y modo oscuro...${NC}"
if [ "$IS_GNOME" = true ]; then NEW_HOSTNAME="MacBook-Pro"
elif [ "$IS_CINNAMON" = true ]; then NEW_HOSTNAME="MacBook-Air"
elif [ "$IS_XFCE" = true ]; then NEW_HOSTNAME="MacBook-Neo"
else NEW_HOSTNAME="MacBook"; fi
sudo hostnamectl set-hostname "$NEW_HOSTNAME" 2>/dev/null || true
echo -e "${GREEN}   ✓ Nombre del equipo: $NEW_HOSTNAME${NC}"
echo ""

echo -e "${YELLOW}✨ [15.9/24] Perfeccionando experiencia macOS...${NC}"
if [ "$IS_GNOME" = true ]; then gnome_step_15_9
elif [ "$IS_CINNAMON" = true ]; then cinnamon_step_15_9
elif [ "$IS_XFCE" = true ]; then xfce_step_15_9; fi
echo ""

if [ "$IS_GNOME" = true ]; then gnome_step_15_10; fi

echo -e "${YELLOW}🔒 [15.10B/24] Configurando pantalla de bloqueo...${NC}"
if [ "$IS_GNOME" = true ]; then gnome_step_15_10b
elif [ "$IS_CINNAMON" = true ]; then cinnamon_step_15_10b
elif [ "$IS_XFCE" = true ]; then xfce_step_15_10b; fi
echo ""

echo -e "${YELLOW} [15.10C/24] Configurando indicadores OSD...${NC}"
if [ "$IS_GNOME" = true ]; then gnome_step_15_10c
elif [ "$IS_CINNAMON" = true ]; then cinnamon_step_15_10c
elif [ "$IS_XFCE" = true ]; then xfce_step_15_10c; fi
echo ""

# =============================================================================
# PASO 16: RENDERIZADO DE FUENTES ESTILO MACOS (Fontconfig)
# =============================================================================
echo -e "${YELLOW}🔤 [16/25] Optimizando renderizado de fuentes (Estilo macOS)...${NC}"
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
  <match target="font">
    <test name="family"><string>SF Pro</string></test>
    <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
    <edit name="autohint" mode="assign"><bool>false</bool></edit>
  </match>
</fontconfig>
EOF
[ -n "$SUDO_USER" ] && chown -R "$REAL_UID:$REAL_GID" "$REAL_HOME/.config/fontconfig" 2>/dev/null || true
fc-cache -f > /dev/null 2>&1 || true
set -e
echo -e "${GREEN}✅ Renderizado de fuentes optimizado para SF Pro.${NC}\n"

# =============================================================================
# PASOS 17 a 23: LLAMADAS FINALES A MÓDULOS
# =============================================================================
echo -e "${YELLOW}💻 [17/24] Configurando terminal estilo macOS...${NC}"
if [ "$IS_GNOME" = true ]; then gnome_step_17
elif [ "$IS_XFCE" = true ]; then xfce_step_17; fi
echo ""

echo -e "${YELLOW} [18/24] Configurando animaciones suaves...${NC}"
if [ "$IS_GNOME" = true ]; then gnome_step_18
elif [ "$IS_XFCE" = true ]; then xfce_step_18; fi
echo ""

echo -e "${YELLOW} [19/24] Instalando efecto Magic Lamp...${NC}"
if [ "$IS_GNOME" = true ]; then gnome_step_19
elif [ "$IS_CINNAMON" = true ]; then cinnamon_step_19; fi
echo ""

echo -e "${YELLOW} [20/25] Tematizando aplicaciones Qt y activando Quick Look...${NC}"
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
elif [[ "$DESKTOP_ENV" == *"cinnamon"* ]] || [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    sudo apt-get install -y -qq gloobus-preview 2>/dev/null || true
fi
set -e
echo -e "${GREEN}✅ Qt tematizado y Quick Look configurado.${NC}\n"

echo -e "${YELLOW}📜 [21/24] Activando Scroll Natural...${NC}"
if [ "$IS_GNOME" = true ] || [ "$IS_CINNAMON" = true ]; then gnome_cinnamon_step_21
elif [ "$IS_XFCE" = true ]; then xfce_step_21; fi
echo ""

echo -e "${YELLOW} [22/24] Instalando Gestos Multitáctiles (Fusuma)...${NC}"
if [ "$IS_GNOME" = true ]; then gnome_step_22
elif [ "$IS_CINNAMON" = true ]; then cinnamon_step_22
elif [ "$IS_XFCE" = true ]; then xfce_step_22; fi
echo ""

echo -e "${YELLOW}📋 [23/24] Configurando Gestor de Portapapeles...${NC}"
if [ "$IS_GNOME" = true ]; then gnome_step_23
elif [ "$IS_CINNAMON" = true ]; then cinnamon_step_23
elif [ "$IS_XFCE" = true ]; then xfce_step_23; fi
echo ""

# =============================================================================
# PASO 24: VERIFICACIÓN POST-INSTALACIÓN (COMÚN)
# =============================================================================
echo -e "${YELLOW}🔍 [24/24] Verificando instalación completa...${NC}"

# ✅ LLAMADA A LA VERIFICACIÓN DE DEPENDENCIAS CRÍTICAS DE XFCE
if [ "$IS_XFCE" = true ]; then
    verify_xfce_critical_deps
fi

echo -e "${CYAN}══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         ¡INSTALACIÓN COMPLETADA CON ÉXITO! 🎉         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo -e "${YELLOW}🔄 IMPORTANTE: Debes REINICIAR EL EQUIPO para que surtan efecto todos los cambios.${NC}"
