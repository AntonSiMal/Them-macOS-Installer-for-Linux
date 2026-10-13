#!/bin/bash

# =============================================================================
# macOS Tahoe Auto-Installer - Versión WWDC26 (Ultimate Edition)
# Compatible con: GNOME / Zorin OS / Cinnamon / XFCE
# =============================================================================

set -e
set +u  # Desactivar modo estricto de variables no asignadas

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

# Variables de configuración
MACOS_VERSION="Tahoe"
GTK_THEME="MacTahoe-Dark"
SHELL_THEME="MacTahoe-Dark"
ICON_THEME="MacTahoe-dark"
CURSOR_THEME="MacTahoe-dark"
SOUND_THEME="bigsur"
UI_FONT="SF Pro Text 11"
MONO_FONT="SF Mono Regular 11"
SERIF_FONT="New York Medium 11"
PLANK_THEME="MacOS-BigSur-Dark"

# Usar REAL_HOME para WORKDIR (NO $HOME que sería /root con sudo)
WORKDIR="$REAL_HOME/.macos-theme-setup"
LOG_FILE="$WORKDIR/install.log"

mkdir -p "$WORKDIR"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Iniciando instalación de macOS Tahoe Theme" > "$LOG_FILE"

echo -e "${CYAN}══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🍎 macOS Tahoe Theme Installer - Ultimate Edition     ║${NC}"
echo -e "${CYAN}║   Instalación 100% automatizada (25 pasos)              ${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# =============================================================================
# 🛡️ MECANISMO DE SEGURIDAD: ROLLBACK AUTOMÁTICO EN CASO DE ERROR
# =============================================================================
INSTALLATION_SUCCESS=false
ROLLBACK_SCRIPT="$WORKDIR/uninstall_rollback.sh"
UNINSTALL_URL="https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/uninstall.sh"

echo -e "${BLUE}🛡️  [0/24] Descargando script de restauración de emergencia...${NC}"
if curl -sSL "$UNINSTALL_URL" -o "$ROLLBACK_SCRIPT" 2>/dev/null; then
    chmod +x "$ROLLBACK_SCRIPT"
    echo -e "${GREEN}✅ Script de restauración guardado localmente. Sistema protegido.${NC}"
else
    echo -e "${YELLOW}⚠️  No se pudo descargar el script de restauración. La limpieza automática podría no estar disponible si falla la instalación.${NC}"
fi

cleanup_on_error() {
    local exit_code=$?
    # Fallback por si BASH_COMMAND no está disponible en este entorno
    local failed_command="${BASH_COMMAND:-Comando ejecutado justo antes del fallo}"
    local line_number="${BASH_LINENO[0]:-Desconocida}"

    echo -e "\n${RED}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   ❌ EL SCRIPT SE DETUVO INESPERADAMENTE                ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}📍 Último comando ejecutado antes del fallo:${NC}"
    echo -e "   ${RED}$failed_command${NC}"
    echo -e "   (Línea aproximada del script: $line_number)"
    echo -e "   (Código de salida: $exit_code)"
    echo ""
    echo -e "${YELLOW}📝 Para ver el detalle completo del error, revisa el log:${NC}"
    echo -e "   ${BLUE}tail -n 20 $LOG_FILE${NC}"
    echo ""
    echo -e "${YELLOW}💡 Causas más comunes:${NC}"
    echo -e "   1. Ejecutaste 'sudo curl ... | bash' en lugar de 'curl ... | sudo bash'"
    echo -e "   2. Se acabó el espacio en disco o se cayó la conexión a internet."
    echo -e "   3. El sistema pidió contraseña de sudo y se agotó el tiempo de espera."
    echo ""
    echo -e "${YELLOW}🔄 Ejecutando restauración del sistema para evitar conflictos...${NC}"
    
    if [ -f "$ROLLBACK_SCRIPT" ]; then
        bash "$ROLLBACK_SCRIPT" --auto
        echo -e "${RED}❌ La instalación ha sido revertida. Corrige el error e inténtalo de nuevo.${NC}"
    else
        echo -e "${RED}❌ No se pudo ejecutar la restauración automática.${NC}"
        echo -e "${YELLOW}Ejecuta manualmente: curl -sSL https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/uninstall.sh | sudo bash -s -- --auto${NC}"
    fi
    exit 1
}

# =============================================================================
# DETECCIÓN DEL ENTORNO
# =============================================================================
DESKTOP_ENV=$(echo "${XDG_CURRENT_DESKTOP:-unknown}" | tr '[:upper:]' '[:lower:]')
SESSION_TYPE="${XDG_SESSION_TYPE:-unknown}"
DISTRO=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')
fi

IS_GNOME=false; IS_CINNAMON=false
[[ "$DESKTOP_ENV" == *"gnome"* ]] || [[ "$DISTRO" == *"zorin"* ]] && IS_GNOME=true
[[ "$DESKTOP_ENV" == *"cinnamon"* ]] || [[ "$DISTRO" == *"mint"* && "$DESKTOP_ENV" != *"xfce"* ]] && IS_CINNAMON=true

if command -v xrandr &> /dev/null; then
    SCREEN_WIDTH=$(xrandr --current | grep '*' | head -1 | awk '{print $1}' | cut -d'x' -f1)
    [ -n "$SCREEN_WIDTH" ] && {
        if [ "$SCREEN_WIDTH" -ge 3840 ]; then SCREEN_VARIANT="4k"; ICON_BOLD_FLAG="-b"
        elif [ "$SCREEN_WIDTH" -ge 2560 ]; then SCREEN_VARIANT="2k"; ICON_BOLD_FLAG=""
        else SCREEN_VARIANT="1080p"; ICON_BOLD_FLAG=""; fi
    } || { SCREEN_VARIANT="4k"; ICON_BOLD_FLAG="-b"; }
else
    SCREEN_VARIANT="4k"; ICON_BOLD_FLAG="-b"
fi

HAS_FLATPAK=false; command -v flatpak &> /dev/null && HAS_FLATPAK=true
HAS_DASH_TO_DOCK=false
[ -d "$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com" ] || \
[ -d "/usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com" ] && HAS_DASH_TO_DOCK=true


# =============================================================================
# PASO 1: DEPENDENCIAS DEL SISTEMA (100% ESTABLE)
# =============================================================================
echo -e "${YELLOW}📦 [1/24] Instalando dependencias del sistema...${NC}"

# Forzar modo no interactivo para evitar la pantalla morada de gdm3
export DEBIAN_FRONTEND=noninteractive

if command -v apt-get &> /dev/null; then
    echo -e "${BLUE}   → Pre-configurando gestor de sesiones (gdm3)...${NC}"
    echo "gdm3 shared/default-x-display-manager select gdm3" | sudo debconf-set-selections 2>/dev/null || true
    echo "gdm3 shared/default-x-display-manager seen true" | sudo debconf-set-selections 2>/dev/null || true
    
    echo -e "${BLUE}   → Actualizando repositorios...${NC}"
    sudo apt-get update -qq || {
        echo -e "${RED}   ✗ Error al actualizar repositorios. Verifica tu conexión a internet.${NC}"
        exit 1
    }
    
    echo -e "${BLUE}   → Instalando paquetes base (esto puede tardar unos minutos)...${NC}"
    
    # Lista de paquetes probados y estables en Ubuntu/Zorin/Debian
    PACKAGES=(
        git sassc libglib2.0-dev-bin libxml2-utils fontconfig
        gnome-tweaks gnome-shell-extension-manager dconf-cli plymouth-themes firefox
        plank x11-xserver-utils python3-pil curl unzip wget jq gnome-backgrounds
        ffmpeg sox rofi fd-find python3-requests xdotool wmctrl x11-utils util-linux
        qt5ct qt6ct ruby libinput-tools clipit xfce4-clipman-plugin gnome-sushi
    )
    
    # Forzamos la aceptación de configuraciones por defecto
    sudo apt-get install -y -qq \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
        "${PACKAGES[@]}" 2>/dev/null || {
        
        echo -e "${YELLOW}   ⚠️  Algunos paquetes opcionales no se pudieron instalar.${NC}"
        echo -e "${YELLOW}      (No te preocupes, el script continuará con el resto de la instalación)${NC}"
    }
    
    echo -e "${GREEN}   ✅ Paquetes base instalados.${NC}"

elif command -v dnf &> /dev/null; then
    echo -e "${BLUE}   → Instalando paquetes (Fedora)...${NC}"
    sudo dnf install -y -q git sassc glib2-devel libxml2 fontconfig gnome-tweaks dconf \
        plymouth-theme-spinner firefox plank xorg-x11-server-utils python3-pillow curl \
        unzip wget jq gnome-backgrounds ffmpeg sox rofi fd-find python3-requests xdotool \
        wmctrl xorg-xprop xorg-xwininfo util-linux qt5ct qt6ct ruby libinput \
        clipit xfce4-clipman-plugin gnome-sushi 2>/dev/null || true
        
elif command -v pacman &> /dev/null; then
    echo -e "${BLUE}   → Instalando paquetes (Arch)...${NC}"
    sudo pacman -S --noconfirm --needed git sassc glib2 libxml2 fontconfig gnome-tweaks \
        dconf plymouth firefox plank xorg-xrandr python-pillow curl unzip wget jq \
        gnome-backgrounds ffmpeg sox rofi fd python-requests xdotool wmctrl xorg-xprop \
        xorg-xwininfo util-linux qt5ct qt6ct ruby libinput \
        clipit xfce4-clipman-plugin gnome-sushi 2>/dev/null || true
else
    echo -e "${RED}    No se detectó un gestor de paquetes compatible (apt, dnf, pacman)${NC}"
    exit 1
fi

# Restaurar el entorno
unset DEBIAN_FRONTEND
echo -e "${GREEN}✅ Dependencias listas.${NC}"
echo ""

# =============================================================================
# PASO 2: FUENTES OFICIALES DE APPLE (SFWindows WWDC26)
# =============================================================================
echo -e "${YELLOW}🔤 [2/24] Instalando fuentes oficiales de Apple (WWDC26)...${NC}"
FONTS_DIR="$HOME/.local/share/fonts"
SF_TEMP="$WORKDIR/sf-windows-temp"
mkdir -p "$FONTS_DIR" "$SF_TEMP"

SF_INSTALLED=false
SF_PRO_URL="https://github.com/bradleyhodges/SFWindows/raw/refs/heads/main/SF%20Pro/SF-Pro.ttf"
SF_COMPACT_URL="https://github.com/bradleyhodges/SFWindows/raw/refs/heads/main/SF%20Compact/SF-Compact.ttf"
NEW_YORK_URL="https://github.com/bradleyhodges/SFWindows/raw/refs/heads/main/New%20York/NewYork.ttf"

download_font() {
    local url="${1:-}" output="${2:-}" name="${3:-}"
    if [ -z "$url" ] || [ -z "$output" ] || [ -z "$name" ]; then return 1; fi
    if curl -L "$url" -o "$output" --silent --fail --max-time 60 2>/dev/null; then
        if file "$output" | grep -q "TrueType\|OpenType\|font"; then
            echo -e "   ${GREEN}✓ $name descargada${NC}"
            return 0
        fi
    fi
    return 1
}

