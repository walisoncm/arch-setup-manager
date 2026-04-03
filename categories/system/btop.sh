#!/usr/bin/env bash
APP_ID="btop"
APP_NAME="Btop"
APP_DESC="Monitor de recursos interativo"

remove_btop() {
    remove_pkg btop
    rm -rf "$HOME/.config/btop"
    log "Btop removido."
}
