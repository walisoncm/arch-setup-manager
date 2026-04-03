#!/usr/bin/env bash
# fwupd-manage.sh ACTION — executa operações do fwupd e retorna HTML formatado

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

export SUDO_ASKPASS="$SCRIPT_DIR/askpass.sh"
sudo() {
    if command sudo -n true 2>/dev/null; then
        command sudo "$@"
    else
        command sudo -A "$@"
    fi
}

action="${1:-get-updates}"

esc_html() {
    local s="$1"
    s="${s//&/&amp;}"
    s="${s//</&lt;}"
    s="${s//>/&gt;}"
    echo "$s"
}

fmt_line() {
    local raw="$1"
    local s; s="$(esc_html "$raw")"
    if   [[ "$s" =~ ^[[:space:]]*$ ]]; then
        echo ""
    elif [[ "$s" =~ (Error|erro|failed|Failed) ]]; then
        echo "<span style='color:#e06c75;'>$s</span>"
    elif [[ "$s" =~ (Warning|aviso) ]]; then
        echo "<span style='color:#ffb74d;'>$s</span>"
    elif [[ "$s" =~ (Version|Versão|Update|Upgrade|upgrade|update|Device|Summary|Release) ]]; then
        echo "<span style='color:#82aaff;'>$s</span>"
    elif [[ "$s" =~ (✓|OK|Success|sucesso|done|Done) ]]; then
        echo "<span style='color:#3ddc84;'>$s</span>"
    elif [[ "$s" =~ ^[[:space:]]*- ]]; then
        echo "<span style='color:#c4c4dc;'>$s</span>"
    else
        echo "$s"
    fi
}

run_and_format() {
    local output
    output="$("$@" 2>&1)"
    local status=$?
    while IFS= read -r line; do
        fmt_line "$line"
    done <<< "$output"
    return $status
}

case "$action" in
    refresh)
        echo "<span style='color:var(--muted);font-weight:600;'>↻ Atualizando metadados do fwupd...</span>"
        echo ""
        run_and_format fwupdmgr refresh --force
        echo ""
        echo "<span style='color:#3ddc84;'>Metadados atualizados.</span>"
        ;;

    get-updates)
        echo "<span style='color:var(--muted);font-weight:600;'>🔍 Verificando atualizações de firmware...</span>"
        echo ""
        output="$(fwupdmgr get-updates 2>&1)"
        status=$?

        while IFS= read -r line; do
            fmt_line "$line"
        done <<< "$output"

        echo ""
        if echo "$output" | grep -qiE "DeviceId|Version \(newer\)|update-available"; then
            echo "<span style='color:#3ddc84;font-weight:600;' data-has-updates='true'>✓ Atualizações disponíveis. Clique em \"Instalar atualizações\".</span>"
        elif [[ $status -ne 0 ]] || echo "$output" | grep -qiE "No upgrades|nothing to do|no devices"; then
            echo "<span style='color:#ffb74d;'>Nenhuma atualização disponível.</span>"
        fi
        ;;

    update)
        echo "<span style='color:var(--muted);font-weight:600;'>⬇ Instalando atualizações de firmware...</span>"
        echo "<span style='color:#ffb74d;'>⚠ O sistema pode reiniciar durante o processo.</span>"
        echo ""
        run_and_format sudo fwupdmgr update --assume-yes
        echo ""
        echo "<span style='color:#3ddc84;font-weight:600;'>Processo concluído.</span>"
        ;;

    *)
        echo "<span style='color:#e06c75;'>Ação desconhecida: $(esc_html "$action")</span>"
        ;;
esac
