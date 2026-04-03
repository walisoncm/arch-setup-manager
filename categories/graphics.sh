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

remove_inkscape() {
    remove_pkg inkscape
    rm -rf "$HOME/.config/inkscape"
    log "Inkscape removido."
}

remove_krita() {
    remove_pkg krita
    rm -rf "$HOME/.config/krita" "$HOME/.local/share/krita"
    log "Krita removido."
}
