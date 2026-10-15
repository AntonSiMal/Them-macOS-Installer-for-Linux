#!/bin/bash
# =============================================================================
# Módulo GNOME - macOS Tahoe Installer
# Este archivo define funciones que son llamadas por install.sh
# =============================================================================

gnome_step_3() {
    echo -e "${YELLOW}🧩 [3/24] Instalando extensión 'Liquid Glass'...${NC}"
    mkdir -p "$REAL_HOME/.local/share/gnome-shell/extensions/"
    [ ! -d "$WORKDIR/liquid-glass" ] && git clone --depth=1 https://github.com/ryohsuke1231/liquid-glass.git "$WORKDIR/liquid-glass" -q
    cp -r "$WORKDIR/liquid-glass/liquid-glass@thinkingcoding1231.gmail.com" "$REAL_HOME/.local/share/gnome-shell/extensions/"
    # ... resto del código de Liquid Glass ...
    echo -e "${GREEN}✅ Liquid Glass instalada.${NC}"
}

gnome_step_6() {
    echo -e "${YELLOW}🌄 [6/24] Instalando wallpaper dinámico Mojave...${NC}"
    # ... código de Mojave ...
}

gnome_step_15() {
    echo -e "${BLUE}   → Configurando GNOME...${NC}"
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
    # ... resto del código del paso 15 para GNOME ...
}

# ... definir gnome_step_15_5, gnome_step_15_6, etc. ...
