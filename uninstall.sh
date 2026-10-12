#!/bin/bash

# =============================================================================
# macOS Tahoe Uninstaller - Restauración del Sistema
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
# DETECCIÓN DE MODO AUTOMÁTICO (Para Rollback de emergencia desde install.sh)
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
echo -e "extensiones y configuraciones instalados por el instalador de macOS Tahoe."
echo -e "Tu escritorio volverá a su estado original (temas por defecto)."
echo ""

# Solo pedir confirmación si NO se está ejecutando en modo automático
if [ "$AUTO_CLEANUP" = false ]; then
    read -p "¿Estás seguro de que deseas continuar? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${BLUE}Operación cancelada.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  MODO AUTOMÁTICO: Ejecutando limpieza de emergencia sin confirmación...${NC}"
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

IS_GNOME=false
IS_CINNAMON=false
[[ "$DESKTOP_ENV" == *"gnome"* ]] || [[ "$DISTRO" == *"zorin"* ]] && IS_GNOME=true
[[ "$DESKTOP_ENV" == *"cinnamon"* ]] || [[ "$DISTRO" == *"mint"* && "$DESKTOP_ENV" != *"xfce"* ]] && IS_CINNAMON=true

# =============================================================================
# 2. ELIMINAR ARCHIVOS, CONFIGURACIONES Y PAQUETES ESPECÍFICOS
# =============================================================================
echo -e "${YELLOW}🗑️  [1/8] Eliminando archivos y configuraciones de macOS...${NC}"

# Fuentes
rm -rf ~/.local/share/fonts/SF* ~/.local/share/fonts/NewYork*
fc-cache -f > /dev/null 2>&1

# Temas, Iconos y Cursores
rm -rf ~/.themes/MacTahoe* ~/.local/share/themes/MacTahoe*
rm -rf ~/.icons/MacTahoe* ~/.local/share/icons/MacTahoe*

# Sonidos
rm -rf ~/.local/share/sounds/bigsur

# Wallpapers
sudo rm -rf /usr/share/dynamicwallpapers/mojave-solar /usr/share/dynamicwallpapers/mojave-timed /usr/share/backgrounds/macOS 2>/dev/null || true
rm -rf ~/.local/share/backgrounds/Sonoma*

# Rofi Spotlight y Scripts
rm -rf ~/.local/share/rofi-spotlight
rm -f ~/.local/share/rofi/themes/spotlight.rasi
rm -f ~/.local/bin/rofi-spotlight-launcher
rm -f ~/.local/share/applications/rofi-spotlight.desktop
rm -f ~/.local/bin/macos-wm-actions

# Plank
rm -rf ~/.local/share/plank/themes/MacOS-* ~/.local/share/plank/themes/elementary-*
rm -f ~/.config/autostart/plank.desktop
pkill plank 2>/dev/null || true

# Fusuma (Gestos y Arrastre 3 dedos)
systemctl --user disable --now fusuma.service 2>/dev/null || true
rm -rf ~/.config/fusuma
sudo gem uninstall fusuma -a -x 2>/dev/null || true
sudo gpasswd -d $USER input 2>/dev/null || true

# Qt5ct y Quick Look
sudo sed -i '/QT_QPA_PLATFORMTHEME=qt5ct/d' /etc/environment 2>/dev/null || true
rm -rf ~/.config/qt5ct
sudo apt-get remove -y -qq sushi gloobus-preview 2>/dev/null || true
sudo dnf remove -y -q sushi gloobus-preview 2>/dev/null || true
sudo pacman -Rns --noconfirm sushi gloobus-preview 2>/dev/null || true

# Gestor de Portapapeles
sudo apt-get remove -y -qq gnome-shell-extension-clipboard-indicator clipit xfce4-clipman-plugin 2>/dev/null || true
sudo dnf remove -y -q gnome-shell-extension-clipboard-indicator clipit xfce4-clipman-plugin 2>/dev/null || true
sudo pacman -Rns --noconfirm gnome-shell-extension-clipboard-indicator clipit xfce4-clipman-plugin 2>/dev/null || true

# Fontconfig y Terminal
rm -f ~/.config/fontconfig/fonts.conf
rm -f ~/.config/xfce4/terminal/terminalrc

# Directorio de trabajo y documentación
rm -rf ~/.macos-theme-setup
rm -f ~/.macos-keybindings.md

echo -e "${GREEN}✅ Archivos y configuraciones eliminados.${NC}"
echo ""

