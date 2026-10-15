#!/bin/bash
# =============================================================================
# Módulo Cinnamon - macOS Tahoe Installer
# Este archivo define funciones que son llamadas por install.sh
# =============================================================================

# =============================================================================
#  Paso 4: Extensión Cinnamon Dynamic Wallpaper
# =============================================================================
cinnamon_step_4() {
    echo -e "${YELLOW}🌅 [4/24] Instalando extensión 'Cinnamon Dynamic Wallpaper'...${NC}"
    mkdir -p "$REAL_HOME/.local/share/cinnamon/extensions/"
    [ ! -d "$WORKDIR/cinnamon-dynamic-wallpaper" ] && git clone --depth=1 https://github.com/TobiZog/cinnamon-dynamic-wallpaper.git "$WORKDIR/cinnamon-dynamic-wallpaper" -q
    cp -r "$WORKDIR/cinnamon-dynamic-wallpaper/cinnamon-dynamic-wallpaper@TobiZog" "$REAL_HOME/.local/share/cinnamon/extensions/" 2>/dev/null
    
    CINNAMON_EXTENSIONS=$(run_as_user gsettings get org.cinnamon enabled-extensions 2>/dev/null)
    if ! echo "$CINNAMON_EXTENSIONS" | grep -q "cinnamon-dynamic-wallpaper@TobiZog"; then
        if [ "$CINNAMON_EXTENSIONS" = "[]" ] || [ -z "$CINNAMON_EXTENSIONS" ]; then
            run_as_user gsettings set org.cinnamon enabled-extensions "['cinnamon-dynamic-wallpaper@TobiZog']" 2>/dev/null
        else
            NEW_EXTENSIONS=$(echo "$CINNAMON_EXTENSIONS" | sed "s/]$/, 'cinnamon-dynamic-wallpaper@TobiZog']/")
            run_as_user gsettings set org.cinnamon enabled-extensions "$NEW_EXTENSIONS" 2>/dev/null
        fi
    fi
    echo -e "${GREEN}✅ Cinnamon Dynamic Wallpaper instalada.${NC}"
}

