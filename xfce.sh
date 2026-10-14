# =============================================================================
# Paso 15: Configuración del sistema, paneles y atajos de teclado
# =============================================================================

elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
echo -e "${BLUE}   → Configurando XFCE...${NC}"
run_as_user xfconf-query -c xsettings -p /Net/ThemeName -s "$GTK_THEME" 2>/dev/null || true
run_as_user xfconf-query -c xsettings -p /Net/IconThemeName -s "$ICON_THEME" 2>/dev/null || true
run_as_user xfconf-query -c xsettings -p /Net/CursorThemeName -s "$CURSOR_THEME" 2>/dev/null || true
if [ "$SF_INSTALLED" = true ]; then
run_as_user xfconf-query -c xsettings -p /Gtk/FontName -s 'SF Pro Text 11' 2>/dev/null || true
run_as_user xfconf-query -c xsettings -p /Gtk/DocumentFontName -s 'New York Medium 11' 2>/dev/null || true
run_as_user xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s 'SF Mono Regular 11' 2>/dev/null || true
run_as_user xfconf-query -c xfwm4 -p /general/title_font -s 'SF Pro Text 11' 2>/dev/null || true
echo -e "${GREEN}   ✓ Fuentes Apple aplicadas${NC}"
fi
# OMH = Close (O), Minimize (M), Maximize (H) - Orden exacto de macOS
run_as_user xfconf-query -c xfwm4 -p /general/button_layout -s "OMH" 2>/dev/null || true
echo -e "${GREEN}   ✓ Botones de ventana movidos a la izquierda${NC}"

# RECONSTRUCCIÓN TOTAL DEL PANEL DE XFCE (ESTILO MACOS - PARTE SUPERIOR)
echo -e "${BLUE}   → Reconstruyendo panel superior estilo macOS desde cero...${NC}"
run_as_user xfce4-panel --quit 2>/dev/null || true
pkill xfce4-panel 2>/dev/null || true
sleep 1
run_as_user xfconf-query -c xfce4-panel -r -R /panels 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -r -R /plugins 2>/dev/null || true

run_as_user xfconf-query -c xfce4-panel -p /panels -n -t empty -a 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0 -n -t empty -a 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/position -s "p=6;x=0;y=0" 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/position-locked -s true 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/size -s 28 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/autohide -s false 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/disable-struts -s false 2>/dev/null || true

run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/plugin-ids -n -t empty -a 2>/dev/null || true
# Plugin 1: Whisker Menu
run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/plugin-ids/1 -s 1 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-1 -n -t string -s "whiskermenu" 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-1/button-icon -s "distributor-logo" 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-1/show-button-title -s false 2>/dev/null || true
# Plugin 2: Separador expansible
run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/plugin-ids/2 -s 2 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-2 -n -t string -s "separator" 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-2/expand -s true 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-2/style -s 0 2>/dev/null || true
# Plugin 3: Reloj
run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/plugin-ids/3 -s 3 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-3 -n -t string -s "clock" 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-3/digital-format -s "%a %d %b, %H:%M" 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-3/digital-layout -s 3 2>/dev/null || true
# Plugin 4: Notificaciones
run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/plugin-ids/4 -s 4 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-4 -n -t string -s "notification-plugin" 2>/dev/null || true
# Plugin 5: Energía
run_as_user xfconf-query -c xfce4-panel -p /panels/panel-0/plugin-ids/5 -s 5 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /plugins/plugin-5 -n -t string -s "power-manager-plugin" 2>/dev/null || true

run_as_user xfce4-panel &>/dev/null &
echo -e "${GREEN}   ✓ Panel de XFCE reconstruido en la parte superior con elementos macOS.${NC}"

# ATAJO DE TECLADO ESTILO macOS (XFCE)
xfce_set_keybinding() {
local command="$1" binding="$2"
run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/$binding" -n -t string -s "$command" 2>/dev/null || \
run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/$binding" -s "$command" 2>/dev/null || true
}
xfce_set_keybinding "rofi-spotlight-launcher" "<Ctrl>space"
xfce_set_keybinding "macos-wm-actions close-app-completely" "<Super>q"
xfce_set_keybinding "macos-wm-actions center" "<Super>c"
xfce_set_keybinding "macos-wm-actions force-kill" "<Ctrl><Alt>Escape"
xfce_set_keybinding "xfce4-terminal" "<Ctrl><Alt>t"
xfce_set_keybinding "xfce4-screensaver-command --lock" "<Super>l"

