#!/usr/bin/env bash
APP_ID="haruna"
APP_NAME="Haruna"
APP_DESC="Player de vídeo moderno baseado em MPV"

remove_haruna() {
    remove_pkg haruna
    rm -rf "$HOME/.config/haruna"
    log "Haruna removido."
}
