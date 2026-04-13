#!/usr/bin/env bash
# goose-manage.sh ACTION [ARGS]

action="${1:-get-config}"
CONF="$HOME/.config/goose/config.yaml"

esc() {
    local s="$1"
    s="${s//&/&amp;}"; s="${s//</&lt;}"; s="${s//>/&gt;}"
    echo -n "$s"
}

get_val() {
    local key="$1"
    [[ -f "$CONF" ]] && grep -m1 "^${key}:" "$CONF" 2>/dev/null \
        | sed "s/^${key}:[[:space:]]*//" | tr -d "\"'"
}

set_val() {
    local key="$1" val="$2"
    mkdir -p "$(dirname "$CONF")"
    local tmp; tmp=$(mktemp)
    if [[ -f "$CONF" ]]; then
        grep -v "^${key}:" "$CONF" > "$tmp"
    fi
    echo "${key}: ${val}" >> "$tmp"
    mv "$tmp" "$CONF"
}

remove_val() {
    local key="$1"
    [[ ! -f "$CONF" ]] && return
    local tmp; tmp=$(mktemp)
    grep -v "^${key}:" "$CONF" > "$tmp"
    mv "$tmp" "$CONF"
}

case "$action" in

    get-config)
        provider=$(get_val "provider")
        model=$(get_val "model")
        if [[ -n "$provider" ]]; then
            printf '<span style="color:var(--muted);">Provider: </span>'
            printf '<span style="font-family:monospace; color:var(--primary);">%s</span>' "$(esc "$provider")"
            if [[ -n "$model" ]]; then
                printf '&nbsp;&nbsp;<span style="color:var(--muted);">Modelo: </span>'
                printf '<span style="font-family:monospace; color:var(--primary);">%s</span>' "$(esc "$model")"
            fi
        else
            echo "<span style='color:var(--muted);'>Nenhuma configuração encontrada — use o modal para configurar</span>"
        fi
        ;;

    set-provider)
        provider="${2:-}"
        model="${3:-}"
        if [[ -z "$provider" || -z "$model" ]]; then
            echo "<span style='color:var(--danger);'>Provider e modelo são obrigatórios.</span>"
            exit 1
        fi
        set_val "provider" "$provider"
        set_val "model" "$model"
        echo "<span style='color:#3ddc84;'>✓ Provider: <code>$(esc "$provider")</code> &nbsp; Modelo: <code>$(esc "$model")</code></span>"
        ;;

    set-key)
        provider="${2:-}"
        key="${3:-}"
        if [[ -z "$provider" || -z "$key" ]]; then
            echo "<span style='color:var(--danger);'>Provider e chave são obrigatórios.</span>"
            exit 1
        fi
        case "$provider" in
            anthropic) key_name="ANTHROPIC_API_KEY" ;;
            openai)    key_name="OPENAI_API_KEY"    ;;
            groq)      key_name="GROQ_API_KEY"      ;;
            google)    key_name="GOOGLE_API_KEY"    ;;
            *)         key_name="${provider^^}_API_KEY" ;;
        esac
        set_val "$key_name" "$key"
        echo "<span style='color:#3ddc84;'>✓ API Key salva para <code>$(esc "$provider")</code></span>"
        ;;

    clear-config)
        if [[ -f "$CONF" ]]; then
            remove_val "provider"
            remove_val "model"
        fi
        echo "<span style='color:var(--muted);'>Configuração de provider/modelo removida.</span>"
        ;;

    list-ollama)
        models=$(ollama list 2>/dev/null | tail -n +2)
        if [[ -z "$models" ]]; then
            echo "<div style='color:var(--muted); font-size:13px;'>Nenhum modelo Ollama instalado.<br>Instale modelos via o gerenciador do Ollama.</div>"
            exit 0
        fi
        current_provider=$(get_val "provider")
        current_model=$(get_val "model")
        echo "<div style='display:flex;flex-direction:column;gap:6px;'>"
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            name=$(echo "$line" | awk '{print $1}')
            size=$(echo "$line" | awk '{print $3, $4}')
            active=""
            [[ "$current_provider" == "ollama" && "$name" == "$current_model" ]] && \
                active="style='border-color:var(--primary);'"
            echo "<div class='gse-row' $active>"
            echo "  <span style='flex:1;font-family:monospace;font-size:13px;'>$(esc "$name") <span style='color:var(--muted);font-size:11px;'>(${size})</span></span>"
            if [[ "$current_provider" == "ollama" && "$name" == "$current_model" ]]; then
                echo "  <span style='font-size:11px; color:var(--primary); padding:3px 8px;'>✓ Ativo</span>"
            else
                echo "  <button class='gse-sel' onclick=\"gseSetProvider('ollama', '$(esc "$name")')\">✓ Usar</button>"
            fi
            echo "</div>"
        done <<< "$models"
        echo "</div>"
        ;;

esac
