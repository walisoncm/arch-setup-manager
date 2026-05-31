#!/usr/bin/env bash
APP_ID="winboat-bin"
APP_NAME="Winboat"
APP_DESC="Windows em container"

install_winboat_bin() {
    need_aur || { err "AUR helper não encontrado."; return 1; }
    step "Instalando Winboat..."
    
    # Dependências de sistema para Podman rootless
    has_pkg "podman" || install_podman
    has_pkg "slirp4netns" || install_pkg slirp4netns
    
    # Configurar DNS global do Podman para evitar falhas de resolução em modo rootless
    mkdir -p "$HOME/.config/containers"
    if [[ ! -f "$HOME/.config/containers/containers.conf" ]]; then
        log "Configurando DNS público para o Podman..."
        echo -e "[containers]\ndns_servers = [\"8.8.8.8\", \"1.1.1.1\"]" > "$HOME/.config/containers/containers.conf"
    fi

    install_pkg winboat-bin
    
    # Criar diretório base se não existir para garantir que o patch seja aplicado
    mkdir -p "$HOME/.winboat"

    # Se o podman-compose.yml ainda não existe, tenta baixar o padrão do winboat para patchear antes do primeiro run
    if [[ ! -f "$HOME/.winboat/podman-compose.yml" ]]; then
        log "Pré-configurando podman-compose.yml..."
        # Tenta copiar o template do pacote (geralmente em /opt/winboat ou similar)
        if [[ -f "/opt/winboat/podman-compose.yml" ]]; then
            cp "/opt/winboat/podman-compose.yml" "$HOME/.winboat/podman-compose.yml"
        fi
    fi

    # Aplica patches de rede e dispositivos se o arquivo existir
    if [[ -f "$HOME/.winboat/podman-compose.yml" ]]; then
        log "Aplicando patches de rede e tun no podman-compose.yml..."
        # Força NETWORK: host e network_mode: host para melhor compatibilidade rootless
        sed -i 's/NETWORK: user/NETWORK: host/' "$HOME/.winboat/podman-compose.yml"
        grep -q "network_mode: host" "$HOME/.winboat/podman-compose.yml" || \
            sed -i '/environment:/i \    network_mode: host' "$HOME/.winboat/podman-compose.yml"
        
        # Adicionar /dev/net/tun se estiver faltando
        if ! grep -q "/dev/net/tun" "$HOME/.winboat/podman-compose.yml"; then
            if grep -q "devices:" "$HOME/.winboat/podman-compose.yml"; then
                sed -i '/devices:/a \      - /dev/net/tun' "$HOME/.winboat/podman-compose.yml"
            else
                sed -i '/volumes:/i \    devices:\n      - /dev/net/tun' "$HOME/.winboat/podman-compose.yml"
            fi
        fi
    fi

    log "Winboat instalado! (Nota: Se o download falhar, abra o app uma vez e reinicie a instalação)."
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
