#!/usr/bin/env bash
APP_ID="earlyoom"
APP_NAME="EarlyOOM"
APP_DESC="Evita travamentos por falta de RAM"

# svc_enabled verifica setup completo, não só o pacote
status_earlyoom() { has_pkg "earlyoom" && svc_enabled "earlyoom.service"; }

install_earlyoom() {
    step "Instalando EarlyOOM..."
    install_pkg earlyoom
    sudo systemctl enable --now earlyoom.service
    log "EarlyOOM ativo."
}
remove_earlyoom() {
    sudo systemctl stop earlyoom.service 2>/dev/null || true
    sudo systemctl disable earlyoom.service 2>/dev/null || true
    remove_pkg earlyoom
    log "EarlyOOM removido."
}
