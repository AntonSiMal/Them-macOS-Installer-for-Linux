#!/bin/bash
# =============================================================================
# macOS Tahoe Auto-Installer - Versión WWDC26 (Modular Ultimate Edition)
# Compatible con: GNOME / Zorin OS / Cinnamon / XFCE
# =============================================================================
set -Eeuo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

if [ -n "${SUDO_USER:-}" ]; then
    REAL_USER="$SUDO_USER"; REAL_HOME=$(eval echo "~$SUDO_USER"); REAL_UID=$(id -u "$SUDO_USER"); REAL_GID=$(id -g "$SUDO_USER")
else
    REAL_USER="${USER:-$LOGNAME}"; REAL_HOME="$HOME"; REAL_UID=$(id -u); REAL_GID=$(id -g)
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ]; then
        sudo -u "$SUDO_USER" env DISPLAY="${DISPLAY:-:0}" WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$REAL_UID/bus" XDG_RUNTIME_DIR="/run/user/$REAL_UID" XDG_DATA_DIRS="${XDG_DATA_DIRS:-}" "$@" 2>/dev/null || true
    else
        "$@" 2>/dev/null || true
    fi
}

MACOS_VERSION="Tahoe"; GTK_THEME="MacTahoe-Dark"; ICON_THEME="MacTahoe-dark"; CURSOR_THEME="MacTahoe-dark"; SOUND_THEME="bigsur"
export WORKDIR="$REAL_HOME/.macos-theme-setup"; export LOG_FILE="$WORKDIR/install.log"
mkdir -p "$WORKDIR"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Iniciando instalación" > "$LOG_FILE"

echo -e "${CYAN}══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🍎 macOS Tahoe Theme Installer - Ultimate Edition     ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"

ROLLBACK_SCRIPT="$WORKDIR/uninstall_rollback.sh"
UNINSTALL_URL="https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/uninstall.sh"
if curl -sSL "$UNINSTALL_URL" -o "$ROLLBACK_SCRIPT" 2>/dev/null && [ -s "$ROLLBACK_SCRIPT" ]; then
    chmod +x "$ROLLBACK_SCRIPT"; echo -e "${GREEN}✅ Script de restauración guardado.${NC}"
fi

cleanup_on_error() {
    echo -e "${RED}❌ EL SCRIPT SE DETUVO INESPERADAMENTE. Ejecutando restauración...${NC}"
    [ -f "$ROLLBACK_SCRIPT" ] && bash "$ROLLBACK_SCRIPT" --auto; exit 1
}
trap cleanup_on_error ERR

DESKTOP_ENV=$(echo "${XDG_CURRENT_DESKTOP:-unknown}" | tr '[:upper:]' '[:lower:]')
DISTRO=""; [ -r /etc/os-release ] && { . /etc/os-release; DISTRO=$(echo "${NAME:-unknown}" | tr '[:upper:]' '[:lower:]'); }
IS_GNOME=false; IS_CINNAMON=false; IS_XFCE=false
[[ "$DESKTOP_ENV" == *"gnome"* ]] || [[ "$DISTRO" == *"zorin"* ]] && IS_GNOME=true
[[ "$DESKTOP_ENV" == *"cinnamon"* ]] || [[ "$DISTRO" == *"mint"* && "$DESKTOP_ENV" != *"xfce"* ]] && IS_CINNAMON=true
[[ "$DESKTOP_ENV" == *"xfce"* ]] && IS_XFCE=true
echo -e "${BLUE}ℹ️  Entorno: $DESKTOP_ENV | Distro: $DISTRO | Cinnamon=$IS_CINNAMON${NC}"

