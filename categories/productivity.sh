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

remove_btop() {
    remove_pkg btop
    rm -rf "$HOME/.config/btop"
    log "Btop removido."
}

remove_fastfetch() {
    remove_pkg fastfetch
    rm -rf "$HOME/.config/fastfetch"
    log "Fastfetch removido."
}
