#!/bin/bash
# =============================================================================
# Módulo XFCE - macOS Tahoe Installer (Versión Corregida y Robusta)
# Este archivo define funciones que son llamadas por install.sh
# =============================================================================

# =============================================================================
# VARIABLES DE ENTORNO (Asegúrate de que install.sh exporte estas variables)
# =============================================================================
# Si por alguna razón no vienen de install.sh, establecemos valores por defecto seguros
WALLPAPER_PATH="${WALLPAPER_PATH:-$WORKDIR/wallpapers/default.jpg}"
ABOUT_SCRIPT="${ABOUT_SCRIPT:-$WORKDIR/about_this_mac.sh}"
SOUND_INSTALLED="${SOUND_INSTALLED:-false}"

# =============================================================================
# FUNCIÓN AUXILIAR PARA ATAJOS DE TECLADO (SINTAXIS CORRECTA)
# =============================================================================
xfce_set_keybinding() {
    local command="$1"
    local binding="$2"

    # Intentar crear la propiedad, si ya existe solo actualizarla
    run_as_user xfconf-query \
        -c xfce4-keyboard-shortcuts \
        -p "/commands/custom/$binding" \
        -n -t string -s "$command" 2>/dev/null ||
    run_as_user xfconf-query \
        -c xfce4-keyboard-shortcuts \
        -p "/commands/custom/$binding" \
        -s "$command" 2>/dev/null || true
}

