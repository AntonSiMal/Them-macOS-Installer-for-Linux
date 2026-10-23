#!/usr/bin/env bash
# =============================================================================
# MacFCE.sh - Instalador Definitivo Estilo macOS Tahoe para XFCE (Todo en uno)
# Soporta: Linux Mint XFCE / Xubuntu / Debian XFCE
# =============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -n "${SUDO_USER:-}" ]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    REAL_UID=$(id -u "$SUDO_USER")
    REAL_GID=$(id -g "$SUDO_USER")
else
    REAL_USER="${USER:-$(whoami)}"
    REAL_HOME="$HOME"
    REAL_UID=$(id -u)
    REAL_GID=$(id -g)
fi

WORKDIR="$REAL_HOME/.macos-theme-setup"
mkdir -p "$WORKDIR"

run_as_user() {
    if [ "$(id -u)" -eq 0 ]; then
        sudo -u "$REAL_USER" env DISPLAY="${DISPLAY:-:0}" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$REAL_UID/bus" \
            XDG_RUNTIME_DIR="/run/user/$REAL_UID" "$@" 2>/dev/null || true
    else
        "$@" 2>/dev/null || true
    fi
}

xfce_set_keybinding() {
    local command="$1"
    local binding="$2"

    run_as_user xfconf-query \
        -c xfce4-keyboard-shortcuts \
        -p "/commands/custom/$binding" \
        -n -t string -s "$command" 2>/dev/null ||
    run_as_user xfconf-query \
        -c xfce4-keyboard-shortcuts \
        -p "/commands/custom/$binding" \
        -s "$command" 2>/dev/null || true
}

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         🍏 Instalador Definitivo macOS Tahoe para XFCE           ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"

# =============================================================================
# PASO 0: CORREGIR PERMISOS Y ESTRUCTURA DE DIRECTORIOS
# =============================================================================
echo -e "\n${YELLOW}🔐 [0/12] Preparando estructura de directorios y permisos...${NC}"

mkdir -p "$REAL_HOME/.local/share/applications"
mkdir -p "$REAL_HOME/.local/share/icons/hicolor/256x256/apps"
mkdir -p "$REAL_HOME/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$REAL_HOME/.local/share/fonts"
mkdir -p "$REAL_HOME/.local/share/sounds"
mkdir -p "$REAL_HOME/.local/share/plank/themes"
mkdir -p "$REAL_HOME/.local/bin"
mkdir -p "$REAL_HOME/.themes"
mkdir -p "$REAL_HOME/.icons"
mkdir -p "$REAL_HOME/.config/rofi"
mkdir -p "$REAL_HOME/.config/autostart"
mkdir -p "$REAL_HOME/.config/systemd/user"
mkdir -p "$REAL_HOME/.config/gtk-3.0"
mkdir -p "$REAL_HOME/.config/xfce4/xfconf/xfce-perchannel-xml"

sudo chown -R "$REAL_USER:$REAL_GID" "$REAL_HOME/.local" "$REAL_HOME/.config" "$WORKDIR" 2>/dev/null || true
chmod -R u+rwX "$REAL_HOME/.local/share/applications/" "$REAL_HOME/.local/share/icons/" 2>/dev/null || true

echo -e "${GREEN}   ✓ Estructura y permisos listos${NC}"

# =============================================================================
# PASO 1: DEPENDENCIAS DEL SISTEMA (INSTALACIÓN SEGURA + SOPORTE APPIMAGE)
# =============================================================================
echo -e "\n${YELLOW}📦 [1/12] Instalando dependencias del sistema, Plank, Flatpak y codecs...${NC}"

sudo apt-get update -qq 2>/dev/null || true

# Paquetes críticos separados para evitar que un paquete ausente cancele todo el bloque
CORE_PKGS=(
    wget curl git unzip sassc libglib2.0-dev-bin libxml2-utils
    wmctrl xdotool x11-utils xinput libinput-tools ruby
    rofi plank qt5ct dconf-cli plymouth plymouth-themes ufw flatpak
    python3 python3-gi gir1.2-gtk-3.0 libnotify-bin
    alsa-utils pulseaudio-utils
    xfce4-whiskermenu-plugin xfce4-pulseaudio-plugin xfce4-notifyd light-locker xfce4-terminal
)

for pkg in "${CORE_PKGS[@]}"; do
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$pkg" 2>/dev/null || true
done

# Soporte FUSE indispensable para ejecutar LocalSend, Zuno e IPTVnator (.AppImage)
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq libfuse2 2>/dev/null || \
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq libfuse2t64 2>/dev/null || true

# Codecs GStreamer y plugins opcionales de XFCE
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav \
    xfce4-appmenu-plugin xfce4-docklike-plugin 2>/dev/null || true

sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
echo -e "${GREEN}   ✓ Dependencias base, Plank y soporte AppImage instalados${NC}"

# =============================================================================
# PASO 2: FUENTES APPLE (SF PRO, SF MONO, NEW YORK) Y FONTCONFIG
# =============================================================================
echo -e "\n${YELLOW}🔤 [2/12] Instalando fuentes Apple y optimización Fontconfig...${NC}"

FONT_DIR="$REAL_HOME/.local/share/fonts"
SF_REPO="$WORKDIR/SFWindows"

if [ ! -d "$SF_REPO" ]; then
    git clone --depth=1 https://github.com/bradleyhodges/SFWindows.git "$SF_REPO" -q 2>/dev/null || \
    git clone --depth=1 https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts.git "$SF_REPO" -q 2>/dev/null || true
fi

if [ -d "$SF_REPO" ]; then
    find "$SF_REPO" -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec cp {} "$FONT_DIR/" \; 2>/dev/null || true
fi

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
    <edit name="lcdfilter" mode="assign"><const>lcddefault</const></edit>
  </match>
</fontconfig>
EOF

sudo chown -R "$REAL_USER:$REAL_GID" "$FONT_DIR" "$REAL_HOME/.config/fontconfig" 2>/dev/null || true
fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true