if download_font "$SF_PRO_URL" "$SF_TEMP/SF-Pro.ttf" "SF Pro" && \
   download_font "$SF_COMPACT_URL" "$SF_TEMP/SF-Compact.ttf" "SF Compact" && \
   download_font "$NEW_YORK_URL" "$SF_TEMP/NewYork.ttf" "New York"; then
    
    cp "$SF_TEMP/SF-Pro.ttf" "$FONTS_DIR/" 2>/dev/null
    cp "$SF_TEMP/SF-Compact.ttf" "$FONTS_DIR/" 2>/dev/null
    cp "$SF_TEMP/NewYork.ttf" "$FONTS_DIR/" 2>/dev/null
    
    SF_REPO="$WORKDIR/SFWindows"
    [ ! -d "$SF_REPO" ] && git clone --depth=1 https://github.com/bradleyhodges/SFWindows.git "$SF_REPO" -q 2>/dev/null
    
    [ -d "$SF_REPO/SF Mono" ] && find "$SF_REPO/SF Mono" -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec cp {} "$FONTS_DIR/" \; 2>/dev/null
    [ -d "$SF_REPO/SF Multilingual Extensions" ] && find "$SF_REPO/SF Multilingual Extensions" -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec cp {} "$FONTS_DIR/" \; 2>/dev/null
    
    SF_INSTALLED=true
else
    SF_REPO="$WORKDIR/SFWindows"
    [ ! -d "$SF_REPO" ] && git clone --depth=1 https://github.com/bradleyhodges/SFWindows.git "$SF_REPO" -q 2>/dev/null
    [ -d "$SF_REPO" ] && find "$SF_REPO" -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec cp {} "$FONTS_DIR/" \; 2>/dev/null
    SF_INSTALLED=true
fi

fc-cache -f "$FONTS_DIR" > /dev/null 2>&1
[ "$SF_INSTALLED" = true ] && echo -e "${GREEN}✅ Fuentes oficiales Apple instaladas.${NC}"
rm -rf "$SF_TEMP"
echo ""

# =============================================================================
# PASO 3: EXTENSIÓN LIQUID GLASS (SOLO GNOME/ZORIN)
# =============================================================================
IS_GNOME=false
if [[ "$DESKTOP_ENV" == *"gnome"* ]] || [[ "$DISTRO" == *"zorin"* ]]; then
    IS_GNOME=true
    echo -e "${YELLOW}🧩 [3/24] Instalando extensión 'Liquid Glass'...${NC}"
    mkdir -p ~/.local/share/gnome-shell/extensions/

    [ ! -d "$WORKDIR/liquid-glass" ] && git clone --depth=1 https://github.com/ryohsuke1231/liquid-glass.git "$WORKDIR/liquid-glass" -q
    cp -r "$WORKDIR/liquid-glass/liquid-glass@thinkingcoding1231.gmail.com" ~/.local/share/gnome-shell/extensions/

    GNOME_VERSION=$(gnome-shell --version 2>/dev/null | grep -oP '\d+' | head -1)
    EXT_DIR=~/.local/share/gnome-shell/extensions/liquid-glass@thinkingcoding1231.gmail.com
    if [ -n "$GNOME_VERSION" ] && [ -f "$EXT_DIR/metadata.json" ]; then
        if ! grep -q "\"$GNOME_VERSION\"" "$EXT_DIR/metadata.json"; then
            python3 -c "
import json
with open('$EXT_DIR/metadata.json', 'r') as f: data = json.load(f)
if '$GNOME_VERSION' not in data.get('shell-version', []):
    data.setdefault('shell-version', []).append('$GNOME_VERSION')
    with open('$EXT_DIR/metadata.json', 'w') as f: json.dump(data, f, indent=2)
" 2>/dev/null
        fi
    fi
    echo -e "${GREEN}✅ Liquid Glass instalada.${NC}"
else
    echo -e "${YELLOW}⏭️  [3/24] Liquid Glass omitida.${NC}"
fi
echo ""

# =============================================================================
# PASO 4: EXTENSIÓN CINNAMON DYNAMIC WALLPAPER (SOLO CINNAMON)
# =============================================================================
IS_CINNAMON=false
if [[ "$DESKTOP_ENV" == *"cinnamon"* ]] || [[ "$DISTRO" == *"mint"* && "$DESKTOP_ENV" != *"xfce"* ]]; then
    IS_CINNAMON=true
    echo -e "${YELLOW}🌅 [4/24] Instalando extensión 'Cinnamon Dynamic Wallpaper'...${NC}"
    mkdir -p ~/.local/share/cinnamon/extensions/

    [ ! -d "$WORKDIR/cinnamon-dynamic-wallpaper" ] && git clone --depth=1 https://github.com/TobiZog/cinnamon-dynamic-wallpaper.git "$WORKDIR/cinnamon-dynamic-wallpaper" -q
    cp -r "$WORKDIR/cinnamon-dynamic-wallpaper/cinnamon-dynamic-wallpaper@TobiZog" ~/.local/share/cinnamon/extensions/ 2>/dev/null

    CINNAMON_EXTENSIONS=$(gsettings get org.cinnamon enabled-extensions 2>/dev/null)
    if ! echo "$CINNAMON_EXTENSIONS" | grep -q "cinnamon-dynamic-wallpaper@TobiZog"; then
        if [ "$CINNAMON_EXTENSIONS" = "[]" ]; then
            gsettings set org.cinnamon enabled-extensions "['cinnamon-dynamic-wallpaper@TobiZog']" 2>/dev/null
        else
            NEW_EXTENSIONS=$(echo "$CINNAMON_EXTENSIONS" | sed "s/]$/, 'cinnamon-dynamic-wallpaper@TobiZog']/")
            gsettings set org.cinnamon enabled-extensions "$NEW_EXTENSIONS" 2>/dev/null
        fi
    fi
    echo -e "${GREEN}✅ Cinnamon Dynamic Wallpaper instalada.${NC}"
else
    echo -e "${YELLOW}⏭️  [4/24] Cinnamon Dynamic Wallpaper omitida.${NC}"
fi
echo ""

# =============================================================================
# PASO 5: TEMA GTK + ICONOS + CURSORES (macOS Tahoe)
# =============================================================================
echo -e "${YELLOW}🎨 [5/24] Instalando tema, iconos y cursores macOS Tahoe...${NC}"

[ ! -d "$WORKDIR/MacTahoe-gtk-theme" ] && git clone --depth=1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git "$WORKDIR/MacTahoe-gtk-theme" -q
[ ! -d "$WORKDIR/MacTahoe-icon-theme" ] && git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git "$WORKDIR/MacTahoe-icon-theme" -q

INSTALL_FLAGS="-c dark --silent-mode --round --darker"
if [ "$IS_GNOME" = true ]; then
    INSTALL_FLAGS="$INSTALL_FLAGS -l"
    if [ -d "$HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx" ] || [ -d "/usr/share/gnome-shell/extensions/blur-my-shell@aunetx" ]; then
        INSTALL_FLAGS="$INSTALL_FLAGS -b"
    fi
fi

( cd "$WORKDIR/MacTahoe-gtk-theme" && ./install.sh $INSTALL_FLAGS > /dev/null 2>&1 )
[ -n "$ICON_BOLD_FLAG" ] && ( cd "$WORKDIR/MacTahoe-icon-theme" && ./install.sh $ICON_BOLD_FLAG > /dev/null 2>&1 ) || ( cd "$WORKDIR/MacTahoe-icon-theme" && ./install.sh > /dev/null 2>&1 )

[ "$HAS_FLATPAK" = true ] && ( cd "$WORKDIR/MacTahoe-gtk-theme" && ./tweaks.sh -F -c dark > /dev/null 2>&1 )
[ "$HAS_DASH_TO_DOCK" = true ] && [ "$IS_GNOME" = true ] && ( cd "$WORKDIR/MacTahoe-gtk-theme" && ./tweaks.sh -d > /dev/null 2>&1 )

echo -e "${GREEN}✅ Tema GTK, Iconos y Cursores MacTahoe instalados correctamente.${NC}"
echo ""

