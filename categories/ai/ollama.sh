#!/usr/bin/env bash
APP_ID="ollama"
APP_NAME="Ollama"
APP_DESC="IA Local com aceleração GPU"

status_ollama() { has_cmd "ollama"; }

install_ollama() {
    step "Instalando Ollama..."
    if ! install_pkg ollama 2>/dev/null; then
        curl -fsSL https://ollama.ai/install.sh | sh
    fi
    sudo systemctl enable --now ollama.service 2>/dev/null || true
    log "Ollama instalado!"
}
remove_ollama() {
    sudo systemctl stop ollama.service 2>/dev/null || true
    remove_pkg ollama
    log "Ollama removido."
}
