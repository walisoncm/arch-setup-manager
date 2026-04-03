#!/usr/bin/env bash
APP_ID="fzf"
APP_NAME="fzf"
APP_DESC="Fuzzy finder interativo para terminal"

install_fzf() {
    step "Instalando fzf..."
    install_pkg fzf

    step "Adicionando ao Fish..."
    mkdir -p "$HOME/.config/fish/conf.d"
    cat > "$HOME/.config/fish/conf.d/fzf.fish" <<'EOF'
fzf --fish | source
EOF

    log "fzf instalado com integração Fish (Ctrl+R, Ctrl+T, Alt+C)."
}
remove_fzf() {
    remove_pkg fzf
    rm -f "$HOME/.config/fish/conf.d/fzf.fish"
    log "fzf removido."
}