# =============================================================================
# PASO 6: WALLPAPER DINÁMICO MOJAVE CON HORARIOS REALES
# =============================================================================
MOJAVE_INSTALLED=false
if [ "$IS_GNOME" = true ]; then
    echo -e "${YELLOW}🌄 [6/24] Instalando wallpaper dinámico Mojave...${NC}"
    MOJAVE_TEMP="$WORKDIR/gnome-kde-mojave-dynamic"
    [ ! -d "$MOJAVE_TEMP" ] && git clone --depth=1 https://github.com/japamax/gnome-kde-dynamic-wallpaper-mojave.git "$MOJAVE_TEMP" -q 2>/dev/null
    
    if [ -d "$MOJAVE_TEMP/mojave" ] && [ -f "$MOJAVE_TEMP/mojave-timed.xml" ]; then
        sudo mkdir -p /usr/share/dynamicwallpapers/mojave-solar/contents/images
        sudo cp "$MOJAVE_TEMP/mojave/"* /usr/share/dynamicwallpapers/mojave-solar/contents/images/ 2>/dev/null
        sudo chmod 755 /usr/share/dynamicwallpapers/mojave-solar/contents/images 2>/dev/null
        sudo chmod 644 /usr/share/dynamicwallpapers/mojave-solar/contents/images/* 2>/dev/null
        
        sudo mkdir -p /usr/share/dynamicwallpapers/mojave-timed/contents
        sudo chmod 755 /usr/share/dynamicwallpapers/mojave-timed/contents 2>/dev/null
        sudo ln -sf /usr/share/dynamicwallpapers/mojave-solar/contents/images /usr/share/dynamicwallpapers/mojave-timed/contents/images 2>/dev/null
        
        sudo mkdir -p /usr/share/backgrounds/macOS
        sudo ln -sf /usr/share/dynamicwallpapers/mojave-solar/contents/images /usr/share/backgrounds/macOS/mojave 2>/dev/null
        
        [ -f "$MOJAVE_TEMP/mojave-solar.json" ] && sudo cp "$MOJAVE_TEMP/mojave-solar.json" /usr/share/dynamicwallpapers/mojave-solar/metadata.json 2>/dev/null
        [ -f "$MOJAVE_TEMP/mojave-timed.json" ] && sudo cp "$MOJAVE_TEMP/mojave-timed.json" /usr/share/dynamicwallpapers/mojave-timed/metadata.json 2>/dev/null
        [ -f "$MOJAVE_TEMP/mojave-timed.xml" ] && sudo cp "$MOJAVE_TEMP/mojave-timed.xml" /usr/share/backgrounds/macOS/mojave-timed.xml 2>/dev/null
        
        sudo mkdir -p /usr/share/gnome-background-properties
        [ -f "$MOJAVE_TEMP/mojave.xml" ] && sudo cp "$MOJAVE_TEMP/mojave.xml" /usr/share/gnome-background-properties/mojave.xml 2>/dev/null
        
        MOJAVE_INSTALLED=true
        echo -e "${GREEN}✅ Wallpaper Mojave con horarios reales instalado.${NC}"
    else
        echo -e "${YELLOW}⚠️  No se pudo descargar Mojave dinámico.${NC}"
    fi
else
    echo -e "${YELLOW}⏭️  [6/24] Mojave dinámico omitido.${NC}"
fi
echo ""


# =============================================================================
# PASO 7: WALLPAPERS SONOMA (RESPALDO)
# =============================================================================
echo -e "${YELLOW}🖼️  [7/24] Instalando wallpapers macOS Sonoma...${NC}"
[ ! -d "$WORKDIR/WhiteSur-wallpapers" ] && git clone --depth=1 https://github.com/vinceliuice/WhiteSur-wallpapers.git "$WORKDIR/WhiteSur-wallpapers" -q

if [ "$IS_GNOME" = true ]; then
    ( cd "$WORKDIR/WhiteSur-wallpapers" && ./install-gnome-backgrounds.sh -t sonoma -s "$SCREEN_VARIANT" > /dev/null 2>&1 )
else
    ( cd "$WORKDIR/WhiteSur-wallpapers" && ./install-wallpapers.sh -t sonoma -c dark -s "$SCREEN_VARIANT" > /dev/null 2>&1 )
fi
echo -e "${GREEN}✅ Wallpapers macOS Sonoma instalados.${NC}"
echo ""

# =============================================================================
# PASO 8: SONIDOS DEL SISTEMA DE macOS BIG SUR (DESCARGA DIRECTA DE ZIP)
# =============================================================================
echo -e "${YELLOW}🔊 [8/24] Instalando sonidos del sistema macOS Big Sur...${NC}"

# Detectar usuario real si no está definido
if [ -z "$REAL_HOME" ]; then
    if [ -n "$SUDO_USER" ]; then
        REAL_HOME=$(eval echo "~$SUDO_USER")
    else
        REAL_HOME="$HOME"
    fi
fi

SOUNDS_DIR="$REAL_HOME/.local/share/sounds"
SOUND_INSTALLED=false

# Crear directorio en la home del usuario real
mkdir -p "$SOUNDS_DIR" 2>/dev/null || true

echo -e "${BLUE}   → Descargando sonidos desde GitHub (rama main)...${NC}"

ZIP_URL="https://github.com/gxanshu/macos-bigsur-sound-theme-linux/archive/refs/heads/main.zip"
ZIP_FILE="/tmp/bigsur-sounds-main.zip"
EXTRACT_DIR="/tmp/bigsur-sounds-extract"

# Limpiar archivos anteriores si existen
rm -f "$ZIP_FILE" 2>/dev/null
rm -rf "$EXTRACT_DIR" 2>/dev/null

# Descargar el ZIP
if curl -sL "$ZIP_URL" --max-time 60 -o "$ZIP_FILE" 2>/dev/null && [ -s "$ZIP_FILE" ]; then
    echo -e "${BLUE}   → Extrayendo archivo ZIP...${NC}"
    
    # Extraer el ZIP
    if unzip -q "$ZIP_FILE" -d "$EXTRACT_DIR" 2>/dev/null; then
        # La carpeta extraída: macos-bigsur-sound-theme-linux-main/theme/bigsur
        SOURCE_DIR="$EXTRACT_DIR/macos-bigsur-sound-theme-linux-main/theme/bigsur"
        
        if [ -d "$SOURCE_DIR" ] && [ -f "$SOURCE_DIR/index.theme" ]; then
            echo -e "${BLUE}   → Copiando sonidos a $SOUNDS_DIR...${NC}"
            cp -r "$SOURCE_DIR" "$SOUNDS_DIR/" 2>/dev/null
            
            if [ -d "$SOUNDS_DIR/bigsur" ]; then
                SOUND_INSTALLED=true
                echo -e "${GREEN}   ✅ Sonidos instalados correctamente.${NC}"
                
                # Ajustar permisos para el usuario real
                if [ -n "$SUDO_USER" ]; then
                    chown -R "$SUDO_USER:$SUDO_USER" "$SOUNDS_DIR/bigsur" 2>/dev/null || true
                fi
            else
                echo -e "${YELLOW}   ⚠️  Error al copiar la carpeta de sonidos.${NC}"
            fi
        else
            echo -e "${YELLOW}   ️  No se encontró la carpeta 'theme/bigsur' en el ZIP.${NC}"
            echo -e "${BLUE}   → Estructura encontrada:${NC}"
            ls -la "$EXTRACT_DIR/macos-bigsur-sound-theme-linux-main/" 2>/dev/null || true
        fi
    else
        echo -e "${YELLOW}   ⚠️  Error al extraer el archivo ZIP.${NC}"
    fi
else
    echo -e "${YELLOW}   ⚠️  No se pudo descargar el archivo ZIP.${NC}"
fi

# Limpieza de archivos temporales
rm -f "$ZIP_FILE" 2>/dev/null
rm -rf "$EXTRACT_DIR" 2>/dev/null

# Verificación final
if [ "$SOUND_INSTALLED" = true ]; then
    echo -e "${GREEN}   ✅ Directorio de sonidos verificado en: $SOUNDS_DIR/bigsur${NC}"
else
    echo -e "${YELLOW}   ️  No se pudieron instalar los sonidos automáticamente.${NC}"
    echo -e "${YELLOW}      (Es un componente opcional, el script continuará)${NC}"
fi

echo ""

# =============================================================================
# PASO 9: ROFI SPOTLIGHT (LANZADOR ESTILO macOS)
# =============================================================================
echo -e "${YELLOW}🔍 [9/24] Instalando Rofi Spotlight...${NC}"

# Usar la home del usuario real, no de root
ROFI_SPOTLIGHT_DIR="$REAL_HOME/.local/share/rofi-spotlight"
ROFI_THEMES_DIR="$REAL_HOME/.local/share/rofi/themes"
ROFI_BIN_DIR="$REAL_HOME/.local/bin"
ROFI_APPS_DIR="$REAL_HOME/.local/share/applications"

# Crear TODOS los directorios necesarios
mkdir -p "$ROFI_SPOTLIGHT_DIR" "$ROFI_THEMES_DIR" "$ROFI_BIN_DIR" "$ROFI_APPS_DIR"

echo -e "${BLUE}   → Clonando Rofi Spotlight...${NC}"
if [ ! -d "$WORKDIR/rofi-spotlight" ]; then
    if ! git clone --depth=1 https://github.com/eromatiya/rofi-spotlight.git "$WORKDIR/rofi-spotlight" -q 2>/dev/null; then
        echo -e "${YELLOW}   ️  No se pudo clonar rofi-spotlight.${NC}"
        echo -e "${BLUE}   → Continuando sin Rofi Spotlight...${NC}"
        echo ""
        continue 2>/dev/null || true
    fi
fi

if [ -d "$WORKDIR/rofi-spotlight" ]; then
    cp -r "$WORKDIR/rofi-spotlight"/* "$ROFI_SPOTLIGHT_DIR/" 2>/dev/null
    chmod +x "$ROFI_SPOTLIGHT_DIR/rofi-spotlight.sh" "$ROFI_SPOTLIGHT_DIR/web-search.py" 2>/dev/null
    echo -e "${GREEN}   ✅ Rofi Spotlight clonado.${NC}"
fi

echo -e "${BLUE}   → Instalando temas de Rofi...${NC}"
if [ ! -d "$WORKDIR/rofi-themes-collection" ]; then
    git clone --depth=1 https://github.com/newmanls/rofi-themes-collection.git "$WORKDIR/rofi-themes-collection" -q 2>/dev/null || true
fi
[ -d "$WORKDIR/rofi-themes-collection/themes" ] && cp "$WORKDIR/rofi-themes-collection/themes/"*.rasi "$ROFI_THEMES_DIR/" 2>/dev/null || true

echo -e "${BLUE}   → Creando lanzador...${NC}"
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

echo -e "${BLUE}   → Creando archivo .desktop...${NC}"
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

# Asegurar permisos correctos para el usuario real
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.local/share/rofi-spotlight" 2>/dev/null || true
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.local/share/rofi" 2>/dev/null || true
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.local/bin" 2>/dev/null || true

echo -e "${GREEN}✅ Rofi Spotlight instalado.${NC}"
echo ""

# =============================================================================
# PASO 10: TEMAS DE PLANK
# =============================================================================
echo -e "${YELLOW}🚀 [10/24] Instalando temas de Plank...${NC}"
[ ! -d "$WORKDIR/MacOS-Mojave-Plank-themes" ] && git clone --depth=1 https://github.com/Macintosh98/MacOS-Mojave-Plank-themes.git "$WORKDIR/MacOS-Mojave-Plank-themes" -q
mkdir -p ~/.local/share/plank/themes
find "$WORKDIR/MacOS-Mojave-Plank-themes" -maxdepth 1 -type d \( -name "MacOS-*" -o -name "elementary-*" \) | while read -r theme_dir; do
    [ -d "$theme_dir" ] && cp -r "$theme_dir" ~/.local/share/plank/themes/
done
echo -e "${GREEN}✅ Temas de Plank instalados.${NC}"
echo ""

# =============================================================================
# PASO 11: TEMA PLYMOUTH (PANTALLA DE ARRANQUE)
# =============================================================================
echo -e "${YELLOW}🖥️  [11/24] Instalando tema Plymouth...${NC}"
if command -v plymouth &> /dev/null || [ -d /usr/share/plymouth/themes ]; then
    [ ! -d "$WORKDIR/apple-mac-plymouth" ] && git clone --depth=1 https://github.com/navisjayaseelan/apple-mac-plymouth.git "$WORKDIR/apple-mac-plymouth" -q
    
    sudo cp -r "$WORKDIR/apple-mac-plymouth/apple-mac-plymouth" /usr/share/plymouth/themes/ 2>/dev/null
    sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/apple-mac-plymouth/apple-mac-plymouth.plymouth 100 2>/dev/null
    
    # Usar --set en lugar de --config para evitar el menú interactivo morado
    sudo update-alternatives --set default.plymouth /usr/share/plymouth/themes/apple-mac-plymouth/apple-mac-plymouth.plymouth 2>/dev/null || true
    
    command -v update-initramfs &> /dev/null && sudo update-initramfs -u > /dev/null 2>&1
    command -v dracut &> /dev/null && sudo dracut --force > /dev/null 2>&1
    echo -e "${GREEN}✅ Tema Plymouth instalado.${NC}"
else
    echo -e "${YELLOW}⏭️  Plymouth no disponible.${NC}"
fi
echo ""

# =============================================================================
# PASO 12: TEMA DE FIREFOX
# =============================================================================
echo -e "${YELLOW}🦊 [12/24] Instalando tema de Firefox...${NC}"
if command -v firefox &> /dev/null || command -v firefox-bin &> /dev/null; then
    pidof firefox &> /dev/null || pidof firefox-bin &> /dev/null && pkill -f firefox 2>/dev/null && sleep 2
    ( cd "$WORKDIR/MacTahoe-gtk-theme" && ./tweaks.sh -f > /dev/null 2>&1 )
    echo -e "${GREEN}✅ Tema de Firefox instalado.${NC}"
else
    echo -e "${YELLOW}⏭️  Firefox no instalado.${NC}"
fi
echo ""

# =============================================================================
# PASO 13: GDM (PANTALLA DE LOGIN)
# =============================================================================
echo -e "${YELLOW}🔐 [13/24] Configurando pantalla de login...${NC}"
if [ "$IS_GNOME" = true ]; then
    ( cd "$WORKDIR/MacTahoe-gtk-theme" && sudo ./tweaks.sh -g -b default > /dev/null 2>&1 )
    echo -e "${GREEN}✅ Pantalla de login configurada.${NC}"
else
    echo -e "${YELLOW}⏭️  GDM omitido.${NC}"
fi
echo ""

# =============================================================================
# PASO 14: SCRIPT AUXILIAR PARA VENTANAS AVANZADAS
# =============================================================================
echo -e "${YELLOW}🪟 [14/24] Instalando script auxiliar de gestión de ventanas...${NC}"
ADVANCED_WM_SCRIPT="$HOME/.local/bin/macos-wm-actions"
mkdir -p "$HOME/.local/bin"

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
echo -e "${GREEN}✅ Script auxiliar creado.${NC}"
echo ""

# =============================================================================
# PASO 15: CONFIGURACIÓN DEL SISTEMA, PANELES Y ATAJO DE TECLADO (UNIVERSAL)
# =============================================================================
echo -e "${YELLOW}⚙️  [15/25] Configurando sistema, paneles y atajos de teclado macOS...${NC}"

set +e # Desactivar salida por error para evitar fallos en configuraciones menores

# Determinar ruta del wallpaper
if [ "$MOJAVE_INSTALLED" = true ]; then
    WALLPAPER_PATH="/usr/share/backgrounds/macOS/mojave-timed.xml"
elif [ "$IS_GNOME" = true ]; then
    WALLPAPER_PATH="$REAL_HOME/.local/share/backgrounds/Sonoma/Sonoma-timed.xml"
else
    WALLPAPER_PATH="$REAL_HOME/.local/share/backgrounds/Sonoma-dark.jpg"
fi

# =============================================================================
# CONFIGURACIÓN PARA GNOME
# =============================================================================
if [ "$IS_GNOME" = true ]; then
    echo -e "${BLUE}   → Configurando GNOME...${NC}"
    
    # Temas y colores
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
    run_as_user gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
    run_as_user gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME"
    run_as_user gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    
    # Fuentes Apple
    if [ "$SF_INSTALLED" = true ]; then
        run_as_user gsettings set org.gnome.desktop.interface font-name 'SF Pro Text 11'
        run_as_user gsettings set org.gnome.desktop.interface document-font-name 'New York Medium 11'
        run_as_user gsettings set org.gnome.desktop.interface monospace-font-name 'SF Mono Regular 11'
        run_as_user gsettings set org.gnome.desktop.wm.preferences titlebar-font 'SF Pro Text 11'
        echo -e "${GREEN}   ✓ Fuentes Apple aplicadas${NC}"
    fi
    
    # Botones de ventana a la izquierda
    run_as_user gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'
    echo -e "${GREEN}   ✓ Botones de ventana movidos a la izquierda${NC}"
    
    # Reloj en barra superior estilo macOS
    run_as_user gsettings set org.gnome.desktop.interface clock-show-date true
    run_as_user gsettings set org.gnome.desktop.interface clock-show-weekday true
    run_as_user gsettings set org.gnome.desktop.interface clock-show-seconds false
    
    # Fondo de pantalla y sonidos
    if [ -f "$WALLPAPER_PATH" ]; then
        run_as_user gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_PATH"
        run_as_user gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_PATH"
    fi
    if [ "$SOUND_INSTALLED" = true ]; then
        run_as_user gsettings set org.gnome.desktop.sound theme-name "$SOUND_THEME"
        run_as_user gsettings set org.gnome.desktop.sound event-sounds true
        run_as_user gsettings set org.gnome.desktop.sound input-feedback-sounds true
    fi
    
    # --- ATAJO DE TECLADO ESTILO macOS (GNOME) ---
    echo -e "${BLUE}   → Aplicando atajos de teclado estilo macOS...${NC}"
    run_as_user gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']"
    run_as_user gsettings set org.gnome.desktop.wm.keybindings minimize "['<Super>m']"
    run_as_user gsettings set org.gnome.desktop.wm.keybindings toggle-maximized "['<Super>Up']"
    run_as_user gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
    run_as_user gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
    run_as_user gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Ctrl><Alt>t']"
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Super>l']"
    
    # Atajos personalizados usando el script del Paso 14
    CUSTOM_PATHS=(); INDEX=0
    gnome_set_keybinding() {
        local name="$1" command="$2" binding="$3" idx="$4"
        local PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${idx}/"
        run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH name "$name" 2>/dev/null || true
        run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH command "$command" 2>/dev/null || true
        run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH binding "$binding" 2>/dev/null || true
        CUSTOM_PATHS+=("'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${idx}/'")
    }
    
    gnome_set_keybinding "Spotlight" "rofi-spotlight-launcher" "<Ctrl>space" $INDEX; INDEX=$((INDEX+1))
    gnome_set_keybinding "Cerrar App" "macos-wm-actions close-app-completely" "<Super>q" $INDEX; INDEX=$((INDEX+1))
    gnome_set_keybinding "Centrar Ventana" "macos-wm-actions center" "<Super>c" $INDEX; INDEX=$((INDEX+1))
    gnome_set_keybinding "Forzar Cierre" "macos-wm-actions force-kill" "<Ctrl><Alt>Escape" $INDEX; INDEX=$((INDEX+1))
    
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$(IFS=,; echo "[${CUSTOM_PATHS[*]}]")" 2>/dev/null || true
    echo -e "${GREEN}   ✓ Atajos de teclado macOS aplicados${NC}"
    
    # Activar extensiones clave
    run_as_user gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null || true
    run_as_user gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null || true
    run_as_user gnome-extensions enable liquid-glass@thinkingcoding1231.gmail.com 2>/dev/null || true
    run_as_user gnome-extensions enable ding@rastersoft.com 2>/dev/null || true
    
    # Configuración fina del Dock
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock hide-mode 'AUTOHIDE'
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock intellihide-mode 'ALL_WINDOWS'
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.4
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock show-show-apps-button true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true
    
    echo -e "${GREEN}   ✓ Configuración GNOME aplicada al 100%${NC}"

# =============================================================================
# CONFIGURACIÓN PARA CINNAMON
# =============================================================================
elif [ "$IS_CINNAMON" = true ]; then
    echo -e "${BLUE}   → Configurando Cinnamon...${NC}"
    
    run_as_user gsettings set org.cinnamon.desktop.interface gtk-theme "$GTK_THEME"
    run_as_user gsettings set org.cinnamon.desktop.interface icon-theme "$ICON_THEME"
    run_as_user gsettings set org.cinnamon.desktop.interface cursor-theme "$CURSOR_THEME"
    run_as_user gsettings set org.cinnamon.desktop.interface color-scheme 'prefer-dark'
    
    if [ "$SF_INSTALLED" = true ]; then
        run_as_user gsettings set org.cinnamon.desktop.interface font-name 'SF Pro Text 11'
        run_as_user gsettings set org.cinnamon.desktop.interface document-font-name 'New York Medium 11'
        run_as_user gsettings set org.cinnamon.desktop.interface monospace-font-name 'SF Mono Regular 11'
        run_as_user gsettings set org.cinnamon.desktop.wm.preferences titlebar-font 'SF Pro Text 11'
        echo -e "${GREEN}   ✓ Fuentes Apple aplicadas${NC}"
    fi
    
    run_as_user gsettings set org.cinnamon.desktop.wm.preferences button-layout 'close,minimize,maximize:'
    echo -e "${GREEN}   ✓ Botones de ventana movidos a la izquierda${NC}"
    
    # PANEL SUPERIOR ESTILO macOS
    run_as_user gsettings set org.cinnamon panels-enabled "['1:0:top']"
    run_as_user gsettings set org.cinnamon.panel-height 28
    run_as_user gsettings set org.cinnamon enabled-applets \
        "['panel1:left:0:menu@cinnamon.org', \
          'panel1:left:1:workspace-switcher@cinnamon.org', \
          'panel1:right:2:notifications@cinnamon.org', \
          'panel1:right:3:user@cinnamon.org', \
          'panel1:right:4:calendar@cinnamon.org', \
          'panel1:right:5:power@cinnamon.org', \
          'panel1:right:6:sound@cinnamon.org', \
          'panel1:right:7:network@cinnamon.org']" 2>/dev/null || true
    echo -e "${GREEN}   ✓ Panel superior configurado (sin lista de ventanas)${NC}"
    
    # --- ATAJO DE TECLADO ESTILO macOS (CINNAMON) ---
    echo -e "${BLUE}   → Aplicando atajos de teclado estilo macOS...${NC}"
    run_as_user gsettings set org.cinnamon.desktop.keybindings.wm show-desktop "['<Super>d']" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.keybindings.wm minimize "['<Super>m']" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.keybindings.wm maximize "['<Super>Up']" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-1 "['<Super>1']" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-2 "['<Super>2']" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-3 "['<Super>3']" 2>/dev/null || true
    
    # Atajos personalizados
    CUSTOM_IDS=()
    cinnamon_set_keybinding() {
        local name="$1" command="$2" binding="$3" id="$4"
        local PATH="/org/cinnamon/desktop/keybindings/custom-keybindings/$id/"
        run_as_user gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$PATH name "$name" 2>/dev/null || true
        run_as_user gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$PATH command "$command" 2>/dev/null || true
        run_as_user gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$PATH binding "$binding" 2>/dev/null || true
        CUSTOM_IDS+=("'${id}'")
    }
    
    cinnamon_set_keybinding "Spotlight" "rofi-spotlight-launcher" "<Ctrl>space" "custom-spotlight"
    cinnamon_set_keybinding "Cerrar App" "macos-wm-actions close-app-completely" "<Super>q" "custom-close"
    cinnamon_set_keybinding "Centrar Ventana" "macos-wm-actions center" "<Super>c" "custom-center"
    cinnamon_set_keybinding "Forzar Cierre" "macos-wm-actions force-kill" "<Ctrl><Alt>Escape" "custom-forcekill"
    
    run_as_user gsettings set org.cinnamon.desktop.keybindings custom-list "$(IFS=,; echo "[${CUSTOM_IDS[*]}]")" 2>/dev/null || true
    echo -e "${GREEN}   ✓ Atajos de teclado macOS aplicados${NC}"
    
    # Fondo y sonidos
    if [ -f "$WALLPAPER_PATH" ]; then
        run_as_user gsettings set org.cinnamon.desktop.background picture-uri "file://$WALLPAPER_PATH"
        run_as_user gsettings set org.cinnamon.desktop.background picture-uri-dark "file://$WALLPAPER_PATH"
    fi
    if [ "$SOUND_INSTALLED" = true ]; then
        run_as_user gsettings set org.cinnamon.desktop.sound theme-name "$SOUND_THEME"
        run_as_user gsettings set org.cinnamon.desktop.sound event-sounds true
        run_as_user gsettings set org.cinnamon.desktop.sound input-feedback-sounds true
    fi
    
    # Activar Hot Corners
    run_as_user gsettings set org.cinnamon.desktop.wm.preferences enable-hot-corners true 2>/dev/null || true
    
    echo -e "${GREEN}   ✓ Configuración Cinnamon aplicada al 100%${NC}"

# =============================================================================
# CONFIGURACIÓN PARA XFCE
# =============================================================================
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    echo -e "${BLUE}   → Configurando XFCE...${NC}"
    
    run_as_user xfconf-query -c xsettings -p /Net/ThemeName -s "$GTK_THEME" 2>/dev/null || true
    run_as_user xfconf-query -c xsettings -p /Net/IconThemeName -s "$ICON_THEME" 2>/dev/null || true
    run_as_user xfconf-query -c xsettings -p /Net/CursorThemeName -s "$CURSOR_THEME" 2>/dev/null || true
    
    if [ "$SF_INSTALLED" = true ]; then
        run_as_user xfconf-query -c xsettings -p /Gtk/FontName -s 'SF Pro Text 11' 2>/dev/null || true
        run_as_user xfconf-query -c xsettings -p /Gtk/DocumentFontName -s 'New York Medium 11' 2>/dev/null || true
        run_as_user xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s 'SF Mono Regular 11' 2>/dev/null || true
        run_as_user xfconf-query -c xfwm4 -p /general/title_font -s 'SF Pro Text 11' 2>/dev/null || true
        echo -e "${GREEN}   ✓ Fuentes Apple aplicadas${NC}"
    fi
    
    run_as_user xfconf-query -c xfwm4 -p /general/button_layout -s "OHM" 2>/dev/null || true
    echo -e "${GREEN}   ✓ Botones de ventana movidos a la izquierda${NC}"
    
    # PANEL SUPERIOR ESTILO macOS
    run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/position -s "p=6;x=0;y=0" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/position-locked -s true 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/size -s 28 2>/dev/null || true
    
    # Eliminar lista de ventanas
    for plugin in $(run_as_user xfconf-query -c xfce4-panel -l 2>/dev/null | grep "/panels/panel-0/plugins/plugin-" | cut -d'/' -f5); do
        plugin_type=$(run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/plugins/$plugin 2>/dev/null)
        if [ "$plugin_type" = "tasklist" ] || [ "$plugin_type" = "windowmenu" ]; then
            run_as_user xfconf-query -c xfce4-panel -r /panels/panel-0/plugins/$plugin 2>/dev/null
        fi
    done
    echo -e "${GREEN}   ✓ Panel superior configurado (sin lista de ventanas)${NC}"
    
    # Formato de reloj estilo macOS
    CLOCK_PLUGIN=$(run_as_user xfconf-query -c xfce4-panel -l 2>/dev/null | grep "/plugins/" | grep "clock" | head -1 | cut -d'/' -f4)
    if [ -n "$CLOCK_PLUGIN" ]; then
        run_as_user xfconf-query -c xfce4-panel -p /plugins/$CLOCK_PLUGIN/digital-format -s "%a %d %b, %H:%M" 2>/dev/null || true
        run_as_user xfconf-query -c xfce4-panel -p /plugins/$CLOCK_PLUGIN/digital-layout -s 3 2>/dev/null || true
    fi
    
    # --- ATAJO DE TECLADO ESTILO macOS (XFCE) ---
    echo -e "${BLUE}   → Aplicando atajos de teclado estilo macOS...${NC}"
    xfce_set_keybinding() {
        local command="$1" binding="$2"
        run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/$binding" -n -t string -s "$command" 2>/dev/null || \
        run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/$binding" -s "$command" 2>/dev/null || true
    }
    
    xfce_set_keybinding "rofi-spotlight-launcher" "<Ctrl>space"
    xfce_set_keybinding "macos-wm-actions close-app-completely" "<Super>q"
    xfce_set_keybinding "macos-wm-actions center" "<Super>c"
    xfce_set_keybinding "macos-wm-actions force-kill" "<Ctrl><Alt>Escape"
    xfce_set_keybinding "xfce4-terminal" "<Ctrl><Alt>t"
    xfce_set_keybinding "xfce4-screensaver-command --lock" "<Super>l"
    
    # Atajos de ventana XFCE
    run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>d" -n -t string -s "show_desktop_key" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>m" -n -t string -s "hide_window_key" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>Up" -n -t string -s "maximize_window_key" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>1" -n -t string -s "workspace_1_key" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>2" -n -t string -s "workspace_2_key" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>3" -n -t string -s "workspace_3_key" 2>/dev/null || true
    echo -e "${GREEN}   ✓ Atajos de teclado macOS aplicados${NC}"
    
    # Tema de notificaciones
    run_as_user xfconf-query -c xfce4-notifyd -p /theme -s "MacTahoe-Dark" 2>/dev/null || true
    
    if [ "$SOUND_INSTALLED" = true ]; then
        run_as_user xfconf-query -c xsettings -p /Net/SoundThemeName -s "$SOUND_THEME" 2>/dev/null || true
    fi
    
    echo -e "${GREEN}   ✓ Configuración XFCE aplicada al 100%${NC}"
fi

set -e # Reactivar salida por error
echo -e "${GREEN}✅ Configuración del sistema aplicada.${NC}"
echo ""

# =============================================================================
# PASO 15.5: BOTÓN DE MENÚ CON ICONO DE APPLE (macOS)
# =============================================================================
echo -e "${YELLOW}🍎 [15.5/25] Configurando icono de Apple en el botón de inicio...${NC}"

set +e

if [ "$IS_GNOME" = true ]; then
    echo -e "${BLUE}   → Configurando GNOME...${NC}"
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock show-show-apps-button true 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true 2>/dev/null || true
    echo -e "${GREEN}   ✓ Botón de aplicaciones configurado con icono de Apple${NC}"
    
elif [ "$IS_CINNAMON" = true ]; then
    echo -e "${BLUE}   → Configurando Cinnamon...${NC}"
    run_as_user gsettings set org.cinnamon.applets.menu@cinnamon.org menu-icon "distributor-logo" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.applets.menu@cinnamon.org menu-icon-size 16 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.menu-favorites-show true 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.menu-show-category-icons true 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.menu-show-application-icons true 2>/dev/null || true
    echo -e "${GREEN}   ✓ Icono de Apple aplicado al menú de Cinnamon${NC}"
    
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    echo -e "${BLUE}   → Configurando XFCE...${NC}"
    WHISKER_ID=$(run_as_user xfconf-query -c xfce4-panel -l 2>/dev/null | grep "whiskermenu" | head -1 | cut -d'/' -f4)
    if [ -n "$WHISKER_ID" ]; then
        run_as_user xfconf-query -c xfce4-panel -p /plugins/$WHISKER_ID/button-icon -s "distributor-logo" 2>/dev/null || true
        run_as_user xfconf-query -c xfce4-panel -p /plugins/$WHISKER_ID/show-button-title -s false 2>/dev/null || true
        run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/plugin-1 -s "whiskermenu" 2>/dev/null || true
        echo -e "${GREEN}   ✓ Icono de Apple aplicado a Whisker Menu (solo icono, sin texto)${NC}"
    else
        echo -e "${YELLOW}   ⚠️  No se encontró Whisker Menu. Asegúrate de tenerlo instalado.${NC}"
    fi
fi

set -e
echo ""

# =============================================================================
# PASO 15.6: AJUSTES FINOS DE COMPORTAMIENTO (FINDER, TRACKPAD Y NOTIFICACIONES)
# =============================================================================
echo -e "${YELLOW}🔧 [15.6/25] Aplicando ajustes finos de comportamiento (Finder, Trackpad, Notificaciones)...${NC}"

set +e

if [ "$IS_GNOME" = true ]; then
    echo -e "${BLUE}   → Ajustando GNOME (Nautilus, Trackpad, Notificaciones)...${NC}"
    
    # 📁 Administrador de Archivos (Nautilus estilo Finder)
    run_as_user gsettings set org.gnome.nautilus.preferences default-folder-viewer 'icon-view' 2>/dev/null || true
    run_as_user gsettings set org.gnome.nautilus.preferences show-hidden-files false 2>/dev/null || true
    run_as_user gsettings set org.gnome.nautilus.preferences search-filter-time-type 'last_modified' 2>/dev/null || true
    
    # 🖱️ Trackpad y Mouse (Nivel Avanzado)
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.peripherals.mouse acceleration-profile 'adaptive' 2>/dev/null || true
    
    # 🔔 Notificaciones (Nativo de GNOME, ya estilizado por el tema)
    # No se requiere acción extra, el tema MacTahoe ya aplica el estilo visual.
    
    echo -e "${GREEN}   ✓ Ajustes finos de GNOME aplicados${NC}"

elif [ "$IS_CINNAMON" = true ]; then
    echo -e "${BLUE}   → Ajustando Cinnamon (Nemo, Trackpad, Notificaciones)...${NC}"
    
    # 📁 Administrador de Archivos (Nemo estilo Finder)
    run_as_user gsettings set org.nemo.preferences default-folder-viewer 'icon-view' 2>/dev/null || true
    run_as_user gsettings set org.nemo.preferences show-hidden-files false 2>/dev/null || true
    run_as_user gsettings set org.nemo.preferences show-hidden-backups false 2>/dev/null || true
    
    # 🖱️ Trackpad y Mouse (Nivel Avanzado)
    run_as_user gsettings set org.cinnamon.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.peripherals.mouse acceleration-profile 'adaptive' 2>/dev/null || true
    
    # 🔔 Centro de Notificaciones (Estilo macOS)
    run_as_user gsettings set org.cinnamon.desktop.notifications show-banners true 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.notifications show-notifications-on-lock-screen false 2>/dev/null || true
    
    echo -e "${GREEN}   ✓ Ajustes finos de Cinnamon aplicados${NC}"

elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    echo -e "${BLUE}   → Ajustando XFCE (Thunar, Trackpad, Notificaciones)...${NC}"
    
    # 📁 Administrador de Archivos (Thunar estilo Finder)
    run_as_user xfconf-query -c thunar -p /misc-default-view -s "THUNAR_VIEW_ICON" 2>/dev/null || true
    run_as_user xfconf-query -c thunar -p /misc-show-hidden -s false 2>/dev/null || true
    run_as_user xfconf-query -c thunar -p /misc-single-click -s false 2>/dev/null || true # Doble clic para abrir, como macOS
    
    # 🖱️ Trackpad (Habilitar Tap-to-Click de forma genérica)
    # Buscamos cualquier dispositivo que contenga "Touchpad" y activamos el tapping
    for dev in $(xinput list --id-only 'Touchpad' 'touchpad' 2>/dev/null); do
        xinput set-prop "$dev" "libinput Tapping Enabled" 1 2>/dev/null || true
        xinput set-prop "$dev" "libinput Natural Scrolling Enabled" 1 2>/dev/null || true
    done
    
    # 🔔 Centro de Notificaciones (Estilo macOS)
    run_as_user xfconf-query -c xfce4-notifyd -p /theme -s "MacTahoe-Dark" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-notifyd -p /notify-location -s 2 2>/dev/null || true # 2 = Esquina superior derecha
    run_as_user xfconf-query -c xfce4-notifyd -p /do-fadeout -s true 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-notifyd -p /fadeout-time -s 500 2>/dev/null || true # Desvanecimiento rápido (0.5s)
    
    echo -e "${GREEN}   ✓ Ajustes finos de XFCE aplicados${NC}"
fi

set -e
echo -e "${GREEN}✅ Ajustes finos de comportamiento completados.${NC}"
echo ""

# =============================================================================
# PASO 15.7: DETALLES FINALES DE EXPERIENCIA macOS (SONIDO, ACERCA DE, SIDEBAR, CURSOR)
# =============================================================================
echo -e "${YELLOW}✨ [15.7/25] Aplicando detalles finales de experiencia macOS...${NC}"

set +e

# =============================================================================
# 1. SONIDO DE ARRANQUE (STARTUP CHIME)
# =============================================================================
echo -e "${BLUE}   → Configurando sonido de arranque estilo macOS...${NC}"

AUTOSTART_DIR="$REAL_HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR" 2>/dev/null || true

SOUND_FILE="$REAL_HOME/.local/share/sounds/bigsur/stereo/desktop-login.oga"

if [ -f "$SOUND_FILE" ]; then
    cat > "$AUTOSTART_DIR/mac-startup-chime.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Mac Startup Chime
Exec=paplay $SOUND_FILE --volume=65536
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
Comment=Reproduce el sonido de arranque de macOS Big Sur
EOF
    echo -e "${GREEN}   ✓ Sonido de arranque configurado${NC}"
else
    echo -e "${YELLOW}   ⚠️  Archivo de sonido no encontrado, omitiendo${NC}"
fi

# =============================================================================
# 2. VENTANA "ACERCA DE ESTE MAC" (CON ACTUALIZACIÓN REAL DEL SISTEMA Y TEMA)
# =============================================================================
echo -e "${BLUE}   → Creando ventana 'Acerca de este Mac' con actualización real...${NC}"

ABOUT_SCRIPT="$REAL_HOME/.local/bin/about-this-mac.sh"
mkdir -p "$REAL_HOME/.local/bin" 2>/dev/null || true

cat > "$ABOUT_SCRIPT" << 'ABOUTEOF'
#!/bin/bash
# Simulación de "Acerca de este Mac" con Actualización de Software Real

CPU=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs | sed 's/(R)//g; s/(TM)//g; s/(C)//g' 2>/dev/null || echo "Procesador")
RAM=$(free -h | awk '/^Mem:/ {print $2}' 2>/dev/null || echo "RAM")
DISK=$(df -h / | awk 'NR==2 {print $2}' 2>/dev/null || echo "Disco")
GRAPHICS=$(lspci 2>/dev/null | grep -i "vga\|3d\|display" | head -1 | cut -d':' -f3 | xargs | sed 's/Corporation//g; s/Inc.//g' 2>/dev/null || echo "Gráficos")
KERNEL=$(uname -r 2>/dev/null || echo "Kernel")

# Función para ejecutar la actualización real en una terminal
run_real_update() {
    # Detectar emulador de terminal disponible
    TERM_CMD=""
    for term in gnome-terminal xfce4-terminal konsole x-terminal-emulator xterm; do
        if command -v $term &> /dev/null; then
            TERM_CMD=$term
            break
        fi
    done

    if [ -z "$TERM_CMD" ]; then
        zenity --error --text="No se encontró una terminal para ejecutar la actualización." 2>/dev/null
        return
    fi

    # Crear script temporal de actualización
    TEMP_UPDATE=$(mktemp /tmp/macos-update-XXXXXX.sh)
    cat > "$TEMP_UPDATE" << 'UPDATEEOF'
#!/bin/bash
clear
echo "🍎 Iniciando Actualización de Software de macOS Tahoe..."
echo "=========================================================="
echo ""
echo "📦 [1/2] Actualizando paquetes del sistema base..."
if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get upgrade -y
elif command -v dnf &> /dev/null; then
    sudo dnf upgrade -y
elif command -v pacman &> /dev/null; then
    sudo pacman -Syu --noconfirm
fi

echo ""
echo "🔄 [2/2] Actualizando componentes del tema macOS Tahoe..."
# Descargar la última versión del script de actualización
curl -sSL https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/update.sh -o /tmp/tahoe-updater.sh
chmod +x /tmp/tahoe-updater.sh

# Ejecutar el script de actualización
sudo /tmp/tahoe-updater.sh

echo ""
echo "✅ ¡Proceso de actualización finalizado con éxito!"
echo "Presiona [ENTER] para cerrar esta ventana."
read -r
UPDATEEOF
    chmod +x "$TEMP_UPDATE"

    # Ejecutar en la terminal detectada
    if [ "$TERM_CMD" = "gnome-terminal" ]; then
        gnome-terminal -- bash -c "$TEMP_UPDATE"
    elif [ "$TERM_CMD" = "xfce4-terminal" ]; then
        xfce4-terminal -x bash -c "$TEMP_UPDATE"
    elif [ "$TERM_CMD" = "konsole" ]; then
        konsole -e bash -c "$TEMP_UPDATE"
    else
        $TERM_CMD -e bash -c "$TEMP_UPDATE"
    fi
}

# Mostrar ventana "Acerca de este Mac"
# Usamos --question para tener dos botones: "Aceptar" y "Actualización de software..."
if zenity --question --title="Acerca de este Mac" --width=360 --height=420 \
--text="<span font='SF Pro Display 18' weight='bold'>macOS Tahoe</span>\n\n\
<span font='SF Pro Text 11'><b>Chip:</b> $CPU</span>\n\
<span font='SF Pro Text 11'><b>Memoria:</b> $RAM</span>\n\
<span font='SF Pro Text 11'><b>Disco de arranque:</b> Macintosh HD ($DISK)</span>\n\
<span font='SF Pro Text 11'><b>Gráficos:</b> $GRAPHICS</span>\n\
<span font='SF Pro Text 11'><b>Sistema:</b> Linux (Kernel $KERNEL)</span>\n\n\
<span font='SF Pro Text 9' foreground='#888888'>TM y © 1983-2026 Apple Inc.\nTodos los derechos reservados.</span>" \
--ok-label="Actualización de software..." \
--cancel-label="Aceptar" 2>/dev/null; then
    
    # Si el usuario hace clic en "Actualización de software..." (salida 0), ejecutamos la función
    run_real_update
fi
ABOUTEOF

chmod +x "$ABOUT_SCRIPT"
if [ -n "$SUDO_USER" ]; then 
    chown "$SUDO_USER:$SUDO_USER" "$ABOUT_SCRIPT" 2>/dev/null || true 
fi
echo -e "${GREEN}   ✓ Script 'Acerca de este Mac' creado con actualización real${NC}"

# Asignar atajo Super+I para abrir la ventana (universal)
if [ "$IS_GNOME" = true ]; then
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybinding:custom0 name "'Acerca de este Mac'" 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybinding:custom0 command "'$ABOUT_SCRIPT'" 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybinding:custom0 binding "'<Super>i'" 2>/dev/null || true
    
    EXISTING=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "[]")
    if echo "$EXISTING" | grep -q "custom0"; then
        echo -e "${GREEN}   ✓ Atajo Super+I ya configurado${NC}"
    else
        NEW_LIST=$(echo "$EXISTING" | sed "s/]$/, '\/org\/gnome\/settings-daemon\/plugins\/media-keys\/custom-keybindings\/custom0\/']/")
        run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_LIST" 2>/dev/null || true
        echo -e "${GREEN}   ✓ Atajo Super+I asignado${NC}"
    fi
elif [ "$IS_CINNAMON" = true ]; then
    run_as_user gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:custom0 name "'Acerca de este Mac'" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:custom0 command "'$ABOUT_SCRIPT'" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:custom0 binding "['<Super>i']" 2>/dev/null || true
    
    EXISTING=$(run_as_user gsettings get org.cinnamon.desktop.keybindings custom-list 2>/dev/null || echo "[]")
    if echo "$EXISTING" | grep -q "custom0"; then
        echo -e "${GREEN}   ✓ Atajo Super+I ya configurado${NC}"
    else
        NEW_LIST=$(echo "$EXISTING" | sed "s/]$/, 'custom0']/")
        run_as_user gsettings set org.cinnamon.desktop.keybindings custom-list "$NEW_LIST" 2>/dev/null || true
        echo -e "${GREEN}   ✓ Atajo Super+I asignado${NC}"
    fi
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>i" -s "$ABOUT_SCRIPT" 2>/dev/null || true
    echo -e "${GREEN}   ✓ Atajo Super+I asignado${NC}"
fi

# =============================================================================
# 3. SIDEBAR DEL ADMINISTRADOR DE ARCHIVOS (ESTILO FINDER)
# =============================================================================
echo -e "${BLUE}   → Configurando barra lateral estilo Finder...${NC}"

GTK_CONFIG_DIR="$REAL_HOME/.config/gtk-3.0"
mkdir -p "$GTK_CONFIG_DIR" 2>/dev/null || true

cat > "$GTK_CONFIG_DIR/bookmarks" << EOF
file://$REAL_HOME/Desktop Desktop
file://$REAL_HOME/Downloads Downloads
file://$REAL_HOME/Documents Documents
file://$REAL_HOME/Music Music
file://$REAL_HOME/Pictures Pictures
file://$REAL_HOME/Videos Videos
file://$REAL_HOME/.local/share/Trash Trash
EOF

if [ -n "$SUDO_USER" ]; then
    chown -R "$SUDO_USER:$SUDO_USER" "$GTK_CONFIG_DIR" 2>/dev/null || true
fi
echo -e "${GREEN}   ✓ Barra lateral de archivos configurada${NC}"

# =============================================================================
# 4. CURSOR MÁS GRANDE (DETALLE VISUAL)
# =============================================================================
echo -e "${BLUE}   → Ajustando tamaño del cursor (32px estilo macOS)...${NC}"

if [ "$IS_GNOME" = true ]; then
    run_as_user gsettings set org.gnome.desktop.interface cursor-size 32 2>/dev/null || true
    echo -e "${GREEN}   ✓ Cursor GNOME ajustado a 32px${NC}"
elif [ "$IS_CINNAMON" = true ]; then
    run_as_user gsettings set org.cinnamon.desktop.interface cursor-size 32 2>/dev/null || true
    echo -e "${GREEN}   ✓ Cursor Cinnamon ajustado a 32px${NC}"
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    run_as_user xfconf-query -c xsettings -p /Gtk/CursorThemeSize -s 32 2>/dev/null || true
    echo -e "${GREEN}   ✓ Cursor XFCE ajustado a 32px${NC}"
fi

set -e
echo -e "${GREEN}✅ Detalles finales de experiencia macOS aplicados.${NC}"
echo ""

# =============================================================================
# PASO 15.8: NOMBRE DE EQUIPO Y MODO OSCURO AUTOMÁTICO
# =============================================================================
echo -e "${YELLOW}💻 [15.8/25] Configurando identidad del equipo y modo oscuro automático...${NC}"

set +e

# =============================================================================
# 1. NOMBRE DEL EQUIPO (HOSTNAME) SEGÚN ENTORNO DE ESCRITORIO
# =============================================================================
echo -e "${BLUE}   → Cambiando nombre del equipo estilo macOS...${NC}"

# Asignar nombre según el entorno de escritorio (sin espacios para compatibilidad de red)
if [ "$IS_GNOME" = true ]; then
    NEW_HOSTNAME="MacBook-Pro"
elif [ "$IS_CINNAMON" = true ]; then
    NEW_HOSTNAME="MacBook-Air"
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    NEW_HOSTNAME="MacBook-Neo"
else
    NEW_HOSTNAME="MacBook"
fi

CURRENT_HOSTNAME=$(hostname 2>/dev/null)

if [ "$CURRENT_HOSTNAME" != "$NEW_HOSTNAME" ]; then
    # Cambiar hostname del sistema
    sudo hostnamectl set-hostname "$NEW_HOSTNAME" 2>/dev/null || true
    echo "$NEW_HOSTNAME" | sudo tee /etc/hostname > /dev/null 2>/dev/null || true
    
    # Actualizar /etc/hosts para evitar errores de sudo y resolución de red
    sudo sed -i "s/127.0.1.1\s\+$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts 2>/dev/null || true
    
    # Asegurar que la entrada exista por si el sed no encontró coincidencia
    if ! grep -q "127.0.1.1.*$NEW_HOSTNAME" /etc/hosts 2>/dev/null; then
        echo "127.0.1.1	$NEW_HOSTNAME" | sudo tee -a /etc/hosts > /dev/null 2>/dev/null || true
    fi
    
    echo -e "${GREEN}   ✓ Nombre del equipo cambiado a: $NEW_HOSTNAME${NC}"
else
    echo -e "${GREEN}   ✓ El nombre del equipo ya es: $NEW_HOSTNAME${NC}"
fi

# =============================================================================
# 2. MODO OSCURO AUTOMÁTICO (SEGÚN HORA DEL DÍA)
# =============================================================================
echo -e "${BLUE}   → Configurando modo oscuro automático (6:00 a 18:00 Claro)...${NC}"

AUTO_DARK_SCRIPT="$REAL_HOME/.local/bin/auto-dark-mode.sh"
mkdir -p "$REAL_HOME/.local/bin" 2>/dev/null || true

# Crear el script que se ejecutará cada hora
cat > "$AUTO_DARK_SCRIPT" << 'AUTODARKEOF'
#!/bin/bash
# Obtener hora actual y forzar base 10 para evitar errores con 08 o 09
HOUR=$(date +%H)
HOUR=$((10#$HOUR))

if [ "$HOUR" -ge 6 ] && [ "$HOUR" -lt 18 ]; then
    GTK_THEME="MacTahoe"
    COLOR_SCHEME="default"
else
    GTK_THEME="MacTahoe-Dark"
    COLOR_SCHEME="prefer-dark"
fi

# Aplicar a GNOME y Cinnamon (usan gsettings)
if command -v gsettings &> /dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme "$COLOR_SCHEME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
    gsettings set org.cinnamon.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
fi

# Aplicar a XFCE (usa xfconf-query)
if command -v xfconf-query &> /dev/null; then
    xfconf-query -c xsettings -p /Net/ThemeName -s "$GTK_THEME" 2>/dev/null || true
fi
AUTODARKEOF

chmod +x "$AUTO_DARK_SCRIPT"
if [ -n "$SUDO_USER" ]; then 
    chown "$SUDO_USER:$SUDO_USER" "$AUTO_DARK_SCRIPT" 2>/dev/null || true 
fi

# Crear servicio y temporizador de systemd para el usuario real
SYSTEMD_DIR="$REAL_HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_DIR" 2>/dev/null || true

cat > "$SYSTEMD_DIR/auto-dark-mode.service" << EOF
[Unit]
Description=Cambio automático de tema macOS (Claro/Oscuro)
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=$AUTO_DARK_SCRIPT
EOF

cat > "$SYSTEMD_DIR/auto-dark-mode.timer" << EOF
[Unit]
Description=Timer para cambio automático de tema macOS

[Timer]
OnBootSec=2min
OnUnitActiveSec=1h

[Install]
WantedBy=timers.target
EOF

# Activar el temporizador
run_as_user systemctl --user daemon-reload 2>/dev/null || true
run_as_user systemctl --user enable --now auto-dark-mode.timer 2>/dev/null || true

echo -e "${GREEN}   ✓ Modo oscuro automático activado (se actualiza cada hora)${NC}"

set -e
echo -e "${GREEN}✅ Identidad y automatización de tema configuradas.${NC}"
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

# Ajustar permisos
if [ -n "$SUDO_USER" ]; then
    chown -R "$SUDO_USER:$SUDO_USER" "$REAL_HOME/.config/fontconfig" 2>/dev/null || true
fi

fc-cache -f > /dev/null 2>&1 || true
set -e

echo -e "${GREEN}✅ Renderizado de fuentes optimizado para SF Pro.${NC}"
echo ""

# =============================================================================
# PASO 17: CONFIGURACIÓN DE TERMINAL ESTILO macOS
# =============================================================================
echo -e "${YELLOW}💻 [17/25] Configurando terminal estilo macOS...${NC}"

set +e

if [ "$IS_GNOME" = true ] && command -v gnome-terminal &> /dev/null; then
    PROFILE_ID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen 2>/dev/null || echo "macos-tahoe-profile")
    run_as_user dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/visible-name "'macOS Tahoe'" 2>/dev/null || true
    run_as_user dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/font "'SF Mono 12'" 2>/dev/null || true
    run_as_user dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/use-system-font false 2>/dev/null || true
    run_as_user dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/background-color "'rgb(30,30,30)'" 2>/dev/null || true
    run_as_user dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/foreground-color "'rgb(230,230,230)'" 2>/dev/null || true
    run_as_user dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/use-theme-colors false 2>/dev/null || true
    run_as_user dconf write /org/gnome/terminal/legacy/default-profile "'$PROFILE_ID'" 2>/dev/null || true
    echo -e "${GREEN}   ✓ Terminal GNOME configurada con tema macOS${NC}"
elif [[ "$DESKTOP_ENV" == *"xfce"* ]] && command -v xfce4-terminal &> /dev/null; then
    mkdir -p "$REAL_HOME/.config/xfce4/terminal" 2>/dev/null || true
    cat > "$REAL_HOME/.config/xfce4/terminal/terminalrc" << 'TERMINALEOF' 2>/dev/null || true
[Configuration]
FontName=SF Mono 12
ColorForeground=#e6e6e6
ColorBackground=#1e1e1e
ColorBold=#ffffff
MiscCursorShape=TERMINAL_CURSOR_SHAPE_IBEAM
MiscCursorBlinks=FALSE
MiscShowUnsafeUrls=FALSE
TERMINALEOF
    if [ -n "$SUDO_USER" ]; then
        chown -R "$SUDO_USER:$SUDO_USER" "$REAL_HOME/.config/xfce4/terminal" 2>/dev/null || true
    fi
    echo -e "${GREEN}   ✓ Terminal XFCE configurada con tema macOS${NC}"
fi

set -e
echo -e "${GREEN}✅ Terminal configurada.${NC}"
echo ""

# =============================================================================
# PASO 18: CONFIGURACIÓN DE ANIMACIONES SUAVES
# =============================================================================
echo -e "${YELLOW} [18/25] Configurando animaciones suaves...${NC}"

set +e

if [ "$IS_GNOME" = true ]; then
    run_as_user gsettings set org.gnome.desktop.interface enable-animations true 2>/dev/null || true
    run_as_user gsettings set org.gnome.mutter center-new-windows true 2>/dev/null || true
fi

if [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    run_as_user xfconf-query -c xfwm4 -p /general/use_compositing -s true 2>/dev/null || true
fi

set -e
echo -e "${GREEN}✅ Animaciones configuradas.${NC}"
echo ""

# =============================================================================
# PASO 19: EFECTO MAGIC LAMP (GNOME y Cinnamon)
# =============================================================================
echo -e "${YELLOW} [19/25] Instalando efecto Magic Lamp (minimizar ventanas)...${NC}"

set +e

if [ "$IS_GNOME" = true ]; then
    echo -e "${BLUE}   → Instalando para GNOME...${NC}"
    mkdir -p "$REAL_HOME/.local/share/gnome-shell/extensions/" 2>/dev/null || true
    
    if [ ! -d "$WORKDIR/compiz-alike-magic-lamp-effect" ]; then
        git clone --depth=1 https://github.com/hermes83/compiz-alike-magic-lamp-effect.git "$WORKDIR/compiz-alike-magic-lamp-effect" -q 2>/dev/null || true
    fi
    
    EXT_MAGIC_LAMP=$(find "$WORKDIR/compiz-alike-magic-lamp-effect" -maxdepth 1 -type d -name "*magic-lamp*" 2>/dev/null | head -1)
    if [ -n "$EXT_MAGIC_LAMP" ]; then
        cp -r "$EXT_MAGIC_LAMP" "$REAL_HOME/.local/share/gnome-shell/extensions/" 2>/dev/null || true
        run_as_user gnome-extensions enable "$(basename "$EXT_MAGIC_LAMP")" 2>/dev/null || true
        echo -e "${GREEN}   ✓ Magic Lamp para GNOME instalada y activada${NC}"
    fi
elif [ "$IS_CINNAMON" = true ]; then
    echo -e "${BLUE}   → Instalando para Cinnamon...${NC}"
    mkdir -p "$REAL_HOME/.local/share/cinnamon/extensions/" 2>/dev/null || true
    
    if [ ! -d "$WORKDIR/CinnamonMagicLamp" ]; then
        git clone --depth=1 https://github.com/klangman/CinnamonMagicLamp.git "$WORKDIR/CinnamonMagicLamp" -q 2>/dev/null || true
    fi
    
    if [ -d "$WORKDIR/CinnamonMagicLamp/CinnamonMagicLamp@klangman" ]; then
        ln -sf "$WORKDIR/CinnamonMagicLamp/CinnamonMagicLamp@klangman" "$REAL_HOME/.local/share/cinnamon/extensions/CinnamonMagicLamp@klangman" 2>/dev/null || true
        run_as_user gsettings set org.cinnamon.desktop.effects minimize-effect "'none'" 2>/dev/null || true
        run_as_user gsettings set org.cinnamon.desktop.effects unminimize-effect "'none'" 2>/dev/null || true
        echo -e "${GREEN}   ✓ Magic Lamp para Cinnamon instalada y activada${NC}"
    fi
else
    echo -e "${YELLOW}   ⏭️  Magic Lamp omitido (solo GNOME y Cinnamon)${NC}"
fi

set -e
echo -e "${GREEN}✅ Magic Lamp configurado.${NC}"
echo ""

# =============================================================================
# PASO 20: TEMATIZACIÓN QT Y QUICK LOOK (Vista Previa)
# =============================================================================
echo -e "${YELLOW} [20/25] Tematizando aplicaciones Qt y activando Quick Look...${NC}"

set +e

# Configuración Qt
if ! grep -q "QT_QPA_PLATFORMTHEME=qt5ct" /etc/environment 2>/dev/null; then
    echo "QT_QPA_PLATFORMTHEME=qt5ct" | sudo tee -a /etc/environment > /dev/null 2>&1 || true
fi

mkdir -p "$REAL_HOME/.config/qt5ct" 2>/dev/null || true
cat > "$REAL_HOME/.config/qt5ct/qt5ct.conf" << 'EOF' 2>/dev/null || true
[Appearance]
style=gtk2
color_scheme_path=
icon_theme=MacTahoe-dark
EOF

if [ -n "$SUDO_USER" ]; then
    chown -R "$SUDO_USER:$SUDO_USER" "$REAL_HOME/.config/qt5ct" 2>/dev/null || true
fi

# Quick Look
if [ "$IS_GNOME" = true ]; then
    sudo apt-get install -y -qq gnome-sushi 2>/dev/null || sudo apt-get install -y -qq sushi 2>/dev/null || true
elif [[ "$DESKTOP_ENV" == *"cinnamon"* ]] || [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    sudo apt-get install -y -qq gloobus-preview 2>/dev/null || true
fi

set -e
echo -e "${GREEN}✅ Qt tematizado y Quick Look configurado.${NC}"
echo ""

# =============================================================================
# PASO 21: SCROLL NATURAL UNIVERSAL
# =============================================================================
echo -e "${YELLOW}📜 [21/25] Activando Scroll Natural (Estilo macOS)...${NC}"

set +e

if [ "$IS_GNOME" = true ] || [ "$IS_CINNAMON" = true ]; then
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.peripherals.mouse natural-scroll true 2>/dev/null || true
fi

if [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    for device in $(xinput list 2>/dev/null | grep -i "pointer" | grep -i "libinput" | sed 's/.*id=\([0-9]*\).*/\1/'); do
        xinput set-prop "$device" "libinput Natural Scrolling Enabled" 1 2>/dev/null || true
    done
