#!/usr/bin/env bash
# openclaude-manage.sh ACTION [ARGS...]
# Gerencia configuração de provider do Open Claude.
# Config salva em ~/.config/fish/conf.d/openclaude.fish

CONF_FILE="$HOME/.config/fish/conf.d/openclaude.fish"

esc() {
    local s="$1"
    s="${s//&/&amp;}"; s="${s//</&lt;}"; s="${s//>/&gt;}"
    echo -n "$s"
}

action="${1:-get-config}"

case "$action" in

    get-config)
        base_url=""; model=""; api_key=""
        if [[ -f "$CONF_FILE" ]]; then
            base_url=$(grep -oP 'OPENAI_BASE_URL \K\S+' "$CONF_FILE" 2>/dev/null || true)
            model=$(grep -oP 'OPENAI_MODEL \K\S+' "$CONF_FILE" 2>/dev/null || true)
            api_key=$(grep -oP 'OPENAI_API_KEY \K\S+' "$CONF_FILE" 2>/dev/null || true)
        fi

        if [[ -n "$base_url" && "$base_url" == *"11434"* ]]; then
            provider="ollama"
        elif [[ -n "$api_key" || -n "$base_url" ]]; then
            provider="openai"
        else
            provider="none"
        fi

        echo "provider=$provider"
        echo "base_url=$base_url"
        echo "model=$model"
        # Mascara a key: mostra apenas os primeiros 8 chars
        if [[ -n "$api_key" ]]; then
            echo "api_key=${api_key:0:8}..."
        else
            echo "api_key="
        fi
        ;;

    list-ollama-models)
        models=$(curl -sf http://localhost:11434/api/tags 2>/dev/null \
            | grep -oP '"name"\s*:\s*"\K[^"]+' 2>/dev/null || true)
        if [[ -z "$models" ]]; then
            echo "[]"
        else
            echo -n "["
            first=true
            while IFS= read -r m; do
                [[ -z "$m" ]] && continue
                $first || echo -n ","
                first=false
                echo -n "\"$(esc "$m")\""
            done <<< "$models"
            echo "]"
        fi
        ;;

    set-ollama)
        base_url="${2:-http://localhost:11434/v1}"
        model="$3"
        [[ -z "$model" ]] && {
            echo "<span style='color:var(--danger);'>Modelo não informado.</span>"
            exit 1
        }
        mkdir -p "$(dirname "$CONF_FILE")"
        cat > "$CONF_FILE" << EOF
# OpenClaude provider config (managed by arch-setup-manager)
set -x CLAUDE_CODE_USE_OPENAI 1
set -x OPENAI_BASE_URL $base_url
set -x OPENAI_MODEL $model
EOF
        echo "<span style='color:#3ddc84;'>✓ Provider <strong>Ollama</strong> configurado com modelo <strong>$(esc "$model")</strong>.<br><span style='color:var(--muted);font-size:11px;'>Reabra o terminal para que as variáveis sejam carregadas.</span></span>"
        ;;

    set-openai)
        api_key="$2"
        model="${3:-gpt-4o}"
        base_url="$4"
        [[ -z "$api_key" ]] && {
            echo "<span style='color:var(--danger);'>API Key não informada.</span>"
            exit 1
        }
        mkdir -p "$(dirname "$CONF_FILE")"
        {
            echo "# OpenClaude provider config (managed by arch-setup-manager)"
            echo "set -x CLAUDE_CODE_USE_OPENAI 1"
            echo "set -x OPENAI_API_KEY $api_key"
            echo "set -x OPENAI_MODEL $model"
            [[ -n "$base_url" ]] && echo "set -x OPENAI_BASE_URL $base_url"
        } > "$CONF_FILE"
        echo "<span style='color:#3ddc84;'>✓ Provider <strong>OpenAI</strong> configurado com modelo <strong>$(esc "$model")</strong>.<br><span style='color:var(--muted);font-size:11px;'>Reabra o terminal para que as variáveis sejam carregadas.</span></span>"
        ;;

    remove-config)
        rm -f "$CONF_FILE"
        echo "<span style='color:#3ddc84;'>✓ Configuração removida.</span>"
        ;;

    *)
        echo "<span style='color:var(--danger);'>Ação desconhecida: $(esc "$action")</span>"
        ;;
esac