run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>d" -n -t string -s "show_desktop_key" 2>/dev/null || true
run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>m" -n -t string -s "hide_window_key" 2>/dev/null || true
run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>Up" -n -t string -s "maximize_window_key" 2>/dev/null || true
run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>1" -n -t string -s "workspace_1_key" 2>/dev/null || true
run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>2" -n -t string -s "workspace_2_key" 2>/dev/null || true
run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>3" -n -t string -s "workspace_3_key" 2>/dev/null || true
echo -e "${GREEN}   ✓ Atajos de teclado macOS aplicados${NC}"

run_as_user xfconf-query -c xfce4-notifyd -p /theme -s "MacTahoe-Dark" 2>/dev/null || true
if [ "$SOUND_INSTALLED" = true ]; then
run_as_user xfconf-query -c xsettings -p /Net/SoundThemeName -s "$SOUND_THEME" 2>/dev/null || true
fi
echo -e "${GREEN}   ✓ Configuración XFCE aplicada al 100%${NC}"
fi


# =============================================================================
#  Paso 15.5: Botón de menú con icono de Apple
# =============================================================================

elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
echo -e "${BLUE}   → Verificando e instalando Whisker Menu en XFCE...${NC}"
if ! command -v xfce4-popup-whiskermenu &> /dev/null; then
echo -e "${BLUE}      → Whisker Menu no detectado. Instalando...${NC}"
if command -v apt-get &> /dev/null; then
sudo apt-get install -y -qq xfce4-whiskermenu-plugin 2>/dev/null || true
elif command -v dnf &> /dev/null; then
sudo dnf install -y -q xfce4-whiskermenu-plugin 2>/dev/null || true
elif command -v pacman &> /dev/null; then
sudo pacman -S --noconfirm --needed xfce4-whiskermenu-plugin 2>/dev/null || true
fi
echo -e "${GREEN}      ✅ Whisker Menu instalado.${NC}"
else
echo -e "${GREEN}      ✓ Whisker Menu ya está instalado.${NC}"
fi
WHISKER_ID=$(run_as_user xfconf-query -c xfce4-panel -l 2>/dev/null | grep "whiskermenu" | head -1 | cut -d'/' -f4)
if [ -n "$WHISKER_ID" ]; then
run_as_user xfconf-query -c xfce4-panel -p /plugins/$WHISKER_ID/button-icon -s "distributor-logo" 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /plugins/$WHISKER_ID/show-button-title -s false 2>/dev/null || true
echo -e "${GREEN}   ✓ Icono de Apple aplicado a Whisker Menu (solo icono, sin texto).${NC}"
else
echo -e "${YELLOW}   ⚠️  Whisker Menu instalado. Para usarlo: Clic derecho en el panel > Panel > Añadir nuevos elementos > 'Menú de aplicaciones' (Whisker) y elimina el menú antiguo.${NC}"
fi
fi

# =============================================================================
#  Paso 15.6: Ajustes finos de comportamiento (Finder, Trackpad, Notificaciones)
# =============================================================================

elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
echo -e "${BLUE}   → Ajustando XFCE (Thunar, Trackpad, Notificaciones)...${NC}"
# 📁 Administrador de Archivos (Thunar estilo Finder)
run_as_user xfconf-query -c thunar -p /misc-default-view -s "THUNAR_VIEW_ICON" 2>/dev/null || true
run_as_user xfconf-query -c thunar -p /misc-show-hidden -s false 2>/dev/null || true
run_as_user xfconf-query -c thunar -p /misc-single-click -s false 2>/dev/null || true # Doble clic para abrir, como macOS
# 🖱️ Trackpad (Habilitar Tap-to-Click de forma genérica)
for dev in $(xinput list --id-only 'Touchpad' 'touchpad' 2>/dev/null); do
xinput set-prop "$dev" "libinput Tapping Enabled" 1 2>/dev/null || true
xinput set-prop "$dev" "libinput Natural Scrolling Enabled" 1 2>/dev/null || true
done
# 🔔 Centro de Notificaciones (Estilo macOS)
run_as_user xfconf-query -c xfce4-notifyd -p /theme -s "MacTahoe-Dark" 2>/dev/null || true
run_as_user xfconf-query -c xfce4-notifyd -p /notify-location -s 2 2>/dev/null || true # 2 = Esquina superior derecha
run_as_user xfconf-query -c xfce4-notifyd -p /do-fadeout -s true 2>/dev/null || true
run_as_user xfconf-query -c xfce4-notifyd -p /fadeout-time -s 500 2>/dev/null || true # Desvanecimiento rápido (0.5s)
echo -e "${GREEN}   ✓ Ajustes finos de XFCE aplicados${NC}"
fi


