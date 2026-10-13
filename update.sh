#!/bin/bash

# =============================================================================
# macOS Tahoe Updater - Actualización Inteligente (Versión Ultimate)
# Solo actualiza los componentes que han cambiado en GitHub
# =============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# =============================================================================
# DETECCIÓN DEL USUARIO REAL (CRÍTICO para evitar corrupción de /root)
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

WORKDIR="$REAL_HOME/.macos-theme-setup"
VERSION_FILE="$WORKDIR/.installed_version"

echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🔄 macOS Tahoe Updater - Actualización Inteligente   ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# =============================================================================
# VERIFICAR QUE EL SISTEMA ESTÁ INSTALADO
# =============================================================================
if [ ! -d "$WORKDIR" ]; then
    echo -e "${RED}❌ No se encontró una instalación previa de macOS Tahoe.${NC}"
    echo -e "${YELLOW}Por favor, ejecuta primero el instalador:${NC}"
    echo -e "   curl -sSL https://raw.githubusercontent.com/AntonSiMal/Them-macOS-Tahoe-Installer-for-Linux/main/install.sh -o install.sh && chmod +x install.sh && sudo ./install.sh"
    exit 1
fi

# Mostrar versión actual instalada
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE")
    echo -e "${BLUE}📋 Versión actual instalada: ${GREEN}$CURRENT_VERSION${NC}"
else
    echo -e "${YELLOW}⚠️  No se encontró registro de versión. Asumiendo instalación antigua.${NC}"
fi
echo ""

# =============================================================================
# DETECCIÓN DEL ENTORNO
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

if command -v xrandr &> /dev/null; then
    SCREEN_WIDTH=$(xrandr --current | grep '*' | head -1 | awk '{print $1}' | cut -d'x' -f1)
    [ -n "$SCREEN_WIDTH" ] && {
        if [ "$SCREEN_WIDTH" -ge 3840 ]; then ICON_BOLD_FLAG="-b"
        else ICON_BOLD_FLAG=""; fi
    } || ICON_BOLD_FLAG="-b"
else
    ICON_BOLD_FLAG="-b"
fi

UPDATED_COMPONENTS=0
TOTAL_COMPONENTS=0

