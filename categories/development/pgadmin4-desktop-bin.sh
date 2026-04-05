#!/usr/bin/env bash
APP_ID="pgadmin4-desktop-bin"
APP_NAME="pgAdmin 4"
APP_DESC="GUI para PostgreSQL (modo desktop)"

remove_pgadmin4_desktop_bin() {
    remove_pkg pgadmin4-desktop-bin
    rm -rf "$HOME/.pgadmin" "$HOME/.config/pgadmin"
    log "pgAdmin 4 removido."
}
