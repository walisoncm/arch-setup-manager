#!/usr/bin/env bash
# ollama-manage.sh ACTION [ARG]

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
export SUDO_ASKPASS="$SCRIPT_DIR/askpass.sh"
sudo() {
    if command sudo -n true 2>/dev/null; then
        command sudo "$@"
    else
        command sudo -A "$@"
    fi
}

action="${1:-list}"

esc() {
    local s="$1"
    s="${s//&/&amp;}"; s="${s//</&lt;}"; s="${s//>/&gt;}"
    echo -n "$s"
}

case "$action" in

    list)
        models=$(ollama list 2>/dev/null | tail -n +2)
        if [[ -z "$models" ]]; then
            echo "<div style='color:var(--muted);line-height:1.7;'>Nenhum modelo instalado.<br>Use a aba <strong>⬇ Baixar</strong> para adicionar o primeiro.</div>"
            exit 0
        fi
        echo "<div style='display:flex;flex-direction:column;gap:6px;'>"
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            name=$(echo "$line" | awk '{print $1}')
            size=$(echo "$line" | awk '{print $3, $4}')
            echo "<div class='olm-row'>"
            echo "  <span style='flex:1;font-family:monospace;font-size:13px;'>$(esc "$name") <span style='color:var(--muted);font-size:11px;'>(${size})</span></span>"
            echo "  <button class='olm-del' onclick=\"olmDelete('$(esc "$name")')\">🗑 Remover</button>"
            echo "</div>"
        done <<< "$models"
        echo "</div>"
        ;;

    delete)
        model="$2"
        [[ -z "$model" ]] && { echo "<span style='color:var(--danger);'>Modelo não informado.</span>"; exit 1; }
        if ollama rm "$model" &>/dev/null; then
            echo "<span style='color:#3ddc84;'>✓ <strong>$(esc "$model")</strong> removido.</span>"
        else
            echo "<span style='color:var(--danger);'>Falha ao remover $(esc "$model").</span>"
        fi
        ;;

    service-status)
        systemctl is-active --quiet ollama.service 2>/dev/null && echo "running" || echo "stopped"
        ;;

    service-start)
        sudo systemctl start ollama.service 2>/dev/null
        sleep 1
        systemctl is-active --quiet ollama.service 2>/dev/null && echo "running" || echo "error"
        ;;

    service-stop)
        sudo systemctl stop ollama.service 2>/dev/null
        echo "stopped"
        ;;

    *)
        echo "<span style='color:var(--danger);'>Ação desconhecida: $(esc "$action")</span>"
        ;;
esac
