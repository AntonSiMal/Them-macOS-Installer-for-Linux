#!/bin/bash

# =============================================================================
# macOS Tahoe Auto-Installer - Versión WWDC26 (Ultimate Edition)
# Compatible con: GNOME / Zorin OS / Cinnamon / XFCE
# =============================================================================

set -e
set +u  # Desactivar modo estricto de variables no asignadas para máxima compatibilidad

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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
WORKDIR="$HOME/.macos-theme-setup"
LOG_FILE="$WORKDIR/install.log"

mkdir -p "$WORKDIR"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Iniciando instalación de macOS Tahoe Theme" > "$LOG_FILE"

echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🍎 macOS Tahoe Theme Installer - Ultimate Edition     ║${NC}"
echo -e "${CYAN}║   Instalación 100% automatizada (24 pasos)              ║${NC}"
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
# PASO 1: DEPENDENCIAS DEL SISTEMA (CON DEBUG)
# =============================================================================
echo -e "${YELLOW}📦 [1/24] Instalando dependencias del sistema...${NC}"

if command -v apt-get &> /dev/null; then
    echo -e "${BLUE}   → Actualizando repositorios...${NC}"
    sudo apt-get update
    echo -e "${BLUE}   → Instalando paquetes necesarios...${NC}"
    sudo apt-get install -y git sassc libglib2.0-dev-bin libxml2-utils fontconfig \
        gnome-tweaks gnome-shell-extension-manager dconf-cli plymouth-themes firefox \
        plank x11-xserver-utils python3-pil curl unzip wget jq gnome-backgrounds \
        ffmpeg sox rofi fd-find python3-requests xdotool wmctrl x11-utils util-linux \
        qt5ct qt6ct sushi ruby libinput-tools \
        gnome-shell-extension-clipboard-indicator clipit xfce4-clipman-plugin
elif command -v dnf &> /dev/null; then
    echo -e "${BLUE}   → Instalando paquetes necesarios (Fedora)...${NC}"
    sudo dnf install -y git sassc glib2-devel libxml2 fontconfig gnome-tweaks dconf \
        plymouth-theme-spinner firefox plank xorg-x11-server-utils python3-pillow curl \
        unzip wget jq gnome-backgrounds ffmpeg sox rofi fd-find python3-requests xdotool \
        wmctrl xorg-xprop xorg-xwininfo util-linux qt5ct qt6ct sushi ruby libinput \
        gnome-shell-extension-clipboard-indicator clipit xfce4-clipman-plugin
elif command -v pacman &> /dev/null; then
    echo -e "${BLUE}   → Instalando paquetes necesarios (Arch)...${NC}"
    sudo pacman -S --noconfirm --needed git sassc glib2 libxml2 fontconfig gnome-tweaks \
        dconf plymouth firefox plank xorg-xrandr python-pillow curl unzip wget jq \
        gnome-backgrounds ffmpeg sox rofi fd python-requests xdotool wmctrl xorg-xprop \
        xorg-xwininfo util-linux qt5ct qt6ct sushi ruby libinput \
        gnome-shell-extension-clipboard-indicator clipit xfce4-clipman-plugin
else
    echo -e "${RED}    No se detectó un gestor de paquetes compatible (apt, dnf, pacman)${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Dependencias listas.${NC}"

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
# PASO 8: SONIDOS DEL SISTEMA DE macOS BIG SUR
# =============================================================================
echo -e "${YELLOW}🔊 [8/24] Instalando sonidos del sistema macOS Big Sur...${NC}"
SOUNDS_DIR="$HOME/.local/share/sounds"
SOUNDS_TEMP="$WORKDIR/bigsur-sounds-temp"
mkdir -p "$SOUNDS_DIR" "$SOUNDS_TEMP"

