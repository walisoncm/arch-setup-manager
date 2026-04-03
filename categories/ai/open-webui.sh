#!/usr/bin/env bash
APP_ID="open-webui"
APP_NAME="Open WebUI"
APP_DESC="Interface web para Ollama (chat, modelos, histórico)"

status_open-webui() { has_cmd "docker" && docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^open-webui$"; }
launch_open-webui() { echo "http://localhost:11500"; }

install_open-webui() {
    step "Verificando Docker..."
    if ! has_cmd "docker"; then
        install_app docker || { err "Falha ao instalar Docker."; return 1; }
    fi
    sudo systemctl enable --now docker.service || { err "Falha ao iniciar docker.service."; return 1; }

    step "Baixando imagem Open WebUI..."
    sudo docker pull ghcr.io/open-webui/open-webui:main || { err "Falha ao baixar a imagem."; return 1; }

    step "Abrindo porta do Ollama para a rede Docker (UFW)..."
    if has_pkg "ufw"; then
        sudo ufw allow from 172.17.0.0/16 to any port 11434 2>/dev/null || true
    fi

    step "Iniciando container Open WebUI..."
    sudo docker stop open-webui 2>/dev/null || true
    sudo docker rm   open-webui 2>/dev/null || true
    sudo docker run -d \
        --name open-webui \
        --restart always \
        -p 11500:8080 \
        -v open-webui:/app/backend/data \
        --add-host=host.docker.internal:host-gateway \
        -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
        ghcr.io/open-webui/open-webui:main || { err "Falha ao iniciar o container."; return 1; }

    step "Criando lançador no sistema..."
    mkdir -p "$HOME/.local/share/applications"
    cat > "$HOME/.local/share/applications/open-webui.desktop" << 'DESKTOP'
[Desktop Entry]
Name=Open WebUI
Comment=Interface web para Ollama (chat, modelos, histórico)
Exec=xdg-open http://localhost:11500
Icon=internet-web-browser
Terminal=false
Type=Application
Categories=Network;Utility;
DESKTOP

    log "Open WebUI instalado! Acesse em http://localhost:11500"
}
remove_open-webui() {
    step "Parando e removendo container..."
    sudo docker stop open-webui 2>/dev/null || true
    sudo docker rm   open-webui 2>/dev/null || true

    step "Removendo imagem e volume Docker..."
    sudo docker rmi ghcr.io/open-webui/open-webui:main 2>/dev/null || true
    sudo docker volume rm open-webui 2>/dev/null || true

    step "Removendo lançador..."
    rm -f "$HOME/.local/share/applications/open-webui.desktop"

    if has_pkg "ufw"; then
        sudo ufw delete allow from 172.17.0.0/16 to any port 11434 2>/dev/null || true
    fi

    log "Open WebUI removido."
}