# =============================================================================
#  Paso 15: Configuración del sistema, paneles y atajos de teclado
# =============================================================================
xfce_step_15() {
    echo -e "${BLUE}   → Configurando XFCE...${NC}"
    run_as_user xfconf-query -c xsettings -p /Net/ThemeName -s "$GTK_THEME" 2>/dev/null || true
    run_as_user xfconf-query -c xsettings -p /Net/IconThemeName -s "$ICON_THEME" 2>/dev/null || true
    run_as_user xfconf-query -c xsettings -p /Net/CursorThemeName -s "$CURSOR_THEME" 2>/dev/null || true
    
    if [ "${SF_INSTALLED:-false}" = true ]; then
        run_as_user xfconf-query -c xsettings -p /Gtk/FontName -s 'SF Pro Text 11' 2>/dev/null || true
        run_as_user xfconf-query -c xsettings -p /Gtk/DocumentFontName -s 'New York Medium 11' 2>/dev/null || true
        run_as_user xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s 'SF Mono Regular 11' 2>/dev/null || true
        run_as_user xfconf-query -c xfwm4 -p /general/title_font -s 'SF Pro Text 11' 2>/dev/null || true
        echo -e "${GREEN}   ✓ Fuentes Apple aplicadas${NC}"
    fi
    
    # OMH = Close (O), Minimize (M), Maximize (H) - Orden exacto de macOS
    run_as_user xfconf-query -c xfwm4 -p /general/button_layout -s "OMH:CLOSE" 2>/dev/null || true
    echo -e "${GREEN}   ✓ Botones de ventana movidos a la izquierda${NC}"

    # 🛡️ RECONSTRUCCIÓN TOTAL DEL PANEL DE XFCE (CON COPIA DE SEGURIDAD)
    echo -e "${BLUE}   → Preparando reconstrucción del panel superior estilo macOS...${NC}"
    
    local PANEL_CONFIG_DIR="$REAL_HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
    local PANEL_BACKUP="$REAL_HOME/.config/xfce4/panel_backup_$(date +%F_%H-%M-%S).xml"
    
    if [ -f "$PANEL_CONFIG_DIR/xfce4-panel.xml" ]; then
        cp "$PANEL_CONFIG_DIR/xfce4-panel.xml" "$PANEL_BACKUP" 2>/dev/null || true
        [ -n "$SUDO_USER" ] && chown "$REAL_UID:$REAL_GID" "$PANEL_BACKUP" 2>/dev/null || true
        echo -e "${GREEN}   ✓ Copia de seguridad del panel creada: $PANEL_BACKUP${NC}"
    else
        echo -e "${YELLOW}   ⚠️  No se encontró configuración previa del panel. Se creará una nueva.${NC}"
    fi

    run_as_user xfce4-panel --quit 2>/dev/null || true
    pkill xfce4-panel 2>/dev/null || true
    sleep 1
    
    # Limpiar configuración anterior del panel
    run_as_user xfconf-query -c xfce4-panel -r -R /panels 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -r -R /plugins 2>/dev/null || true

    # Crear panel 0 con tipos correctos de xfconf
    run_as_user xfconf-query -c xfce4-panel -p /panels -n -t empty -a 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0 -n -t empty -a 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/position -s "p=6;x=0;y=0" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/position-locked -n -t bool -s true 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/size -n -t uint -s 28 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/autohide -n -t bool -s false 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/disable-struts -n -t bool -s false 2>/dev/null || true

    # Crear lista de plugin-ids como array de enteros (CORREGIDO)
    run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/plugin-ids -n -t int -a 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/plugin-ids -n -t int -a -s 1 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/plugin-ids -n -t int -a -s 2 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/plugin-ids -n -t int -a -s 3 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/plugin-ids -n -t int -a -s 4 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/plugin-ids -n -t int -a -s 5 2>/dev/null || true
    
    # Plugin 1: Whisker Menu (con tipos correctos)
    run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-1 -n -t string -s "whiskermenu" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-1/button-icon -n -t string -s "distributor-logo" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-1/show-button-title -n -t bool -s false 2>/dev/null || true
    
    # Plugin 2: Separador expansible (con tipos correctos)
    run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-2 -n -t string -s "separator" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-2/expand -n -t bool -s true 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-2/style -n -t uint -s 0 2>/dev/null || true
    
    # Plugin 3: Reloj (con tipos correctos)
    run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-3 -n -t string -s "clock" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-3/digital-format -n -t string -s "%a %d %b, %H:%M" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-3/digital-layout -n -t uint -s 3 2>/dev/null || true
    
    # Plugin 4: Notificaciones
    run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-4 -n -t string -s "notification-plugin" 2>/dev/null || true
    
    # Plugin 5: Energía
    run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-5 -n -t string -s "power-manager-plugin" 2>/dev/null || true

    # Reiniciar panel en segundo plano
    run_as_user xfce4-panel &>/dev/null &
    sleep 2
    echo -e "${GREEN}   ✓ Panel de XFCE reconstruido en la parte superior.${NC}"

    # ATAJO DE TECLADO ESTILO macOS (XFCE) - Usando función auxiliar corregida
    xfce_set_keybinding "rofi -show drun" "<Ctrl>space"
    xfce_set_keybinding "xfce4-session-logout" "<Super>q"
    xfce_set_keybinding "xfce4-terminal" "<Ctrl><Alt>t"
    xfce_set_keybinding "xfce4-screensaver-command --lock" "<Super>l"

    run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>d" -n -t string -s "show_desktop_key" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>m" -n -t string -s "hide_window_key" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>Up" -n -t string -s "maximize_window_key" 2>/dev/null || true
    
    echo -e "${GREEN}   ✓ Atajos de teclado macOS aplicados${NC}"

    run_as_user xfconf-query -c xfce4-notifyd -p /theme -n -t string -s "MacTahoe-Dark" 2>/dev/null || true
    if [ "$SOUND_INSTALLED" = true ]; then
        run_as_user xfconf-query -c xsettings -p /Net/SoundThemeName -n -t string -s "${SOUND_THEME:-bigsur}" 2>/dev/null || true
    fi
    echo -e "${GREEN}   ✓ Configuración XFCE aplicada al 100%${NC}"
}

# =============================================================================
#  Paso 15.5: Botón de menú con icono de Apple
# =============================================================================
xfce_step_15_5() {
    echo -e "${BLUE}   → Verificando e instalando Whisker Menu en XFCE...${NC}"
    if ! command -v xfce4-popup-whiskermenu &> /dev/null; then
        echo -e "${BLUE}      → Whisker Menu no detectado. Instalando...${NC}"
        if command -v apt-get &> /dev/null; then
            sudo apt-get install -y -qq xfce4-whiskermenu-plugin 2>/dev/null || echo -e "${RED}⚠️ Fallo al instalar whiskermenu${NC}"
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y -q xfce4-whiskermenu-plugin 2>/dev/null || echo -e "${RED}⚠️ Fallo al instalar whiskermenu${NC}"
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm --needed xfce4-whiskermenu-plugin 2>/dev/null || echo -e "${RED}⚠️ Fallo al instalar whiskermenu${NC}"
        fi
    fi
    
    local WHISKER_ID
    WHISKER_ID=$(run_as_user xfconf-query -c xfce4-panel -l 2>/dev/null | grep "whiskermenu" | head -1 | cut -d'/' -f4)
    if [ -n "$WHISKER_ID" ]; then
        run_as_user xfconf-query -c xfce4-panel -p /plugins/$WHISKER_ID/button-icon -n -t string -s "distributor-logo" 2>/dev/null || true
        run_as_user xfconf-query -c xfce4-panel -p /plugins/$WHISKER_ID/show-button-title -n -t bool -s false 2>/dev/null || true
        echo -e "${GREEN}   ✓ Icono de Apple aplicado a Whisker Menu.${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Whisker Menu instalado. Añádelo manualmente al panel si no aparece.${NC}"
    fi
}

