#!/usr/bin/env bash
APP_ID="mpv"
APP_NAME="mpv"
APP_DESC="Player de vídeo leve com suporte nativo a Wayland"

remove_mpv() {
    remove_pkg mpv
    rm -rf "$HOME/.config/mpv"
    log "mpv removido."
}