fi

set -e
echo -e "${GREEN}✅ Scroll natural activado.${NC}"
echo ""

# =============================================================================
# PASO 22: GESTOS MULTITÁCTILES ESTILO MACOS (FUSUMA) + ARRASTRE 3 DEDOS
# =============================================================================
echo -e "${YELLOW}👆 [22/25] Instalando Gestos Multitáctiles y Arrastre con 3 dedos...${NC}"

set +e

sudo gpasswd -a "$REAL_USER" input 2>/dev/null || true

# Instalar fusuma como usuario real
if command -v gem &> /dev/null; then
    sudo -u "$REAL_USER" gem install fusuma --no-document 2>/dev/null || true
fi

mkdir -p "$REAL_HOME/.config/fusuma" 2>/dev/null || true
cat > "$REAL_HOME/.config/fusuma/config.yml" << 'EOF' 2>/dev/null || true
plugin:
  inputs:
    libinput_command_input:
      enable-tap: true
swipe:
  3:
    left:
      command: 'xdotool key ctrl+alt+Right'
    right:
      command: 'xdotool key ctrl+alt+Left'
    up:
      command: 'xdotool key super'
    down:
      command: 'xdotool key super'
  4:
    left:
      command: 'xdotool key alt+Left'
    right:
      command: 'xdotool key alt+Right'
