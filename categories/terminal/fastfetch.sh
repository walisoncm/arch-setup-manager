#!/usr/bin/env bash
APP_ID="fastfetch"
APP_NAME="Fastfetch"
APP_DESC="Informações do sistema estilizadas"

remove_fastfetch() {
    remove_pkg fastfetch
    rm -rf "$HOME/.config/fastfetch"
    log "Fastfetch removido."
}