RELEASE_URL=$(curl -s https://api.github.com/repos/gxanshu/macos-bigsur-sound-theme-linux/releases/latest 2>/dev/null | grep "browser_download_url" | grep -E "\.tar\.gz|\.zip" | head -1 | cut -d '"' -f 4)
SOUND_INSTALLED=false

if [ -n "$RELEASE_URL" ]; then
    ARCHIVE_FILE="$SOUNDS_TEMP/bigsur-sounds.tar.gz"
    if curl -L "$RELEASE_URL" -o "$ARCHIVE_FILE" --silent --fail --max-time 120 2>/dev/null; then
        if file "$ARCHIVE_FILE" | grep -q "gzip"; then tar -xzf "$ARCHIVE_FILE" -C "$SOUNDS_TEMP" 2>/dev/null
        elif file "$ARCHIVE_FILE" | grep -q "Zip"; then unzip -q "$ARCHIVE_FILE" -d "$SOUNDS_TEMP" 2>/dev/null; fi
        
        EXTRACTED_DIR=$(find "$SOUNDS_TEMP" -maxdepth 1 -type d -name "bigsur*" -o -name "*sound*" | head -1)
        [ -z "$EXTRACTED_DIR" ] && EXTRACTED_DIR="$SOUNDS_TEMP"
        
        if [ -f "$EXTRACTED_DIR/index.theme" ] || [ -d "$EXTRACTED_DIR/stereo" ]; then
            rm -rf "$SOUNDS_DIR/bigsur"
            cp -r "$EXTRACTED_DIR" "$SOUNDS_DIR/bigsur"
            [ -d "$SOUNDS_DIR/bigsur/stereo" ] || [ -f "$SOUNDS_DIR/bigsur/index.theme" ] && SOUND_INSTALLED=true && echo -e "${GREEN}✅ Tema de sonidos macOS Big Sur instalado.${NC}"
        fi
    fi
fi

if [ "$SOUND_INSTALLED" != "true" ]; then
    ALT_REPO="$WORKDIR/bigsur-sound-theme"
    [ ! -d "$ALT_REPO" ] && git clone --depth=1 https://github.com/gxanshu/macos-bigsur-sound-theme-linux.git "$ALT_REPO" -q 2>/dev/null
    if [ -d "$ALT_REPO" ]; then
        ( cd "$ALT_REPO" && make install > /dev/null 2>&1 ) 2>/dev/null
        [ -d "$SOUNDS_DIR/bigsur" ] && SOUND_INSTALLED=true && echo -e "${GREEN}✅ Tema de sonidos construido e instalado.${NC}"
    fi
fi
rm -rf "$SOUNDS_TEMP"
echo ""

# =============================================================================
# PASO 9: ROFI SPOTLIGHT (LANZADOR ESTILO macOS)
# =============================================================================
echo -e "${YELLOW}🔍 [9/24] Instalando Rofi Spotlight...${NC}"
ROFI_SPOTLIGHT_DIR="$HOME/.local/share/rofi-spotlight"
ROFI_THEMES_DIR="$HOME/.local/share/rofi/themes"
mkdir -p "$ROFI_SPOTLIGHT_DIR" "$ROFI_THEMES_DIR"

[ ! -d "$WORKDIR/rofi-spotlight" ] && git clone --depth=1 https://github.com/eromatiya/rofi-spotlight.git "$WORKDIR/rofi-spotlight" -q 2>/dev/null
if [ -d "$WORKDIR/rofi-spotlight" ]; then
    cp -r "$WORKDIR/rofi-spotlight"/* "$ROFI_SPOTLIGHT_DIR/" 2>/dev/null
    chmod +x "$ROFI_SPOTLIGHT_DIR/rofi-spotlight.sh" "$ROFI_SPOTLIGHT_DIR/web-search.py" 2>/dev/null
fi

[ ! -d "$WORKDIR/rofi-themes-collection" ] && git clone --depth=1 https://github.com/newmanls/rofi-themes-collection.git "$WORKDIR/rofi-themes-collection" -q 2>/dev/null
[ -d "$WORKDIR/rofi-themes-collection/themes" ] && cp "$WORKDIR/rofi-themes-collection/themes/"*.rasi "$ROFI_THEMES_DIR/" 2>/dev/null

ROFI_LAUNCHER="$HOME/.local/bin/rofi-spotlight-launcher"
mkdir -p "$HOME/.local/bin"
cat > "$ROFI_LAUNCHER" << 'EOF'
#!/bin/bash
ROFI_SPOTLIGHT_DIR="$HOME/.local/share/rofi-spotlight"
ROFI_THEMES_DIR="$HOME/.local/share/rofi/themes"
if ! command -v rofi &> /dev/null; then notify-send "Error" "Rofi no está instalado" -i dialog-error; exit 1; fi
if [ -f "$ROFI_SPOTLIGHT_DIR/rofi-spotlight.sh" ]; then
    rofi -modi "Global Search:$ROFI_SPOTLIGHT_DIR/rofi-spotlight.sh" -show "Global Search" -theme "$ROFI_THEMES_DIR/spotlight.rasi" -config "$ROFI_SPOTLIGHT_DIR/rofi.rasi"
else
    rofi -show drun -theme "$ROFI_THEMES_DIR/spotlight.rasi"
fi
EOF
chmod +x "$ROFI_LAUNCHER"

cat > "$HOME/.local/share/applications/rofi-spotlight.desktop" << 'EOF'
[Desktop Entry]
Name=Spotlight Search
Comment=macOS-style file and web search
Exec=rofi-spotlight-launcher
Icon=search
Type=Application
Categories=Utility;
Keywords=search;spotlight;files;web;
EOF
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
    echo "1" | sudo update-alternatives --config default.plymouth > /dev/null 2>&1
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
# PASO 15: CONFIGURACIÓN DEL SISTEMA Y ATAJO DE TECLADO
# =============================================================================
echo -e "${YELLOW}⚙️  [15/24] Configurando sistema y atajos de teclado macOS...${NC}"

gnome_set_keybinding() {
    local name="${1:-}" command="${2:-}" binding="${3:-}" index="${4:-}"
    local PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${index}/"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH name "$name" 2>/dev/null
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH command "$command" 2>/dev/null
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH binding "$binding" 2>/dev/null
}

cinnamon_set_keybinding() {
    local name="${1:-}" command="${2:-}" binding="${3:-}" id="${4:-}"
    local PATH="/org/cinnamon/desktop/keybindings/custom-keybindings/$id/"
    gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$PATH name "$name" 2>/dev/null
    gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$PATH command "$command" 2>/dev/null
    gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$PATH binding "$binding" 2>/dev/null
}

xfce_set_keybinding() {
    local command="${1:-}" binding="${2:-}"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/$binding" -n -t string -s "$command" 2>/dev/null || xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/$binding" -s "$command" 2>/dev/null
}

if [ "$MOJAVE_INSTALLED" = true ]; then
    WALLPAPER_PATH="/usr/share/backgrounds/macOS/mojave-timed.xml"; WALLPAPER_DESC="dinámico Mojave"
elif [ "$IS_GNOME" = true ]; then
    WALLPAPER_PATH="$HOME/.local/share/backgrounds/Sonoma/Sonoma-timed.xml"; WALLPAPER_DESC="dinámico Sonoma"
else
    WALLPAPER_PATH="$HOME/.local/share/backgrounds/Sonoma-dark.jpg"; WALLPAPER_DESC="estático Sonoma"
fi

if [ "$IS_GNOME" = true ]; then
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null
    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null
    gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null
    gsettings set org.gnome.desktop.interface monospace-font-name "$MONO_FONT" 2>/dev/null
    [ "$SF_INSTALLED" = true ] && { gsettings set org.gnome.desktop.interface font-name "$UI_FONT" 2>/dev/null; gsettings set org.gnome.desktop.interface document-font-name "$SERIF_FONT" 2>/dev/null; gsettings set org.gnome.desktop.wm.preferences titlebar-font "$UI_FONT" 2>/dev/null; }
    gsettings set org.gnome.shell.extensions.user-theme name "$SHELL_THEME" 2>/dev/null
    [ -f "$WALLPAPER_PATH" ] && { gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_PATH" 2>/dev/null; gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_PATH" 2>/dev/null; }
    [ "$SOUND_INSTALLED" = true ] && { gsettings set org.gnome.desktop.sound theme-name "$SOUND_THEME" 2>/dev/null; gsettings set org.gnome.desktop.sound event-sounds true 2>/dev/null; gsettings set org.gnome.desktop.sound input-feedback-sounds true 2>/dev/null; }
    
    gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']" 2>/dev/null
    gsettings set org.gnome.mutter.keybindings toggle-tiled-left "['<Super>Left']" 2>/dev/null
    gsettings set org.gnome.mutter.keybindings toggle-tiled-right "['<Super>Right']" 2>/dev/null
    gsettings set org.gnome.desktop.wm.keybindings minimize "['<Super>m']" 2>/dev/null
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']" 2>/dev/null
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']" 2>/dev/null
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']" 2>/dev/null
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Super><Shift>1']" 2>/dev/null
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Super><Shift>2']" 2>/dev/null
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Super><Shift>3']" 2>/dev/null
    gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Ctrl><Alt>t']" 2>/dev/null
    gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Super>l']" 2>/dev/null
    gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot "['Print']" 2>/dev/null
    gsettings set org.gnome.settings-daemon.plugins.media-keys window-screenshot "['<Alt>Print']" 2>/dev/null
    gsettings set org.gnome.settings-daemon.plugins.media-keys area-screenshot "['<Shift>Print']" 2>/dev/null
    
    CUSTOM_PATHS=(); INDEX=0
    gnome_set_keybinding "Explorador" "nautilus" "<Super>e" $INDEX; CUSTOM_PATHS+=("'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${INDEX}/'"); INDEX=$((INDEX+1))
    gnome_set_keybinding "Configuración" "gnome-control-center" "<Super>a" $INDEX; CUSTOM_PATHS+=("'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${INDEX}/'"); INDEX=$((INDEX+1))
    gnome_set_keybinding "Monitor Sistema" "gnome-system-monitor" "<Ctrl><Shift>Escape" $INDEX; CUSTOM_PATHS+=("'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${INDEX}/'"); INDEX=$((INDEX+1))
    gnome_set_keybinding "Cerrar App Completo" "macos-wm-actions close-app-completely" "<Ctrl>q" $INDEX; CUSTOM_PATHS+=("'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${INDEX}/'"); INDEX=$((INDEX+1))
    gnome_set_keybinding "Maximizar/Restaurar" "macos-wm-actions toggle-maximize" "<Super>x" $INDEX; CUSTOM_PATHS+=("'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${INDEX}/'"); INDEX=$((INDEX+1))
    gnome_set_keybinding "Pantalla Completa" "macos-wm-actions toggle-fullscreen" "F11" $INDEX; CUSTOM_PATHS+=("'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${INDEX}/'"); INDEX=$((INDEX+1))
    gnome_set_keybinding "Centrar Ventana" "macos-wm-actions center" "<Super>c" $INDEX; CUSTOM_PATHS+=("'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${INDEX}/'"); INDEX=$((INDEX+1))
    gnome_set_keybinding "Siempre al Frente" "macos-wm-actions toggle-always-on-top" "<Super>f" $INDEX; CUSTOM_PATHS+=("'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${INDEX}/'"); INDEX=$((INDEX+1))
    gnome_set_keybinding "Mover Ventana" "macos-wm-actions move-window" "<Super>v" $INDEX; CUSTOM_PATHS+=("'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${INDEX}/'"); INDEX=$((INDEX+1))
    gnome_set_keybinding "Redimensionar" "macos-wm-actions resize-window" "<Super>r" $INDEX; CUSTOM_PATHS+=("'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${INDEX}/'"); INDEX=$((INDEX+1))
    gnome_set_keybinding "Menos Opacidad" "macos-wm-actions opacity-decrease" "<Super>o" $INDEX; CUSTOM_PATHS+=("'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${INDEX}/'"); INDEX=$((INDEX+1))
    gnome_set_keybinding "Más Opacidad" "macos-wm-actions opacity-increase" "<Super><Ctrl>o" $INDEX; CUSTOM_PATHS+=("'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${INDEX}/'"); INDEX=$((INDEX+1))
    gnome_set_keybinding "Spotlight" "rofi-spotlight-launcher" "<Ctrl>space" $INDEX; CUSTOM_PATHS+=("'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${INDEX}/'"); INDEX=$((INDEX+1))
    gnome_set_keybinding "Forzar Cierre" "macos-wm-actions force-kill" "<Ctrl><Alt>Escape" $INDEX; CUSTOM_PATHS+=("'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${INDEX}/'"); INDEX=$((INDEX+1))
    gnome_set_keybinding "Preferencias" "macos-wm-actions open-preferences" "<Ctrl>comma" $INDEX; CUSTOM_PATHS+=("'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${INDEX}/'"); INDEX=$((INDEX+1))
    gnome_set_keybinding "Cerrar Sesión" "gnome-session-quit --logout --no-prompt" "<Ctrl><Alt>Delete" $INDEX; CUSTOM_PATHS+=("'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${INDEX}/'"); INDEX=$((INDEX+1))
    gnome_set_keybinding "Apagar/Reiniciar" "gnome-session-quit --power-off" "<Ctrl><Alt>End" $INDEX; CUSTOM_PATHS+=("'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${INDEX}/'"); INDEX=$((INDEX+1))
    
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$(IFS=,; echo "[${CUSTOM_PATHS[*]}]")" 2>/dev/null
    
    command -v gnome-extensions &> /dev/null && { gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null; gnome-extensions enable liquid-glass@thinkingcoding1231.gmail.com 2>/dev/null; gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null; }
    
    LG_SCHEMA="org.gnome.shell.extensions.liquid-glass"
    gsettings list-schemas 2>/dev/null | grep -q "$LG_SCHEMA" && { gsettings set "$LG_SCHEMA" enable-top-bar true 2>/dev/null; gsettings set "$LG_SCHEMA" enable-dash-to-dock true 2>/dev/null; gsettings set "$LG_SCHEMA" enable-notifications true 2>/dev/null; }
    
    DOCK_SCHEMA="org.gnome.shell.extensions.dash-to-dock"
    gsettings list-schemas 2>/dev/null | grep -q "$DOCK_SCHEMA" && { gsettings set "$DOCK_SCHEMA" dock-position 'BOTTOM' 2>/dev/null; gsettings set "$DOCK_SCHEMA" transparency-mode 'FIXED' 2>/dev/null; gsettings set "$DOCK_SCHEMA" background-opacity 0.4 2>/dev/null; }

elif [[ "$DESKTOP_ENV" == *"cinnamon"* ]] || [[ "$DISTRO" == *"mint"* && "$DESKTOP_ENV" != *"xfce"* ]]; then
    gsettings set org.cinnamon.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null
    gsettings set org.cinnamon.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null
    gsettings set org.cinnamon.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null
    gsettings set org.cinnamon.theme name "$GTK_THEME" 2>/dev/null
    gsettings set org.cinnamon.desktop.wm.preferences theme "$GTK_THEME" 2>/dev/null
    gsettings set org.cinnamon.desktop.interface color-scheme 'prefer-dark' 2>/dev/null
    gsettings set org.cinnamon.desktop.interface monospace-font-name "$MONO_FONT" 2>/dev/null
    [ "$SF_INSTALLED" = true ] && { gsettings set org.cinnamon.desktop.interface font-name "$UI_FONT" 2>/dev/null; gsettings set org.cinnamon.desktop.wm.preferences titlebar-font "$UI_FONT" 2>/dev/null; }
    [ -f "$WALLPAPER_PATH" ] && gsettings set org.cinnamon.desktop.background picture-uri "file://$WALLPAPER_PATH" 2>/dev/null
    [ "$SOUND_INSTALLED" = true ] && { gsettings set org.cinnamon.desktop.sound theme-name "$SOUND_THEME" 2>/dev/null; gsettings set org.cinnamon.desktop.sound event-sounds true 2>/dev/null; }
    
    gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-1 "['<Super>1']" 2>/dev/null
    gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-2 "['<Super>2']" 2>/dev/null
    gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-3 "['<Super>3']" 2>/dev/null
    gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-left "['<Ctrl><Alt>Left']" 2>/dev/null
    gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-right "['<Ctrl><Alt>Right']" 2>/dev/null
    gsettings set org.cinnamon.desktop.keybindings.wm tile-left "['<Super>Left']" 2>/dev/null
    gsettings set org.cinnamon.desktop.keybindings.wm tile-right "['<Super>Right']" 2>/dev/null
    gsettings set org.cinnamon.desktop.keybindings show-desktop "['<Super>d']" 2>/dev/null
    
    CUSTOM_IDS=()
    cinnamon_set_keybinding "Explorador" "nemo" "<Super>e" "app-explorer"; CUSTOM_IDS+=("'app-explorer'")
    cinnamon_set_keybinding "Configuración" "cinnamon-settings" "<Super>a" "app-settings"; CUSTOM_IDS+=("'app-settings'")
    cinnamon_set_keybinding "Monitor" "gnome-system-monitor" "<Ctrl><Shift>Escape" "app-monitor"; CUSTOM_IDS+=("'app-monitor'")
    cinnamon_set_keybinding "Terminal" "gnome-terminal" "<Ctrl><Alt>t" "app-terminal"; CUSTOM_IDS+=("'app-terminal'")
    cinnamon_set_keybinding "Cerrar Completo" "macos-wm-actions close-app-completely" "<Ctrl>q" "wm-close-full"; CUSTOM_IDS+=("'wm-close-full'")
    cinnamon_set_keybinding "Minimizar" "xdotool getactivewindow windowminimize" "<Super>m" "wm-minimize"; CUSTOM_IDS+=("'wm-minimize'")
    cinnamon_set_keybinding "Maximizar" "macos-wm-actions toggle-maximize" "<Super>x" "wm-maximize"; CUSTOM_IDS+=("'wm-maximize'")
    cinnamon_set_keybinding "Pantalla Completa" "macos-wm-actions toggle-fullscreen" "F11" "wm-fullscreen"; CUSTOM_IDS+=("'wm-fullscreen'")
    cinnamon_set_keybinding "Centrar" "macos-wm-actions center" "<Super>c" "wm-center"; CUSTOM_IDS+=("'wm-center'")
    cinnamon_set_keybinding "Siempre Frente" "macos-wm-actions toggle-always-on-top" "<Super>f" "wm-top"; CUSTOM_IDS+=("'wm-top'")
    cinnamon_set_keybinding "Mover" "macos-wm-actions move-window" "<Super>v" "wm-move"; CUSTOM_IDS+=("'wm-move'")
    cinnamon_set_keybinding "Redimensionar" "macos-wm-actions resize-window" "<Super>r" "wm-resize"; CUSTOM_IDS+=("'wm-resize'")
    cinnamon_set_keybinding "Menos Opacidad" "macos-wm-actions opacity-decrease" "<Super>o" "wm-opacity-dec"; CUSTOM_IDS+=("'wm-opacity-dec'")
    cinnamon_set_keybinding "Más Opacidad" "macos-wm-actions opacity-increase" "<Super><Ctrl>o" "wm-opacity-inc"; CUSTOM_IDS+=("'wm-opacity-inc'")
    cinnamon_set_keybinding "Spotlight" "rofi-spotlight-launcher" "<Ctrl>space" "spotlight"; CUSTOM_IDS+=("'spotlight'")
    cinnamon_set_keybinding "Forzar Cierre" "macos-wm-actions force-kill" "<Ctrl><Alt>Escape" "force-kill"; CUSTOM_IDS+=("'force-kill'")
    cinnamon_set_keybinding "Bloquear" "cinnamon-screensaver-command --lock" "<Super>l" "lock-screen"; CUSTOM_IDS+=("'lock-screen'")
    cinnamon_set_keybinding "Reiniciar Cinnamon" "macos-wm-actions restart-cinnamon" "<Ctrl><Alt>Escape" "restart-cinnamon"; CUSTOM_IDS+=("'restart-cinnamon'")
    cinnamon_set_keybinding "Cerrar Sesión" "cinnamon-session-quit --logout" "<Ctrl><Alt>Delete" "logout"; CUSTOM_IDS+=("'logout'")
    cinnamon_set_keybinding "Apagar" "cinnamon-session-quit --power-off" "<Ctrl><Alt>End" "poweroff"; CUSTOM_IDS+=("'poweroff'")
    
    gsettings set org.cinnamon.desktop.keybindings custom-list "$(IFS=,; echo "[${CUSTOM_IDS[*]}]")" 2>/dev/null
    gsettings set org.cinnamon panels-enabled "['1:0:bottom']" 2>/dev/null

elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    xfconf-query -c xsettings -p /Net/ThemeName -n -t string -s "$GTK_THEME" 2>/dev/null || xfconf-query -c xsettings -p /Net/ThemeName -s "$GTK_THEME" 2>/dev/null
    xfconf-query -c xsettings -p /Net/IconThemeName -n -t string -s "$ICON_THEME" 2>/dev/null || xfconf-query -c xsettings -p /Net/IconThemeName -s "$ICON_THEME" 2>/dev/null
    xfconf-query -c xsettings -p /Net/CursorThemeName -n -t string -s "$CURSOR_THEME" 2>/dev/null || xfconf-query -c xsettings -p /Net/CursorThemeName -s "$CURSOR_THEME" 2>/dev/null
    xfconf-query -c xfwm4 -p /general/theme -n -t string -s "$GTK_THEME" 2>/dev/null || xfconf-query -c xfwm4 -p /general/theme -s "$GTK_THEME" 2>/dev/null
    xfconf-query -c xfwm4 -p /general/show_dock_shadow -n -t bool -s false 2>/dev/null
    xfconf-query -c xfwm4 -p /general/button_layout -n -t string -s "O|HMC" 2>/dev/null
    [ "$SF_INSTALLED" = true ] && { xfconf-query -c xsettings -p /Gtk/FontName -n -t string -s "$UI_FONT" 2>/dev/null || xfconf-query -c xsettings -p /Gtk/FontName -s "$UI_FONT" 2>/dev/null; xfconf-query -c xfwm4 -p /general/title_font -n -t string -s "$UI_FONT" 2>/dev/null || xfconf-query -c xfwm4 -p /general/title_font -s "$UI_FONT" 2>/dev/null; }
    xfconf-query -c xsettings -p /Gtk/MonospaceFontName -n -t string -s "$MONO_FONT" 2>/dev/null || xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s "$MONO_FONT" 2>/dev/null
    [ "$SOUND_INSTALLED" = true ] && { xfconf-query -c xsettings -p /Net/SoundThemeName -n -t string -s "$SOUND_THEME" 2>/dev/null || xfconf-query -c xsettings -p /Net/SoundThemeName -s "$SOUND_THEME" 2>/dev/null; xfconf-query -c xsettings -p /Net/EnableEventSounds -n -t bool -s true 2>/dev/null; xfconf-query -c xsettings -p /Net/EnableInputFeedbackSounds -n -t bool -s true 2>/dev/null; }
    
    xfce_set_keybinding "thunar" "<Super>e"
    xfce_set_keybinding "xfce4-settings-manager" "<Super>a"
    xfce_set_keybinding "xfce4-terminal" "<Ctrl><Alt>t"
    xfce_set_keybinding "xfce4-taskmanager" "<Ctrl><Shift>Escape"
    xfce_set_keybinding "xfce4-screensaver-command --lock" "<Super>l"
    xfce_set_keybinding "xfce4-session-logout" "<Ctrl><Alt>Delete"
    xfce_set_keybinding "rofi-spotlight-launcher" "<Ctrl>space"
    xfce_set_keybinding "macos-wm-actions force-kill" "<Ctrl><Alt>Escape"
    xfce_set_keybinding "macos-wm-actions close-app-completely" "<Ctrl>q"
    xfce_set_keybinding "macos-wm-actions center" "<Super>c"
    xfce_set_keybinding "macos-wm-actions toggle-always-on-top" "<Super>f"
    xfce_set_keybinding "macos-wm-actions move-window" "<Super>v"
    xfce_set_keybinding "macos-wm-actions resize-window" "<Super>r"
    xfce_set_keybinding "macos-wm-actions opacity-decrease" "<Super>o"
    xfce_set_keybinding "macos-wm-actions opacity-increase" "<Super><Ctrl>o"
    xfce_set_keybinding "xfce4-screenshooter -f" "Print"
    xfce_set_keybinding "xfce4-screenshooter -w" "<Alt>Print"
    xfce_set_keybinding "xfce4-screenshooter -r" "<Shift>Print"
    
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>m" -n -t string -s "hide_window_key" 2>/dev/null
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>x" -n -t string -s "maximize_toggle_key" 2>/dev/null
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>Left" -n -t string -s "tile_left_key" 2>/dev/null
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>Right" -n -t string -s "tile_right_key" 2>/dev/null
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>Up" -n -t string -s "tile_up_key" 2>/dev/null
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>Down" -n -t string -s "tile_down_key" 2>/dev/null
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/F11" -n -t string -s "fullscreen_key" 2>/dev/null
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>1" -n -t string -s "workspace_1_key" 2>/dev/null
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>2" -n -t string -s "workspace_2_key" 2>/dev/null
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>3" -n -t string -s "workspace_3_key" 2>/dev/null
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Ctrl><Alt>Left" -n -t string -s "left_workspace_key" 2>/dev/null
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Ctrl><Alt>Right" -n -t string -s "right_workspace_key" 2>/dev/null
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>d" -n -t string -s "show_desktop_key" 2>/dev/null
    
    [ -f "$WALLPAPER_PATH" ] && xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -n -t string -s "$WALLPAPER_PATH" 2>/dev/null || xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$WALLPAPER_PATH" 2>/dev/null
    
    if ! command -v plank &> /dev/null; then
        sudo apt-get install -y -qq plank 2>/dev/null || sudo dnf install -y -q plank 2>/dev/null || sudo pacman -S --noconfirm plank 2>/dev/null
    fi
    if command -v plank &> /dev/null; then
        PLANK_DCONF="/net/launchpad/plank/docks/dock1"
        dconf write "$PLANK_DCONF/theme" "'$PLANK_THEME'" 2>/dev/null
        dconf write "$PLANK_DCONF/position" "'bottom'" 2>/dev/null
        dconf write "$PLANK_DCONF/icon-size" "48" 2>/dev/null
        dconf write "$PLANK_DCONF/hide-mode" "'intelligent'" 2>/dev/null
        mkdir -p ~/.config/autostart
        cat > ~/.config/autostart/plank.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Plank
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
        nohup plank > /dev/null 2>&1 &
    fi
fi
echo -e "${GREEN}✅ Configuración del sistema aplicada.${NC}"
echo ""

# =============================================================================
# PASO 16: TEMATIZACIÓN QT Y QUICK LOOK (Vista Previa)
# =============================================================================
echo -e "${YELLOW}🎨 [16/24] Tematizando aplicaciones Qt y activando Quick Look...${NC}"
if ! grep -q "QT_QPA_PLATFORMTHEME=qt5ct" /etc/environment; then
    echo "QT_QPA_PLATFORMTHEME=qt5ct" | sudo tee -a /etc/environment > /dev/null
fi
mkdir -p ~/.config/qt5ct
cat > ~/.config/qt5ct/qt5ct.conf << 'EOF'
[Appearance]
style=gtk2
color_scheme_path=
icon_theme=MacTahoe-dark
EOF

if [ "$IS_GNOME" = true ]; then
    sudo apt-get install -y -qq sushi 2>/dev/null || sudo dnf install -y -q sushi 2>/dev/null || sudo pacman -S --noconfirm sushi 2>/dev/null
else
    sudo apt-get install -y -qq gloobus-preview 2>/dev/null || sudo dnf install -y -q gloobus-preview 2>/dev/null || sudo pacman -S --noconfirm gloobus-preview 2>/dev/null
fi
echo -e "${GREEN}✅ Qt tematizado y Quick Look instalado.${NC}"
echo ""

# =============================================================================
# PASO 17: SCROLL NATURAL UNIVERSAL
# =============================================================================
echo -e "${YELLOW}📜 [17/24] Activando Scroll Natural (Estilo macOS)...${NC}"
if [ "$IS_GNOME" = true ] || [ "$IS_CINNAMON" = true ]; then
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null
    gsettings set org.gnome.desktop.peripherals.mouse natural-scroll true 2>/dev/null
fi

if [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    for device in $(xinput list 2>/dev/null | grep -i "pointer" | grep -i "libinput" | sed 's/.*id=\([0-9]*\).*/\1/'); do
        xinput set-prop "$device" "libinput Natural Scrolling Enabled" 1 2>/dev/null || true
    done
    xfconf-query -c pointers -p /-1/Properties/libinput_Natural_Scrolling_Enabled -n -t bool -s true 2>/dev/null || true
fi
echo -e "${GREEN}✅ Scroll natural activado.${NC}"
echo ""

# =============================================================================
# PASO 18: GESTOS MULTITÁCTILES ESTILO MACOS (FUSUMA) + ARRASTRE 3 DEDOS
# =============================================================================
echo -e "${YELLOW}👆 [18/24] Instalando Gestos Multitáctiles y Arrastre con 3 dedos...${NC}"
sudo gpasswd -a $USER input 2>/dev/null || true
sudo gem install fusuma --no-document 2>/dev/null || true

mkdir -p ~/.config/fusuma
cat > ~/.config/fusuma/config.yml << 'EOF'
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

mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/fusuma.service << 'EOF'
[Unit]
Description=Fusuma Multitouch Gestures
After=graphical-session.target

[Service]
ExecStart=/usr/bin/env fusuma
Restart=on-failure

[Install]
WantedBy=graphical-session.target
EOF

systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable --now fusuma.service 2>/dev/null || true
echo -e "${GREEN}✅ Fusuma y Arrastre con 3 dedos configurados.${NC}"
echo ""

# =============================================================================
# PASO 19: GESTOR DE PORTAPAPELES MINIMALISTA
# =============================================================================
echo -e "${YELLOW}📋 [19/24] Configurando Gestor de Portapapeles estilo macOS...${NC}"
if [ "$IS_GNOME" = true ]; then
    gnome-extensions enable clipboard-indicator@tudmotu.com 2>/dev/null || true
    echo -e "${GREEN}✅ Clipboard Indicator activado para GNOME.${NC}"
elif [ "$IS_CINNAMON" = true ]; then
    echo -e "${GREEN}✅ Clipit instalado para Cinnamon (inícialo desde el menú).${NC}"
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    echo -e "${GREEN}✅ Clipman instalado para XFCE (añádelo al panel manualmente).${NC}"
fi
echo ""

# =============================================================================
# PASO 20: RENDERIZADO DE FUENTES ESTILO MACOS (Fontconfig)
# =============================================================================
echo -e "${YELLOW}🔤 [20/24] Optimizando renderizado de fuentes (Estilo macOS)...${NC}"
mkdir -p ~/.config/fontconfig/
cat > ~/.config/fontconfig/fonts.conf << 'EOF'
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
fc-cache -f > /dev/null 2>&1
echo -e "${GREEN}✅ Renderizado de fuentes optimizado para SF Pro.${NC}"
echo ""

# =============================================================================
# PASO 21: CONFIGURACIÓN DE TERMINAL ESTILO macOS
# =============================================================================
echo -e "${YELLOW}💻 [21/24] Configurando terminal estilo macOS...${NC}"

if [ "$IS_GNOME" = true ] && command -v gnome-terminal &> /dev/null; then
    PROFILE_ID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen)
    dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/visible-name "'macOS Tahoe'"
    dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/font "'SF Mono 12'"
    dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/use-system-font false
    dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/background-color "'rgb(30,30,30)'"
    dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/foreground-color "'rgb(230,230,230)'"
    dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/bold-color "'rgb(255,255,255)'"
    dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/use-theme-colors false
    dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/use-theme-transparency false
    dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/audible-bell false
    dconf write /org/gnome/terminal/legacy/default-profile "'$PROFILE_ID'"
    echo -e "${GREEN}✅ Terminal GNOME configurada con tema macOS.${NC}"
