#!/usr/bin/env bash
APP_ID="pear-desktop"
APP_NAME="Pear Desktop"
APP_DESC="Player de música com integração ao Last.fm e streaming"

remove_pear_desktop() {
    remove_pkg pear-desktop
    rm -rf "$HOME/.config/PearDesktop" "$HOME/.config/pear-desktop"
    log "Pear Desktop removido."
}
