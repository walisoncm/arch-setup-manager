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
    sudo pacman -S --needed --noconfirm gamemode lib32-gamemode
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
    sudo pacman -R --noconfirm gamemode lib32-gamemode 2>/dev/null || true
    log "GameMode removido."
}

install_mangohud() {
    step "Instalando MangoHud e GOverlay..."
    sudo pacman -S --needed --noconfirm mangohud lib32-mangohud goverlay
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
    sudo pacman -R --noconfirm mangohud lib32-mangohud goverlay 2>/dev/null || true
    rm -rf "$HOME/.config/MangoHud"
    log "MangoHud removido."
}

install_steam() {
    step "Instalando Steam e Millennium..."
    sudo pacman -S --needed --noconfirm steam millennium
    log "Steam instalado!"
}
remove_steam() {
    sudo pacman -R --noconfirm steam millennium 2>/dev/null || true
    log "Steam removido."
}

install_com_vysp3r_ProtonPlus() {
    step "Instalando ProtonPlus..."
    sudo flatpak install --noninteractive flathub com.vysp3r.ProtonPlus
    log "ProtonPlus instalado."
}
remove_com_vysp3r_ProtonPlus() {
    sudo flatpak uninstall --noninteractive com.vysp3r.ProtonPlus 2>/dev/null || true
    log "ProtonPlus removido."
}

install_protontricks() {
    step "Instalando Protontricks..."
    sudo pacman -S --needed --noconfirm protontricks
    log "Protontricks instalado."
}
remove_protontricks() {
    sudo pacman -R --noconfirm protontricks 2>/dev/null || true
    log "Protontricks removido."
}

install_winetricks() {
    step "Instalando Winetricks..."
    sudo pacman -S --needed --noconfirm winetricks
    log "Winetricks instalado."
}
remove_winetricks() {
    sudo pacman -R --noconfirm winetricks 2>/dev/null || true
    log "Winetricks removido."
}

install_com_usebottles_bottles() {
    step "Instalando Bottles..."
    sudo flatpak install --noninteractive flathub com.usebottles.bottles
    log "Bottles instalado."
}
remove_com_usebottles_bottles() {
    sudo flatpak uninstall --noninteractive com.usebottles.bottles 2>/dev/null || true
    log "Bottles removido."
}

install_lutris() {
    step "Instalando Lutris..."
    sudo pacman -S --needed --noconfirm lutris
    log "Lutris instalado."
}
remove_lutris() {
    sudo pacman -R --noconfirm lutris 2>/dev/null || true
    rm -rf "$HOME/.config/lutris" "$HOME/.local/share/lutris"
    log "Lutris e dados removidos."
}