run_as_user xfconf-query -c xsettings -p /Gtk/FontName -n -t string -s "SF Pro Text 11" 2>/dev/null || \
run_as_user xfconf-query -c xsettings -p /Gtk/FontName -s "SF Pro Text 11" 2>/dev/null || true
run_as_user xfconf-query -c xsettings -p /Gtk/MonospaceFontName -n -t string -s "SF Mono Regular 11" 2>/dev/null || \
run_as_user xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s "SF Mono Regular 11" 2>/dev/null || true
run_as_user xfconf-query -c xfwm4 -p /general/title_font -n -t string -s "SF Pro Text Bold 11" 2>/dev/null || \
run_as_user xfconf-query -c xfwm4 -p /general/title_font -s "SF Pro Text Bold 11" 2>/dev/null || true

echo -e "${GREEN}   ✓ Fuentes Apple instaladas y aplicadas en XFCE${NC}"

# =============================================================================
# PASO 3: TEMA MACTAHOE GTK, ICONOS, BOTONES DE VENTANA (CHM|) Y PLANK DOCK
# =============================================================================
echo -e "\n${YELLOW}🎨 [3/12] Instalando Tema MacTahoe, ordenando botones y configurando Plank...${NC}"

SCREEN_WIDTH=$(xrandr --current 2>/dev/null | grep '*' | head -1 | awk '{print $1}' | cut -d'x' -f1 || echo "1920")
ICON_BOLD_FLAG=""
[ "${SCREEN_WIDTH:-1920}" -ge 3840 ] && ICON_BOLD_FLAG="-b"

if [ ! -d "$WORKDIR/MacTahoe-gtk-theme" ]; then
    git clone --depth=1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git "$WORKDIR/MacTahoe-gtk-theme" -q 2>/dev/null || \
    git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git "$WORKDIR/MacTahoe-gtk-theme" -q 2>/dev/null || true
fi
if [ -d "$WORKDIR/MacTahoe-gtk-theme" ]; then
    ( cd "$WORKDIR/MacTahoe-gtk-theme" && ./install.sh -d "$REAL_HOME/.themes" -c dark -c light --round > /dev/null 2>&1 ) || true
fi

if [ ! -d "$WORKDIR/MacTahoe-icon-theme" ]; then
    git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git "$WORKDIR/MacTahoe-icon-theme" -q 2>/dev/null || \
    git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git "$WORKDIR/MacTahoe-icon-theme" -q 2>/dev/null || true
fi
if [ -d "$WORKDIR/MacTahoe-icon-theme" ]; then
    ( cd "$WORKDIR/MacTahoe-icon-theme" && ./install.sh -d "$REAL_HOME/.icons" $ICON_BOLD_FLAG > /dev/null 2>&1 ) || true
fi

sudo chown -R "$REAL_USER:$REAL_GID" "$REAL_HOME/.themes" "$REAL_HOME/.icons" 2>/dev/null || true

# Detectar nombre exacto del tema instalado (MacTahoe-Dark o WhiteSur-Dark)
INSTALLED_GTK="MacTahoe-Dark"
[ ! -d "$REAL_HOME/.themes/MacTahoe-Dark" ] && [ -d "$REAL_HOME/.themes/WhiteSur-Dark" ] && INSTALLED_GTK="WhiteSur-Dark"

INSTALLED_ICONS="MacTahoe-dark"
[ ! -d "$REAL_HOME/.icons/MacTahoe-dark" ] && [ -d "$REAL_HOME/.icons/WhiteSur-dark" ] && INSTALLED_ICONS="WhiteSur-dark"
[ ! -d "$REAL_HOME/.icons/$INSTALLED_ICONS" ] && [ -d "$REAL_HOME/.icons/WhiteSur" ] && INSTALLED_ICONS="WhiteSur"

run_as_user xfconf-query -c xsettings -p /Net/ThemeName -n -t string -s "$INSTALLED_GTK" 2>/dev/null || \
run_as_user xfconf-query -c xsettings -p /Net/ThemeName -s "$INSTALLED_GTK" 2>/dev/null || true

run_as_user xfconf-query -c xfwm4 -p /general/theme -n -t string -s "$INSTALLED_GTK" 2>/dev/null || \
run_as_user xfconf-query -c xfwm4 -p /general/theme -s "$INSTALLED_GTK" 2>/dev/null || true

run_as_user xfconf-query -c xsettings -p /Net/IconThemeName -n -t string -s "$INSTALLED_ICONS" 2>/dev/null || \
run_as_user xfconf-query -c xsettings -p /Net/IconThemeName -s "$INSTALLED_ICONS" 2>/dev/null || true

# ORDENAR BOTONES DE VENTANA EN XFWM4: Cerrar (C), Minimizar (H), Maximizar (M) a la izquierda + Título (|)
run_as_user xfconf-query -c xfwm4 -p /general/button_layout -n -t string -s "CHM|" 2>/dev/null || \
run_as_user xfconf-query -c xfwm4 -p /general/button_layout -s "CHM|" 2>/dev/null || true
run_as_user xfconf-query -c xfwm4 -p /general/use_compositing -n -t bool -s true 2>/dev/null || \
run_as_user xfconf-query -c xfwm4 -p /general/use_compositing -s true 2>/dev/null || true

echo -e "${GREEN}   ✓ Botones de ventana ordenados a la izquierda: Cerrar (C), Minimizar (H), Maximizar (M)${NC}"

# Configurar temas de Plank Dock y lanzarlo
if [ ! -d "$WORKDIR/MacOS-Mojave-Plank-themes" ]; then
    git clone --depth=1 https://github.com/Macintosh98/MacOS-Mojave-Plank-themes.git "$WORKDIR/MacOS-Mojave-Plank-themes" -q 2>/dev/null || true
