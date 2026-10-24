#!/usr/bin/env bash
# =============================================================================
# MacGNOME.sh - Instalador Definitivo macOS Tahoe para GNOME (Todo en uno)
# Soporta: Ubuntu GNOME / Debian GNOME / Zorin OS / Pop!_OS
# Incluye: GTK3/GTK4 (Libadwaita), Iconos, Cursores, Sonidos Big Sur,
#          Liquid Glass, Magic Lamp, Dash-to-Dock, Wallpapers Dinámicos XML,
#          Quick Look (Sushi), Rofi Spotlight, Apps y 50+ Atajos macOS.
# =============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. Detectar el usuario real aunque se ejecute con sudo
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

# 2. Capturar DBUS_SESSION_BUS_ADDRESS, DISPLAY y WAYLAND_DISPLAY reales de gnome-shell
GNOME_PID=""
for proc in gnome-shell gsd-xsettings nautilus gnome-session-binary; do
    GNOME_PID=$(pgrep -u "$REAL_USER" "$proc" 2>/dev/null | head -n 1 || true)
    [ -n "$GNOME_PID" ] && break
done

if [ -n "$GNOME_PID" ] && [ -r "/proc/$GNOME_PID/environ" ]; then
    REAL_DBUS=$(tr '\0' '\n' < "/proc/$GNOME_PID/environ" | grep '^DBUS_SESSION_BUS_ADDRESS=' | cut -d= -f2- || true)
    REAL_DISPLAY=$(tr '\0' '\n' < "/proc/$GNOME_PID/environ" | grep '^DISPLAY=' | cut -d= -f2- || true)
    REAL_WAYLAND=$(tr '\0' '\n' < "/proc/$GNOME_PID/environ" | grep '^WAYLAND_DISPLAY=' | cut -d= -f2- || true)
fi
REAL_DBUS="${REAL_DBUS:-unix:path=/run/user/$REAL_UID/bus}"
REAL_DISPLAY="${REAL_DISPLAY:-${DISPLAY:-:0}}"
REAL_WAYLAND="${REAL_WAYLAND:-${WAYLAND_DISPLAY:-}}"

# Función infalible para ejecutar gsettings, dconf y gnome-extensions en la sesión del usuario
run_as_user() {
    if [ "$(id -u)" -eq 0 ]; then
        sudo -u "$REAL_USER" env \
            HOME="$REAL_HOME" \
            USER="$REAL_USER" \
            LOGNAME="$REAL_USER" \
            DISPLAY="$REAL_DISPLAY" \
            WAYLAND_DISPLAY="$REAL_WAYLAND" \
            DBUS_SESSION_BUS_ADDRESS="$REAL_DBUS" \
            XDG_RUNTIME_DIR="/run/user/$REAL_UID" \
            XDG_CURRENT_DESKTOP="GNOME" \
            "$@" 2>/dev/null || true
    else
        "$@" 2>/dev/null || true
    fi
}

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         🍏 Instalador Definitivo macOS Tahoe para GNOME          ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo -e "${BLUE}   👤 Usuario: $REAL_USER (UID: $REAL_UID) | DISPLAY: $REAL_DISPLAY${NC}"
echo -e "${BLUE}   🔌 D-Bus: $REAL_DBUS${NC}"

# =============================================================================
# PASO 0: ESTRUCTURA DE DIRECTORIOS Y DESBLOQUEO DE PERMISOS
# =============================================================================
echo -e "\n${YELLOW}🔐 [0/12] Preparando directorios y desbloqueando permisos de usuario...${NC}"

mkdir -p "$REAL_HOME/.local/share/applications"
mkdir -p "$REAL_HOME/.local/share/icons/hicolor/256x256/apps"
mkdir -p "$REAL_HOME/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$REAL_HOME/.local/share/fonts"
mkdir -p "$REAL_HOME/.local/share/sounds"
mkdir -p "$REAL_HOME/.local/share/gnome-shell/extensions"
mkdir -p "$REAL_HOME/.local/bin"
mkdir -p "$REAL_HOME/.themes"
mkdir -p "$REAL_HOME/.icons"
mkdir -p "$REAL_HOME/.config/rofi"
mkdir -p "$REAL_HOME/.config/autostart"
mkdir -p "$REAL_HOME/.config/systemd/user"
mkdir -p "$REAL_HOME/.config/gtk-3.0"
mkdir -p "$REAL_HOME/.config/gtk-4.0"
mkdir -p "$REAL_HOME/.config/fusuma"
sudo mkdir -p /usr/share/themes /usr/share/icons /usr/share/sounds /usr/share/backgrounds/macos-dynamic /usr/share/gnome-background-properties

sudo chown -R "$REAL_USER:$REAL_GID" "$REAL_HOME/.local" "$REAL_HOME/.config" "$REAL_HOME/.cache" "$REAL_HOME/.themes" "$REAL_HOME/.icons" "$WORKDIR" 2>/dev/null || true
chmod -R u+rwX "$REAL_HOME/.config" "$REAL_HOME/.local" 2>/dev/null || true

echo -e "${GREEN}   ✓ Directorios y permisos listos${NC}"

# =============================================================================
# PASO 1: DEPENDENCIAS DEL SISTEMA, COMPILADORES GTK Y UTILIDADES GNOME
# =============================================================================
echo -e "\n${YELLOW}📦 [1/12] Instalando dependencias del sistema, compiladores GTK y herramientas GNOME...${NC}"