pinch:
  2:
    in:
      command: 'xdotool keydown ctrl click 4 keyup ctrl'
    out:
      command: 'xdotool keydown ctrl click 5 keyup ctrl'
hold:
  3:
    begin:
      command: 'xdotool mousedown 1'
    end:
      command: 'xdotool mouseup 1'
EOF

mkdir -p "$REAL_HOME/.config/systemd/user" 2>/dev/null || true
cat > "$REAL_HOME/.config/systemd/user/fusuma.service" << 'EOF' 2>/dev/null || true
[Unit]
Description=Fusuma Multitouch Gestures
After=graphical-session.target

[Service]
ExecStart=/usr/bin/env fusuma
Restart=on-failure

[Install]
WantedBy=graphical-session.target
EOF

# Ajustar permisos
if [ -n "$SUDO_USER" ]; then
    chown -R "$SUDO_USER:$SUDO_USER" "$REAL_HOME/.config/fusuma" 2>/dev/null || true
    chown -R "$SUDO_USER:$SUDO_USER" "$REAL_HOME/.config/systemd" 2>/dev/null || true
fi

# Activar servicio como usuario real
run_as_user systemctl --user daemon-reload 2>/dev/null || true
run_as_user systemctl --user enable --now fusuma.service 2>/dev/null || true

