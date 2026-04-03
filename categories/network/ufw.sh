#!/usr/bin/env bash
APP_ID="ufw"
APP_NAME="UFW (Firewall)"
APP_DESC="Firewall simples com regras básicas"

# svc_enabled verifica setup completo
status_ufw() { has_pkg "ufw" && svc_enabled "ufw.service"; }

install_ufw() {
    step "Instalando UFW..."
    install_pkg ufw

    step "Configurando regras básicas..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh

    step "Habilitando firewall..."
    sudo systemctl enable --now ufw.service
    sudo ufw --force enable

    log "UFW ativo com política deny-incoming / allow-outgoing."
}
remove_ufw() {
    sudo ufw --force disable 2>/dev/null || true
    sudo systemctl stop ufw.service 2>/dev/null || true
    sudo systemctl disable ufw.service 2>/dev/null || true
    remove_pkg ufw
    log "UFW removido."
}