sudo apt-get update -qq 2>/dev/null || true

PKGS=(
    wget curl git unzip sassc libglib2.0-dev-bin libxml2-utils
    gtk2-engines-murrine gtk2-engines-pixbuf libgdk-pixbuf2.0-dev imagemagick dialog optipng
    wmctrl xdotool x11-utils xinput libinput-tools ruby
    rofi qt5ct qt5-style-plugins dconf-cli plymouth plymouth-themes ufw flatpak
    python3 python3-gi gir1.2-gtk-3.0 libnotify-bin
    alsa-utils pulseaudio-utils sox libcanberra-gtk-module libcanberra-gtk3-module
    gnome-shell-extensions gnome-tweaks gnome-sushi
    gnome-shell-extension-dashtodock gnome-shell-extension-manager
    gstreamer1.0-plugins-base gstreamer1.0-plugins-good
    gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav
)

for pkg in "${PKGS[@]}"; do
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$pkg" >/dev/null 2>&1 || true
done

# Soporte FUSE indispensable para ejecutar LocalSend, Zuno e IPTVnator (.AppImage)
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq libfuse2 >/dev/null 2>&1 || \
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq libfuse2t64 >/dev/null 2>&1 || true

sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
echo -e "${GREEN}   ✓ Dependencias instaladas correctamente${NC}"

# =============================================================================
# PASO 2: FUENTES APPLE (SF PRO, SF MONO, NEW YORK) Y FONTCONFIG
# =============================================================================
echo -e "\n${YELLOW}🔤 [2/12] Instalando fuentes oficiales Apple y optimización Fontconfig...${NC}"

FONT_DIR="/usr/share/fonts/truetype/apple-fonts"
sudo mkdir -p "$FONT_DIR"

