#!/usr/bin/env bash
APP_ID="claude-native"
APP_NAME="Claude (Native)"
APP_DESC="Claude Code instalado nativamente via installer oficial (sem dependência de Node.js)"

status_claude_native() {
    [[ -d "$HOME/.local/share/claude" ]] && [[ -x "$HOME/.local/bin/claude" ]]
}

install_claude_native() {
    step "Instalando Claude Code via installer oficial..."
    curl -fsSL https://claude.ai/install.sh | bash || { err "Falha ao instalar Claude Code nativo."; return 1; }

    # Persiste ~/.local/bin no fish (o installer sugere isso mas não faz automaticamente)
    if getent passwd "$USER" | grep -q fish; then
        fish -c "fish_add_path '$HOME/.local/bin'" 2>/dev/null || true
    fi

    if [[ -x "$HOME/.local/bin/claude" ]]; then
        log "Claude Code (nativo) instalado! Execute: claude"
    else
        err "Instalação concluída, mas '$HOME/.local/bin/claude' não encontrado."
        return 1
    fi
}

remove_claude_native() {
    step "Removendo Claude Code nativo..."
    rm -rf "$HOME/.local/share/claude"
    rm -f "$HOME/.local/bin/claude"

    step "Removendo configurações (~/.claude)..."
    rm -rf "$HOME/.cache/claude"
    rm -rf "$HOME/.claude"
    rm -f "$HOME/.claude.json"
    log "Claude Code (nativo) removido."
}
