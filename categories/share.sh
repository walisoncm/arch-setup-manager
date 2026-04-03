#!/usr/bin/env bash
CAT_ID="share"
CAT_TITLE="Compartilhamento"
CAT_ICON="📂"
CAT_DESC="Share files and desktops"
CAT_APPS="rustdesk-bin org.localsend.localsend_app"

name_rustdesk-bin()              { echo "RustDesk"; }
name_org_localsend_localsend_app() { echo "LocalSend"; }

desc_rustdesk-bin()              { echo "Desktop remoto open-source"; }
desc_org_localsend_localsend_app() { echo "Envio de arquivos via rede local"; }

install_rustdesk-bin() {
    need_aur || { err "AUR helper não encontrado."; return 1; }
    step "Instalando RustDesk..."
    $AUR -S --needed --noconfirm rustdesk-bin
    log "RustDesk instalado."
}
remove_rustdesk-bin() {
    $AUR -R --noconfirm rustdesk-bin 2>/dev/null || true
    log "RustDesk removido."
}

install_org_localsend_localsend_app() {
    step "Instalando LocalSend..."
    sudo flatpak install --noninteractive flathub org.localsend.localsend_app
    log "LocalSend instalado."
}
remove_org_localsend_localsend_app() {
    sudo flatpak uninstall --noninteractive org.localsend.localsend_app 2>/dev/null || true
    log "LocalSend removido."
}
