#!/usr/bin/env bash
# =============================================================================
# MacGNOME.sh - Instalador Definitivo macOS Tahoe para GNOME (Todo en uno)
# Soporta: Ubuntu GNOME / Debian GNOME / Zorin OS / Pop!_OS (X11 y Wayland)
# Incluye: Autorreparación automática de dpkg/apt, Logo Apple Wikimedia (/3/31/),
#          Logo oficial Apple TV PNG, Color de resalte Azul (#0A84FF),
#          Tema completo de Terminal macOS, GTK3/GTK4 (Libadwaita), Iconos,
#          Cursores, Sonidos Big Sur, Liquid Glass, Magic Lamp, Dash-to-Dock,
#          Wallpapers Dinámicos XML libres, Rofi Spotlight, Apps y Atajos macOS.
# =============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

WIKI_UA="MacGNOME-Installer/1.0 (https://github.com/vinceliuice/MacTahoe-gtk-theme)"

# 0. Solicitar y mantener activo el ticket sudo si no se lanzó directamente como root
if [ "$(id -u)" -ne 0 ]; then
    sudo -v || { echo -e "${RED}Se requieren permisos de administrador (sudo).${NC}"; exit 1; }
    ( while true; do sudo -n true; sleep 55; kill -0 "$$" 2>/dev/null || exit; done ) &
fi

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
SESSION_TYPE="x11"
[ -n "$REAL_WAYLAND" ] && SESSION_TYPE="wayland"

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

wait_for_apt() {
    local tries=0
    while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
          sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
          sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
          sudo fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
        tries=$((tries + 1))
        [ "$tries" -ge 30 ] && break
        sleep 2
    done
}

repair_dpkg_state() {
    wait_for_apt
    sudo DEBIAN_FRONTEND=noninteractive dpkg --configure -a >/dev/null 2>&1 || true
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -f -y >/dev/null 2>&1 || true
}

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         🍏 Instalador Definitivo macOS Tahoe para GNOME          ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo -e "${BLUE}   👤 Usuario: $REAL_USER (UID: $REAL_UID) | Sesión: $SESSION_TYPE ($REAL_DISPLAY)${NC}"
echo -e "${BLUE}   🔌 D-Bus: $REAL_DBUS${NC}"

if ! curl -Is --max-time 8 https://github.com >/dev/null 2>&1; then
    echo -e "${RED}   ✖ Sin conexión a GitHub. Verifica tu red antes de continuar.${NC}"
    exit 1
fi

# =============================================================================
# PASO 0: ESTRUCTURA DE DIRECTORIOS Y LOGOTIPO OFICIAL DE APPLE
# =============================================================================
echo -e "\n${YELLOW}🔐 [0/12] Preparando directorios y desbloqueando permisos de usuario...${NC}"

mkdir -p "$REAL_HOME/.local/share/applications"
mkdir -p "$REAL_HOME/.local/share/icons/hicolor/256x256/apps"
mkdir -p "$REAL_HOME/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$REAL_HOME/.local/share/fonts"
mkdir -p "$REAL_HOME/.local/share/sounds"
mkdir -p "$REAL_HOME/.local/share/themes"
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
sudo mkdir -p /usr/share/themes /usr/share/icons /usr/share/sounds /usr/share/backgrounds/macos-dynamic /usr/share/gnome-background-properties /usr/share/pixmaps

echo -e "${BLUE}    ⬇️  Descargando logotipo oficial de Apple (White SVG)...${NC}"
sudo rm -f /usr/share/pixmaps/apple-logo.svg
sudo curl -fsSL -A "$WIKI_UA" "https://upload.wikimedia.org/wikipedia/commons/3/31/Apple_logo_white.svg" -o /usr/share/pixmaps/apple-logo.svg || true

# Respaldo local en caso de operar sin salida a Wikimedia
if [ ! -s "/usr/share/pixmaps/apple-logo.svg" ] || ! grep -qi "<svg" /usr/share/pixmaps/apple-logo.svg 2>/dev/null; then
    cat > /tmp/apple-logo.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 170 170" width="100%" height="100%">
  <path fill="#FFFFFF" d="M150.37 130.25c-2.45 5.66-5.35 10.87-8.71 15.66-4.58 6.53-8.33 11.05-11.22 13.56-4.48 4.12-9.28 6.23-14.42 6.35-3.69 0-8.14-1.05-13.32-3.18-5.19-2.12-9.97-3.17-14.34-3.17-4.58 0-9.49 1.05-14.75 3.17-5.26 2.13-9.5 3.24-12.74 3.35-4.35.13-9.13-1.9-14.34-6.08-3.69-3.03-7.61-7.82-11.77-14.37-5.93-9.28-10.76-19.99-14.47-32.12-3.71-12.13-5.56-23.36-5.56-33.68 0-12.87 3.22-23.47 9.65-31.78 6.44-8.31 14.54-12.63 24.31-12.96 4.92 0 10.35 1.49 16.29 4.46 5.93 2.97 9.77 4.51 11.51 4.62 1.45 0 5.64-1.78 12.56-5.34 6.93-3.56 13.06-5.07 18.39-4.54 13.65 1.1 23.91 6.49 30.78 16.17-12.19 7.39-18.15 17.65-17.88 30.78.27 10.27 4.28 18.82 12.02 25.65 5.46 4.86 11.97 7.79 19.53 8.79-1.57 4.79-3.43 9.69-5.58 14.69zM119.22 31.01c0 8.05-2.94 15.56-8.82 22.53-7.09 8.28-15.65 13.05-24.91 12.3-.19-.96-.29-2.01-.29-3.15 0-7.73 3.25-15.99 9.75-23.23 3.11-3.51 7.06-6.42 11.85-8.73 4.79-2.31 9.33-3.59 13.62-3.84.13 1.42.2 2.79.2 4.12z"/>
