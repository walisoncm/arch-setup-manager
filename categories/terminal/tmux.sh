#!/usr/bin/env bash
APP_ID="tmux"
APP_NAME="Tmux + TPM"
APP_DESC="Multiplexer com tema Nord e suporte a mouse"

install_tmux() {
    step "Instalando Tmux..."
    install_pkg tmux

    step "Copiando configuração..."
    mkdir -p "$HOME/.config/tmux"
    cp "$SCRIPT_DIR/configs/tmux.conf" "$HOME/.config/tmux/tmux.conf"

    step "Instalando TPM (Tmux Plugin Manager)..."
    if [[ ! -d "$HOME/.config/tmux/plugins/tpm" ]]; then
        git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
    fi

    step "Instalando plugins do tmux..."
    "$HOME/.config/tmux/plugins/tpm/bin/install_plugins" 2>/dev/null || true

    log "Tmux instalado com tema Nord."
}
remove_tmux() {
    remove_pkg tmux
    rm -rf "$HOME/.config/tmux"
    log "Tmux e plugins removidos."
}