fi
if [ -d "$WORKDIR/MacOS-Mojave-Plank-themes" ]; then
    cp -r "$WORKDIR/MacOS-Mojave-Plank-themes"/* "$REAL_HOME/.local/share/plank/themes/" 2>/dev/null || true
    sudo cp -r "$WORKDIR/MacOS-Mojave-Plank-themes"/* /usr/share/plank/themes/ 2>/dev/null || true
fi

run_as_user dconf write /net/launchpad/plank/docks/dock1/position "'bottom'" 2>/dev/null || true
run_as_user dconf write /net/launchpad/plank/docks/dock1/alignment "'center'" 2>/dev/null || true
run_as_user dconf write /net/launchpad/plank/docks/dock1/hide-mode "'intelligent'" 2>/dev/null || true
run_as_user dconf write /net/launchpad/plank/docks/dock1/icon-size 48 2>/dev/null || true
run_as_user dconf write /net/launchpad/plank/docks/dock1/zoom-enabled true 2>/dev/null || true
run_as_user dconf write /net/launchpad/plank/docks/dock1/zoom-percent 150 2>/dev/null || true
run_as_user dconf write /net/launchpad/plank/docks/dock1/theme "'Gtk+'" 2>/dev/null || true

cat > "$REAL_HOME/.config/autostart/plank.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Plank Dock
Comment=macOS Dock for XFCE
Exec=plank
X-GNOME-Autostart-enabled=true
X-XFCE-Autostart-Override=true
NoDisplay=false
EOF

echo -e "${GREEN}   ✓ Tema MacTahoe y Plank Dock configurados${NC}"

# =============================================================================
# PASO 4: PANEL SUPERIOR ESTILO macOS Y WHISKER MENU CON LOGO APPLE
# =============================================================================
echo -e "\n${YELLOW}🍎 [4/12] Configurando panel superior y Whisker Menu...${NC}"

ICON_DIR="$REAL_HOME/.local/share/icons/apple-menu/scalable/apps"
mkdir -p "$ICON_DIR"

cat > "$ICON_DIR/apple-logo.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 170 170" width="100%" height="100%">
  <path fill="#FFFFFF" d="M150.37 130.25c-2.45 5.66-5.35 10.87-8.71 15.66-4.58 6.53-8.33 11.05-11.22 13.56-4.48 4.12-9.28 6.23-14.42 6.35-3.69 0-8.14-1.05-13.32-3.18-5.19-2.12-9.97-3.17-14.34-3.17-4.58 0-9.49 1.05-14.75 3.17-5.26 2.13-9.5 3.24-12.74 3.35-4.35.13-9.13-1.9-14.34-6.08-3.69-3.03-7.61-7.82-11.77-14.37-5.93-9.28-10.76-19.99-14.47-32.12-3.71-12.13-5.56-23.36-5.56-33.68 0-12.87 3.22-23.47 9.65-31.78 6.44-8.31 14.54-12.63 24.31-12.96 4.92 0 10.35 1.49 16.29 4.46 5.93 2.97 9.77 4.51 11.51 4.62 1.45 0 5.64-1.78 12.56-5.34 6.93-3.56 13.06-5.07 18.39-4.54 13.65 1.1 23.91 6.49 30.78 16.17-12.19 7.39-18.15 17.65-17.88 30.78.27 10.27 4.28 18.82 12.02 25.65 5.46 4.86 11.97 7.79 19.53 8.79-1.57 4.79-3.43 9.69-5.58 14.69zM119.22 31.01c0 8.05-2.94 15.56-8.82 22.53-7.09 8.28-15.65 13.05-24.91 12.3-.19-.96-.29-2.01-.29-3.15 0-7.73 3.25-15.99 9.75-23.23 3.11-3.51 7.06-6.42 11.85-8.73 4.79-2.31 9.33-3.59 13.62-3.84.13 1.42.2 2.79.2 4.12z"/>
</svg>
EOF

sudo cp "$ICON_DIR/apple-logo.svg" /usr/share/pixmaps/apple-logo.svg 2>/dev/null || true

PANEL_CONFIG_DIR="$REAL_HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
PANEL_BACKUP="$REAL_HOME/.config/xfce4/panel_backup_$(date +%F_%H-%M-%S).xml"
[ -f "$PANEL_CONFIG_DIR/xfce4-panel.xml" ] && cp "$PANEL_CONFIG_DIR/xfce4-panel.xml" "$PANEL_BACKUP" 2>/dev/null || true

run_as_user xfce4-panel --quit 2>/dev/null || true
pkill xfce4-panel 2>/dev/null || true
sleep 1

run_as_user xfconf-query -c xfce4-panel -r -R /panels 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -r -R /plugins 2>/dev/null || true

run_as_user xfconf-query -c xfce4-panel -p /panels -n -t int -a -s 0 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/position -n -t string -s "p=6;x=0;y=0" 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/position-locked -n -t bool -s true 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/size -n -t uint -s 28 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/length -n -t uint -s 100 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/autohide-behavior -n -t uint -s 0 2>/dev/null || true

run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/plugin-ids -n \
    -t int -s 1 -t int -s 2 -t int -s 3 -t int -s 4 -t int -s 5 -t int -s 6 2>/dev/null || true

# Plugin 1: Whisker Menu con Logo de Apple
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-1 -n -t string -s "whiskermenu" 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-1/button-icon -n -t string -s "/usr/share/pixmaps/apple-logo.svg" 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-1/show-button-title -n -t bool -s false 2>/dev/null || true

mkdir -p "$REAL_HOME/.config/xfce4/panel"
cat > "$REAL_HOME/.config/xfce4/panel/whiskermenu-1.rc" << 'EOF'
button-icon=/usr/share/pixmaps/apple-logo.svg
button-single-row=false
show-button-title=false
show-button-icon=true
EOF

# Plugin 2: Separador expansible
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-2 -n -t string -s "separator" 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-2/expand -n -t bool -s true 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-2/style -n -t uint -s 0 2>/dev/null || true

# Plugin 3: Bandeja del sistema (Systray)
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-3 -n -t string -s "systray" 2>/dev/null || true

# Plugin 4: Audio (PulseAudio)
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-4 -n -t string -s "pulseaudio" 2>/dev/null || true

# Plugin 5: Energía
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-5 -n -t string -s "power-manager-plugin" 2>/dev/null || true

# Plugin 6: Reloj estilo macOS
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-6 -n -t string -s "clock" 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-6/digital-format -n -t string -s "%a %d %b  %H:%M" 2>/dev/null || true

echo -e "${GREEN}   ✓ Panel superior reconstruido con logo de Apple${NC}"

# =============================================================================
# PASO 5: PLYMOUTH (PANTALLA DE ARRANQUE CON LOGO APPLE)
# =============================================================================
echo -e "\n${YELLOW}🖥️  [5/12] Instalando pantalla de arranque Apple Mac Plymouth...${NC}"

if [ ! -d "$WORKDIR/apple-mac-plymouth" ]; then
    git clone --depth=1 https://github.com/navisjayaseelan/apple-mac-plymouth.git "$WORKDIR/apple-mac-plymouth" -q 2>/dev/null || true
fi

if [ -d "$WORKDIR/apple-mac-plymouth/apple-mac-plymouth" ]; then
    sudo mkdir -p /usr/share/plymouth/themes
    sudo cp -r "$WORKDIR/apple-mac-plymouth/apple-mac-plymouth" /usr/share/plymouth/themes/ 2>/dev/null || true
    sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/apple-mac-plymouth/apple-mac-plymouth.plymouth 100 2>/dev/null || true
    sudo update-alternatives --set default.plymouth /usr/share/plymouth/themes/apple-mac-plymouth/apple-mac-plymouth.plymouth 2>/dev/null || true
    command -v update-initramfs &>/dev/null && sudo update-initramfs -u >/dev/null 2>&1 || true
    echo -e "${GREEN}   ✓ Tema Apple Mac Plymouth instalado y activado en initramfs${NC}"
else
    echo -e "${RED}   ⚠️ No se pudo clonar el repositorio de Plymouth${NC}"
fi

# =============================================================================
# PASO 6: DESCARGA E INSTALACIÓN REAL DE APPS (LOCALSEND, ZUNO, IPTVNATOR, OFFICE)
# =============================================================================
echo -e "\n${YELLOW}🎵 [6/12] Descargando e instalando LocalSend, Apple TV, Apple Music, Office y Safari...${NC}"

APP_ICON_DIR="$REAL_HOME/.local/share/icons/hicolor/256x256/apps"
SCALABLE_APP_DIR="$REAL_HOME/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$APP_ICON_DIR" "$SCALABLE_APP_DIR"

# 1. Generar SVGs vectoriales a prueba de fallos
cat > "$APP_ICON_DIR/applemusic.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><defs><linearGradient id="am" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" stop-color="#FF5E7E"/><stop offset="100%" stop-color="#FF2D55"/></linearGradient></defs><rect width="512" height="512" rx="115" fill="url(#am)"/><path fill="#FFF" d="M368 122c0-10.5-9.2-18.3-19.6-16.3l-152 29c-8.3 1.6-14.4 8.9-14.4 17.4v185.3c-10.2-6.8-23.3-10.4-37.3-9.1-27.1 2.5-48.7 23.6-50.5 50.1-2.1 31.2 22.8 56.6 53.8 56.6 29.8 0 54-23.7 54-53.5V212l134-25.6v118c-10.2-6.8-23.3-10.4-37.3-9.1-27.1 2.5-48.7 23.6-50.5 50.1-2.1 31.2 22.8 56.6 53.8 56.6 29.8 0 54-23.7 54-53.5V122z"/></svg>
EOF

cat > "$APP_ICON_DIR/appletv.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><defs><linearGradient id="atv" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" stop-color="#2C2C2E"/><stop offset="100%" stop-color="#000000"/></linearGradient></defs><rect width="512" height="512" rx="115" fill="url(#atv)"/><path fill="#FFF" d="M168.5 190c-12 21-29 20-29 20s-2-15 9-29c10-13 26-14 26-14s3 11-6 23zm-6.5 29c14 0 20 9 30 9s18-9 31-9c12 0 25 7 32 18-28 16-23 53 5 64-7 17-16 33-28 45-11 11-18 11-28 4-11-6-21-6-32 0-10 6-18 6-28-4-16-16-29-46-29-73 0-32 21-54 47-54zm95-14h28v26h23v21h-23v55c0 11 5 16 15 16 4 0 8-1 8-1v21s-6 2-15 2c-22 0-36-12-36-35v-58h-16v-21h16v-26zm62 26h29l23 82h1l23-82h28l-37 110h-30l-37-110z"/></svg>
EOF

cat > "$APP_ICON_DIR/office.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><defs><linearGradient id="off" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stop-color="#FF6A00"/><stop offset="100%" stop-color="#D83B01"/></linearGradient></defs><rect width="512" height="512" rx="115" fill="url(#off)"/><path fill="#FFF" d="M148 156l142-48 82 26v244l-82 24-142-50 142 18V168l-92 22v138l-50 28V156z"/></svg>
EOF

cat > "$APP_ICON_DIR/safari.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><defs><linearGradient id="saf" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" stop-color="#1E90FF"/><stop offset="100%" stop-color="#0066CC"/></linearGradient></defs><rect width="512" height="512" rx="115" fill="#FFF"/><circle cx="256" cy="256" r="210" fill="url(#saf)"/><polygon points="256,256 365,147 285,285" fill="#FF3B30"/><polygon points="256,256 147,365 227,227" fill="#FFF"/></svg>
EOF

cat > "$APP_ICON_DIR/localsend.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><rect width="512" height="512" rx="115" fill="#008080"/><circle cx="256" cy="256" r="150" fill="none" stroke="#FFF" stroke-width="28"/><circle cx="256" cy="256" r="85" fill="none" stroke="#FFF" stroke-width="28"/><circle cx="256" cy="256" r="32" fill="#FFF"/></svg>
EOF

cp "$APP_ICON_DIR"/*.svg "$SCALABLE_APP_DIR/" 2>/dev/null || true

# 2. Descargar e instalar LocalSend (AppImage + Firewall UFW)
echo -e "${BLUE}   ⬇️  Descargando LocalSend...${NC}"
if [ ! -s "$REAL_HOME/.local/bin/localsend" ]; then
    LOCALSEND_URL=$(curl -sL https://api.github.com/repos/localsend/localsend/releases/latest | grep -o "https://.*linux-x86_64\.AppImage" | head -1)
    [ -z "$LOCALSEND_URL" ] && LOCALSEND_URL="https://github.com/localsend/localsend/releases/download/v1.15.4/LocalSend-1.15.4-linux-x86_64.AppImage"
    curl -sL "$LOCALSEND_URL" -o "$REAL_HOME/.local/bin/localsend" || true
    chmod +x "$REAL_HOME/.local/bin/localsend" 2>/dev/null || true
fi
if command -v ufw &>/dev/null; then
    sudo ufw allow 53317/tcp >/dev/null 2>&1 || true
    sudo ufw allow 53317/udp >/dev/null 2>&1 || true
fi
cat > "$REAL_HOME/.local/share/applications/localsend.desktop" << EOF
[Desktop Entry]
Name=LocalSend (AirDrop)
GenericName=Compartir Archivos
Comment=Alternativa open-source a AirDrop
Exec=$REAL_HOME/.local/bin/localsend --no-sandbox %U
Icon=$APP_ICON_DIR/localsend.svg
Terminal=false
Type=Application
Categories=Network;FileTransfer;
StartupNotify=true
EOF

# 3. Descargar e instalar Apple TV (IPTVnator AppImage + Lista M3U Español)
echo -e "${BLUE}   ⬇️  Descargando Apple TV (IPTVnator)...${NC}"
if [ ! -s "$REAL_HOME/.local/bin/iptvnator" ]; then
    IPTV_URL=$(curl -sL https://api.github.com/repos/4gray/iptvnator/releases/latest | grep -o "https://.*linux-x86_64\.AppImage" | head -1)
    [ -z "$IPTV_URL" ] && IPTV_URL="https://github.com/4gray/iptvnator/releases/download/v0.16.0/iptvnator-0.16.0-linux-x86_64.AppImage"
    curl -sL "$IPTV_URL" -o "$REAL_HOME/.local/bin/iptvnator" || \
    curl -sL "https://github.com/4gray/iptvnator/releases/download/v0.14.0/iptvnator-0.14.0-linux-x86_64.AppImage" -o "$REAL_HOME/.local/bin/iptvnator" || true
    chmod +x "$REAL_HOME/.local/bin/iptvnator" 2>/dev/null || true
fi
mkdir -p "$REAL_HOME/.config/iptvnator"
cat > "$REAL_HOME/.config/iptvnator/store.json" << 'EOF'
{"playlists": [{"id": "spa", "name": "📺 Canales en Español", "url": "https://iptv-org.github.io/iptv/languages/spa.m3u", "autoRefresh": true}], "settings": {"player": "html5", "theme": "dark"}}
EOF
cat > "$REAL_HOME/.local/share/applications/appletv.desktop" << EOF
[Desktop Entry]
Name=Apple TV
GenericName=Reproductor de Video
Comment=Apple TV powered by IPTVnator
Exec=$REAL_HOME/.local/bin/iptvnator --no-sandbox --ozone-platform=x11 %U
Icon=$APP_ICON_DIR/appletv.svg
Terminal=false
Type=Application
Categories=AudioVideo;Video;Player;
StartupNotify=true
EOF

# 4. Descargar e instalar Apple Music (Zuno AppImage)
echo -e "${BLUE}   ⬇️  Descargando Apple Music (Zuno)...${NC}"
if [ ! -s "$REAL_HOME/.local/bin/zuno" ]; then
    curl -sL "https://github.com/noFAYZ/zuno/releases/download/v1.4.0/Zuno_1.4.0_amd64.AppImage" -o "$REAL_HOME/.local/bin/zuno" || \
    curl -sL "https://github.com/noFAYZ/zuno/releases/download/v1.3.2/Zuno_1.3.2_amd64.AppImage" -o "$REAL_HOME/.local/bin/zuno" || true
    chmod +x "$REAL_HOME/.local/bin/zuno" 2>/dev/null || true
fi
cat > "$REAL_HOME/.local/share/applications/applemusic.desktop" << EOF
[Desktop Entry]
Name=Apple Music
GenericName=Reproductor de Música
Comment=Apple Music powered by Zuno
Exec=env WEBKIT_DISABLE_DMABUF_RENDERER=1 $REAL_HOME/.local/bin/zuno --no-sandbox %U
Icon=$APP_ICON_DIR/applemusic.svg
Terminal=false
Type=Application
Categories=Audio;Music;Player;AudioVideo;
StartupNotify=true
EOF

# 5. Instalar Suite Office (ONLYOFFICE Desktop Editors vía Flatpak)
echo -e "${BLUE}   ⬇️  Instalando ONLYOFFICE Desktop Editors (Flatpak)...${NC}"
if command -v flatpak &>/dev/null; then
    sudo flatpak install -y --noninteractive flathub org.onlyoffice.desktopeditors 2>/dev/null || \
    run_as_user flatpak install -y --noninteractive flathub org.onlyoffice.desktopeditors 2>/dev/null || true
fi
cat > "$REAL_HOME/.local/share/applications/office.desktop" << EOF
[Desktop Entry]
Name=Office
GenericName=Suite de Oficina
Comment=ONLYOFFICE Desktop Editors
Exec=flatpak run org.onlyoffice.desktopeditors %U
Icon=$APP_ICON_DIR/office.svg
Terminal=false
Type=Application
Categories=Office;
StartupNotify=true
EOF

# 6. Safari y Finder (Thunar)
cat > "$REAL_HOME/.local/share/applications/safari.desktop" << EOF
[Desktop Entry]
Name=Safari
GenericName=Navegador Web
Comment=Firefox personalizado como Safari
Exec=firefox %u
Icon=$APP_ICON_DIR/safari.svg
Terminal=false
Type=Application
Categories=Network;WebBrowser;
StartupNotify=true
EOF

if [ -f "/usr/share/applications/thunar.desktop" ]; then
    cp "/usr/share/applications/thunar.desktop" "$REAL_HOME/.local/share/applications/finder.desktop"
    sed -i 's/^Name=.*/Name=Finder/g; s/^Icon=.*/Icon=system-file-manager/g' "$REAL_HOME/.local/share/applications/finder.desktop"
