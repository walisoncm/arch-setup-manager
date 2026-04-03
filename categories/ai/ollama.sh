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

    step "Configurando Ollama para aceitar conexões externas (Docker)..."
    sudo mkdir -p /etc/systemd/system/ollama.service.d
    sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null <<'EOF'
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable --now ollama.service 2>/dev/null || true
    log "Ollama instalado!"
    warn "Nenhum modelo foi baixado. Execute: ollama pull <modelo> (ex: ollama pull llama3)"
}
remove_ollama() {
    sudo systemctl stop ollama.service 2>/dev/null || true
    sudo systemctl disable ollama.service 2>/dev/null || true

    # Instalado via pacman/AUR ou via script curl
    if has_pkg ollama; then
        remove_pkg ollama
    else
        sudo rm -f /usr/local/bin/ollama
        sudo rm -f /etc/systemd/system/ollama.service
        sudo rm -rf /usr/share/ollama
    fi

    sudo rm -f /etc/systemd/system/ollama.service.d/override.conf
    sudo systemctl daemon-reload
    log "Ollama removido."
}