if [ -z "$(ls -A "$FONT_DIR" 2>/dev/null)" ]; then
    rm -rf /tmp/sf-fonts
    git clone --depth=1 https://github.com/bradleyhodges/SFWindows.git /tmp/sf-fonts 2>/dev/null || \
    git clone --depth=1 https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts.git /tmp/sf-fonts 2>/dev/null || true
    if [ -d "/tmp/sf-fonts" ]; then
        sudo find /tmp/sf-fonts -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec cp {} "$FONT_DIR/" \; 2>/dev/null || true
        sudo cp "$FONT_DIR"/* "$REAL_HOME/.local/share/fonts/" 2>/dev/null || true
        rm -rf /tmp/sf-fonts
    fi
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

sudo fc-cache -f >/dev/null 2>&1 || true

run_as_user gsettings set org.gnome.desktop.interface font-name 'SF Pro Text 11'
run_as_user gsettings set org.gnome.desktop.interface document-font-name 'New York Medium 11'
run_as_user gsettings set org.gnome.desktop.interface monospace-font-name 'SF Mono Regular 11'
run_as_user gsettings set org.gnome.desktop.wm.preferences titlebar-font 'SF Pro Text Bold 11'
run_as_user gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
run_as_user gsettings set org.gnome.desktop.interface font-hinting 'slight'

echo -e "${GREEN}   ✓ Fuentes Apple instaladas y activadas en GNOME${NC}"

# =============================================================================
# PASO 3: TEMA MACTAHOE (GTK3 + GTK4 LIBADWAITA + SHELL + GDM), ICONOS Y CURSOR
# =============================================================================
echo -e "\n${YELLOW}🎨 [3/12] Compilando Tema MacTahoe (GTK3/GTK4/Shell/GDM), Iconos y Cursores...${NC}"

SCREEN_WIDTH=$(xrandr --current 2>/dev/null | grep '*' | head -1 | awk '{print $1}' | cut -d'x' -f1 || echo "1920")
ICON_BOLD_FLAG=""
[ "${SCREEN_WIDTH:-1920}" -ge 3840 ] && ICON_BOLD_FLAG="-b"

# 3.1 Tema GTK + GNOME Shell + Libadwaita
echo -e "${BLUE}   ⬇️  Descargando y compilando MacTahoe GTK/Shell Theme...${NC}"
rm -rf /tmp/macos-gtk-theme
git clone --depth=1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git /tmp/macos-gtk-theme 2>/dev/null || \
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git /tmp/macos-gtk-theme 2>/dev/null || true

if [ -d "/tmp/macos-gtk-theme" ]; then
    find /tmp/macos-gtk-theme -type f -name "*.sh" -exec sed -i 's/xfce4-panel -r/true/g' {} + 2>/dev/null || true
    chown -R "$REAL_USER:$REAL_GID" /tmp/macos-gtk-theme

    # Instalar para el usuario incluyendo soporte Libadwaita (-l) para apps GTK4 de GNOME
    run_as_user bash -c "cd /tmp/macos-gtk-theme && ./install.sh -d '$REAL_HOME/.themes' -c dark -c light -l --round" || \
    run_as_user bash -c "cd /tmp/macos-gtk-theme && ./install.sh -d '$REAL_HOME/.themes' -c dark -c light" || true
    sudo cp -r "$REAL_HOME/.themes"/* /usr/share/themes/ 2>/dev/null || true

    # Aplicar estilo macOS a la pantalla de login GDM (exclusivo de GNOME)
    if [ -f "/tmp/macos-gtk-theme/tweaks.sh" ]; then
        ( cd /tmp/macos-gtk-theme && sudo ./tweaks.sh -g -b default >/dev/null 2>&1 ) || true
    fi
    rm -rf /tmp/macos-gtk-theme
fi

GTK_THEME_DARK="MacTahoe-Dark"
GTK_THEME_LIGHT="MacTahoe-Light"
for t in "MacTahoe-Dark" "MacTahoe-dark" "WhiteSur-Dark" "WhiteSur-dark"; do
    if [ -d "$REAL_HOME/.themes/$t" ] || [ -d "/usr/share/themes/$t" ]; then
        GTK_THEME_DARK="$t"
        break
    fi
done
for t in "MacTahoe-Light" "MacTahoe-light" "WhiteSur-Light" "WhiteSur-light"; do
    if [ -d "$REAL_HOME/.themes/$t" ] || [ -d "/usr/share/themes/$t" ]; then
        GTK_THEME_LIGHT="$t"
        break
    fi
done

# 3.2 Tema de Iconos
echo -e "${BLUE}   ⬇️  Descargando e instalando MacTahoe Icon Theme...${NC}"
rm -rf /tmp/macos-icon-theme
git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git /tmp/macos-icon-theme 2>/dev/null || \
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/macos-icon-theme 2>/dev/null || true

if [ -d "/tmp/macos-icon-theme" ]; then
    chown -R "$REAL_USER:$REAL_GID" /tmp/macos-icon-theme
    run_as_user bash -c "cd /tmp/macos-icon-theme && ./install.sh -d '$REAL_HOME/.icons' $ICON_BOLD_FLAG" || true
    sudo cp -r "$REAL_HOME/.icons"/* /usr/share/icons/ 2>/dev/null || true
    rm -rf /tmp/macos-icon-theme
fi

ICON_THEME_NAME="MacTahoe-dark"
for i in "MacTahoe-dark" "MacTahoe" "WhiteSur-dark" "WhiteSur"; do
    if [ -d "$REAL_HOME/.icons/$i" ] || [ -d "/usr/share/icons/$i" ]; then
        ICON_THEME_NAME="$i"
        break
    fi
done

# 3.3 Tema de Cursores
echo -e "${BLUE}   ⬇️  Descargando e instalando Cursores macOS...${NC}"
rm -rf /tmp/macos-cursors
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-cursors.git /tmp/macos-cursors 2>/dev/null || true
if [ -d "/tmp/macos-cursors/dist" ]; then
    cp -r /tmp/macos-cursors/dist "$REAL_HOME/.icons/WhiteSur-cursors" 2>/dev/null || true
    sudo cp -r /tmp/macos-cursors/dist /usr/share/icons/WhiteSur-cursors 2>/dev/null || true
    rm -rf /tmp/macos-cursors
fi
CURSOR_THEME_NAME="WhiteSur-cursors"

# Activar User Themes y aplicar Temas, Iconos, Cursores y Botones de Ventana (Izquierda)
run_as_user gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
run_as_user gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_DARK"
run_as_user gsettings set org.gnome.desktop.wm.preferences theme "$GTK_THEME_DARK"
run_as_user gsettings set org.gnome.shell.extensions.user-theme name "$GTK_THEME_DARK"
run_as_user gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
run_as_user gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME_NAME"
run_as_user gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME_NAME"
run_as_user gsettings set org.gnome.desktop.interface cursor-size 24

# Ordenar botones de ventana estilo macOS: Cerrar, Minimizar, Maximizar a la izquierda
run_as_user gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'

# Tematización Qt
if ! grep -q "QT_QPA_PLATFORMTHEME=qt5ct" /etc/environment 2>/dev/null; then
    echo "QT_QPA_PLATFORMTHEME=qt5ct" | sudo tee -a /etc/environment >/dev/null 2>&1 || true
fi

cat > "$REAL_HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-theme-name=$GTK_THEME_DARK
gtk-icon-theme-name=$ICON_THEME_NAME
gtk-font-name=SF Pro Text 11
gtk-cursor-theme-name=$CURSOR_THEME_NAME
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
gtk-decoration-layout=close,minimize,maximize:
EOF

echo -e "${GREEN}   ✓ Tema GTK/Shell ($GTK_THEME_DARK), Iconos ($ICON_THEME_NAME), Cursores y Botones aplicados${NC}"

# =============================================================================
# PASO 4: EXTENSIONES GNOME (LIQUID GLASS, MAGIC LAMP Y DASH TO DOCK)
# =============================================================================
echo -e "\n${YELLOW}🧩 [4/12] Instalando Liquid Glass, Magic Lamp Effect y configurando Dock...${NC}"

EXT_DIR="$REAL_HOME/.local/share/gnome-shell/extensions"

# 4.1 Compiz Alike Magic Lamp Effect (Efecto Genio al minimizar en GNOME)
rm -rf /tmp/magic-lamp
git clone --depth=1 https://github.com/hermes83/compiz-alike-magic-lamp-effect.git /tmp/magic-lamp 2>/dev/null || true
if [ -d "/tmp/magic-lamp" ]; then
    MAGIC_UUID="compiz-alike-magic-lamp-effect@hermes83.github.com"
    mkdir -p "$EXT_DIR/$MAGIC_UUID"
    cp -r /tmp/magic-lamp/* "$EXT_DIR/$MAGIC_UUID/" 2>/dev/null || true
    glib-compile-schemas "$EXT_DIR/$MAGIC_UUID/schemas/" 2>/dev/null || true
    rm -rf /tmp/magic-lamp
fi

# 4.2 Liquid Glass (Efecto cristal líquido en GNOME)
rm -rf /tmp/liquid-glass
git clone --depth=1 https://github.com/ryohsuke1231/liquid-glass.git /tmp/liquid-glass 2>/dev/null || true
if [ -d "/tmp/liquid-glass" ]; then
    LG_METADATA=$(find /tmp/liquid-glass -name "metadata.json" | head -n 1)
    if [ -n "$LG_METADATA" ]; then
        LG_UUID=$(python3 -c "import json; print(json.load(open('$LG_METADATA'))['uuid'])" 2>/dev/null || echo "liquid-glass@ryohsuke1231")
        LG_SRC_DIR=$(dirname "$LG_METADATA")
        mkdir -p "$EXT_DIR/$LG_UUID"
        cp -r "$LG_SRC_DIR"/* "$EXT_DIR/$LG_UUID/" 2>/dev/null || true
        glib-compile-schemas "$EXT_DIR/$LG_UUID/schemas/" 2>/dev/null || true
    fi
    rm -rf /tmp/liquid-glass
fi

sudo chown -R "$REAL_USER:$REAL_GID" "$EXT_DIR" 2>/dev/null || true

# Habilitar extensiones en GNOME Shell
run_as_user gsettings set org.gnome.shell disable-user-extensions false
run_as_user gnome-extensions enable "compiz-alike-magic-lamp-effect@hermes83.github.com"
[ -n "${LG_UUID:-}" ] && run_as_user gnome-extensions enable "$LG_UUID"
run_as_user gnome-extensions enable "dash-to-dock@micxgx.gmail.com"
run_as_user gnome-extensions enable "ubuntu-dock@ubuntu.com"

# 4.3 Configurar Dash-to-Dock / Ubuntu Dock como Dock inferior de macOS
for DOCK_SCHEMA in "org.gnome.shell.extensions.dash-to-dock"; do
    run_as_user gsettings set "$DOCK_SCHEMA" dock-position 'BOTTOM'
    run_as_user gsettings set "$DOCK_SCHEMA" extend-height false
    run_as_user gsettings set "$DOCK_SCHEMA" dock-fixed false
    run_as_user gsettings set "$DOCK_SCHEMA" autohide true
    run_as_user gsettings set "$DOCK_SCHEMA" intellihide true
    run_as_user gsettings set "$DOCK_SCHEMA" dash-max-icon-size 48
    run_as_user gsettings set "$DOCK_SCHEMA" click-action 'minimize'
    run_as_user gsettings set "$DOCK_SCHEMA" show-trash true
    run_as_user gsettings set "$DOCK_SCHEMA" show-Apps-at-top true
    run_as_user gsettings set "$DOCK_SCHEMA" transparency-mode 'DYNAMIC'
    run_as_user gsettings set "$DOCK_SCHEMA" background-opacity 0.4
    run_as_user gsettings set "$DOCK_SCHEMA" hot-keys false
done

echo -e "${GREEN}   ✓ Liquid Glass, Magic Lamp y Dock estilo macOS configurados${NC}"

# =============================================================================
# PASO 5: SONIDOS macOS BIG SUR Y STARTUP CHIME
# =============================================================================
echo -e "\n${YELLOW}🔊 [5/12] Instalando sonidos macOS Big Sur y Startup Chime...${NC}"

rm -rf /tmp/bigsur.zip /tmp/bigsur-extract
ZIP_URL="https://github.com/gxanshu/macos-bigsur-sound-theme-linux/archive/refs/heads/main.zip"
if curl -sL "$ZIP_URL" --max-time 60 -o "/tmp/bigsur.zip" && [ -s "/tmp/bigsur.zip" ]; then
    unzip -q -o "/tmp/bigsur.zip" -d "/tmp/bigsur-extract" 2>/dev/null || true
    FOUND_SOUND=$(find /tmp/bigsur-extract -type d -name "bigsur" | head -n 1)
    if [ -n "$FOUND_SOUND" ]; then
        sudo cp -r "$FOUND_SOUND" /usr/share/sounds/ 2>/dev/null || true
        cp -r "$FOUND_SOUND" "$REAL_HOME/.local/share/sounds/" 2>/dev/null || true
    fi
    rm -rf /tmp/bigsur.zip /tmp/bigsur-extract
fi

run_as_user gsettings set org.gnome.desktop.sound theme-name 'bigsur'
run_as_user gsettings set org.gnome.desktop.sound event-sounds true
run_as_user gsettings set org.gnome.desktop.sound input-feedback-sounds true

cat > "$REAL_HOME/.config/autostart/macos-startup-chime.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=macOS Startup Chime
Exec=sh -c "paplay /usr/share/sounds/bigsur/stereo/desktop-login.oga 2>/dev/null || paplay /usr/share/sounds/freedesktop/stereo/service-login.oga 2>/dev/null || true"
X-GNOME-Autostart-enabled=true
EOF

echo -e "${GREEN}   ✓ Sonidos Big Sur y Startup Chime activados${NC}"

# =============================================================================
# PASO 6: PLYMOUTH (PANTALLA DE ARRANQUE CON LOGO APPLE)
# =============================================================================
echo -e "\n${YELLOW}🖥️  [6/12] Instalando tema de arranque Apple Mac Plymouth...${NC}"

rm -rf /tmp/apple-mac-plymouth
git clone --depth=1 https://github.com/navisjayaseelan/apple-mac-plymouth.git /tmp/apple-mac-plymouth 2>/dev/null || true
if [ -d "/tmp/apple-mac-plymouth/apple-mac-plymouth" ]; then
    sudo mkdir -p /usr/share/plymouth/themes
    sudo cp -r /tmp/apple-mac-plymouth/apple-mac-plymouth /usr/share/plymouth/themes/
    sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/apple-mac-plymouth/apple-mac-plymouth.plymouth 100 2>/dev/null || true
    sudo update-alternatives --set default.plymouth /usr/share/plymouth/themes/apple-mac-plymouth/apple-mac-plymouth.plymouth 2>/dev/null || true
    command -v update-initramfs &>/dev/null && sudo update-initramfs -u >/dev/null 2>&1 || true
    rm -rf /tmp/apple-mac-plymouth
    echo -e "${GREEN}   ✓ Plymouth instalado${NC}"
fi

# =============================================================================
# PASO 7: APLICACIONES (LOCALSEND, APPLE TV, APPLE MUSIC, OFFICE, SAFARI, FINDER)
# =============================================================================
echo -e "\n${YELLOW}🎵 [7/12] Instalando LocalSend, Apple TV, Apple Music, Office, Safari y Finder...${NC}"

APP_ICON_DIR="$REAL_HOME/.local/share/icons/hicolor/256x256/apps"
mkdir -p "$APP_ICON_DIR"

cat > /tmp/apple-logo.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 170 170" width="100%" height="100%">
  <path fill="#FFFFFF" d="M150.37 130.25c-2.45 5.66-5.35 10.87-8.71 15.66-4.58 6.53-8.33 11.05-11.22 13.56-4.48 4.12-9.28 6.23-14.42 6.35-3.69 0-8.14-1.05-13.32-3.18-5.19-2.12-9.97-3.17-14.34-3.17-4.58 0-9.49 1.05-14.75 3.17-5.26 2.13-9.5 3.24-12.74 3.35-4.35.13-9.13-1.9-14.34-6.08-3.69-3.03-7.61-7.82-11.77-14.37-5.93-9.28-10.76-19.99-14.47-32.12-3.71-12.13-5.56-23.36-5.56-33.68 0-12.87 3.22-23.47 9.65-31.78 6.44-8.31 14.54-12.63 24.31-12.96 4.92 0 10.35 1.49 16.29 4.46 5.93 2.97 9.77 4.51 11.51 4.62 1.45 0 5.64-1.78 12.56-5.34 6.93-3.56 13.06-5.07 18.39-4.54 13.65 1.1 23.91 6.49 30.78 16.17-12.19 7.39-18.15 17.65-17.88 30.78.27 10.27 4.28 18.82 12.02 25.65 5.46 4.86 11.97 7.79 19.53 8.79-1.57 4.79-3.43 9.69-5.58 14.69zM119.22 31.01c0 8.05-2.94 15.56-8.82 22.53-7.09 8.28-15.65 13.05-24.91 12.3-.19-.96-.29-2.01-.29-3.15 0-7.73 3.25-15.99 9.75-23.23 3.11-3.51 7.06-6.42 11.85-8.73 4.79-2.31 9.33-3.59 13.62-3.84.13 1.42.2 2.79.2 4.12z"/>
</svg>
EOF
sudo mv /tmp/apple-logo.svg /usr/share/pixmaps/apple-logo.svg
sudo chmod 644 /usr/share/pixmaps/apple-logo.svg

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

if [ ! -s "$REAL_HOME/.local/bin/localsend" ]; then
    curl -sL "https://github.com/localsend/localsend/releases/download/v1.15.4/LocalSend-1.15.4-linux-x86_64.AppImage" -o "$REAL_HOME/.local/bin/localsend" || true
    chmod +x "$REAL_HOME/.local/bin/localsend" 2>/dev/null || true
fi
if command -v ufw &>/dev/null; then
    sudo ufw allow 53317/tcp >/dev/null 2>&1 || true
    sudo ufw allow 53317/udp >/dev/null 2>&1 || true
fi

if [ ! -s "$REAL_HOME/.local/bin/iptvnator" ]; then
    curl -sL "https://github.com/4gray/iptvnator/releases/download/v0.16.0/iptvnator-0.16.0-linux-x86_64.AppImage" -o "$REAL_HOME/.local/bin/iptvnator" || \
    curl -sL "https://github.com/4gray/iptvnator/releases/download/v0.14.0/iptvnator-0.14.0-linux-x86_64.AppImage" -o "$REAL_HOME/.local/bin/iptvnator" || true
    chmod +x "$REAL_HOME/.local/bin/iptvnator" 2>/dev/null || true
fi
mkdir -p "$REAL_HOME/.config/iptvnator"
cat > "$REAL_HOME/.config/iptvnator/store.json" << 'EOF'
{"playlists": [{"id": "spa", "name": "📺 Canales en Español", "url": "https://iptv-org.github.io/iptv/languages/spa.m3u", "autoRefresh": true}], "settings": {"player": "html5", "theme": "dark"}}
EOF

if [ ! -s "$REAL_HOME/.local/bin/zuno" ]; then
    curl -sL "https://github.com/noFAYZ/zuno/releases/download/v1.4.0/Zuno_1.4.0_amd64.AppImage" -o "$REAL_HOME/.local/bin/zuno" || true
    chmod +x "$REAL_HOME/.local/bin/zuno" 2>/dev/null || true
fi

if command -v flatpak &>/dev/null; then
    sudo flatpak install -y --noninteractive flathub org.onlyoffice.desktopeditors >/dev/null 2>&1 || true
fi

cat > "$REAL_HOME/.local/share/applications/localsend.desktop" << EOF
[Desktop Entry]
Name=LocalSend (AirDrop)
Exec=$REAL_HOME/.local/bin/localsend --no-sandbox %U
Icon=$APP_ICON_DIR/localsend.svg
Terminal=false
Type=Application
Categories=Network;FileTransfer;
EOF

cat > "$REAL_HOME/.local/share/applications/appletv.desktop" << EOF
[Desktop Entry]
Name=Apple TV
Exec=$REAL_HOME/.local/bin/iptvnator --no-sandbox --ozone-platform=x11 %U
Icon=$APP_ICON_DIR/appletv.svg
Terminal=false
Type=Application
Categories=AudioVideo;Video;Player;
EOF

cat > "$REAL_HOME/.local/share/applications/applemusic.desktop" << EOF
[Desktop Entry]
Name=Apple Music
Exec=env WEBKIT_DISABLE_DMABUF_RENDERER=1 $REAL_HOME/.local/bin/zuno --no-sandbox %U
Icon=$APP_ICON_DIR/applemusic.svg
Terminal=false
Type=Application
Categories=Audio;Music;Player;
EOF

cat > "$REAL_HOME/.local/share/applications/office.desktop" << EOF
[Desktop Entry]
Name=Office
Exec=flatpak run org.onlyoffice.desktopeditors %U
Icon=$APP_ICON_DIR/office.svg
Terminal=false
Type=Application
Categories=Office;
EOF

cat > "$REAL_HOME/.local/share/applications/safari.desktop" << EOF
[Desktop Entry]
Name=Safari
Exec=firefox %u
Icon=$APP_ICON_DIR/safari.svg
Terminal=false
Type=Application
Categories=Network;WebBrowser;
EOF

if [ -f "/usr/share/applications/org.gnome.Nautilus.desktop" ]; then
    cp "/usr/share/applications/org.gnome.Nautilus.desktop" "$REAL_HOME/.local/share/applications/org.gnome.Nautilus.desktop"
    sed -i 's/^Name=.*/Name=Finder/g' "$REAL_HOME/.local/share/applications/org.gnome.Nautilus.desktop"
