#!/usr/bin/env bash
# run.sh — Executa install/remove e grava log em tempo real para polling

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/common.sh"

# ── SUDO ─────────────────────────────────────────────────────────────────────
export SUDO_ASKPASS="$SCRIPT_DIR/askpass.sh"
sudo() {
    if command sudo -n true 2>/dev/null; then
        command sudo "$@"
    else
        command sudo -A "$@"
    fi
}
source "$SCRIPT_DIR/backend.sh"

action="${1:-install}"
app="${2:-}"

# ── LOG E FIFO DE STDIN ───────────────────────────────────────────────────────
LOG="/tmp/bbv-action-${app}.log"
STDIN_FIFO="/tmp/bbv-stdin-${app}.fifo"
PID_FILE="/tmp/bbv-pid-${app}"
> "$LOG"
echo $$ > "$PID_FILE"
rm -f "$STDIN_FIFO"
mkfifo "$STDIN_FIFO"

# ── CABEÇALHO HTML (para o BBV; o terminal usa polling do log) ───────────────
echo "<html><head><style>
    body { background:#181818; color:#dcdcdc; font-family:monospace; font-size:12px; margin:10px; overflow-x:hidden; }
    pre  { white-space:pre-wrap; word-wrap:break-word; margin:0; padding-bottom:50px; }
    .step,.t-step { color:#5fb3b3; font-weight:bold; display:block; margin-top:10px; }
    .ok,.t-ok     { color:#99c794; }
    .err,.t-err   { color:#ec5f67; }
    .t-warn       { color:#ffb74d; }
</style></head><body><pre id='console'>"

# ── VALIDAÇÃO DO SUDO ────────────────────────────────────────────────────────
echo "<span class='step'>──▸ Verificando privilégios de administrador...</span>" | tee -a "$LOG"
if ! sudo -v; then
    echo "<span class='err'>[✗] Erro: Senha incorreta ou cancelada.</span>" | tee -a "$LOG"
    echo "___DONE_1___" >> "$LOG"
    echo "</pre></body></html>"
    exit 1
fi
echo "<span class='ok'>[+] Autorizado. Iniciando processo...</span>" | tee -a "$LOG"

# Mantém sudo vivo em background
( while true; do sudo -n true; sleep 40; done ) &
KEEP_SUDO_ALIVE_PID=$!
trap "kill $KEEP_SUDO_ALIVE_PID 2>/dev/null; rm -f '$STDIN_FIFO' '$PID_FILE'" EXIT

# ── EXECUÇÃO ─────────────────────────────────────────────────────────────────
if [[ -n "$app" ]]; then
    export PYTHONUNBUFFERED=1
    # Stdin do processo via FIFO (read+write — não bloqueia na abertura nem causa EOF)
    # format_output converte ANSI→HTML; tee grava no log em tempo real
    stdbuf -oL -eL bash -c "source '$SCRIPT_DIR/backend.sh'; ${action}_app '$app'" \
        <>"$STDIN_FIFO" 2>&1 \
        | format_output \
        | tee -a "$LOG"
    exit_code="${PIPESTATUS[0]}"
else
    exit_code=1
fi

# Marcador de conclusão para o JavaScript parar o polling
echo "___DONE_${exit_code}___" >> "$LOG"

# ── RODAPÉ HTML ──────────────────────────────────────────────────────────────
echo "</pre>"
if [[ $exit_code -eq 0 ]]; then
    echo "<div class='ok' style='font-weight:bold;'>✓ Operação finalizada com sucesso!</div>"
else
    echo "<div class='err' style='font-weight:bold;'>✗ O processo falhou (Erro: $exit_code)</div>"
fi
echo "</body></html>"
