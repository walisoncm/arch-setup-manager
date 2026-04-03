#!/usr/bin/env bash
APP_ID="winboat-bin"
APP_NAME="Winboat"
APP_DESC="Windows em container"

install_winboat-bin() {
    need_aur || { err "AUR helper não encontrado."; return 1; }
    step "Instalando Winboat..."
    has_pkg "podman" || install_podman
    install_pkg winboat-bin
    log "Winboat instalado!"
}
remove_winboat-bin() {
    [[ -f "$HOME/.winboat/podman-compose.yml" ]] && (cd "$HOME/.winboat" && podman compose down 2>/dev/null) || true
    remove_pkg winboat-bin
    log "Winboat removido."
}