fi

chmod +x "$REAL_HOME/.local/share/applications/"*.desktop 2>/dev/null || true
gtk-update-icon-cache -f "$REAL_HOME/.local/share/icons/hicolor" 2>/dev/null || true
run_as_user update-desktop-database "$REAL_HOME/.local/share/applications" 2>/dev/null || true

echo -e "${GREEN}   ✓ LocalSend, Apple TV, Apple Music, Office y Safari instalados${NC}"

# =============================================================================
# PASO 7: WALLPAPERS DINÁMICOS Y MODO OSCURO AUTOMÁTICO
# =============================================================================
echo -e "\n${YELLOW}🌅 [7/12] Instalando Wallpapers Dinámicos y Modo Oscuro Automático...${NC}"

BG_DIR="/usr/share/backgrounds/macos-dynamic"
sudo mkdir -p "$BG_DIR" /usr/share/xfce4/backdrops

if [ ! -s "$BG_DIR/mojave-day.jpg" ]; then
    sudo curl -sL -A "Mozilla/5.0" "https://raw.githubusercontent.com/linuxdotexe/nordic-wallpapers/master/wallpapers/ign_macos.png" -o "$BG_DIR/mojave-day.jpg" || true
fi
if [ ! -s "$BG_DIR/mojave-night.jpg" ]; then
    sudo curl -sL -A "Mozilla/5.0" "https://raw.githubusercontent.com/aynp/dracula-wallpapers/main/os/macos-big-sur-night.jpg" -o "$BG_DIR/mojave-night.jpg" || true