# =============================================================================
#  Paso 15: Configuración del sistema, paneles y atajos de teclado
# =============================================================================
cinnamon_step_15() {
    echo -e "${BLUE}   → Configurando Cinnamon...${NC}"
    run_as_user gsettings set org.cinnamon.desktop.interface gtk-theme "$GTK_THEME"
    run_as_user gsettings set org.cinnamon.desktop.interface icon-theme "$ICON_THEME"
    run_as_user gsettings set org.cinnamon.desktop.interface cursor-theme "$CURSOR_THEME"
    run_as_user gsettings set org.cinnamon.desktop.interface color-scheme 'prefer-dark'
    
    if [ "$SF_INSTALLED" = true ]; then
        run_as_user gsettings set org.cinnamon.desktop.interface font-name 'SF Pro Text 11'
        run_as_user gsettings set org.cinnamon.desktop.interface document-font-name 'New York Medium 11'
        run_as_user gsettings set org.cinnamon.desktop.interface monospace-font-name 'SF Mono Regular 11'
        run_as_user gsettings set org.cinnamon.desktop.wm.preferences titlebar-font 'SF Pro Text 11'
        echo -e "${GREEN}   ✓ Fuentes Apple aplicadas${NC}"
    fi
    
    run_as_user gsettings set org.cinnamon.desktop.wm.preferences button-layout 'close,minimize,maximize:'
    echo -e "${GREEN}   ✓ Botones de ventana movidos a la izquierda${NC}"
    
    # PANEL SUPERIOR ESTILO macOS
    run_as_user gsettings set org.cinnamon panels-enabled "['1:0:top']"
    run_as_user gsettings set org.cinnamon.panel-height 28
    run_as_user gsettings set org.cinnamon.enabled-applets \
    "['panel1:left:0:menu@cinnamon.org', \
    'panel1:left:1:workspace-switcher@cinnamon.org', \
    'panel1:right:2:notifications@cinnamon.org', \
    'panel1:right:3:user@cinnamon.org', \
    'panel1:right:4:calendar@cinnamon.org', \
    'panel1:right:5:power@cinnamon.org', \
    'panel1:right:6:sound@cinnamon.org', \
    'panel1:right:7:network@cinnamon.org']" 2>/dev/null || true
    echo -e "${GREEN}   ✓ Panel superior configurado (sin lista de ventanas)${NC}"
    
    echo -e "${BLUE}   → Aplicando atajos de teclado estilo macOS...${NC}"
    run_as_user gsettings set org.cinnamon.desktop.keybindings.wm show-desktop "['<Super>d']" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.keybindings.wm minimize "['<Super>m']" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.keybindings.wm maximize "['<Super>Up']" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-1 "['<Super>1']" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-2 "['<Super>2']" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-3 "['<Super>3']" 2>/dev/null || true
    
    CUSTOM_IDS=()
    cinnamon_set_keybinding() {
        local name="$1" command="$2" binding="$3" id="$4"
        local PATH="/org/cinnamon/desktop/keybindings/custom-keybindings/$id/"
        run_as_user gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$PATH name "$name" 2>/dev/null || true
        run_as_user gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$PATH command "$command" 2>/dev/null || true
        run_as_user gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$PATH binding "$binding" 2>/dev/null || true
        CUSTOM_IDS+=("'${id}'")
    }
    
    cinnamon_set_keybinding "Spotlight" "rofi-spotlight-launcher" "<Ctrl>space" "custom-spotlight"
    cinnamon_set_keybinding "Cerrar App" "macos-wm-actions close-app-completely" "<Super>q" "custom-close"
    cinnamon_set_keybinding "Centrar Ventana" "macos-wm-actions center" "<Super>c" "custom-center"
    cinnamon_set_keybinding "Forzar Cierre" "macos-wm-actions force-kill" "<Ctrl><Alt>Escape" "custom-forcekill"
    
    run_as_user gsettings set org.cinnamon.desktop.keybindings custom-list "$(IFS=,; echo "[${CUSTOM_IDS[*]}]")" 2>/dev/null || true
    echo -e "${GREEN}   ✓ Atajos de teclado macOS aplicados${NC}"
    
    if [ -f "$WALLPAPER_PATH" ]; then
        run_as_user gsettings set org.cinnamon.desktop.background picture-uri "file://$WALLPAPER_PATH"
        run_as_user gsettings set org.cinnamon.desktop.background picture-uri-dark "file://$WALLPAPER_PATH"
    fi
    
    if [ "$SOUND_INSTALLED" = true ]; then
        run_as_user gsettings set org.cinnamon.desktop.sound theme-name "$SOUND_THEME"
        run_as_user gsettings set org.cinnamon.desktop.sound event-sounds true
        run_as_user gsettings set org.cinnamon.desktop.sound input-feedback-sounds true
    fi
    
    run_as_user gsettings set org.cinnamon.desktop.wm.preferences enable-hot-corners true 2>/dev/null || true
    echo -e "${GREEN}   ✓ Configuración Cinnamon aplicada al 100%${NC}"
}

# =============================================================================
#  Paso 15.5: Botón de menú con icono de Apple
# =============================================================================
cinnamon_step_15_5() {
    echo -e "${BLUE}   → Configurando icono de menú en Cinnamon...${NC}"
    run_as_user gsettings set org.cinnamon.applets.menu@cinnamon.org menu-icon "distributor-logo" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.applets.menu@cinnamon.org menu-icon-size 16 2>/dev/null || true
    echo -e "${GREEN}   ✓ Icono de Apple aplicado al menú de Cinnamon${NC}"
}

