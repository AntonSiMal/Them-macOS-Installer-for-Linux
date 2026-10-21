#!/bin/bash
# =============================================================================
# Módulo Cinnamon - macOS Tahoe Installer
# Este archivo define funciones que son llamadas por install.sh
# =============================================================================

cinnamon_step_4() {
    echo -e "${YELLOW}🌅 [4/24] Instalando extensión 'Cinnamon Dynamic Wallpaper'...${NC}"
    mkdir -p "$REAL_HOME/.local/share/cinnamon/extensions/" 2>/dev/null || true
    [ ! -d "$WORKDIR/cinnamon-dynamic-wallpaper" ] && git clone --depth=1 https://github.com/TobiZog/cinnamon-dynamic-wallpaper.git "$WORKDIR/cinnamon-dynamic-wallpaper" -q 2>/dev/null || true
    if [ -d "$WORKDIR/cinnamon-dynamic-wallpaper/cinnamon-dynamic-wallpaper@TobiZog" ]; then
        cp -r "$WORKDIR/cinnamon-dynamic-wallpaper/cinnamon-dynamic-wallpaper@TobiZog" "$REAL_HOME/.local/share/cinnamon/extensions/" 2>/dev/null || true
        echo -e "${GREEN}   ✅ Extensión Dynamic Wallpaper instalada.${NC}"
        echo -e "${BLUE}   ℹ️  (Actívala manualmente desde 'Configuración > Applets' si deseas usarla)${NC}"
    fi
}

