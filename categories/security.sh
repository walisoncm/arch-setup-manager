#!/usr/bin/env bash
CAT_ID="security"
CAT_TITLE="Segurança"
CAT_ICON="🔒"
CAT_DESC="Senhas e privacidade"
CAT_APPS="proton-pass"

name_proton-pass() { echo "ProtonPass"; }
desc_proton-pass() { echo "Gerenciador de senhas do ecossistema Proton"; }

install_proton-pass() {
    need_aur || { err "AUR helper não encontrado."; return 1; }
    step "Instalando ProtonPass..."
    $AUR -S --needed --noconfirm proton-pass || { err "Falha ao instalar proton-pass."; return 1; }
    log "ProtonPass instalado."
}
remove_proton-pass() {
    $AUR -R --noconfirm proton-pass 2>/dev/null || true
    log "ProtonPass removido."
}