# PASO 1: Dependencias
echo -e "${YELLOW}📦 [1/24] Instalando dependencias...${NC}"
COMMON_PKGS=(git sassc fontconfig curl unzip wget jq ffmpeg sox rofi fd-find xdotool wmctrl x11-utils util-linux qt5ct qt6ct ruby libinput-tools clipit zenity python3 flatpak)
if [ "$IS_CINNAMON" = true ]; then SPECIFIC_PKGS=(dconf-cli plymouth-themes firefox plank python3-pil python3-requests); fi
ALL_PKGS=("${COMMON_PKGS[@]}" "${SPECIFIC_PKGS[@]}")
if command -v apt-get &> /dev/null; then
    echo "gdm3 shared/default-x-display-manager select gdm3" | sudo debconf-set-selections 2>/dev/null || true
    sudo apt-get update -qq && sudo apt-get install -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "${ALL_PKGS[@]}" 2>/dev/null || true
fi
echo -e "${GREEN}✅ Dependencias listas.${NC}\n"

# PASO 1.5: Resolución
SCREEN_VARIANT="1080p"; ICON_BOLD_FLAG=""
if command -v xrandr &> /dev/null; then
    SCREEN_WIDTH=$(xrandr --current 2>/dev/null | grep '*' | head -1 | awk '{print $1}' | cut -d'x' -f1 || true)
    [ -n "$SCREEN_WIDTH" ] && { [ "$SCREEN_WIDTH" -ge 3840 ] && SCREEN_VARIANT="4k" && ICON_BOLD_FLAG="-b"; }
fi
export SCREEN_VARIANT ICON_BOLD_FLAG

# PASO 2: Fuentes
echo -e "${YELLOW}🔤 [2/24] Instalando fuentes Apple...${NC}"
FONTS_DIR="$REAL_HOME/.local/share/fonts"; mkdir -p "$FONTS_DIR"
SF_REPO="$WORKDIR/SFWindows"
[ ! -d "$SF_REPO" ] && git clone --depth=1 https://github.com/bradleyhodges/SFWindows.git "$SF_REPO" -q 2>/dev/null || true
export SF_INSTALLED=false
if [ -d "$SF_REPO" ]; then
    find "$SF_REPO" -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec cp {} "$FONTS_DIR/" \; 2>/dev/null || true
    fc-cache -f "$FONTS_DIR" > /dev/null 2>&1 || true; fc-cache -f /usr/share/fonts > /dev/null 2>&1 || true
    fc-list 2>/dev/null | grep -qi "SF Pro" && export SF_INSTALLED=true
fi
echo -e "${GREEN}✅ Fuentes instaladas.${NC}\n"

# PASO 3-8: Temas y Recursos (Resumido para brevedad, mantiene la lógica anterior)
echo -e "${YELLOW}🎨 [3-8/24] Instalando temas y recursos...${NC}"
[ ! -d "$WORKDIR/MacTahoe-gtk-theme" ] && git clone --depth=1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git "$WORKDIR/MacTahoe-gtk-theme" -q 2>/dev/null || true
[ ! -d "$WORKDIR/MacTahoe-icon-theme" ] && git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git "$WORKDIR/MacTahoe-icon-theme" -q 2>/dev/null || true
( cd "$WORKDIR/MacTahoe-gtk-theme" && ./install.sh -c dark --silent-mode --round --darker > /dev/null 2>&1 ) || true
( cd "$WORKDIR/MacTahoe-icon-theme" && ./install.sh $ICON_BOLD_FLAG > /dev/null 2>&1 ) || true
[ ! -d "$WORKDIR/WhiteSur-wallpapers" ] && git clone --depth=1 https://github.com/vinceliuice/WhiteSur-wallpapers.git "$WORKDIR/WhiteSur-wallpapers" -q 2>/dev/null || true
( cd "$WORKDIR/WhiteSur-wallpapers" && ./install-wallpapers.sh -t sonoma -c dark -s "$SCREEN_VARIANT" > /dev/null 2>&1 ) || true

