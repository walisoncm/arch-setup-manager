#!/usr/bin/env bash
# launch.sh URL — abre a URL no navegador padrão do sistema
url="${1:-}"
[[ -z "$url" ]] && exit 1
xdg-open "$url" &>/dev/null &
