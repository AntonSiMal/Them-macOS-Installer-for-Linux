#!/bin/bash

# =============================================================================
# macOS Tahoe Uninstaller - Restauración del Sistema (Versión Ultimate)
# Elimina todos los componentes instalados y restablece la configuración por defecto
# =============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# =============================================================================
# DETECCIÓN DEL USUARIO REAL (CRÍTICO para evitar borrar /root)
# =============================================================================
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(eval echo "~$SUDO_USER")
    REAL_UID=$(id -u "$SUDO_USER")
else
    REAL_USER="$USER"
    REAL_HOME="$HOME"
    REAL_UID=$(id -u)
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
# DETECCIÓN DE MODO AUTOMÁTICO (Para Rollback de emergencia)
# =============================================================================
AUTO_CLEANUP=false
if [[ "$1" == "--auto" || "$1" == "--force" ]]; then
    AUTO_CLEANUP=true
fi

echo -e "${RED}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║   ⚠️  macOS Tahoe Uninstaller - Restauración del Sistema  ║${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}ADVERTENCIA:${NC}"
echo -e "Este script eliminará todos los temas, iconos, fuentes, sonidos,"
echo -e "extensiones, scripts, aplicaciones personalizadas y configuraciones"
echo -e "instalados por el instalador. Tu escritorio volverá a su estado original."
echo ""

if [ "$AUTO_CLEANUP" = false ]; then
    read -p "¿Estás seguro de que deseas continuar? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${BLUE}Operación cancelada.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  MODO AUTOMÁTICO: Ejecutando limpieza de emergencia...${NC}"
    sleep 2
fi

echo -e "${CYAN}Iniciando proceso de desinstalación...${NC}"
echo ""

# =============================================================================
# 1. DETECCIÓN DEL ENTORNO
# =============================================================================
DESKTOP_ENV=$(echo "${XDG_CURRENT_DESKTOP:-unknown}" | tr '[:upper:]' '[:lower:]')
DISTRO=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')
fi

IS_GNOME=false; IS_CINNAMON=false
[[ "$DESKTOP_ENV" == *"gnome"* ]] || [[ "$DISTRO" == *"zorin"* ]] && IS_GNOME=true
[[ "$DESKTOP_ENV" == *"cinnamon"* ]] || [[ "$DISTRO" == *"mint"* && "$DESKTOP_ENV" != *"xfce"* ]] && IS_CINNAMON=true

# =============================================================================
# 2. ELIMINAR ARCHIVOS, SCRIPTS Y CONFIGURACIONES
# =============================================================================
echo -e "${YELLOW}🗑️  [1/9] Eliminando archivos, scripts y configuraciones...${NC}"

# 2.1. Scripts auxiliares y servicios
rm -f "$REAL_HOME/.local/bin/about-this-mac.sh"
rm -f "$REAL_HOME/.local/bin/auto-dark-mode.sh"
rm -f "$REAL_HOME/.config/systemd/user/auto-dark-mode.service"
rm -f "$REAL_HOME/.config/systemd/user/auto-dark-mode.timer"
run_as_user systemctl --user disable --now auto-dark-mode.timer 2>/dev/null || true
run_as_user systemctl --user daemon-reload 2>/dev/null || true

rm -f "$REAL_HOME/.config/autostart/mac-startup-chime.desktop"
rm -f "$REAL_HOME/.config/gtk-3.0/bookmarks"

# 2.2. Iconos de escritorio creados
rm -f "$REAL_HOME/Desktop/Trash.desktop"
rm -f "$REAL_HOME/Desktop/Macintosh HD.desktop"
rm -f "$REAL_HOME/Desktop/$REAL_USER.desktop"

# 2.3. Fuentes, Temas, Iconos y Sonidos
rm -rf "$REAL_HOME/.local/share/fonts/SF"* "$REAL_HOME/.local/share/fonts/NewYork"*
fc-cache -f > /dev/null 2>&1

rm -rf "$REAL_HOME/.themes/MacTahoe"* "$REAL_HOME/.local/share/themes/MacTahoe"*
rm -rf "$REAL_HOME/.icons/MacTahoe"* "$REAL_HOME/.local/share/icons/MacTahoe"*
rm -rf "$REAL_HOME/.local/share/sounds/bigsur"

# 2.4. Wallpapers
sudo rm -rf /usr/share/dynamicwallpapers/mojave-solar /usr/share/dynamicwallpapers/mojave-timed /usr/share/backgrounds/macOS 2>/dev/null || true
rm -rf "$REAL_HOME/.local/share/backgrounds/Sonoma"*

