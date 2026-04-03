#!/usr/bin/env bash
APP_ID="steam"
APP_NAME="Steam + Millennium"
APP_DESC="Launcher de jogos com skin manager"

install_steam() {
    step "Instalando Steam + Millennium..."
    install_pkg steam millennium
    log "Steam instalado!"
}
remove_steam() {
    remove_pkg steam millennium
    log "Steam removido."
}