set -e
echo -e "${GREEN}✅ Fusuma y Arrastre con 3 dedos configurados.${NC}"
echo ""

# =============================================================================
# PASO 23: GESTOR DE PORTAPAPELES MINIMALISTA
# =============================================================================
echo -e "${YELLOW}📋 [23/25] Configurando Gestor de Portapapeles estilo macOS...${NC}"

set +e

if [ "$IS_GNOME" = true ]; then
    run_as_user gnome-extensions enable clipboard-indicator@tudmotu.com 2>/dev/null || true
    echo -e "${GREEN}   ✓ Clipboard Indicator activado para GNOME${NC}"
elif [ "$IS_CINNAMON" = true ]; then
    echo -e "${GREEN}   ✓ Clipit instalado para Cinnamon (inícialo desde el menú)${NC}"
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    echo -e "${GREEN}   ✓ Clipman instalado para XFCE (añádelo al panel manualmente)${NC}"
fi

set -e
echo -e "${GREEN}✅ Gestor de Portapapeles configurado.${NC}"
echo ""

# =============================================================================
# PASO 24: VERIFICACIÓN POST-INSTALACIÓN INTELIGENTE
# =============================================================================
echo -e "${YELLOW} [24/25] Verificando instalación completa...${NC}"

CRITICAL_ERRORS=0
OPTIONAL_ERRORS=0