# =============================================================================
# FUNCIÓN AUXILIAR: Actualizar repositorio y detectar cambios
# =============================================================================
update_repo() {
    local repo_path="$1"
    local repo_url="$2"
    local component_name="$3"
    
    TOTAL_COMPONENTS=$((TOTAL_COMPONENTS + 1))
    
    if [ ! -d "$repo_path" ]; then
        echo -e "   ${YELLOW}⚠️  $component_name: No encontrado, clonando de nuevo...${NC}"
        git clone --depth=1 "$repo_url" "$repo_path" -q 2>/dev/null
        UPDATED_COMPONENTS=$((UPDATED_COMPONENTS + 1))
        return 0
    fi
    
    cd "$repo_path"
    LOCAL_COMMIT=$(git rev-parse HEAD 2>/dev/null)
    
    git fetch --depth=1 origin main -q 2>/dev/null || git fetch --depth=1 origin master -q 2>/dev/null
    REMOTE_COMMIT=$(git rev-parse FETCH_HEAD 2>/dev/null)
    
    if [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
        echo -e "   ${GREEN}✓ $component_name: Actualización disponible${NC}"
        git pull --depth=1 origin $(git symbolic-ref --short HEAD 2>/dev/null || echo "main") -q 2>/dev/null || \
        git pull --depth=1 origin master -q 2>/dev/null
        UPDATED_COMPONENTS=$((UPDATED_COMPONENTS + 1))
        return 0
    else
        echo -e "   ${BLUE}• $component_name: Ya está actualizado${NC}"
        return 1
    fi
}

# =============================================================================
# ACTUALIZAR REPOSITORIOS Y DETECTAR CAMBIOS
# =============================================================================
echo -e "${YELLOW}🔍 Buscando actualizaciones en GitHub...${NC}"
echo ""

NEEDS_REINSTALL=()

if update_repo "$WORKDIR/SFWindows" "https://github.com/bradleyhodges/SFWindows.git" "Fuentes Apple"; then
    NEEDS_REINSTALL+=("fonts")
fi

if update_repo "$WORKDIR/MacTahoe-gtk-theme" "https://github.com/vinceliuice/MacTahoe-gtk-theme.git" "Tema GTK MacTahoe"; then
    NEEDS_REINSTALL+=("gtk")
fi

if update_repo "$WORKDIR/MacTahoe-icon-theme" "https://github.com/vinceliuice/MacTahoe-icon-theme.git" "Iconos MacTahoe"; then
    NEEDS_REINSTALL+=("icons")
fi

if update_repo "$WORKDIR/WhiteSur-wallpapers" "https://github.com/vinceliuice/WhiteSur-wallpapers.git" "Wallpapers Sonoma"; then
    NEEDS_REINSTALL+=("wallpapers")
fi

if update_repo "$WORKDIR/rofi-spotlight" "https://github.com/eromatiya/rofi-spotlight.git" "Rofi Spotlight"; then
    NEEDS_REINSTALL+=("rofi")
fi

if update_repo "$WORKDIR/MacOS-Mojave-Plank-themes" "https://github.com/Macintosh98/MacOS-Mojave-Plank-themes.git" "Temas Plank"; then
    NEEDS_REINSTALL+=("plank")
fi

if [ "$IS_CINNAMON" = true ]; then
    if update_repo "$WORKDIR/cinnamon-dynamic-wallpaper" "https://github.com/TobiZog/cinnamon-dynamic-wallpaper.git" "Cinnamon Dynamic Wallpaper"; then
        NEEDS_REINSTALL+=("cinnamon-dynamic")
    fi
fi

if [ "$IS_GNOME" = true ]; then
    if update_repo "$WORKDIR/compiz-alike-magic-lamp-effect" "https://github.com/hermes83/compiz-alike-magic-lamp-effect.git" "Magic Lamp (GNOME)"; then
        NEEDS_REINSTALL+=("magic-lamp-gnome")
    fi
    if update_repo "$WORKDIR/liquid-glass" "https://github.com/ryohsuke1231/liquid-glass.git" "Liquid Glass"; then
        NEEDS_REINSTALL+=("liquid-glass")
    fi
fi

if [ "$IS_CINNAMON" = true ]; then
    if update_repo "$WORKDIR/CinnamonMagicLamp" "https://github.com/klangman/CinnamonMagicLamp.git" "Magic Lamp (Cinnamon)"; then
        NEEDS_REINSTALL+=("magic-lamp-cinnamon")
    fi
fi

echo ""

# =============================================================================
# REINSTALAR SOLO LO QUE CAMBIÓ
# =============================================================================
if [ ${#NEEDS_REINSTALL[@]} -eq 0 ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ ¡TODO ESTÁ ACTUALIZADO! No se requieren cambios    ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 0
fi

echo -e "${YELLOW}🔧 Reinstalando componentes actualizados...${NC}"
echo ""

for component in "${NEEDS_REINSTALL[@]}"; do
    case "$component" in
        "fonts")
            echo -e "   ${BLUE}→ Actualizando fuentes Apple...${NC}"
            FONTS_DIR="$REAL_HOME/.local/share/fonts"
            mkdir -p "$FONTS_DIR"
            [ -d "$WORKDIR/SFWindows/SF Mono" ] && find "$WORKDIR/SFWindows/SF Mono" -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec cp {} "$FONTS_DIR/" \; 2>/dev/null
            [ -d "$WORKDIR/SFWindows/SF Multilingual Extensions" ] && find "$WORKDIR/SFWindows/SF Multilingual Extensions" -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec cp {} "$FONTS_DIR/" \; 2>/dev/null
            fc-cache -f "$FONTS_DIR" > /dev/null 2>&1
            echo -e "   ${GREEN}✓ Fuentes actualizadas${NC}"
            ;;
            
        "gtk")
            echo -e "   ${BLUE}→ Actualizando tema GTK MacTahoe...${NC}"
            INSTALL_FLAGS="-c dark --silent-mode --round --darker"
            [ "$IS_GNOME" = true ] && INSTALL_FLAGS="$INSTALL_FLAGS -l"
            ( cd "$WORKDIR/MacTahoe-gtk-theme" && ./install.sh $INSTALL_FLAGS > /dev/null 2>&1 )
            echo -e "   ${GREEN}✓ Tema GTK actualizado${NC}"
            ;;
            
        "icons")
            echo -e "   ${BLUE}→ Actualizando iconos y cursores MacTahoe...${NC}"
            if [ -n "$ICON_BOLD_FLAG" ]; then
                ( cd "$WORKDIR/MacTahoe-icon-theme" && ./install.sh $ICON_BOLD_FLAG > /dev/null 2>&1 )
            else
                ( cd "$WORKDIR/MacTahoe-icon-theme" && ./install.sh > /dev/null 2>&1 )
            fi
            echo -e "   ${GREEN}✓ Iconos y cursores actualizados${NC}"
            ;;
            
        "wallpapers")
            echo -e "   ${BLUE}→ Actualizando wallpapers...${NC}"
            if [ "$IS_GNOME" = true ]; then
                ( cd "$WORKDIR/WhiteSur-wallpapers" && ./install-gnome-backgrounds.sh -t sonoma > /dev/null 2>&1 )
            else
                ( cd "$WORKDIR/WhiteSur-wallpapers" && ./install-wallpapers.sh -t sonoma -c dark > /dev/null 2>&1 )
            fi
            echo -e "   ${GREEN}✓ Wallpapers actualizados${NC}"
            ;;
            
        "rofi")
            echo -e "   ${BLUE}→ Actualizando Rofi Spotlight...${NC}"
            mkdir -p "$REAL_HOME/.local/share/rofi-spotlight" "$REAL_HOME/.local/share/rofi/themes"
            cp -r "$WORKDIR/rofi-spotlight"/* "$REAL_HOME/.local/share/rofi-spotlight/" 2>/dev/null
            chmod +x "$REAL_HOME/.local/share/rofi-spotlight/rofi-spotlight.sh" "$REAL_HOME/.local/share/rofi-spotlight/web-search.py" 2>/dev/null
            echo -e "   ${GREEN}✓ Rofi Spotlight actualizado${NC}"
            ;;
            
        "plank")
            echo -e "   ${BLUE}→ Actualizando temas de Plank...${NC}"
            mkdir -p "$REAL_HOME/.local/share/plank/themes"
            find "$WORKDIR/MacOS-Mojave-Plank-themes" -maxdepth 1 -type d \( -name "MacOS-*" -o -name "elementary-*" \) | while read -r theme_dir; do
                [ -d "$theme_dir" ] && cp -r "$theme_dir" "$REAL_HOME/.local/share/plank/themes/"
            done
            echo -e "   ${GREEN}✓ Temas de Plank actualizados${NC}"
            ;;
            
        "cinnamon-dynamic")
            echo -e "   ${BLUE}→ Actualizando Cinnamon Dynamic Wallpaper...${NC}"
            mkdir -p "$REAL_HOME/.local/share/cinnamon/extensions"
            cp -r "$WORKDIR/cinnamon-dynamic-wallpaper/cinnamon-dynamic-wallpaper@TobiZog" "$REAL_HOME/.local/share/cinnamon/extensions/" 2>/dev/null
            echo -e "   ${GREEN}✓ Cinnamon Dynamic Wallpaper actualizado${NC}"
            ;;
            
        "magic-lamp-gnome")
            echo -e "   ${BLUE}→ Actualizando Magic Lamp para GNOME...${NC}"
            mkdir -p "$REAL_HOME/.local/share/gnome-shell/extensions"
            EXT_MAGIC_LAMP=$(find "$WORKDIR/compiz-alike-magic-lamp-effect" -maxdepth 1 -type d -name "*magic-lamp*" | head -1)
            if [ -n "$EXT_MAGIC_LAMP" ]; then
                cp -r "$EXT_MAGIC_LAMP" "$REAL_HOME/.local/share/gnome-shell/extensions/" 2>/dev/null
                run_as_user gnome-extensions enable "$(basename "$EXT_MAGIC_LAMP")" 2>/dev/null || true
            fi
            echo -e "   ${GREEN}✓ Magic Lamp (GNOME) actualizado${NC}"
            ;;
            
        "magic-lamp-cinnamon")
            echo -e "   ${BLUE}→ Actualizando Magic Lamp para Cinnamon...${NC}"
            mkdir -p "$REAL_HOME/.local/share/cinnamon/extensions"
            ln -sf "$WORKDIR/CinnamonMagicLamp/CinnamonMagicLamp@klangman" "$REAL_HOME/.local/share/cinnamon/extensions/CinnamonMagicLamp@klangman" 2>/dev/null
            echo -e "   ${GREEN}✓ Magic Lamp (Cinnamon) actualizado${NC}"
            ;;
            
        "liquid-glass")
            echo -e "   ${BLUE}→ Actualizando Liquid Glass...${NC}"
            mkdir -p "$REAL_HOME/.local/share/gnome-shell/extensions"
            cp -r "$WORKDIR/liquid-glass/liquid-glass@thinkingcoding1231.gmail.com" "$REAL_HOME/.local/share/gnome-shell/extensions/" 2>/dev/null
            run_as_user gnome-extensions enable liquid-glass@thinkingcoding1231.gmail.com 2>/dev/null || true
            echo -e "   ${GREEN}✓ Liquid Glass actualizado${NC}"
            ;;
    esac
done

echo ""

# =============================================================================
# SINCRONIZACIÓN DE CONFIGURACIÓN (Asegura que los ajustes estén al día)
# =============================================================================
echo -e "${YELLOW}🔄 Sincronizando configuraciones del sistema...${NC}"

# 1. Actualizar scripts auxiliares (Acerca de este Mac y Auto Dark Mode)
ABOUT_SCRIPT="$REAL_HOME/.local/bin/about-this-mac.sh"
mkdir -p "$REAL_HOME/.local/bin" 2>/dev/null || true
cat > "$ABOUT_SCRIPT" << 'ABOUTEOF'
#!/bin/bash
CPU=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs | sed 's/(R)//g; s/(TM)//g; s/(C)//g' 2>/dev/null || echo "Procesador")
RAM=$(free -h | awk '/^Mem:/ {print $2}' 2>/dev/null || echo "RAM")
DISK=$(df -h / | awk 'NR==2 {print $2}' 2>/dev/null || echo "Disco")
GRAPHICS=$(lspci 2>/dev/null | grep -i "vga\|3d\|display" | head -1 | cut -d':' -f3 | xargs | sed 's/Corporation//g; s/Inc.//g' 2>/dev/null || echo "Gráficos")
KERNEL=$(uname -r 2>/dev/null || echo "Kernel")

zenity --info --title="Acerca de este Mac" --width=340 --height=400 \
--text="<span font='SF Pro Display 18' weight='bold'>macOS Tahoe</span>\n\n\
<span font='SF Pro Text 11'><b>Chip:</b> $CPU</span>\n\
<span font='SF Pro Text 11'><b>Memoria:</b> $RAM</span>\n\
<span font='SF Pro Text 11'><b>Disco de arranque:</b> Macintosh HD ($DISK)</span>\n\
<span font='SF Pro Text 11'><b>Gráficos:</b> $GRAPHICS</span>\n\
<span font='SF Pro Text 11'><b>Sistema:</b> Linux (Kernel $KERNEL)</span>\n\n\
<span font='SF Pro Text 9' foreground='#888888'>TM y © 1983-2026 Apple Inc.\nTodos los derechos reservados.</span>" \
--ok-label="Actualización de software..." 2>/dev/null || true
ABOUTEOF
chmod +x "$ABOUT_SCRIPT"

# 2. Re-aplicar tamaño de cursor (32px)
if [ "$IS_GNOME" = true ]; then
    run_as_user gsettings set org.gnome.desktop.interface cursor-size 32 2>/dev/null || true
elif [ "$IS_CINNAMON" = true ]; then
    run_as_user gsettings set org.cinnamon.desktop.interface cursor-size 32 2>/dev/null || true
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
    run_as_user xfconf-query -c xsettings -p /Gtk/CursorThemeSize -s 32 2>/dev/null || true
fi

# 3. Re-aplicar configuración de fuentes y tema por si acaso
run_as_user gsettings set org.gnome.desktop.interface font-name 'SF Pro Text 11' 2>/dev/null || true
run_as_user gsettings set org.cinnamon.desktop.interface font-name 'SF Pro Text 11' 2>/dev/null || true
run_as_user xfconf-query -c xsettings -p /Gtk/FontName -s 'SF Pro Text 11' 2>/dev/null || true

echo -e "${GREEN}   ✓ Configuraciones sincronizadas${NC}"
echo ""

# =============================================================================
# ACTUALIZAR REGISTRO DE VERSIÓN
# =============================================================================
NEW_VERSION=$(date '+%Y-%m-%d')
echo "$NEW_VERSION" > "$VERSION_FILE"

# Ajustar permisos de toda la carpeta de trabajo
if [ -n "$SUDO_USER" ]; then
    chown -R "$SUDO_USER:$SUDO_USER" "$WORKDIR" 2>/dev/null || true
fi

# =============================================================================
# MENSAJE FINAL
# =============================================================================
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   ✅ ACTUALIZACIÓN COMPLETADA                           ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✨ Se actualizaron ${UPDATED_COMPONENTS} de ${TOTAL_COMPONENTS} componentes.${NC}"
echo ""
echo -e "${BLUE}Componentes actualizados:${NC}"
for component in "${NEEDS_REINSTALL[@]}"; do
    echo -e "   • $component"
done
echo ""
echo -e "${YELLOW}⚠️  Para aplicar todos los cambios, reinicia tu sesión o el equipo.${NC}"
echo ""

if [ "$IS_GNOME" = true ]; then
    echo -e "${BLUE}💡 Si usas X11, puedes reiniciar GNOME Shell con:${NC}"
    echo -e "   ${CYAN}dbus-send --session --type=method_call --dest=org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Eval string:'Meta.restart(\"Reiniciando...\")'${NC}"
fi

echo ""
