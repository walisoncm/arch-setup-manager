#!/usr/bin/env bash
CAT_ID="containers"
CAT_TITLE="Containers"
CAT_ICON="🐋"
CAT_DESC="Virtual machines e containers"
CAT_APPS="docker podman podman-desktop gnome-boxes distrobox winboat-bin waydroid"

name_docker()          { echo "Docker + Compose"; }
name_podman()          { echo "Podman"; }
name_podman-desktop()  { echo "Podman Desktop"; }
name_gnome-boxes()     { echo "GNOME Boxes"; }
name_distrobox()       { echo "Distrobox"; }
name_winboat-bin()     { echo "Winboat"; }
name_waydroid()        { echo "Waydroid"; }

desc_docker()          { echo "Docker Engine com usuário no grupo"; }
desc_podman()          { echo "Podman Engine rootless"; }
desc_podman-desktop()  { echo "Interface gráfica para Podman e Kubernetes"; }
desc_gnome-boxes()     { echo "VMs de qualquer distro com interface gráfica"; }
desc_distrobox()       { echo "Containers de qualquer distro no terminal"; }
desc_winboat-bin()     { echo "Windows em container"; }
desc_waydroid()        { echo "Android em container"; }

# in_group é parte do setup — verifica instalação completa
status_docker() { has_pkg "docker" && in_group "docker"; }

install_docker() {
    step "Instalando Docker..."
    sudo pacman -S --needed --noconfirm docker docker-compose docker-buildx
    step "Habilitando serviço..."
    sudo systemctl enable --now docker.socket
    sudo systemctl enable docker.service
    sudo usermod -aG docker "$USER"
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json > /dev/null <<'EOF'
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": { "max-size": "50m", "max-file": "3" }
}
EOF
    log "Docker instalado!"
    warn "Logout/login necessário para usar sem sudo."
}
remove_docker() {
    sudo systemctl stop docker.service docker.socket 2>/dev/null || true
    sudo systemctl disable docker.service docker.socket 2>/dev/null || true
    sudo pacman -R --noconfirm docker docker-compose docker-buildx 2>/dev/null || true
    sudo rm -f /etc/docker/daemon.json
    log "Docker removido."
}

install_podman() {
    step "Instalando Podman..."
    sudo pacman -S --needed --noconfirm podman podman-compose
    log "Podman instalado!"
}
remove_podman() {
    sudo pacman -R --noconfirm podman podman-compose 2>/dev/null || true
    log "Podman removido."
}

install_podman-desktop() {
    step "Instalando Podman Desktop..."
    sudo pacman -S --needed --noconfirm podman-desktop
    log "Podman Desktop instalado."
}
remove_podman-desktop() {
    sudo pacman -R --noconfirm podman-desktop 2>/dev/null || true
    log "Podman Desktop removido."
}

install_winboat-bin() {
    need_aur || { err "AUR helper não encontrado."; return 1; }
    step "Instalando Winboat..."
    $AUR -S --needed --noconfirm winboat-bin
    has_pkg "podman" || install_podman
    log "Winboat instalado!"
}
remove_winboat-bin() {
    [[ -f "$HOME/.winboat/podman-compose.yml" ]] && (cd "$HOME/.winboat" && podman compose down 2>/dev/null) || true
    $AUR -R --noconfirm winboat-bin 2>/dev/null || true
    log "Winboat removido."
}

install_gnome-boxes() {
    step "Instalando GNOME Boxes..."
    sudo pacman -S --needed --noconfirm gnome-boxes
    log "GNOME Boxes instalado!"
}
remove_gnome-boxes() {
    sudo pacman -R --noconfirm gnome-boxes 2>/dev/null || true
    log "GNOME Boxes removido."
}

install_distrobox() {
    step "Instalando Distrobox..."
    sudo pacman -S --needed --noconfirm distrobox
    log "Distrobox instalado!"
}
remove_distrobox() {
    sudo pacman -R --noconfirm distrobox 2>/dev/null || true
    log "Distrobox removido."
}

status_waydroid() {
    has_pkg "waydroid" && svc_enabled "waydroid-container.service" && [[ -d "/var/lib/waydroid/images" ]]
}