# 2.5. Rofi, Plank y Utilidades
rm -rf "$REAL_HOME/.local/share/rofi-spotlight"
rm -f "$REAL_HOME/.local/share/rofi/themes/spotlight.rasi"
rm -f "$REAL_HOME/.local/bin/rofi-spotlight-launcher"
rm -f "$REAL_HOME/.local/share/applications/rofi-spotlight.desktop"
rm -f "$REAL_HOME/.local/bin/macos-wm-actions"

rm -rf "$REAL_HOME/.local/share/plank/themes/MacOS-"* "$REAL_HOME/.local/share/plank/themes/elementary-"*
rm -f "$REAL_HOME/.config/autostart/plank.desktop"
pkill plank 2>/dev/null || true

# 2.6. Fusuma y Gestos
run_as_user systemctl --user disable --now fusuma.service 2>/dev/null || true
rm -rf "$REAL_HOME/.config/fusuma"
sudo gem uninstall fusuma -a -x 2>/dev/null || true
sudo gpasswd -d "$REAL_USER" input 2>/dev/null || true

# 2.7. Qt, Quick Look y Portapapeles
sudo sed -i '/QT_QPA_PLATFORMTHEME=qt5ct/d' /etc/environment 2>/dev/null || true
rm -rf "$REAL_HOME/.config/qt5ct"
sudo apt-get remove -y -qq sushi gloobus-preview 2>/dev/null || true
sudo dnf remove -y -q sushi gloobus-preview 2>/dev/null || true
sudo pacman -Rns --noconfirm sushi gloobus-preview 2>/dev/null || true

sudo apt-get remove -y -qq gnome-shell-extension-clipboard-indicator clipit xfce4-clipman-plugin 2>/dev/null || true
sudo dnf remove -y -q gnome-shell-extension-clipboard-indicator clipit xfce4-clipman-plugin 2>/dev/null || true
sudo pacman -Rns --noconfirm gnome-shell-extension-clipboard-indicator clipit xfce4-clipman-plugin 2>/dev/null || true

# 2.8. Fontconfig, Terminal y Directorio de Trabajo
rm -f "$REAL_HOME/.config/fontconfig/fonts.conf"
rm -f "$REAL_HOME/.config/xfce4/terminal/terminalrc"
rm -rf "$REAL_HOME/.macos-theme-setup"
rm -f "$REAL_HOME/.macos-keybindings.md"

# 2.9. Aplicaciones Personalizadas (Safari, Apple Music, LocalSend, Apple TV, Office)
echo -e "${BLUE}      → Limpiando personalizaciones de aplicaciones...${NC}"

# Desinstalar paquetes si fueron instalados vía gestor
sudo apt-get remove -y -qq zuno localsend iptvnator 2>/dev/null || true
sudo dnf remove -y -q zuno localsend iptvnator 2>/dev/null || true
sudo pacman -Rns --noconfirm zuno localsend-bin iptvnator-bin 2>/dev/null || true

# Desinstalar ONLYOFFICE (Office) si fue instalado vía Flatpak
run_as_user flatpak uninstall -y --delete-data org.onlyoffice.desktopeditors 2>/dev/null || true

# Eliminar binarios locales (Fallback de AppImage)
rm -f "$REAL_HOME/.local/bin/zuno"
rm -f "$REAL_HOME/.local/bin/localsend"
rm -f "$REAL_HOME/.local/bin/iptvnator"

# Eliminar lanzadores personalizados
rm -f "$REAL_HOME/.local/share/applications/safari.desktop"
rm -f "$REAL_HOME/.local/share/applications/applemusic.desktop"
rm -f "$REAL_HOME/.local/share/applications/appletv.desktop"
rm -f "$REAL_HOME/.local/share/applications/localsend.desktop"
rm -f "$REAL_HOME/.local/share/applications/office.desktop"

# Eliminar archivos "Hidden=true" que ocultaban los lanzadores originales
rm -f "$REAL_HOME/.local/share/applications/firefox.desktop"
rm -f "$REAL_HOME/.local/share/applications/firefox-esr.desktop"
rm -f "$REAL_HOME/.local/share/applications/org.mozilla.firefox.desktop"
rm -f "$REAL_HOME/.local/share/applications/zuno.desktop"
rm -f "$REAL_HOME/.local/share/applications/com.zuno.desktop.desktop"
rm -f "$REAL_HOME/.local/share/applications/iptvnator.desktop"
rm -f "$REAL_HOME/.local/share/applications/com.github.4gray.iptvnator.desktop"
rm -f "$REAL_HOME/.local/share/applications/org.onlyoffice.desktopeditors.desktop"

