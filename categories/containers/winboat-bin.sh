#!/usr/bin/env bash
APP_ID="winboat-bin"
APP_NAME="Winboat"
APP_DESC="Windows em container"

install_winboat_bin() {
    need_aur || { err "AUR helper não encontrado."; return 1; }
    step "Instalando Winboat..."
    has_pkg "podman" || install_podman
    install_pkg winboat-bin
    log "Winboat instalado!"
}
remove_winboat_bin() {
    step "Removendo Winboat e limpando rastros..."
    
    # Matar processos do Winboat
    if pgrep -i winboat &>/dev/null; then
        log "Finalizando processos do Winboat..."
        pkill -9 -i winboat || true
        sleep 1
    fi

    # Parar e remover container (tenta podman e docker, ignorando case)
    for engine in podman docker; do
        if command -v $engine &>/dev/null; then
            # Busca containers que contenham 'winboat' no nome (case-insensitive)
            local containers=$($engine ps -a --format "{{.Names}}" | grep -i "winboat")
            if [[ -n "$containers" ]]; then
                log "Removendo containers do $engine ($containers)..."
                $engine rm -f $containers &>/dev/null || true
            fi
            
            # Remover imagem se existir (dockur/windows é a imagem padrão do winboat)
            local images=$($engine images --format "{{.Repository}}:{{.Tag}}" | grep -E "dockur/windows|winboat")
            if [[ -n "$images" ]]; then
                log "Removendo imagens do $engine..."
                $engine rmi -f $images &>/dev/null || true
            fi
        fi
    done

    [[ -f "$HOME/.winboat/podman-compose.yml" ]] && (cd "$HOME/.winboat" && podman compose down 2>/dev/null) || true
    
    # Limpar diretórios de dados e config
    for dir in "$HOME/.winboat" "$HOME/.config/winboat"; do
        if [[ -d "$dir" ]]; then
            log "Removendo diretório $dir..."
            sudo rm -rf "$dir"
        fi
    done

    remove_pkg winboat-bin
    log "Winboat removido completamente."
}