fi

sudo ln -sf "$BG_DIR/mojave-day.jpg" /usr/share/xfce4/backdrops/macos-mojave-day.jpg 2>/dev/null || true
sudo ln -sf "$BG_DIR/mojave-night.jpg" /usr/share/xfce4/backdrops/macos-mojave-night.jpg 2>/dev/null || true

cat > "$REAL_HOME/.local/bin/macos-day-night-xfce" << 'EOF'
#!/usr/bin/env bash
HOUR=$(date +%-H)
if [ "$HOUR" -ge 6 ] && [ "$HOUR" -lt 18 ]; then
    WP="/usr/share/backgrounds/macos-dynamic/mojave-day.jpg"
    THEME_SUFFIX="Light"
else
    WP="/usr/share/backgrounds/macos-dynamic/mojave-night.jpg"
    THEME_SUFFIX="Dark"
fi

if [ -s "$WP" ]; then
    for prop in $(xfconf-query -c xfce4-desktop -p /backdrop -l 2>/dev/null | grep -E "last-image|image-path"); do
        xfconf-query -c xfce4-desktop -p "$prop" -s "$WP" 2>/dev/null || true
    done
fi

for prefix in "MacTahoe" "WhiteSur"; do
    if [ -d "$HOME/.themes/${prefix}-${THEME_SUFFIX}" ] || [ -d "/usr/share/themes/${prefix}-${THEME_SUFFIX}" ]; then
        xfconf-query -c xsettings -p /Net/ThemeName -s "${prefix}-${THEME_SUFFIX}" 2>/dev/null || true
        xfconf-query -c xfwm4 -p /general/theme -s "${prefix}-${THEME_SUFFIX}" 2>/dev/null || true
        break
    fi
