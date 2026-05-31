#!/usr/bin/env bash
# pi-manage.sh ACTION [ARG]

MODELS_JSON="$HOME/.pi/agent/models.json"
mkdir -p "$(dirname "$MODELS_JSON")"

action="${1:-list}"

case "$action" in
    get-config)
        if [[ ! -f "$MODELS_JSON" ]]; then
            echo "Padrão (Google/Claude)"
            exit 0
        fi
        
        # Tenta identificar o provedor ativo baseado no que está no JSON
        # Esta é uma simplificação, já que o Pi pode ter múltiplos
        if grep -q "localhost:11434" "$MODELS_JSON"; then
            echo "Ollama (Local)"
        elif grep -q "localhost:8080" "$MODELS_JSON"; then
            echo "Llama.cpp (Local)"
        else
            echo "Nuvem / Outro"
        fi
        ;;

    set-ollama)
        model="${2:-llama3}"
        cat << EOF > "$MODELS_JSON"
{
  "providers": {
    "ollama": {
      "baseUrl": "http://localhost:11434/v1",
      "api": "openai-completions",
      "apiKey": "none",
      "models": [
        { "id": "$model" }
      ]
    }
  }
}
EOF
        echo "✓ Pi configurado para usar Ollama ($model)"
        ;;

    set-llama-cpp)
        model="${2:-model}"
        cat << EOF > "$MODELS_JSON"
{
  "providers": {
    "llama-cpp": {
      "baseUrl": "http://localhost:8080/v1",
      "api": "openai-completions",
      "apiKey": "none",
      "models": [
        { "id": "$model" }
      ]
    }
  }
}
EOF
        echo "✓ Pi configurado para usar Llama.cpp ($model)"
        ;;

    clear)
        rm -f "$MODELS_JSON"
        echo "✓ Configurações do Pi resetadas para o padrão."
        ;;
esac