cinnamon_step_15() {
    echo -e "${BLUE}   → Configurando Cinnamon (Modo Seguro)...${NC}"
    run_as_user gsettings set org.cinnamon.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    
    if [ "${SF_INSTALLED:-false}" = true ]; then
        fc-cache -f "$REAL_HOME/.local/share/fonts" > /dev/null 2>&1 || true
        if fc-list 2>/dev/null | grep -qi "SF Pro"; then
            run_as_user gsettings set org.cinnamon.desktop.interface font-name 'SF Pro Text 11' 2>/dev/null || true
            run_as_user gsettings set org.cinnamon.desktop.interface document-font-name 'New York Medium 11' 2>/dev/null || true
            run_as_user gsettings set org.cinnamon.desktop.interface monospace-font-name 'SF Mono Regular 11' 2>/dev/null || true
            run_as_user gsettings set org.cinnamon.desktop.wm.preferences titlebar-font 'SF Pro Text 11' 2>/dev/null || true
            echo -e "${GREEN}   ✓ Fuentes Apple aplicadas correctamente${NC}"
        fi
    fi

    run_as_user gsettings set org.cinnamon.desktop.wm.preferences button-layout 'close,minimize,maximize:' 2>/dev/null || true
    echo -e "${GREEN}   ✓ Botones de ventana movidos a la izquierda${NC}"
    
    # 🛡️ SEGURO: Solo ajustamos la altura, NO reescribimos enabled-applets
    run_as_user gsettings set org.cinnamon.panel-height 28 2>/dev/null || true
    echo -e "${GREEN}   ✓ Altura del panel ajustada (28px)${NC}"
    
    echo -e "${BLUE}   → Aplicando atajos de teclado estilo macOS...${NC}"
    run_as_user gsettings set org.cinnamon.desktop.keybindings.wm show-desktop "['<Super>d']" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.keybindings.wm minimize "['<Super>m']" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.keybindings.wm maximize "['<Super>Up']" 2>/dev/null || true
    
    CUSTOM_IDS=()
    cinnamon_set_keybinding() {
        local name="$1" command="$2" binding="$3" id="$4"
        local SCHEMA_PATH="/org/cinnamon/desktop/keybindings/custom-keybindings/$id/"
        run_as_user gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:${SCHEMA_PATH}" name "$name" 2>/dev/null || true
        run_as_user gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:${SCHEMA_PATH}" command "$command" 2>/dev/null || true
        run_as_user gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:${SCHEMA_PATH}" binding "['$binding']" 2>/dev/null || true
        CUSTOM_IDS+=("'$SCHEMA_PATH'")
    }
    cinnamon_set_keybinding "Spotlight" "rofi-spotlight-launcher" "<Ctrl>space" "custom-spotlight"
    cinnamon_set_keybinding "Cerrar App" "macos-wm-actions close-app-completely" "<Super>q" "custom-close"
    
    if [ ${#CUSTOM_IDS[@]} -gt 0 ]; then
        CURRENT_LIST=$(run_as_user gsettings get org.cinnamon.desktop.keybindings custom-list 2>/dev/null || echo "[]")
        if [ "$CURRENT_LIST" = "[]" ]; then
            NEW_LIST="[$(IFS=,; echo "${CUSTOM_IDS[*]}")]"
        else
            CLEAN_LIST="${CURRENT_LIST%]}"
            NEW_LIST="${CLEAN_LIST}, $(IFS=,; echo "${CUSTOM_IDS[*]}")]"
        fi
        run_as_user gsettings set org.cinnamon.desktop.keybindings custom-list "$NEW_LIST" 2>/dev/null || true
    fi
    echo -e "${GREEN}   ✓ Atajos de teclado macOS aplicados${NC}"
}

cinnamon_step_15_5() {
    echo -e "${BLUE}   → Configurando icono de menú en Cinnamon...${NC}"
    run_as_user gsettings set org.cinnamon.applets.menu@cinnamon.org menu-icon "distributor-logo" 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.applets.menu@cinnamon.org menu-icon-size 16 2>/dev/null || true
    echo -e "${GREEN}   ✓ Icono de Apple aplicado al menú de Cinnamon${NC}"
    echo -e "${BLUE}   ℹ️  Si no cambia al instante, haz clic derecho en el panel > 'Solucionar problemas' > 'Reiniciar Cinnamon'${NC}"
}

cinnamon_step_15_6() {
    echo -e "${BLUE}   → Ajustando Cinnamon (Nemo, Trackpad, Notificaciones)...${NC}"
    run_as_user gsettings set org.nemo.preferences default-folder-viewer 'icon-view' 2>/dev/null || true
    run_as_user gsettings set org.nemo.preferences show-hidden-files false 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.notifications show-banners true 2>/dev/null || true
    echo -e "${GREEN}   ✓ Ajustes finos de Cinnamon aplicados${NC}"
}

cinnamon_step_15_7() {
    run_as_user gsettings set org.cinnamon.desktop.interface cursor-size 32 2>/dev/null || true
    echo -e "${GREEN}   ✓ Cursor Cinnamon ajustado a 32px${NC}"
}

cinnamon_step_15_9() {
    run_as_user gsettings set org.cinnamon.desktop.interface clock-show-date true 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.interface clock-show-weekday true 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.interface clock-show-seconds false 2>/dev/null || true
    echo -e "${GREEN}   ✓ Reloj Cinnamon configurado con formato macOS${NC}"
}

cinnamon_step_15_10b() {
    echo -e "${BLUE}   → Configurando pantalla de bloqueo para Cinnamon...${NC}"
    if [ -n "${WALLPAPER_PATH:-}" ] && [ -f "$WALLPAPER_PATH" ]; then
        run_as_user gsettings set org.cinnamon.desktop.screensaver picture-uri "file://$WALLPAPER_PATH" 2>/dev/null || true
        run_as_user gsettings set org.cinnamon.desktop.screensaver picture-options 'zoom' 2>/dev/null || true
    fi
    echo -e "${GREEN}   ✓ Pantalla de bloqueo Cinnamon configurada${NC}"
}

cinnamon_step_15_11() {
    echo -e "${BLUE}   → Configurando inicio automático de Plank...${NC}"
    mkdir -p "$REAL_HOME/.config/autostart" 2>/dev/null || true
    cat > "$REAL_HOME/.config/autostart/plank.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Plank
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Comment=Iniciar Dock de Plank al inicio de sesión
EOF
    [ -n "$SUDO_USER" ] && chown "$REAL_UID:$REAL_GID" "$REAL_HOME/.config/autostart/plank.desktop" 2>/dev/null || true
    echo -e "${GREEN}   ✓ Plank configurado para iniciar automáticamente.${NC}"
}

cinnamon_step_15_12() {
    echo -e "${BLUE}   → Configurando atajo 'Acerca de este Mac' (Super + I)...${NC}"
    if [ -n "${ABOUT_SCRIPT:-}" ] && [ -f "$ABOUT_SCRIPT" ]; then
        local CUSTOM_ABOUT_PATH="/org/cinnamon/desktop/keybindings/custom-keybindings/custom-about-mac/"
        run_as_user gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:${CUSTOM_ABOUT_PATH}" name "'Acerca de este Mac'" 2>/dev/null || true
        run_as_user gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:${CUSTOM_ABOUT_PATH}" command "'$ABOUT_SCRIPT'" 2>/dev/null || true
        run_as_user gsettings set "org.cinnamon.desktop.keybindings.custom-keybinding:${CUSTOM_ABOUT_PATH}" binding "['<Super>i']" 2>/dev/null || true
        
        local CURRENT_LIST
        CURRENT_LIST=$(run_as_user gsettings get org.cinnamon.desktop.keybindings custom-list 2>/dev/null || echo "[]")
        if [ "$CURRENT_LIST" = "[]" ] || [ -z "$CURRENT_LIST" ]; then
            run_as_user gsettings set org.cinnamon.desktop.keybindings custom-list "['$CUSTOM_ABOUT_PATH']" 2>/dev/null || true
        else
            local CLEAN_LIST="${CURRENT_LIST%]}"
            run_as_user gsettings set org.cinnamon.desktop.keybindings custom-list "${CLEAN_LIST}, '$CUSTOM_ABOUT_PATH']" 2>/dev/null || true
        fi
        echo -e "${GREEN}   ✓ Atajo Super+I asignado correctamente en Cinnamon${NC}"
    fi
}

cinnamon_step_17() {
    echo -e "${BLUE}   → Configurando Terminal estilo macOS para Cinnamon...${NC}"
    if command -v gnome-terminal &> /dev/null; then
        local PROFILE_ID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "macos-tahoe-cinnamon")
        run_as_user dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/visible-name "'macOS Tahoe'" 2>/dev/null || true
        run_as_user dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/font "'SF Mono 12'" 2>/dev/null || true
        run_as_user dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/background-color "'rgb(30,30,30)'" 2>/dev/null || true
        run_as_user dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/foreground-color "'rgb(230,230,230)'" 2>/dev/null || true
        run_as_user dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/use-system-font false 2>/dev/null || true
        run_as_user dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/cursor-shape "'ibeam'" 2>/dev/null || true
        echo -e "${GREEN}   ✓ Terminal configurada con SF Mono y colores macOS${NC}"
    fi
}

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

cinnamon_step_21() {
    run_as_user gsettings set org.cinnamon.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
    run_as_user gsettings set org.cinnamon.desktop.peripherals.mouse natural-scroll true 2>/dev/null || true
    echo -e "${GREEN}   ✓ Scroll natural aplicado a Cinnamon${NC}"
}

cinnamon_step_22() {
    mkdir -p "$REAL_HOME/.config/fusuma" 2>/dev/null || true
    cat > "$REAL_HOME/.config/fusuma/config.yml" << 'EOF' 2>/dev/null || true
plugin:
  inputs:
    libinput_command_input:
      enable-tap: true
  swipe:
    3:
      left: { command: 'xdotool key ctrl+alt+Right' }
      right: { command: 'xdotool key ctrl+alt+Left' }
      up: { command: 'xdotool key super+d' }
      down: { command: 'xdotool key super+d' }
    4:
      left: { command: 'xdotool key alt+Left' }
      right: { command: 'xdotool key alt+Right' }
      up: { command: 'xdotool key super+s' }
      down: { command: 'xdotool key super+s' }
  pinch:
    2:
      in: { command: 'xdotool keydown ctrl click 4 keyup ctrl' }
      out: { command: 'xdotool keydown ctrl click 5 keyup ctrl' }
EOF
}

cinnamon_step_23() {
    echo -e "${GREEN}   ✓ Clipit instalado para Cinnamon (inícialo desde el menú)${NC}"
}
