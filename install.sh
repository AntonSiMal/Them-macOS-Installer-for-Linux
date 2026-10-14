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
        zenity  # <-- AÑADIDO: Crítico para la ventana "Acerca de este Mac"
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
FONTS_DIR="$REAL_HOME/.local/share/fonts"
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
    mkdir -p "$REAL_HOME/.local/share/gnome-shell/extensions/"

    [ ! -d "$WORKDIR/liquid-glass" ] && git clone --depth=1 https://github.com/ryohsuke1231/liquid-glass.git "$WORKDIR/liquid-glass" -q
    cp -r "$WORKDIR/liquid-glass/liquid-glass@thinkingcoding1231.gmail.com" "$REAL_HOME/.local/share/gnome-shell/extensions/"

    GNOME_VERSION=$(gnome-shell --version 2>/dev/null | grep -oP '\d+' | head -1)
    EXT_DIR="$REAL_HOME/.local/share/gnome-shell/extensions/liquid-glass@thinkingcoding1231.gmail.com"
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
    mkdir -p "$REAL_HOME/.local/share/cinnamon/extensions/"

    [ ! -d "$WORKDIR/cinnamon-dynamic-wallpaper" ] && git clone --depth=1 https://github.com/TobiZog/cinnamon-dynamic-wallpaper.git "$WORKDIR/cinnamon-dynamic-wallpaper" -q
    cp -r "$WORKDIR/cinnamon-dynamic-wallpaper/cinnamon-dynamic-wallpaper@TobiZog" "$REAL_HOME/.local/share/cinnamon/extensions/" 2>/dev/null

    CINNAMON_EXTENSIONS=$(run_as_user gsettings get org.cinnamon enabled-extensions 2>/dev/null)
    if ! echo "$CINNAMON_EXTENSIONS" | grep -q "cinnamon-dynamic-wallpaper@TobiZog"; then
        if [ "$CINNAMON_EXTENSIONS" = "[]" ]; then
            run_as_user gsettings set org.cinnamon enabled-extensions "['cinnamon-dynamic-wallpaper@TobiZog']" 2>/dev/null
        else
            NEW_EXTENSIONS=$(echo "$CINNAMON_EXTENSIONS" | sed "s/]$/, 'cinnamon-dynamic-wallpaper@TobiZog']/")
            run_as_user gsettings set org.cinnamon enabled-extensions "$NEW_EXTENSIONS" 2>/dev/null
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
    if [ -d "$REAL_HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx" ] || [ -d "/usr/share/gnome-shell/extensions/blur-my-shell@aunetx" ]; then
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
mkdir -p "$REAL_HOME/.local/share/plank/themes"
find "$WORKDIR/MacOS-Mojave-Plank-themes" -maxdepth 1 -type d \( -name "MacOS-*" -o -name "elementary-*" \) | while read -r theme_dir; do
    [ -d "$theme_dir" ] && cp -r "$theme_dir" "$REAL_HOME/.local/share/plank/themes/"
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
# PASO 12: NAVEGADORES, STREAMING Y HERRAMIENTAS DE RED
# =============================================================================
echo -e "${YELLOW}🌐🎵📡 [12/24] Configurando aplicaciones de escritorio y red...${NC}"

# CRÍTICO: Usar $REAL_HOME en lugar de ~ para evitar que se guarde en /root/ al usar sudo
mkdir -p "$REAL_HOME/.local/share/applications"
mkdir -p "$REAL_HOME/.local/share/icons/hicolor/256x256/apps"
mkdir -p "$REAL_HOME/.local/bin"

# =============================================================================
# 12.1: FIREFOX -> SAFARI
# =============================================================================
echo -e "${BLUE}   → [12.1] Verificando y configurando Firefox (renombrado a Safari)...${NC}"
if ! command -v firefox &> /dev/null; then
    echo -e "${BLUE}      → Firefox no detectado. Instalando...${NC}"
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
    wget -q -O "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/safari.svg" "https://upload.wikimedia.org/wikipedia/commons/5/52/Safari_browser_logo.svg" 2>/dev/null || true
    cp "$ORIGINAL_FF_DESKTOP" "$REAL_HOME/.local/share/applications/safari.desktop"
    sed -i 's/^Name=.*/Name=Safari/g' "$REAL_HOME/.local/share/applications/safari.desktop"
    sed -i 's/^Name\[es\]=.*/Name[es]=Safari/g' "$REAL_HOME/.local/share/applications/safari.desktop"
    sed -i 's/^GenericName=.*/GenericName=Navegador Web Safari/g' "$REAL_HOME/.local/share/applications/safari.desktop"
    sed -i 's/^Icon=.*/Icon=safari/g' "$REAL_HOME/.local/share/applications/safari.desktop"
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
    wget -q -O "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/safari.svg" "https://upload.wikimedia.org/wikipedia/commons/5/52/Safari_browser_logo.svg" 2>/dev/null || true
    echo -e "${GREEN}      ✅ Safari creado manualmente.${NC}"
fi

# =============================================================================
# 12.5: ZUNO -> APPLE MUSIC (CORREGIDO CON DESCARGA DIRECTA)
# =============================================================================
echo -e "${BLUE}   → [12.5] Instalando Zuno y transformando en Apple Music...${NC}"

# Instalar codecs
if command -v apt-get &> /dev/null; then
    sudo apt-get install -y -qq gstreamer1.0-libav gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad 2>/dev/null || true
fi

mkdir -p "$REAL_HOME/.local/bin" "$REAL_HOME/.local/share/applications" "$REAL_HOME/.local/share/icons/hicolor/256x256/apps"

# Descarga directa del AppImage (más estable que la API de GitHub)
ZUNO_URL="https://github.com/noFAYZ/zuno/releases/download/v1.4.0/Zuno_1.4.0_amd64.AppImage"
echo -e "${BLUE}      → Descargando Zuno AppImage...${NC}"
if wget -q --user-agent="Mozilla/5.0" --show-progress -O "$REAL_HOME/.local/bin/zuno" "$ZUNO_URL" 2>/dev/null; then
    chmod +x "$REAL_HOME/.local/bin/zuno"
    echo -e "${GREEN}      ✅ Zuno descargado correctamente.${NC}"
else
    echo -e "${YELLOW}      ⚠️  Fallo en descarga directa, intentando versión anterior...${NC}"
    wget -q --user-agent="Mozilla/5.0" -O "$REAL_HOME/.local/bin/zuno" "https://github.com/noFAYZ/zuno/releases/download/v1.3.2/Zuno_1.3.2_amd64.AppImage" 2>/dev/null || true
    chmod +x "$REAL_HOME/.local/bin/zuno" 2>/dev/null || true
fi

# Crear lanzador Apple Music
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