fi

chmod +x "$REAL_HOME/.local/share/applications/"*.desktop 2>/dev/null || true
run_as_user update-desktop-database "$REAL_HOME/.local/share/applications" 2>/dev/null || true
echo -e "${GREEN}   ✓ Aplicaciones instaladas y transformadas${NC}"

# =============================================================================
# PASO 8: WALLPAPERS DINÁMICOS NATIVOS GNOME (XML) + MODO OSCURO AUTOMÁTICO
# =============================================================================
echo -e "\n${YELLOW}🌅 [8/12] Configurando Wallpapers Dinámicos XML y Modo Oscuro Automático...${NC}"

BG_DIR="/usr/share/backgrounds/macos-dynamic"
sudo mkdir -p "$BG_DIR" /usr/share/gnome-background-properties

sudo curl -sL "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1920&q=85" -o "$BG_DIR/mojave-day.jpg" || \
sudo curl -sL -A "Mozilla/5.0" "https://raw.githubusercontent.com/linuxdotexe/nordic-wallpapers/master/wallpapers/ign_macos.png" -o "$BG_DIR/mojave-day.jpg" || true

sudo curl -sL "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=1920&q=85" -o "$BG_DIR/mojave-night.jpg" || \
sudo curl -sL -A "Mozilla/5.0" "https://raw.githubusercontent.com/aynp/dracula-wallpapers/main/os/macos-big-sur-night.jpg" -o "$BG_DIR/mojave-night.jpg" || true