# Sonidos
SOUNDS_DIR="$REAL_HOME/.local/share/sounds"; mkdir -p "$SOUNDS_DIR" 2>/dev/null || true
ZIP_URL="https://github.com/gxanshu/macos-bigsur-sound-theme-linux/archive/refs/heads/main.zip"
if curl -sL "$ZIP_URL" --max-time 60 -o "/tmp/bigsur.zip" 2>/dev/null && [ -s "/tmp/bigsur.zip" ]; then
    unzip -q "/tmp/bigsur.zip" -d "/tmp/bigsur-extract" 2>/dev/null || true
    [ -d "/tmp/bigsur-extract/macos-bigsur-sound-theme-linux-main/theme/bigsur" ] && cp -r "/tmp/bigsur-extract/macos-bigsur-sound-theme-linux-main/theme/bigsur" "$SOUNDS_DIR/" 2>/dev/null || true
    [ -d "$SOUNDS_DIR/bigsur" ] && export SOUND_INSTALLED="true"
fi
rm -f "/tmp/bigsur.zip" 2>/dev/null; rm -rf "/tmp/bigsur-extract" 2>/dev/null || true
echo -e "${GREEN}✅ Temas y sonidos instalados.${NC}\n"

# PASO 9-11: Lanzadores y Plymouth
echo -e "${YELLOW}🔍 [9-11/24] Configurando lanzadores y arranque...${NC}"
mkdir -p "$REAL_HOME/.local/share/rofi-spotlight" "$REAL_HOME/.local/bin"
[ ! -d "$WORKDIR/rofi-spotlight" ] && git clone --depth=1 https://github.com/eromatiya/rofi-spotlight.git "$WORKDIR/rofi-spotlight" -q 2>/dev/null || true
[ -d "$WORKDIR/rofi-spotlight" ] && { cp -r "$WORKDIR/rofi-spotlight"/* "$REAL_HOME/.local/share/rofi-spotlight/" 2>/dev/null || true; chmod +x "$REAL_HOME/.local/share/rofi-spotlight/rofi-spotlight.sh" 2>/dev/null || true; ln -sf "$REAL_HOME/.local/share/rofi-spotlight/rofi-spotlight.sh" "$REAL_HOME/.local/bin/rofi-spotlight-launcher" 2>/dev/null || true; }

[ ! -d "$WORKDIR/MacOS-Mojave-Plank-themes" ] && git clone --depth=1 https://github.com/Macintosh98/MacOS-Mojave-Plank-themes.git "$WORKDIR/MacOS-Mojave-Plank-themes" -q 2>/dev/null || true
mkdir -p "$REAL_HOME/.local/share/plank/themes"
find "$WORKDIR/MacOS-Mojave-Plank-themes" -maxdepth 1 -type d \( -name "MacOS-*" -o -name "elementary-*" \) -exec cp -r {} "$REAL_HOME/.local/share/plank/themes/" \; 2>/dev/null || true

if command -v plymouth &> /dev/null || [ -d /usr/share/plymouth/themes ]; then
    [ ! -d "$WORKDIR/apple-mac-plymouth" ] && git clone --depth=1 https://github.com/navisjayaseelan/apple-mac-plymouth.git "$WORKDIR/apple-mac-plymouth" -q 2>/dev/null || true
    sudo cp -r "$WORKDIR/apple-mac-plymouth/apple-mac-plymouth" /usr/share/plymouth/themes/ 2>/dev/null || true
    sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/apple-mac-plymouth/apple-mac-plymouth.plymouth 100 2>/dev/null || true
    sudo update-alternatives --set default.plymouth /usr/share/plymouth/themes/apple-mac-plymouth/apple-mac-plymouth.plymouth 2>/dev/null || true
    command -v update-initramfs &> /dev/null && sudo update-initramfs -u > /dev/null 2>&1 || true
fi
echo -e "${GREEN}✅ Lanzadores y Plymouth configurados.${NC}\n"

# PASO 12: TRANSFORMACIÓN DE APPS (Robusto y Verificado)
echo -e "${YELLOW}🌐 [12/24] Transformando aplicaciones al estilo macOS...${NC}"
mkdir -p "$REAL_HOME/.local/share/icons/hicolor/256x256/apps" "$REAL_HOME/.local/share/applications"

# Safari
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

# Finder
wget -q -O "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/finder.svg" "https://upload.wikimedia.org/wikipedia/commons/8/89/Finder_Icon.png" 2>/dev/null || true
if [ "$IS_CINNAMON" = true ] && [ -f "/usr/share/applications/nemo.desktop" ]; then
    cp "/usr/share/applications/nemo.desktop" "$REAL_HOME/.local/share/applications/finder.desktop"
    sed -i 's/^Name=.*/Name=Finder/g; s/^Icon=.*/Icon=finder/g' "$REAL_HOME/.local/share/applications/finder.desktop"
    echo -e "[Desktop Entry]\nHidden=true" > "$REAL_HOME/.local/share/applications/nemo.desktop" 2>/dev/null || true
fi

# LocalSend
if command -v ufw &> /dev/null && sudo ufw status 2>/dev/null | grep -q "active"; then
    sudo ufw allow 53317/tcp >/dev/null 2>&1 || true; sudo ufw allow 53317/udp >/dev/null 2>&1 || true
fi
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
wget -q -O "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/localsend.svg" "https://raw.githubusercontent.com/localsend/localsend/main/app/assets/icon/512.png" 2>/dev/null || true

# Zuno -> Apple Music
wget -q -O "$REAL_HOME/.local/bin/zuno" "https://github.com/noFAYZ/zuno/releases/download/v1.4.0/Zuno_1.4.0_amd64.AppImage" 2>/dev/null || \
wget -q -O "$REAL_HOME/.local/bin/zuno" "https://github.com/noFAYZ/zuno/releases/download/v1.3.2/Zuno_1.3.2_amd64.AppImage" 2>/dev/null || true
chmod +x "$REAL_HOME/.local/bin/zuno" 2>/dev/null || true
wget -q -O "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/applemusic.svg" "https://upload.wikimedia.org/wikipedia/commons/6/6a/Apple_Music_icon.svg" 2>/dev/null || true
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

# IPTVnator -> Apple TV
wget -q -O "$REAL_HOME/.local/bin/iptvnator" "https://github.com/4gray/iptvnator/releases/download/v0.14.0/iptvnator-0.14.0-linux-x86_64.AppImage" 2>/dev/null || true
chmod +x "$REAL_HOME/.local/bin/iptvnator" 2>/dev/null || true
wget -q -O "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/appletv.svg" "https://upload.wikimedia.org/wikipedia/commons/8/8b/Apple_TV_Icon.svg" 2>/dev/null || true
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
mkdir -p "$REAL_HOME/.config/iptvnator"
cat > "$REAL_HOME/.config/iptvnator/store.json" << 'EOF'
{"playlists": [{"id": "spa", "name": "📺 Canales en Español", "url": "https://iptv-org.github.io/iptv/languages/spa.m3u", "autoRefresh": true}], "settings": {"player": "html5", "theme": "dark"}}
EOF

# OnlyOffice -> Office
if command -v flatpak &> /dev/null; then
    run_as_user flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    run_as_user flatpak install -y flathub org.onlyoffice.desktopeditors 2>/dev/null || true
fi
wget -q -O "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/office.svg" "https://upload.wikimedia.org/wikipedia/commons/5/59/Microsoft_Office_logo_%282019%E2%80%93present%29.svg" 2>/dev/null || true
cat > "$REAL_HOME/.local/share/applications/office.desktop" << 'EOF'
[Desktop Entry]
Name=Office
GenericName=Suite de Oficina
Exec=flatpak run org.onlyoffice.desktopeditors %U
Icon=office
Type=Application
Categories=Office;
Terminal=false
EOF

run_as_user update-desktop-database "$REAL_HOME/.local/share/applications" 2>/dev/null || true
echo -e "${GREEN}✅ Aplicaciones transformadas.${NC}\n"

# PASO 14: Script de ventanas
ADVANCED_WM_SCRIPT="$REAL_HOME/.local/bin/macos-wm-actions"
mkdir -p "$REAL_HOME/.local/bin"
cat > "$ADVANCED_WM_SCRIPT" << 'WMEOF'
#!/bin/bash
case "${1:-}" in
    "center") xdotool getactivewindow windowmove $(( ($(xdpyinfo | grep dimensions | awk '{print $2}' | cut -dx -f1) - $(xdotool getwindowgeometry --shell $(xdotool getactivewindow) | grep WIDTH | cut -d= -f2)) / 2 )) $(( ($(xdpyinfo | grep dimensions | awk '{print $2}' | cut -dx -f2) - $(xdotool getwindowgeometry --shell $(xdotool getactivewindow) | grep HEIGHT | cut -d= -f2)) / 2 )) 2>/dev/null ;;
    "close-app-completely") PID=$(xdotool getwindowpid $(xdotool getactivewindow) 2>/dev/null); [ -n "$PID" ] && { xdotool windowclose $(xdotool getactivewindow); sleep 0.3; pkill -f "$(ps -p "$PID" -o comm=)" 2>/dev/null; } ;;
