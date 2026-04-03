#!/usr/bin/env bash
APP_ID="cuda"
APP_NAME="CUDA Toolkit"
APP_DESC="NVIDIA CUDA + PATH configurado"

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
