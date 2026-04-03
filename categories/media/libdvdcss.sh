#!/usr/bin/env bash
APP_ID="libdvdcss"
APP_NAME="Suporte a DVD"
APP_DESC="Reprodução de DVDs protegidos"

install_libdvdcss() {
    step "Instalando suporte a DVD..."
    install_pkg libdvdcss libdvdread libdvdnav
    log "Suporte a DVD instalado."
}
remove_libdvdcss() {
    remove_pkg libdvdcss libdvdread libdvdnav
    log "libdvdcss removido."
}