# Detecta GPU NVIDIA proprietária e configura Waydroid para usar a GPU integrada.
# O driver NVIDIA proprietário não expõe a interface DRM que o waydroidplatform precisa,
# causando tela preta e "Failed to get service waydroidplatform".
_waydroid_fix_nvidia_render() {
    lsmod 2>/dev/null | grep -q '^nvidia ' || return 0

    # Slots PCI das GPUs NVIDIA (ex: "01:00.0")
    local nvidia_slots
    nvidia_slots=$(lspci 2>/dev/null | grep -i nvidia | awk '{print $1}')

    # Procura o primeiro render device que NÃO pertence à NVIDIA
    local render_dev=""
    for link in /dev/dri/by-path/pci-*-render; do
        [[ -L "$link" ]] || continue
        # pci-0000:01:00.0-render → 01:00.0
        local slot
        slot=$(basename "$link" | sed 's/pci-[0-9]*://;s/-render//')
        local is_nvidia=false
        for nv in $nvidia_slots; do
            [[ "$slot" == "$nv" ]] && { is_nvidia=true; break; }
        done
        $is_nvidia || { render_dev=$(readlink -f "$link"); break; }
    done

    if [[ -n "$render_dev" ]]; then
        step "GPU NVIDIA detectada — configurando Waydroid para usar GPU integrada ($render_dev)..."
        # Evita duplicar a linha se já foi definida (re-instalação)
        if ! grep -q "^render_device" /var/lib/waydroid/waydroid.cfg 2>/dev/null; then
            sudo sed -i "/^\[waydroid\]/a render_device = $render_dev" /var/lib/waydroid/waydroid.cfg
        else
            sudo sed -i "s|^render_device.*|render_device = $render_dev|" /var/lib/waydroid/waydroid.cfg
        fi
        sudo systemctl restart waydroid-container.service
        sleep 3
    else
        warn "GPU NVIDIA detectada mas não foi possível encontrar GPU integrada."
        warn "Se a UI piscar, adicione 'render_device = /dev/dri/renderD129' em /var/lib/waydroid/waydroid.cfg"
    fi
}

install_waydroid() {
    need_aur || { err "AUR helper não encontrado."; return 1; }

    step "Instalando dependências..."
    # wl-clipboard: integração de clipboard Wayland ↔ Android
    sudo pacman -S --needed --noconfirm wl-clipboard python || { err "Falha ao instalar dependências."; return 1; }

    step "Instalando Waydroid..."
    $AUR -S --needed --noconfirm waydroid || { err "Falha ao instalar waydroid."; return 1; }

    step "Carregando módulo binder_linux..."
    if ! lsmod 2>/dev/null | grep -q binder; then
        sudo modprobe binder_linux 2>/dev/null || sudo modprobe binder 2>/dev/null || \
            warn "Módulo binder não carregado — verifique se o kernel tem suporte a binder."
    fi
    # Persistir módulo entre reboots
    echo "binder_linux" | sudo tee /etc/modules-load.d/waydroid.conf > /dev/null

    step "Habilitando serviço de container..."
    sudo systemctl enable --now waydroid-container.service || { err "Falha ao habilitar waydroid-container.service."; return 1; }

    step "Inicializando imagem Android (vanilla AOSP)..."
    warn "O download da imagem pode demorar alguns minutos (~500 MB)."
    if ! sudo waydroid init; then
        err "Falha na inicialização. Verifique a conectividade e tente 'sudo waydroid init' manualmente."
        return 1
    fi

    _waydroid_fix_nvidia_render

    step "Iniciando sessão para aplicar configurações..."
    waydroid session start &>/dev/null &
    local _pid=$!
    sleep 6  # aguarda o container subir

    step "Aplicando otimizações..."
    # Cada app Android abre como janela independente no desktop Linux
    waydroid prop set persist.waydroid.multi_windows true
    # Resolução automática (adapta ao monitor atual)
    waydroid prop set persist.waydroid.width 0
    waydroid prop set persist.waydroid.height 0
    # Cursor dentro de subsurfaces (evita artefatos de ponteiro)
    waydroid prop set persist.waydroid.cursor_on_subsurface false

    # Forçar ativação do clipboard manager do Android
    # O clipboard Wayland↔Android funciona via wl-clipboard + serviço interno do Waydroid
    waydroid prop set persist.waydroid.clipboard_manager true 2>/dev/null || true

    waydroid session stop 2>/dev/null || true
    wait $_pid 2>/dev/null || true

    log "Waydroid instalado e configurado!"
    log "Apps instalados via 'waydroid app install <apk>' aparecem automaticamente no launcher."
    warn "Para tradução ARM (apps não-x86): execute 'waydroid-extras' ou instale via waydroid_script após o setup."
}

remove_waydroid() {
    step "Parando sessão..."
    waydroid session stop 2>/dev/null || true
    sudo systemctl stop waydroid-container.service 2>/dev/null || true
    sudo systemctl disable waydroid-container.service 2>/dev/null || true

    step "Removendo pacote..."
    $AUR -R --noconfirm waydroid 2>/dev/null || sudo pacman -R --noconfirm waydroid 2>/dev/null || true

    step "Limpando dados e entradas do launcher..."
    sudo rm -rf /var/lib/waydroid
    rm -rf "$HOME/.local/share/waydroid"
    rm -rf "$HOME/.local/share/applications/waydroid"
    rm -rf "$HOME/.local/share/waydroid-launchers"
    sudo rm -f /etc/modules-load.d/waydroid.conf

    log "Waydroid removido."
}
