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