done
EOF
chmod +x "$REAL_HOME/.local/bin/macos-day-night-xfce"

cat > "$REAL_HOME/.config/systemd/user/macos-day-night.service" << EOF
[Unit]
Description=Sincronizar Wallpaper y Modo Oscuro XFCE

[Service]
Type=oneshot
ExecStart=$REAL_HOME/.local/bin/macos-day-night-xfce
EOF

cat > "$REAL_HOME/.config/systemd/user/macos-day-night.timer" << 'EOF'
[Unit]
Description=Timer horario Wallpaper XFCE

[Timer]
OnBootSec=1min
OnUnitActiveSec=15min
Persistent=true

[Install]
WantedBy=timers.target
EOF

run_as_user systemctl --user daemon-reload 2>/dev/null || true
run_as_user systemctl --user enable --now macos-day-night.timer 2>/dev/null || true
run_as_user "$REAL_HOME/.local/bin/macos-day-night-xfce" 2>/dev/null || true

echo -e "${GREEN}   ✓ Wallpapers dinámicos activos en XFCE${NC}"

# =============================================================================
# PASO 8: ROFI SPOTLIGHT Y ACERCA DE ESTE MAC
# =============================================================================
echo -e "\n${YELLOW}🔍 [8/12] Configurando Rofi Spotlight y 'Acerca de este Mac'...${NC}"

