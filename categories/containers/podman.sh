#!/usr/bin/env bash
APP_ID="podman"
APP_NAME="Podman"
APP_DESC="Podman Engine rootless"

install_podman() {
    step "Instalando Podman..."
    install_pkg podman podman-compose
    log "Podman instalado!"
}
remove_podman() {
    remove_pkg podman podman-compose
    log "Podman removido."
}
