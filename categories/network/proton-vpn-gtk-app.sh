#!/usr/bin/env bash
APP_ID="proton-vpn-gtk-app"
APP_NAME="ProtonVPN"
APP_DESC="Cliente oficial ProtonVPN"

remove_proton-vpn-gtk-app() {
    remove_pkg proton-vpn-gtk-app
    rm -rf "$HOME/.config/protonvpn"
    log "ProtonVPN removido."
}
