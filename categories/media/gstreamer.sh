#!/usr/bin/env bash
APP_ID="gstreamer"
APP_NAME="GStreamer Codecs"
APP_DESC="Suporte total a vídeos e áudio"

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