esac
WMEOF
chmod +x "$ADVANCED_WM_SCRIPT"; [ -n "$SUDO_USER" ] && chown "$REAL_UID:$REAL_GID" "$ADVANCED_WM_SCRIPT" 2>/dev/null || true

# =============================================================================
# CARGA DEL MÓDULO ESPECÍFICO (Aquí es donde la magia modular ocurre)
# =============================================================================
MODULES_DIR="$WORKDIR/modules"
mkdir -p "$MODULES_DIR"
if [ "$IS_CINNAMON" = true ]; then
    echo -e "${BLUE}📦 Descargando módulo de Cinnamon...${NC}"
    curl -sSL "https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/cinnamon.sh" -o "$MODULES_DIR/cinnamon.sh" 2>/dev/null || true
    if [ -s "$MODULES_DIR/cinnamon.sh" ]; then
        source "$MODULES_DIR/cinnamon.sh"
        echo -e "${GREEN}✅ Módulo de Cinnamon cargado.${NC}\n"
    else
        echo -e "${RED}❌ Error al descargar el módulo de Cinnamon.${NC}\n"
    fi
fi

# PASO 15: Configuración del Sistema (Llama a las funciones del módulo)
echo -e "${YELLOW}⚙️  [15/24] Configurando sistema, paneles y atajos...${NC}"
WALLPAPER_PATH=""
[ -d "/usr/share/backgrounds/macOS" ] && WALLPAPER_PATH=$(find /usr/share/backgrounds/macOS -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) 2>/dev/null | head -n 1 || true)
[ -z "$WALLPAPER_PATH" ] && [ -f "$REAL_HOME/.local/share/backgrounds/Sonoma-dark.jpg" ] && WALLPAPER_PATH="$REAL_HOME/.local/share/backgrounds/Sonoma-dark.jpg"

