#!/usr/bin/env bash
APP_ID="lutris"
APP_NAME="Lutris"
APP_DESC="Launcher de jogos com scripts de instalação"

remove_lutris() {
    remove_pkg lutris
    rm -rf "$HOME/.config/lutris" "$HOME/.local/share/lutris"
    log "Lutris e dados removidos."
}
