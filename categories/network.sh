#!/usr/bin/env bash
CAT_ID="network"
CAT_TITLE="Rede"
CAT_ICON="🌐"
CAT_DESC="VPN, firewall e conectividade"
CAT_APPS="proton-vpn-gtk-app kdeconnect com.freerdp.FreeRDP ufw"

name_proton-vpn-gtk-app()  { echo "ProtonVPN"; }
name_kdeconnect()           { echo "KDE Connect"; }
name_com_freerdp_FreeRDP()  { echo "FreeRDP"; }
name_ufw()                  { echo "UFW (Firewall)"; }

desc_proton-vpn-gtk-app()  { echo "Cliente oficial ProtonVPN"; }
desc_kdeconnect()           { echo "Integração com smartphone (arquivos, clipboard, notificações)"; }
desc_com_freerdp_FreeRDP()  { echo "Cliente de área de trabalho remota RDP"; }
desc_ufw()                  { echo "Firewall simples com regras básicas"; }

# svc_enabled verifica setup completo
status_ufw() { has_pkg "ufw" && svc_enabled "ufw.service"; }

remove_proton-vpn-gtk-app() {
    remove_pkg proton-vpn-gtk-app
    rm -rf "$HOME/.config/protonvpn"
    log "ProtonVPN removido."
}

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
