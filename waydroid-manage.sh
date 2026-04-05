#!/usr/bin/env bash
# waydroid-manage.sh ACTION — executa operações do waydroid e retorna HTML formatado

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

export SUDO_ASKPASS="$SCRIPT_DIR/askpass.sh"
sudo() {
    if command sudo -n true 2>/dev/null; then
        command sudo "$@"
    else
        command sudo -A "$@"
    fi
}

action="${1:-upgrade}"

esc_html() {
    local s="$1"
    s="${s//&/&amp;}"
    s="${s//</&lt;}"
    s="${s//>/&gt;}"
    echo "$s"
}

fmt_line() {
    local s; s="$(esc_html "$1")"
    [[ -z "$s" ]] && { echo ""; return; }
    if   [[ "$s" =~ (Error|erro|[Ff]ailed|[Ff]alha) ]]; then
        echo "<span style='color:#e06c75;'>$s</span>"
    elif [[ "$s" =~ ([Ww]arning|[Aa]viso) ]]; then
        echo "<span style='color:#ffb74d;'>$s</span>"
    elif [[ "$s" =~ (Download|Downloading|[Uu]pdating|[Uu]pgrading|[Vv]ersion) ]]; then
        echo "<span style='color:#82aaff;'>$s</span>"
    elif [[ "$s" =~ (✓|OK|[Ss]uccess|[Dd]one|[Cc]oncluído|[Ff]inish) ]]; then
        echo "<span style='color:#3ddc84;'>$s</span>"
    else
        echo "$s"
    fi
}

case "$action" in
    upgrade)
        echo "<span style='color:var(--muted);font-weight:600;'>↑ Verificando atualização da imagem Android...</span>"
        echo ""
        output="$(sudo waydroid upgrade 2>&1)"
        status=$?
        while IFS= read -r line; do fmt_line "$line"; done <<< "$output"
        echo ""
        if [[ $status -eq 0 ]]; then
            echo "<span style='color:#3ddc84;font-weight:600;'>✓ Concluído. Reinicie o Waydroid para aplicar.</span>"
        else
            echo "<span style='color:#e06c75;font-weight:600;'>✗ Falha na atualização (código $status).</span>"
        fi
        ;;
    stop)
        echo "<span style='color:var(--muted);font-weight:600;'>⏹ Parando Waydroid...</span>"
        echo ""
        waydroid session stop 2>&1 | while IFS= read -r line; do fmt_line "$line"; done
        sudo systemctl stop waydroid-container.service 2>&1 | while IFS= read -r line; do fmt_line "$line"; done
        echo ""
        echo "<span style='color:#3ddc84;font-weight:600;'>✓ Waydroid parado.</span>"
        ;;
    *)
        echo "<span style='color:#e06c75;'>Ação desconhecida: $(esc_html "$action")</span>"
        ;;
esac
