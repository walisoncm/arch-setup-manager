#!/usr/bin/env bash
CAT_ID="development"
CAT_TITLE="Desenvolvimento"
CAT_ICON="💻"
CAT_DESC="Editores, LSPs, DB e ferramentas"
CAT_APPS="cuda neovim dev.zed.Zed pgadmin4-desktop-bin rest.insomnia.Insomnia nvm-fish bruno-bin"

name_cuda()                   { echo "CUDA Toolkit"; }
name_neovim()                 { echo "Neovim"; }
name_dev_zed_Zed()            { echo "Zed Editor"; }
name_pgadmin4-desktop-bin()   { echo "pgAdmin 4"; }
name_rest_insomnia_Insomnia()  { echo "Insomnia"; }
name_nvm-fish()               { echo "NVM (Fish)"; }
name_bruno-bin()              { echo "Bruno"; }

desc_cuda()                   { echo "NVIDIA CUDA + PATH configurado"; }
desc_neovim()                 { echo "Editor com lazy.nvim, LSP e config pessoal"; }
desc_dev_zed_Zed()            { echo "Editor de código moderno"; }
desc_pgadmin4-desktop-bin()   { echo "GUI para PostgreSQL (modo desktop)"; }
desc_rest_insomnia_Insomnia()  { echo "Cliente REST/GraphQL para testes de API"; }
desc_nvm-fish()               { echo "Node Version Manager para Fish shell"; }
desc_bruno-bin()              { echo "API client open-source (alternativa ao Insomnia)"; }

install_cuda() {
    step "Instalando CUDA..."
    install_pkg cuda cudnn

    step "Configurando PATH..."
    mkdir -p "$HOME/.config/fish/conf.d"
    cat > "$HOME/.config/fish/conf.d/cuda.fish" <<'EOF'
set -gx CUDA_PATH /opt/cuda
fish_add_path /opt/cuda/bin
set -gx LD_LIBRARY_PATH $LD_LIBRARY_PATH /opt/cuda/lib64
EOF
    cat > "$HOME/.config/cuda_env.sh" <<'EOF'
export CUDA_PATH=/opt/cuda
export PATH="$PATH:/opt/cuda/bin"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/opt/cuda/lib64"
EOF
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        [[ -f "$rc" ]] && ! grep -q "cuda_env.sh" "$rc" && echo 'source "$HOME/.config/cuda_env.sh"' >> "$rc"
    done
    log "CUDA instalado e PATH configurado."
}
remove_cuda() {
    remove_pkg cuda cudnn
    rm -f "$HOME/.config/fish/conf.d/cuda.fish" "$HOME/.config/cuda_env.sh"
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do [[ -f "$rc" ]] && sed -i '/cuda_env\.sh/d' "$rc"; done
    log "CUDA removido."
}

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

remove_pgadmin4-desktop-bin() {
    remove_pkg pgadmin4-desktop-bin
    rm -rf "$HOME/.pgadmin" "$HOME/.config/pgadmin"
    log "pgAdmin 4 removido."
}

remove_nvm-fish() {
    remove_pkg nvm-fish
    rm -rf "$HOME/.nvm"
    log "NVM removido."
}

remove_bruno-bin() {
    remove_pkg bruno-bin
    rm -rf "$HOME/.config/bruno"
    log "Bruno removido."
}

