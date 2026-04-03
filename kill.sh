#!/usr/bin/env bash
# kill.sh APP — interrompe a árvore inteira de processos do run.sh (inclusive sudo)

app="${1:-}"
[[ -z "$app" ]] && exit 1

PID_FILE="/tmp/bbv-pid-${app}"
LOG="/tmp/bbv-action-${app}.log"

# Mata recursivamente todos os descendentes de um PID (filhos, netos, etc.)
# Usa sudo kill para alcançar processos rodando como root (ex: sudo pacman)
kill_tree() {
    local pid=$1
    local children
    children=$(pgrep -P "$pid" 2>/dev/null)
    for child in $children; do
        kill_tree "$child"
    done
    sudo kill -KILL "$pid" 2>/dev/null
    kill      -KILL "$pid" 2>/dev/null
}

if [[ -f "$PID_FILE" ]]; then
    pid=$(cat "$PID_FILE")
    kill_tree "$pid"
    rm -f "$PID_FILE"
fi

echo "___DONE_130___" >> "$LOG"