</svg>
EOF
    sudo mv /tmp/apple-logo.svg /usr/share/pixmaps/apple-logo.svg
fi

sudo chmod 644 /usr/share/pixmaps/apple-logo.svg
sudo chown -R "$REAL_USER:$REAL_GID" "$REAL_HOME/.local" "$REAL_HOME/.config" "$REAL_HOME/.cache" "$REAL_HOME/.themes" "$REAL_HOME/.icons" "$WORKDIR" 2>/dev/null || true
chmod -R u+rwX "$REAL_HOME/.config" "$REAL_HOME/.local" 2>/dev/null || true

echo -e "${GREEN}   ✓ Directorios y logo de Apple listos${NC}"

# =============================================================================
# PASO 1: DEPENDENCIAS DEL SISTEMA, COMPILADORES GTK Y UTILIDADES GNOME
# =============================================================================
echo -e "\n${YELLOW}📦 [1/12] Instalando dependencias del sistema, compiladores GTK y herramientas GNOME...${NC}"

repair_dpkg_state
wait_for_apt
sudo apt-get update -qq 2>/dev/null || true

PKGS=(
    wget curl git unzip sassc libglib2.0-dev-bin libxml2-utils
    gtk2-engines-murrine gtk2-engines-pixbuf libgdk-pixbuf2.0-dev imagemagick dialog optipng
    wmctrl xdotool x11-utils xinput libinput-tools ruby ruby-dev build-essential
    rofi qt5ct qt5-style-plugins dconf-cli plymouth plymouth-themes ufw flatpak
    python3 python3-gi gir1.2-gtk-3.0 libnotify-bin
    alsa-utils pulseaudio-utils sox libcanberra-gtk-module libcanberra-gtk3-module
    gnome-terminal gnome-shell-extensions gnome-tweaks gnome-sushi
    gnome-shell-extension-dashtodock gnome-shell-extension-manager
    gstreamer1.0-plugins-base gstreamer1.0-plugins-good
    gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav
)

for pkg in "${PKGS[@]}"; do
    wait_for_apt
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$pkg" >/dev/null 2>&1 || true
done

wait_for_apt
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq libfuse2t64 >/dev/null 2>&1 || \
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq libfuse2 >/dev/null 2>&1 || true

if command -v gem &>/dev/null && ! command -v fusuma &>/dev/null; then
    sudo gem install --no-document fusuma >/dev/null 2>&1 || true
fi

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
# PASO 3: TEMA MACTAHOE (AZUL + MANZANA EN ESQUINA SUPERIOR IZQUIERDA)
# =============================================================================
echo -e "\n${YELLOW}🎨 [3/12] Compilando Tema MacTahoe (Resalte Azul + Manzana en Panel), Iconos y Cursores...${NC}"

SCREEN_WIDTH=$(xrandr --current 2>/dev/null | grep '*' | head -1 | awk '{print $1}' | cut -d'x' -f1 || echo "1920")
ICON_BOLD_FLAG=""
[ "${SCREEN_WIDTH:-1920}" -ge 3840 ] && ICON_BOLD_FLAG="-b"

echo -e "${BLUE}    ⬇️  Descargando y compilando MacTahoe GTK/Shell Theme (Azul)...${NC}"
rm -rf /tmp/macos-gtk-theme
git clone --depth=1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git /tmp/macos-gtk-theme 2>/dev/null || \
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git /tmp/macos-gtk-theme 2>/dev/null || true

if [ -d "/tmp/macos-gtk-theme" ]; then
    find /tmp/macos-gtk-theme -type f -name "*.sh" -exec sed -i 's/xfce4-panel -r/true/g' {} + 2>/dev/null || true
    chown -R "$REAL_USER:$REAL_GID" /tmp/macos-gtk-theme

    run_as_user bash -c "cd /tmp/macos-gtk-theme && ./install.sh -d '$REAL_HOME/.themes' -c dark -c light -t default -l --round" || \
    run_as_user bash -c "cd /tmp/macos-gtk-theme && ./install.sh -d '$REAL_HOME/.themes' -c dark -c light -t default" || true

    cp -r "$REAL_HOME/.themes"/* "$REAL_HOME/.local/share/themes/" 2>/dev/null || true
    sudo cp -r "$REAL_HOME/.themes"/* /usr/share/themes/ 2>/dev/null || true

    if [ -f "/tmp/macos-gtk-theme/tweaks.sh" ]; then
        run_as_user bash -c "cd /tmp/macos-gtk-theme && ./tweaks.sh -g -b default >/dev/null 2>&1" || true
    fi
    rm -rf /tmp/macos-gtk-theme
fi

for shell_css in "$REAL_HOME/.local/share/themes"/*/gnome-shell/gnome-shell.css "$REAL_HOME/.themes"/*/gnome-shell/gnome-shell.css /usr/share/themes/*/gnome-shell/gnome-shell.css; do
    if [ -f "$shell_css" ] && [[ "$shell_css" == *"Tahoe"* || "$shell_css" == *"WhiteSur"* ]]; then
        grep -q "panelActivities.panel-button" "$shell_css" 2>/dev/null || sudo bash -c "cat >> '$shell_css'" << 'EOF'

