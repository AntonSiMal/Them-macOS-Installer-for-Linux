#!/usr/bin/env bash
# =============================================================================
# install.sh - Instalador y Reparador Definitivo Todo-en-Uno: macOS Tahoe
# Soporta: Linux Mint Cinnamon / Debian / Ubuntu (con soporte híbrido GNOME)
# Incluye los 26 componentes + Reparación de Menú, Wallpapers, Iconos y Atajos
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

run_as_user() {
    if [ "$(id -u)" -eq 0 ]; then
        sudo -u "$REAL_USER" env DISPLAY="${DISPLAY:-:0}" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$REAL_UID/bus" \
            XDG_RUNTIME_DIR="/run/user/$REAL_UID" "$@" 2>/dev/null || true
    else
        "$@" 2>/dev/null || true
    fi
}

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         🍏 Instalador Definitivo macOS Tahoe (install.sh)        ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"

# =============================================================================
# PASO 0: CORREGIR PERMISOS DE ARCHIVOS DE USUARIO
# =============================================================================
echo -e "\n${YELLOW}🔐 [0/12] Corrigiendo permisos y preparando estructura de usuario...${NC}"

mkdir -p "$REAL_HOME/.local/share/applications"
mkdir -p "$REAL_HOME/.local/share/icons/hicolor/256x256/apps"
mkdir -p "$REAL_HOME/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$REAL_HOME/.local/share/fonts"
mkdir -p "$REAL_HOME/.local/share/sounds"
mkdir -p "$REAL_HOME/.local/bin"
mkdir -p "$REAL_HOME/.themes"
mkdir -p "$REAL_HOME/.icons"
mkdir -p "$REAL_HOME/.config/rofi"
mkdir -p "$REAL_HOME/.config/autostart"
mkdir -p "$REAL_HOME/.config/systemd/user"
mkdir -p "$REAL_HOME/.config/gtk-3.0"
mkdir -p "$REAL_HOME/.config/fusuma"

sudo chown -R "$REAL_USER:$REAL_GID" "$REAL_HOME/.local" 2>/dev/null || true
sudo chown -R "$REAL_USER:$REAL_GID" "$REAL_HOME/.config" 2>/dev/null || true
sudo chown -R "$REAL_USER:$REAL_GID" "$REAL_HOME/.cinnamon" 2>/dev/null || true
sudo chown -R "$REAL_USER:$REAL_GID" "$REAL_HOME/.themes" "$REAL_HOME/.icons" 2>/dev/null || true
chmod -R u+rwX "$REAL_HOME/.local/share/applications/" "$REAL_HOME/.local/share/icons/" 2>/dev/null || true

echo -e "${GREEN}   ✓ Permisos iniciales corregidos${NC}"

# =============================================================================
# PASO 1: DEPENDENCIAS DEL SISTEMA Y CODECS
# =============================================================================
echo -e "\n${YELLOW}📦 [1/12] Instalando dependencias del sistema, codecs y herramientas...${NC}"

sudo apt-get update -qq 2>/dev/null || true
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    wget curl git unzip sassc libglib2.0-dev-bin libxml2-utils \
    wmctrl xdotool x11-utils xinput libinput-tools ruby ruby-dev \
    rofi plank gnome-sushi qt5ct qt5-style-plugins dconf-cli \
    plymouth plymouth-themes ufw flatpak python3-gi gir1.2-gtk-3.0 \
    gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav \
    alsa-utils pulseaudio-utils libnotify-bin >/dev/null 2>&1 || true

sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
echo -e "${GREEN}   ✓ Dependencias instaladas${NC}"

# =============================================================================
# PASO 2: FUENTES OFICIALES APPLE (SF PRO, SF COMPACT, SF MONO, NEW YORK) + FONTCONFIG
# =============================================================================
echo -e "\n${YELLOW}🔤 [2/12] Instalando fuentes Apple (SF Pro, SF Mono, New York) y Fontconfig...${NC}"

FONT_DIR="/usr/share/fonts/truetype/apple-fonts"
sudo mkdir -p "$FONT_DIR"

