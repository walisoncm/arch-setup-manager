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
    sudo pacman -S --needed --noconfirm cuda cudnn

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
    sudo pacman -R --noconfirm cuda cudnn 2>/dev/null || true
    rm -f "$HOME/.config/fish/conf.d/cuda.fish" "$HOME/.config/cuda_env.sh"
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do [[ -f "$rc" ]] && sed -i '/cuda_env\.sh/d' "$rc"; done
    log "CUDA removido."
}

install_neovim() {
    step "Instalando Neovim e dependências..."
    sudo pacman -S --needed --noconfirm neovim ripgrep fd lazygit luarocks tree-sitter-cli

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
    sudo pacman -R --noconfirm neovim 2>/dev/null || true
    rm -rf "$HOME/.config/nvim" "$HOME/.local/share/nvim" "$HOME/.cache/nvim"
    log "Neovim e dados removidos."
}

install_pgadmin4-desktop-bin() {
    need_aur || { err "AUR helper não encontrado."; return 1; }
    step "Instalando pgAdmin 4 Desktop..."
    $AUR -S --needed --noconfirm pgadmin4-desktop-bin
    log "pgAdmin 4 instalado."
}
remove_pgadmin4-desktop-bin() {
    $AUR -R --noconfirm pgadmin4-desktop-bin 2>/dev/null || true
    rm -rf "$HOME/.pgadmin" "$HOME/.config/pgadmin"
    log "pgAdmin 4 removido."
}

install_rest_insomnia_Insomnia() {
    step "Instalando Insomnia..."
    sudo flatpak install --noninteractive flathub rest.insomnia.Insomnia
    log "Insomnia instalado."
}
remove_rest_insomnia_Insomnia() {
    sudo flatpak uninstall --noninteractive rest.insomnia.Insomnia 2>/dev/null || true
    log "Insomnia removido."
}

install_nvm-fish() {
    need_aur || { err "AUR helper não encontrado."; return 1; }
    step "Instalando NVM para Fish..."
    $AUR -S --needed --noconfirm nvm-fish
    log "NVM instalado. Use 'nvm install <versão>' para instalar o Node."
}
remove_nvm-fish() {
    $AUR -R --noconfirm nvm-fish 2>/dev/null || true
    rm -rf "$HOME/.nvm"
    log "NVM removido."
}

install_bruno-bin() {
    need_aur || { err "AUR helper não encontrado."; return 1; }
    step "Instalando Bruno..."
    $AUR -S --needed --noconfirm bruno-bin
    log "Bruno instalado."
}
remove_bruno-bin() {
    $AUR -R --noconfirm bruno-bin 2>/dev/null || true
    rm -rf "$HOME/.config/bruno"
    log "Bruno removido."
}

