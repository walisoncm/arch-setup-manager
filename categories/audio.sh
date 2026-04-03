#!/usr/bin/env bash
CAT_ID="audio"
CAT_TITLE="Áudio"
CAT_ICON="🎵"
CAT_DESC="DSP, equalizer e efeitos"
CAT_APPS="easyeffects jamesdsp"

name_easyeffects() { echo "EasyEffects"; }
name_jamesdsp()    { echo "JamesDSP"; }

desc_easyeffects() { echo "Equalizer e efeitos para PipeWire"; }
desc_jamesdsp()    { echo "DSP avançado (bass boost, convolução)"; }

install_easyeffects() {
    step "Instalando EasyEffects..."
    sudo pacman -S --needed --noconfirm easyeffects lsp-plugins
    step "Configurando autostart..."
    mkdir -p "$HOME/.config/autostart"
    cat > "$HOME/.config/autostart/easyeffects-service.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=EasyEffects Service
Exec=easyeffects --gapplication-service
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
    log "EasyEffects instalado com autostart."
}
remove_easyeffects() {
    pkill -f easyeffects 2>/dev/null || true
    sudo pacman -R --noconfirm easyeffects 2>/dev/null || true
    rm -f "$HOME/.config/autostart/easyeffects-service.desktop"
    rm -rf "$HOME/.config/easyeffects"
    log "EasyEffects removido."
}

install_jamesdsp() {
    need_aur || { err "AUR helper não encontrado."; return 1; }
    step "Instalando JamesDSP..."
    $AUR -S --needed --noconfirm jamesdsp
    step "Configurando autostart..."
    mkdir -p "$HOME/.config/autostart"
    cat > "$HOME/.config/autostart/jamesdsp.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=JamesDSP
Exec=jamesdsp --tray
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
    log "JamesDSP instalado com autostart."
}
remove_jamesdsp() {
    pkill -f jamesdsp 2>/dev/null || true
    $AUR -R --noconfirm jamesdsp 2>/dev/null || true
    rm -f "$HOME/.config/autostart/jamesdsp.desktop"
    rm -rf "$HOME/.config/jamesdsp"
    log "JamesDSP removido."
}