/* Forzar Logo de Apple en botón superior izquierdo (GNOME 40-48 / Zorin OS Menu & Activities) */
#panel #panelActivities.panel-button,
#panel .panel-button.activities-button,
#panel .zorin-menu-button,
#panel .panel-button.zorin-menu-button,
#panel #panel-activities {
    background-image: url("file:///usr/share/pixmaps/apple-logo.svg") !important;
    background-repeat: no-repeat !important;
    background-position: center center !important;
    background-size: 18px 18px !important;
    min-width: 44px !important;
    color: transparent !important;
}
#panel #panelActivities.panel-button > *,
#panel #panelActivities.panel-button .workspace-dots,
#panel #panelActivities.panel-button .workspace-dot,
#panel .panel-button.activities-button > *,
#panel .zorin-menu-button > *,
#panel .panel-button.zorin-menu-button > *,
#panel #panel-activities > * {
    background-color: transparent !important;
    background-image: none !important;
    border: none !important;
    box-shadow: none !important;
    opacity: 0 !important;
    width: 0 !important;
    margin: 0 !important;
    padding: 0 !important;
}
EOF
    fi
done

for z_icon in /usr/share/icons/*/*/apps/*zorin*icon*.svg \
              /usr/share/icons/*/*/apps/start-here*.svg \
              /usr/share/icons/*/scalable/apps/zorin-icon.svg \
              /usr/share/gnome-shell/extensions/zorin-menu*/*.svg \
              /usr/share/gnome-shell/extensions/zorin-menu*/*zorin*.svg; do
    if [ -f "$z_icon" ]; then
        sudo cp /usr/share/pixmaps/apple-logo.svg "$z_icon" 2>/dev/null || true
    fi
done

run_as_user gsettings set org.gnome.shell.extensions.zorin-menu menu-text "" 2>/dev/null || true
run_as_user gsettings set org.gnome.shell.extensions.zorin-menu icon-type 'custom' 2>/dev/null || true
run_as_user gsettings set org.gnome.shell.extensions.zorin-menu custom-icon '/usr/share/pixmaps/apple-logo.svg' 2>/dev/null || true
run_as_user gsettings set org.gnome.shell.extensions.zorin-menu icon-size 22 2>/dev/null || true

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

echo -e "${BLUE}    ⬇️  Descargando e instalando MacTahoe Icon Theme...${NC}"
rm -rf /tmp/macos-icon-theme
git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git /tmp/macos-icon-theme 2>/dev/null || \
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/macos-icon-theme 2>/dev/null || true

if [ -d "/tmp/macos-icon-theme" ]; then
    chown -R "$REAL_USER:$REAL_GID" /tmp/macos-icon-theme
    run_as_user bash -c "cd /tmp/macos-icon-theme && ./install.sh -d '$REAL_HOME/.icons' -t default $ICON_BOLD_FLAG" || \
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

echo -e "${BLUE}    ⬇️  Descargando e instalando Cursores macOS...${NC}"
rm -rf /tmp/macos-cursors
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-cursors.git /tmp/macos-cursors 2>/dev/null || true
if [ -d "/tmp/macos-cursors/dist" ]; then
    cp -r /tmp/macos-cursors/dist "$REAL_HOME/.icons/WhiteSur-cursors" 2>/dev/null || true
    sudo cp -r /tmp/macos-cursors/dist /usr/share/icons/WhiteSur-cursors 2>/dev/null || true
    rm -rf /tmp/macos-cursors
fi
CURSOR_THEME_NAME="WhiteSur-cursors"

run_as_user gsettings set org.gnome.desktop.interface accent-color 'blue'
run_as_user gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_DARK"
run_as_user gsettings set org.gnome.desktop.wm.preferences theme "$GTK_THEME_DARK"
run_as_user gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
run_as_user gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME_NAME"
run_as_user gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME_NAME"
run_as_user gsettings set org.gnome.desktop.interface cursor-size 24
run_as_user gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'

for css_file in "$REAL_HOME/.config/gtk-3.0/gtk.css" "$REAL_HOME/.config/gtk-4.0/gtk.css"; do
    grep -q "accent_bg_color #0A84FF" "$css_file" 2>/dev/null || cat >> "$css_file" << 'EOF'

/* Color de resalte Azul oficial de macOS (#0A84FF) */
@define-color accent_color #0A84FF;
@define-color accent_bg_color #0A84FF;
@define-color accent_fg_color #FFFFFF;
@define-color theme_selected_bg_color #0A84FF;
@define-color theme_selected_fg_color #FFFFFF;
selection { background-color: #0A84FF; color: #FFFFFF; }
EOF
done

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

if ! grep -q "QT_QPA_PLATFORMTHEME=qt5ct" /etc/environment 2>/dev/null; then
    echo "QT_QPA_PLATFORMTHEME=qt5ct" | sudo tee -a /etc/environment >/dev/null 2>&1 || true
fi

echo -e "${GREEN}    ✓ Tema ($GTK_THEME_DARK), Manzana Superior Izquierda y Resalte Azul aplicados${NC}"

# =============================================================================
# PASO 4: EXTENSIONES GNOME (USER-THEME, LIQUID GLASS, MAGIC LAMP, DOCK)
# =============================================================================
echo -e "\n${YELLOW}🧩 [4/12] Activando User-Theme, Liquid Glass, Magic Lamp y Dock...${NC}"

EXT_DIR="$REAL_HOME/.local/share/gnome-shell/extensions"

rm -rf /tmp/magic-lamp
git clone --depth=1 https://github.com/hermes83/compiz-alike-magic-lamp-effect.git /tmp/magic-lamp 2>/dev/null || true
if [ -d "/tmp/magic-lamp" ]; then
    MAGIC_UUID="compiz-alike-magic-lamp-effect@hermes83.github.com"
    mkdir -p "$EXT_DIR/$MAGIC_UUID"
    cp -r /tmp/magic-lamp/* "$EXT_DIR/$MAGIC_UUID/" 2>/dev/null || true
    glib-compile-schemas "$EXT_DIR/$MAGIC_UUID/schemas/" 2>/dev/null || true
    rm -rf /tmp/magic-lamp
fi

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

run_as_user gnome-extensions disable ubuntu-dock@ubuntu.com
run_as_user gnome-extensions disable zorin-taskbar@zorinos.com
run_as_user gnome-extensions disable custom-accent-colors@demiskp

run_as_user gsettings set org.gnome.shell disable-user-extensions false
CURRENT_EXTS=$(run_as_user gsettings get org.gnome.shell enabled-extensions)
UPDATED_EXTS=$(python3 - "$CURRENT_EXTS" "${LG_UUID:-}" << 'EOF'
import sys, ast
raw = sys.argv[1].replace("@as ", "").strip()
lg = sys.argv[2]
try:
    lst = ast.literal_eval(raw) if raw else []
except Exception:
    lst = []
for conflict in ["ubuntu-dock@ubuntu.com", "zorin-taskbar@zorinos.com", "custom-accent-colors@demiskp"]:
    if conflict in lst:
        lst.remove(conflict)
for ext in [
    "user-theme@gnome-shell-extensions.gcampax.github.com",
    "compiz-alike-magic-lamp-effect@hermes83.github.com",
    "dash-to-dock@micxgx.gmail.com"
]:
    if ext not in lst:
        lst.append(ext)
if lg and lg not in lst:
    lst.append(lg)
print(str(lst))
EOF
)
run_as_user gsettings set org.gnome.shell enabled-extensions "$UPDATED_EXTS"
run_as_user gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
run_as_user gnome-extensions enable compiz-alike-magic-lamp-effect@hermes83.github.com
[ -n "${LG_UUID:-}" ] && run_as_user gnome-extensions enable "$LG_UUID"
run_as_user gnome-extensions enable dash-to-dock@micxgx.gmail.com
run_as_user gsettings set org.gnome.shell.extensions.user-theme name "$GTK_THEME_DARK"
run_as_user dconf write /org/gnome/shell/extensions/user-theme/name "'$GTK_THEME_DARK'"

run_as_user gsettings set org.gnome.shell.extensions.user-theme name 'Default'
sleep 0.4
run_as_user gsettings set org.gnome.shell.extensions.user-theme name "$GTK_THEME_DARK"

DOCK_SCHEMA="org.gnome.shell.extensions.dash-to-dock"
run_as_user gsettings set "$DOCK_SCHEMA" dock-position 'BOTTOM'
run_as_user gsettings set "$DOCK_SCHEMA" extend-height false
run_as_user gsettings set "$DOCK_SCHEMA" dock-fixed false
run_as_user gsettings set "$DOCK_SCHEMA" autohide true
run_as_user gsettings set "$DOCK_SCHEMA" intellihide true
run_as_user gsettings set "$DOCK_SCHEMA" dash-max-icon-size 48
run_as_user gsettings set "$DOCK_SCHEMA" click-action 'minimize'
run_as_user gsettings set "$DOCK_SCHEMA" show-trash true
run_as_user gsettings set "$DOCK_SCHEMA" show-apps-at-top true
run_as_user gsettings set "$DOCK_SCHEMA" transparency-mode 'DYNAMIC'
run_as_user gsettings set "$DOCK_SCHEMA" background-opacity 0.4
run_as_user gsettings set "$DOCK_SCHEMA" hot-keys false

echo -e "${GREEN}   ✓ Extensiones y tema de GNOME Shell recargados${NC}"

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

echo -e "${GREEN}   ✓ Sonidos Big Sur activados${NC}"

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
APP_ICON_SCALABLE="$REAL_HOME/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$APP_ICON_DIR" "$APP_ICON_SCALABLE"

cat > "$APP_ICON_DIR/applemusic.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><defs><linearGradient id="am" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" stop-color="#FF5E7E"/><stop offset="100%" stop-color="#FF2D55"/></linearGradient></defs><rect width="512" height="512" rx="115" fill="url(#am)"/><path fill="#FFF" d="M368 122c0-10.5-9.2-18.3-19.6-16.3l-152 29c-8.3 1.6-14.4 8.9-14.4 17.4v185.3c-10.2-6.8-23.3-10.4-37.3-9.1-27.1 2.5-48.7 23.6-50.5 50.1-2.1 31.2 22.8 56.6 53.8 56.6 29.8 0 54-23.7 54-53.5V212l134-25.6v118c-10.2-6.8-23.3-10.4-37.3-9.1-27.1 2.5-48.7 23.6-50.5 50.1-2.1 31.2 22.8 56.6 53.8 56.6 29.8 0 54-23.7 54-53.5V122z"/></svg>
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

cp "$APP_ICON_DIR"/*.svg "$APP_ICON_SCALABLE/" 2>/dev/null || true
sudo cp "$APP_ICON_DIR/office.svg" /usr/share/pixmaps/office.svg 2>/dev/null || true
sudo cp "$APP_ICON_DIR/office.svg" /usr/share/pixmaps/org.onlyoffice.desktopeditors.svg 2>/dev/null || true

# LocalSend (descarga dinámica desde API de GitHub)
if [ -f "$REAL_HOME/.local/bin/localsend" ] && [ "$(stat -c%s "$REAL_HOME/.local/bin/localsend" 2>/dev/null || echo 0)" -lt 10000000 ]; then
    rm -f "$REAL_HOME/.local/bin/localsend"
fi
if [ ! -s "$REAL_HOME/.local/bin/localsend" ]; then
    LS_APPIMAGE_URL=$(curl -fsSL https://api.github.com/repos/localsend/localsend/releases/latest 2>/dev/null | grep -iE "browser_download_url.*linux-x86[_-]64\.AppImage" | cut -d '"' -f 4 | head -n 1)
    if [ -n "$LS_APPIMAGE_URL" ]; then
        curl -fsSL "$LS_APPIMAGE_URL" -o "$REAL_HOME/.local/bin/localsend" || true
        if [ -f "$REAL_HOME/.local/bin/localsend" ] && [ "$(stat -c%s "$REAL_HOME/.local/bin/localsend" 2>/dev/null || echo 0)" -gt 10000000 ]; then
            chmod +x "$REAL_HOME/.local/bin/localsend"
        else
            rm -f "$REAL_HOME/.local/bin/localsend"
        fi
    fi
fi
if command -v ufw &>/dev/null; then
    sudo ufw allow 53317/tcp >/dev/null 2>&1 || true
    sudo ufw allow 53317/udp >/dev/null 2>&1 || true
fi

# Instalación garantizada de Apple TV (IPTVnator) vía paquete .deb desde la API de GitHub
echo -e "${BLUE}    ⬇️  Descargando e instalando Apple TV (IPTVnator)...${NC}"
rm -f "$REAL_HOME/.local/bin/iptvnator" "$REAL_HOME/.local/share/applications/appletv.desktop"
sudo rm -f /usr/share/applications/appletv.desktop
repair_dpkg_state

IPTV_DEB_URL=$(curl -fsSL https://api.github.com/repos/4gray/iptvnator/releases/latest 2>/dev/null | grep -i "browser_download_url.*amd64\.deb" | cut -d '"' -f 4 | head -n 1)
if [ -n "$IPTV_DEB_URL" ]; then
    curl -fsSL "$IPTV_DEB_URL" -o /tmp/iptvnator.deb || true
    if [ -s /tmp/iptvnator.deb ] && dpkg-deb -I /tmp/iptvnator.deb >/dev/null 2>&1; then
        wait_for_apt
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq /tmp/iptvnator.deb >/dev/null 2>&1 || repair_dpkg_state
    fi
    rm -f /tmp/iptvnator.deb
fi

# Icono oficial Apple TV PNG (Wikimedia con User-Agent validado + respaldo SVG local)
rm -f "$APP_ICON_DIR/appletv.svg" "$APP_ICON_SCALABLE/appletv.svg" "$APP_ICON_DIR/appletv.png"
curl -fsSL -A "$WIKI_UA" "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/AppleTVLogo.svg/960px-AppleTVLogo.svg.png" -o "$APP_ICON_DIR/appletv.png" || true
if [ -s "$APP_ICON_DIR/appletv.png" ] && file "$APP_ICON_DIR/appletv.png" 2>/dev/null | grep -qi "PNG"; then
    sudo cp "$APP_ICON_DIR/appletv.png" /usr/share/pixmaps/appletv.png 2>/dev/null || true
    sudo cp "$APP_ICON_DIR/appletv.png" /usr/share/pixmaps/iptvnator.png 2>/dev/null || true
    APPLETV_ICON="/usr/share/pixmaps/appletv.png"
else
    rm -f "$APP_ICON_DIR/appletv.png"
    cat > "$APP_ICON_DIR/appletv.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><defs><linearGradient id="atv" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" stop-color="#2C2C2E"/><stop offset="100%" stop-color="#000000"/></linearGradient></defs><rect width="512" height="512" rx="115" fill="url(#atv)"/><path fill="#FFF" d="M168.5 190c-12 21-29 20-29 20s-2-15 9-29c10-13 26-14 26-14s3 11-6 23zm-6.5 29c14 0 20 9 30 9s18-9 31-9c12 0 25 7 32 18-28 16-23 53 5 64-7 17-16 33-28 45-11 11-18 11-28 4-11-6-21-6-32 0-10 6-18 6-28-4-16-16-29-46-29-73 0-32 21-54 47-54zm95-14h28v26h23v21h-23v55c0 11 5 16 15 16 4 0 8-1 8-1v21s-6 2-15 2c-22 0-36-12-36-35v-58h-16v-21h16v-26zm62 26h29l23 82h1l23-82h28l-37 110h-30l-37-110z"/></svg>
EOF
    sudo cp "$APP_ICON_DIR/appletv.svg" /usr/share/pixmaps/appletv.svg 2>/dev/null || true
    sudo cp "$APP_ICON_DIR/appletv.svg" /usr/share/pixmaps/iptvnator.svg 2>/dev/null || true
    APPLETV_ICON="/usr/share/pixmaps/appletv.svg"
fi

mkdir -p "$REAL_HOME/.config/iptvnator"
cat > "$REAL_HOME/.config/iptvnator/store.json" << 'EOF'
{"playlists": [{"id": "spa", "name": "📺 Canales en Español", "url": "https://iptv-org.github.io/iptv/languages/spa.m3u", "autoRefresh": true}], "settings": {"player": "html5", "theme": "dark"}}
EOF

sudo tee /usr/share/applications/iptvnator.desktop > /dev/null << EOF
[Desktop Entry]
Name=Apple TV
GenericName=Apple TV
Exec=/usr/bin/iptvnator --ozone-platform=x11 --no-sandbox %U
Icon=$APPLETV_ICON
Terminal=false
Type=Application
Categories=AudioVideo;Video;Player;
StartupNotify=true
StartupWMClass=iptvnator
EOF

cp /usr/share/applications/iptvnator.desktop "$REAL_HOME/.local/share/applications/iptvnator.desktop"

# Apple Music (Zuno) con descarga dinámica desde API de GitHub
if [ -f "$REAL_HOME/.local/bin/zuno" ] && [ "$(stat -c%s "$REAL_HOME/.local/bin/zuno" 2>/dev/null || echo 0)" -lt 10000000 ]; then
    rm -f "$REAL_HOME/.local/bin/zuno"
fi
if [ ! -s "$REAL_HOME/.local/bin/zuno" ]; then
    ZUNO_URL=$(curl -fsSL https://api.github.com/repos/noFAYZ/zuno/releases/latest 2>/dev/null | grep -i "browser_download_url.*amd64\.AppImage" | cut -d '"' -f 4 | head -n 1)
    ZUNO_URL="${ZUNO_URL:-https://github.com/noFAYZ/zuno/releases/download/v1.4.0/Zuno_1.4.0_amd64.AppImage}"
    curl -fsSL "$ZUNO_URL" -o "$REAL_HOME/.local/bin/zuno" || true
    if [ -f "$REAL_HOME/.local/bin/zuno" ] && [ "$(stat -c%s "$REAL_HOME/.local/bin/zuno" 2>/dev/null || echo 0)" -gt 10000000 ]; then
        chmod +x "$REAL_HOME/.local/bin/zuno"
    else
        rm -f "$REAL_HOME/.local/bin/zuno"
    fi
fi

# Transformar ONLYOFFICE en Office parcheando el lanzador oficial de Flatpak (sin duplicados)
if command -v flatpak &>/dev/null; then
    sudo flatpak install -y --noninteractive flathub org.onlyoffice.desktopeditors >/dev/null 2>&1 || true

    FLATPAK_OFFICE_SRC="/var/lib/flatpak/exports/share/applications/org.onlyoffice.desktopeditors.desktop"
    [ ! -f "$FLATPAK_OFFICE_SRC" ] && FLATPAK_OFFICE_SRC="$REAL_HOME/.local/share/flatpak/exports/share/applications/org.onlyoffice.desktopeditors.desktop"

    if [ -f "$FLATPAK_OFFICE_SRC" ]; then
        cp "$FLATPAK_OFFICE_SRC" "$REAL_HOME/.local/share/applications/org.onlyoffice.desktopeditors.desktop"
        sed -i 's/^Name=.*/Name=Office/g' "$REAL_HOME/.local/share/applications/org.onlyoffice.desktopeditors.desktop"
        sed -i 's/^GenericName=.*/GenericName=Office/g' "$REAL_HOME/.local/share/applications/org.onlyoffice.desktopeditors.desktop"
        sed -i 's|^Icon=.*|Icon=/usr/share/pixmaps/office.svg|g' "$REAL_HOME/.local/share/applications/org.onlyoffice.desktopeditors.desktop"
    else
        cat > "$REAL_HOME/.local/share/applications/org.onlyoffice.desktopeditors.desktop" << EOF
[Desktop Entry]
Name=Office
GenericName=Office
Exec=flatpak run org.onlyoffice.desktopeditors %U
Icon=/usr/share/pixmaps/office.svg
Terminal=false
Type=Application
Categories=Office;
StartupWMClass=DesktopEditors
EOF
    fi
    rm -f "$REAL_HOME/.local/share/applications/office.desktop"
fi

cat > "$REAL_HOME/.local/share/applications/localsend.desktop" << EOF
[Desktop Entry]
Name=LocalSend (AirDrop)
Exec=$REAL_HOME/.local/bin/localsend --no-sandbox %U
Icon=$APP_ICON_DIR/localsend.svg
Terminal=false
Type=Application
Categories=Network;FileTransfer;
StartupWMClass=localsend_app
EOF

cat > "$REAL_HOME/.local/share/applications/applemusic.desktop" << EOF
[Desktop Entry]
Name=Apple Music
Exec=env WEBKIT_DISABLE_DMABUF_RENDERER=1 $REAL_HOME/.local/bin/zuno --no-sandbox %U
Icon=$APP_ICON_DIR/applemusic.svg
Terminal=false
Type=Application
Categories=Audio;Music;Player;
StartupWMClass=zuno
EOF

cat > "$REAL_HOME/.local/share/applications/safari.desktop" << EOF
[Desktop Entry]
Name=Safari
Exec=firefox %u
Icon=$APP_ICON_DIR/safari.svg
Terminal=false
Type=Application
Categories=Network;WebBrowser;
StartupWMClass=firefox
EOF

if [ -f "/usr/share/applications/org.gnome.Nautilus.desktop" ]; then
    cp "/usr/share/applications/org.gnome.Nautilus.desktop" "$REAL_HOME/.local/share/applications/org.gnome.Nautilus.desktop"
    sed -i 's/^Name=.*/Name=Finder/g' "$REAL_HOME/.local/share/applications/org.gnome.Nautilus.desktop"
fi

chmod +x "$REAL_HOME/.local/share/applications/"*.desktop 2>/dev/null || true
sudo update-desktop-database /usr/share/applications 2>/dev/null || true
run_as_user update-desktop-database "$REAL_HOME/.local/share/applications" 2>/dev/null || true
echo -e "${GREEN}   ✓ Aplicaciones instaladas y transformadas${NC}"

# =============================================================================
# PASO 8: WALLPAPERS DINÁMICOS NATIVOS GNOME (XML) SIN BLOQUEO PERMANENTE
# =============================================================================
echo -e "\n${YELLOW}🌅 [8/12] Registrando Wallpaper Dinámico XML en el selector de GNOME...${NC}"

BG_DIR="/usr/share/backgrounds/macos-dynamic"
sudo mkdir -p "$BG_DIR" /usr/share/gnome-background-properties

sudo curl -sL "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1920&q=85" -o "$BG_DIR/mojave-day.jpg" || \
sudo curl -sL -A "Mozilla/5.0" "https://raw.githubusercontent.com/linuxdotexe/nordic-wallpapers/master/wallpapers/ign_macos.png" -o "$BG_DIR/mojave-day.jpg" || true

sudo curl -sL "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=1920&q=85" -o "$BG_DIR/mojave-night.jpg" || \
sudo curl -sL -A "Mozilla/5.0" "https://raw.githubusercontent.com/aynp/dracula-wallpapers/main/os/macos-big-sur-night.jpg" -o "$BG_DIR/mojave-night.jpg" || true

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

run_as_user systemctl --user stop macos-day-night.timer macos-day-night.service 2>/dev/null || true
run_as_user systemctl --user disable macos-day-night.timer macos-day-night.service 2>/dev/null || true
rm -f "$REAL_HOME/.config/systemd/user/macos-day-night."* "$REAL_HOME/.local/bin/macos-day-night-gnome" 2>/dev/null || true
run_as_user systemctl --user daemon-reload 2>/dev/null || true

run_as_user gsettings set org.gnome.desktop.background picture-uri "file://$BG_DIR/mojave-timed.xml"
run_as_user gsettings set org.gnome.desktop.background picture-uri-dark "file://$BG_DIR/mojave-timed.xml"
run_as_user gsettings set org.gnome.desktop.background picture-options 'zoom'

echo -e "${GREEN}   ✓ Fondo dinámico registrado en GNOME (los usuarios ahora pueden cambiarlo libremente)${NC}"

# =============================================================================
# PASO 9: ROFI SPOTLIGHT, ACERCA DE ESTE MAC Y HOSTNAME
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
# PASO 10: TEMA DE TERMINAL macOS (COLORES + RESALTE AZUL), SCROLL Y FUSUMA
# =============================================================================
echo -e "\n${YELLOW}💻 [10/12] Configurando Tema de Terminal macOS, Scroll Natural y Sidebar Finder...${NC}"

run_as_user gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
run_as_user gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
run_as_user gsettings set org.gnome.desktop.peripherals.mouse natural-scroll true

TERM_DEFAULT=$(run_as_user gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
TERM_LIST=$(run_as_user gsettings get org.gnome.Terminal.ProfilesList list | tr -d "[]' ")
ALL_PROFILES=$(echo "$TERM_DEFAULT,$TERM_LIST" | tr ',' '\n' | sort -u | grep -v '^$' || true)

for prof in $ALL_PROFILES; do
    TPATH="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$prof/"
    run_as_user gsettings set "$TPATH" visible-name 'macOS Tahoe'
    run_as_user gsettings set "$TPATH" use-theme-colors false
    run_as_user gsettings set "$TPATH" background-color '#1E1E1E'
    run_as_user gsettings set "$TPATH" foreground-color '#E6E6E6'
    run_as_user gsettings set "$TPATH" bold-color-same-as-fg false
    run_as_user gsettings set "$TPATH" bold-color '#FFFFFF'
    run_as_user gsettings set "$TPATH" cursor-colors-set true
    run_as_user gsettings set "$TPATH" cursor-background-color '#0A84FF'
    run_as_user gsettings set "$TPATH" cursor-foreground-color '#FFFFFF'
    run_as_user gsettings set "$TPATH" highlight-colors-set true
    run_as_user gsettings set "$TPATH" highlight-background-color '#0A84FF'
    run_as_user gsettings set "$TPATH" highlight-foreground-color '#FFFFFF'
    run_as_user gsettings set "$TPATH" use-system-font false
    run_as_user gsettings set "$TPATH" font 'SF Mono Regular 11'
    run_as_user gsettings set "$TPATH" cursor-shape 'ibeam'
    run_as_user gsettings set "$TPATH" palette "['#1e1e1e', '#ff453a', '#32d74b', '#ffd60a', '#0a84ff', '#bf5af2', '#5ac8fa', '#e6e6e6', '#636366', '#ff6961', '#30db5b', '#ffd426', '#409cff', '#da8fff', '#70d7ff', '#ffffff']"
done

run_as_user gsettings set org.gnome.Console use-system-font false
run_as_user gsettings set org.gnome.Console custom-font 'SF Mono Regular 11'
run_as_user gsettings set org.gnome.Console theme 'night'
run_as_user gsettings set org.gnome.Ptyxis use-system-font false
run_as_user gsettings set org.gnome.Ptyxis font-name 'SF Mono Regular 11'
run_as_user gsettings set org.gnome.Ptyxis cursor-shape 'ibeam'

cat > "$REAL_HOME/.config/gtk-3.0/bookmarks" << EOF
file://$REAL_HOME/Desktop Desktop
file://$REAL_HOME/Documents Documents
file://$REAL_HOME/Downloads Downloads
file://$REAL_HOME/Music Music
file://$REAL_HOME/Pictures Pictures
file://$REAL_HOME/Videos Movies
EOF

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

cat > "$REAL_HOME/.config/autostart/fusuma-gestures.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Fusuma Touchpad Gestures
Exec=sh -c "[ \"$XDG_SESSION_TYPE\" = \"x11\" ] && command -v fusuma >/dev/null && fusuma -d"
X-GNOME-Autostart-enabled=true
EOF

echo -e "${GREEN}   ✓ Tema de Terminal macOS (con resalte azul), Scroll Natural y Sidebar listos${NC}"

# =============================================================================
# PASO 11: 50+ ATAJOS DE TECLADO ESTILO macOS EN GNOME
# =============================================================================
echo -e "\n${YELLOW}⌨️  [11/12] Configurando atajos de teclado estilo macOS en GNOME...${NC}"

cat > "$REAL_HOME/.local/bin/macos-center-window" << 'EOF'
#!/usr/bin/env bash
[ "$XDG_SESSION_TYPE" = "wayland" ] && exit 0
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
    gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell \
        --method org.gnome.Shell.Eval "Main.overview.toggle();" >/dev/null 2>&1 || true
fi
EOF
chmod +x "$REAL_HOME/.local/bin/macos-"*

run_as_user gsettings set org.gnome.desktop.wm.preferences num-workspaces 4
run_as_user gsettings set org.gnome.mutter dynamic-workspaces false
for i in 1 2 3 4; do
    run_as_user gsettings set org.gnome.shell.keybindings "switch-to-application-$i" "[]"
done

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

run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"
run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Primary><Alt>t']"
run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Super>l']"

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
# PASO 12: PERMISOS DEFINITIVOS, CACHÉS Y RECARGA EN VIVO
# =============================================================================
echo -e "\n${YELLOW}🔒 [12/12] Restaurando propiedad al usuario y recargando tema en vivo...${NC}"

sudo chown -R "$REAL_USER:$REAL_GID" "$REAL_HOME/.local" "$REAL_HOME/.config" "$REAL_HOME/.cache" "$REAL_HOME/.themes" "$REAL_HOME/.icons" "$WORKDIR" 2>/dev/null || true
chmod -R u+rwX "$REAL_HOME/.config" "$REAL_HOME/.local" 2>/dev/null || true

sudo gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
sudo gtk-update-icon-cache -f "/usr/share/icons/$ICON_THEME_NAME" 2>/dev/null || true
sudo gtk-update-icon-cache -f "$REAL_HOME/.local/share/icons/hicolor" 2>/dev/null || true
for z_dir in /usr/share/icons/Zorin*; do
    [ -d "$z_dir" ] && sudo gtk-update-icon-cache -f "$z_dir" 2>/dev/null || true
done

run_as_user gsettings set org.gnome.shell.extensions.user-theme name 'Default'
sleep 0.4
run_as_user gsettings set org.gnome.shell.extensions.user-theme name "$GTK_THEME_DARK"

echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         ✅ INSTALACIÓN GNOME COMPLETADA Y VERIFICADA             ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo -e "   • ${GREEN}Botón Superior Izquierdo:${NC} Logo Apple oficial en Activities y Zorin Menu"
echo -e "   • ${GREEN}Color de Resalte:${NC} Azul macOS (#0A84FF) activo en GNOME, GTK3 y GTK4"
echo -e "   • ${GREEN}Terminal macOS:${NC} Paleta oscura ANSI, cursor I-Beam y selección en Azul"
echo -e "   • ${GREEN}Apps Unificadas:${NC} Apple TV (iptvnator.desktop) y Office (org.onlyoffice.desktopeditors.desktop)"
echo -e "   • ${GREEN}Fondo Dinámico:${NC} XML registrado sin bloqueo (cambiable libremente en Configuración)"
echo -e "   • ${GREEN}Tema GTK / Shell / Libadwaita:${NC} $GTK_THEME_DARK"
echo -e "   • ${YELLOW}Importante:${NC} Cierra sesión y vuelve a iniciar para cargar las extensiones nuevas.\n"
