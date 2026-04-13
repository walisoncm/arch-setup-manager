#!/usr/bin/env bash
APP_ID="openclaude"
APP_NAME="Open Claude"
APP_DESC="CLI open source para IA no terminal com agentes e edição de código"

status_openclaude() {
    has_cmd "openclaude" || [[ -x "$HOME/.local/bin/openclaude" ]] || \
    find "$HOME/.nvm/versions" -name "openclaude" -type f 2>/dev/null | grep -q .
}

install_openclaude() {
    step "Verificando Node.js..."
    if ! has_cmd "node"; then
        install_pkg nodejs npm || { err "Falha ao instalar Node.js."; return 1; }
    fi

    local node_ver
    node_ver="$(node --version 2>/dev/null | sed 's/v//' | cut -d. -f1)"
    if [[ -n "$node_ver" && "$node_ver" -lt 18 ]]; then
        warn "Node.js $node_ver detectado. Claude Code requer Node.js ≥ 18."
        step "Instalando Node.js >=18 via nvm ou atualizando pacote..."
        install_pkg nodejs npm || { err "Falha ao atualizar Node.js."; return 1; }
    fi

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

    step "Instalando Open Claude via npm..."
    npm install -g @gitlawb/openclaude || { err "Falha ao instalar openclaude."; return 1; }

    if has_cmd "openclaude"; then
        log "Open Claude instalado!"
    else
        err "Instalação concluída, mas 'openclaude' não encontrado no PATH."
        if getent passwd "$USER" | grep -q fish; then
            warn "Adicione ao PATH: fish_add_path ~/.local/bin"
        else
            warn "Adicione ao PATH: export PATH=\"\$PATH:\$HOME/.local/bin\""
        fi
        return 1
    fi

    step "Configurando MCP filesystem (acesso ao home)..."
    openclaude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem "$HOME" \
        && ok "MCP filesystem configurado para \$HOME." \
        || warn "Não foi possível configurar o MCP filesystem (configure manualmente depois)."

    log "Open Claude instalado! Execute: openclaude"
}

remove_openclaude() {
    step "Removendo Open Claude..."
    npm uninstall -g @gitlawb/openclaude 2>/dev/null || true

    step "Removendo configurações em ~/.openclaude..."
    rm -rf "$HOME/.openclaude"
    rm -f "$HOME/.config/fish/conf.d/openclaude.fish"
    rm -rf "$HOME/.cache/claude"
    rm -rf "$HOME/.cache/claude-cli-nodejs/"
    rm -rf "$HOME/.claude"
    rm -f "$HOME/.claude.json"

    log "Open Claude removido."
}