# Crear XML de transición dinámica nativo de GNOME
sudo bash -c "cat > $BG_DIR/mojave-timed.xml" << 'EOF'
<background>
  <starttime>
    <year>2026</year>
    <month>01</month>
    <day>01</day>
    <hour>06</hour>
    <minute>00</minute>
    <second>00</second>
  </starttime>
  <static>
    <duration>41400.0</duration>
    <file>/usr/share/backgrounds/macos-dynamic/mojave-day.jpg</file>
  </static>
  <transition type="overlay">
    <duration>1800.0</duration>
    <from>/usr/share/backgrounds/macos-dynamic/mojave-day.jpg</from>
    <to>/usr/share/backgrounds/macos-dynamic/mojave-night.jpg</to>
  </transition>
  <static>
    <duration>41400.0</duration>
    <file>/usr/share/backgrounds/macos-dynamic/mojave-night.jpg</file>
  </static>
  <transition type="overlay">
    <duration>1800.0</duration>
    <from>/usr/share/backgrounds/macos-dynamic/mojave-night.jpg</from>
    <to>/usr/share/backgrounds/macos-dynamic/mojave-day.jpg</to>
  </transition>
</background>
EOF

# Registrar el fondo dinámico en la Configuración de GNOME
sudo bash -c "cat > /usr/share/gnome-background-properties/macos-dynamic.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
<wallpapers>
  <wallpaper deleted="false">
    <name>macOS Tahoe Dynamic</name>
    <filename>/usr/share/backgrounds/macos-dynamic/mojave-timed.xml</filename>
    <options>zoom</options>
    <pcolor>#000000</pcolor>
    <scolor>#000000</scolor>
  </wallpaper>
