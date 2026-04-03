#!/usr/bin/env bash
APP_ID="alacritty"
APP_NAME="Alacritty"
APP_DESC="Terminal GPU-acelerado com tema Noctalia"

install_alacritty() {
    step "Instalando Alacritty..."
    install_pkg alacritty

    step "Copiando configuração..."
    mkdir -p "$HOME/.config/alacritty/themes"
    cp "$SCRIPT_DIR/configs/alacritty.toml"         "$HOME/.config/alacritty/alacritty.toml"
    cp "$SCRIPT_DIR/configs/alacritty-noctalia.toml" "$HOME/.config/alacritty/themes/noctalia.toml"

    log "Alacritty instalado com tema Noctalia."
}
remove_alacritty() {
    remove_pkg alacritty
    rm -rf "$HOME/.config/alacritty"
    log "Alacritty removido."
}
