#!/usr/bin/env bash
APP_ID="antigravity"
APP_NAME="Antigravity"
APP_DESC="Plataforma de orquestração multi-agente do Google"
APP_TYPE="agent"

remove_antigravity() {
    remove_pkg antigravity
    rm -rf "$HOME/.config/Antigravity"
    log "Antigravity removido."
}
