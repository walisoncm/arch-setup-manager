#!/usr/bin/env bash
APP_ID="gamemode"
APP_NAME="GameMode"
APP_DESC="Boost automático de CPU/GPU ao iniciar jogos"

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
