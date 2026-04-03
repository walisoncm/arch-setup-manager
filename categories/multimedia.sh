#!/usr/bin/env bash
CAT_ID="multimedia"
CAT_TITLE="Multimídia"
CAT_ICON="🎬"
CAT_DESC="Codecs de vídeo e áudio"
CAT_APPS="gstreamer libdvdcss"

name_gstreamer() { echo "GStreamer Codecs"; }
name_libdvdcss() { echo "Suporte a DVD"; }

desc_gstreamer() { echo "Suporte total a vídeos e áudio"; }
desc_libdvdcss() { echo "Reprodução de DVDs protegidos"; }

# Verifica dois pacotes distintos — nome do grupo "gstreamer" não é o pacote real
status_gstreamer() { has_pkg "gst-plugins-ugly" && has_pkg "gst-libav"; }

install_gstreamer() {
    step "Instalando codecs GStreamer..."
    sudo pacman -S --needed --noconfirm gst-plugins-bad gst-plugins-ugly gst-plugins-good gst-libav gst-plugin-va gst-plugin-pipewire ffmpegthumbnailer ffmpegthumbs
    log "Codecs GStreamer instalados!"
}
remove_gstreamer() {
    sudo pacman -R --noconfirm gst-plugins-bad gst-plugins-ugly gst-libav ffmpegthumbnailer ffmpegthumbs 2>/dev/null || true
    log "Codecs removidos."
}

install_libdvdcss() {
    step "Instalando suporte a DVD..."
    sudo pacman -S --needed --noconfirm libdvdcss libdvdread libdvdnav
    log "Suporte a DVD instalado."
}
remove_libdvdcss() {
    sudo pacman -R --noconfirm libdvdcss libdvdread libdvdnav 2>/dev/null || true
    log "libdvdcss removido."
}
