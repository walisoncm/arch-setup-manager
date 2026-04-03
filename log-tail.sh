#!/usr/bin/env bash
# log-tail.sh APP OFFSET
# Retorna o conteúdo do log de ação a partir de um offset em bytes.
# Usado pelo JavaScript de action.sh para polling em tempo real.
app="${1:-}"
offset="${2:-0}"
[[ -z "$app" ]] && exit 1
LOG="/tmp/bbv-action-${app}.log"
[[ -f "$LOG" ]] || exit 0
tail -c +"$((offset + 1))" "$LOG" 2>/dev/null