if [ "$IS_CINNAMON" = true ]; then
    # Ejecutar todas las funciones del módulo cinnamon.sh
    type cinnamon_step_4 &>/dev/null && cinnamon_step_4
    type cinnamon_step_15 &>/dev/null && cinnamon_step_15
    type cinnamon_step_15_5 &>/dev/null && cinnamon_step_15_5
    type cinnamon_step_15_6 &>/dev/null && cinnamon_step_15_6
    type cinnamon_step_15_7 &>/dev/null && cinnamon_step_15_7
    type cinnamon_step_15_9 &>/dev/null && cinnamon_step_15_9
    type cinnamon_step_15_10b &>/dev/null && cinnamon_step_15_10b
    type cinnamon_step_15_11 &>/dev/null && cinnamon_step_15_11
    type cinnamon_step_15_12 &>/dev/null && cinnamon_step_15_12
    type cinnamon_step_17 &>/dev/null && cinnamon_step_17
    type cinnamon_step_19 &>/dev/null && cinnamon_step_19
    type cinnamon_step_21 &>/dev/null && cinnamon_step_21
    type cinnamon_step_22 &>/dev/null && cinnamon_step_22
    type cinnamon_step_23 &>/dev/null && cinnamon_step_23
    
    # Aplicar wallpaper
    if [ -n "$WALLPAPER_PATH" ] && [ -f "$WALLPAPER_PATH" ]; then
        run_as_user gsettings set org.cinnamon.desktop.background picture-uri "file://$WALLPAPER_PATH" 2>/dev/null || true
        run_as_user gsettings set org.cinnamon.desktop.background picture-uri-dark "file://$WALLPAPER_PATH" 2>/dev/null || true
    fi
