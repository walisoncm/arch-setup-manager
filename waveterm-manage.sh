#!/usr/bin/env bash
# waveterm-manage.sh ACTION [ARG]

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
export SUDO_ASKPASS="$SCRIPT_DIR/askpass.sh"

WAVEAI_JSON="${WAVEAI_CONFIG:-$HOME/.config/waveterm/waveai.json}"

esc() {
    local s="$1"
    s="${s//&/&amp;}"; s="${s//</&lt;}"; s="${s//>/&gt;}"
    echo -n "$s"
}

model_to_key() {
    # "qwen2.5-coder:7b" -> "ollama-qwen2-5-coder-7b"
    local key="ollama-$1"
    key="${key//:/-}"
    key="${key//./-}"
    echo "$key"
}

ensure_waveai() {
    mkdir -p "$(dirname "$WAVEAI_JSON")"
    [[ -f "$WAVEAI_JSON" ]] || echo '{}' > "$WAVEAI_JSON"
}

action="${1:-list-configs}"

case "$action" in

    list-configs)
        ensure_waveai
        entries=$(jq -r 'to_entries | sort_by(.value["display:order"] // 999) | .[] |
            "\(.key)\t\(.value["display:name"])\t\(.value["ai:model"])"' "$WAVEAI_JSON" 2>/dev/null)

        if [[ -z "$entries" ]]; then
            echo "<div style='color:var(--muted);line-height:1.7;'>Nenhuma IA configurada no WaveTerm.<br>Use a aba <strong>➕ Adicionar</strong> para configurar modelos do Ollama.</div>"
            exit 0
        fi
        echo "<div style='display:flex;flex-direction:column;gap:6px;'>"
        while IFS=$'\t' read -r key name model; do
            [[ -z "$key" ]] && continue
            echo "<div class='wtm-row'>"
            echo "  <div style='flex:1;'>"
            echo "    <span style='font-size:13px;font-weight:600;'>$(esc "$name")</span>"
            echo "    <span style='font-size:11px;color:var(--muted);margin-left:8px;font-family:monospace;'>$(esc "$model")</span>"
            echo "  </div>"
            echo "  <button class='wtm-del' onclick=\"wtmRemoveConfig('$(esc "$key")')\">🗑 Remover</button>"
            echo "</div>"
        done <<< "$entries"
        echo "</div>"
        ;;

    list-models)
        # Lista modelos Ollama ainda não configurados no WaveTerm
        ensure_waveai
        all_models=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}')
        if [[ -z "$all_models" ]]; then
            echo "<div style='color:var(--muted);'>Nenhum modelo Ollama instalado.</div>"
            exit 0
        fi

        configured=$(jq -r '[.[] | .["ai:model"]] | .[]' "$WAVEAI_JSON" 2>/dev/null)

        echo "<div style='display:flex;flex-direction:column;gap:6px;'>"
        while IFS= read -r model; do
            [[ -z "$model" ]] && continue
            is_cfg=false
            while IFS= read -r cm; do
                [[ "$cm" == "$model" ]] && { is_cfg=true; break; }
            done <<< "$configured"

            if $is_cfg; then
                echo "<div class='wtm-row'>"
                echo "  <span style='flex:1;font-family:monospace;font-size:13px;'>$(esc "$model")</span>"
                echo "  <span style='font-size:11px;color:#3ddc84;'>✓ já configurado</span>"
                echo "</div>"
            else
                echo "<div class='wtm-row'>"
                echo "  <span style='flex:1;font-family:monospace;font-size:13px;'>$(esc "$model")</span>"
                echo "  <button class='wtm-add' onclick=\"wtmAddModel('$(esc "$model")')\">➕ Adicionar</button>"
                echo "</div>"
            fi
        done <<< "$all_models"
        echo "</div>"
        ;;

    add)
        model="$2"
        name="${3:-Ollama ($model)}"
        [[ -z "$model" ]] && { echo "<span style='color:var(--danger);'>Modelo não informado.</span>"; exit 1; }
        ensure_waveai

        key=$(model_to_key "$model")

        # Determina próximo display:order
        max_order=$(jq '[.[] | .["display:order"] // 0] | max // 0' "$WAVEAI_JSON" 2>/dev/null)
        next_order=$(( max_order + 1 ))

        tmp=$(mktemp)
        jq --arg key "$key" \
           --arg name "$name" \
           --arg model "$model" \
           --argjson order "$next_order" \
           '.[$key] = {
               "display:name": $name,
               "display:order": $order,
               "ai:apitype": "openai-chat",
               "ai:model": $model,
               "ai:endpoint": "http://127.0.0.1:11434/v1/chat/completions",
               "ai:apitoken": "ollama",
               "ai:capabilities": ["tools"]
           }' "$WAVEAI_JSON" > "$tmp" && mv "$tmp" "$WAVEAI_JSON"

        echo "<span style='color:#3ddc84;'>✓ <strong>$(esc "$name")</strong> adicionado ao WaveTerm.</span>"
        ;;

    remove)
        key="$2"
        [[ -z "$key" ]] && { echo "<span style='color:var(--danger);'>Chave não informada.</span>"; exit 1; }
        ensure_waveai

        tmp=$(mktemp)
        jq --arg key "$key" 'del(.[$key])' "$WAVEAI_JSON" > "$tmp" && mv "$tmp" "$WAVEAI_JSON"
        echo "<span style='color:#3ddc84;'>✓ Configuração removida.</span>"
        ;;

    *)
        echo "<span style='color:var(--danger);'>Ação desconhecida: $(esc "$action")</span>"
        ;;
esac