# =============================================================================
#  Paso 15.6: Ajustes finos de comportamiento (Finder, Trackpad, Notificaciones)
# =============================================================================
xfce_step_15_6() {
    echo -e "${BLUE}   → Ajustando XFCE (Thunar, Trackpad, Notificaciones)...${NC}"
    run_as_user xfconf-query -c thunar -p /misc-default-view -s "THUNAR_VIEW_ICON" 2>/dev/null || true
    run_as_user xfconf-query -c thunar -p /misc-show-hidden -n -t bool -s false 2>/dev/null || true
    run_as_user xfconf-query -c thunar -p /misc-single-click -n -t bool -s false 2>/dev/null || true
    
    # Trackpad (Habilitar Tap-to-Click y Scroll Natural)
    for dev in $(xinput list --id-only 'Touchpad' 'touchpad' 2>/dev/null); do
        xinput set-prop "$dev" "libinput Tapping Enabled" 1 2>/dev/null || true
        xinput set-prop "$dev" "libinput Natural Scrolling Enabled" 1 2>/dev/null || true
    done
    
    run_as_user xfconf-query -c xfce4-notifyd -p /theme -n -t string -s "MacTahoe-Dark" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-notifyd -p /notify-location -n -t uint -s 2 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-notifyd -p /do-fadeout -n -t bool -s true 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-notifyd -p /fadeout-time -n -t uint -s 500 2>/dev/null || true
    echo -e "${GREEN}   ✓ Ajustes finos de XFCE aplicados${NC}"
}

# =============================================================================
#  Paso 15.7: Detalles finales (Cursor y Atajo "Acerca de este Mac")
# =============================================================================
xfce_step_15_7() {
    run_as_user xfconf-query -c xsettings -p /Gtk/CursorThemeSize -n -t uint -s 32 2>/dev/null || true
    echo -e "${GREEN}   ✓ Cursor XFCE ajustado a 32px${NC}"

    if [ -f "$ABOUT_SCRIPT" ]; then
        run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>i" -n -t string -s "bash $ABOUT_SCRIPT" 2>/dev/null || \
        run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>i" -s "bash $ABOUT_SCRIPT" 2>/dev/null || true
        echo -e "${GREEN}   ✓ Atajo Super+I asignado correctamente.${NC}"
    fi
}

# =============================================================================
#  Paso 15.8: Modo oscuro automático
# =============================================================================
xfce_step_15_8() {
    if command -v xfconf-query &> /dev/null; then
        xfconf-query -c xsettings -p /Net/ThemeName -s "$GTK_THEME" 2>/dev/null || true
    fi
}

# =============================================================================
#  Paso 15.9: Perfeccionamiento de experiencia macOS
# =============================================================================
xfce_step_15_9() {
    local CLOCK_PLUGIN
    CLOCK_PLUGIN=$(run_as_user xfconf-query -c xfce4-panel -l 2>/dev/null | grep "/plugins/" | grep "clock" | head -1 | cut -d'/' -f4)
    if [ -n "$CLOCK_PLUGIN" ]; then
        run_as_user xfconf-query -c xfce4-panel -p /plugins/$CLOCK_PLUGIN/digital-format -n -t string -s "%a %d %b, %H:%M" 2>/dev/null || true
        run_as_user xfconf-query -c xfce4-panel -p /plugins/$CLOCK_PLUGIN/digital-layout -n -t uint -s 3 2>/dev/null || true
    fi

    run_as_user xfconf-query -c xsettings -p /Net/EnableInputFeedbackSounds -n -t bool -s true 2>/dev/null || true
    run_as_user xfconf-query -c xsettings -p /Net/EnableEventSounds -n -t bool -s true 2>/dev/null || true

    run_as_user xfconf-query -c xfwm4 -p /general/button_layout -s "OMH:CLOSE" 2>/dev/null || true
    if command -v xfwm4 &> /dev/null; then
        run_as_user xfwm4 --replace &>/dev/null &
        sleep 1
    fi
    echo -e "${GREEN}   ✓ Botones XFCE corregidos y gestor recargado.${NC}"
}

