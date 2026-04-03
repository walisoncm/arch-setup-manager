#!/usr/bin/env bash
APP_ID="starship"
APP_NAME="Starship"
APP_DESC="Prompt minimalista com ícones Nerd Font"

install_starship() {
    step "Instalando Starship..."
    install_pkg starship

    step "Copiando configuração..."
    cp "$SCRIPT_DIR/configs/starship.toml" "$HOME/.config/starship.toml"

    step "Adicionando ao Fish..."
    mkdir -p "$HOME/.config/fish/conf.d"
    if ! grep -q "starship init fish" "$HOME/.config/fish/config.fish" 2>/dev/null && \
       ! ls "$HOME/.config/fish/conf.d/"*starship* 2>/dev/null | grep -q .; then
        echo 'starship init fish | source' > "$HOME/.config/fish/conf.d/starship.fish"
    fi

    log "Starship instalado com prompt customizado."
}
remove_starship() {
    remove_pkg starship
    rm -f "$HOME/.config/starship.toml"
    rm -f "$HOME/.config/fish/conf.d/starship.fish"
    log "Starship removido."
}
