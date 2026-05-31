#!/usr/bin/env bash
APP_ID="kiro-ide"
APP_NAME="Kiro IDE"
APP_DESC="IDE de IA agêntica para desenvolvimento orientado a especificações"

remove_kiro_ide() {
    remove_pkg kiro-ide
    rm -rf "$HOME/.config/kiro-ide"
    log "Kiro IDE removido."
}