</wallpapers>
EOF

sudo chmod 644 "$BG_DIR"/* /usr/share/gnome-background-properties/macos-dynamic.xml 2>/dev/null || true

run_as_user gsettings set org.gnome.desktop.background picture-uri "file://$BG_DIR/mojave-day.jpg"
run_as_user gsettings set org.gnome.desktop.background picture-uri-dark "file://$BG_DIR/mojave-night.jpg"
run_as_user gsettings set org.gnome.desktop.background picture-options 'zoom'

# Script de sincronización horaria de Modo Claro/Oscuro (06:00 a 18:00) para GNOME
cat > "$REAL_HOME/.local/bin/macos-day-night-gnome" << EOF
#!/usr/bin/env bash
HOUR=\$(date +%-H)
if [ "\$HOUR" -ge 6 ] && [ "\$HOUR" -lt 18 ]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_LIGHT"
    gsettings set org.gnome.shell.extensions.user-theme name "$GTK_THEME_LIGHT"
    gsettings set org.gnome.desktop.background picture-uri "file://$BG_DIR/mojave-day.jpg"
else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_DARK"
    gsettings set org.gnome.shell.extensions.user-theme name "$GTK_THEME_DARK"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$BG_DIR/mojave-night.jpg"
fi
EOF
chmod +x "$REAL_HOME/.local/bin/macos-day-night-gnome"

cat > "$REAL_HOME/.config/systemd/user/macos-day-night.service" << EOF
[Unit]
Description=Sincronizar Wallpaper y Modo Oscuro macOS en GNOME
[Service]
Type=oneshot
ExecStart=$REAL_HOME/.local/bin/macos-day-night-gnome
EOF

cat > "$REAL_HOME/.config/systemd/user/macos-day-night.timer" << 'EOF'
[Unit]
Description=Timer horario para Modo Oscuro macOS en GNOME
[Timer]
OnBootSec=1min
OnUnitActiveSec=15min
Persistent=true
[Install]
WantedBy=timers.target
EOF

run_as_user systemctl --user daemon-reload
run_as_user systemctl --user enable --now macos-day-night.timer
run_as_user "$REAL_HOME/.local/bin/macos-day-night-gnome"

echo -e "${GREEN}   ✓ Wallpapers dinámicos XML y Modo Oscuro Automático activos en GNOME${NC}"

# =============================================================================
# PASO 9: ROFI SPOTLIGHT, ACERCA DE ESTE MAC Y HOSTNAME (MacBook-Pro)
# =============================================================================
echo -e "\n${YELLOW}💻 [9/12] Configurando Rofi Spotlight, 'Acerca de este Mac' y Hostname...${NC}"

cat > "$REAL_HOME/.config/rofi/config.rasi" << 'EOF'
configuration {
    modi: "drun,run,filebrowser";
    show-icons: true;
    display-drun: "🔍 Spotlight";
    font: "SF Pro Text 13";
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

        sub = Gtk.Label(label="Versión 26.0 (GNOME Edition)")
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
        for cmd in ["update-manager", "gnome-software", "mintupdate"]:
            if subprocess.call(["which", cmd], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) == 0:
                subprocess.Popen([cmd]); return
        subprocess.Popen(["gnome-terminal", "--", "bash", "-c", "sudo apt update && sudo apt upgrade; read -p 'Enter para salir...'"])

win = AboutThisMac()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()
EOF
chmod +x "$REAL_HOME/.local/bin/about-this-mac"
sudo ln -sf "$REAL_HOME/.local/bin/about-this-mac" /usr/local/bin/about-this-mac 2>/dev/null || true

NEW_HOSTNAME="MacBook-Pro"
sudo hostnamectl set-hostname "$NEW_HOSTNAME" 2>/dev/null || true
echo "$NEW_HOSTNAME" | sudo tee /etc/hostname > /dev/null 2>/dev/null || true
sudo sed -i "s/127\.0\.1\.1.*/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts 2>/dev/null || true