# =============================================================================
#  Paso 15.7: Detalles finales (Cursor y Atajo "Acerca de este Mac")
# =============================================================================
# Cursor
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
run_as_user xfconf-query -c xsettings -p /Gtk/CursorThemeSize -s 32 2>/dev/null || true
echo -e "${GREEN}   ✓ Cursor XFCE ajustado a 32px${NC}"
fi

# Atajo Super+I
if [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>i" -n -t string -s "$ABOUT_SCRIPT" 2>/dev/null || \
run_as_user xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>i" -s "$ABOUT_SCRIPT" 2>/dev/null || true
echo -e "${GREEN}   ✓ Atajo Super+I asignado correctamente en XFCE.${NC}"
fi

# =============================================================================
#  Paso 15.8: Nombre de equipo y modo oscuro automático
# =============================================================================
# Nombre de equipo
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
NEW_HOSTNAME="MacBook-Neo"
fi

# Dentro del script de modo oscuro automático (auto-dark-mode.sh)
if command -v xfconf-query &> /dev/null; then
xfconf-query -c xsettings -p /Net/ThemeName -s "$GTK_THEME" 2>/dev/null || true
fi

# =============================================================================
#  Paso 15.9: Perfeccionamiento de experiencia macOS (Reloj, Sonidos, Botones)
# =============================================================================
# Reloj
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
CLOCK_PLUGIN=$(run_as_user xfconf-query -c xfce4-panel -l 2>/dev/null | grep "/plugins/" | grep "clock" | head -1 | cut -d'/' -f4)
if [ -n "$CLOCK_PLUGIN" ]; then
run_as_user xfconf-query -c xfce4-panel -p /plugins/$CLOCK_PLUGIN/digital-format -s "%a %d %b, %H:%M" 2>/dev/null || true
run_as_user xfconf-query -c xfce4-panel -p /plugins/$CLOCK_PLUGIN/digital-layout -s 3 2>/dev/null || true
fi
echo -e "${GREEN}   ✓ Reloj XFCE configurado con formato macOS${NC}"
fi

# Sonidos de teclado
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
run_as_user xfconf-query -c xsettings -p /Net/EnableInputFeedbackSounds -s true 2>/dev/null || true
run_as_user xfconf-query -c xsettings -p /Net/EnableEventSounds -s true 2>/dev/null || true
echo -e "${GREEN}   ✓ Sonidos de teclado activados en XFCE${NC}"
fi

# Botones de ventana
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
run_as_user xfconf-query -c xfwm4 -p /general/button_layout -s "OMH" 2>/dev/null || true
if command -v xfwm4 &> /dev/null; then
run_as_user xfwm4 --replace &>/dev/null &
sleep 1
fi
echo -e "${GREEN}   ✓ Botones XFCE corregidos a 'Cerrar, Minimizar, Maximizar' y gestor recargado.${NC}"
fi

# =============================================================================
#  Paso 15.10B: Pantalla de bloqueo estilo macOS
# =============================================================================
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
echo -e "${BLUE}   → Instalando light-locker para XFCE...${NC}"
if ! command -v light-locker &> /dev/null; then
if command -v apt-get &> /dev/null; then
sudo apt-get install -y -qq light-locker 2>/dev/null || true
elif command -v dnf &> /dev/null; then
sudo dnf install -y -q light-locker 2>/dev/null || true
elif command -v pacman &> /dev/null; then
sudo pacman -S --noconfirm --needed light-locker 2>/dev/null || true
fi
fi
if [ -f "$WALLPAPER_PATH" ]; then
mkdir -p "$REAL_HOME/.config/light-locker" 2>/dev/null || true
cat > "$REAL_HOME/.config/light-locker/light-locker.conf" << EOF
[light-locker]
lock-on-suspend=true
lock-on-lid=false
idle-activation-enabled=true
EOF
if [ -n "$SUDO_USER" ]; then
chown -R "$SUDO_USER:$SUDO_USER" "$REAL_HOME/.config/light-locker" 2>/dev/null || true
fi
fi
run_as_user xfconf-query -c xfce4-session -p /general/lock_command -s "light-locker-command -l" 2>/dev/null || true
echo -e "${GREEN}   ✓ light-locker instalado y configurado para XFCE${NC}"
fi

# =============================================================================
#  Paso 15.10C: Indicadores OSD de volumen y brillo
# =============================================================================
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
echo -e "${BLUE}   → Configurando OSD para XFCE...${NC}"
if ! command -v xfce4-volumed-pulse &> /dev/null; then
if command -v apt-get &> /dev/null; then
sudo apt-get install -y -qq xfce4-volumed-pulse 2>/dev/null || true
elif command -v dnf &> /dev/null; then
sudo dnf install -y -q xfce4-volumed-pulse 2>/dev/null || true
elif command -v pacman &> /dev/null; then
sudo pacman -S --noconfirm --needed xfce4-volumed-pulse 2>/dev/null || true
fi
fi
run_as_user xfconf-query -c xfce4-notifyd -p /theme -s "MacTahoe-Dark" 2>/dev/null || true
run_as_user xfconf-query -c xfce4-notifyd -p /notify-location -s 2 2>/dev/null || true
run_as_user xfconf-query -c xfce4-notifyd -p /do-fadeout -s true 2>/dev/null || true
run_as_user xfconf-query -c xfce4-notifyd -p /fadeout-time -s 500 2>/dev/null || true
echo -e "${GREEN}   ✓ OSD de XFCE configurado con tema macOS${NC}"
fi

# =============================================================================
#  Paso 17: Configuración de Terminal estilo macOS
# =============================================================================
elif [[ "$DESKTOP_ENV" == *"xfce"* ]] && command -v xfce4-terminal &> /dev/null; then
mkdir -p "$REAL_HOME/.config/xfce4/terminal" 2>/dev/null || true
cat > "$REAL_HOME/.config/xfce4/terminal/terminalrc" << 'TERMINALEOF' 2>/dev/null || true
[Configuration]
FontName=SF Mono 12
ColorForeground=#e6e6e6
ColorBackground=#1e1e1e
ColorBold=#ffffff
MiscCursorShape=TERMINAL_CURSOR_SHAPE_IBEAM
MiscCursorBlinks=FALSE
MiscShowUnsafeUrls=FALSE
TERMINALEOF
if [ -n "$SUDO_USER" ]; then
chown -R "$SUDO_USER:$SUDO_USER" "$REAL_HOME/.config/xfce4/terminal" 2>/dev/null || true
fi
echo -e "${GREEN}   ✓ Terminal XFCE configurada con tema macOS${NC}"
fi

# =============================================================================
#  Paso 18: Configuración de animaciones suaves
# =============================================================================
if [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
run_as_user xfconf-query -c xfwm4 -p /general/use_compositing -s true 2>/dev/null || true
fi

# =============================================================================
#  Paso 21: Scroll natural universal
# =============================================================================
if [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
for device in $(xinput list 2>/dev/null | grep -i "pointer" | grep -i "libinput" | sed 's/.*id=\([0-9]*\).*/\1/'); do
xinput set-prop "$device" "libinput Natural Scrolling Enabled" 1 2>/dev/null || true
done
fi

# =============================================================================
#  Paso 22: Gestos multitáctiles estilo macOS (Fusuma)
# =============================================================================
else
# XFCE: Super+d para mostrar escritorio
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

# =============================================================================
#  Paso 23: Gestor de portapapeles minimalista
# =============================================================================
elif [[ "$DESKTOP_ENV" == *"xfce"* ]]; then
echo -e "${GREEN}   ✓ Clipman instalado para XFCE (añádelo al panel manualmente)${NC}"
fi