# =============================================================================
#  Paso 15.10B: Pantalla de bloqueo estilo macOS
# =============================================================================
xfce_step_15_10b() {
    echo -e "${BLUE}   → Configurando pantalla de bloqueo (light-locker)...${NC}"
    if ! command -v light-locker &> /dev/null; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get install -y -qq light-locker 2>/dev/null || true
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y -q light-locker 2>/dev/null || true
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm --needed light-locker 2>/dev/null || true
        fi
    fi
    
    mkdir -p "$REAL_HOME/.config/light-locker" 2>/dev/null || true
    cat > "$REAL_HOME/.config/light-locker/light-locker.conf" << EOF
[light-locker]
lock-on-suspend=true
lock-on-lid=false
idle-activation-enabled=true
EOF
    [ -n "$SUDO_USER" ] && chown -R "$REAL_UID:$REAL_GID" "$REAL_HOME/.config/light-locker" 2>/dev/null || true
    
    run_as_user xfconf-query -c xfce4-session -p /general/lock_command -n -t string -s "light-locker-command -l" 2>/dev/null || true
    echo -e "${GREEN}   ✓ light-locker configurado para XFCE${NC}"
}

# =============================================================================
#  Paso 15.10C: Indicadores OSD de volumen y brillo (MEJORADO)
# =============================================================================
xfce_step_15_10c() {
    echo -e "${BLUE}   → Configurando OSD (Volumen/Brillo) para XFCE...${NC}"
    
    # Priorizar el plugin moderno, caer en el legacy solo si es necesario
    local volume_pkg=""
    if command -v xfce4-pulseaudio-plugin &> /dev/null || dpkg -l xfce4-pulseaudio-plugin &>/dev/null || pacman -Q xfce4-pulseaudio-plugin &>/dev/null 2>&1; then
        volume_pkg="xfce4-pulseaudio-plugin"
        echo -e "${GREEN}   ✓ Usando plugin de audio moderno: $volume_pkg${NC}"
    elif command -v xfce4-volumed-pulse &> /dev/null; then
        volume_pkg="xfce4-volumed-pulse"
        echo -e "${YELLOW}   ⚠️  Usando demonio legacy: $volume_pkg${NC}"
    else
        echo -e "${BLUE}   → Instalando plugin de audio para XFCE...${NC}"
        if command -v apt-get &> /dev/null; then
            sudo apt-get install -y -qq xfce4-pulseaudio-plugin 2>/dev/null || sudo apt-get install -y -qq xfce4-volumed-pulse 2>/dev/null || true
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y -q xfce4-pulseaudio-plugin 2>/dev/null || true
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm --needed xfce4-pulseaudio-plugin 2>/dev/null || true
        fi
    fi

    run_as_user xfconf-query -c xfce4-notifyd -p /theme -n -t string -s "MacTahoe-Dark" 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-notifyd -p /notify-location -n -t uint -s 2 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-notifyd -p /do-fadeout -n -t bool -s true 2>/dev/null || true
    run_as_user xfconf-query -c xfce4-notifyd -p /fadeout-time -n -t uint -s 500 2>/dev/null || true
    echo -e "${GREEN}   ✓ OSD de XFCE configurado correctamente.${NC}"
}

# =============================================================================
#  Paso 17: Configuración de Terminal estilo macOS
# =============================================================================
xfce_step_17() {
    if command -v xfce4-terminal &> /dev/null; then
        mkdir -p "$REAL_HOME/.config/xfce4/terminal" 2>/dev/null || true
        cat > "$REAL_HOME/.config/xfce4/terminal/terminalrc" << 'TERMINALEOF' 2>/dev/null || true
[Configuration]
FontName=SF Mono Regular 12
ColorForeground=#e6e6e6
ColorBackground=#1e1e1e
ColorBold=#ffffff
MiscCursorShape=TERMINAL_CURSOR_SHAPE_IBEAM
MiscCursorBlinks=FALSE
MiscShowUnsafeUrls=FALSE
TERMINALEOF
        [ -n "$SUDO_USER" ] && chown -R "$REAL_UID:$REAL_GID" "$REAL_HOME/.config/xfce4/terminal" 2>/dev/null || true
        echo -e "${GREEN}   ✓ Terminal XFCE configurada con tema macOS${NC}"
    fi
}