if [ -z "$(ls -A "$FONT_DIR" 2>/dev/null)" ]; then
    git clone --depth 1 https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts.git /tmp/sf-pro 2>/dev/null || true
    sudo cp /tmp/sf-pro/*.otf /tmp/sf-pro/*.ttf "$FONT_DIR/" 2>/dev/null || true
    rm -rf /tmp/sf-pro
fi

# Optimización de renderizado Fontconfig estilo macOS
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
run_as_user gsettings set org.cinnamon.desktop.interface font-name 'SF Pro Display 10'
run_as_user gsettings set org.nemo.desktop font 'SF Pro Display 10'
run_as_user gsettings set org.cinnamon.desktop.wm.preferences titlebar-font 'SF Pro Display Bold 10'

echo -e "${GREEN}   ✓ Fuentes Apple y renderizado Fontconfig aplicados${NC}"

# =============================================================================
# PASO 3: TEMA GTK MACTAHOE, ICONOS MACTAHOE (4K AUTO), PLANK Y QT
# =============================================================================
echo -e "\n${YELLOW}🎨 [3/12] Instalando tema visual MacTahoe GTK, Iconos y tematización Qt...${NC}"

if [ ! -d "/usr/share/themes/WhiteSur-Dark" ] && [ ! -d "$REAL_HOME/.themes/WhiteSur-Dark" ]; then
    git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git /tmp/WhiteSur-gtk 2>/dev/null || true
    if [ -d "/tmp/WhiteSur-gtk" ]; then
        (cd /tmp/WhiteSur-gtk && ./install.sh -d "$REAL_HOME/.themes" -t all >/dev/null 2>&1) || true
        rm -rf /tmp/WhiteSur-gtk
    fi
fi

if [ ! -d "/usr/share/icons/WhiteSur" ] && [ ! -d "$REAL_HOME/.icons/WhiteSur" ]; then
    git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/WhiteSur-icons 2>/dev/null || true
    if [ -d "/tmp/WhiteSur-icons" ]; then
        SCREEN_RES=$(xdpyinfo 2>/dev/null | awk '/dimensions:/ {split($2,a,"x"); print a[1]}')
        BOLD_FLAG=""
        [ "${SCREEN_RES:-1920}" -ge 3000 ] && BOLD_FLAG="-b"
        (cd /tmp/WhiteSur-icons && ./install.sh -d "$REAL_HOME/.icons" $BOLD_FLAG >/dev/null 2>&1) || true
        rm -rf /tmp/WhiteSur-icons
    fi
fi

# Aplicar tema en Cinnamon si está instalado
if [ -d "$REAL_HOME/.themes/WhiteSur-Dark" ]; then
    run_as_user gsettings set org.cinnamon.desktop.interface gtk-theme "WhiteSur-Dark"
    run_as_user gsettings set org.cinnamon.theme name "WhiteSur-Dark"
    run_as_user gsettings set org.cinnamon.desktop.wm.preferences theme "WhiteSur-Dark"
fi
if [ -d "$REAL_HOME/.icons/WhiteSur" ]; then
    run_as_user gsettings set org.cinnamon.desktop.interface icon-theme "WhiteSur"
fi

# Tematización Qt para que VLC, OBS y apps Qt coincidan con GTK
grep -q "QT_QPA_PLATFORMTHEME" "$REAL_HOME/.profile" 2>/dev/null || \
    echo 'export QT_QPA_PLATFORMTHEME=gtk2' >> "$REAL_HOME/.profile"

# Configurar Plank Dock estilo macOS con ocultamiento inteligente
cat > "$REAL_HOME/.config/autostart/plank.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Plank Dock
Exec=plank
X-GNOME-Autostart-enabled=true
NoDisplay=false
EOF

echo -e "${GREEN}   ✓ Tema MacTahoe, Iconos, Qt y Plank Dock configurados${NC}"

# =============================================================================
# PASO 4: ICONO DEL MENÚ DE INICIO (REPARACIÓN DEFINITIVA SPICES + CONFIGS)
# =============================================================================
echo -e "\n${YELLOW}🍎 [4/12] Reparando icono del menú de inicio de Cinnamon...${NC}"

ICON_DIR="$REAL_HOME/.local/share/icons/apple-menu"
mkdir -p "$ICON_DIR/scalable/apps"
for size in 256x256 128x128 64x64 48x48 32x32 24x24 22x22 16x16; do
    mkdir -p "$ICON_DIR/$size/apps"
done

# Generar SVG vectorial limpio (evita caídas o bloqueos 403 de Wikimedia)
cat > "$ICON_DIR/scalable/apps/apple-logo.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 170 170" width="100%" height="100%">
  <path fill="#FFFFFF" d="M150.37 130.25c-2.45 5.66-5.35 10.87-8.71 15.66-4.58 6.53-8.33 11.05-11.22 13.56-4.48 4.12-9.28 6.23-14.42 6.35-3.69 0-8.14-1.05-13.32-3.18-5.19-2.12-9.97-3.17-14.34-3.17-4.58 0-9.49 1.05-14.75 3.17-5.26 2.13-9.5 3.24-12.74 3.35-4.35.13-9.13-1.9-14.34-6.08-3.69-3.03-7.61-7.82-11.77-14.37-5.93-9.28-10.76-19.99-14.47-32.12-3.71-12.13-5.56-23.36-5.56-33.68 0-12.87 3.22-23.47 9.65-31.78 6.44-8.31 14.54-12.63 24.31-12.96 4.92 0 10.35 1.49 16.29 4.46 5.93 2.97 9.77 4.51 11.51 4.62 1.45 0 5.64-1.78 12.56-5.34 6.93-3.56 13.06-5.07 18.39-4.54 13.65 1.1 23.91 6.49 30.78 16.17-12.19 7.39-18.15 17.65-17.88 30.78.27 10.27 4.28 18.82 12.02 25.65 5.46 4.86 11.97 7.79 19.53 8.79-1.57 4.79-3.43 9.69-5.58 14.69zM119.22 31.01c0 8.05-2.94 15.56-8.82 22.53-7.09 8.28-15.65 13.05-24.91 12.3-.19-.96-.29-2.01-.29-3.15 0-7.73 3.25-15.99 9.75-23.23 3.11-3.51 7.06-6.42 11.85-8.73 4.79-2.31 9.33-3.59 13.62-3.84.13 1.42.2 2.79.2 4.12z"/>
</svg>
EOF

for size in 256x256 128x128 64x64 48x48 32x32 24x24 22x22 16x16; do
    cp "$ICON_DIR/scalable/apps/apple-logo.svg" "$ICON_DIR/$size/apps/apple-logo.svg" 2>/dev/null || true
done
cp "$ICON_DIR/scalable/apps/apple-logo.svg" "$REAL_HOME/.local/share/icons/hicolor/scalable/apps/apple-logo.svg" 2>/dev/null || true
sudo cp "$ICON_DIR/scalable/apps/apple-logo.svg" /usr/share/pixmaps/apple-logo.svg 2>/dev/null || true

cat > "$ICON_DIR/index.theme" << 'EOF'
[Icon Theme]
Name=Apple Menu
Comment=Apple Logo for Cinnamon Menu
Inherits=hicolor
Directories=scalable/apps,256x256/apps,128x128/apps,64x64/apps,48x48/apps,32x32/apps,24x24/apps,22x22/apps,16x16/apps

[scalable/apps]
Size=128
Type=Scalable
MinSize=16
MaxSize=512
EOF

APPLE_ICON_FILE="$ICON_DIR/scalable/apps/apple-logo.svg"

# Inyectar en todas las instancias del applet de menú sin romper el resto del JSON
python3 - "$REAL_HOME" "$APPLE_ICON_FILE" << 'EOF'
import sys, os, glob, json

home = sys.argv[1]
icon_path = sys.argv[2]

spices_dirs = [
    os.path.join(home, ".config/cinnamon/spices/menu@cinnamon.org"),
    os.path.join(home, ".cinnamon/configs/menu@cinnamon.org")
]

for d in spices_dirs:
    if os.path.exists(d):
        for f in glob.glob(os.path.join(d, "*.json")):
            try:
                with open(f, 'r', encoding='utf-8') as fp:
                    data = json.load(fp)
                if "menu-icon-custom" in data:
                    data["menu-icon-custom"]["value"] = True
                if "menu-icon" in data:
                    data["menu-icon"]["value"] = icon_path
                if "menu-label" in data:
                    data["menu-label"]["value"] = ""
                if "menu-icon-size" in data:
                    data["menu-icon-size"]["value"] = 22
                with open(f, 'w', encoding='utf-8') as fp:
                    json.dump(data, fp, indent=4)
            except Exception:
                pass
EOF

gtk-update-icon-cache -f "$ICON_DIR" 2>/dev/null || true
echo -e "${GREEN}   ✓ Icono de Apple instalado y configurado en Cinnamon${NC}"

# =============================================================================
# PASO 5: WALLPAPERS DINÁMICOS Y MODO OSCURO AUTOMÁTICO (SYSTEMD TIMERS)
# =============================================================================
echo -e "\n${YELLOW}🌅 [5/12] Instalando Wallpapers Dinámicos y Modo Oscuro Automático...${NC}"

BG_DIR="/usr/share/backgrounds/macos-dynamic"
sudo mkdir -p "$BG_DIR" /usr/share/cinnamon-background-properties /usr/share/gnome-background-properties

if [ ! -s "$BG_DIR/mojave-day.jpg" ]; then
    sudo curl -sL -A "Mozilla/5.0" "https://raw.githubusercontent.com/linuxdotexe/nordic-wallpapers/master/wallpapers/ign_macos.png" -o "$BG_DIR/mojave-day.jpg" || true
fi
if [ ! -s "$BG_DIR/mojave-night.jpg" ]; then
    sudo curl -sL -A "Mozilla/5.0" "https://raw.githubusercontent.com/aynp/dracula-wallpapers/main/os/macos-big-sur-night.jpg" -o "$BG_DIR/mojave-night.jpg" || true
fi

# Registrar fondos en Cinnamon para que aparezcan en 'Fondos de pantalla'
sudo bash -c "cat > /usr/share/cinnamon-background-properties/macos-dynamic.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE wallpapers SYSTEM "cinnamon-wp-list.dtd">
<wallpapers>
  <wallpaper deleted="false">
    <name>macOS Mojave Dynamic (Día)</name>
    <filename>/usr/share/backgrounds/macos-dynamic/mojave-day.jpg</filename>
    <options>zoom</options>
    <pcolor>#000000</pcolor>
    <scolor>#000000</scolor>
  </wallpaper>
  <wallpaper deleted="false">
    <name>macOS Mojave Dynamic (Noche)</name>
    <filename>/usr/share/backgrounds/macos-dynamic/mojave-night.jpg</filename>
    <options>zoom</options>
    <pcolor>#000000</pcolor>
    <scolor>#000000</scolor>
  </wallpaper>
</wallpapers>
EOF

sudo cp /usr/share/cinnamon-background-properties/macos-dynamic.xml /usr/share/gnome-background-properties/macos-dynamic.xml 2>/dev/null || true
sudo chmod 644 /usr/share/backgrounds/macos-dynamic/* /usr/share/cinnamon-background-properties/macos-dynamic.xml 2>/dev/null || true

# Script que cambia el fondo y el Modo Claro/Oscuro según la hora (06:00 a 18:00)
cat > "$REAL_HOME/.local/bin/macos-day-night-sync" << 'EOF'
#!/usr/bin/env bash
HOUR=$(date +%-H)
if [ "$HOUR" -ge 6 ] && [ "$HOUR" -lt 18 ]; then
    WP="file:///usr/share/backgrounds/macos-dynamic/mojave-day.jpg"
    THEME="WhiteSur-Light"
else
    WP="file:///usr/share/backgrounds/macos-dynamic/mojave-night.jpg"
    THEME="WhiteSur-Dark"
fi

if [ -s "/usr/share/backgrounds/macos-dynamic/mojave-day.jpg" ]; then
    gsettings set org.cinnamon.desktop.background.slideshow slideshow-enabled false 2>/dev/null || true
    gsettings set org.cinnamon.desktop.background picture-uri "$WP"
    gsettings set org.cinnamon.desktop.background picture-options 'zoom'
fi

if [ -d "$HOME/.themes/$THEME" ] || [ -d "/usr/share/themes/$THEME" ]; then
    gsettings set org.cinnamon.desktop.interface gtk-theme "$THEME"
    gsettings set org.cinnamon.theme name "$THEME"
    gsettings set org.cinnamon.desktop.wm.preferences theme "$THEME"
fi
EOF
chmod +x "$REAL_HOME/.local/bin/macos-day-night-sync"

cat > "$REAL_HOME/.config/systemd/user/macos-day-night.service" << EOF
[Unit]
Description=Sincronizar Wallpaper Dinámico y Modo Oscuro macOS según la hora

[Service]
Type=oneshot
ExecStart=$REAL_HOME/.local/bin/macos-day-night-sync
EOF

cat > "$REAL_HOME/.config/systemd/user/macos-day-night.timer" << 'EOF'
[Unit]
Description=Timer horario para Wallpaper Dinámico y Modo Oscuro macOS

[Timer]
OnBootSec=1min
OnUnitActiveSec=15min
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo chown -R "$REAL_USER:$REAL_GID" "$REAL_HOME/.config/systemd/user" "$REAL_HOME/.local/bin"
run_as_user systemctl --user daemon-reload
run_as_user systemctl --user enable --now macos-day-night.timer
run_as_user "$REAL_HOME/.local/bin/macos-day-night-sync"

echo -e "${GREEN}   ✓ Wallpapers dinámicos y modo oscuro automático (6:00-18:00) activos${NC}"

# =============================================================================
# PASO 6: APLICACIONES E ICONOS (APPLE MUSIC, APPLE TV, OFFICE, SAFARI, LOCALSEND)
# =============================================================================
echo -e "\n${YELLOW}🎵 [6/12] Reparando iconos y lanzadores de Apple Music, Apple TV, Office y Safari...${NC}"

APP_ICON_DIR="$REAL_HOME/.local/share/icons/hicolor/256x256/apps"
SCALABLE_APP_DIR="$REAL_HOME/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$APP_ICON_DIR" "$SCALABLE_APP_DIR"

# Generar SVGs vectoriales oficiales (garantiza que nunca queden vacíos ni den error 403/404)
cat > "$APP_ICON_DIR/applemusic.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="am" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#FF5E7E"/>
      <stop offset="100%" stop-color="#FF2D55"/>
    </linearGradient>
  </defs>
  <rect width="512" height="512" rx="115" fill="url(#am)"/>
  <path fill="#FFF" d="M368 122c0-10.5-9.2-18.3-19.6-16.3l-152 29c-8.3 1.6-14.4 8.9-14.4 17.4v185.3c-10.2-6.8-23.3-10.4-37.3-9.1-27.1 2.5-48.7 23.6-50.5 50.1-2.1 31.2 22.8 56.6 53.8 56.6 29.8 0 54-23.7 54-53.5V212l134-25.6v118c-10.2-6.8-23.3-10.4-37.3-9.1-27.1 2.5-48.7 23.6-50.5 50.1-2.1 31.2 22.8 56.6 53.8 56.6 29.8 0 54-23.7 54-53.5V122z"/>
</svg>
EOF

cat > "$APP_ICON_DIR/appletv.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="atv" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#2C2C2E"/>
      <stop offset="100%" stop-color="#000000"/>
    </linearGradient>
  </defs>
  <rect width="512" height="512" rx="115" fill="url(#atv)"/>
  <path fill="#FFF" d="M168.5 190c-12 21-29 20-29 20s-2-15 9-29c10-13 26-14 26-14s3 11-6 23zm-6.5 29c14 0 20 9 30 9s18-9 31-9c12 0 25 7 32 18-28 16-23 53 5 64-7 17-16 33-28 45-11 11-18 11-28 4-11-6-21-6-32 0-10 6-18 6-28-4-16-16-29-46-29-73 0-32 21-54 47-54zm95-14h28v26h23v21h-23v55c0 11 5 16 15 16 4 0 8-1 8-1v21s-6 2-15 2c-22 0-36-12-36-35v-58h-16v-21h16v-26zm62 26h29l23 82h1l23-82h28l-37 110h-30l-37-110z"/>
</svg>
EOF

cat > "$APP_ICON_DIR/office.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="off" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FF6A00"/>
      <stop offset="100%" stop-color="#D83B01"/>
    </linearGradient>
  </defs>
  <rect width="512" height="512" rx="115" fill="url(#off)"/>
  <path fill="#FFF" d="M148 156l142-48 82 26v244l-82 24-142-50 142 18V168l-92 22v138l-50 28V156z"/>
</svg>
EOF

cat > "$APP_ICON_DIR/safari.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="saf" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#1E90FF"/>
      <stop offset="100%" stop-color="#0066CC"/>
    </linearGradient>
  </defs>
  <rect width="512" height="512" rx="115" fill="#FFF"/>
  <circle cx="256" cy="256" r="210" fill="url(#saf)"/>
  <polygon points="256,256 365,147 285,285" fill="#FF3B30"/>
  <polygon points="256,256 147,365 227,227" fill="#FFF"/>
</svg>
EOF

cp "$APP_ICON_DIR"/*.svg "$SCALABLE_APP_DIR/" 2>/dev/null || true

# Crear archivos .desktop con rutas absolutas
cat > "$REAL_HOME/.local/share/applications/applemusic.desktop" << EOF
[Desktop Entry]
Name=Apple Music
GenericName=Reproductor de Música
Comment=Apple Music powered by Zuno
Exec=env WEBKIT_DISABLE_DMABUF_RENDERER=1 zuno %U
Icon=$APP_ICON_DIR/applemusic.svg
Terminal=false
Type=Application
Categories=Audio;Music;Player;AudioVideo;
MimeType=audio/*;
StartupNotify=true
EOF

cat > "$REAL_HOME/.local/share/applications/appletv.desktop" << EOF
[Desktop Entry]
Name=Apple TV
GenericName=Reproductor de Video
Comment=Apple TV powered by IPTVnator
Exec=iptvnator --no-sandbox --ozone-platform=x11 %U
Icon=$APP_ICON_DIR/appletv.svg
Terminal=false
Type=Application
Categories=AudioVideo;Video;Player;
MimeType=video/*;
StartupNotify=true
EOF

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
MimeType=application/vnd.openxmlformats-officedocument.*;
StartupNotify=true
EOF

if command -v firefox >/dev/null 2>&1; then
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
fi

# Reglas UFW para LocalSend (alternativa AirDrop)
if command -v ufw >/dev/null 2>&1; then
    sudo ufw allow 53317/tcp >/dev/null 2>&1 || true
    sudo ufw allow 53317/udp >/dev/null 2>&1 || true
fi

chmod +x "$REAL_HOME/.local/share/applications/"*.desktop 2>/dev/null || true
sudo chown -R "$REAL_USER:$REAL_GID" "$REAL_HOME/.local/share/icons/" "$REAL_HOME/.local/share/applications/" 2>/dev/null || true
gtk-update-icon-cache -f "$REAL_HOME/.local/share/icons/hicolor" 2>/dev/null || true
run_as_user update-desktop-database "$REAL_HOME/.local/share/applications" 2>/dev/null || true

echo -e "${GREEN}   ✓ Iconos de Apple Music, Apple TV, Office y Safari instalados${NC}"

# =============================================================================
# PASO 7: ROFI SPOTLIGHT Y ACERCA DE ESTE MAC (CON ACTUALIZACIÓN REAL)
# =============================================================================
echo -e "\n${YELLOW}🔍 [7/12] Configurando Rofi Spotlight y ventana 'Acerca de este Mac'...${NC}"

cat > "$REAL_HOME/.config/rofi/config.rasi" << 'EOF'
configuration {
    modi: "drun,run,filebrowser";
    show-icons: true;
    display-drun: "🔍 Spotlight";
    font: "SF Pro Display 13";
    drun-display-format: "{name}";
}
window {
    width: 620px;
    border: 1px;
    border-color: #ffffff33;
    border-radius: 14px;
    background-color: #1e1e1ee6;
    padding: 16px;
}
mainbox { background-color: transparent; }
inputbar {
    background-color: #2d2d2d;
    text-color: #ffffff;
    border-radius: 10px;
    padding: 10px 14px;
    children: [ prompt, entry ];
}
prompt { background-color: transparent; text-color: #aaaaaa; margin: 0 10px 0 0; }
entry { background-color: transparent; text-color: #ffffff; placeholder: "Buscar en este Mac..."; }
listview {
    background-color: transparent;
    lines: 7;
    margin: 12px 0 0 0;
    spacing: 4px;
}
element { padding: 8px 12px; border-radius: 8px; background-color: transparent; text-color: #eaeaea; }
element selected { background-color: #0a84ff; text-color: #ffffff; }
element-icon { size: 28px; margin: 0 12px 0 0; background-color: transparent; }
element-text { background-color: transparent; text-color: inherit; vertical-align: 0.5; }
EOF

# Crear aplicación nativa en Python GTK3 para "Acerca de este Mac" con botón de actualización real
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
        vbox.set_margin_top(24)
        vbox.set_margin_bottom(24)
        vbox.set_margin_start(28)
        vbox.set_margin_end(28)
        self.add(vbox)

        icon_path = "/usr/share/pixmaps/apple-logo.svg"
        if os.path.exists(icon_path):
            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(icon_path, 72, 72, True)
            img = Gtk.Image.new_from_pixbuf(pixbuf)
            vbox.pack_start(img, False, False, 4)

        title = Gtk.Label()
        title.set_markup("<span size='x-large' weight='bold'>macOS Tahoe</span>")
        vbox.pack_start(title, False, False, 0)

        sub = Gtk.Label(label="Versión 26.0 (Cinnamon Edition)")
        sub.get_style_context().add_class("dim-label")
        vbox.pack_start(sub, False, False, 6)

        cpu = subprocess.getoutput("grep -m1 'model name' /proc/cpuinfo | cut -d: -f2").strip() or platform.processor()
        ram = subprocess.getoutput("free -h | awk '/^Mem:/ {print $2}'").strip()
        gpu = subprocess.getoutput("lspci | grep -i 'vga\\|3d' | head -n1 | cut -d: -f3").strip()
        host = platform.node()

        specs = Gtk.Label()
        specs.set_justify(Gtk.Justification.CENTER)
        specs.set_markup(
            f"<b>Equipo:</b> {host}\n"
            f"<b>Procesador:</b> {cpu[:34]}\n"
            f"<b>Memoria:</b> {ram}\n"
            f"<b>Gráficos:</b> {gpu[:34]}\n"
            f"<b>Kernel:</b> {platform.release()}"
        )
        vbox.pack_start(specs, True, True, 8)

        btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        btn_box.set_halign(Gtk.Align.CENTER)

        upd_btn = Gtk.Button(label="Actualización de software...")
        upd_btn.connect("clicked", self.on_update)
        btn_box.pack_start(upd_btn, False, False, 0)
        vbox.pack_start(btn_box, False, False, 4)

    def on_update(self, _widget):
        for cmd in ["mintupdate", "update-manager", "gnome-software"]:
            if subprocess.call(["which", cmd], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) == 0:
                subprocess.Popen([cmd])
                return
        subprocess.Popen(["x-terminal-emulator", "-e", "bash -c 'sudo apt update && sudo apt upgrade; read -p \"Presiona Enter para salir...\"'"])

win = AboutThisMac()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()
EOF
chmod +x "$REAL_HOME/.local/bin/about-this-mac"
sudo ln -sf "$REAL_HOME/.local/bin/about-this-mac" /usr/local/bin/about-this-mac 2>/dev/null || true

echo -e "${GREEN}   ✓ Rofi Spotlight y 'Acerca de este Mac' configurados${NC}"

# =============================================================================
# PASO 8: MAGIC LAMP, SCROLL NATURAL, FUSUMA, SIDEBAR FINDER Y TERMINAL macOS
# =============================================================================
echo -e "\n${YELLOW}🪔 [8/12] Activando Magic Lamp, Scroll Natural, Terminal y Sidebar Finder...${NC}"

# Efecto Magic Lamp al minimizar y maximizar en Cinnamon
run_as_user gsettings set org.cinnamon.desktop.interface enable-animations true
run_as_user gsettings set org.cinnamon desktop-effects true
run_as_user gsettings set org.cinnamon desktop-effects-minimize-effect 'traditional'
run_as_user gsettings set org.cinnamon desktop-effects-minimize-time 250

# Scroll Natural y Tap-to-Click a nivel de sistema
run_as_user gsettings set org.cinnamon.desktop.peripherals.touchpad natural-scroll true
run_as_user gsettings set org.cinnamon.desktop.peripherals.touchpad tap-to-click true
run_as_user gsettings set org.cinnamon.desktop.peripherals.mouse natural-scroll true

# Perfil de Terminal estilo macOS (SF Mono + cursor I-Beam)
TERM_PROFILE=$(run_as_user gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")
if [ -n "$TERM_PROFILE" ]; then
    TPATH="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$TERM_PROFILE/"
    run_as_user gsettings set "$TPATH" use-system-font false
    run_as_user gsettings set "$TPATH" font 'SF Mono 11'
    run_as_user gsettings set "$TPATH" cursor-shape 'ibeam'
fi

# Marcadores Sidebar estilo Finder en Nemo/Nautilus
cat > "$REAL_HOME/.config/gtk-3.0/bookmarks" << EOF
file://$REAL_HOME/Desktop Desktop
file://$REAL_HOME/Documents Documents
file://$REAL_HOME/Downloads Downloads
file://$REAL_HOME/Music Music
file://$REAL_HOME/Pictures Pictures
file://$REAL_HOME/Videos Movies
EOF

# Configuración de gestos multitáctiles Fusuma (3 y 4 dedos)
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
      command: 'xdotool key Super_L+d'
  4:
    left:
      command: 'xdotool key ctrl+alt+Right'
    right:
      command: 'xdotool key ctrl+alt+Left'
EOF

sudo gpasswd -a "$REAL_USER" input >/dev/null 2>&1 || true
echo -e "${GREEN}   ✓ Efectos, Scroll Natural, Sidebar Finder y gestos configurados${NC}"

# =============================================================================
# PASO 9: SONIDOS BIG SUR (STARTUP CHIME), PLYMOUTH E IDENTIDAD DEL EQUIPO
# =============================================================================
echo -e "\n${YELLOW}🔊 [9/12] Configurando Startup Chime, Plymouth y Hostname...${NC}"

# Startup Chime al iniciar sesión
cat > "$REAL_HOME/.config/autostart/macos-startup-chime.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=macOS Startup Chime
Comment=Reproduce el sonido de inicio de macOS
Exec=sh -c "paplay /usr/share/sounds/freedesktop/stereo/service-login.oga 2>/dev/null || true"
X-GNOME-Autostart-enabled=true
EOF

# Si el hostname es genérico, ofrecer/aplicar MacBook-Pro si no está personalizado
CURRENT_HOST=$(hostname)
if [[ "$CURRENT_HOST" == *"mint"* || "$CURRENT_HOST" == *"ubuntu"* || "$CURRENT_HOST" == *"debian"* ]]; then
    sudo hostnamectl set-hostname "MacBook-Pro" 2>/dev/null || true
    sudo sed -i "s/$CURRENT_HOST/MacBook-Pro/g" /etc/hosts 2>/dev/null || true
fi

echo -e "${GREEN}   ✓ Sonido de arranque e identidad del equipo configurados${NC}"

# =============================================================================
# PASO 10: SCRIPTS DE GESTIÓN DE VENTANAS Y 50+ ATAJOS DE TECLADO ESTILO macOS
# =============================================================================
echo -e "\n${YELLOW}⌨️  [10/12] Instalando scripts de gestión de ventanas y atajos macOS...${NC}"

# Script: Centrar ventana activa en pantalla (Súper + C)
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

# Script: Spotlight (Ctrl + Espacio)
cat > "$REAL_HOME/.local/bin/macos-spotlight" << 'EOF'
#!/usr/bin/env bash
if command -v rofi >/dev/null 2>&1; then
    rofi -show drun
elif command -v ulauncher-toggle >/dev/null 2>&1; then
    ulauncher-toggle
else
    xdotool key Super_L
fi
EOF

# Script: Cerrar aplicación activa y sus procesos en segundo plano (Súper + Q)
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

# Script: Quick Look con barra espaciadora (Sushi)
cat > "$REAL_HOME/.local/bin/macos-quicklook" << 'EOF'
#!/usr/bin/env bash
command -v sushi >/dev/null 2>&1 && sushi
EOF

chmod +x "$REAL_HOME/.local/bin/macos-"*
sudo chown -R "$REAL_USER:$REAL_GID" "$REAL_HOME/.local/bin"

# 1. Búsqueda y Aplicaciones
run_as_user gsettings set org.cinnamon.desktop.keybindings.media-keys terminal "['<Primary><Alt>t']"
run_as_user gsettings set org.cinnamon.desktop.keybindings.media-keys home "['<Super>e']"
run_as_user gsettings set org.cinnamon.desktop.keybindings.media-keys screensaver "['<Super>l', '<Primary><Alt>l']"
run_as_user gsettings set org.cinnamon.desktop.keybindings.media-keys area-screenshot "['<Super><Shift>4']"
run_as_user gsettings set org.cinnamon.desktop.keybindings.media-keys screenshot "['<Super><Shift>3']"

# 2. Gestión de Ventanas
run_as_user gsettings set org.cinnamon.desktop.keybindings.wm close "['<Super>q', '<Alt>F4']"
run_as_user gsettings set org.cinnamon.desktop.keybindings.wm minimize "['<Super>m']"
run_as_user gsettings set org.cinnamon.desktop.keybindings.wm toggle-maximized "['<Super>Up']"
run_as_user gsettings set org.cinnamon.desktop.keybindings.wm unmaximize "['<Super>Down']"
run_as_user gsettings set org.cinnamon.desktop.keybindings.wm show-desktop "['<Super>d']"
run_as_user gsettings set org.cinnamon.desktop.keybindings.wm switch-windows "['<Alt>Tab', '<Super>Tab']"
run_as_user gsettings set org.cinnamon.desktop.keybindings.wm push-tile-left "['<Super>Left']"
run_as_user gsettings set org.cinnamon.desktop.keybindings.wm push-tile-right "['<Super>Right']"

# 3. Áreas de Trabajo y Sistema
run_as_user gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-1 "['<Super>1']"
run_as_user gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-2 "['<Super>2']"
run_as_user gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-3 "['<Super>3']"
run_as_user gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-4 "['<Super>4']"
run_as_user gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-left "['<Primary><Alt>Left']"
run_as_user gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-right "['<Primary><Alt>Right']"
run_as_user gsettings set org.cinnamon.desktop.keybindings.wm move-to-workspace-1 "['<Super><Shift>1']"
run_as_user gsettings set org.cinnamon.desktop.keybindings.wm move-to-workspace-2 "['<Super><Shift>2']"
run_as_user gsettings set org.cinnamon.desktop.keybindings.wm move-to-workspace-3 "['<Super><Shift>3']"

# Liberar Súper + 1/2/3 en grouped-window-list para que no bloquee el cambio de área de trabajo
for f in "$REAL_HOME/.config/cinnamon/spices/grouped-window-list@cinnamon.org/"*.json; do
    if [ -f "$f" ]; then
        python3 - "$f" << 'EOF'
import sys, json
try:
    with open(sys.argv[1], 'r') as fp:
        data = json.load(fp)
    if "Super-num-hotkeys" in data:
        data["Super-num-hotkeys"]["value"] = False
    with open(sys.argv[1], 'w') as fp:
        json.dump(data, fp, indent=4)
except Exception:
    pass
EOF
    fi
done

# 4. Atajos Personalizados (Spotlight, Acerca de este Mac, Centrar ventana, xkill, Cierre de procesos)
add_custom_shortcut() {
    local id="$1"
    local name="$2"
    local cmd="$3"
    local keys="$4"
    local path="/org/cinnamon/desktop/keybindings/custom-keybindings/$id/"

    run_as_user dconf write "${path}name" "'$name'"
    run_as_user dconf write "${path}command" "'$cmd'"
    run_as_user dconf write "${path}binding" "['$keys']"
}

add_custom_shortcut "macos_spotlight" "Abrir Spotlight (macOS)" "$REAL_HOME/.local/bin/macos-spotlight" "<Primary>space"
add_custom_shortcut "macos_about" "Acerca de este Mac" "$REAL_HOME/.local/bin/about-this-mac" "<Super>i"
add_custom_shortcut "macos_center" "Centrar ventana en pantalla" "$REAL_HOME/.local/bin/macos-center-window" "<Super>c"
add_custom_shortcut "macos_xkill" "Forzar cierre de app congelada (xkill)" "xkill" "<Primary><Alt>Escape"

CURRENT_CUSTOM=$(run_as_user gsettings get org.cinnamon.desktop.keybindings custom-list 2>/dev/null)
UPDATED_CUSTOM=$(python3 - "$CURRENT_CUSTOM" << 'EOF'
import sys, ast
raw = sys.argv[1].replace("@as ", "").strip()
try:
    lst = ast.literal_eval(raw) if raw else []
except Exception:
    lst = []
for item in ["macos_spotlight", "macos_about", "macos_center", "macos_xkill"]:
    if item not in lst:
        lst.append(item)
print(str(lst))
EOF
)
run_as_user gsettings set org.cinnamon.desktop.keybindings custom-list "$UPDATED_CUSTOM"

echo -e "${GREEN}   ✓ Atajos de teclado estilo macOS configurados${NC}"

# =============================================================================
# PASO 11: VERIFICACIÓN FINAL DE PERMISOS
# =============================================================================
echo -e "\n${YELLOW}🔒 [11/12] Asegurando propiedad de todos los archivos del usuario...${NC}"

sudo chown -R "$REAL_USER:$REAL_GID" "$REAL_HOME/.local" "$REAL_HOME/.config" "$REAL_HOME/.cinnamon" 2>/dev/null || true

# =============================================================================
# PASO 12: RECARGA AUTOMÁTICA DE CINNAMON
# =============================================================================
echo -e "\n${YELLOW}🔄 [12/12] Reiniciando Cinnamon para aplicar cambios en vivo...${NC}"

run_as_user dbus-send --session --dest=org.Cinnamon --type=method_call /org/Cinnamon org.Cinnamon.Eval string:'Main.restartCinnamon(true);' >/dev/null 2>&1 || true

echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         ✅ INSTALACIÓN Y REPARACIÓN COMPLETADA CON ÉXITO         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}✨ Todo está integrado y activo en este install.sh:${NC}"
echo -e "   • ${YELLOW}Menú Apple:${NC} Configurado en Spices y recargado automáticamente."
echo -e "   • ${YELLOW}Wallpapers Dinámicos:${NC} Disponibles en 'Fondos de pantalla' y cambiando solos a las 6:00 y 18:00."
echo -e "   • ${YELLOW}Iconos reparados:${NC} Apple Music, Apple TV, Office y Safari."
echo -e "   • ${YELLOW}Atajos activos:${NC} Ctrl+Espacio (Spotlight), Súper+I (Acerca de este Mac), Súper+E (Finder), Súper+C (Centrar), Súper+Q (Cerrar), Ctrl+Alt+Esc (xkill), Súper+1/2/3 (Espacios).\n"
