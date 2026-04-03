#!/usr/bin/env bash
CAT_ID="media"
CAT_TITLE="Mídia"
CAT_ICON="▶️"
CAT_DESC="Players de vídeo e áudio"
CAT_APPS="haruna pavucontrol pear-desktop"

name_haruna()      { echo "Haruna"; }
name_pavucontrol() { echo "PulseAudio Control"; }
name_pear-desktop() { echo "Pear Desktop"; }

desc_haruna()      { echo "Player de vídeo moderno baseado em MPV"; }
desc_pavucontrol() { echo "Mixer de áudio com controle por app"; }
desc_pear-desktop() { echo "Player de música com integração ao Last.fm e streaming"; }

install_haruna() {
    step "Instalando Haruna..."
    sudo pacman -S --needed --noconfirm haruna
    log "Haruna instalado."
}
remove_haruna() {
    sudo pacman -R --noconfirm haruna 2>/dev/null || true
    rm -rf "$HOME/.config/haruna"
    log "Haruna removido."
}

install_pavucontrol() {
    step "Instalando PulseAudio Control..."
    sudo pacman -S --needed --noconfirm pavucontrol
    log "PulseAudio Control instalado."
}
remove_pavucontrol() {
    sudo pacman -R --noconfirm pavucontrol 2>/dev/null || true
    log "PulseAudio Control removido."
}

install_pear-desktop() {
    need_aur || { err "AUR helper não encontrado."; return 1; }
    step "Instalando Pear Desktop..."
    $AUR -S --needed --noconfirm pear-desktop
    log "Pear Desktop instalado."
}
remove_pear-desktop() {
    $AUR -R --noconfirm pear-desktop 2>/dev/null || true
    rm -rf "$HOME/.config/PearDesktop" "$HOME/.config/pear-desktop"
    log "Pear Desktop removido."
}
