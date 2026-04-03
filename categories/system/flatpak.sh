#!/usr/bin/env bash
APP_ID="flatpak"
APP_NAME="Flatpak + Flathub"
APP_DESC="Suporte a apps universais"

# Verifica também se o remote flathub foi adicionado
status_flatpak() { has_pkg "flatpak" && flatpak remotes 2>/dev/null | grep -q "flathub"; }

install_flatpak() {
    step "Instalando Flatpak + Flathub..."
    install_pkg flatpak xdg-desktop-portal-kde
    sudo flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    log "Flatpak + Flathub configurados!"
}
remove_flatpak() {
    flatpak uninstall --all --noninteractive 2>/dev/null || true
    remove_pkg flatpak xdg-desktop-portal-kde
    log "Flatpak removido."
}