# Verificar fuentes
echo -e "${BLUE}   → Verificando fuentes Apple...${NC}"
FONTS_FOUND=false
if sudo -u "$REAL_USER" fc-list 2>/dev/null | grep -qi "SF Pro"; then
    FONTS_FOUND=true
fi
if find "$REAL_HOME/.local/share/fonts" /usr/local/share/fonts /usr/share/fonts -name "SF-Pro*" 2>/dev/null | grep -q "SF-Pro"; then
    FONTS_FOUND=true
fi

if [ "$FONTS_FOUND" = true ]; then
    echo -e "   ${GREEN}✓ Fuentes Apple instaladas${NC}"
else
    echo -e "   ${RED}✗ CRÍTICO: Fuentes Apple no encontradas${NC}"
    CRITICAL_ERRORS=$((CRITICAL_ERRORS + 1))
fi

# Verificar tema GTK
echo -e "${BLUE}   → Verificando tema GTK...${NC}"
THEME_FOUND=false
[ -d "$REAL_HOME/.themes/MacTahoe-Dark" ] && THEME_FOUND=true
[ -d "$REAL_HOME/.local/share/themes/MacTahoe-Dark" ] && THEME_FOUND=true
[ -d "/usr/share/themes/MacTahoe-Dark" ] && THEME_FOUND=true