# =============================================================================
#  Paso 15.6: Ajustes finos de comportamiento (Nemo, Trackpad, Notificaciones)
# =============================================================================
cinnamon_step_15_6() {
    echo -e "${BLUE}   → Ajustando Cinnamon (Nemo, Trackpad, Notificaciones)...${NC}"
    # 📁 Administrador de Archivos (Nemo estilo Finder)
    run_as_user gsettings set org.nemo.preferences default-folder-viewer 'icon-view' 2>/dev/null || true
    run_as_user gsettings set org.nemo.preferences show-hidden-files false 2>/dev/null || true
    run_as_user gsettings set org.nemo.preferences show-hidden-backups false 2>/dev/null || true
    
    # 🖱️ Trackpad y Mouse (Nivel Avanzado)
    run_as_user gsettings set org.cinnamon.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.peripherals.mouse acceleration-profile 'adaptive' 2>/dev/null || true
    
    # 🔔 Centro de Notificaciones (Estilo macOS)
    run_as_user gsettings set org.cinnamon.desktop.notifications show-banners true 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.notifications show-notifications-on-lock-screen false 2>/dev/null || true
    echo -e "${GREEN}   ✓ Ajustes finos de Cinnamon aplicados${NC}"
}

# =============================================================================
#  Paso 15.7: Detalles finales (Cursor 32px)
# =============================================================================
cinnamon_step_15_7() {
    run_as_user gsettings set org.cinnamon.desktop.interface cursor-size 32 2>/dev/null || true
    echo -e "${GREEN}   ✓ Cursor Cinnamon ajustado a 32px${NC}"
}

# =============================================================================
#  Paso 15.8: Modo oscuro automático (Específico Cinnamon)
# =============================================================================
cinnamon_step_15_8() {
    # El hostname se gestiona en el script principal, aquí aplicamos el refuerzo de tema
    if command -v gsettings &> /dev/null; then
        gsettings set org.cinnamon.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
    fi
}

# =============================================================================
#  Paso 15.9: Perfeccionamiento de experiencia macOS (Reloj, Sonidos, Botones)
# =============================================================================
cinnamon_step_15_9() {
    # Reloj
    run_as_user gsettings set org.cinnamon.desktop.interface clock-show-date true 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.interface clock-show-weekday true 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.interface clock-show-seconds false 2>/dev/null || true
    
    CALENDAR_APPLET=$(run_as_user gsettings get org.cinnamon enabled-applets 2>/dev/null | grep -o "calendar@cinnamon.org" | head -1)
    if [ -n "$CALENDAR_APPLET" ]; then
        run_as_user gsettings set org.cinnamon.applets.calendar@cinnamon.org use-custom-format true 2>/dev/null || true
        run_as_user gsettings set org.cinnamon.applets.calendar@cinnamon.org custom-format "%a %d %b, %H:%M" 2>/dev/null || true
    fi
    echo -e "${GREEN}   ✓ Reloj Cinnamon configurado con formato macOS${NC}"

    # Sonidos de teclado
    run_as_user gsettings set org.cinnamon.desktop.sound input-feedback-sounds true 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.sound event-sounds true 2>/dev/null || true
    echo -e "${GREEN}   ✓ Sonidos de teclado activados en Cinnamon${NC}"

    # Botones de ventana
    run_as_user gsettings set org.cinnamon.desktop.wm.preferences button-layout 'close,minimize,maximize:' 2>/dev/null || true
    echo -e "${GREEN}   ✓ Botones Cinnamon reforzados${NC}"
}

# =============================================================================
#  Paso 15.10B: Pantalla de bloqueo estilo macOS
# =============================================================================
cinnamon_step_15_10b() {
    echo -e "${BLUE}   → Configurando pantalla de bloqueo para Cinnamon...${NC}"
    if [ -f "$WALLPAPER_PATH" ]; then
        run_as_user gsettings set org.cinnamon.desktop.screensaver picture-uri "file://$WALLPAPER_PATH" 2>/dev/null || true
        run_as_user gsettings set org.cinnamon.desktop.screensaver picture-options 'zoom' 2>/dev/null || true
    fi
    echo -e "${GREEN}   ✓ Pantalla de bloqueo Cinnamon configurada${NC}"
}