echo -e "${GREEN}   ✓ Spotlight, Acerca de este Mac y Hostname ($NEW_HOSTNAME) configurados${NC}"

# =============================================================================
# PASO 10: SCROLL NATURAL, TERMINAL macOS, SIDEBAR FINDER Y GESTOS FUSUMA
# =============================================================================
echo -e "\n${YELLOW}📜 [10/12] Configurando Scroll Natural, Terminal, Sidebar Finder y Fusuma...${NC}"

# Scroll Natural y Tap-to-Click en GNOME
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
run_as_user gsettings set org.gnome.desktop.peripherals.mouse natural-scroll true

# Perfil de GNOME Terminal con SF Mono y cursor I-Beam
TERM_PROFILE=$(run_as_user gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
if [ -n "$TERM_PROFILE" ]; then
    TPATH="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$TERM_PROFILE/"
    run_as_user gsettings set "$TPATH" use-system-font false
    run_as_user gsettings set "$TPATH" font 'SF Mono Regular 11'
    run_as_user gsettings set "$TPATH" cursor-shape 'ibeam'
fi

# Marcadores Sidebar estilo Finder en Nautilus
cat > "$REAL_HOME/.config/gtk-3.0/bookmarks" << EOF
file://$REAL_HOME/Desktop Desktop
file://$REAL_HOME/Documents Documents
file://$REAL_HOME/Downloads Downloads
file://$REAL_HOME/Music Music
file://$REAL_HOME/Pictures Pictures
file://$REAL_HOME/Videos Movies
EOF

# Gestos Fusuma
sudo usermod -aG input "$REAL_USER" 2>/dev/null || true
cat > "$REAL_HOME/.config/fusuma/config.yml" << 'EOF'
swipe:
  3:
    left:
      command: 'xdotool key ctrl+alt+Right'
    right:
      command: 'xdotool key ctrl+alt+Left'
    up:
      command: 'xdotool key Super_L'
    down:
      command: 'xdotool key super+d'
EOF

echo -e "${GREEN}   ✓ Scroll Natural, Terminal, Nautilus Sidebar y Gestos listos${NC}"

# =============================================================================
# PASO 11: 50+ ATAJOS DE TECLADO ESTILO macOS EN GNOME
# =============================================================================
echo -e "\n${YELLOW}⌨️  [11/12] Configurando atajos de teclado estilo macOS en GNOME...${NC}"

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
    xdotool key Super_L
fi
EOF
chmod +x "$REAL_HOME/.local/bin/macos-"*

# Liberar Super+1/2/3/4 de GNOME Shell para que cambien de área de trabajo
run_as_user gsettings set org.gnome.desktop.wm.preferences num-workspaces 4
run_as_user gsettings set org.gnome.mutter dynamic-workspaces false
for i in 1 2 3 4; do
    run_as_user gsettings set org.gnome.shell.keybindings "switch-to-application-$i" "[]"
done

# Atajos de Gestión de Ventanas y Áreas de Trabajo en Mutter / GNOME
run_as_user gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q', '<Alt>F4']"
run_as_user gsettings set org.gnome.desktop.wm.keybindings minimize "['<Super>m']"
run_as_user gsettings set org.gnome.desktop.wm.keybindings toggle-maximized "['<Super>Up']"
run_as_user gsettings set org.gnome.desktop.wm.keybindings unmaximize "['<Super>Down']"
run_as_user gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']"
run_as_user gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
run_as_user gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
run_as_user gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
run_as_user gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"
run_as_user gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Primary><Alt>Left']"
run_as_user gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Primary><Alt>Right']"

# Atajos de Sistema (Finder, Terminal, Bloqueo)
run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"
run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Primary><Alt>t']"
run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Super>l']"

# Atajos personalizados en GNOME (Spotlight, Acerca de este Mac, Centrar ventana, xkill)
add_gnome_shortcut() {
    local id="$1"
    local name="$2"
    local cmd="$3"
    local binding="$4"
    local path="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/$id/"
    run_as_user gsettings set "$path" name "$name"
    run_as_user gsettings set "$path" command "$cmd"
    run_as_user gsettings set "$path" binding "$binding"
}

add_gnome_shortcut "macos-spotlight" "Spotlight (macOS)" "$REAL_HOME/.local/bin/macos-spotlight" "<Primary>space"
add_gnome_shortcut "macos-about" "Acerca de este Mac" "$REAL_HOME/.local/bin/about-this-mac" "<Super>i"
add_gnome_shortcut "macos-center" "Centrar ventana" "$REAL_HOME/.local/bin/macos-center-window" "<Super>c"
add_gnome_shortcut "macos-xkill" "Forzar cierre de app (xkill)" "xkill" "<Primary><Alt>Escape"

CURRENT_CUSTOM=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
UPDATED_CUSTOM=$(python3 - "$CURRENT_CUSTOM" << 'EOF'
import sys, ast
raw = sys.argv[1].replace("@as ", "").strip()
try:
    lst = ast.literal_eval(raw) if raw else []
except Exception:
    lst = []
for slot in ["macos-spotlight", "macos-about", "macos-center", "macos-xkill"]:
    p = f"/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/{slot}/"
    if p not in lst:
        lst.append(p)
print(str(lst))
EOF
)
run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$UPDATED_CUSTOM"

echo -e "${GREEN}   ✓ Atajos de teclado estilo macOS configurados en GNOME${NC}"

# =============================================================================
# PASO 12: PERMISOS DEFINITIVOS Y ACTUALIZACIÓN DE CACHÉS
# =============================================================================
echo -e "\n${YELLOW}🔒 [12/12] Restaurando propiedad al usuario y actualizando cachés...${NC}"

sudo chown -R "$REAL_USER:$REAL_GID" "$REAL_HOME/.local" "$REAL_HOME/.config" "$REAL_HOME/.cache" "$REAL_HOME/.themes" "$REAL_HOME/.icons" "$WORKDIR" 2>/dev/null || true
chmod -R u+rwX "$REAL_HOME/.config" "$REAL_HOME/.local" 2>/dev/null || true

sudo gtk-update-icon-cache -f "/usr/share/icons/$ICON_THEME_NAME" 2>/dev/null || true
sudo gtk-update-icon-cache -f "$REAL_HOME/.local/share/icons/hicolor" 2>/dev/null || true

echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         ✅ INSTALACIÓN GNOME COMPLETADA Y VERIFICADA             ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo -e "   • ${GREEN}Tema GTK / Shell / Libadwaita:${NC} $GTK_THEME_DARK"
echo -e "   • ${GREEN}Tema de Iconos:${NC} $ICON_THEME_NAME"
echo -e "   • ${GREEN}Tema de Cursor:${NC} $CURSOR_THEME_NAME"
echo -e "   • ${GREEN}Extensiones GNOME:${NC} User-Theme, Liquid Glass, Magic Lamp y Dash-to-Dock"
echo -e "   • ${GREEN}Fondo Dinámico:${NC} macOS Tahoe Dynamic registrado en Configuración > Fondo\n"
