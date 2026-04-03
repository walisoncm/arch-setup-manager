#!/usr/bin/env bash
CAT_ID="gaming"
CAT_TITLE="Gaming"
CAT_ICON="🎮"
CAT_DESC="Performance, overlays e launchers"
CAT_APPS="gamemode mangohud gamescope steam heroic-games-launcher-bin com.vysp3r.ProtonPlus protontricks winetricks com.usebottles.bottles lutris"

name_gamemode()                    { echo "GameMode"; }
name_mangohud()                    { echo "MangoHud + GOverlay"; }
name_gamescope()                   { echo "Gamescope"; }
name_steam()                       { echo "Steam + Millennium"; }
name_heroic-games-launcher-bin()   { echo "Heroic Games Launcher"; }
name_com_vysp3r_ProtonPlus()       { echo "ProtonPlus"; }
name_protontricks()                { echo "Protontricks"; }
name_winetricks()                  { echo "Winetricks"; }
name_com_usebottles_bottles()      { echo "Bottles"; }
name_lutris()                      { echo "Lutris"; }

desc_gamemode()                    { echo "Boost automático de CPU/GPU ao iniciar jogos"; }
desc_mangohud()                    { echo "Overlay de FPS/GPU/CPU e configurador visual"; }
desc_gamescope()                   { echo "Compositor micro-Wayland para jogos (upscaling, VRR)"; }
desc_steam()                       { echo "Launcher de jogos com skin manager"; }
desc_heroic-games-launcher-bin()   { echo "Launcher para Epic Games, GOG e Amazon"; }
desc_com_vysp3r_ProtonPlus()       { echo "Gerenciador de versões do Proton/Wine"; }
desc_protontricks()                { echo "Instala dependências Wine em prefixos Steam"; }
desc_winetricks()                  { echo "Scripts de compatibilidade para apps Windows"; }
desc_com_usebottles_bottles()      { echo "Gerenciador de prefixos Wine para apps fora do Steam"; }
desc_lutris()                      { echo "Launcher de jogos com scripts de instalação"; }

install_gamemode() {
    step "Instalando GameMode..."
    install_pkg gamemode lib32-gamemode
    step "Adicionando ao grupo..."
    sudo usermod -aG gamemode "$USER"
    step "Habilitando serviço de usuário..."
    systemctl --user enable --now gamemoded.service 2>/dev/null || true
    log "GameMode instalado!"
    warn "Logout/login para aplicar o grupo gamemode."
}
remove_gamemode() {
    systemctl --user disable --now gamemoded.service 2>/dev/null || true
    sudo gpasswd -d "$USER" gamemode 2>/dev/null || true
    remove_pkg gamemode lib32-gamemode
    log "GameMode removido."
}

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

install_steam() {
    step "Instalando Steam + Millennium..."
    install_pkg steam millennium
    log "Steam instalado!"
}
remove_steam() {
    remove_pkg steam millennium
    log "Steam removido."
}

remove_lutris() {
    remove_pkg lutris
    rm -rf "$HOME/.config/lutris" "$HOME/.local/share/lutris"
    log "Lutris e dados removidos."
}