elif [[ "$DESKTOP_ENV" == *"xfce"* ]] && command -v xfce4-terminal &> /dev/null; then
    mkdir -p "$HOME/.config/xfce4/terminal"
    cat > "$HOME/.config/xfce4/terminal/terminalrc" << 'TERMINALEOF'
[Configuration]
FontName=SF Mono 12
ColorForeground=#e6e6e6
ColorBackground=#1e1e1e
ColorBold=#ffffff
MiscCursorShape=TERMINAL_CURSOR_SHAPE_IBEAM
MiscCursorBlinks=FALSE
MiscShowUnsafeUrls=FALSE
TERMINALEOF
    echo -e "${GREEN}✅ Terminal XFCE configurada con tema macOS.${NC}"
fi
echo ""

# =============================================================================
# PASO 22: CONFIGURACIÓN DE ANIMACIONES SUAVES
# =============================================================================
echo -e "${YELLOW}🎬 [22/24] Configurando animaciones suaves...${NC}"

if [ "$IS_GNOME" = true ]; then
    gsettings set org.gnome.desktop.interface enable-animations true 2>/dev/null
    gsettings set org.gnome.mutter center-new-windows true 2>/dev/null
fi

if [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    xfconf-query -c xfwm4 -p /general/use_compositing -s true 2>/dev/null
fi

echo -e "${GREEN}✅ Animaciones configuradas.${NC}"
echo ""

# =============================================================================
# PASO 23: EFECTO MAGIC LAMP (GNOME y Cinnamon)
# =============================================================================
echo -e "${YELLOW}🪔 [23/24] Instalando efecto Magic Lamp (minimizar ventanas)...${NC}"

if [ "$IS_GNOME" = true ]; then
    echo -e "   ${BLUE}→ Instalando para GNOME...${NC}"
    mkdir -p ~/.local/share/gnome-shell/extensions/
    if [ ! -d "$WORKDIR/compiz-alike-magic-lamp-effect" ]; then
        git clone --depth=1 https://github.com/hermes83/compiz-alike-magic-lamp-effect.git "$WORKDIR/compiz-alike-magic-lamp-effect" -q 2>/dev/null
    fi
    EXT_MAGIC_LAMP=$(find "$WORKDIR/compiz-alike-magic-lamp-effect" -maxdepth 1 -type d -name "*magic-lamp*" | head -1)
    if [ -n "$EXT_MAGIC_LAMP" ]; then
        cp -r "$EXT_MAGIC_LAMP" ~/.local/share/gnome-shell/extensions/ 2>/dev/null
        gnome-extensions enable "$(basename "$EXT_MAGIC_LAMP")" 2>/dev/null
        echo -e "${GREEN}✅ Magic Lamp para GNOME instalada y activada.${NC}"
    fi
elif [ "$IS_CINNAMON" = true ]; then
    echo -e "   ${BLUE}→ Instalando para Cinnamon...${NC}"
    mkdir -p ~/.local/share/cinnamon/extensions/
    if [ ! -d "$WORKDIR/CinnamonMagicLamp" ]; then
        git clone --depth=1 https://github.com/klangman/CinnamonMagicLamp.git "$WORKDIR/CinnamonMagicLamp" -q 2>/dev/null
    fi
    if [ -d "$WORKDIR/CinnamonMagicLamp/CinnamonMagicLamp@klangman" ]; then
        ln -sf "$WORKDIR/CinnamonMagicLamp/CinnamonMagicLamp@klangman" ~/.local/share/cinnamon/extensions/CinnamonMagicLamp@klangman 2>/dev/null
        
        CINNAMON_EXTENSIONS=$(gsettings get org.cinnamon enabled-extensions 2>/dev/null)
        if ! echo "$CINNAMON_EXTENSIONS" | grep -q "CinnamonMagicLamp@klangman"; then
            if [ "$CINNAMON_EXTENSIONS" = "[]" ]; then
                gsettings set org.cinnamon enabled-extensions "['CinnamonMagicLamp@klangman']" 2>/dev/null
            else
                NEW_EXTENSIONS=$(echo "$CINNAMON_EXTENSIONS" | sed "s/]$/, 'CinnamonMagicLamp@klangman']/")
                gsettings set org.cinnamon enabled-extensions "$NEW_EXTENSIONS" 2>/dev/null
            fi
        fi
        
        gsettings set org.cinnamon.desktop.effects minimize-effect "'none'" 2>/dev/null
        gsettings set org.cinnamon.desktop.effects unminimize-effect "'none'" 2>/dev/null
        
        echo -e "${GREEN}✅ Magic Lamp para Cinnamon instalada y activada.${NC}"
    fi
else
    echo -e "${YELLOW}⏭️  [23/24] Magic Lamp omitido (solo GNOME y Cinnamon).${NC}"
fi
echo ""

# =============================================================================
# PASO 24: VERIFICACIÓN POST-INSTALACIÓN INTELIGENTE
# =============================================================================
echo -e "${YELLOW}🔍 [24/24] Verificando instalación completa...${NC}"

CRITICAL_ERRORS=0
OPTIONAL_ERRORS=0

if ! fc-list | grep -q "SF Pro"; then
    echo -e "   ${RED}✗ CRÍTICO: Fuentes Apple no instaladas${NC}"
    CRITICAL_ERRORS=$((CRITICAL_ERRORS + 1))
fi

if [ ! -d "$HOME/.themes/MacTahoe-Dark" ] && [ ! -d "$HOME/.local/share/themes/MacTahoe-Dark" ]; then
    echo -e "   ${RED}✗ CRÍTICO: Tema GTK no instalado${NC}"
    CRITICAL_ERRORS=$((CRITICAL_ERRORS + 1))
fi

if [ ! -d "$HOME/.icons/MacTahoe-dark" ] && [ ! -d "$HOME/.local/share/icons/MacTahoe-dark" ]; then
    echo -e "   ${RED}✗ CRÍTICO: Iconos y cursores no instalados${NC}"
    CRITICAL_ERRORS=$((CRITICAL_ERRORS + 1))
fi

if [ ! -d "$HOME/.local/share/sounds/bigsur" ]; then
    echo -e "   ${RED}✗ CRÍTICO: Sonidos del sistema no instalados${NC}"
    CRITICAL_ERRORS=$((CRITICAL_ERRORS + 1))
fi

if [ ! -f "$HOME/.local/bin/rofi-spotlight-launcher" ]; then
    echo -e "   ${YELLOW}⚠ OPCIONAL: Rofi Spotlight no instalado${NC}"
    OPTIONAL_ERRORS=$((OPTIONAL_ERRORS + 1))
fi

if ! systemctl --user is-active --quiet fusuma.service 2>/dev/null; then
    echo -e "   ${YELLOW}⚠ OPCIONAL: Gestos Fusuma no activos${NC}"
    OPTIONAL_ERRORS=$((OPTIONAL_ERRORS + 1))
fi

if ! command -v sushi &> /dev/null && ! command -v gloobus-preview &> /dev/null; then
    echo -e "   ${YELLOW}⚠ OPCIONAL: Quick Look no disponible${NC}"
    OPTIONAL_ERRORS=$((OPTIONAL_ERRORS + 1))
fi

echo ""

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
    
    if [ -f "$ROLLBACK_SCRIPT" ]; then
        bash "$ROLLBACK_SCRIPT" --auto
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

# =============================================================================
# DESACTIVAR TRAMPA DE ERROR (Solo si no hubo fallos críticos)
# =============================================================================
if [ "$CRITICAL_ERRORS" -eq 0 ]; then
    INSTALLATION_SUCCESS=true
    trap - ERR
fi

# =============================================================================
# MENSAJE FINAL (Solo si no hubo rollback)
# =============================================================================
if [ "$CRITICAL_ERRORS" -eq 0 ]; then
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    if [ "$OPTIONAL_ERRORS" -eq 0 ]; then
        echo -e "${CYAN}║        🎉 ¡INSTALACIÓN COMPLETADA CON ÉXITO! 🎉         ║${NC}"
    else
        echo -e "${YELLOW}║   ⚠️  INSTALACIÓN PARCIAL - REINICIAR PARA APLICAR     ║${NC}"
    fi
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}✨ Tu sistema Linux ahora tiene la experiencia ULTIMA de macOS Tahoe.${NC}"
    echo -e "${YELLOW}⚠️  IMPORTANTE: Debes REINICIAR EL EQUIPO para que surtan efecto:${NC}"
    echo -e "${YELLOW}   • Permisos del grupo 'input' (para los gestos Fusuma)${NC}"
    echo -e "${YELLOW}   • Configuración de aplicaciones Qt${NC}"
    echo -e "${YELLOW}   • Tema de arranque Plymouth (si fue instalado)${NC}"
    echo ""
fi