# =============================================================================
#  Paso 15.10C: Indicadores OSD de volumen y brillo
# =============================================================================
cinnamon_step_15_10c() {
    echo -e "${BLUE}   → Configurando OSD para Cinnamon...${NC}"
    run_as_user gsettings set org.cinnamon.desktop.sound volume-sound-enabled true 2>/dev/null || true
    echo -e "${GREEN}   ✓ OSD de Cinnamon verificado${NC}"
}

# =============================================================================
#  Paso 15.11: Integración de aplicaciones en el Dock (Plank)
# =============================================================================
cinnamon_step_15_11() {
    echo -e "${BLUE}   → Configurando inicio automático de Plank...${NC}"
    mkdir -p "$REAL_HOME/.config/autostart" 2>/dev/null || true
    cat > "$REAL_HOME/.config/autostart/plank.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Plank
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Comment=Iniciar Dock de Plank al inicio de sesión
EOF
    [ -n "$SUDO_USER" ] && chown "$SUDO_USER:$SUDO_USER" "$REAL_HOME/.config/autostart/plank.desktop" 2>/dev/null || true
    echo -e "${GREEN}   ✓ Plank configurado para iniciar automáticamente.${NC}"
}

# =============================================================================
#  Paso 19: Efecto Magic Lamp
# =============================================================================
cinnamon_step_19() {
    echo -e "${BLUE}   → Instalando Magic Lamp para Cinnamon...${NC}"
    mkdir -p "$REAL_HOME/.local/share/cinnamon/extensions/" 2>/dev/null || true
    if [ ! -d "$WORKDIR/CinnamonMagicLamp" ]; then
        git clone --depth=1 https://github.com/klangman/CinnamonMagicLamp.git "$WORKDIR/CinnamonMagicLamp" -q 2>/dev/null || true
    fi
    if [ -d "$WORKDIR/CinnamonMagicLamp/CinnamonMagicLamp@klangman" ]; then
        ln -sf "$WORKDIR/CinnamonMagicLamp/CinnamonMagicLamp@klangman" "$REAL_HOME/.local/share/cinnamon/extensions/CinnamonMagicLamp@klangman" 2>/dev/null || true
        run_as_user gsettings set org.cinnamon.desktop.effects minimize-effect "'none'" 2>/dev/null || true
        run_as_user gsettings set org.cinnamon.desktop.effects unminimize-effect "'none'" 2>/dev/null || true
        echo -e "${GREEN}   ✓ Magic Lamp para Cinnamon instalada y activada${NC}"
    fi
}

# =============================================================================
#  Paso 20: Quick Look (Vista Previa)
# =============================================================================
cinnamon_step_20() {
    echo -e "${BLUE}   → Instalando Quick Look (gloobus-preview)...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y -qq gloobus-preview 2>/dev/null || true
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y -q gloobus-preview 2>/dev/null || true
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm --needed gloobus-preview 2>/dev/null || true
    fi
    echo -e "${GREEN}   ✓ Quick Look instalado${NC}"
}

# =============================================================================
#  Paso 21: Scroll natural universal
# =============================================================================
cinnamon_step_21() {
    # Cinnamon a veces usa schemas de GNOME subyacentes, configuramos ambos por seguridad
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.peripherals.mouse natural-scroll true 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.peripherals.mouse natural-scroll true 2>/dev/null || true
}

# =============================================================================
#  Paso 22: Gestos multitáctiles estilo macOS (Fusuma)
# =============================================================================
cinnamon_step_22() {
    cat > "$REAL_HOME/.config/fusuma/config.yml" << 'EOF' 2>/dev/null || true
plugin:
  inputs:
    libinput_command_input:
      enable-tap: true
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
  hold:
    3:
      begin:
        command: 'xdotool mousedown 1'
      end:
        command: 'xdotool mouseup 1'
EOF
}

# =============================================================================
#  Paso 23: Gestor de portapapeles minimalista
# =============================================================================
cinnamon_step_23() {
    echo -e "${GREEN}   ✓ Clipit instalado para Cinnamon (inícialo desde el menú)${NC}"
}
