#!/usr/bin/env bash
APP_ID="nvm-fish"
APP_NAME="NVM (Fish)"
APP_DESC="Node Version Manager para Fish shell"

remove_nvm-fish() {
    remove_pkg nvm-fish
    rm -rf "$HOME/.nvm"
    log "NVM removido."
}
