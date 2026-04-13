#!/usr/bin/env bash
# aider-manage.sh ACTION [ARG]

action="${1:-get-config}"
CONF="$HOME/.aider.conf.yml"

esc() {
    local s="$1"
    s="${s//&/&amp;}"; s="${s//</&lt;}"; s="${s//>/&gt;}"
    echo -n "$s"
}

get_current_model() {
    if [[ -f "$CONF" ]]; then
        grep -m1 '^model:' "$CONF" 2>/dev/null | sed 's/^model:[[:space:]]*//' | tr -d "\"'"
    fi
}

case "$action" in

    get-config)
        model=$(get_current_model)
        if [[ -n "$model" ]]; then
            echo "<span style='font-family:monospace; color:var(--primary);'>$(esc "$model")</span>"
        else
            echo "<span style='color:var(--muted);'>Nenhum modelo configurado (usa padrão do aider)</span>"
        fi
        ;;

    list-ollama)
        models=$(ollama list 2>/dev/null | tail -n +2)
        if [[ -z "$models" ]]; then
            echo "<div style='color:var(--muted); font-size:13px;'>Nenhum modelo Ollama instalado.<br>Instale modelos via o gerenciador do Ollama.</div>"
            exit 0
        fi
        current=$(get_current_model)
        echo "<div style='display:flex;flex-direction:column;gap:6px;'>"
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            name=$(echo "$line" | awk '{print $1}')
            size=$(echo "$line" | awk '{print $3, $4}')
            aider_model="ollama/$name"
            active=""
            [[ "$aider_model" == "$current" ]] && active="style='border-color:var(--primary);'"
            echo "<div class='adr-row' $active>"
            echo "  <span style='flex:1;font-family:monospace;font-size:13px;'>$(esc "$name") <span style='color:var(--muted);font-size:11px;'>(${size})</span></span>"
            if [[ "$aider_model" == "$current" ]]; then
                echo "  <span style='font-size:11px; color:var(--primary); padding:3px 8px;'>✓ Ativo</span>"
            else
                echo "  <button class='adr-sel' onclick=\"adrSetModel('$(esc "$aider_model")')\">✓ Usar</button>"
            fi
            echo "</div>"
        done <<< "$models"
        echo "</div>"
        ;;

    set-model)
        model="${2:-}"
        if [[ -z "$model" ]]; then
            echo "<span style='color:var(--danger);'>Nenhum modelo informado.</span>"
            exit 1
        fi
        tmp=$(mktemp)
        if [[ -f "$CONF" ]]; then
            # Remove model, ollama-api-base (inválido) e bloco set-env anterior
            awk '
                /^model:/ { next }
                /^ollama-api-base:/ { next }
                /^set-env:/ { skip=1; next }
                skip && /^[- ]/ { next }
                { skip=0; print }
            ' "$CONF" > "$tmp"
        fi
        echo "model: $model" >> "$tmp"
        # Ollama precisa de OLLAMA_API_BASE; usa set-env (suportado pelo aider)
        if [[ "$model" == ollama/* ]]; then
            printf 'set-env:\n- OLLAMA_API_BASE=http://localhost:11434\n' >> "$tmp"
        fi
        mv "$tmp" "$CONF"
        echo "<span style='color:#3ddc84;'>✓ Modelo definido: <code>$(esc "$model")</code></span>"
        ;;

    clear-model)
        if [[ -f "$CONF" ]]; then
            tmp=$(mktemp)
            awk '
                /^model:/ { next }
                /^ollama-api-base:/ { next }
                /^set-env:/ { skip=1; next }
                skip && /^[- ]/ { next }
                { skip=0; print }
            ' "$CONF" > "$tmp"
            mv "$tmp" "$CONF"
        fi
        echo "<span style='color:var(--muted);'>Modelo removido. Aider usará o padrão.</span>"
        ;;

esac
