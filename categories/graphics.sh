#!/usr/bin/env bash
CAT_ID="graphics"
CAT_TITLE="Gráficos"
CAT_ICON="🎨"
CAT_DESC="Edição de imagem e design"
CAT_APPS="org.gimp.GIMP inkscape krita"

name_org_gimp_GIMP() { echo "GIMP"; }
name_inkscape()      { echo "Inkscape"; }
name_krita()         { echo "Krita"; }

desc_org_gimp_GIMP() { echo "Editor de imagem profissional open-source"; }
desc_inkscape()      { echo "Editor de gráficos vetoriais (SVG)"; }
desc_krita()         { echo "Pintura digital e ilustração"; }

install_org_gimp_GIMP() {
    step "Instalando GIMP..."
    sudo flatpak install --noninteractive flathub org.gimp.GIMP
    log "GIMP instalado."
}
remove_org_gimp_GIMP() {
    sudo flatpak uninstall --noninteractive org.gimp.GIMP 2>/dev/null || true
    log "GIMP removido."
}

install_inkscape() {
    step "Instalando Inkscape..."
    sudo pacman -S --needed --noconfirm inkscape
    log "Inkscape instalado."
}
remove_inkscape() {
    sudo pacman -R --noconfirm inkscape 2>/dev/null || true
    rm -rf "$HOME/.config/inkscape"
    log "Inkscape removido."
}

install_krita() {
    step "Instalando Krita..."
    sudo pacman -S --needed --noconfirm krita
    log "Krita instalado."
}
remove_krita() {
    sudo pacman -R --noconfirm krita 2>/dev/null || true
    rm -rf "$HOME/.config/krita" "$HOME/.local/share/krita"
    log "Krita removido."
}
