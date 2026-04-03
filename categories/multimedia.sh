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