# Eliminar iconos personalizados descargados
rm -f "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/safari.svg"
rm -f "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/applemusic.svg"
rm -f "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/appletv.svg"
rm -f "$REAL_HOME/.local/share/icons/hicolor/256x256/apps/office.svg"

# Eliminar configuración de IPTVnator (Apple TV)
rm -rf "$REAL_HOME/.config/iptvnator"

# Limpiar reglas de firewall de LocalSend
if command -v ufw &> /dev/null; then
    sudo ufw delete allow 53317/tcp 2>/dev/null || true
    sudo ufw delete allow 53317/udp 2>/dev/null || true
fi
if command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --remove-port=53317/tcp 2>/dev/null || true
    sudo firewall-cmd --permanent --remove-port=53317/udp 2>/dev/null || true
    sudo firewall-cmd --reload 2>/dev/null || true
fi

echo -e "${GREEN}✅ Archivos, configuraciones y apps personalizadas eliminados.${NC}"
echo ""

# =============================================================================
# 3. RESTAURAR NOMBRE DEL EQUIPO (HOSTNAME)
# =============================================================================
echo -e "${YELLOW}💻 [2/9] Restableciendo nombre del equipo...${NC}"
sudo hostnamectl set-hostname "$REAL_USER" 2>/dev/null || true
echo "$REAL_USER" | sudo tee /etc/hostname > /dev/null 2>/dev/null || true
sudo sed -i "s/127.0.1.1.*/127.0.1.1\t$REAL_USER/g" /etc/hosts 2>/dev/null || true
echo -e "${GREEN}✅ Nombre del equipo restablecido a: $REAL_USER${NC}"
echo ""

# =============================================================================
# 4. RESTAURAR CONFIGURACIÓN DE ESCRITORIO (GNOME)
# =============================================================================
if [ "$IS_GNOME" = true ]; then
    echo -e "${YELLOW}⚙️  [3/9] Restaurando configuración de GNOME...${NC}"
    
    run_as_user gsettings reset org.gnome.desktop.interface gtk-theme
    run_as_user gsettings reset org.gnome.desktop.interface icon-theme
    run_as_user gsettings reset org.gnome.desktop.interface cursor-theme
    run_as_user gsettings reset org.gnome.desktop.interface cursor-size
    run_as_user gsettings reset org.gnome.desktop.interface font-name
    run_as_user gsettings reset org.gnome.desktop.interface monospace-font-name
    run_as_user gsettings reset org.gnome.desktop.interface document-font-name
    run_as_user gsettings reset org.gnome.desktop.wm.preferences titlebar-font
    
    run_as_user gsettings reset org.gnome.desktop.background picture-uri
    run_as_user gsettings reset org.gnome.desktop.background picture-uri-dark
    
    run_as_user gsettings reset org.gnome.desktop.sound theme-name
    run_as_user gsettings reset org.gnome.desktop.peripherals.touchpad natural-scroll
    run_as_user gsettings reset org.gnome.desktop.peripherals.mouse natural-scroll
    
    run_as_user gsettings reset-recursively org.gnome.desktop.wm.keybindings
    run_as_user gsettings reset-recursively org.gnome.settings-daemon.plugins.media-keys
    
    run_as_user gsettings reset org.gnome.desktop.interface enable-animations
    run_as_user gsettings reset org.gnome.mutter center-new-windows
    run_as_user gsettings reset org.gnome.mutter dynamic-workspaces
    
    # Desactivar y eliminar extensiones
    run_as_user gnome-extensions disable liquid-glass@thinkingcoding1231.gmail.com 2>/dev/null || true
    run_as_user gnome-extensions disable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null || true
    run_as_user gnome-extensions disable dash-to-dock@micxgx.gmail.com 2>/dev/null || true
    run_as_user gnome-extensions disable clipboard-indicator@tudmotu.com 2>/dev/null || true
    run_as_user gnome-extensions disable ding@rastersoft.com 2>/dev/null || true
    
    rm -rf "$REAL_HOME/.local/share/gnome-shell/extensions/liquid-glass@thinkingcoding1231.gmail.com"
    rm -rf "$REAL_HOME/.local/share/gnome-shell/extensions/"*magic-lamp*
    
    run_as_user gsettings reset org.gnome.terminal.legacy/default-profile
    
    echo -e "${GREEN}✅ Configuración de GNOME restaurada.${NC}"
    echo ""