cat > "$REAL_HOME/.config/rofi/config.rasi" << 'EOF'
configuration {
    modi: "drun,run,filebrowser";
    show-icons: true;
    display-drun: "🔍 Spotlight";
    font: "SF Pro Display 13";
    drun-display-format: "{name}";
}
window { width: 620px; border: 1px; border-color: #ffffff33; border-radius: 14px; background-color: #1e1e1ee6; padding: 16px; }
mainbox { background-color: transparent; }
inputbar { background-color: #2d2d2d; text-color: #ffffff; border-radius: 10px; padding: 10px 14px; children: [ prompt, entry ]; }
prompt { background-color: transparent; text-color: #aaaaaa; margin: 0 10px 0 0; }
entry { background-color: transparent; text-color: #ffffff; placeholder: "Buscar en este Mac..."; }
listview { background-color: transparent; lines: 7; margin: 12px 0 0 0; spacing: 4px; }
element { padding: 8px 12px; border-radius: 8px; background-color: transparent; text-color: #eaeaea; }
element selected { background-color: #0a84ff; text-color: #ffffff; }
element-icon { size: 28px; margin: 0 12px 0 0; background-color: transparent; }
element-text { background-color: transparent; text-color: inherit; vertical-align: 0.5; }
EOF

cat > "$REAL_HOME/.local/bin/about-this-mac" << 'EOF'
#!/usr/bin/env python3
import gi, os, subprocess, platform
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GdkPixbuf

class AboutThisMac(Gtk.Window):
    def __init__(self):
        super().__init__(title="Acerca de este Mac")
        self.set_default_size(340, 420)
        self.set_resizable(False)
        self.set_position(Gtk.WindowPosition.CENTER)

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        vbox.set_margin_top(24); vbox.set_margin_bottom(24)
        vbox.set_margin_start(28); vbox.set_margin_end(28)
        self.add(vbox)

        icon_path = "/usr/share/pixmaps/apple-logo.svg"
        if os.path.exists(icon_path):
            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(icon_path, 72, 72, True)
            vbox.pack_start(Gtk.Image.new_from_pixbuf(pixbuf), False, False, 4)

        title = Gtk.Label()
        title.set_markup("<span size='x-large' weight='bold'>macOS Tahoe</span>")
        vbox.pack_start(title, False, False, 0)

        sub = Gtk.Label(label="Versión 26.0 (XFCE Edition)")
        vbox.pack_start(sub, False, False, 6)

        cpu = subprocess.getoutput("grep -m1 'model name' /proc/cpuinfo | cut -d: -f2").strip() or platform.processor()
        ram = subprocess.getoutput("free -h | awk '/^Mem:/ {print $2}'").strip()
        gpu = subprocess.getoutput("lspci | grep -i 'vga\\|3d' | head -n1 | cut -d: -f3").strip()

        specs = Gtk.Label()
        specs.set_justify(Gtk.Justification.CENTER)
        specs.set_markup(
            f"<b>Equipo:</b> {platform.node()}\n"
            f"<b>Procesador:</b> {cpu[:34]}\n"
            f"<b>Memoria:</b> {ram}\n"
            f"<b>Gráficos:</b> {gpu[:34]}\n"
            f"<b>Kernel:</b> {platform.release()}"
        )
        vbox.pack_start(specs, True, True, 8)

        upd_btn = Gtk.Button(label="Actualización de software...")
        upd_btn.connect("clicked", self.on_update)
        vbox.pack_start(upd_btn, False, False, 4)

    def on_update(self, _widget):
        for cmd in ["mintupdate", "update-manager", "gnome-software"]:
            if subprocess.call(["which", cmd], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) == 0:
                subprocess.Popen([cmd]); return
        subprocess.Popen(["xfce4-terminal", "-e", "bash -c 'sudo apt update && sudo apt upgrade; read -p \"Enter para salir...\"'"])

win = AboutThisMac()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()
EOF
chmod +x "$REAL_HOME/.local/bin/about-this-mac"
sudo ln -sf "$REAL_HOME/.local/bin/about-this-mac" /usr/local/bin/about-this-mac 2>/dev/null || true

echo -e "${GREEN}   ✓ Rofi Spotlight y 'Acerca de este Mac' listos${NC}"

# =============================================================================
# PASO 9: CAMBIO DE HOSTNAME INCONDICIONAL Y SONIDOS BIG SUR
# =============================================================================
echo -e "\n${YELLOW}💻 [9/12] Configurando identidad del equipo (Hostname) y sonidos Big Sur...${NC}"

NEW_HOSTNAME="MacBook-Neo"
CURRENT_HOSTNAME=$(hostname 2>/dev/null || cat /etc/hostname)

if [ "$CURRENT_HOSTNAME" != "$NEW_HOSTNAME" ]; then
    sudo hostnamectl set-hostname "$NEW_HOSTNAME" 2>/dev/null || true
    echo "$NEW_HOSTNAME" | sudo tee /etc/hostname > /dev/null 2>/dev/null || true
    sudo sed -i "s/127\.0\.1\.1.*/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts 2>/dev/null || true
    grep -q "127.0.1.1" /etc/hosts 2>/dev/null || echo -e "127.0.1.1\t$NEW_HOSTNAME" | sudo tee -a /etc/hosts > /dev/null 2>/dev/null || true
fi
echo -e "${GREEN}   ✓ Nombre del host actualizado a: $NEW_HOSTNAME${NC}"

# Sonidos macOS Big Sur
SOUNDS_DIR="$REAL_HOME/.local/share/sounds"
if [ ! -d "$SOUNDS_DIR/bigsur" ]; then
    ZIP_URL="https://github.com/gxanshu/macos-bigsur-sound-theme-linux/archive/refs/heads/main.zip"
    if curl -sL "$ZIP_URL" --max-time 60 -o "/tmp/bigsur.zip" 2>/dev/null && [ -s "/tmp/bigsur.zip" ]; then
        unzip -q -o "/tmp/bigsur.zip" -d "/tmp/bigsur-extract" 2>/dev/null || true
        [ -d "/tmp/bigsur-extract/macos-bigsur-sound-theme-linux-main/theme/bigsur" ] && \
            cp -r "/tmp/bigsur-extract/macos-bigsur-sound-theme-linux-main/theme/bigsur" "$SOUNDS_DIR/" 2>/dev/null || true
        rm -rf "/tmp/bigsur.zip" "/tmp/bigsur-extract"
    fi
fi
run_as_user xfconf-query -c xsettings -p /Net/SoundThemeName -n -t string -s "bigsur" 2>/dev/null || true

cat > "$REAL_HOME/.config/autostart/macos-startup-chime.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=macOS Startup Chime
Exec=sh -c "paplay /usr/share/sounds/freedesktop/stereo/service-login.oga 2>/dev/null || true"
X-GNOME-Autostart-enabled=true
EOF

# =============================================================================
# PASO 10: THUNAR, TERMINAL, SCROLL NATURAL Y ATAJOS DE TECLADO
# =============================================================================
echo -e "\n${YELLOW}⌨️  [10/12] Configurando Thunar, Terminal, Scroll Natural y Atajos macOS...${NC}"

run_as_user xfconf-query -c thunar -p /misc-default-view -n -t string -s "THUNAR_VIEW_ICON" 2>/dev/null || true
run_as_user xfconf-query -c thunar -p /misc-single-click -n -t bool -s false 2>/dev/null || true

for dev in $(xinput list --id-only 'Touchpad' 'touchpad' 2>/dev/null); do
    xinput set-prop "$dev" "libinput Tapping Enabled" 1 2>/dev/null || true
    xinput set-prop "$dev" "libinput Natural Scrolling Enabled" 1 2>/dev/null || true
done

mkdir -p "$REAL_HOME/.config/xfce4/terminal"
cat > "$REAL_HOME/.config/xfce4/terminal/terminalrc" << 'EOF'
[Configuration]
FontName=SF Mono Regular 12
ColorForeground=#e6e6e6
ColorBackground=#1e1e1e
ColorBold=#ffffff
MiscCursorShape=TERMINAL_CURSOR_SHAPE_IBEAM
MiscCursorBlinks=FALSE
EOF

cat > "$REAL_HOME/.config/gtk-3.0/bookmarks" << EOF
file://$REAL_HOME/Desktop Desktop
file://$REAL_HOME/Documents Documents
file://$REAL_HOME/Downloads Downloads
file://$REAL_HOME/Music Music
file://$REAL_HOME/Pictures Pictures
file://$REAL_HOME/Videos Movies
EOF

# Scripts auxiliares de ventanas
cat > "$REAL_HOME/.local/bin/macos-center-window" << 'EOF'
#!/usr/bin/env bash
WIN_ID=$(xdotool getactivewindow 2>/dev/null)
[ -z "$WIN_ID" ] && exit 0
eval "$(xdotool getwindowgeometry --shell "$WIN_ID")"
SCREEN_W=$(xdpyinfo | awk '/dimensions:/ {split($2,a,"x"); print a[1]}')
SCREEN_H=$(xdpyinfo | awk '/dimensions:/ {split($2,a,"x"); print a[2]}')
NEW_X=$(( (SCREEN_W - WIDTH) / 2 ))
NEW_Y=$(( (SCREEN_H - HEIGHT) / 2 ))
wmctrl -i -r "$WIN_ID" -b remove,maximized_vert,maximized_horz
xdotool windowmove "$WIN_ID" "$NEW_X" "$NEW_Y"
EOF

cat > "$REAL_HOME/.local/bin/macos-spotlight" << 'EOF'
#!/usr/bin/env bash
if command -v rofi >/dev/null 2>&1; then
    rofi -show drun
else
    xfce4-popup-whiskermenu
fi
EOF

cat > "$REAL_HOME/.local/bin/macos-quit-app" << 'EOF'
#!/usr/bin/env bash
WIN_ID=$(xdotool getactivewindow 2>/dev/null)
[ -z "$WIN_ID" ] && exit 0
WIN_PID=$(xdotool getwindowpid "$WIN_ID" 2>/dev/null)
wmctrl -ic "$WIN_ID"
if [ -n "$WIN_PID" ] && [ "$WIN_PID" -gt 100 ]; then
    sleep 0.3
    kill -15 "$WIN_PID" 2>/dev/null || true
fi
EOF

chmod +x "$REAL_HOME/.local/bin/macos-"*

# Atajos de aplicaciones y comandos
xfce_set_keybinding "$REAL_HOME/.local/bin/macos-spotlight" "<Primary>space"
xfce_set_keybinding "$REAL_HOME/.local/bin/about-this-mac" "<Super>i"
xfce_set_keybinding "$REAL_HOME/.local/bin/macos-center-window" "<Super>c"
xfce_set_keybinding "$REAL_HOME/.local/bin/macos-quit-app" "<Super>q"
xfce_set_keybinding "xfce4-popup-whiskermenu" "Super_L"
xfce_set_keybinding "exo-open --launch FileManager" "<Super>e"
xfce_set_keybinding "xfce4-terminal" "<Primary><Alt>t"
xfce_set_keybinding "xkill" "<Primary><Alt>Escape"
xfce_set_keybinding "light-locker-command -l" "<Super>l"

# Atajos de ventanas (XFWM4)
for pair in \
    "<Super>m:hide_window_key" \
    "<Super>Up:maximize_window_key" \
    "<Super>d:show_desktop_key" \
    "<Super>1:workspace_1_key" \
    "<Super>2:workspace_2_key" \
    "<Super>3:workspace_3_key" \
    "<Primary><Alt>Left:left_workspace_key" \
    "<Primary><Alt>Right:right_workspace_key"; do
    KEY="${pair%%:*}"
    VAL="${pair##*:}"
    run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/$KEY" -n -t string -s "$VAL" 2>/dev/null || \
    run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/$KEY" -s "$VAL" 2>/dev/null || true
done

echo -e "${GREEN}   ✓ Atajos de teclado configurados${NC}"

# =============================================================================
# PASO 11: GESTOS FUSUMA Y PERMISOS FINALES
# =============================================================================
echo -e "\n${YELLOW}🔒 [11/12] Configurando Gestos Fusuma y permisos finales...${NC}"

if ! groups "$REAL_USER" | grep -q '\binput\b'; then
    sudo usermod -aG input "$REAL_USER" 2>/dev/null || true
fi

mkdir -p "$REAL_HOME/.config/fusuma"
cat > "$REAL_HOME/.config/fusuma/config.yml" << 'EOF'
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
EOF

sudo chown -R "$REAL_USER:$REAL_GID" "$REAL_HOME/.local" "$REAL_HOME/.config" "$WORKDIR" 2>/dev/null || true

# =============================================================================
# PASO 12: RECARGA EN VIVO DE XFWM4, PANEL Y PLANK DOCK
# =============================================================================
echo -e "\n${YELLOW}🔄 [12/12] Recargando XFWM4, Panel Superior y lanzando Plank Dock...${NC}"

# Recargar orden de botones CHM| y tema en XFWM4
run_as_user xfconf-query -c xfwm4 -p /general/button_layout -s "CHM|" 2>/dev/null || true
if command -v xfwm4 &>/dev/null; then
    run_as_user xfwm4 --replace >/dev/null 2>&1 &
fi

# Reiniciar panel superior de XFCE
run_as_user xfce4-panel -r >/dev/null 2>&1 || run_as_user xfce4-panel >/dev/null 2>&1 &

# Lanzar Plank Dock inmediatamente en la sesión actual
pkill plank 2>/dev/null || true
sleep 1
if command -v plank &>/dev/null; then
    run_as_user nohup plank >/dev/null 2>&1 &
fi

echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         ✅ INSTALACIÓN XFCE COMPLETADA CON ÉXITO                 ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}✨ Correcciones aplicadas en este MacFCE.sh:${NC}"
echo -e "   • ${YELLOW}Botones de ventana:${NC} Ordenados a la izquierda con sintaxis XFWM4 'CHM|' (Cerrar, Minimizar, Maximizar)."
echo -e "   • ${YELLOW}Hostname:${NC} Cambiado directamente a 'MacBook-Neo' en /etc/hostname y /etc/hosts."
echo -e "   • ${YELLOW}Plank Dock:${NC} Instalado, configurado en dconf y ejecutándose en la parte inferior."
echo -e "   • ${YELLOW}Plymouth:${NC} Tema Apple Mac Plymouth clonado y activado en initramfs."
echo -e "   • ${YELLOW}Apps instaladas:${NC} LocalSend (.AppImage), Apple TV / IPTVnator (.AppImage + canales), Apple Music / Zuno (.AppImage) y Office / ONLYOFFICE (Flatpak).\n"
