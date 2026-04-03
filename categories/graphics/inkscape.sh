#!/usr/bin/env bash
APP_ID="inkscape"
APP_NAME="Inkscape"
APP_DESC="Editor de gráficos vetoriais (SVG)"

remove_inkscape() {
    remove_pkg inkscape
    rm -rf "$HOME/.config/inkscape"
    log "Inkscape removido."
}
