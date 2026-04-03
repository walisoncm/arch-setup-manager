#!/usr/bin/env bash
APP_ID="neovim"
APP_NAME="Neovim"
APP_DESC="Editor com lazy.nvim, LSP e config pessoal"

install_neovim() {
    step "Instalando Neovim e dependências..."
    install_pkg neovim ripgrep fd lazygit luarocks tree-sitter-cli

    step "Aplicando configuração pessoal..."
    if [[ -d "$HOME/.config/nvim" ]]; then
        mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak.$(date +%s)"
        warn "Config anterior movida para ~/.config/nvim.bak.*"
    fi
    mkdir -p "$HOME/.config/nvim"
    cp "$SCRIPT_DIR/configs/nvim-init.lua" "$HOME/.config/nvim/init.lua"

    log "Neovim instalado. Plugins serão instalados no primeiro acesso."
}
remove_neovim() {
    remove_pkg neovim
    rm -rf "$HOME/.config/nvim" "$HOME/.local/share/nvim" "$HOME/.cache/nvim"
    log "Neovim e dados removidos."
}
