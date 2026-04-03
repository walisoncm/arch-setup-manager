#!/usr/bin/env bash
# askpass.sh — popup gráfico de senha para sudo -A (SUDO_ASKPASS)

# Força o foco da janela para evitar que o usuário clique fora sem querer
zenity \
    --password \
    --title="Arch Setup Manager" \
    --text="🔐 Senha necessária para tarefas administrativas:" \
    --icon-name="dialog-password" \
    2>/dev/null
