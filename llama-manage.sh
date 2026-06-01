#!/usr/bin/env bash
# llama-manage.sh ACTION [ARG]

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
export SUDO_ASKPASS="$SCRIPT_DIR/askpass.sh"

# Diretório padrão para modelos GGUF (Compartilhado com LM Studio)
MODELS_DIR="$HOME/.local/share/models/gguf"
mkdir -p "$MODELS_DIR"

# Garante compatibilidade com LM Studio (symlink se necessário)
LM_STUDIO_DIR="$HOME/.cache/lm-studio/models"
if [[ ! -L "$LM_STUDIO_DIR" && ! -d "$LM_STUDIO_DIR" ]]; then
    mkdir -p "$(dirname "$LM_STUDIO_DIR")"
    ln -s "$MODELS_DIR" "$LM_STUDIO_DIR"
fi

# Arquivo para salvar o modelo "ativo" (usado para iniciar o server)
CONFIG_DIR="$HOME/.config/llama.cpp"
mkdir -p "$CONFIG_DIR"
ACTIVE_MODEL_FILE="$CONFIG_DIR/active_model"

action="${1:-list}"

esc() {
    local s="$1"
    s="${s//&/&amp;}"; s="${s//</&lt;}"; s="${s//>/&gt;}"
    echo -n "$s"
}

case "$action" in

    list)
        # Busca recursiva para suportar estrutura do LM Studio (publisher/model/file.gguf)
        models=$(find "$MODELS_DIR" -name "*.gguf" -printf "%P\n" | sort)
        active_model=$(cat "$ACTIVE_MODEL_FILE" 2>/dev/null)

        if [[ -z "$models" ]]; then
            echo "<div style='color:var(--muted);line-height:1.7;'>Nenhum arquivo .gguf encontrado em:<br><code style='font-size:11px;'>$MODELS_DIR</code></div>"
            exit 0
        fi

        echo "<div style='display:flex;flex-direction:column;gap:6px;'>"
        while IFS= read -r rel_path; do
            [[ -z "$rel_path" ]] && continue
            
            size=$(du -h "$MODELS_DIR/$rel_path" | awk '{print $1}')
            name=$(basename "$rel_path")
            # Para exibição, se estiver em subpasta, mostra o caminho resumido
            display_name="$rel_path"
            
            echo "<div class='olm-row $( [[ "$rel_path" == "$active_model" ]] && echo "selected-model" )' style='padding:10px;'>"
            echo "  <div style='flex:1; cursor:pointer;' onclick=\"llmSetActive('$(esc "$rel_path")')\">"
            echo "    <div style='font-family:monospace;font-size:13px;'>$(esc "$display_name")</div>"
            echo "    <div style='color:var(--muted);font-size:10px;'>Tamanho: ${size}</div>"
            echo "  </div>"
            echo "  <div style='display:flex; gap:6px;'>"
            if [[ "$rel_path" == "$active_model" ]]; then
                echo "    <span style='color:var(--primary); font-size:11px; font-weight:bold; align-self:center; margin-right:8px;'>ATIVO</span>"
            fi
            echo "    <button class='olm-del' onclick=\"llmDelete('$(esc "$rel_path")')\">🗑</button>"
            echo "  </div>"
            echo "</div>"
        done <<< "$models"
        echo "</div>"
        ;;

    set-active)
        model="$2"
        echo "$model" > "$ACTIVE_MODEL_FILE"
        echo "<span style='color:var(--primary);'>✓ Modelo <strong>$(esc "$model")</strong> selecionado.</span>"
        ;;

    get-active)
        cat "$ACTIVE_MODEL_FILE" 2>/dev/null || echo "Nenhum selecionado"
        ;;

    delete)
        model="$2"
        rm -f "$MODELS_DIR/$model"
        [[ "$model" == "$(cat "$ACTIVE_MODEL_FILE" 2>/dev/null)" ]] && rm -f "$ACTIVE_MODEL_FILE"
        echo "<span style='color:#3ddc84;'>✓ Removido.</span>"
        ;;

    service-status)
        if pgrep -x "llama-server" > /dev/null; then
            echo "running"
        else
            echo "stopped"
        fi
        ;;

    service-start)
        model=$(cat "$ACTIVE_MODEL_FILE" 2>/dev/null)
        if [[ -z "$model" || ! -f "$MODELS_DIR/$model" ]]; then
            echo "error_no_model"
            exit 1
        fi
        
        # Inicia o server em background usando nohup para persistir
        # -ngl 99: Força o uso total da GPU
        # --flash-attn on: Otimiza performance e economiza VRAM de contexto
        # --embedding: Necessário para ferramentas como OpenHands
        nohup llama-server -m "$MODELS_DIR/$model" --port 8080 --host 0.0.0.0 --ctx-size 16384 -ngl 99 --flash-attn on --embedding > /tmp/llama-server.log 2>&1 &
        sleep 2
        
        if pgrep -x "llama-server" > /dev/null; then
            echo "running"
        else
            echo "error"
        fi
        ;;

    service-stop)
        pkill -x "llama-server"
        echo "stopped"
        ;;

    autostart-status)
        if systemctl --user is-enabled llama-server.service &>/dev/null; then
            echo "enabled"
        else
            echo "disabled"
        fi
        ;;

    autostart-toggle)
        if systemctl --user is-enabled llama-server.service &>/dev/null; then
            systemctl --user disable llama-server.service &>/dev/null
            echo "disabled"
        else
            # Cria arquivo de serviço se não existir
            SERVICE_FILE="$HOME/.config/systemd/user/llama-server.service"
            mkdir -p "$(dirname "$SERVICE_FILE")"
            cat << EOF > "$SERVICE_FILE"
[Unit]
Description=Llama.cpp Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/bash -c 'ACTIVE_MODEL=\$(cat %h/.config/llama.cpp/active_model 2>/dev/null); [ -z "\$ACTIVE_MODEL" ] && { echo "Nenhum modelo selecionado"; exit 1; }; exec llama-server -m %h/.local/share/models/gguf/\$ACTIVE_MODEL --port 8080 --host 0.0.0.0 --ctx-size 16384 -ngl 99 --flash-attn on --embedding'
Restart=on-failure

[Install]
WantedBy=default.target
EOF
            systemctl --user daemon-reload
            systemctl --user enable llama-server.service &>/dev/null
            echo "enabled"
        fi
        ;;

    *)
        echo "Ação desconhecida: $action"
        ;;
esac
