#!/usr/bin/env bash
CAT_ID="media"
CAT_TITLE="Mídia"
CAT_ICON="▶️"
CAT_DESC="Players de vídeo, áudio e codecs"
CAT_APPS="haruna pavucontrol pear-desktop gstreamer libdvdcss"

name_haruna()      { echo "Haruna"; }
name_pavucontrol() { echo "PulseAudio Control"; }
name_pear-desktop() { echo "Pear Desktop"; }

desc_haruna()      { echo "Player de vídeo moderno baseado em MPV"; }
desc_pavucontrol() { echo "Mixer de áudio com controle por app"; }
desc_pear-desktop() { echo "Player de música com integração ao Last.fm e streaming"; }

remove_haruna() {
    remove_pkg haruna
    rm -rf "$HOME/.config/haruna"
    log "Haruna removido."
}

remove_pear-desktop() {
    remove_pkg pear-desktop
    rm -rf "$HOME/.config/PearDesktop" "$HOME/.config/pear-desktop"
    log "Pear Desktop removido."
}

name_gstreamer() { echo "GStreamer Codecs"; }
name_libdvdcss() { echo "Suporte a DVD"; }

desc_gstreamer() { echo "Suporte total a vídeos e áudio"; }
desc_libdvdcss() { echo "Reprodução de DVDs protegidos"; }

status_gstreamer() { has_pkg "gst-plugins-ugly" && has_pkg "gst-libav"; }

install_gstreamer() {
    step "Instalando codecs GStreamer..."
    install_pkg gst-plugins-bad gst-plugins-ugly gst-plugins-good gst-libav gst-plugin-va gst-plugin-pipewire ffmpegthumbnailer ffmpegthumbs
    log "Codecs GStreamer instalados!"
}
remove_gstreamer() {
    remove_pkg gst-plugins-bad gst-plugins-ugly gst-libav ffmpegthumbnailer ffmpegthumbs
    log "Codecs removidos."
}

install_libdvdcss() {
    step "Instalando suporte a DVD..."
    install_pkg libdvdcss libdvdread libdvdnav
    log "Suporte a DVD instalado."
}
remove_libdvdcss() {
    remove_pkg libdvdcss libdvdread libdvdnav
    log "libdvdcss removido."
}
