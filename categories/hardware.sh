#!/usr/bin/env bash
CAT_ID="hardware"
CAT_TITLE="Hardware"
CAT_ICON="🔋"
CAT_DESC="Bateria, performance e RGB"
CAT_APPS="damx"

name_damx()   { echo "DAMX (Acer Nitro)"; }
desc_damx()   { echo "Bateria, performance e RGB para o Nitro V15"; }
status_damx() { has_pkg "acer-wmi-battery-dkms-git" && svc_enabled "damx-daemon.service"; }

install_damx() {
    need_aur || { err "AUR helper não encontrado."; return 1; }
    local kfull ksuf headers
    kfull="$(uname -r)"
    ksuf="$(echo "$kfull" | grep -oP '(cachyos-lts|cachyos|zen-lts|zen|lts|hardened|rt)' | head -1)"
    headers="${ksuf:+linux-${ksuf}-headers}"; [[ -z "$headers" ]] && headers="linux-headers"
    
    step "Instalando dependências..."
    sudo pacman -S --needed --noconfirm base-devel "$headers" clang llvm dkms acpi_call-dkms
    
    for kver in $(ls /lib/modules/); do
        local ks kpkg
        ks="$(echo "$kver" | grep -oP '(cachyos-lts|cachyos|zen-lts|zen|lts|hardened|rt)' | head -1)"
        kpkg="${ks:+linux-${ks}-headers}"; [[ -z "$kpkg" ]] && kpkg="linux-headers"
        [[ "$kpkg" != "$headers" ]] && sudo pacman -S --needed --noconfirm "$kpkg" 2>/dev/null || true
    done
    
    step "Instalando pacotes AUR..."
    $AUR -S --needed --noconfirm acer-wmi-battery-dkms-git linuwu-sense-dkms
    
    step "Configurando blacklist..."
    sudo tee /etc/modprobe.d/acer-blacklist.conf > /dev/null <<'EOF'
blacklist acer_wmi
blacklist acer_wmi_battery
EOF
    
    step "Baixando DAMX..."
    local repo="PXDiv/Div-Acer-Manager-Max"
    local vers tarb tmp
    vers="$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)"
    [[ -z "$vers" ]] && err "Versão DAMX não encontrada." && return 1
    tarb="$(curl -fsSL "https://github.com/${repo}/releases/expanded_assets/${vers}" | grep -Pio '(?<=href=")([^"]+\.tar\.xz)' | head -1)"
    [[ -z "$tarb" ]] && err "Tarball não encontrado." && return 1
    tmp="$(mktemp -d /tmp/damx.XXXXXX)"
    curl -fsSL "https://github.com${tarb}" -o- | tar -xJf - -C "${tmp}" --strip-components=1
    if [[ ! -f "${tmp}/setup.sh" ]]; then
        err "setup.sh não encontrado em ${tmp}. Estrutura do tarball inesperada."
        ls "${tmp}" 2>/dev/null
        rm -rf "$tmp"
        return 1
    fi
    # Opção 2 = instala Daemon + GUI sem drivers (DKMS já gerencia linuwu-sense)
    # Os "q" extras satisfazem as chamadas pause() do setup.sh (read -n 1)
    printf '2\n%0.s\n%0.s\n%0.s\n%0.s\n%0.s\nq\n' | sudo bash "${tmp}/setup.sh"
    rm -rf "$tmp"
    
    step "Configurando DKMS..."
    if ! dkms status | grep -q "linuwu"; then
        local src ver nm
        src="$(find /usr/src -maxdepth 1 -name "linuwu*" -type d 2>/dev/null | head -1)"
        if [[ -n "$src" ]]; then
            ver="$(basename "$src" | grep -oP '\d+\.\d+\.\d+')"
            nm="$(basename "$src" | sed "s/-${ver}//")"
            sudo dkms add "$src" 2>/dev/null || true
            sudo dkms install "${nm}/${ver}" -k "$kfull" 2>/dev/null || true
        fi
    fi

    step "Configurando autoload de módulos..."
    sudo tee /etc/modules-load.d/damx.conf > /dev/null <<'EOF'
acpi_call
linuwu_sense
EOF
    ok "modules-load.d/damx.conf criado"

    step "Regenerando initramfs..."
    sudo mkinitcpio -P

    step "Carregando módulos..."
    sudo modprobe -r acer_wmi 2>/dev/null || true
    sudo modprobe acpi_call 2>/dev/null && ok "acpi_call carregado" || warn "acpi_call: aplique no reboot"
    sudo modprobe linuwu_sense 2>/dev/null && ok "linuwu_sense carregado" || warn "linuwu_sense: aplique no reboot"

    step "Habilitando damx-daemon..."
    sudo systemctl daemon-reload
    sudo systemctl enable --now damx-daemon.service 2>/dev/null || warn "damx-daemon.service: disponível após reboot."
    
    log "DAMX instalado!"
    warn "REINICIALIZE para aplicar o blacklist."
}

remove_damx() {
    step "Parando serviço..."
    sudo systemctl stop damx-daemon.service 2>/dev/null || true
    sudo systemctl disable damx-daemon.service 2>/dev/null || true
    
    step "Removendo DKMS..."
    sudo dkms remove --all acer-wmi-battery 2>/dev/null || true
    sudo dkms remove --all linuwu-sense 2>/dev/null || true
    
    step "Removendo pacotes..."
    $AUR -R --noconfirm acer-wmi-battery-dkms-git linuwu-sense-dkms 2>/dev/null || true
    sudo pacman -R --noconfirm acpi_call-dkms 2>/dev/null || true
    
    step "Removendo arquivos DAMX..."
    sudo rm -f /usr/local/bin/damx /usr/local/bin/damx-daemon
    sudo rm -f /usr/lib/systemd/system/damx-daemon.service
    sudo rm -rf /usr/local/share/damx
    sudo systemctl daemon-reload
    
    step "Removendo blacklist e autoload..."
    sudo rm -f /etc/modprobe.d/acer-blacklist.conf
    sudo rm -f /etc/modules-load.d/damx.conf
    
    step "Regenerando initramfs..."
    sudo mkinitcpio -P
    log "DAMX removido. Reinicialize para restaurar o acer_wmi."
}

