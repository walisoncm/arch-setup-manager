#!/usr/bin/env bash
APP_ID="g435-pipewire"
APP_NAME="G435 PipeWire Fix (Updated)"
APP_DESC="Corrige perfil, volume baixo e ganho automático do Logitech G435 (WP 0.5+)"

_WP_DIR="$HOME/.config/wireplumber/wireplumber.conf.d"
_G435_CONF="$_WP_DIR/55-g435-restore.conf"

_g435_conf_ok() {
    [[ -f "$_G435_CONF" ]] && grep -q "node.fixed-volume = true" "$_G435_CONF"
}

status_g435_pipewire() { _g435_conf_ok; }

install_g435_pipewire() {
    step "Criando configuração otimizada para o G435 (formato WP 0.5+)..."
    mkdir -p "$_WP_DIR"
    
    # Backup de configurações antigas se existirem
    [[ -f "$_WP_DIR/50-g435-profile.conf" ]] && mv "$_WP_DIR/50-g435-profile.conf" "$_WP_DIR/50-g435-profile.conf.bak"

    cat > "$_G435_CONF" <<EOF
monitor.alsa.rules = [
  {
    matches = [
      {
        node.name = "~alsa_input.usb-Logitech_G_series_G435.*"
      },
      {
        node.name = "~alsa_output.usb-Logitech_G_series_G435.*"
      }
    ]
    actions = {
      update-props = {
        node.description = "Logitech G435 (Otimizado)"
        device.profile = "mono-fallback"
        session.suspend-on-idle = false
        node.fixed-volume = true
        node.passive = true
        audio.channels = 1
        monitor.channel-volumes = false
      }
    }
  }
]
EOF
    ok "Configuração criada em $_G435_CONF"

    step "Limpando cache do WirePlumber..."
    rm -rf "$HOME/.local/state/wireplumber"
    
    step "Reiniciando serviços de áudio..."
    systemctl --user restart pipewire wireplumber pipewire-pulse
    sleep 2
    
    step "Ajustando volume de hardware via ALSA..."
    # Tenta encontrar a placa do G435 para forçar o volume no hardware
    G435_CARD_INDEX=$(aplay -l | grep "G435" | cut -d' ' -f2 | tr -d ':' | head -n 1)
    if [[ -n "$G435_CARD_INDEX" ]]; then
        amixer -c "$G435_CARD_INDEX" sset 'Mic' 100% 2>/dev/null
        ok "Volume de hardware setado para 100% na placa $G435_CARD_INDEX"
    fi

    log "Fix aplicado! O volume agora está travado e o perfil está otimizado para a versão mais recente do sistema."
}

remove_g435_pipewire() {
    step "Removendo configurações do G435..."
    rm -f "$_G435_CONF"
    rm -rf "$HOME/.local/state/wireplumber"
    
    systemctl --user restart pipewire wireplumber
    ok "Configurações removidas e serviços reiniciados."
}
