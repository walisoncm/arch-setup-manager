#!/usr/bin/env bash
APP_ID="kdeconnect"
APP_NAME="KDE Connect"
APP_DESC="Integração com smartphone (arquivos, clipboard, notificações)"

install_kdeconnect() {
    step "Instalando KDE Connect..."
    install_pkg kdeconnect

    step "Abrindo porta no firewall..."
    if has_pkg "ufw"; then
        sudo ufw allow 1714:1764/udp 2>/dev/null || true
        sudo ufw allow 1714:1764/tcp 2>/dev/null || true
    fi

    log "KDE Connect instalado."
    warn "Emparelhe o dispositivo via app KDE Connect no smartphone."
}
remove_kdeconnect() {
    remove_pkg kdeconnect
    if has_pkg "ufw"; then
        sudo ufw delete allow 1714:1764/udp 2>/dev/null || true
        sudo ufw delete allow 1714:1764/tcp 2>/dev/null || true
    fi
    log "KDE Connect removido."
}
