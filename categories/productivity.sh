#!/usr/bin/env bash
CAT_ID="productivity"
CAT_TITLE="Produtividade"
CAT_ICON="📝"
CAT_DESC="Notas, monitoramento e utilidades"
CAT_APPS="obsidian btop fastfetch"

name_obsidian()  { echo "Obsidian"; }
name_btop()      { echo "Btop"; }
name_fastfetch() { echo "Fastfetch"; }

desc_obsidian()  { echo "Editor de notas em Markdown com vault local"; }
desc_btop()      { echo "Monitor de recursos interativo"; }
desc_fastfetch() { echo "Informações do sistema estilizadas"; }

install_obsidian() {
    step "Instalando Obsidian..."
    sudo pacman -S --needed --noconfirm obsidian
    log "Obsidian instalado."
}
remove_obsidian() {
    sudo pacman -R --noconfirm obsidian 2>/dev/null || true
    log "Obsidian removido."
}

install_btop() {
    step "Instalando Btop..."
    sudo pacman -S --needed --noconfirm btop
    log "Btop instalado."
}
remove_btop() {
    sudo pacman -R --noconfirm btop 2>/dev/null || true
    rm -rf "$HOME/.config/btop"
    log "Btop removido."
}

install_fastfetch() {
    step "Instalando Fastfetch..."
    sudo pacman -S --needed --noconfirm fastfetch
    log "Fastfetch instalado."
}
remove_fastfetch() {
    sudo pacman -R --noconfirm fastfetch 2>/dev/null || true
    rm -rf "$HOME/.config/fastfetch"
    log "Fastfetch removido."
}
