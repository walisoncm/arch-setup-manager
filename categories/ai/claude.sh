#!/usr/bin/env bash
APP_ID="claude"
APP_NAME="Claude Code"
APP_DESC="CLI oficial da Anthropic para IA no terminal com agentes e edição de código"

status_claude() {
    npm list -g @anthropic-ai/claude-code &>/dev/null 2>&1
}

install_claude() {
    step "Verificando Node.js..."
    if ! has_cmd "node"; then
        install_pkg nodejs npm || { err "Falha ao instalar Node.js."; return 1; }
    fi

    local node_ver
    node_ver="$(node --version 2>/dev/null | sed 's/v//' | cut -d. -f1)"
    if [[ -n "$node_ver" && "$node_ver" -lt 18 ]]; then
        warn "Node.js $node_ver detectado. Claude Code requer Node.js ≥ 18."
        step "Atualizando Node.js..."
        install_pkg nodejs npm || { err "Falha ao atualizar Node.js."; return 1; }
    fi

    # O npm instalado via pacman usa /usr/lib/node_modules como prefixo global,
    # que requer root. Redirecionamos para ~/.local para instalar sem sudo.
    local npm_prefix
    npm_prefix="$(npm prefix -g 2>/dev/null)"
    if [[ "$npm_prefix" == /usr* ]]; then
        step "Configurando prefixo npm para ~/.local (sem necessidade de root)..."
        npm config set prefix "$HOME/.local"
    fi
    # Garante ~/.local/bin no PATH do processo atual (prefixo pode já ser ~/.local)
    export PATH="$HOME/.local/bin:$PATH"
    # Persiste no fish se for o shell padrão do usuário
    if getent passwd "$USER" | grep -q fish; then
        fish -c "fish_add_path '$HOME/.local/bin'" 2>/dev/null || true
    fi

    step "Instalando Claude Code via npm..."
    npm install -g @anthropic-ai/claude-code || { err "Falha ao instalar Claude Code."; return 1; }

    if has_cmd "claude"; then
        log "Claude Code instalado! Execute: claude"
    else
        err "Instalação concluída, mas 'claude' não encontrado no PATH."
        if getent passwd "$USER" | grep -q fish; then
            warn "Adicione ao PATH: fish_add_path ~/.local/bin"
        else
            warn "Adicione ao PATH: export PATH=\"\$PATH:\$HOME/.local/bin\""
        fi
        return 1
    fi
}

remove_claude() {
    step "Removendo Claude Code..."
    npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true

    step "Removendo configurações (~/.claude)..."
    rm -rf "$HOME/.cache/claude"
    rm -rf "$HOME/.cache/claude-cli-nodejs/"
    rm -rf "$HOME/.claude"
    rm -f "$HOME/.claude.json"

    log "Claude Code removido."
}