if [ "$THEME_FOUND" = true ]; then
    echo -e "   ${GREEN}✓ Tema GTK instalado${NC}"
else
    echo -e "   ${RED}✗ CRÍTICO: Tema GTK no instalado${NC}"
    CRITICAL_ERRORS=$((CRITICAL_ERRORS + 1))
fi

# Verificar iconos y cursores
echo -e "${BLUE}   → Verificando iconos y cursores...${NC}"
ICONS_FOUND=false
[ -d "$REAL_HOME/.icons/MacTahoe-dark" ] && ICONS_FOUND=true
[ -d "$REAL_HOME/.local/share/icons/MacTahoe-dark" ] && ICONS_FOUND=true
[ -d "/usr/share/icons/MacTahoe-dark" ] && ICONS_FOUND=true

if [ "$ICONS_FOUND" = true ]; then
    echo -e "   ${GREEN}✓ Iconos y cursores instalados${NC}"
else
    echo -e "   ${RED}✗ CRÍTICO: Iconos y cursores no instalados${NC}"
    CRITICAL_ERRORS=$((CRITICAL_ERRORS + 1))
fi

# Verificar sonidos
echo -e "${BLUE}   → Verificando sonidos...${NC}"
SOUNDS_FOUND=false
[ -d "$REAL_HOME/.local/share/sounds/bigsur" ] && SOUNDS_FOUND=true
[ -d "/usr/share/sounds/bigsur" ] && SOUNDS_FOUND=true

if [ "$SOUNDS_FOUND" = true ]; then
    echo -e "   ${GREEN}✓ Sonidos instalados${NC}"
else
    echo -e "   ${RED}✗ CRÍTICO: Sonidos del sistema no instalados${NC}"
    CRITICAL_ERRORS=$((CRITICAL_ERRORS + 1))
fi

# Verificaciones opcionales
echo -e "${BLUE}   → Verificando componentes opcionales...${NC}"

if [ -f "$REAL_HOME/.local/bin/rofi-spotlight-launcher" ]; then
    echo -e "   ${GREEN}✓ Rofi Spotlight instalado${NC}"
else
    echo -e "   ${YELLOW}⚠ OPCIONAL: Rofi Spotlight no instalado${NC}"
    OPTIONAL_ERRORS=$((OPTIONAL_ERRORS + 1))
fi

if run_as_user systemctl --user is-active --quiet fusuma.service 2>/dev/null; then
    echo -e "   ${GREEN}✓ Gestos Fusuma activos${NC}"
else
    echo -e "   ${YELLOW}⚠ OPCIONAL: Gestos Fusuma no activos${NC}"
    echo -e "   ${BLUE}   (Puede activarse después con: systemctl --user enable --now fusuma)${NC}"
    OPTIONAL_ERRORS=$((OPTIONAL_ERRORS + 1))
fi

if command -v sushi &> /dev/null || command -v gloobus-preview &> /dev/null; then
    echo -e "   ${GREEN}✓ Quick Look disponible${NC}"
else
    echo -e "   ${YELLOW}⚠ OPCIONAL: Quick Look no disponible${NC}"
    OPTIONAL_ERRORS=$((OPTIONAL_ERRORS + 1))
fi

echo ""

# =============================================================================
# TOMA DE DECISIÓN
# =============================================================================
if [ "$CRITICAL_ERRORS" -gt 0 ]; then
    echo -e "${RED}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   ❌ INSTALACIÓN FALLIDA - EJECUTANDO RESTAURACIÓN     ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Se detectaron $CRITICAL_ERRORS componente(s) crítico(s) faltante(s).${NC}"
    echo -e "${YELLOW}Para evitar dejar el sistema en un estado inconsistente, se ejecutará${NC}"
    echo -e "${YELLOW}el script de restauración automáticamente...${NC}"
    echo ""
    sleep 3
    
    if [ -f "$WORKDIR/uninstall_rollback.sh" ]; then
        bash "$WORKDIR/uninstall_rollback.sh" --auto
    else
        echo -e "${RED}❌ El script de restauración no está disponible.${NC}"
        echo -e "${YELLOW}Por favor, ejecuta manualmente:${NC}"
        echo -e "   curl -sSL https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/uninstall.sh | bash -s -- --auto"
    fi
    exit 1
    
elif [ "$OPTIONAL_ERRORS" -gt 0 ]; then
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║   ⚠️  INSTALACIÓN COMPLETADA CON ADVERTENCIAS           ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}✅ Los componentes críticos se instalaron correctamente.${NC}"
    echo -e "${YELLOW}⚠️  $OPTIONAL_ERRORS componente(s) opcional(es) no se pudieron instalar.${NC}"
    echo -e "${YELLOW}   El sistema es funcional, pero algunas características avanzadas${NC}"
    echo -e "${YELLOW}   pueden no estar disponibles.${NC}"
    echo ""
else
    echo -e "${GREEN}✅ Todos los componentes verificados correctamente.${NC}"
    echo ""
fi

# Desactivar trampa de error
if [ "$CRITICAL_ERRORS" -eq 0 ]; then
    INSTALLATION_SUCCESS=true
    trap - ERR
fi

# Mensaje final
if [ "$CRITICAL_ERRORS" -eq 0 ]; then
    echo -e "${CYAN}══════════════════════════════════════════════════════════╗${NC}"
    if [ "$OPTIONAL_ERRORS" -eq 0 ]; then
        echo -e "${CYAN}║         ¡INSTALACIÓN COMPLETADA CON ÉXITO! 🎉         ║${NC}"
    else
        echo -e "${YELLOW}║   ⚠️  INSTALACIÓN PARCIAL - REINICIAR PARA APLICAR     ║${NC}"
    fi
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}✨ Tu sistema Linux ahora tiene la experiencia ULTIMA de macOS Tahoe.${NC}"
    echo -e "${YELLOW}️  IMPORTANTE: Debes REINICIAR EL EQUIPO para que surtan efecto:${NC}"
    echo -e "${YELLOW}   • Permisos del grupo 'input' (para los gestos Fusuma)${NC}"
    echo -e "${YELLOW}   • Configuración de aplicaciones Qt${NC}"
    echo -e "${YELLOW}   • Tema de arranque Plymouth (si fue instalado)${NC}"
    echo ""
fi

# Registrar versión instalada
echo "$(date '+%Y-%m-%d')" > "$WORKDIR/.installed_version" 2>/dev/null || true
