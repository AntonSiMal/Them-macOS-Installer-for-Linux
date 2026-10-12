#!/bin/bash

# =============================================================================
# macOS Tahoe Auto-Installer - Versión WWDC26
# Compatible con: GNOME / Zorin OS / Cinnamon / XFCE
# Incluye: temas, fuentes, sonidos, wallpapers dinámicos, Rofi Spotlight,
#          atajos de teclado estilo macOS, Plymouth, Firefox, Plank, GDM
# =============================================================================

set -e  # Salir en caso de error crítico

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# =============================================================================
# CONFIGURACIÓN GLOBAL
# =============================================================================
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

echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🍎 macOS Tahoe Theme Installer - WWDC26 Edition       ║${NC}"
echo -e "${CYAN}║   Instalación 100% automatizada                         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📋 Resumen de la instalación:${NC}"
echo -e "   • Tema GTK e Iconos: ${GREEN}macOS Tahoe (26.7.1)${NC}"
echo -e "   • Fuentes oficiales: ${GREEN}SF Pro + New York (WWDC26 v27.0)${NC}"
echo -e "   • Wallpaper dinámico: ${GREEN}macOS Mojave (horarios reales)${NC}"
echo -e "   • Sonidos del sistema: ${GREEN}macOS Big Sur (44 eventos)${NC}"
echo -e "   • Lanzador: ${GREEN}Rofi Spotlight (Ctrl+Espacio)${NC}"
echo -e "   • Atajos: ${GREEN}Estilo macOS completo${NC}"
echo ""

# =============================================================================
# DETECCIÓN DEL ENTORNO
# =============================================================================
echo -e "${YELLOW}🔍 Detectando entorno de escritorio...${NC}"

DESKTOP_ENV=$(echo "${XDG_CURRENT_DESKTOP:-unknown}" | tr '[:upper:]' '[:lower:]')
SESSION_TYPE="${XDG_SESSION_TYPE:-unknown}"
DISTRO=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')
fi

echo -e "   • Entorno: ${GREEN}$DESKTOP_ENV${NC}"
echo -e "   • Sesión:  ${GREEN}$SESSION_TYPE${NC}"
echo -e "   • Distro:  ${GREEN}$DISTRO${NC}"

# Detectar resolución
if command -v xrandr &> /dev/null; then
    SCREEN_WIDTH=$(xrandr --current | grep '*' | head -1 | awk '{print $1}' | cut -d'x' -f1)
    if [ -n "$SCREEN_WIDTH" ]; then
        if [ "$SCREEN_WIDTH" -ge 3840 ]; then
            SCREEN_VARIANT="4k"; ICON_BOLD_FLAG="-b"
        elif [ "$SCREEN_WIDTH" -ge 2560 ]; then
            SCREEN_VARIANT="2k"; ICON_BOLD_FLAG=""
        else
            SCREEN_VARIANT="1080p"; ICON_BOLD_FLAG=""
        fi
        echo -e "   • Resolución: ${GREEN}${SCREEN_WIDTH}px → $SCREEN_VARIANT${NC}"
    else
        SCREEN_VARIANT="4k"; ICON_BOLD_FLAG="-b"
    fi
else
    SCREEN_VARIANT="4k"; ICON_BOLD_FLAG="-b"
fi

# Detectar componentes
HAS_FLATPAK=false
command -v flatpak &> /dev/null && HAS_FLATPAK=true

HAS_DASH_TO_DOCK=false
[ -d "$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com" ] || \
[ -d "/usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com" ] && HAS_DASH_TO_DOCK=true

echo -e "   • Flatpak:      $([ "$HAS_FLATPAK" = true ] && echo "${GREEN}Detectado${NC}" || echo "${YELLOW}No detectado${NC}")"
echo -e "   • Dash to Dock: $([ "$HAS_DASH_TO_DOCK" = true ] && echo "${GREEN}Detectado${NC}" || echo "${YELLOW}No detectado${NC}")"
echo ""

# =============================================================================
# PASO 1: DEPENDENCIAS DEL SISTEMA
# =============================================================================
echo -e "${YELLOW}📦 [1/15] Instalando dependencias del sistema...${NC}"
if command -v apt-get &> /dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq git sassc libglib2.0-dev-bin libxml2-utils \
        fontconfig gnome-tweaks gnome-shell-extension-manager dconf-cli \
        plymouth-themes firefox plank x11-xserver-utils python3-pil \
        curl unzip wget jq gnome-backgrounds ffmpeg sox rofi fd-find \
        python3-requests xdotool wmctrl x11-utils 2>/dev/null
elif command -v dnf &> /dev/null; then
    sudo dnf install -y -q git sassc glib2-devel libxml2 fontconfig gnome-tweaks \
        dconf plymouth-theme-spinner firefox plank xorg-x11-server-utils \
        python3-pillow curl unzip wget jq gnome-backgrounds ffmpeg sox rofi \
        fd-find python3-requests xdotool wmctrl xorg-xprop xorg-xwininfo
elif command -v pacman &> /dev/null; then
    sudo pacman -S --noconfirm --needed git sassc glib2 libxml2 fontconfig gnome-tweaks \
        dconf plymouth firefox plank xorg-xrandr python-pillow curl unzip wget jq \
        gnome-backgrounds ffmpeg sox rofi fd python-requests xdotool wmctrl \
        xorg-xprop xorg-xwininfo
fi
echo -e "${GREEN}✅ Dependencias listas.${NC}"
echo ""

# =============================================================================
# PASO 2: FUENTES OFICIALES DE APPLE (SFWindows WWDC26)
# =============================================================================
echo -e "${YELLOW}🔤 [2/15] Instalando fuentes oficiales de Apple (WWDC26)...${NC}"
echo -e "   ${BLUE}→ SF Pro (interfaz del sistema)${NC}"
echo -e "   ${BLUE}→ SF Compact (variante watchOS)${NC}"
echo -e "   ${BLUE}→ SF Mono (terminal y código)${NC}"
echo -e "   ${BLUE}→ New York (fuente serif)${NC}"

FONTS_DIR="$HOME/.local/share/fonts"
SF_TEMP="$WORKDIR/sf-windows-temp"
mkdir -p "$FONTS_DIR" "$SF_TEMP" "$WORKDIR"

SF_INSTALLED=false

SF_PRO_URL="https://github.com/bradleyhodges/SFWindows/raw/refs/heads/main/SF%20Pro/SF-Pro.ttf"
SF_COMPACT_URL="https://github.com/bradleyhodges/SFWindows/raw/refs/heads/main/SF%20Compact/SF-Compact.ttf"
NEW_YORK_URL="https://github.com/bradleyhodges/SFWindows/raw/refs/heads/main/New%20York/NewYork.ttf"

