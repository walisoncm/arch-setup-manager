#!/usr/bin/env bash
APP_ID="windsurf"
APP_NAME="Windsurf"
APP_DESC="IDE da Codeium com agentes de IA integrados"

remove_windsurf() {
    remove_pkg windsurf
    rm -rf "$HOME/.config/Windsurf"
    log "Windsurf removido."
}
