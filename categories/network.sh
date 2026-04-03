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

install_proton-vpn-gtk-app() {
    step "Instalando ProtonVPN..."
    sudo pacman -S --needed --noconfirm proton-vpn-gtk-app
    log "ProtonVPN instalado."
}
remove_proton-vpn-gtk-app() {
    sudo pacman -R --noconfirm proton-vpn-gtk-app 2>/dev/null || true
    rm -rf "$HOME/.config/protonvpn"
    log "ProtonVPN removido."
}

install_kdeconnect() {
    step "Instalando KDE Connect..."
    sudo pacman -S --needed --noconfirm kdeconnect

    step "Abrindo porta no firewall..."
    if has_pkg "ufw"; then
        sudo ufw allow 1714:1764/udp 2>/dev/null || true
        sudo ufw allow 1714:1764/tcp 2>/dev/null || true
    fi

    log "KDE Connect instalado."
    warn "Emparelhe o dispositivo via app KDE Connect no smartphone."
}
remove_kdeconnect() {
    sudo pacman -R --noconfirm kdeconnect 2>/dev/null || true
    if has_pkg "ufw"; then
        sudo ufw delete allow 1714:1764/udp 2>/dev/null || true
        sudo ufw delete allow 1714:1764/tcp 2>/dev/null || true
    fi
    log "KDE Connect removido."
}

install_com_freerdp_FreeRDP() {
    step "Instalando FreeRDP..."
    sudo flatpak install --noninteractive flathub com.freerdp.FreeRDP
    log "FreeRDP instalado."
}
remove_com_freerdp_FreeRDP() {
    sudo flatpak uninstall --noninteractive com.freerdp.FreeRDP 2>/dev/null || true
    log "FreeRDP removido."
}

install_ufw() {
    step "Instalando UFW..."
    sudo pacman -S --needed --noconfirm ufw

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
    sudo pacman -R --noconfirm ufw 2>/dev/null || true
    log "UFW removido."
}
