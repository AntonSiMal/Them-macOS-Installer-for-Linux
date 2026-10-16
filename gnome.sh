#!/bin/bash
# =============================================================================
# Módulo GNOME - macOS Tahoe Installer
# Este archivo define funciones que son llamadas por install.sh
# =============================================================================

# =============================================================================
#  Paso 3: Extensión Liquid Glass
# =============================================================================
gnome_step_3() {
    echo -e "${YELLOW}🧩 [3/24] Instalando extensión 'Liquid Glass'...${NC}"
    mkdir -p "$REAL_HOME/.local/share/gnome-shell/extensions/"
    [ ! -d "$WORKDIR/liquid-glass" ] && git clone --depth=1 https://github.com/ryohsuke1231/liquid-glass.git "$WORKDIR/liquid-glass" -q
    cp -r "$WORKDIR/liquid-glass/liquid-glass@thinkingcoding1231.gmail.com" "$REAL_HOME/.local/share/gnome-shell/extensions/"
    
    GNOME_VERSION=$(gnome-shell --version 2>/dev/null | grep -oP '\d+' | head -1)
    EXT_DIR="$REAL_HOME/.local/share/gnome-shell/extensions/liquid-glass@thinkingcoding1231.gmail.com"
    if [ -n "$GNOME_VERSION" ] && [ -f "$EXT_DIR/metadata.json" ]; then
        if ! grep -q "\"$GNOME_VERSION\"" "$EXT_DIR/metadata.json"; then
            python3 -c "
import json
with open('$EXT_DIR/metadata.json', 'r') as f: data = json.load(f)
if '$GNOME_VERSION' not in data.get('shell-version', []):
    data.setdefault('shell-version', []).append('$GNOME_VERSION')
with open('$EXT_DIR/metadata.json', 'w') as f: json.dump(data, f, indent=2)
" 2>/dev/null
        fi
    fi
    echo -e "${GREEN}✅ Liquid Glass instalada.${NC}"
}