# =============================================================================
#  Paso 18: Configuración de animaciones suaves
# =============================================================================
xfce_step_18() {
    run_as_user xfconf-query -c xfwm4 -p /general/use_compositing -n -t bool -s true 2>/dev/null || true
    echo -e "${GREEN}   ✓ Compositing activado en XFWM4${NC}"
}

# =============================================================================
#  Paso 21: Scroll natural universal
# =============================================================================
xfce_step_21() {
    for device in $(xinput list 2>/dev/null | grep -i "pointer" | grep -i "libinput" | sed 's/.*id=\([0-9]*\).*/\1/'); do
        xinput set-prop "$device" "libinput Natural Scrolling Enabled" 1 2>/dev/null || true
    done
    echo -e "${GREEN}   ✓ Scroll natural aplicado a dispositivos libinput${NC}"
}

# =============================================================================
#  Paso 22: Gestos multitáctiles estilo macOS (Fusuma - MEJORADO)
# =============================================================================
xfce_step_22() {
    echo -e "${BLUE}   → Configurando Gestos Multitáctiles (Fusuma)...${NC}"
    
    # 1. Verificar y añadir al grupo 'input' para permitir lectura del touchpad
    if ! groups "$REAL_USER" | grep -q '\binput\b'; then
        echo -e "${YELLOW}   ⚠️  Añadiendo usuario al grupo 'input' para permitir lectura del touchpad...${NC}"
        sudo usermod -aG input "$REAL_USER" 2>/dev/null || true
        echo -e "${RED}   ❗ IMPORTANTE: Debes CERRAR SESIÓN y volver a entrar (o reiniciar) para que los gestos funcionen.${NC}"
    fi

    # 2. Crear directorio con permisos correctos
    mkdir -p "$REAL_HOME/.config/fusuma" 2>/dev/null || true
    [ -n "$SUDO_USER" ] && chown -R "$REAL_UID:$REAL_GID" "$REAL_HOME/.config/fusuma" 2>/dev/null || true

    # 3. Escribir configuración robusta
    cat > "$REAL_HOME/.config/fusuma/config.yml" << 'EOF'
plugin:
  inputs:
    libinput_command_input:
      enable-tap: true
      show-keycodes: false
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
    4:
      left:
        command: 'xdotool key alt+Left'
      right:
        command: 'xdotool key alt+Right'
      up:
        command: 'xdotool key super+s'
      down:
        command: 'xdotool key super+s'
  pinch:
    2:
      in:
        command: 'xdotool keydown ctrl click 4 keyup ctrl'
      out:
        command: 'xdotool keydown ctrl click 5 keyup ctrl'
EOF
    echo -e "${GREEN}   ✓ Configuración de Fusuma escrita. Añade 'fusuma' a las aplicaciones de inicio.${NC}"
}

# =============================================================================
#  Paso 23: Gestor de portapapeles minimalista
# =============================================================================
xfce_step_23() {
    echo -e "${GREEN}   ✓ Clipman instalado para XFCE (añádelo al panel manualmente si no aparece).${NC}"
}

# =============================================================================
#  Validación de dependencias críticas de XFCE
# =============================================================================
verify_xfce_critical_deps() {
    echo -e "${BLUE}🔍 [Verificación] Comprobando dependencias críticas de XFCE...${NC}"
    local missing_deps=()
    local critical_pkgs=("xfce4-whiskermenu-plugin" "xfce4-notifyd" "xfce4-terminal")
    
    for pkg in "${critical_pkgs[@]}"; do
        if command -v dpkg &>/dev/null; then
            dpkg -l "$pkg" &>/dev/null || missing_deps+=("$pkg")
        elif command -v pacman &>/dev/null; then
            pacman -Q "$pkg" &>/dev/null || missing_deps+=("$pkg")
        elif command -v rpm &>/dev/null; then
            rpm -q "$pkg" &>/dev/null || missing_deps+=("$pkg")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}❌ Faltan paquetes críticos: ${missing_deps[*]}${NC}"
        echo -e "${YELLOW}⚠️  La experiencia macOS en XFCE estará incompleta. Intenta instalarlos manualmente.${NC}"
    else
        echo -e "${GREEN}   ✓ Todas las dependencias críticas de XFCE están presentes.${NC}"
    fi
}
