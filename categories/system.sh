#!/usr/bin/env bash
CAT_ID="system"
CAT_TITLE="Sistema"
CAT_ICON="⚙️"
CAT_DESC="Utilitários e otimizações"
CAT_APPS="earlyoom flatpak fwupd shelly"

name_earlyoom() { echo "EarlyOOM"; }
name_flatpak()  { echo "Flatpak + Flathub"; }
name_fwupd()    { echo "fwupd (Firmware Updates)"; }
name_shelly()   { echo "Shelly"; }

desc_earlyoom() { echo "Evita travamentos por falta de RAM"; }
desc_flatpak()  { echo "Suporte a apps universais"; }
desc_fwupd()    { echo "Atualização de BIOS e Hardware"; }
desc_shelly()   { echo "Gerenciador de pacotes Arch moderno"; }

# svc_enabled verifica setup completo, não só o pacote
status_earlyoom() { has_pkg "earlyoom" && svc_enabled "earlyoom.service"; }

# Verifica também se o remote flathub foi adicionado
status_flatpak() { has_pkg "flatpak" && flatpak remotes 2>/dev/null | grep -q "flathub"; }

install_earlyoom() {
    step "Instalando EarlyOOM..."
    sudo pacman -S --needed --noconfirm earlyoom
    sudo systemctl enable --now earlyoom.service
    log "EarlyOOM ativo."
}
remove_earlyoom() {
    sudo systemctl stop earlyoom.service 2>/dev/null || true
    sudo systemctl disable earlyoom.service 2>/dev/null || true
    sudo pacman -R --noconfirm earlyoom 2>/dev/null || true
    log "EarlyOOM removido."
}

install_flatpak() {
    step "Instalando Flatpak + Flathub..."
    sudo pacman -S --needed --noconfirm flatpak xdg-desktop-portal-kde
    sudo flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    log "Flatpak + Flathub configurados!"
}
remove_flatpak() {
    flatpak uninstall --all --noninteractive 2>/dev/null || true
    sudo pacman -R --noconfirm flatpak 2>/dev/null || true
    log "Flatpak removido."
}

install_fwupd() {
    step "Instalando fwupd..."
    sudo pacman -S --needed --noconfirm fwupd
    sudo systemctl enable --now fwupd-refresh.timer
    log "fwupd instalado."
}
remove_fwupd() {
    sudo pacman -R --noconfirm fwupd 2>/dev/null || true
    log "fwupd removido."
}

install_shelly() {
    need_aur || { err "AUR helper não encontrado."; return 1; }
    step "Instalando Shelly..."
    $AUR -S --needed --noconfirm shelly
    log "Shelly instalado."
}
remove_shelly() {
    $AUR -R --noconfirm shelly 2>/dev/null || true
    log "Shelly removido."
}
