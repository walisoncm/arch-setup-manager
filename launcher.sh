#!/usr/bin/env bash
# =============================================================================
#  Arch Setup Manager — launcher
#  Gerenciador gráfico de apps e configurações para CachyOS / Arch Linux
#  Acer Nitro V15 (ANV15-41)
# =============================================================================
[[ "$EUID" -eq 0 ]] && echo "Não execute como root." && exit 1

APP_DIR="."

if [[ ! -d "$APP_DIR" ]]; then
    echo "Erro: diretório do app não encontrado em $APP_DIR"
    exit 1
fi

if ! command -v bigbashview &>/dev/null; then
    echo "Erro: bigbashview não está instalado."
    echo "Instale com: paru -S bigbashview-git"
    exit 1
fi

export PYTHONPATH=/usr/lib

exec bigbashview \
    --directory "$APP_DIR" \
    --name "Arch Setup Manager" \
    --icon "$APP_DIR/icon.svg" \
    --size 980x720 \
    --gpu