fi

# =============================================================================
# 5. RESTAURAR CONFIGURACIÓN DE ESCRITORIO (CINNAMON)
# =============================================================================
if [ "$IS_CINNAMON" = true ]; then
    echo -e "${YELLOW}⚙️  [4/9] Restaurando configuración de Cinnamon...${NC}"
    
    run_as_user gsettings reset org.cinnamon.desktop.interface gtk-theme
    run_as_user gsettings reset org.cinnamon.desktop.interface icon-theme
    run_as_user gsettings reset org.cinnamon.desktop.interface cursor-theme
    run_as_user gsettings reset org.cinnamon.desktop.interface cursor-size
    run_as_user gsettings reset org.cinnamon.desktop.interface font-name
    run_as_user gsettings reset org.cinnamon.desktop.interface monospace-font-name
    run_as_user gsettings reset org.cinnamon.theme name
    run_as_user gsettings reset org.cinnamon.desktop.wm.preferences theme
    run_as_user gsettings reset org.cinnamon.desktop.wm.preferences titlebar-font
    run_as_user gsettings reset org.cinnamon.desktop.wm.preferences enable-hot-corners
    
    run_as_user gsettings reset org.cinnamon.desktop.background picture-uri
    run_as_user gsettings reset org.cinnamon.desktop.background picture-uri-dark
    run_as_user gsettings reset org.cinnamon.desktop.sound theme-name
    run_as_user gsettings reset org.cinnamon.desktop.peripherals.touchpad natural-scroll 2>/dev/null || true
    
    run_as_user gsettings reset-recursively org.cinnamon.desktop.keybindings
    
    run_as_user gsettings reset org.cinnamon.desktop.effects minimize-effect
    run_as_user gsettings reset org.cinnamon.desktop.effects unminimize-effect
    
    run_as_user gsettings reset org.cinnamon panels-enabled
    run_as_user gsettings reset org.cinnamon panel-height
    
    rm -rf "$REAL_HOME/.local/share/cinnamon/extensions/cinnamon-dynamic-wallpaper@TobiZog"
    rm -rf "$REAL_HOME/.local/share/cinnamon/extensions/CinnamonMagicLamp@klangman"
    
    echo -e "${GREEN}✅ Configuración de Cinnamon restaurada.${NC}"
    echo ""
fi