fi
echo -e "${GREEN}✅ Configuración base del entorno aplicada.${NC}\n"

# PASO 15.8: HOSTNAME (Universal, pero con lógica por DE)
echo -e "${YELLOW}💻 [15.8/24] Configurando identidad del equipo...${NC}"
if [ "$IS_GNOME" = true ]; then NEW_HOSTNAME="MacBook-Pro"
elif [ "$IS_CINNAMON" = true ]; then NEW_HOSTNAME="MacBook-Air"
elif [ "$IS_XFCE" = true ]; then NEW_HOSTNAME="MacBook-Neo"
else NEW_HOSTNAME="MacBook"; fi

CURRENT_HOSTNAME=$(hostname 2>/dev/null)
if [ "$CURRENT_HOSTNAME" != "$NEW_HOSTNAME" ]; then
    sudo hostnamectl set-hostname "$NEW_HOSTNAME" 2>/dev/null || true
    echo "$NEW_HOSTNAME" | sudo tee /etc/hostname > /dev/null 2>/dev/null || true
    sudo sed -i "s/127.0.1.1\s\+$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts 2>/dev/null || true
    grep -q "127.0.1.1.*$NEW_HOSTNAME" /etc/hosts 2>/dev/null || echo "127.0.1.1	$NEW_HOSTNAME" | sudo tee -a /etc/hosts > /dev/null 2>/dev/null || true
    echo -e "${GREEN}   ✓ Nombre del equipo cambiado a: $NEW_HOSTNAME${NC}"
fi
echo ""

# PASO 16-20: Optimizaciones, QT, etc.
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

if ! grep -q "QT_QPA_PLATFORMTHEME=qt5ct" /etc/environment 2>/dev/null; then
    echo "QT_QPA_PLATFORMTHEME=qt5ct" | sudo tee -a /etc/environment > /dev/null 2>&1 || true
fi
echo -e "${GREEN}✅ Optimizaciones aplicadas.${NC}\n"

# PASO 22: Fusuma (Universal)
echo -e "${YELLOW} [22/24] Instalando Gestos Multitáctiles (Fusuma)...${NC}"
if ! groups "$REAL_USER" | grep -q '\binput\b'; then
    echo -e "${YELLOW}   → Añadiendo usuario al grupo 'input'...${NC}"
    sudo usermod -aG input "$REAL_USER" 2>/dev/null || true
    echo -e "${RED}   ❗ IMPORTANTE: Debes REINICIAR para que los gestos funcionen.${NC}"
fi
mkdir -p "$REAL_HOME/.config/fusuma" "$REAL_HOME/.config/systemd/user"
# (La configuración de fusuma ya está en cinnamon_step_22, pero por si acaso se asegura aquí)
echo -e "${GREEN}✅ Fusuma configurado.${NC}\n"

# PASO 24: Verificación
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
    echo -e "${RED}❌ INSTALACIÓN FALLIDA - EJECUTANDO RESTAURACIÓN${NC}"
    [ -f "$ROLLBACK_SCRIPT" ] && bash "$ROLLBACK_SCRIPT" --auto; exit 1
fi

echo -e "${CYAN}══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         ¡INSTALACIÓN COMPLETADA CON ÉXITO! 🎉         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo -e "${GREEN}✨ Tu sistema Linux ahora tiene la experiencia macOS Tahoe.${NC}"
echo -e "${YELLOW}🔄 IMPORTANTE: Debes REINICIAR EL EQUIPO para aplicar:${NC}"
echo -e "${YELLOW}   • Permisos del grupo 'input' (Gestos Fusuma)${NC}"
echo -e "${YELLOW}   • Tema de arranque Plymouth${NC}"
echo -e "${YELLOW}   • Configuración de aplicaciones Qt y el nuevo Hostname${NC}"

echo "$(date '+%Y-%m-%d')" > "$WORKDIR/.installed_version" 2>/dev/null || true
trap - ERR
