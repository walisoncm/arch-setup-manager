#!/usr/bin/env bash
CAT_ID="ai"
CAT_TITLE="IA"
CAT_ICON="🤖"
CAT_DESC="IA Local com aceleração GPU"
CAT_APPS="ollama open-webui"

name_ollama()    { echo "Ollama"; }
name_open-webui() { echo "Open WebUI"; }

desc_ollama()    { echo "IA Local com aceleração GPU"; }
desc_open-webui() { echo "Interface web para Ollama (chat, modelos, histórico)"; }

status_ollama()    { has_cmd "ollama"; }
status_open-webui() { has_pkg "open-webui" && svc_enabled "open-webui.service"; }

install_ollama() {
    step "Instalando Ollama..."
    if ! sudo pacman -S --needed --noconfirm ollama 2>/dev/null; then
        curl -fsSL https://ollama.ai/install.sh | sh
    fi
    sudo systemctl enable --now ollama.service 2>/dev/null || true
    log "Ollama instalado!"
}
remove_ollama() {
    sudo systemctl stop ollama.service 2>/dev/null || true
    sudo pacman -R --noconfirm ollama 2>/dev/null || true
    log "Ollama removido."
}

install_open-webui() {
    need_aur || { err "AUR helper não encontrado."; return 1; }

    # open-webui requer 'nodejs' que conflita com nodejs-lts-*
    # Como o usuário usa nvm-fish, o pacote sistema de nodejs-lts pode ser substituído com segurança
    local lts_pkg=""
    for candidate in nodejs-lts-krypton nodejs-lts-iron nodejs-lts-hydrogen nodejs-lts-fermium nodejs-lts-gallium; do
        if has_pkg "$candidate"; then
            lts_pkg="$candidate"
            break
        fi
    done

    if [[ -n "$lts_pkg" ]]; then
        warn "Conflito detectado: $lts_pkg ↔ nodejs. Substituindo (nvm-fish não depende do pacote sistema)..."
        sudo pacman -R --noconfirm "$lts_pkg" || { err "Não foi possível remover $lts_pkg."; return 1; }
    fi

    step "Instalando Open WebUI..."
    $AUR -S --needed --noconfirm open-webui || { err "Falha ao instalar open-webui."; return 1; }

    step "Habilitando serviço..."
    sudo systemctl enable --now open-webui.service || { err "Falha ao habilitar open-webui.service."; return 1; }

    log "Open WebUI instalado! Acesse em http://localhost:8080"
}
remove_open-webui() {
    sudo systemctl stop open-webui.service 2>/dev/null || true
    sudo systemctl disable open-webui.service 2>/dev/null || true
    $AUR -R --noconfirm open-webui 2>/dev/null || true
    log "Open WebUI removido."
}
