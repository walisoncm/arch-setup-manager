#!/usr/bin/env bash
APP_ID="bruno-bin"
APP_NAME="Bruno"
APP_DESC="API client open-source (alternativa ao Insomnia)"

remove_bruno_bin() {
    remove_pkg bruno-bin
    rm -rf "$HOME/.config/bruno"
    log "Bruno removido."
}