# =============================================================================
# 3. RESTAURAR CONFIGURACIÓN DE ESCRITORIO (GNOME)
# =============================================================================
if [ "$IS_GNOME" = true ]; then
    echo -e "${YELLOW}⚙️  [2/8] Restaurando configuración de GNOME...${NC}"
    
    # Restablecer temas, iconos, cursores y fuentes a los valores por defecto
    gsettings reset org.gnome.desktop.interface gtk-theme
    gsettings reset org.gnome.desktop.interface icon-theme
    gsettings reset org.gnome.desktop.interface cursor-theme
    gsettings reset org.gnome.desktop.interface font-name
    gsettings reset org.gnome.desktop.interface monospace-font-name
    gsettings reset org.gnome.desktop.interface document-font-name
    gsettings reset org.gnome.desktop.wm.preferences titlebar-font
    
    # Restablecer fondo de pantalla
    gsettings reset org.gnome.desktop.background picture-uri
    gsettings reset org.gnome.desktop.background picture-uri-dark
    
    # Restablecer sonidos y scroll natural
    gsettings reset org.gnome.desktop.sound theme-name
    gsettings reset org.gnome.desktop.peripherals.touchpad natural-scroll
    gsettings reset org.gnome.desktop.peripherals.mouse natural-scroll
    
    # Restablecer atajos de teclado y combinaciones
    gsettings reset-recursively org.gnome.desktop.wm.keybindings
    gsettings reset-recursively org.gnome.settings-daemon.plugins.media-keys
    
    # Restablecer animaciones
    gsettings reset org.gnome.desktop.interface enable-animations
    gsettings reset org.gnome.mutter center-new-windows
    
    # Desactivar y eliminar extensiones
    gnome-extensions disable liquid-glass@thinkingcoding1231.gmail.com 2>/dev/null || true
    gnome-extensions disable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null || true
    gnome-extensions disable dash-to-dock@micxgx.gmail.com 2>/dev/null || true
    gnome-extensions disable clipboard-indicator@tudmotu.com 2>/dev/null || true
    
    rm -rf ~/.local/share/gnome-shell/extensions/liquid-glass@thinkingcoding1231.gmail.com
    rm -rf ~/.local/share/gnome-shell/extensions/*magic-lamp*
    
    # Restablecer perfil de terminal por defecto
    gsettings reset org.gnome.terminal.legacy/default-profile
    
    echo -e "${GREEN}✅ Configuración de GNOME restaurada.${NC}"
    echo ""
fi

# =============================================================================
# 4. RESTAURAR CONFIGURACIÓN DE ESCRITORIO (CINNAMON)
# =============================================================================
if [ "$IS_CINNAMON" = true ]; then
    echo -e "${YELLOW}⚙️  [3/8] Restaurando configuración de Cinnamon...${NC}"
    
    # Restablecer temas, iconos y cursores
    gsettings reset org.cinnamon.desktop.interface gtk-theme
    gsettings reset org.cinnamon.desktop.interface icon-theme
    gsettings reset org.cinnamon.desktop.interface cursor-theme
    gsettings reset org.cinnamon.desktop.interface font-name
    gsettings reset org.cinnamon.desktop.interface monospace-font-name
    gsettings reset org.cinnamon.theme name
    gsettings reset org.cinnamon.desktop.wm.preferences theme
    gsettings reset org.cinnamon.desktop.wm.preferences titlebar-font
    
    # Restablecer fondo y sonidos
    gsettings reset org.cinnamon.desktop.background picture-uri
    gsettings reset org.cinnamon.desktop.sound theme-name
    gsettings reset org.gnome.desktop.peripherals.touchpad natural-scroll 2>/dev/null || true
    
    # Restablecer atajos de teclado
    gsettings reset-recursively org.cinnamon.desktop.keybindings
    
    # Restablecer efectos de ventana
    gsettings reset org.cinnamon.desktop.effects minimize-effect
    gsettings reset org.cinnamon.desktop.effects unminimize-effect
    
    # Eliminar extensiones
    rm -rf ~/.local/share/cinnamon/extensions/cinnamon-dynamic-wallpaper@TobiZog
    rm -rf ~/.local/share/cinnamon/extensions/CinnamonMagicLamp@klangman
    
    echo -e "${GREEN}✅ Configuración de Cinnamon restaurada.${NC}"
    echo ""
fi

# =============================================================================
# 5. RESTAURAR CONFIGURACIÓN DE ESCRITORIO (XFCE)
# =============================================================================
if [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    echo -e "${YELLOW}⚙️  [4/8] Restaurando configuración de XFCE...${NC}"
    
    # Restablecer temas, iconos, cursores, fuentes y scroll (la flag -r resetea al valor por defecto)
    xfconf-query -c xsettings -p /Net/ThemeName -r 2>/dev/null || true
    xfconf-query -c xsettings -p /Net/IconThemeName -r 2>/dev/null || true
    xfconf-query -c xsettings -p /Net/CursorThemeName -r 2>/dev/null || true
    xfconf-query -c xsettings -p /Gtk/FontName -r 2>/dev/null || true
    xfconf-query -c xsettings -p /Gtk/MonospaceFontName -r 2>/dev/null || true
    xfconf-query -c xsettings -p /Net/SoundThemeName -r 2>/dev/null || true
    
    # Restablecer gestor de ventanas
    xfconf-query -c xfwm4 -p /general/theme -r 2>/dev/null || true
    xfconf-query -c xfwm4 -p /general/title_font -r 2>/dev/null || true
    xfconf-query -c xfwm4 -p /general/use_compositing -r 2>/dev/null || true
    
    # Eliminar atajos de teclado personalizados específicos de macOS
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/<Super>e -r 2>/dev/null || true
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/<Super>a -r 2>/dev/null || true
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/<Ctrl><Alt>t -r 2>/dev/null || true
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/<Ctrl><Shift>Escape -r 2>/dev/null || true
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/<Super>l -r 2>/dev/null || true
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/<Ctrl><Alt>Delete -r 2>/dev/null || true
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/<Ctrl>space -r 2>/dev/null || true
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/<Ctrl><Alt>Escape -r 2>/dev/null || true
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/<Ctrl>q -r 2>/dev/null || true
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/<Super>c -r 2>/dev/null || true
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/<Super>f -r 2>/dev/null || true
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/<Super>v -r 2>/dev/null || true
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/<Super>r -r 2>/dev/null || true
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/<Super>o -r 2>/dev/null || true
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/<Super><Ctrl>o -r 2>/dev/null || true
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/Print -r 2>/dev/null || true
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/<Alt>Print -r 2>/dev/null || true
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/<Shift>Print -r 2>/dev/null || true
    
    echo -e "${GREEN}✅ Configuración de XFCE restaurada.${NC}"
    echo ""
fi

# =============================================================================
# 6. RESTAURAR PLYMOUTH (PANTALLA DE ARRANQUE)
# =============================================================================
echo -e "${YELLOW}🖥️  [5/8] Restaurando pantalla de arranque (Plymouth)...${NC}"
if [ -d /usr/share/plymouth/themes/apple-mac-plymouth ]; then
    sudo rm -rf /usr/share/plymouth/themes/apple-mac-plymouth
    # Restablecer al tema por defecto del sistema
    sudo update-alternatives --auto default.plymouth 2>/dev/null || true
    sudo update-initramfs -u > /dev/null 2>&1 || sudo dracut --force > /dev/null 2>&1 || true
    echo -e "${GREEN}✅ Plymouth restaurado.${NC}"
else
    echo -e "${YELLOW}⏭️  Plymouth no fue modificado o no está presente.${NC}"
fi
echo ""

# =============================================================================
# 7. RESTAURAR FIREFOX Y GDM (Si aplica)
# =============================================================================
echo -e "${YELLOW}🦊 [6/8] Limpiando configuraciones de Firefox y GDM...${NC}"
# Eliminar perfiles de tema de Firefox si existen
rm -rf ~/.mozilla/firefox/*.default*/chrome 2>/dev/null || true
rm -rf ~/.var/app/org.mozilla.firefox/.mozilla/firefox/*.default*/chrome 2>/dev/null || true