download_font() {
    local url="$1"
    local output="$2"
    local name="$3"
    
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
    echo -e "   ${BLUE}→ Descargando SF Mono desde SFWindows...${NC}"
    if [ ! -d "$SF_REPO" ]; then
        git clone --depth=1 https://github.com/bradleyhodges/SFWindows.git "$SF_REPO" -q 2>/dev/null
    fi
    
    if [ -d "$SF_REPO/SF Mono" ]; then
        find "$SF_REPO/SF Mono" -type f \( -iname "*.ttf" -o -iname "*.otf" \) \
            -exec cp {} "$FONTS_DIR/" \; 2>/dev/null
        echo -e "   ${GREEN}✓ SF Mono instalada${NC}"
    fi
    
    if [ -d "$SF_REPO/SF Multilingual Extensions" ]; then
        find "$SF_REPO/SF Multilingual Extensions" -type f \( -iname "*.ttf" -o -iname "*.otf" \) \
            -exec cp {} "$FONTS_DIR/" \; 2>/dev/null
        echo -e "   ${GREEN}✓ Extensiones multilingües instaladas${NC}"
    fi
    
    SF_INSTALLED=true
else
    echo -e "   ${YELLOW}⚠️  Clonando repositorio completo como respaldo...${NC}"
    SF_REPO="$WORKDIR/SFWindows"
    [ ! -d "$SF_REPO" ] && git clone --depth=1 https://github.com/bradleyhodges/SFWindows.git "$SF_REPO" -q 2>/dev/null
    
    if [ -d "$SF_REPO" ]; then
        find "$SF_REPO" -type f \( -iname "*.ttf" -o -iname "*.otf" \) \
            -exec cp {} "$FONTS_DIR/" \; 2>/dev/null
        SF_INSTALLED=true
    fi
fi

fc-cache -f "$FONTS_DIR" > /dev/null 2>&1
[ "$SF_INSTALLED" = true ] && echo -e "${GREEN}✅ Fuentes oficiales Apple instaladas (WWDC26 v27.0).${NC}"
rm -rf "$SF_TEMP"
echo ""

# =============================================================================
# PASO 3: EXTENSIÓN LIQUID GLASS (SOLO GNOME/ZORIN)
# =============================================================================
IS_GNOME=false
if [[ "$DESKTOP_ENV" == *"gnome"* ]] || [[ "$DISTRO" == *"zorin"* ]]; then
    IS_GNOME=true
    echo -e "${YELLOW}🧩 [3/15] Instalando extensión 'Liquid Glass'...${NC}"
    mkdir -p ~/.local/share/gnome-shell/extensions/

    [ ! -d "$WORKDIR/liquid-glass" ] && \
        git clone --depth=1 https://github.com/ryohsuke1231/liquid-glass.git "$WORKDIR/liquid-glass" -q

    cp -r "$WORKDIR/liquid-glass/liquid-glass@thinkingcoding1231.gmail.com" \
        ~/.local/share/gnome-shell/extensions/

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
    echo -e "${YELLOW}⏭️  [3/15] Liquid Glass omitida (solo GNOME/Zorin).${NC}"
fi
echo ""

# =============================================================================
# PASO 4: EXTENSIÓN CINNAMON DYNAMIC WALLPAPER (SOLO CINNAMON)
# =============================================================================
IS_CINNAMON=false
if [[ "$DESKTOP_ENV" == *"cinnamon"* ]] || [[ "$DISTRO" == *"mint"* && "$DESKTOP_ENV" != *"xfce"* ]]; then
    IS_CINNAMON=true
    echo -e "${YELLOW}🌅 [4/15] Instalando extensión 'Cinnamon Dynamic Wallpaper'...${NC}"
    mkdir -p ~/.local/share/cinnamon/extensions/

    [ ! -d "$WORKDIR/cinnamon-dynamic-wallpaper" ] && \
        git clone --depth=1 https://github.com/TobiZog/cinnamon-dynamic-wallpaper.git "$WORKDIR/cinnamon-dynamic-wallpaper" -q

    cp -r "$WORKDIR/cinnamon-dynamic-wallpaper/cinnamon-dynamic-wallpaper@TobiZog" \
        ~/.local/share/cinnamon/extensions/ 2>/dev/null

    CINNAMON_EXTENSIONS=$(gsettings get org.cinnamon enabled-extensions 2>/dev/null)
    if ! echo "$CINNAMON_EXTENSIONS" | grep -q "cinnamon-dynamic-wallpaper@TobiZog"; then
        if [ "$CINNAMON_EXTENSIONS" = "[]" ]; then
            gsettings set org.cinnamon enabled-extensions "['cinnamon-dynamic-wallpaper@TobiZog']" 2>/dev/null
        else
            NEW_EXTENSIONS=$(echo "$CINNAMON_EXTENSIONS" | sed "s/]$, 'cinnamon-dynamic-wallpaper@TobiZog']/")
            gsettings set org.cinnamon enabled-extensions "$NEW_EXTENSIONS" 2>/dev/null
        fi
    fi
    echo -e "${GREEN}✅ Cinnamon Dynamic Wallpaper instalada.${NC}"
else
    echo -e "${YELLOW}⏭️  [4/15] Cinnamon Dynamic Wallpaper omitida.${NC}"
fi
echo ""

# =============================================================================
# PASO 5: TEMA GTK + ICONOS + CURSORES (macOS Tahoe)
# =============================================================================
echo -e "${YELLOW}🎨 [5/15] Instalando tema macOS Tahoe...${NC}"

[ ! -d "$WORKDIR/MacTahoe-gtk-theme" ] && \
    git clone --depth=1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git "$WORKDIR/MacTahoe-gtk-theme" -q
[ ! -d "$WORKDIR/MacTahoe-icon-theme" ] && \
    git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git "$WORKDIR/MacTahoe-icon-theme" -q

INSTALL_FLAGS="-c dark --silent-mode --round --darker"
if [ "$IS_GNOME" = true ]; then
    INSTALL_FLAGS="$INSTALL_FLAGS -l"
    if [ -d "$HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx" ] || \
       [ -d "/usr/share/gnome-shell/extensions/blur-my-shell@aunetx" ]; then
        INSTALL_FLAGS="$INSTALL_FLAGS -b"
    fi
fi

( cd "$WORKDIR/MacTahoe-gtk-theme" && ./install.sh $INSTALL_FLAGS > /dev/null 2>&1 )

if [ -n "$ICON_BOLD_FLAG" ]; then
    ( cd "$WORKDIR/MacTahoe-icon-theme" && ./install.sh $ICON_BOLD_FLAG > /dev/null 2>&1 )
else
    ( cd "$WORKDIR/MacTahoe-icon-theme" && ./install.sh > /dev/null 2>&1 )
fi

[ "$HAS_FLATPAK" = true ] && ( cd "$WORKDIR/MacTahoe-gtk-theme" && ./tweaks.sh -F -c dark > /dev/null 2>&1 )
[ "$HAS_DASH_TO_DOCK" = true ] && [ "$IS_GNOME" = true ] && ( cd "$WORKDIR/MacTahoe-gtk-theme" && ./tweaks.sh -d > /dev/null 2>&1 )
echo -e "${GREEN}✅ macOS Tahoe instalado.${NC}"
echo ""

# =============================================================================
# PASO 6: WALLPAPER DINÁMICO MOJAVE CON HORARIOS REALES
# =============================================================================
MOJAVE_INSTALLED=false
if [ "$IS_GNOME" = true ]; then
    echo -e "${YELLOW}🌄 [6/15] Instalando wallpaper dinámico Mojave...${NC}"
    MOJAVE_TEMP="$WORKDIR/gnome-kde-mojave-dynamic"
    
    [ ! -d "$MOJAVE_TEMP" ] && \
        git clone --depth=1 https://github.com/japamax/gnome-kde-dynamic-wallpaper-mojave.git "$MOJAVE_TEMP" -q 2>/dev/null
    
    if [ -d "$MOJAVE_TEMP/mojave" ] && [ -f "$MOJAVE_TEMP/mojave-timed.xml" ]; then
        sudo mkdir -p /usr/share/dynamicwallpapers/mojave-solar/contents/images
        sudo cp "$MOJAVE_TEMP/mojave/"* /usr/share/dynamicwallpapers/mojave-solar/contents/images/ 2>/dev/null
        sudo chmod 755 /usr/share/dynamicwallpapers/mojave-solar/contents/images 2>/dev/null
        sudo chmod 644 /usr/share/dynamicwallpapers/mojave-solar/contents/images/* 2>/dev/null
        
        sudo mkdir -p /usr/share/dynamicwallpapers/mojave-timed/contents
        sudo chmod 755 /usr/share/dynamicwallpapers/mojave-timed/contents 2>/dev/null
        sudo ln -sf /usr/share/dynamicwallpapers/mojave-solar/contents/images \
            /usr/share/dynamicwallpapers/mojave-timed/contents/images 2>/dev/null
        
        sudo mkdir -p /usr/share/backgrounds/macOS
        sudo ln -sf /usr/share/dynamicwallpapers/mojave-solar/contents/images \
            /usr/share/backgrounds/macOS/mojave 2>/dev/null
        
        [ -f "$MOJAVE_TEMP/mojave-solar.json" ] && \
            sudo cp "$MOJAVE_TEMP/mojave-solar.json" /usr/share/dynamicwallpapers/mojave-solar/metadata.json 2>/dev/null
        [ -f "$MOJAVE_TEMP/mojave-timed.json" ] && \
            sudo cp "$MOJAVE_TEMP/mojave-timed.json" /usr/share/dynamicwallpapers/mojave-timed/metadata.json 2>/dev/null
        [ -f "$MOJAVE_TEMP/mojave-timed.xml" ] && \
            sudo cp "$MOJAVE_TEMP/mojave-timed.xml" /usr/share/backgrounds/macOS/mojave-timed.xml 2>/dev/null
        
        sudo mkdir -p /usr/share/gnome-background-properties
        [ -f "$MOJAVE_TEMP/mojave.xml" ] && \
            sudo cp "$MOJAVE_TEMP/mojave.xml" /usr/share/gnome-background-properties/mojave.xml 2>/dev/null
        
        MOJAVE_INSTALLED=true
        echo -e "${GREEN}✅ Wallpaper Mojave con horarios reales instalado.${NC}"
    else
        echo -e "${YELLOW}⚠️  No se pudo descargar Mojave dinámico.${NC}"
    fi
else
    echo -e "${YELLOW}⏭️  [6/15] Mojave dinámico omitido (solo GNOME).${NC}"
fi
echo ""

# =============================================================================
# PASO 7: WALLPAPERS SONOMA (RESPALDO)
# =============================================================================
echo -e "${YELLOW}🖼️  [7/15] Instalando wallpapers macOS Sonoma...${NC}"

[ ! -d "$WORKDIR/WhiteSur-wallpapers" ] && \
    git clone --depth=1 https://github.com/vinceliuice/WhiteSur-wallpapers.git "$WORKDIR/WhiteSur-wallpapers" -q

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
echo -e "${YELLOW}🔊 [8/15] Instalando sonidos del sistema macOS Big Sur...${NC}"

SOUNDS_DIR="$HOME/.local/share/sounds"
SOUNDS_TEMP="$WORKDIR/bigsur-sounds-temp"
mkdir -p "$SOUNDS_DIR" "$SOUNDS_TEMP"

RELEASE_URL=$(curl -s https://api.github.com/repos/gxanshu/macos-bigsur-sound-theme-linux/releases/latest 2>/dev/null \
    | grep "browser_download_url" \
    | grep -E "\.tar\.gz|\.zip" \
    | head -1 \
    | cut -d '"' -f 4)

SOUND_INSTALLED=false

if [ -n "$RELEASE_URL" ]; then
    ARCHIVE_FILE="$SOUNDS_TEMP/bigsur-sounds.tar.gz"
    
    if curl -L "$RELEASE_URL" -o "$ARCHIVE_FILE" --silent --fail --max-time 120 2>/dev/null; then
        if file "$ARCHIVE_FILE" | grep -q "gzip"; then
            tar -xzf "$ARCHIVE_FILE" -C "$SOUNDS_TEMP" 2>/dev/null
        elif file "$ARCHIVE_FILE" | grep -q "Zip"; then
            unzip -q "$ARCHIVE_FILE" -d "$SOUNDS_TEMP" 2>/dev/null
        fi
        
        EXTRACTED_DIR=$(find "$SOUNDS_TEMP" -maxdepth 1 -type d -name "bigsur*" -o -name "*sound*" | head -1)
        [ -z "$EXTRACTED_DIR" ] && EXTRACTED_DIR="$SOUNDS_TEMP"
        
        if [ -f "$EXTRACTED_DIR/index.theme" ] || [ -d "$EXTRACTED_DIR/stereo" ]; then
            rm -rf "$SOUNDS_DIR/bigsur"
            cp -r "$EXTRACTED_DIR" "$SOUNDS_DIR/bigsur"
            
            if [ -d "$SOUNDS_DIR/bigsur/stereo" ] || [ -f "$SOUNDS_DIR/bigsur/index.theme" ]; then
                SOUND_INSTALLED=true
                echo -e "${GREEN}✅ Tema de sonidos macOS Big Sur instalado.${NC}"
            fi
        fi
    fi
fi

if [ "$SOUND_INSTALLED" != "true" ]; then
    ALT_REPO="$WORKDIR/bigsur-sound-theme"
    [ ! -d "$ALT_REPO" ] && \
        git clone --depth=1 https://github.com/gxanshu/macos-bigsur-sound-theme-linux.git "$ALT_REPO" -q 2>/dev/null
    
    if [ -d "$ALT_REPO" ]; then
        ( cd "$ALT_REPO" && make install > /dev/null 2>&1 ) 2>/dev/null
        [ -d "$SOUNDS_DIR/bigsur" ] && SOUND_INSTALLED=true && \
            echo -e "${GREEN}✅ Tema de sonidos construido e instalado.${NC}"
    fi
fi

rm -rf "$SOUNDS_TEMP"
echo ""

# =============================================================================
# PASO 9: ROFI SPOTLIGHT (LANZADOR ESTILO macOS)
# =============================================================================
echo -e "${YELLOW}🔍 [9/15] Instalando Rofi Spotlight (lanzador estilo macOS)...${NC}"

ROFI_SPOTLIGHT_DIR="$HOME/.local/share/rofi-spotlight"
ROFI_THEMES_DIR="$HOME/.local/share/rofi/themes"
mkdir -p "$ROFI_SPOTLIGHT_DIR" "$ROFI_THEMES_DIR"

[ ! -d "$WORKDIR/rofi-spotlight" ] && \
    git clone --depth=1 https://github.com/eromatiya/rofi-spotlight.git "$WORKDIR/rofi-spotlight" -q 2>/dev/null

if [ -d "$WORKDIR/rofi-spotlight" ]; then
    cp -r "$WORKDIR/rofi-spotlight"/* "$ROFI_SPOTLIGHT_DIR/" 2>/dev/null
    chmod +x "$ROFI_SPOTLIGHT_DIR/rofi-spotlight.sh" 2>/dev/null
    chmod +x "$ROFI_SPOTLIGHT_DIR/web-search.py" 2>/dev/null
fi

[ ! -d "$WORKDIR/rofi-themes-collection" ] && \
    git clone --depth=1 https://github.com/newmanls/rofi-themes-collection.git "$WORKDIR/rofi-themes-collection" -q 2>/dev/null

if [ -d "$WORKDIR/rofi-themes-collection/themes" ]; then
    cp "$WORKDIR/rofi-themes-collection/themes/"*.rasi "$ROFI_THEMES_DIR/" 2>/dev/null
fi

ROFI_LAUNCHER="$HOME/.local/bin/rofi-spotlight-launcher"
mkdir -p "$HOME/.local/bin"

cat > "$ROFI_LAUNCHER" << 'EOF'
#!/bin/bash
ROFI_SPOTLIGHT_DIR="$HOME/.local/share/rofi-spotlight"
ROFI_THEMES_DIR="$HOME/.local/share/rofi/themes"

if ! command -v rofi &> /dev/null; then
    notify-send "Error" "Rofi no está instalado" -i dialog-error
    exit 1
fi

if [ -f "$ROFI_SPOTLIGHT_DIR/rofi-spotlight.sh" ]; then
    rofi -modi "Global Search:$ROFI_SPOTLIGHT_DIR/rofi-spotlight.sh" \
         -show "Global Search" \
         -theme "$ROFI_THEMES_DIR/spotlight.rasi" \
         -config "$ROFI_SPOTLIGHT_DIR/rofi.rasi"
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
echo -e "${YELLOW}🚀 [10/15] Instalando temas de Plank...${NC}"

[ ! -d "$WORKDIR/MacOS-Mojave-Plank-themes" ] && \
    git clone --depth=1 https://github.com/Macintosh98/MacOS-Mojave-Plank-themes.git "$WORKDIR/MacOS-Mojave-Plank-themes" -q

mkdir -p ~/.local/share/plank/themes

find "$WORKDIR/MacOS-Mojave-Plank-themes" -maxdepth 1 -type d \
    \( -name "MacOS-*" -o -name "elementary-*" \) | while read -r theme_dir; do
    [ -d "$theme_dir" ] && cp -r "$theme_dir" ~/.local/share/plank/themes/
done
echo -e "${GREEN}✅ Temas de Plank instalados.${NC}"
echo ""

# =============================================================================
# PASO 11: TEMA PLYMOUTH (PANTALLA DE ARRANQUE)
# =============================================================================
echo -e "${YELLOW}🖥️  [11/15] Instalando tema Plymouth...${NC}"

if command -v plymouth &> /dev/null || [ -d /usr/share/plymouth/themes ]; then
    [ ! -d "$WORKDIR/apple-mac-plymouth" ] && \
        git clone --depth=1 https://github.com/navisjayaseelan/apple-mac-plymouth.git "$WORKDIR/apple-mac-plymouth" -q

    sudo cp -r "$WORKDIR/apple-mac-plymouth/apple-mac-plymouth" /usr/share/plymouth/themes/ 2>/dev/null

    sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth \
        default.plymouth /usr/share/plymouth/themes/apple-mac-plymouth/apple-mac-plymouth.plymouth 100 2>/dev/null

    echo "1" | sudo update-alternatives --config default.plymouth > /dev/null 2>&1

    if command -v update-initramfs &> /dev/null; then
        sudo update-initramfs -u > /dev/null 2>&1
    elif command -v dracut &> /dev/null; then
        sudo dracut --force > /dev/null 2>&1
    fi
    echo -e "${GREEN}✅ Tema Plymouth instalado.${NC}"
else
    echo -e "${YELLOW}⏭️  Plymouth no disponible.${NC}"
fi
echo ""

# =============================================================================
# PASO 12: TEMA DE FIREFOX
# =============================================================================
echo -e "${YELLOW}🦊 [12/15] Instalando tema de Firefox...${NC}"

if command -v firefox &> /dev/null || command -v firefox-bin &> /dev/null; then
    if pidof firefox &> /dev/null || pidof firefox-bin &> /dev/null; then
        pkill -f firefox 2>/dev/null
        sleep 2
    fi
    ( cd "$WORKDIR/MacTahoe-gtk-theme" && ./tweaks.sh -f > /dev/null 2>&1 )
    echo -e "${GREEN}✅ Tema de Firefox instalado.${NC}"
else
    echo -e "${YELLOW}⏭️  Firefox no instalado.${NC}"
fi
echo ""

# =============================================================================
# PASO 13: GDM (PANTALLA DE LOGIN)
# =============================================================================
echo -e "${YELLOW}🔐 [13/15] Configurando pantalla de login...${NC}"
if [ "$IS_GNOME" = true ]; then
    ( cd "$WORKDIR/MacTahoe-gtk-theme" && sudo ./tweaks.sh -g -b default > /dev/null 2>&1 )
    echo -e "${GREEN}✅ Pantalla de login configurada.${NC}"
else
    echo -e "${YELLOW}⏭️  GDM omitido (solo GNOME/Zorin).${NC}"
fi
echo ""

# =============================================================================
# PASO 14: SCRIPT AUXILIAR PARA VENTANAS AVANZADAS
# =============================================================================
echo -e "${YELLOW}🪟 [14/15] Instalando script auxiliar de gestión de ventanas...${NC}"

ADVANCED_WM_SCRIPT="$HOME/.local/bin/macos-wm-actions"
mkdir -p "$HOME/.local/bin"

cat > "$ADVANCED_WM_SCRIPT" << 'WMEOF'
#!/bin/bash
# macOS-style Window Management Actions
ACTION="${1}"

case "$ACTION" in
    "center")
        if command -v xdotool &> /dev/null; then
            WIN_ID=$(xdotool getactivewindow)
            WIN_W=$(xdotool getwindowgeometry --shell "$WIN_ID" | grep WIDTH | cut -d= -f2)
            WIN_H=$(xdotool getwindowgeometry --shell "$WIN_ID" | grep HEIGHT | cut -d= -f2)
            SCREEN_W=$(xdpyinfo | grep dimensions | awk '{print $2}' | cut -dx -f1)
            SCREEN_H=$(xdpyinfo | grep dimensions | awk '{print $2}' | cut -dx -f2)
            X=$(( (SCREEN_W - WIN_W) / 2 ))
            Y=$(( (SCREEN_H - WIN_H) / 2 ))
            xdotool windowmove "$WIN_ID" "$X" "$Y"
        fi
        ;;
    "toggle-maximize")
        if command -v xdotool &> /dev/null; then
            xdotool getactivewindow windowtogglemaximize 2>/dev/null || \
            wmctrl -r :ACTIVE: -b toggle,maximized_vert,maximized_horz 2>/dev/null
        fi
        ;;
    "toggle-fullscreen")
        [ -n "$(command -v wmctrl)" ] && wmctrl -r :ACTIVE: -b toggle,fullscreen
        ;;
    "toggle-always-on-top")
        [ -n "$(command -v wmctrl)" ] && wmctrl -r :ACTIVE: -b toggle,above
        ;;
    "opacity-decrease")
        if command -v xprop &> /dev/null; then
            CURRENT=$(xprop -id $(xdotool getactivewindow) _NET_WM_WINDOW_OPACITY 2>/dev/null | awk '{print $3}')
            CURRENT=${CURRENT:-0xffffffff}
            CURRENT=$((CURRENT))
            NEW=$((CURRENT - 427819008))
            [ "$NEW" -lt 858993459 ] && NEW=858993459
            xprop -id $(xdotool getactivewindow) -f _NET_WM_WINDOW_OPACITY 32c -set _NET_WM_WINDOW_OPACITY "$NEW"
        fi
        ;;
    "opacity-increase")
        if command -v xprop &> /dev/null; then
            CURRENT=$(xprop -id $(xdotool getactivewindow) _NET_WM_WINDOW_OPACITY 2>/dev/null | awk '{print $3}')
            CURRENT=${CURRENT:-0xffffffff}
            CURRENT=$((CURRENT))
            NEW=$((CURRENT + 427819008))
            [ "$NEW" -gt 4294967295 ] && NEW=4294967295
            xprop -id $(xdotool getactivewindow) -f _NET_WM_WINDOW_OPACITY 32c -set _NET_WM_WINDOW_OPACITY "$NEW"
        fi
        ;;
    "opacity-reset")
        [ -n "$(command -v xprop)" ] && xprop -id $(xdotool getactivewindow) -remove _NET_WM_WINDOW_OPACITY 2>/dev/null
        ;;
    "move-window")
        [ -n "$(command -v xdotool)" ] && xdotool getactivewindow windowmove --sync 0 0 2>/dev/null
        ;;
    "resize-window")
        [ -n "$(command -v xdotool)" ] && xdotool getactivewindow windowsize 50% 50% 2>/dev/null
        ;;
    "force-kill")
        if command -v xkill &> /dev/null; then
            xkill
        else
            notify-send "Error" "xkill no está instalado" -i dialog-error
        fi
        ;;
    "close-app-completely")
        if command -v xdotool &> /dev/null; then
            WIN_ID=$(xdotool getactivewindow)
            PID=$(xdotool getwindowpid "$WIN_ID" 2>/dev/null)
            if [ -n "$PID" ]; then
                PROCESS_NAME=$(ps -p "$PID" -o comm=)
                xdotool windowclose "$WIN_ID"
                sleep 0.3
                pkill -f "$PROCESS_NAME" 2>/dev/null
                notify-send "Aplicación cerrada" "$PROCESS_NAME finalizado completamente" -t 1500
            fi
        fi
        ;;
    "open-preferences")
        [ -n "$(command -v xdotool)" ] && xdotool key --clearmodifiers ctrl+comma
        ;;
    "restart-cinnamon")
        if [ "$XDG_CURRENT_DESKTOP" = "X-Cinnamon" ] || [ "$XDG_CURRENT_DESKTOP" = "cinnamon" ]; then
            dbus-send --session --dest=org.Cinnamon.LookingGlass \
                --type=method_call /org/Cinnamon/LookingGlass \
                org.Cinnamon.LookingGlass.ExecuteCommand string:"global.reexec_self()"
            notify-send "Cinnamon reiniciado" -t 1500
        fi
        ;;
esac
WMEOF

chmod +x "$ADVANCED_WM_SCRIPT"
echo -e "${GREEN}✅ Script auxiliar creado en $ADVANCED_WM_SCRIPT${NC}"
echo ""

# =============================================================================
# PASO 15: CONFIGURACIÓN DEL SISTEMA Y ATAJO DE TECLADO
# =============================================================================
echo -e "${YELLOW}⚙️  [15/15] Configurando sistema y atajos de teclado macOS...${NC}"

# Funciones auxiliares
gnome_set_keybinding() {
    local name="$1" command="$2" binding="$3" index="$4"
    local PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${index}/"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH name "$name" 2>/dev/null
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH command "$command" 2>/dev/null
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH binding "$binding" 2>/dev/null
}

cinnamon_set_keybinding() {
    local name="$1" command="$2" binding="$3" id="$4"
    local PATH="/org/cinnamon/desktop/keybindings/custom-keybindings/$id/"
    gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$PATH name "$name" 2>/dev/null
    gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$PATH command "$command" 2>/dev/null
    gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$PATH binding "$binding" 2>/dev/null
}

xfce_set_keybinding() {
    local command="$1" binding="$2"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/$binding" -n -t string -s "$command" 2>/dev/null || \
        xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/$binding" -s "$command" 2>/dev/null
}

# Selección inteligente del wallpaper
if [ "$MOJAVE_INSTALLED" = true ]; then
    WALLPAPER_PATH="/usr/share/backgrounds/macOS/mojave-timed.xml"
    WALLPAPER_DESC="dinámico Mojave (horarios reales)"
elif [ "$IS_GNOME" = true ]; then
    WALLPAPER_PATH="$HOME/.local/share/backgrounds/Sonoma/Sonoma-timed.xml"
    WALLPAPER_DESC="dinámico Sonoma"
else
    WALLPAPER_PATH="$HOME/.local/share/backgrounds/Sonoma-dark.jpg"
    WALLPAPER_DESC="estático Sonoma"
fi

# ---------- GNOME / ZORIN ----------
if [ "$IS_GNOME" = true ]; then
    echo -e "   ${BLUE}→ Configurando GNOME/Zorin...${NC}"
    
    # Tema e iconos
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null
    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null
    gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null
    gsettings set org.gnome.desktop.interface monospace-font-name "$MONO_FONT" 2>/dev/null
    
    # Fuentes Apple
    if [ "$SF_INSTALLED" = true ]; then
        gsettings set org.gnome.desktop.interface font-name "$UI_FONT" 2>/dev/null
        gsettings set org.gnome.desktop.interface document-font-name "$SERIF_FONT" 2>/dev/null
        gsettings set org.gnome.desktop.wm.preferences titlebar-font "$UI_FONT" 2>/dev/null
    fi
    
    gsettings set org.gnome.shell.extensions.user-theme name "$SHELL_THEME" 2>/dev/null
    
    # Wallpaper
    if [ -f "$WALLPAPER_PATH" ]; then
        gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_PATH" 2>/dev/null
        gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_PATH" 2>/dev/null
    fi
    
    # Sonidos
    if [ "$SOUND_INSTALLED" = true ]; then
        gsettings set org.gnome.desktop.sound theme-name "$SOUND_THEME" 2>/dev/null
        gsettings set org.gnome.desktop.sound event-sounds true 2>/dev/null
        gsettings set org.gnome.desktop.sound input-feedback-sounds true 2>/dev/null
    fi
    
    # Atajos nativos de GNOME
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
    
    # Capturas
    gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot "['Print']" 2>/dev/null
    gsettings set org.gnome.settings-daemon.plugins.media-keys window-screenshot "['<Alt>Print']" 2>/dev/null
    gsettings set org.gnome.settings-daemon.plugins.media-keys area-screenshot "['<Shift>Print']" 2>/dev/null
    
    # Atajos personalizados
    CUSTOM_PATHS=()
    INDEX=0
    
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
    
    CUSTOM_LIST=$(IFS=,; echo "[${CUSTOM_PATHS[*]}]")
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$CUSTOM_LIST" 2>/dev/null
    
    # Extensiones
    if command -v gnome-extensions &> /dev/null; then
        gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null
        gnome-extensions enable liquid-glass@thinkingcoding1231.gmail.com 2>/dev/null
        gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null
    fi
    
    # Liquid Glass
    LG_SCHEMA="org.gnome.shell.extensions.liquid-glass"
    if gsettings list-schemas 2>/dev/null | grep -q "$LG_SCHEMA"; then
        gsettings set "$LG_SCHEMA" enable-top-bar true 2>/dev/null
        gsettings set "$LG_SCHEMA" enable-dash-to-dock true 2>/dev/null
        gsettings set "$LG_SCHEMA" enable-notifications true 2>/dev/null
    fi
    
    # Dash to Dock
    DOCK_SCHEMA="org.gnome.shell.extensions.dash-to-dock"
    if gsettings list-schemas 2>/dev/null | grep -q "$DOCK_SCHEMA"; then
        gsettings set "$DOCK_SCHEMA" dock-position 'BOTTOM' 2>/dev/null
        gsettings set "$DOCK_SCHEMA" transparency-mode 'FIXED' 2>/dev/null
        gsettings set "$DOCK_SCHEMA" background-opacity 0.4 2>/dev/null
    fi

# ---------- CINNAMON ----------
elif [[ "$DESKTOP_ENV" == *"cinnamon"* ]] || [[ "$DISTRO" == *"mint"* && "$DESKTOP_ENV" != *"xfce"* ]]; then
    echo -e "   ${BLUE}→ Configurando Cinnamon...${NC}"
    
    # Tema e iconos
    gsettings set org.cinnamon.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null
    gsettings set org.cinnamon.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null
    gsettings set org.cinnamon.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null
    gsettings set org.cinnamon.theme name "$GTK_THEME" 2>/dev/null
    gsettings set org.cinnamon.desktop.wm.preferences theme "$GTK_THEME" 2>/dev/null
    gsettings set org.cinnamon.desktop.interface color-scheme 'prefer-dark' 2>/dev/null
    gsettings set org.cinnamon.desktop.interface monospace-font-name "$MONO_FONT" 2>/dev/null
    
    # Fuentes Apple
    if [ "$SF_INSTALLED" = true ]; then
        gsettings set org.cinnamon.desktop.interface font-name "$UI_FONT" 2>/dev/null
        gsettings set org.cinnamon.desktop.wm.preferences titlebar-font "$UI_FONT" 2>/dev/null
    fi
    
    # Wallpaper
    [ -f "$WALLPAPER_PATH" ] && gsettings set org.cinnamon.desktop.background picture-uri "file://$WALLPAPER_PATH" 2>/dev/null
    
    # Sonidos
    if [ "$SOUND_INSTALLED" = true ]; then
        gsettings set org.cinnamon.desktop.sound theme-name "$SOUND_THEME" 2>/dev/null
        gsettings set org.cinnamon.desktop.sound event-sounds true 2>/dev/null
    fi
    
    # Áreas de trabajo nativas
    gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-1 "['<Super>1']" 2>/dev/null
    gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-2 "['<Super>2']" 2>/dev/null
    gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-3 "['<Super>3']" 2>/dev/null
    gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-left "['<Ctrl><Alt>Left']" 2>/dev/null
    gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-right "['<Ctrl><Alt>Right']" 2>/dev/null
    gsettings set org.cinnamon.desktop.keybindings.wm tile-left "['<Super>Left']" 2>/dev/null
    gsettings set org.cinnamon.desktop.keybindings.wm tile-right "['<Super>Right']" 2>/dev/null
    gsettings set org.cinnamon.desktop.keybindings show-desktop "['<Super>d']" 2>/dev/null
    
    # Atajos personalizados
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
    
    CUSTOM_LIST=$(IFS=,; echo "[${CUSTOM_IDS[*]}]")
    gsettings set org.cinnamon.desktop.keybindings custom-list "$CUSTOM_LIST" 2>/dev/null
    
    # Panel inferior
    gsettings set org.cinnamon panels-enabled "['1:0:bottom']" 2>/dev/null

# ---------- XFCE ----------
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    echo -e "   ${BLUE}→ Configurando XFCE...${NC}"
    
    # Tema e iconos
    xfconf-query -c xsettings -p /Net/ThemeName -n -t string -s "$GTK_THEME" 2>/dev/null || \
        xfconf-query -c xsettings -p /Net/ThemeName -s "$GTK_THEME" 2>/dev/null
    xfconf-query -c xsettings -p /Net/IconThemeName -n -t string -s "$ICON_THEME" 2>/dev/null || \
        xfconf-query -c xsettings -p /Net/IconThemeName -s "$ICON_THEME" 2>/dev/null
    xfconf-query -c xsettings -p /Net/CursorThemeName -n -t string -s "$CURSOR_THEME" 2>/dev/null || \
        xfconf-query -c xsettings -p /Net/CursorThemeName -s "$CURSOR_THEME" 2>/dev/null
    
    # XFWM
    xfconf-query -c xfwm4 -p /general/theme -n -t string -s "$GTK_THEME" 2>/dev/null || \
        xfconf-query -c xfwm4 -p /general/theme -s "$GTK_THEME" 2>/dev/null
    xfconf-query -c xfwm4 -p /general/show_dock_shadow -n -t bool -s false 2>/dev/null
    xfconf-query -c xfwm4 -p /general/button_layout -n -t string -s "O|HMC" 2>/dev/null
    
    # Fuentes Apple
    if [ "$SF_INSTALLED" = true ]; then
        xfconf-query -c xsettings -p /Gtk/FontName -n -t string -s "$UI_FONT" 2>/dev/null || \
            xfconf-query -c xsettings -p /Gtk/FontName -s "$UI_FONT" 2>/dev/null
        xfconf-query -c xfwm4 -p /general/title_font -n -t string -s "$UI_FONT" 2>/dev/null || \
            xfconf-query -c xfwm4 -p /general/title_font -s "$UI_FONT" 2>/dev/null
    fi
    
    xfconf-query -c xsettings -p /Gtk/MonospaceFontName -n -t string -s "$MONO_FONT" 2>/dev/null || \
        xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s "$MONO_FONT" 2>/dev/null
    
    # Sonidos
    if [ "$SOUND_INSTALLED" = true ]; then
        xfconf-query -c xsettings -p /Net/SoundThemeName -n -t string -s "$SOUND_THEME" 2>/dev/null || \
            xfconf-query -c xsettings -p /Net/SoundThemeName -s "$SOUND_THEME" 2>/dev/null
        xfconf-query -c xsettings -p /Net/EnableEventSounds -n -t bool -s true 2>/dev/null
        xfconf-query -c xsettings -p /Net/EnableInputFeedbackSounds -n -t bool -s true 2>/dev/null
    fi
    
    # Atajos
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
    
    # XFWM atajos
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
    
    # Wallpaper
    [ -f "$WALLPAPER_PATH" ] && \
        xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -n -t string -s "$WALLPAPER_PATH" 2>/dev/null || \
        xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$WALLPAPER_PATH" 2>/dev/null
    
    # Plank
    if ! command -v plank &> /dev/null; then
        sudo apt-get install -y -qq plank 2>/dev/null || \
        sudo dnf install -y -q plank 2>/dev/null || \
        sudo pacman -S --noconfirm plank 2>/dev/null
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
# DOCUMENTACIÓN DE ATAJO DE TECLADO
# =============================================================================
KEYBINDINGS_DOC="$HOME/.macos-keybindings.md"
cat > "$KEYBINDINGS_DOC" << 'DOCEOF'
# 🍎 Atajos de Teclado Estilo macOS en Linux

## 📝 Edición de Texto (Nativos de apps GTK)
| Atajo | Acción |
|-------|--------|
| Ctrl + C | Copiar |
| Ctrl + V | Pegar |
| Ctrl + X | Cortar |
| Ctrl + Z | Deshacer |
| Ctrl + Y | Rehacer |
| Ctrl + A | Seleccionar todo |
| Ctrl + F | Buscar |
| Ctrl + B / I / U | Negrita / Cursiva / Subrayado |
| Ctrl + W | Cerrar pestaña actual |
| Ctrl + , | Preferencias de la app |

## 🖱️ Explorador de Archivos (Nativos)
| Atajo | Acción |
|-------|--------|
| Súper + E | Abrir Explorador |
| F2 | Renombrar |
| Alt + Enter | Propiedades |
| Supr | Papelera |
| Shift + Supr | Eliminar permanente |
| Ctrl + Shift + N | Nueva carpeta |
| Alt + ← / → | Atrás / Adelante |
| Alt + ↑ | Subir nivel |

## 🪟 Gestión de Ventanas
| Atajo | Acción |
|-------|--------|
| Súper + Q | Cerrar app |
| Súper + M | Minimizar |
| Súper + X | Maximizar/Restaurar |
| Súper + ← / → / ↑ / ↓ | Snap ventana |
| F11 | Pantalla completa |
| Súper + C | Centrar ventana |
| Súper + F | Siempre al frente |
| Súper + V | Mover ventana |
| Súper + R | Redimensionar |
| Súper + O | Menos opacidad |
| Súper + Ctrl + O | Más opacidad |
| Ctrl + Q | Cerrar app completamente |

## 🖥️ Sistema
| Atajo | Acción |
|-------|--------|
| Súper + A | Configuración |
| Súper + D | Mostrar/Ocultar Escritorio |
| Súper + L | Bloquear pantalla |
| Ctrl + Alt + T | Terminal |
| Ctrl + Shift + Esc | Monitor del Sistema |
| Ctrl + Espacio | Spotlight |
| ImprPant | Captura completa |
| Alt + ImprPant | Captura ventana |
| Shift + ImprPant | Captura área |

## 🏢 Áreas de Trabajo
| Atajo | Acción |
|-------|--------|
| Súper + F3 | Vista Galería |
| Súper + 1 / 2 / 3 | Ir al área 1/2/3 |
| Súper + Shift + 1/2/3 | Mover app al área |
| Ctrl + Alt + ← / → | Cambiar área |
| Ctrl + Alt + Supr | Cerrar sesión |
| Ctrl + Alt + Fin | Apagar/Reiniciar |

## 🔍 Avanzado
| Atajo | Acción |
|-------|--------|
| Alt + Ctrl + Esc | Forzar cierre (xkill) |
| Alt + Súper + = / - | Zoom in/out |
DOCEOF

echo -e "${GREEN}✅ Guía de atajos guardada en: ${BLUE}$KEYBINDINGS_DOC${NC}"
echo ""

# =============================================================================
# PROBAR SONIDO DE BIENVENIDA
# =============================================================================
if [ "$SOUND_INSTALLED" = true ]; then
    SOUND_FILE="$HOME/.local/share/sounds/bigsur/stereo/desktop-login.oga"
    if [ -f "$SOUND_FILE" ]; then
        if command -v paplay &> /dev/null; then
            paplay "$SOUND_FILE" 2>/dev/null &
        elif command -v aplay &> /dev/null; then
            aplay "$SOUND_FILE" 2>/dev/null &
        fi
        sleep 1
    fi
fi

# =============================================================================
# MENSAJE FINAL
# =============================================================================
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        🎉 ¡INSTALACIÓN COMPLETADA CON ÉXITO! 🎉         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📋 Versiones instaladas:${NC}"
echo -e "   🍎 ${GREEN}macOS Tahoe (26.7.1)${NC} - Tema GTK, iconos y cursores"
echo -e "   🔤 ${GREEN}Apple SF Pro + New York (WWDC26 v27.0)${NC} - Fuentes oficiales"
[ "$MOJAVE_INSTALLED" = true ] && \
    echo -e "   🌄 ${GREEN}macOS Mojave${NC} - Wallpaper dinámico (16 imágenes, horarios reales)" || \
    echo -e "   🖼️  ${GREEN}macOS Sonoma (14.8.9)${NC} - Wallpaper (respaldo)"
[ "$SOUND_INSTALLED" = true ] && \
    echo -e "   🔊 ${GREEN}macOS Big Sur${NC} - 44 eventos de sonido del sistema"
echo ""
echo -e "${BLUE}⌨️  Atajos configurados (principales):${NC}"
echo -e "   ${CYAN}Ctrl + Espacio${NC}   → Spotlight"
echo -e "   ${CYAN}Súper + E${NC}        → Explorador"
echo -e "   ${CYAN}Súper + D${NC}        → Escritorio"
echo -e "   ${CYAN}Súper + L${NC}        → Bloquear pantalla"
echo -e "   ${CYAN}Ctrl + Alt + T${NC}   → Terminal"
echo -e "   ${CYAN}Súper + Flechas${NC}  → Snap ventanas"
echo -e "   ${CYAN}Súper + C/F/V/R${NC}  → Centrar/Fijar/Mover/Redimensionar"
echo -e "   ${CYAN}Alt + Ctrl + Esc${NC} → Forzar cierre (xkill)"
echo ""
echo -e "   📖 Guía completa: ${BLUE}$KEYBINDINGS_DOC${NC}"
echo ""
echo -e "${BLUE}Componentes instalados:${NC}"
echo -e "   ✅ ${CYAN}SF Pro + New York${NC} (fuentes oficiales Apple)"
echo -e "   ✅ ${CYAN}SF Mono${NC} (terminal y código)"
echo -e "   ✅ Tema GTK: $GTK_THEME"
echo -e "   ✅ Iconos: $ICON_THEME"
echo -e "   ✅ Cursores: $CURSOR_THEME"
echo -e "   ✅ Rofi Spotlight (lanzador estilo macOS)"
[ "$SOUND_INSTALLED" = true ] && echo -e "   ✅ Sonidos macOS Big Sur (44 eventos)"
echo -e "   ✅ Temas de Plank"
echo -e "   ✅ Tema Plymouth (pantalla de arranque)"
echo -e "   ✅ Tema Firefox (estilo Safari)"
[ "$IS_GNOME" = true ] && echo -e "   ✅ Extensión Liquid Glass"
[ "$HAS_FLATPAK" = true ] && echo -e "   ✅ Soporte Flatpak"
[ "$HAS_DASH_TO_DOCK" = true ] && echo -e "   ✅ Fix Dash to Dock"
echo ""

if [ "$IS_GNOME" = true ]; then
    echo -e "${YELLOW}⚠️  ÚNICO PASO MANUAL:${NC}"
    if [ "$SESSION_TYPE" = "wayland" ]; then
        echo -e "   En Wayland, cierra sesión y vuelve a entrar:"
        echo -e "   ${BLUE}gnome-session-quit --logout${NC}"
    else
        echo -e "   Reiniciando GNOME Shell en X11..."
        dbus-send --session --type=method_call --dest=org.gnome.Shell \
            /org/gnome/Shell org.gnome.Shell.Eval \
            string:'Meta.restart("Reiniciando GNOME Shell...")' 2>/dev/null
    fi
elif [ "$IS_CINNAMON" = true ]; then
    dbus-send --session --dest=org.Cinnamon.LookingGlass --type=method_call \
        /org/Cinnamon/LookingGlass org.Cinnamon.LookingGlass.ExecuteCommand \
        string:"global.reexec_self()" 2>/dev/null
    echo -e "${GREEN}✨ Todo listo. ¡Disfruta de macOS Tahoe!${NC}"
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    echo -e "${GREEN}✨ Todo listo. ¡Disfruta de macOS Tahoe!${NC}"
fi

echo ""
echo -e "${YELLOW}💡 Prueba estos atajos ahora:${NC}"
echo -e "   • ${CYAN}Ctrl + Espacio${NC} → Abre Spotlight"
echo -e "   • ${CYAN}Súper + E${NC}        → Abre el explorador"
echo -e "   • ${CYAN}Súper + L${NC}        → Bloquea la pantalla"
echo -e "   • ${CYAN}Ctrl + Alt + T${NC}   → Abre el terminal"
echo ""
echo -e "${YELLOW}📜 Aviso legal:${NC}"
echo -e "   Las fuentes San Francisco y New York son propiedad de Apple Inc."
echo -e "   Su uso está sujeto a los acuerdos de licencia de Apple."
echo ""
