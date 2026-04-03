#!/usr/bin/env bash
CAT_ID="terminal"
CAT_TITLE="Terminal"
CAT_ICON="🖥️"
CAT_DESC="Emuladores, multiplexer e prompt"
CAT_APPS="alacritty tmux starship fzf"

name_alacritty() { echo "Alacritty"; }
name_tmux()      { echo "Tmux + TPM"; }
name_starship()  { echo "Starship"; }
name_fzf()       { echo "fzf"; }

desc_alacritty() { echo "Terminal GPU-acelerado com tema Noctalia"; }
desc_tmux()      { echo "Multiplexer com tema Nord e suporte a mouse"; }
desc_starship()  { echo "Prompt minimalista com ícones Nerd Font"; }
desc_fzf()       { echo "Fuzzy finder interativo para terminal"; }

install_alacritty() {
    step "Instalando Alacritty..."
    sudo pacman -S --needed --noconfirm alacritty

    step "Copiando configuração..."
    mkdir -p "$HOME/.config/alacritty/themes"
    cp "$SCRIPT_DIR/configs/alacritty.toml"         "$HOME/.config/alacritty/alacritty.toml"
    cp "$SCRIPT_DIR/configs/alacritty-noctalia.toml" "$HOME/.config/alacritty/themes/noctalia.toml"

    log "Alacritty instalado com tema Noctalia."
}
remove_alacritty() {
    sudo pacman -R --noconfirm alacritty 2>/dev/null || true
    rm -rf "$HOME/.config/alacritty"
    log "Alacritty removido."
}

install_tmux() {
    step "Instalando Tmux..."
    sudo pacman -S --needed --noconfirm tmux

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
    sudo pacman -R --noconfirm tmux 2>/dev/null || true
    rm -rf "$HOME/.config/tmux"
    log "Tmux e plugins removidos."
}

install_starship() {
    step "Instalando Starship..."
    sudo pacman -S --needed --noconfirm starship

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
    sudo pacman -R --noconfirm starship 2>/dev/null || true
    rm -f "$HOME/.config/starship.toml"
    rm -f "$HOME/.config/fish/conf.d/starship.fish"
    log "Starship removido."
}

install_fzf() {
    step "Instalando fzf..."
    sudo pacman -S --needed --noconfirm fzf

    step "Adicionando ao Fish..."
    mkdir -p "$HOME/.config/fish/conf.d"
    cat > "$HOME/.config/fish/conf.d/fzf.fish" <<'EOF'
fzf --fish | source
EOF

    log "fzf instalado com integração Fish (Ctrl+R, Ctrl+T, Alt+C)."
}
remove_fzf() {
    sudo pacman -R --noconfirm fzf 2>/dev/null || true
    rm -f "$HOME/.config/fish/conf.d/fzf.fish"
    log "fzf removido."
}