# =============================================================================
# 6. RESTAURAR CONFIGURACIÓN DE ESCRITORIO (XFCE)
# =============================================================================
if [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    echo -e "${YELLOW}⚙️  [5/9] Restaurando configuración de XFCE...${NC}"
    
    run_as_user xfconf-query -c xsettings -p /Net/ThemeName -r 2>/dev/null || true
    run_as_user xfconf-query -c xsettings -p /Net/IconThemeName -r 2>/dev/null || true
    run_as_user xfconf-query -c xsettings -p /Net/CursorThemeName -r 2>/dev/null || true
    run_as_user xfconf-query -c xsettings -p /Gtk/CursorThemeSize -r 2>/dev/null || true
    run_as_user xfconf-query -c xsettings -p /Gtk/FontName -r 2>/dev/null || true
    run_as_user xfconf-query -c xsettings -p /Gtk/MonospaceFontName -r 2>/dev/null || true
    run_as_user xfconf-query -c xsettings -p /Net/SoundThemeName -r 2>/dev/null || true
    
    run_as_user xfconf-query -c xfwm4 -p /general/theme -r 2>/dev/null || true
    run_as_user xfconf-query -c xfwm4 -p /general/title_font -r 2>/dev/null || true
    run_as_user xfconf-query -c xfwm4 -p /general/button_layout -r 2>/dev/null || true
    run_as_user xfconf-query -c xfwm4 -p /general/use_compositing -r 2>/dev/null || true
    run_as_user xfconf-query -c xfwm4 -p /general/workspace_count -r 2>/dev/null || true
    
    for shortcut in "<Super>e" "<Super>a" "<Ctrl><Alt>t" "<Ctrl><Shift>Escape" "<Super>l" "<Ctrl><Alt>Delete" "<Ctrl>space" "<Ctrl><Alt>Escape" "<Ctrl>q" "<Super>c" "<Super>f" "<Super>v" "<Super>r" "<Super>o" "<Super><Ctrl>o" "<Super>i" "<Super><Shift>3" "<Super><Shift>4" "Print" "<Alt>Print" "<Shift>Print"; do
        run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/$shortcut" -r 2>/dev/null || true
    done
    
    run_as_user xfconf-query -c xfce4-notifyd -p /theme -r 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-notifyd -p /notify-location -r 2>/dev/null || true
    
    echo -e "${GREEN}✅ Configuración de XFCE restaurada.${NC}"
    echo ""
fi

# =============================================================================
# 7. RESTAURAR PLYMOUTH (PANTALLA DE ARRANQUE)
# =============================================================================
echo -e "${YELLOW}🖥️  [6/9] Restaurando pantalla de arranque (Plymouth)...${NC}"
if [ -d /usr/share/plymouth/themes/apple-mac-plymouth ]; then
    sudo rm -rf /usr/share/plymouth/themes/apple-mac-plymouth
    sudo update-alternatives --auto default.plymouth 2>/dev/null || true
    command -v update-initramfs &> /dev/null && sudo update-initramfs -u > /dev/null 2>&1 || true
    command -v dracut &> /dev/null && sudo dracut --force > /dev/null 2>&1 || true
    echo -e "${GREEN}✅ Plymouth restaurado.${NC}"
else
    echo -e "${YELLOW}⏭️  Plymouth no fue modificado o no está presente.${NC}"
fi
echo ""

# =============================================================================
# 8. RESTAURAR FIREFOX Y GDM
# =============================================================================
echo -e "${YELLOW}🦊 [7/9] Limpiando configuraciones profundas de Firefox y GDM...${NC}"
rm -rf "$REAL_HOME/.mozilla/firefox/"*.default*/chrome 2>/dev/null || true
rm -rf "$REAL_HOME/.var/app/org.mozilla.firefox/.mozilla/firefox/"*.default*/chrome 2>/dev/null || true

if [ "$IS_GNOME" = true ] && [ -d "$REAL_HOME/.macos-theme-setup/MacTahoe-gtk-theme" ]; then
    ( cd "$REAL_HOME/.macos-theme-setup/MacTahoe-gtk-theme" && sudo ./tweaks.sh -g -r > /dev/null 2>&1 ) || true
fi
echo -e "${GREEN}✅ Limpieza de Firefox/GDM completada.${NC}"
echo ""

# =============================================================================
# 9. LIMPIEZA FINAL DE PAQUETES Y CACHÉ
# =============================================================================
echo -e "${YELLOW}🧹 [8/9] Actualizando caché de escritorios e iconos...${NC}"
run_as_user update-desktop-database "$REAL_HOME/.local/share/applications" 2>/dev/null || true
run_as_user gtk-update-icon-cache -f -t "$REAL_HOME/.local/share/icons/hicolor" 2>/dev/null || true
echo -e "${GREEN}✅ Caché actualizado.${NC}"
echo ""

echo -e "${YELLOW}📦 [9/9] Limpieza de paquetes huérfanos del sistema...${NC}"
if command -v apt-get &> /dev/null; then
    sudo apt-get autoremove -y -qq 2>/dev/null || true
elif command -v dnf &> /dev/null; then
    sudo dnf autoremove -y -q 2>/dev/null || true
elif command -v pacman &> /dev/null; then
    sudo pacman -Rns --noconfirm $(pacman -Qdtq 2>/dev/null) 2>/dev/null || true
fi
echo -e "${GREEN}✅ Limpieza de paquetes completada.${NC}"
echo ""

# =============================================================================
# MENSAJE FINAL
# =============================================================================
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        🎉 ¡DESINSTALACIÓN COMPLETADA CON ÉXITO! 🎉       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Tu sistema ha sido restaurado a su estado original.${NC}"
echo -e "${GREEN}Se han eliminado las personalizaciones de Safari, Apple Music, LocalSend, Apple TV y Office.${NC}"
echo -e "${YELLOW}⚠️  IMPORTANTE: Debes ${RED}reiniciar el equipo${YELLOW} para que todos los cambios${NC}"
echo -e "${YELLOW}   (especialmente Plymouth, nombre del equipo, firewall y configuraciones de sesión) surtan efecto.${NC}"
echo ""

if [ "$IS_GNOME" = true ]; then
    echo -e "${BLUE}Si usas X11 y prefieres no reiniciar, puedes reiniciar GNOME Shell con:${NC}"
    echo -e "   ${CYAN}dbus-send --session --type=method_call --dest=org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Eval string:'Meta.restart(\"Reiniciando...\")'${NC}"
fi
echo ""
