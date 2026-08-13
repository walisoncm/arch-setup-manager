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
OH_RUNTIME="ghcr.io/all-hands-ai/runtime:0.28-nikolaik-python-nodejs-python3.12-nodejs22"
OH_CONTAINER="openhands-app"
OH_STATE="$HOME/.openhands-state"
OH_SETTINGS="$OH_STATE/settings.json"

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
    # Tenta buscar dentro de um objeto 'llm' se existir (versões novas)
    if v is None and 'llm' in d and isinstance(d['llm'], dict):
        v = d['llm'].get(sys.argv[1])
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
    path = str(pathlib.Path.home() / '.openhands-state/settings.json')

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
    mkdir -p "$OH_STATE"
    _docker run -d \
        --name "$OH_CONTAINER" \
        --restart always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$OH_STATE:/.openhands" \
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
        _recreate_container >/dev/null 2>&1
        sleep 5
        if _container_running; then
            # Apply security_risk patch for local models (Gemma, etc)
            _docker exec "$OH_CONTAINER" bash -c "sed -i \"s/, 'security_risk'//g\" /app/openhands/agenthub/codeact_agent/tools/*.py && sed -i \"s/'security_risk', //g\" /app/openhands/agenthub/codeact_agent/tools/*.py" >/dev/null 2>&1
            _docker exec "$OH_CONTAINER" bash -c "echo '' > /app/openhands/agenthub/codeact_agent/prompts/security_risk_assessment.j2" >/dev/null 2>&1
            _docker restart "$OH_CONTAINER" >/dev/null 2>&1
            sleep 2
        fi
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
                "llm_base_url=http://172.17.0.1:11434" \
                "llm_api_key=ollama"
        elif [[ "$provider" == "llama-cpp" ]]; then
            OH_SETTINGS="$OH_SETTINGS" settings_update \
                "llm_model=$model" \
                "llm_base_url=http://172.17.0.1:8080/v1" \
                "llm_api_key=llama.cpp"
        else
            OH_SETTINGS="$OH_SETTINGS" settings_update \
                "llm_model=$model" \
                "llm_base_url=__null__"
        fi

        echo "<span style='color:#3ddc84;'>✓ LLM: <code>$(esc "$model")</code> &nbsp; Recarregue o OpenHands para aplicar.</span>"
        ;;

    list-llama)
        # Lista modelos da pasta compartilhada
        MODELS_DIR="$HOME/.local/share/models/gguf"
        models=$(find "$MODELS_DIR" -name "*.gguf" -printf "%P\n" | sort)
        if [[ -z "$models" ]]; then
            echo "<div style='color:var(--muted); font-size:13px;'>Nenhum modelo GGUF encontrado em:<br><code style='font-size:11px;'>$MODELS_DIR</code></div>"
            exit 0
        fi
        current_model=$(settings_get "llm_model")
        echo "<div style='display:flex;flex-direction:column;gap:6px;'>"
        while IFS= read -r rel_path; do
            [[ -z "$rel_path" ]] && continue
            name=$(basename "$rel_path")
            oh_model="openai/$rel_path"
            active=""
            [[ "$oh_model" == "$current_model" ]] && active="style='border-color:var(--primary);'"
            
            size=$(du -h "$MODELS_DIR/$rel_path" | awk '{print $1}')

            echo "<div class='ohd-row' $active>"
            echo "  <span style='flex:1;font-family:monospace;font-size:13px;'>$(esc "$rel_path") <span style='color:var(--muted);font-size:11px;'>(${size})</span></span>"
            if [[ "$oh_model" == "$current_model" ]]; then
                echo "  <span style='font-size:11px; color:var(--primary); padding:3px 8px;'>✓ Ativo</span>"
            else
                echo "  <button class='ohd-sel' onclick=\"ohdSetLLM('llama-cpp', '$(esc "$oh_model")')\">✓ Usar</button>"
            fi
            echo "</div>"
        done <<< "$models"
        echo "</div>"
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
