#!/usr/bin/env bash
APP_ID="krita"
APP_NAME="Krita"
APP_DESC="Pintura digital e ilustração"

remove_krita() {
    remove_pkg krita
    rm -rf "$HOME/.config/krita" "$HOME/.local/share/krita"
    log "Krita removido."
}