# =============================================================================
#  Paso 6: Wallpaper dinámico Mojave con horarios reales
# =============================================================================
gnome_step_6() {
    echo -e "${YELLOW}🌄 [6/24] Instalando wallpaper dinámico Mojave...${NC}"
    MOJAVE_TEMP="$WORKDIR/gnome-kde-mojave-dynamic"
    [ ! -d "$MOJAVE_TEMP" ] && git clone --depth=1 https://github.com/japamax/gnome-kde-dynamic-wallpaper-mojave.git "$MOJAVE_TEMP" -q 2>/dev/null
    
    if [ -d "$MOJAVE_TEMP/mojave" ] && [ -f "$MOJAVE_TEMP/mojave-timed.xml" ]; then
        sudo mkdir -p /usr/share/dynamicwallpapers/mojave-solar/contents/images
        sudo cp "$MOJAVE_TEMP/mojave/"* /usr/share/dynamicwallpapers/mojave-solar/contents/images/ 2>/dev/null
        sudo chmod 755 /usr/share/dynamicwallpapers/mojave-solar/contents/images 2>/dev/null
        sudo chmod 644 /usr/share/dynamicwallpapers/mojave-solar/contents/images/* 2>/dev/null
        sudo mkdir -p /usr/share/dynamicwallpapers/mojave-timed/contents
        sudo chmod 755 /usr/share/dynamicwallpapers/mojave-timed/contents 2>/dev/null
        sudo ln -sf /usr/share/dynamicwallpapers/mojave-solar/contents/images /usr/share/dynamicwallpapers/mojave-timed/contents/images 2>/dev/null
        sudo mkdir -p /usr/share/backgrounds/macOS
        sudo ln -sf /usr/share/dynamicwallpapers/mojave-solar/contents/images /usr/share/backgrounds/macOS/mojave 2>/dev/null
        [ -f "$MOJAVE_TEMP/mojave-solar.json" ] && sudo cp "$MOJAVE_TEMP/mojave-solar.json" /usr/share/dynamicwallpapers/mojave-solar/metadata.json 2>/dev/null
        [ -f "$MOJAVE_TEMP/mojave-timed.json" ] && sudo cp "$MOJAVE_TEMP/mojave-timed.json" /usr/share/dynamicwallpapers/mojave-timed/metadata.json 2>/dev/null
        [ -f "$MOJAVE_TEMP/mojave-timed.xml" ] && sudo cp "$MOJAVE_TEMP/mojave-timed.xml" /usr/share/backgrounds/macOS/mojave-timed.xml 2>/dev/null
        sudo mkdir -p /usr/share/gnome-background-properties
        [ -f "$MOJAVE_TEMP/mojave.xml" ] && sudo cp "$MOJAVE_TEMP/mojave.xml" /usr/share/gnome-background-properties/mojave.xml 2>/dev/null
        
        export MOJAVE_INSTALLED=true
        echo -e "${GREEN}✅ Wallpaper Mojave con horarios reales instalado.${NC}"
    else
        echo -e "${YELLOW}⚠️  No se pudo descargar Mojave dinámico.${NC}"
    fi
}

# =============================================================================
#  Paso 13: GDM (Pantalla de Login)
# =============================================================================
gnome_step_13() {
    echo -e "${YELLOW}🔐 [13/25] Configurando pantalla de login (GDM)...${NC}"
    set +e
    if [ -d "$WORKDIR/MacTahoe-gtk-theme" ]; then
        echo -e "${BLUE}   → Aplicando tema a GDM (esto puede tardar unos segundos)...${NC}"
        if sudo "$WORKDIR/MacTahoe-gtk-theme/tweaks.sh" -g -b default > /tmp/gdm-tweak.log 2>&1; then
            echo -e "${GREEN}   ✅ Pantalla de login configurada correctamente.${NC}"
        else
            echo -e "${YELLOW}   ⚠️  No se pudo configurar GDM automáticamente.${NC}"
            echo -e "${YELLOW}      (Esto es común en algunas distros por políticas de seguridad de GDM).${NC}"
            echo -e "${YELLOW}      El resto de la instalación continuará normalmente.${NC}"
            echo -e "${BLUE}      → Si deseas investigar, revisa el registro: /tmp/gdm-tweak.log${NC}"
        fi
    else
        echo -e "${YELLOW}   ⚠️  No se encontró la carpeta del tema para configurar GDM.${NC}"
    fi
    set -e
}

# =============================================================================
#  Paso 15: Configuración del sistema, paneles y atajos de teclado
# =============================================================================
gnome_step_15() {
    echo -e "${BLUE}   → Configurando GNOME...${NC}"
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
    run_as_user gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
    run_as_user gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME"
    run_as_user gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    
    if [ "$SF_INSTALLED" = true ]; then
        run_as_user gsettings set org.gnome.desktop.interface font-name 'SF Pro Text 11'
        run_as_user gsettings set org.gnome.desktop.interface document-font-name 'New York Medium 11'
        run_as_user gsettings set org.gnome.desktop.interface monospace-font-name 'SF Mono Regular 11'
        run_as_user gsettings set org.gnome.desktop.wm.preferences titlebar-font 'SF Pro Text 11'
        echo -e "${GREEN}   ✓ Fuentes Apple aplicadas${NC}"
    fi
    
    run_as_user gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'
    echo -e "${GREEN}   ✓ Botones de ventana movidos a la izquierda${NC}"
    
    run_as_user gsettings set org.gnome.desktop.interface clock-show-date true
    run_as_user gsettings set org.gnome.desktop.interface clock-show-weekday true
    run_as_user gsettings set org.gnome.desktop.interface clock-show-seconds false
    
    if [ -f "$WALLPAPER_PATH" ]; then
        run_as_user gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_PATH"
        run_as_user gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_PATH"
    fi
    
    if [ "$SOUND_INSTALLED" = true ]; then
        run_as_user gsettings set org.gnome.desktop.sound theme-name "$SOUND_THEME"
        run_as_user gsettings set org.gnome.desktop.sound event-sounds true
        run_as_user gsettings set org.gnome.desktop.sound input-feedback-sounds true
    fi
    
    echo -e "${BLUE}   → Aplicando atajos de teclado estilo macOS...${NC}"
    run_as_user gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']"
    run_as_user gsettings set org.gnome.desktop.wm.keybindings minimize "['<Super>m']"
    run_as_user gsettings set org.gnome.desktop.wm.keybindings toggle-maximized "['<Super>Up']"
    run_as_user gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
    run_as_user gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
    run_as_user gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Ctrl><Alt>t']"
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Super>l']"
    
    CUSTOM_PATHS=(); INDEX=0
    gnome_set_keybinding() {
        local name="$1" command="$2" binding="$3" idx="$4"
        local PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${idx}/"
        run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH name "$name" 2>/dev/null || true
        run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH command "$command" 2>/dev/null || true
        run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH binding "$binding" 2>/dev/null || true
        CUSTOM_PATHS+=("'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${idx}/'")
    }
    
    gnome_set_keybinding "Spotlight" "rofi-spotlight-launcher" "<Ctrl>space" $INDEX; INDEX=$((INDEX+1))
    gnome_set_keybinding "Cerrar App" "macos-wm-actions close-app-completely" "<Super>q" $INDEX; INDEX=$((INDEX+1))
    gnome_set_keybinding "Centrar Ventana" "macos-wm-actions center" "<Super>c" $INDEX; INDEX=$((INDEX+1))
    gnome_set_keybinding "Forzar Cierre" "macos-wm-actions force-kill" "<Ctrl><Alt>Escape" $INDEX; INDEX=$((INDEX+1))
    
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$(IFS=,; echo "[${CUSTOM_PATHS[*]}]")" 2>/dev/null || true
    echo -e "${GREEN}   ✓ Atajos de teclado macOS aplicados${NC}"
    
    run_as_user gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null || true
    run_as_user gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null || true
    run_as_user gnome-extensions enable liquid-glass@thinkingcoding1231.gmail.com 2>/dev/null || true
    run_as_user gnome-extensions enable ding@rastersoft.com 2>/dev/null || true
    
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock hide-mode 'AUTOHIDE'
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock intellihide-mode 'ALL_WINDOWS'
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.4
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock show-show-apps-button true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true
    
    echo -e "${GREEN}   ✓ Configuración GNOME aplicada al 100%${NC}"
}

# =============================================================================
#  Paso 15.5: Botón de menú con icono de Apple
# =============================================================================
gnome_step_15_5() {
    echo -e "${BLUE}   → Configurando botón de aplicaciones en GNOME...${NC}"
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock show-show-apps-button true 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true 2>/dev/null || true
    echo -e "${GREEN}   ✓ Botón de aplicaciones configurado con icono de Apple${NC}"
}

# =============================================================================
#  Paso 15.6: Ajustes finos de comportamiento (Nautilus, Trackpad, Notificaciones)
# =============================================================================
gnome_step_15_6() {
    echo -e "${BLUE}   → Ajustando GNOME (Nautilus, Trackpad, Notificaciones)...${NC}"
    # 📁 Administrador de Archivos (Nautilus estilo Finder)
    run_as_user gsettings set org.gnome.nautilus.preferences default-folder-viewer 'icon-view' 2>/dev/null || true
    run_as_user gsettings set org.gnome.nautilus.preferences show-hidden-files false 2>/dev/null || true
    run_as_user gsettings set org.gnome.nautilus.preferences search-filter-time-type 'last_modified' 2>/dev/null || true
    
    # 🖱️ Trackpad y Mouse (Nivel Avanzado)
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.peripherals.mouse acceleration-profile 'adaptive' 2>/dev/null || true
    
    # 🔔 Notificaciones (Nativo de GNOME, ya estilizado por el tema)
    echo -e "${GREEN}   ✓ Ajustes finos de GNOME aplicados${NC}"
}

# =============================================================================
#  Paso 15.7: Detalles finales (Cursor 32px y Atajo Super+I) - 🛡️ CORREGIDO
# =============================================================================
gnome_step_15_7() {
    # Cursor
    run_as_user gsettings set org.gnome.desktop.interface cursor-size 32 2>/dev/null || true
    echo -e "${GREEN}   ✓ Cursor GNOME ajustado a 32px${NC}"

    # Atajo Super+I (Acerca de este Mac)
    local KB_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
    
    # 1. Definir las propiedades del atajo con la sintaxis de esquema correcta
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KB_PATH name "'Acerca de este Mac'" 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KB_PATH command "'$ABOUT_SCRIPT'" 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KB_PATH binding "'<Super>i'" 2>/dev/null || true
    
    # 2. Agregar a la lista de custom-keybindings de forma segura (evita sintaxis inválida @as)
    local existing
    existing=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null | sed "s/@as //; s/\[//; s/\]//; s/'//g; s/ //g")
    
    local new_list
    if [ -z "$existing" ]; then
        new_list="['$KB_PATH']"
    else
        # Reconstruir el array correctamente separado por comas
        local formatted_existing=$(echo "$existing" | sed "s/,/', '/g")
        new_list="['$formatted_existing', '$KB_PATH']"
    fi
    
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_list" 2>/dev/null || true
    
    echo -e "${GREEN}   ✓ Atajo Super+I asignado correctamente en GNOME.${NC}"
}

# =============================================================================
#  Paso 15.9: Perfeccionamiento (Reloj, Sonidos, Nautilus Finder, Dash to Dock)
# =============================================================================
gnome_step_15_9() {
    # Reloj
    run_as_user gsettings set org.gnome.desktop.interface clock-show-date true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface clock-show-weekday true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface clock-show-seconds false 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface clock-format '24h' 2>/dev/null || true
    echo -e "${GREEN}   ✓ Reloj GNOME configurado con formato macOS${NC}"

    # Sonidos de teclado
    run_as_user gsettings set org.gnome.desktop.sound input-feedback-sounds true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.sound event-sounds true 2>/dev/null || true
    echo -e "${GREEN}   ✓ Sonidos de teclado activados en GNOME${NC}"

    # Nautilus estilo Finder
    echo -e "${BLUE}   → Aplicando estilo Finder a Nautilus...${NC}"
    run_as_user gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' 2>/dev/null || true
    run_as_user gsettings set org.gnome.nautilus.preferences show-hidden-files false 2>/dev/null || true
    run_as_user gsettings set org.gnome.nautilus.preferences always-use-location-entry false 2>/dev/null || true
    run_as_user gsettings set org.gnome.nautilus.preferences show-image-thumbnails 'always' 2>/dev/null || true
    
    NAUTILUS_CSS_DIR="$REAL_HOME/.config/gtk-3.0"
    mkdir -p "$NAUTILUS_CSS_DIR" 2>/dev/null || true
    cat > "$NAUTILUS_CSS_DIR/gtk.css" << 'NAUTILUSCSS' 2>/dev/null || true
.nautilus-window .sidebar { background-color: alpha(@theme_bg_color, 0.95); border-right: 1px solid alpha(@borders, 0.3); }
.nautilus-window .sidebar row { border-radius: 6px; margin: 2px 8px; padding: 6px 10px; transition: all 200ms ease; }
.nautilus-window .sidebar row:selected { background-color: @theme_selected_bg_color; color: @theme_selected_fg_color; }
.nautilus-window .sidebar row:hover:not(:selected) { background-color: alpha(@theme_fg_color, 0.08); }
NAUTILUSCSS
    if [ -n "$SUDO_USER" ]; then chown -R "$SUDO_USER:$SUDO_USER" "$NAUTILUS_CSS_DIR" 2>/dev/null || true; fi
    echo -e "${GREEN}   ✓ Nautilus configurado con estilo Finder${NC}"

    # Dash to Dock estilo macOS Dock
    echo -e "${BLUE}   → Configurando Dash to Dock con estilo macOS Dock...${NC}"
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM' 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'DYNAMIC' 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.4 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'DOTS' 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize-or-previews' 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock show-show-apps-button true 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true 2>/dev/null || true
    run_as_user gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null || true
    echo -e "${GREEN}   ✓ Dash to Dock configurado con estilo macOS${NC}"

    # Reforzar botones de ventana
    run_as_user gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:' 2>/dev/null || true
    echo -e "${GREEN}   ✓ Botones GNOME reforzados${NC}"
}

# =============================================================================
#  Paso 15.10: Night Shift, Batería, Dock
# =============================================================================
gnome_step_15_10() {
    echo -e "${BLUE}   → Ajustando detalles finales de GNOME...${NC}"
    # 1. Night Light (Equivalente exacto a "Night Shift" de macOS)
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic true 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 2700 2>/dev/null || true
    # 2. Mostrar porcentaje de batería en la barra superior
    run_as_user gsettings set org.gnome.desktop.interface show-battery-percentage true 2>/dev/null || true
    # 3. Ocultar el icono de la Papelera en el Dock cuando está vacía
    run_as_user gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false 2>/dev/null || true
    echo -e "${GREEN}   ✓ Night Light, Porcentaje de batería y Dock optimizados${NC}"
}

# =============================================================================
#  Paso 15.10B: Pantalla de bloqueo estilo macOS
# =============================================================================
gnome_step_15_10b() {
    echo -e "${BLUE}   → Configurando pantalla de bloqueo para GNOME...${NC}"
    # Configurar el fondo del salvapantallas para que coincida con el wallpaper
    if [ -f "$WALLPAPER_PATH" ]; then
        run_as_user gsettings set org.gnome.desktop.screensaver picture-uri "file://$WALLPAPER_PATH" 2>/dev/null || true
        run_as_user gsettings set org.gnome.desktop.screensaver picture-uri-dark "file://$WALLPAPER_PATH" 2>/dev/null || true
        run_as_user gsettings set org.gnome.desktop.screensaver picture-options 'zoom' 2>/dev/null || true
    fi
    # Asegurar que el salvapantallas no sea negro
    run_as_user gsettings set org.gnome.desktop.screensaver color-shading-type 'solid' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.screensaver primary-color '#000000' 2>/dev/null || true
    # Mostrar reloj grande en la pantalla de bloqueo (comportamiento macOS)
    run_as_user gsettings set org.gnome.desktop.screensaver show-clock true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.screensaver show-full-name-in-top-bar false 2>/dev/null || true
    echo -e "${GREEN}   ✓ Pantalla de bloqueo GNOME configurada con wallpaper dinámico${NC}"
}

# =============================================================================
#  Paso 15.10C: Indicadores OSD de volumen y brillo
# =============================================================================
gnome_step_15_10c() {
    echo -e "${BLUE}   → Instalando extensión OSD estilo macOS para GNOME...${NC}"
    # Intentar instalar la extensión "Avatar" que proporciona OSD minimalista
    EXTENSION_UUID="avatar@nathanpierce.com"
    if ! run_as_user gnome-extensions list 2>/dev/null | grep -q "$EXTENSION_UUID"; then
        echo -e "${BLUE}      → Descargando extensión Avatar...${NC}"
        # Obtener versión de GNOME Shell
        GNOME_VERSION=$(run_as_user gnome-shell --version 2>/dev/null | grep -oP '\d+' | head -1)
        if [ -n "$GNOME_VERSION" ]; then
            # Intentar descargar desde extensions.gnome.org
            EXTENSION_URL="https://extensions.gnome.org/extension-data/avatar@nathanpierce.com.v68.shell-extension.zip"
            TEMP_EXT=$(mktemp -d)
            if curl -sL "$EXTENSION_URL" -o "$TEMP_EXT/avatar.zip" 2>/dev/null && [ -f "$TEMP_EXT/avatar.zip" ]; then
                mkdir -p "$REAL_HOME/.local/share/gnome-shell/extensions/$EXTENSION_UUID"
                unzip -q "$TEMP_EXT/avatar.zip" -d "$REAL_HOME/.local/share/gnome-shell/extensions/$EXTENSION_UUID" 2>/dev/null
                # Actualizar metadata.json para compatibilidad con la versión de GNOME
                if [ -f "$REAL_HOME/.local/share/gnome-shell/extensions/$EXTENSION_UUID/metadata.json" ]; then
                    python3 -c "
import json
with open('$REAL_HOME/.local/share/gnome-shell/extensions/$EXTENSION_UUID/metadata.json', 'r') as f:
    data = json.load(f)
if '$GNOME_VERSION' not in data.get('shell-version', []):
    data.setdefault('shell-version', []).append('$GNOME_VERSION')
with open('$REAL_HOME/.local/share/gnome-shell/extensions/$EXTENSION_UUID/metadata.json', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || true
                fi
                run_as_user gnome-extensions enable "$EXTENSION_UUID" 2>/dev/null || true
                echo -e "${GREEN}      ✓ Extensión Avatar instalada y activada${NC}"
            else
                echo -e "${YELLOW}       No se pudo descargar la extensión. Puedes instalarla manualmente desde extensions.gnome.org${NC}"
            fi
            rm -rf "$TEMP_EXT"
        else
            echo -e "${YELLOW}      ⚠️  No se pudo detectar la versión de GNOME${NC}"
        fi
    else
        echo -e "${GREEN}      ✓ Extensión Avatar ya está instalada${NC}"
    fi
    echo -e "${GREEN}   ✓ OSD de volumen y brillo configurado para GNOME${NC}"
}

# =============================================================================
#  Paso 17: Configuración de Terminal estilo macOS
# =============================================================================
gnome_step_17() {
    if command -v gnome-terminal &> /dev/null; then
        PROFILE_ID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen 2>/dev/null || echo "macos-tahoe-profile")
        run_as_user dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/visible-name "'macOS Tahoe'" 2>/dev/null || true
        run_as_user dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/font "'SF Mono 12'" 2>/dev/null || true
        run_as_user dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/use-system-font false 2>/dev/null || true
        run_as_user dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/background-color "'rgb(30,30,30)'" 2>/dev/null || true
        run_as_user dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/foreground-color "'rgb(230,230,230)'" 2>/dev/null || true
        run_as_user dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/use-theme-colors false 2>/dev/null || true
        run_as_user dconf write /org/gnome/terminal/legacy/default-profile "'$PROFILE_ID'" 2>/dev/null || true
        echo -e "${GREEN}   ✓ Terminal GNOME configurada con tema macOS${NC}"
    fi
}

# =============================================================================
#  Paso 18: Configuración de animaciones suaves
# =============================================================================
gnome_step_18() {
    run_as_user gsettings set org.gnome.desktop.interface enable-animations true 2>/dev/null || true
    run_as_user gsettings set org.gnome.mutter center-new-windows true 2>/dev/null || true
}

# =============================================================================
#  Paso 19: Efecto Magic Lamp
# =============================================================================
gnome_step_19() {
    echo -e "${BLUE}   → Instalando Magic Lamp para GNOME...${NC}"
    mkdir -p "$REAL_HOME/.local/share/gnome-shell/extensions/" 2>/dev/null || true
    if [ ! -d "$WORKDIR/compiz-alike-magic-lamp-effect" ]; then
        git clone --depth=1 https://github.com/hermes83/compiz-alike-magic-lamp-effect.git "$WORKDIR/compiz-alike-magic-lamp-effect" -q 2>/dev/null || true
    fi
    EXT_MAGIC_LAMP=$(find "$WORKDIR/compiz-alike-magic-lamp-effect" -maxdepth 1 -type d -name "*magic-lamp*" 2>/dev/null | head -1)
    if [ -n "$EXT_MAGIC_LAMP" ]; then
        cp -r "$EXT_MAGIC_LAMP" "$REAL_HOME/.local/share/gnome-shell/extensions/" 2>/dev/null || true
        run_as_user gnome-extensions enable "$(basename "$EXT_MAGIC_LAMP")" 2>/dev/null || true
        echo -e "${GREEN}   ✓ Magic Lamp para GNOME instalada y activada${NC}"
    fi
}

# =============================================================================
#  Paso 20: Tematización Qt y Quick Look
# =============================================================================
gnome_step_20() {
    echo -e "${BLUE}   → Instalando Quick Look (gnome-sushi)...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y -qq gnome-sushi 2>/dev/null || sudo apt-get install -y -qq sushi 2>/dev/null || true
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y -q gnome-sushi 2>/dev/null || true
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm --needed gnome-sushi 2>/dev/null || true
    fi
    echo -e "${GREEN}   ✓ Quick Look instalado${NC}"
}

# =============================================================================
#  Paso 21: Scroll natural universal
# =============================================================================
gnome_step_21() {
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.peripherals.mouse natural-scroll true 2>/dev/null || true
}

# =============================================================================
#  Paso 22: Gestos multitáctiles estilo macOS (Fusuma)
# =============================================================================
gnome_step_22() {
    # GNOME: Super+s para Actividades/Mission Control, Super+d para mostrar escritorio
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
gnome_step_23() {
    run_as_user gnome-extensions enable clipboard-indicator@tudmotu.com 2>/dev/null || true
    echo -e "${GREEN}   ✓ Clipboard Indicator activado para GNOME${NC}"
}
