#!/usr/bin/env bash
CAT_ID="ai"
CAT_TITLE="IA"
CAT_ICON="🤖"
CAT_DESC="IA Local com aceleração GPU"
CAT_APPS="ollama open-webui"

name_ollama()    { echo "Ollama"; }
name_open-webui() { echo "Open WebUI"; }

desc_ollama()    { echo "IA Local com aceleração GPU"; }
desc_open-webui() { echo "Interface web para Ollama (chat, modelos, histórico)"; }

status_ollama()    { has_cmd "ollama"; }
launch_open-webui() { echo "http://localhost:11500"; }

status_open-webui() { has_cmd "docker" && docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^open-webui$"; }

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

install_open-webui() {
    step "Verificando Docker..."
    if ! has_cmd "docker"; then
        install_app docker || { err "Falha ao instalar Docker."; return 1; }
    fi
    sudo systemctl enable --now docker.service || { err "Falha ao iniciar docker.service."; return 1; }

    step "Baixando imagem Open WebUI..."
    sudo docker pull ghcr.io/open-webui/open-webui:main || { err "Falha ao baixar a imagem."; return 1; }

    step "Iniciando container Open WebUI..."
    sudo docker stop open-webui 2>/dev/null || true
    sudo docker rm   open-webui 2>/dev/null || true
    sudo docker run -d \
        --name open-webui \
        --restart always \
        -p 11500:8080 \
        -v open-webui:/app/backend/data \
        --add-host=host.docker.internal:host-gateway \
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

    log "Open WebUI removido."
}