# Revertir GDM si el script de tweaks está disponible
if [ "$IS_GNOME" = true ] && [ -d "$HOME/.macos-theme-setup/MacTahoe-gtk-theme" ]; then
    ( cd "$HOME/.macos-theme-setup/MacTahoe-gtk-theme" && sudo ./tweaks.sh -g -r > /dev/null 2>&1 ) || true
fi
echo -e "${GREEN}✅ Limpieza de Firefox/GDM completada.${NC}"
echo ""

# =============================================================================
# 8. LIMPIEZA FINAL DE PAQUETES
# =============================================================================
echo -e "${YELLOW}🧹 [7/8] Limpieza del sistema...${NC}"
echo -e "${BLUE}Nota: Los paquetes de dependencias generales (rofi, plank, etc.) se mantienen${NC}"
echo -e "${BLUE}instalados por si los usabas antes. Puedes eliminarlos manualmente si${NC}"
echo -e "${BLUE}deseas una limpieza total.${NC}"

if command -v apt-get &> /dev/null; then
    sudo apt-get autoremove -y -qq 2>/dev/null || true
elif command -v dnf &> /dev/null; then
    sudo dnf autoremove -y -q 2>/dev/null || true
elif command -v pacman &> /dev/null; then
    sudo pacman -Rns --noconfirm $(pacman -Qdtq) 2>/dev/null || true
fi
echo -e "${GREEN}✅ Limpieza de paquetes huérfanos completada.${NC}"
echo ""

# =============================================================================
# MENSAJE FINAL
# =============================================================================
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        🎉 ¡DESINSTALACIÓN COMPLETADA CON ÉXITO! 🎉       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Tu sistema ha sido restaurado a su estado original.${NC}"
echo -e "${YELLOW}⚠️  IMPORTANTE: Debes ${RED}reiniciar el equipo${YELLOW} para que todos los cambios${NC}"
echo -e "${YELLOW}   (especialmente Plymouth, grupo 'input' y Qt) surtan efecto correctamente.${NC}"
echo ""

if [ "$IS_GNOME" = true ]; then
    echo -e "${BLUE}Si usas X11 y prefieres no reiniciar, puedes reiniciar GNOME Shell con:${NC}"
    echo -e "   ${CYAN}dbus-send --session --type=method_call --dest=org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Eval string:'Meta.restart(\"Reiniciando...\")'${NC}"
fi

echo ""
