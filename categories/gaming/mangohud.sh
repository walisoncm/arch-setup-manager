#!/usr/bin/env bash
APP_ID="mangohud"
APP_NAME="MangoHud + GOverlay"
APP_DESC="Overlay de FPS/GPU/CPU e configurador visual"

install_mangohud() {
    step "Instalando MangoHud e GOverlay..."
    install_pkg mangohud lib32-mangohud goverlay
    step "Criando config padrão..."
    mkdir -p "$HOME/.config/MangoHud"
    cat > "$HOME/.config/MangoHud/MangoHud.conf" <<'EOF'
gpu_stats
cpu_stats
cpu_temp
gpu_temp
ram
fps
frametime
position=top-left
font_size=24
background_alpha=0.5
toggle_hud=Shift_R+F12
EOF
    log "MangoHud instalado! Use MANGOHUD=1 na Steam."
}
remove_mangohud() {
    remove_pkg mangohud lib32-mangohud goverlay
    rm -rf "$HOME/.config/MangoHud"
    log "MangoHud removido."
}