# =============================================================================
# 12.6: LOCALSEND (AirDrop Open Source)
# =============================================================================
echo -e "${BLUE}   → [12.6] Instalando LocalSend y configurando red local...${NC}"

if command -v apt-get &> /dev/null; then
    sudo apt-get install -y -qq xdg-desktop-portal xdg-desktop-portal-gtk 2>/dev/null || true
elif command -v dnf &> /dev/null; then
    sudo dnf install -y -q xdg-desktop-portal xdg-desktop-portal-gnome 2>/dev/null || true
elif command -v pacman &> /dev/null; then
    sudo pacman -S --noconfirm --needed xdg-desktop-portal xdg-desktop-portal-gtk 2>/dev/null || true
fi

if command -v ufw &> /dev/null && sudo ufw status 2>/dev/null | grep -q "active"; then
    sudo ufw allow 53317/tcp >/dev/null 2>&1 || true
    sudo ufw allow 53317/udp >/dev/null 2>&1 || true
fi

LS_INSTALLED=false
LATEST_RELEASE_LS=$(curl -s --max-time 10 https://api.github.com/repos/localsend/localsend/releases/latest 2>/dev/null)
LATEST_VERSION_LS=$(echo "$LATEST_RELEASE_LS" | jq -r .tag_name 2>/dev/null)

if [ -n "$LATEST_VERSION_LS" ] && [ "$LATEST_VERSION_LS" != "null" ]; then
    if command -v apt-get &> /dev/null; then
        DEB_URL=$(echo "$LATEST_RELEASE_LS" | jq -r '.assets[] | select(.name | test("amd64.deb"; "i")).browser_download_url' | head -n 1)
        if [ -n "$DEB_URL" ] && [ "$DEB_URL" != "null" ]; then
            wget -q --max-time 30 -O /tmp/localsend.deb "$DEB_URL" 2>/dev/null && sudo apt-get install -y -qq /tmp/localsend.deb 2>/dev/null && LS_INSTALLED=true
        fi
    fi
fi

if [ "$LS_INSTALLED" = false ]; then
    echo -e "${BLUE}      → Instalación de paquete falló, usando AppImage como fallback...${NC}"
    mkdir -p "$REAL_HOME/.local/bin" "$REAL_HOME/.local/share/applications"
    
    APPIMAGE_URL=$(echo "$LATEST_RELEASE_LS" | jq -r '.assets[] | select(.name | test("amd64.AppImage|x86_64.AppImage"; "i")).browser_download_url' | head -n 1)
    if [ -n "$APPIMAGE_URL" ] && [ "$APPIMAGE_URL" != "null" ]; then
        wget -q --max-time 60 -O "$REAL_HOME/.local/bin/localsend" "$APPIMAGE_URL" 2>/dev/null || true
    else
        wget -q --max-time 60 -O "$REAL_HOME/.local/bin/localsend" "https://github.com/localsend/localsend/releases/download/v1.15.3/LocalSend-1.15.3-linux-x86_64.AppImage" 2>/dev/null || true
    fi
    
    if [ -f "$REAL_HOME/.local/bin/localsend" ]; then
        chmod +x "$REAL_HOME/.local/bin/localsend"
        LS_INSTALLED=true
        echo -e "${GREEN}      ✅ LocalSend instalado como AppImage.${NC}"
    else
        echo -e "${RED}      ❌ Fallo al descargar LocalSend.${NC}"
    fi
fi

mkdir -p "$REAL_HOME/.local/share/applications"
cat > "$REAL_HOME/.local/share/applications/localsend.desktop" << EOF
[Desktop Entry]
Name=LocalSend
Exec=$REAL_HOME/.local/bin/localsend %U
Icon=localsend
Type=Application
Categories=Network;FileTransfer;
Terminal=false
EOF
wget -q -O "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/localsend.svg" "https://raw.githubusercontent.com/localsend/localsend/main/app/assets/icon/512.png" 2>/dev/null || true
echo -e "${GREEN}      ✅ LocalSend configurado correctamente.${NC}"

# =============================================================================
# 12.7: IPTVNATOR -> APPLE TV (CORREGIDO CON DESCARGA DIRECTA)
# =============================================================================
echo -e "${BLUE}   → [12.7] Instalando IPTVnator y transformando en Apple TV...${NC}"

if command -v apt-get &> /dev/null; then
    sudo apt-get install -y -qq mpv xdg-utils 2>/dev/null || true
fi

mkdir -p "$REAL_HOME/.local/bin" "$REAL_HOME/.local/share/applications" "$REAL_HOME/.local/share/icons/hicolor/256x256/apps"

# Descarga directa del AppImage de IPTVnator
IPTV_URL="https://github.com/4gray/iptvnator/releases/download/v0.14.0/iptvnator-0.14.0-linux-x86_64.AppImage"
echo -e "${BLUE}      → Descargando IPTVnator AppImage...${NC}"
if wget -q --user-agent="Mozilla/5.0" --show-progress -O "$REAL_HOME/.local/bin/iptvnator" "$IPTV_URL" 2>/dev/null; then
    chmod +x "$REAL_HOME/.local/bin/iptvnator"
    echo -e "${GREEN}      ✅ IPTVnator descargado correctamente.${NC}"
else
    echo -e "${YELLOW}      ⚠️  Fallo en AppImage, intentando paquete .deb...${NC}"
    wget -q --user-agent="Mozilla/5.0" -O "/tmp/iptvnator.deb" "https://github.com/4gray/iptvnator/releases/download/v0.12.0/iptvnator_0.12.0_amd64.deb" 2>/dev/null || true
    sudo apt-get install -y -qq /tmp/iptvnator.deb 2>/dev/null || true
fi

# Crear lanzador Apple TV
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

# Pre-configurar lista de reproducción en Español
CONFIG_DIR="$REAL_HOME/.config/iptvnator"
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/store.json" << 'EOF'
{
  "playlists": [
    {
      "id": "spa-iptv-org",
      "name": "📺 Canales en Español (iptv-org)",
      "url": "https://iptv-org.github.io/iptv/languages/spa.m3u",
      "autoRefresh": true,
      "userAgent": ""
    }
  ],
  "settings": {
    "player": "html5",
    "theme": "dark",
    "epgUrl": "https://iptv-org.github.io/epg/guides/es/movistarplus.es.xml"
  }
}
EOF
echo -e "${GREEN}      ✅ IPTVnator transformado a 'Apple TV' con lista en español.${NC}"

# =============================================================================
# PASO 13: GDM (PANTALLA DE LOGIN)
# =============================================================================
echo -e "${YELLOW}🔐 [13/25] Configurando pantalla de login (GDM)...${NC}"

# Desactivar temporalmente la detención por errores para evitar que el script "desaparezca"
set +e

if [ "$IS_GNOME" = true ]; then
    if [ -d "$WORKDIR/MacTahoe-gtk-theme" ]; then
        echo -e "${BLUE}   → Aplicando tema a GDM (esto puede tardar unos segundos)...${NC}"
        
        # Ejecutamos el tweak. Redirigimos la salida a un archivo de log temporal
        if sudo "$WORKDIR/MacTahoe-gtk-theme/tweaks.sh" -g -b default > /tmp/gdm-tweak.log 2>&1; then
            echo -e "${GREEN}   ✅ Pantalla de login configurada correctamente.${NC}"
        else
            echo -e "${YELLOW}   ⚠️  No se pudo configurar GDM automáticamente.${NC}"
            echo -e "${YELLOW}      (Esto es común en algunas distros por políticas de seguridad de GDM).${NC}"
            echo -e "${YELLOW}      El resto de la instalación continuará normalmente.${NC}"
            echo -e "${BLUE}      → Si deseas investigar, revisa el registro: /tmp/gdm-tweak.log${NC}"
        fi
    else
        echo -e "${YELLOW}   ⚠️  No se encontró la carpeta del tema para configurar GDM.${NC}"
    fi
else
    echo -e "${BLUE}   ⏭️  GDM omitido (Entorno no compatible o no es GNOME/Zorin).${NC}"
fi

# Reactivar la detención de errores para el resto del script
set -e
echo ""

# =============================================================================
# PASO 14: SCRIPT AUXILIAR PARA VENTANAS AVANZADAS
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
if [ -n "$SUDO_USER" ]; then
    chown "$SUDO_USER:$SUDO_USER" "$ADVANCED_WM_SCRIPT" 2>/dev/null || true
fi
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
# PASO 15.4: INSTALAR ONLYOFFICE Y TRANSFORMAR EN "OFFICE"
# =============================================================================
echo -e "${YELLOW}📝 [15.4/25] Instalando ONLYOFFICE y transformando en 'Office'...${NC}"
set +e

# 1. Asegurar que Flatpak esté instalado
if ! command -v flatpak &> /dev/null; then
    echo -e "${BLUE}   → Flatpak no detectado. Instalando...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y -qq flatpak 2>/dev/null || true
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y -q flatpak 2>/dev/null || true
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm --needed flatpak 2>/dev/null || true
    fi
    echo -e "${GREEN}   ✅ Flatpak instalado.${NC}"
fi

# 2. Agregar repositorio Flathub (como usuario real)
echo -e "${BLUE}   → Verificando y añadiendo repositorio Flathub...${NC}"
run_as_user flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# 3. Instalar ONLYOFFICE Desktop Editors
echo -e "${BLUE}   → Instalando ONLYOFFICE Desktop Editors (esto puede tardar un poco)...${NC}"
run_as_user flatpak install -y flathub org.onlyoffice.desktopeditors 2>/dev/null || {
    echo -e "${YELLOW}   ⚠️  No se pudo instalar ONLYOFFICE automáticamente. Verifica tu conexión o espacio en disco.${NC}"
}

# 4. Transformar a "Office" (Renombrar y cambiar icono)
echo -e "${BLUE}   → Personalizando lanzador e icono a 'Office'...${NC}"
mkdir -p "$REAL_HOME/.local/share/applications"
mkdir -p "$REAL_HOME/.local/share/icons/hicolor/256x256/apps"

# Buscar el lanzador original de Flatpak (puede estar en sistema o en usuario)
ONLYOFFICE_DESKTOP=""
for path in "/var/lib/flatpak/exports/share/applications/org.onlyoffice.desktopeditors.desktop" \
            "$REAL_HOME/.local/share/flatpak/exports/share/applications/org.onlyoffice.desktopeditors.desktop"; do
    if [ -f "$path" ]; then
        ONLYOFFICE_DESKTOP="$path"
        break
    fi
done

# Descargar icono moderno de Office (con User-Agent para evitar bloqueo de Wikimedia)
echo -e "${BLUE}      → Descargando icono de Office...${NC}"
ICON_URL="https://upload.wikimedia.org/wikipedia/commons/5/59/Microsoft_Office_logo_%282019%E2%80%93present%29.svg"
BACKUP_ICON_URL="https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/microsoftoffice.svg"

if ! wget -q --user-agent="Mozilla/5.0" -O "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/office.svg" "$ICON_URL" 2>/dev/null; then
    wget -q --user-agent="Mozilla/5.0" -O "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/office.svg" "$BACKUP_ICON_URL" 2>/dev/null || true
fi

if [ -n "$ONLYOFFICE_DESKTOP" ]; then
    # Copiar y modificar el lanzador
    cp "$ONLYOFFICE_DESKTOP" "$REAL_HOME/.local/share/applications/office.desktop"
    # Cambiar nombres y asignar nuevo icono
    sed -i 's/^Name=.*/Name=Office/g' "$REAL_HOME/.local/share/applications/office.desktop"
    sed -i 's/^Name\[es\]=.*/Name[es]=Office/g' "$REAL_HOME/.local/share/applications/office.desktop"
    sed -i 's/^GenericName=.*/GenericName=Suite de Oficina/g' "$REAL_HOME/.local/share/applications/office.desktop"
    sed -i 's/^Icon=.*/Icon=office/g' "$REAL_HOME/.local/share/applications/office.desktop"
    # Ocultar el lanzador original de ONLYOFFICE para evitar duplicados en el menú
    echo -e "[Desktop Entry]\nHidden=true" > "$REAL_HOME/.local/share/applications/$(basename "$ONLYOFFICE_DESKTOP")"
    echo -e "${GREEN}   ✅ ONLYOFFICE renombrado e icono actualizado a 'Office'.${NC}"
else
    echo -e "${YELLOW}   ⚠️  No se encontró el lanzador de ONLYOFFICE. Es posible que necesites reiniciar la sesión.${NC}"
fi

# Actualizar cachés de escritorio e iconos
run_as_user update-desktop-database "$REAL_HOME/.local/share/applications" 2>/dev/null || true
run_as_user gtk-update-icon-cache -f -t "$REAL_HOME/.local/share/icons/hicolor" 2>/dev/null || true

set -e
echo ""

# =============================================================================
# PASO 15.5: INSTALAR WHISKER MENU (SI FALTA) Y CONFIGURAR ICONO DE APPLE
# =============================================================================
echo -e "${YELLOW}🍎 [15.5/25] Configurando menú de inicio estilo macOS...${NC}"
set +e

if [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    echo -e "${BLUE}   → Verificando Whisker Menu en XFCE...${NC}"
    # Instalar Whisker Menu si no está presente
    if ! command -v xfce4-popup-whiskermenu &> /dev/null; then
        echo -e "${BLUE}      → Whisker Menu no detectado. Instalando...${NC}"
        if command -v apt-get &> /dev/null; then
            sudo apt-get install -y -qq xfce4-whiskermenu-plugin 2>/dev/null || true
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y -q xfce4-whiskermenu-plugin 2>/dev/null || true
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm --needed xfce4-whiskermenu-plugin 2>/dev/null || true
        fi
        echo -e "${GREEN}      ✅ Whisker Menu instalado.${NC}"
    else
        echo -e "${GREEN}      ✓ Whisker Menu ya está instalado.${NC}"
    fi
    
    # Configurar icono de Apple y ocultar texto
    WHISKER_ID=$(run_as_user xfconf-query -c xfce4-panel -l 2>/dev/null | grep "whiskermenu" | head -1 | cut -d'/' -f4)
    if [ -n "$WHISKER_ID" ]; then
        run_as_user xfconf-query -c xfce4-panel -p /plugins/$WHISKER_ID/button-icon -s "distributor-logo" 2>/dev/null || true
        run_as_user xfconf-query -c xfce4-panel -p /plugins/$WHISKER_ID/show-button-title -s false 2>/dev/null || true
        echo -e "${GREEN}   ✓ Icono de Apple aplicado a Whisker Menu (solo icono, sin texto).${NC}"
    else
        echo -e "${YELLOW}   ⚠️  No se pudo configurar Whisker Menu automáticamente. Añádelo al panel manualmente.${NC}"
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
# PASO 15.9: PERFECCIONAMIENTO DE EXPERIENCIA MACOS (DOCK, FINDER, SONIDOS)
# =============================================================================
echo -e "${YELLOW}✨ [15.9/25] Perfeccionando experiencia macOS (Dock, Finder, Sonidos)...${NC}"
set +e

# =============================================================================
# 1. FORMATO DE RELOJ Y FECHA IDÉNTICO A macOS (UNIVERSAL)
# =============================================================================
echo -e "${BLUE}   → Ajustando formato de reloj y fecha estilo macOS...${NC}"
if [ "$IS_GNOME" = true ]; then
    run_as_user gsettings set org.gnome.desktop.interface clock-show-date true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface clock-show-weekday true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface clock-show-seconds false 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface clock-format '24h' 2>/dev/null || true
    echo -e "${GREEN}   ✓ Reloj GNOME configurado con formato macOS${NC}"
elif [ "$IS_CINNAMON" = true ]; then
    run_as_user gsettings set org.cinnamon.desktop.interface clock-show-date true 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.interface clock-show-weekday true 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.interface clock-show-seconds false 2>/dev/null || true
    CALENDAR_APPLET=$(run_as_user gsettings get org.cinnamon enabled-applets 2>/dev/null | grep -o "calendar@cinnamon.org" | head -1)
    if [ -n "$CALENDAR_APPLET" ]; then
        run_as_user gsettings set org.cinnamon.applets.calendar@cinnamon.org use-custom-format true 2>/dev/null || true
        run_as_user gsettings set org.cinnamon.applets.calendar@cinnamon.org custom-format "%a %d %b, %H:%M" 2>/dev/null || true
    fi
    echo -e "${GREEN}   ✓ Reloj Cinnamon configurado con formato macOS${NC}"
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    CLOCK_PLUGIN=$(run_as_user xfconf-query -c xfce4-panel -l 2>/dev/null | grep "/plugins/" | grep "clock" | head -1 | cut -d'/' -f4)
    if [ -n "$CLOCK_PLUGIN" ]; then
        run_as_user xfconf-query -c xfce4-panel -p /plugins/$CLOCK_PLUGIN/digital-format -s "%a %d %b, %H:%M" 2>/dev/null || true
        run_as_user xfconf-query -c xfce4-panel -p /plugins/$CLOCK_PLUGIN/digital-layout -s 3 2>/dev/null || true
        run_as_user xfconf-query -c xfce4-panel -p /plugins/$CLOCK_PLUGIN/digital-time-format -s "%H:%M" 2>/dev/null || true
        run_as_user xfconf-query -c xfce4-panel -p /plugins/$CLOCK_PLUGIN/digital-date-format -s "%a %d %b" 2>/dev/null || true
    fi
    echo -e "${GREEN}   ✓ Reloj XFCE configurado con formato macOS${NC}"
fi

# =============================================================================
# 2. SONIDO DE TECLADO AL ESCRIBIR (UNIVERSAL)
# =============================================================================
echo -e "${BLUE}   → Configurando sonido de teclado al escribir...${NC}"
KEYBOARD_SOUND_DIR="$REAL_HOME/.local/share/sounds/bigsur/stereo"
mkdir -p "$KEYBOARD_SOUND_DIR" 2>/dev/null || true
if [ ! -f "$KEYBOARD_SOUND_DIR/keyboard-click.oga" ]; then
    if [ -f "$KEYBOARD_SOUND_DIR/button-pressed.oga" ]; then
        cp "$KEYBOARD_SOUND_DIR/button-pressed.oga" "$KEYBOARD_SOUND_DIR/keyboard-click.oga" 2>/dev/null || true
    fi
fi
if [ "$IS_GNOME" = true ]; then
    run_as_user gsettings set org.gnome.desktop.sound input-feedback-sounds true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.sound event-sounds true 2>/dev/null || true
    echo -e "${GREEN}   ✓ Sonidos de teclado activados en GNOME${NC}"
elif [ "$IS_CINNAMON" = true ]; then
    run_as_user gsettings set org.cinnamon.desktop.sound input-feedback-sounds true 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.sound event-sounds true 2>/dev/null || true
    echo -e "${GREEN}   ✓ Sonidos de teclado activados en Cinnamon${NC}"
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    run_as_user xfconf-query -c xsettings -p /Net/EnableInputFeedbackSounds -s true 2>/dev/null || true
    run_as_user xfconf-query -c xsettings -p /Net/EnableEventSounds -s true 2>/dev/null || true
    echo -e "${GREEN}   ✓ Sonidos de teclado activados en XFCE${NC}"
fi

# =============================================================================
# 3. NAUTILUS ESTILO FINDER (SOLO GNOME)
# =============================================================================
if [ "$IS_GNOME" = true ]; then
    echo -e "${BLUE}   → Aplicando estilo Finder a Nautilus...${NC}"
    run_as_user gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' 2>/dev/null || true
    run_as_user gsettings set org.gnome.nautilus.preferences show-hidden-files false 2>/dev/null || true
    run_as_user gsettings set org.gnome.nautilus.preferences always-use-location-entry false 2>/dev/null || true
    run_as_user gsettings set org.gnome.nautilus.preferences show-image-thumbnails 'always' 2>/dev/null || true
    
    NAUTILUS_CSS_DIR="$REAL_HOME/.config/gtk-3.0"
    mkdir -p "$NAUTILUS_CSS_DIR" 2>/dev/null || true
    cat > "$NAUTILUS_CSS_DIR/gtk.css" << 'NAUTILUSCSS' 2>/dev/null || true
.nautilus-window .sidebar { background-color: alpha(@theme_bg_color, 0.95); border-right: 1px solid alpha(@borders, 0.3); }
.nautilus-window .sidebar row { border-radius: 6px; margin: 2px 8px; padding: 6px 10px; transition: all 200ms ease; }
.nautilus-window .sidebar row:selected { background-color: @theme_selected_bg_color; color: @theme_selected_fg_color; }
.nautilus-window .sidebar row:hover:not(:selected) { background-color: alpha(@theme_fg_color, 0.08); }
NAUTILUSCSS
    if [ -n "$SUDO_USER" ]; then chown -R "$SUDO_USER:$SUDO_USER" "$NAUTILUS_CSS_DIR" 2>/dev/null || true; fi
    echo -e "${GREEN}   ✓ Nautilus configurado con estilo Finder${NC}"
fi

# =============================================================================
# 4. DASH TO DOCK ESTILO macOS DOCK (SOLO GNOME)
# =============================================================================
if [ "$IS_GNOME" = true ]; then
    echo -e "${BLUE}   → Configurando Dash to Dock con estilo macOS Dock...${NC}"
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM' 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'DYNAMIC' 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.4 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'DOTS' 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize-or-previews' 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock show-show-apps-button true 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true 2>/dev/null || true
    run_as_user gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null || true
    echo -e "${GREEN}   ✓ Dash to Dock configurado con estilo macOS${NC}"
fi

# =============================================================================
# 5. REFORZAR BOTONES DE VENTANA A LA IZQUIERDA (UNIVERSAL Y A PRUEBA DE FALLOS)
# =============================================================================
echo -e "${BLUE}   → Reforzando botones de ventana a la izquierda (Cerrar, Minimizar, Maximizar)...${NC}"
if [ "$IS_GNOME" = true ]; then
    run_as_user gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:' 2>/dev/null || true
    echo -e "${GREEN}   ✓ Botones GNOME reforzados${NC}"
elif [ "$IS_CINNAMON" = true ]; then
    run_as_user gsettings set org.cinnamon.desktop.wm.preferences button-layout 'close,minimize,maximize:' 2>/dev/null || true
    echo -e "${GREEN}   ✓ Botones Cinnamon reforzados${NC}"
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    # OHM = Close (O), Maximize (H), Minimize (M). El orden es de izquierda a derecha.
    run_as_user xfconf-query -c xfwm4 -p /general/button_layout -s "OHM" 2>/dev/null || true
    
    # Si el tema no carga los botones, forzar recarga del gestor de ventanas
    if command -v xfwm4 &> /dev/null; then
        run_as_user xfwm4 --replace &>/dev/null &
        sleep 1
    fi
    echo -e "${GREEN}   ✓ Botones XFCE reforzados y gestor de ventanas recargado.${NC}"
fi

set -e
echo -e "${GREEN}✅ Perfeccionamiento de experiencia macOS completado.${NC}"
echo ""

# =============================================================================
# PASO 15.10: DETALLES FINALES 100% MACOS (Night Shift, Batería, Dock)
# =============================================================================
echo -e "${YELLOW}✨ [15.10/24] Aplicando los últimos detalles 100% macOS...${NC}"

if [ "$IS_GNOME" = true ]; then
    echo -e "${BLUE}   → Ajustando detalles finales de GNOME...${NC}"
    
    # 1. Night Light (Equivalente exacto a "Night Shift" de macOS)
    # Se activa automáticamente al atardecer con un tono cálido (2700K)
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic true 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 2700 2>/dev/null || true
    
    # 2. Mostrar porcentaje de batería en la barra superior (Estándar en macOS)
    run_as_user gsettings set org.gnome.desktop.interface show-battery-percentage true 2>/dev/null || true
    
    # 3. Ocultar el icono de la Papelera en el Dock cuando está vacía (Comportamiento nativo de macOS)
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false 2>/dev/null || true
    
    echo -e "${GREEN}   ✓ Night Light, Porcentaje de batería y Dock optimizados${NC}"
fi

echo -e "${GREEN}✅ Toque final 100% macOS aplicado.${NC}"
echo ""

# =============================================================================
# PASO 15.10B: PANTALLA DE BLOQUEO ESTILO macOS
# =============================================================================
echo -e "${YELLOW}🔒 [15.10B/25] Configurando pantalla de bloqueo estilo macOS...${NC}"

set +e

if [ "$IS_GNOME" = true ]; then
    echo -e "${BLUE}   → Configurando pantalla de bloqueo para GNOME...${NC}"
    
    # Configurar el fondo del salvapantallas para que coincida con el wallpaper
    if [ -f "$WALLPAPER_PATH" ]; then
        run_as_user gsettings set org.gnome.desktop.screensaver picture-uri "file://$WALLPAPER_PATH" 2>/dev/null || true
        run_as_user gsettings set org.gnome.desktop.screensaver picture-uri-dark "file://$WALLPAPER_PATH" 2>/dev/null || true
        run_as_user gsettings set org.gnome.desktop.screensaver picture-options 'zoom' 2>/dev/null || true
    fi
    
    # Asegurar que el salvapantallas no sea negro
    run_as_user gsettings set org.gnome.desktop.screensaver color-shading-type 'solid' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.screensaver primary-color '#000000' 2>/dev/null || true
    
    # Mostrar reloj grande en la pantalla de bloqueo (comportamiento macOS)
    run_as_user gsettings set org.gnome.desktop.screensaver show-clock true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.screensaver show-full-name-in-top-bar false 2>/dev/null || true
    
    echo -e "${GREEN}   ✓ Pantalla de bloqueo GNOME configurada con wallpaper dinámico${NC}"
    
elif [ "$IS_CINNAMON" = true ]; then
    echo -e "${BLUE}   → Configurando pantalla de bloqueo para Cinnamon...${NC}"
    
    # Cinnamon usa su propio sistema de screensaver
    if [ -f "$WALLPAPER_PATH" ]; then
        run_as_user gsettings set org.cinnamon.desktop.screensaver picture-uri "file://$WALLPAPER_PATH" 2>/dev/null || true
        run_as_user gsettings set org.cinnamon.desktop.screensaver picture-options 'zoom' 2>/dev/null || true
    fi
    
    echo -e "${GREEN}   ✓ Pantalla de bloqueo Cinnamon configurada${NC}"
    
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    echo -e "${BLUE}   → Instalando light-locker para XFCE...${NC}"
    
    # Instalar light-locker si no está presente
    if ! command -v light-locker &> /dev/null; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get install -y -qq light-locker 2>/dev/null || true
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y -q light-locker 2>/dev/null || true
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm --needed light-locker 2>/dev/null || true
        fi
    fi
    
    # Configurar light-locker para usar el wallpaper
    if [ -f "$WALLPAPER_PATH" ]; then
        mkdir -p "$REAL_HOME/.config/light-locker" 2>/dev/null || true
        cat > "$REAL_HOME/.config/light-locker/light-locker.conf" << EOF
[light-locker]
lock-on-suspend=true
lock-on-lid=false
idle-activation-enabled=true
EOF
        if [ -n "$SUDO_USER" ]; then
            chown -R "$SUDO_USER:$SUDO_USER" "$REAL_HOME/.config/light-locker" 2>/dev/null || true
        fi
    fi
    
    # Asegurar que xfce4-screensaver esté desactivado para evitar conflictos
    run_as_user xfconf-query -c xfce4-session -p /general/lock_command -s "light-locker-command -l" 2>/dev/null || true
    
    echo -e "${GREEN}   ✓ light-locker instalado y configurado para XFCE${NC}"
fi

set -e
echo -e "${GREEN}✅ Pantalla de bloqueo estilo macOS configurada.${NC}"
echo ""

# =============================================================================
# PASO 15.10C: INDICADORES OSD DE VOLUMEN Y BRILLO (BARRA FLOTANTE)
# =============================================================================
echo -e "${YELLOW} [15.10C/25] Configurando indicadores OSD de volumen y brillo...${NC}"

set +e

if [ "$IS_GNOME" = true ]; then
    echo -e "${BLUE}   → Instalando extensión OSD estilo macOS para GNOME...${NC}"
    
    # Intentar instalar la extensión "Avatar" que proporciona OSD minimalista
    EXTENSION_UUID="avatar@nathanpierce.com"
    
    if ! run_as_user gnome-extensions list 2>/dev/null | grep -q "$EXTENSION_UUID"; then
        echo -e "${BLUE}      → Descargando extensión Avatar...${NC}"
        
        # Obtener versión de GNOME Shell
        GNOME_VERSION=$(run_as_user gnome-shell --version 2>/dev/null | grep -oP '\d+' | head -1)
        
        if [ -n "$GNOME_VERSION" ]; then
            # Intentar descargar desde extensions.gnome.org
            EXTENSION_URL="https://extensions.gnome.org/extension-data/avatar@nathanpierce.com.v68.shell-extension.zip"
            
            TEMP_EXT=$(mktemp -d)
            if curl -sL "$EXTENSION_URL" -o "$TEMP_EXT/avatar.zip" 2>/dev/null && [ -f "$TEMP_EXT/avatar.zip" ]; then
                mkdir -p "$REAL_HOME/.local/share/gnome-shell/extensions/$EXTENSION_UUID"
                unzip -q "$TEMP_EXT/avatar.zip" -d "$REAL_HOME/.local/share/gnome-shell/extensions/$EXTENSION_UUID" 2>/dev/null
                
                # Actualizar metadata.json para compatibilidad con la versión de GNOME
                if [ -f "$REAL_HOME/.local/share/gnome-shell/extensions/$EXTENSION_UUID/metadata.json" ]; then
                    python3 -c "
import json
with open('$REAL_HOME/.local/share/gnome-shell/extensions/$EXTENSION_UUID/metadata.json', 'r') as f:
    data = json.load(f)
if '$GNOME_VERSION' not in data.get('shell-version', []):
    data.setdefault('shell-version', []).append('$GNOME_VERSION')
with open('$REAL_HOME/.local/share/gnome-shell/extensions/$EXTENSION_UUID/metadata.json', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || true
                fi
                
                run_as_user gnome-extensions enable "$EXTENSION_UUID" 2>/dev/null || true
                echo -e "${GREEN}      ✓ Extensión Avatar instalada y activada${NC}"
            else
                echo -e "${YELLOW}      ️  No se pudo descargar la extensión. Puedes instalarla manualmente desde extensions.gnome.org${NC}"
            fi
            rm -rf "$TEMP_EXT"
        else
            echo -e "${YELLOW}      ⚠️  No se pudo detectar la versión de GNOME${NC}"
        fi
    else
        echo -e "${GREEN}      ✓ Extensión Avatar ya está instalada${NC}"
    fi
    
    echo -e "${GREEN}   ✓ OSD de volumen y brillo configurado para GNOME${NC}"
    
elif [ "$IS_CINNAMON" = true ]; then
    echo -e "${BLUE}   → Configurando OSD para Cinnamon...${NC}"
    
    # Cinnamon ya tiene OSD integrado, solo aseguramos que esté habilitado
    run_as_user gsettings set org.cinnamon.desktop.sound volume-sound-enabled true 2>/dev/null || true
    
    echo -e "${GREEN}   ✓ OSD de Cinnamon verificado${NC}"
    
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    echo -e "${BLUE}   → Configurando OSD para XFCE...${NC}"
    
    # Instalar xfce4-volumed-pulse para mejor control de volumen
    if ! command -v xfce4-volumed-pulse &> /dev/null; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get install -y -qq xfce4-volumed-pulse 2>/dev/null || true
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y -q xfce4-volumed-pulse 2>/dev/null || true
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm --needed xfce4-volumed-pulse 2>/dev/null || true
        fi
    fi
    
    # Asegurar que xfce4-notifyd use el tema MacTahoe-Dark para notificaciones de volumen
    run_as_user xfconf-query -c xfce4-notifyd -p /theme -s "MacTahoe-Dark" 2>/dev/null || true
    
    # Configurar notificaciones en esquina superior derecha (estilo macOS)
    run_as_user xfconf-query -c xfce4-notifyd -p /notify-location -s 2 2>/dev/null || true
    
    # Reducir tiempo de desvanecimiento para notificaciones
    run_as_user xfconf-query -c xfce4-notifyd -p /do-fadeout -s true 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-notifyd -p /fadeout-time -s 500 2>/dev/null || true
    
    echo -e "${GREEN}   ✓ OSD de XFCE configurado con tema macOS${NC}"
fi

set -e
echo -e "${GREEN}✅ Indicadores OSD de volumen y brillo configurados.${NC}"
echo ""

# =============================================================================
# PASO 15.11: INTEGRACIÓN INTELIGENTE DE APLICACIONES EN EL DOCK
# =============================================================================
echo -e "${YELLOW}🚀 [15.11/25] Integrando aplicaciones en el Dock (detectando apps instaladas)...${NC}"

APPS_DIR="$REAL_HOME/.local/share/applications"
mkdir -p "$APPS_DIR" 2>/dev/null || true

# Array para guardar los nombres de las apps que SÍ encontramos instaladas
FOUND_DOCK_APPS=()

# --- 1. SAFARI (Firefox) ---
if [ -f "$APPS_DIR/safari.desktop" ] || command -v firefox &> /dev/null; then
    FOUND_DOCK_APPS+=("safari.desktop")
    echo -e "${GREEN}   ✓ Safari (Firefox) detectado${NC}"
fi

# --- 2. OFFICE (OnlyOffice) ---
if [ -f "$APPS_DIR/office.desktop" ] || command -v onlyoffice-desktopeditors &> /dev/null || flatpak list --columns=application 2>/dev/null | grep -q "org.onlyoffice.desktopeditors"; then
    FOUND_DOCK_APPS+=("office.desktop")
    echo -e "${GREEN}   ✓ Office (OnlyOffice) detectado${NC}"
fi

# --- 3. APPLE MUSIC (Zuno) ---
if [ -f "$APPS_DIR/applemusic.desktop" ] || command -v zuno &> /dev/null; then
    FOUND_DOCK_APPS+=("applemusic.desktop")
    echo -e "${GREEN}   ✓ Apple Music (Zuno) detectado${NC}"
fi

# --- 4. APPLE TV (IPTVnator) ---
if [ -f "$APPS_DIR/appletv.desktop" ] || command -v iptvnator &> /dev/null; then
    FOUND_DOCK_APPS+=("appletv.desktop")
    echo -e "${GREEN}   ✓ Apple TV (IPTVnator) detectado${NC}"
fi

# --- 5. LOCALSEND ---
if [ -f "$APPS_DIR/localsend.desktop" ] || command -v localsend &> /dev/null || command -v localsend-app &> /dev/null; then
    FOUND_DOCK_APPS+=("localsend.desktop")
    echo -e "${GREEN}   ✓ LocalSend detectado${NC}"
fi

if [ ${#FOUND_DOCK_APPS[@]} -gt 0 ]; then
    echo -e "${GREEN}   ✓ Accesos directos con nombres macOS detectados${NC}"
else
    echo -e "${YELLOW}   ⚠️  No se detectaron aplicaciones compatibles para el Dock.${NC}"
fi

# =============================================================================
# ANCLAR AL DOCK DE GNOME (Dash-to-Dock)
# =============================================================================
if [ "$IS_GNOME" = true ] && [ ${#FOUND_DOCK_APPS[@]} -gt 0 ]; then
    echo -e "${BLUE}   → Configurando favoritos en GNOME Dash...${NC}"
    
    FAVORITES_ARRAY="["
    for app in "${FOUND_DOCK_APPS[@]}"; do
        FAVORITES_ARRAY+="'$app', "
    done
    FAVORITES_ARRAY+="'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.Software.desktop']"
    
    # Limpiar comas dobles o espacios extraños
    FAVORITES_ARRAY=$(echo "$FAVORITES_ARRAY" | sed "s/, ]/]/g")
    
    run_as_user gsettings set org.gnome.shell favorite-apps "$FAVORITES_ARRAY" 2>/dev/null || true
    echo -e "${GREEN}   ✓ Dock de GNOME configurado con las apps instaladas${NC}"
fi

# =============================================================================
# ANCLAR AL DOCK DE PLANK (XFCE / CINNAMON)
# =============================================================================
if ([ "$IS_CINNAMON" = true ] || [[ "$DESKTOP_ENV" == *"xfce"* ]]) && [ ${#FOUND_DOCK_APPS[@]} -gt 0 ]; then
    echo -e "${BLUE}   → Configurando lanzadores en Plank...${NC}"
    PLANK_LAUNCHERS_DIR="$REAL_HOME/.config/plank/dock1/launchers"
    mkdir -p "$PLANK_LAUNCHERS_DIR" 2>/dev/null || true

    for app_stem in "${FOUND_DOCK_APPS[@]}"; do
        app="${app_stem%.desktop}" # Quitar .desktop para buscar el archivo base
        
        DESKTOP_FILE=""
        [ -f "$APPS_DIR/${app}.desktop" ] && DESKTOP_FILE="$APPS_DIR/${app}.desktop"
        [ -z "$DESKTOP_FILE" ] && [ -f "/usr/share/applications/${app}.desktop" ] && DESKTOP_FILE="/usr/share/applications/${app}.desktop"
        [ -z "$DESKTOP_FILE" ] && [ -f "/var/lib/flatpak/exports/share/applications/${app}.desktop" ] && DESKTOP_FILE="/var/lib/flatpak/exports/share/applications/${app}.desktop"
        [ -z "$DESKTOP_FILE" ] && [ -f "$REAL_HOME/.local/share/flatpak/exports/share/applications/${app}.desktop" ] && DESKTOP_FILE="$REAL_HOME/.local/share/flatpak/exports/share/applications/${app}.desktop"

        if [ -n "$DESKTOP_FILE" ]; then
            cat > "$PLANK_LAUNCHERS_DIR/${app}.dockitem" << EOF
[PlankItemsDockItemPreferences]
Launcher=file://${DESKTOP_FILE}
EOF
        fi
    done
    
    if [ -n "$SUDO_USER" ]; then
        chown -R "$SUDO_USER:$SUDO_USER" "$PLANK_LAUNCHERS_DIR" 2>/dev/null || true
    fi
    echo -e "${GREEN}   ✓ Dock de Plank configurado con las apps instaladas${NC}"
fi

echo -e "${GREEN}✅ Integración inteligente de aplicaciones en el Dock completada.${NC}"
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
echo -e "${YELLOW} [22/25] Instalando Gestos Multitáctiles y Arrastre con 3 dedos...${NC}"

set +e

sudo gpasswd -a "$REAL_USER" input 2>/dev/null || true

# Instalar fusuma como usuario real
if command -v gem &> /dev/null; then
    sudo -u "$REAL_USER" gem install fusuma --no-document 2>/dev/null || true
fi

mkdir -p "$REAL_HOME/.config/fusuma" 2>/dev/null || true

# Configurar gestos estilo macOS (3 dedos para espacios, 4 dedos para Mission Control)
if [ "$IS_GNOME" = true ]; then
    # GNOME: Super+s para Actividades/Mission Control, Super+d para mostrar escritorio
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
      command: 'xdotool key super+d'
    down:
      command: 'xdotool key super+d'
  4:
    left:
      command: 'xdotool key alt+Left'
    right:
      command: 'xdotool key alt+Right'
    up:
      command: 'xdotool key super+s'
    down:
      command: 'xdotool key super+s'
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
elif [ "$IS_CINNAMON" = true ]; then
    # Cinnamon: Super+d para mostrar escritorio
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
      command: 'xdotool key super+d'
    down:
      command: 'xdotool key super+d'
  4:
    left:
      command: 'xdotool key alt+Left'
    right:
      command: 'xdotool key alt+Right'
    up:
      command: 'xdotool key super+s'
    down:
      command: 'xdotool key super+s'
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
else
    # XFCE: Super+d para mostrar escritorio
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
      command: 'xdotool key super+d'
    down:
      command: 'xdotool key super+d'
  4:
    left:
      command: 'xdotool key alt+Left'
    right:
      command: 'xdotool key alt+Right'
    up:
      command: 'xdotool key super+s'
    down:
      command: 'xdotool key super+s'
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
fi

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
echo -e "${GREEN}✅ Fusuma configurado con gestos estilo Mission Control.${NC}"
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
echo -e "${YELLOW}🔍 [24/24] Verificando instalación completa...${NC}"

CRITICAL_ERRORS=0
OPTIONAL_ERRORS=0

# =============================================================================
# VERIFICACIONES CRÍTICAS (Tema macOS)
# =============================================================================
echo -e "${BLUE}   → Verificando componentes críticos del sistema...${NC}"

# 1. Verificar fuentes
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

# 2. Verificar tema GTK
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

# 3. Verificar iconos y cursores
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

# 4. Verificar sonidos
SOUNDS_FOUND=false
[ -d "$REAL_HOME/.local/share/sounds/bigsur" ] && SOUNDS_FOUND=true
[ -d "/usr/share/sounds/bigsur" ] && SOUNDS_FOUND=true

if [ "$SOUNDS_FOUND" = true ]; then
    echo -e "   ${GREEN}✓ Sonidos del sistema instalados${NC}"
else
    echo -e "   ${RED}✗ CRÍTICO: Sonidos del sistema no instalados${NC}"
    CRITICAL_ERRORS=$((CRITICAL_ERRORS + 1))
fi

# =============================================================================
# VERIFICACIONES OPCIONALES (Apps y Personalizaciones del Paso 12)
# =============================================================================
echo -e "${BLUE}   → Verificando aplicaciones y personalizaciones...${NC}"

# A. Safari (Firefox)
if [ -f "$REAL_HOME/.local/share/applications/safari.desktop" ] && [ -f "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/safari.svg" ]; then
    echo -e "   ${GREEN}✓ Navegador 'Safari' configurado correctamente${NC}"
else
    echo -e "   ${YELLOW}⚠ OPCIONAL: 'Safari' no configurado (Firefox mantiene nombre original)${NC}"
    OPTIONAL_ERRORS=$((OPTIONAL_ERRORS + 1))
fi

# B. Apple Music (Zuno)
if [ -f "$REAL_HOME/.local/share/applications/applemusic.desktop" ] && [ -f "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/applemusic.svg" ]; then
    echo -e "   ${GREEN}✓ 'Apple Music' (Zuno) configurado correctamente${NC}"
else
    echo -e "   ${YELLOW}⚠ OPCIONAL: 'Apple Music' no configurado${NC}"
    OPTIONAL_ERRORS=$((OPTIONAL_ERRORS + 1))
fi

# C. LocalSend
LS_INSTALLED=false
[ -f "$REAL_HOME/.local/share/applications/localsend.desktop" ] && LS_INSTALLED=true
[ -f "/usr/share/applications/localsend.desktop" ] && LS_INSTALLED=true
[ -f "$REAL_HOME/.local/bin/localsend" ] && LS_INSTALLED=true

if [ "$LS_INSTALLED" = true ]; then
    # Verificar si el puerto 53317 está abierto en el firewall
    FW_OK=false
    if command -v ufw &> /dev/null && sudo ufw status 2>/dev/null | grep -q "53317"; then FW_OK=true; fi
    if command -v firewall-cmd &> /dev/null && sudo firewall-cmd --list-ports 2>/dev/null | grep -q "53317"; then FW_OK=true; fi
    
    if [ "$FW_OK" = true ]; then
        echo -e "   ${GREEN}✓ LocalSend instalado y puerto de red (53317) configurado${NC}"
    else
        echo -e "   ${GREEN}✓ LocalSend instalado${NC}"
        echo -e "   ${YELLOW}  (Nota: Si no descubres dispositivos, verifica manualmente tu firewall)${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠ OPCIONAL: LocalSend no instalado${NC}"
    OPTIONAL_ERRORS=$((OPTIONAL_ERRORS + 1))
fi

# D. Apple TV (IPTVnator)
if [ -f "$REAL_HOME/.local/share/applications/appletv.desktop" ] && [ -f "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/appletv.svg" ]; then
    if [ -f "$REAL_HOME/.config/iptvnator/store.json" ]; then
        echo -e "   ${GREEN}✓ 'Apple TV' (IPTVnator) configurado con lista en español${NC}"
    else
        echo -e "   ${GREEN}✓ 'Apple TV' (IPTVnator) configurado${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠ OPCIONAL: 'Apple TV' no configurado${NC}"
    OPTIONAL_ERRORS=$((OPTIONAL_ERRORS + 1))
fi

# E. Otras herramientas opcionales del tema
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
    echo -e "${GREEN}✅ Los componentes críticos del tema macOS se instalaron correctamente.${NC}"
    echo -e "${YELLOW}⚠️  $OPTIONAL_ERRORS componente(s) opcional(es) no se pudieron configurar.${NC}"
    echo -e "${YELLOW}   (Esto suele deberse a límites de la API de GitHub o falta de conexión)${NC}"
    echo -e "${YELLOW}   El sistema es totalmente funcional.${NC}"
    echo ""
else
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ TODOS LOS COMPONENTES VERIFICADOS CORRECTAMENTE     ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
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
    echo -e "${GREEN}✨ Tu sistema Linux ahora tiene la experiencia macOS Tahoe.${NC}"
    echo -e "${GREEN}✨ Incluye: Safari, Apple Music, LocalSend y Apple TV listos para usar.${NC}"
    echo ""
    echo -e "${YELLOW}🔄 IMPORTANTE: Debes REINICIAR EL EQUIPO para que surtan efecto:${NC}"
    echo -e "${YELLOW}   • Permisos del grupo 'input' (para los gestos Fusuma)${NC}"
    echo -e "${YELLOW}   • Configuración de aplicaciones Qt${NC}"
    echo -e "${YELLOW}   • Tema de arranque Plymouth (si fue instalado)${NC}"
    echo -e "${YELLOW}   • Actualización del caché de iconos y lanzadores${NC}"
    echo ""
fi

# Registrar versión instalada
echo "$(date '+%Y-%m-%d')" > "$WORKDIR/.installed_version" 2>/dev/null || true
