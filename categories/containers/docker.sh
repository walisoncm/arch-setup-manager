#!/usr/bin/env bash
APP_ID="docker"
APP_NAME="Docker + Compose"
APP_DESC="Docker Engine com usuário no grupo"

# in_group é parte do setup — verifica instalação completa
status_docker() { has_pkg "docker" && in_group "docker"; }

install_docker() {
    step "Instalando Docker..."
    install_pkg docker docker-compose docker-buildx
    step "Habilitando serviço..."
    sudo systemctl enable --now docker.socket
    sudo systemctl enable docker.service
    sudo usermod -aG docker "$USER"
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json > /dev/null <<'EOF'
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": { "max-size": "50m", "max-file": "3" }
}
EOF
    log "Docker instalado!"
    warn "Logout/login necessário para usar sem sudo."
}
remove_docker() {
    sudo systemctl stop docker.service docker.socket 2>/dev/null || true
    sudo systemctl disable docker.service docker.socket 2>/dev/null || true
    remove_pkg docker docker-compose docker-buildx
    sudo rm -f /etc/docker/daemon.json
    log "Docker removido."
}
