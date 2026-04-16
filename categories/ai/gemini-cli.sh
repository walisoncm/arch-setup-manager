#!/usr/bin/env bash
APP_ID="gemini-cli"
APP_NAME="Gemini CLI"
APP_DESC="CLI oficial do Google para usar modelos Gemini no terminal com agentes e edição de código"

status_gemini_cli() {
    npm list -g @google/gemini-cli &>/dev/null 2>&1
}

install_gemini_cli() {
    step "Verificando Node.js..."
    if ! has_cmd "node"; then
        install_pkg nodejs npm || { err "Falha ao instalar Node.js."; return 1; }
    fi

    local node_ver
    node_ver="$(node --version 2>/dev/null | sed 's/v//' | cut -d. -f1)"
    if [[ -n "$node_ver" && "$node_ver" -lt 18 ]]; then
        warn "Node.js $node_ver detectado. Gemini CLI requer Node.js ≥ 18."
        step "Atualizando Node.js..."
        install_pkg nodejs npm || { err "Falha ao atualizar Node.js."; return 1; }
    fi

    local npm_prefix
    npm_prefix="$(npm prefix -g 2>/dev/null)"
    if [[ "$npm_prefix" == /usr* ]]; then
        step "Configurando prefixo npm para ~/.local (sem necessidade de root)..."
        npm config set prefix "$HOME/.local"
    fi

    export PATH="$HOME/.local/bin:$PATH"
    if getent passwd "$USER" | grep -q fish; then
        fish -c "fish_add_path '$HOME/.local/bin'" 2>/dev/null || true
    fi

    step "Instalando Gemini CLI via npm..."
    npm install -g @google/gemini-cli || { err "Falha ao instalar Gemini CLI."; return 1; }

    if has_cmd "gemini"; then
        log "Gemini CLI instalado! Execute: gemini"
    else
        err "Instalação concluída, mas 'gemini' não encontrado no PATH."
        if getent passwd "$USER" | grep -q fish; then
            warn "Adicione ao PATH: fish_add_path ~/.local/bin"
        else
            warn "Adicione ao PATH: export PATH=\"\$PATH:\$HOME/.local/bin\""
        fi
        return 1
    fi
}

remove_gemini_cli() {
    step "Removendo Gemini CLI..."
    npm uninstall -g @google/gemini-cli 2>/dev/null || true

    step "Removendo configurações (~/.gemini)..."
    rm -rf "$HOME/.gemini"

    log "Gemini CLI removido."
}
