#!/usr/bin/env bash
# stdin-relay.sh APP
# Recebe $input via POST (variável de ambiente injetada pelo BBV) e escreve no
# FIFO de stdin do processo de instalação em execução.
app="${1:-}"
FIFO="/tmp/bbv-stdin-${app}.fifo"
[[ -p "$FIFO" ]] || exit 0
printf '%s\n' "${input:-}" > "$FIFO"
