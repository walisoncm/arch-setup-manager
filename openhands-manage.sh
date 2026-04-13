#!/usr/bin/env bash
# openhands-manage.sh ACTION [ARGS]
#
# Configuração salva em ~/.openhands-state/.openhands/settings.json
# (montado como /.openhands no container — onde o OpenHands persiste as configurações)

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

export SUDO_ASKPASS="$SCRIPT_DIR/askpass.sh"
_docker() {
    if id -nG "$USER" | grep -qw docker; then
        docker "$@"
    elif command sudo -n true 2>/dev/null; then
        command sudo docker "$@"
    else
        command sudo -A docker "$@"
    fi
}

OH_IMAGE="ghcr.io/all-hands-ai/openhands:latest"
OH_RUNTIME="nikolaik/python-nodejs:python3.12-nodejs22"
OH_CONTAINER="openhands-app"
OH_STATE="$HOME/.openhands-state"
OH_SETTINGS="$OH_STATE/.openhands/settings.json"

action="${1:-get-config}"

esc() {
    local s="$1"
    s="${s//&/&amp;}"; s="${s//</&lt;}"; s="${s//>/&gt;}"
    echo -n "$s"
}

# ── helpers de settings.json ─────────────────────────────────────────────────

settings_get() {
    # Lê um campo do settings.json via python3
    [[ -f "$OH_SETTINGS" ]] || return
    python3 -c "
import json, sys
try:
    d = json.load(open('$OH_SETTINGS'))
    v = d.get(sys.argv[1])
    if v: print(v)
except: pass
" "$1" 2>/dev/null
}

settings_update() {
    # Atualiza campos no settings.json via python3; cria o arquivo se não existir
    # Args: key=value key=value ...
    mkdir -p "$(dirname "$OH_SETTINGS")"
    python3 - "$@" << 'PYEOF'
import json, sys, os

path = os.environ.get('OH_SETTINGS', '')
if not path:
    import pathlib
    path = str(pathlib.Path.home() / '.openhands-state/.openhands/settings.json')

try:
    with open(path) as f:
        data = json.load(f)
except Exception:
    data = {}

for arg in sys.argv[1:]:
    key, _, val = arg.partition('=')
    if val == '__null__':
        data[key] = None
    else:
        data[key] = val

os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
PYEOF
}

# ── gerenciamento do container ───────────────────────────────────────────────

_container_running() {
    _docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${OH_CONTAINER}$"
}

_recreate_container() {
    _docker stop "$OH_CONTAINER" 2>/dev/null || true
    _docker rm   "$OH_CONTAINER" 2>/dev/null || true
    mkdir -p "$OH_STATE/.openhands"
    _docker run -d \
        --name "$OH_CONTAINER" \
        --restart always \
        -e SANDBOX_RUNTIME_CONTAINER_IMAGE="$OH_RUNTIME" \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$OH_STATE:/.openhands-state" \
        -v "$OH_STATE/.openhands:/.openhands" \
        -p 13000:3000 \
        --add-host host.docker.internal:host-gateway \
        "$OH_IMAGE" 2>/dev/null
}

# ── ações ────────────────────────────────────────────────────────────────────

case "$action" in

    service-status)
        _container_running && echo "running" || echo "stopped"
        ;;

    service-start)
        _recreate_container
        sleep 2
        _container_running && echo "running" || echo "error"
        ;;

    service-stop)
        _docker stop "$OH_CONTAINER" 2>/dev/null
        echo "stopped"
        ;;

    get-config)
        model=$(settings_get "llm_model")
        if [[ -n "$model" ]]; then
            echo "<span style='font-family:monospace; color:var(--primary);'>$(esc "$model")</span>"
        else
            echo "<span style='color:var(--muted);'>Nenhum LLM configurado — selecione um provider abaixo</span>"
        fi
        ;;

    set-llm)
        # set-llm PROVIDER MODEL
        provider="${2:-}"
        model="${3:-}"
        if [[ -z "$model" ]]; then
            echo "<span style='color:var(--danger);'>Modelo não informado.</span>"
            exit 1
        fi

        if [[ "$provider" == "ollama" ]]; then
            OH_SETTINGS="$OH_SETTINGS" settings_update \
                "llm_model=$model" \
                "llm_base_url=http://host.docker.internal:11434" \
                "llm_api_key=ollama"
        else
            OH_SETTINGS="$OH_SETTINGS" settings_update \
                "llm_model=$model" \
                "llm_base_url=__null__"
        fi

        echo "<span style='color:#3ddc84;'>✓ LLM: <code>$(esc "$model")</code> &nbsp; Recarregue o OpenHands para aplicar.</span>"
        ;;

    set-key)
        # set-key KEY_ENV_NAME VALUE
        # Mapeamento: ANTHROPIC_API_KEY → llm_api_key, etc.
        key_name="${2:-}"
        key_val="${3:-}"
        if [[ -z "$key_name" || -z "$key_val" ]]; then
            echo "<span style='color:var(--danger);'>Parâmetros incompletos.</span>"
            exit 1
        fi
        OH_SETTINGS="$OH_SETTINGS" settings_update "llm_api_key=$key_val"
        echo "<span style='color:#3ddc84;'>✓ API Key salva. Recarregue o OpenHands para aplicar.</span>"
        ;;

    list-ollama)
        models=$(ollama list 2>/dev/null | tail -n +2)
        if [[ -z "$models" ]]; then
            echo "<div style='color:var(--muted); font-size:13px;'>Nenhum modelo Ollama instalado.<br>Instale modelos via o gerenciador do Ollama.</div>"
            exit 0
        fi
        current_model=$(settings_get "llm_model")
        echo "<div style='display:flex;flex-direction:column;gap:6px;'>"
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            name=$(echo "$line" | awk '{print $1}')
            size=$(echo "$line" | awk '{print $3, $4}')
            oh_model="ollama/$name"
            active=""
            [[ "$oh_model" == "$current_model" ]] && active="style='border-color:var(--primary);'"
            echo "<div class='ohd-row' $active>"
            echo "  <span style='flex:1;font-family:monospace;font-size:13px;'>$(esc "$name") <span style='color:var(--muted);font-size:11px;'>(${size})</span></span>"
            if [[ "$oh_model" == "$current_model" ]]; then
                echo "  <span style='font-size:11px; color:var(--primary); padding:3px 8px;'>✓ Ativo</span>"
            else
                echo "  <button class='ohd-sel' onclick=\"ohdSetLLM('ollama', '$(esc "$oh_model")')\">✓ Usar</button>"
            fi
            echo "</div>"
        done <<< "$models"
        echo "</div>"
        ;;

    *)
        echo "<span style='color:var(--danger);'>Ação desconhecida: $(esc "$action")</span>"
        ;;
esac
