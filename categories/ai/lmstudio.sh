#!/usr/bin/env bash
# categories/ai/lmstudio.sh

APP_ID="lmstudio-bin"
APP_NAME="LM Studio"
APP_DESC="Interface gráfica elegante para rodar LLMs localmente (GGUF)"
APP_TYPE="interface"

# ── Status ────────────────────────────────────────────────────────────────────
status_lmstudio_bin() {
    has_pkg "lmstudio-bin" || has_pkg "lm-studio" || has_cmd "lms"
}

# ── Instalação ────────────────────────────────────────────────────────────────
install_lmstudio_bin() {
    step "Instalando LM Studio via AUR..."
    
    # Tenta instalar o pacote binário do AUR
    if ! install_pkg "lmstudio-bin"; then
        warn "Falha ao instalar lmstudio-bin. Tentando lm-studio..."
        if ! install_pkg "lm-studio"; then
            err "Não foi possível instalar o LM Studio."
            return 1
        fi
    fi

    # ── Configuração de Modelos Compartilhados ──
    # Usamos ~/.local/share/models/gguf como o "single source of truth"
    local models_dir="$HOME/.local/share/models/gguf"
    local lm_cache_dir="$HOME/.cache/lm-studio/models"
    local lm_dot_dir="$HOME/.lmstudio/models"
    
    mkdir -p "$models_dir"
    
    _link_models() {
        local target="$1"
        if [[ ! -L "$target" ]]; then
            if [[ -d "$target" ]]; then
                log "Migrando modelos de $target para $models_dir..."
                mkdir -p "$models_dir"
                mv "$target"/* "$models_dir/" 2>/dev/null
                rm -rf "$target"
            fi
            mkdir -p "$(dirname "$target")"
            ln -s "$models_dir" "$target"
            ok "Sincronizado: $target -> $models_dir"
        fi
    }

    _link_models "$lm_cache_dir"
    _link_models "$lm_dot_dir"

    ok "LM Studio instalado e modelos sincronizados com Llama.cpp!"
}

# ── Remoção ───────────────────────────────────────────────────────────────────
remove_lmstudio_bin() {
    step "Removendo LM Studio..."
    remove_pkg "lmstudio-bin" "lm-studio"
    
    # Mantemos os links simbólicos e modelos, pois são compartilhados
    ok "LM Studio removido (modelos mantidos em ~/.local/share/models/gguf)."
}
