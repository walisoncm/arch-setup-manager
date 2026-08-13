#!/usr/bin/env bash
APP_ID="restore-backup"
APP_NAME="Restaurar backup de migração"
APP_DESC="Restaura dotfiles, configs, pacotes, flatpaks e systemd units a partir de um backup gerado por biglinux-migration/backup.sh"

RESTORE_MARKER="$HOME/.biglinux-migration-restored"

# Pacotes cujo nome sugere a mesma função de uma ferramenta que o BigLinux já
# traz pronta (gerenciador de driver, boas-vindas, snapshot, loja de apps,
# AUR helper). Só entram na lista de revisão manual quando NÃO existe um app
# cadastrado no ASM com esse nome exato (ou seja, quando não temos como saber
# se é seguro instalar).
MIGRATION_REVIEW_KEYWORDS='driver-manager|network-info|hello|welcome|octopi|timeshift|snapper|btrfs-assist|bigger|^big-|store|boot-repair|kernel-manager|mirrorlist|rate-mirrors|packageinstaller|conclusion|calamares|plymouth'

status_restore_backup() { [[ -f "$RESTORE_MARKER" ]]; }

_migration_find_backup() {
    find "$HOME/biglinux-migration" /run/media /media -maxdepth 3 \
        -iname 'backup-*.tar.zst' -printf '%T@ %p\n' 2>/dev/null \
        | sort -rn | head -n1 | cut -d' ' -f2-
}

# Instala um pacote da lista de backup, delegando pro installer especializado
# do ASM quando existe (ex.: ollama, noctalia, aider), senão instala genérico.
# Pacotes com cara de "equivalente nativo do BigLinux" e sem app cadastrado
# no ASM só vão para a lista de revisão manual.
_migration_install_pkg() {
    local pkg="$1" review_file="$2" normalize_id="${1//[.-]/_}"

    has_pkg "$pkg" && return 0

    if declare -f "install_$normalize_id" > /dev/null; then
        install_app "$pkg"
        return
    fi

    if echo "$pkg" | grep -qEi "$MIGRATION_REVIEW_KEYWORDS"; then
        echo "$pkg" >> "$review_file"
        return
    fi

    install_app "$pkg"
}

install_restore_backup() {
    step "Procurando backup de migração..."
    local tarball; tarball="$(_migration_find_backup)"
    if [[ -z "$tarball" ]]; then
        err "Nenhum backup-*.tar.zst encontrado em ~/biglinux-migration/ nem em mídia removível montada."
        return 1
    fi
    log "Backup encontrado: $tarball"

    local workdir="$HOME/biglinux-migration"
    mkdir -p "$workdir"
    local bkname; bkname="$(tar -I zstd -tf "$tarball" 2>/dev/null | head -1 | sed 's#/$##')"
    local bkpath="$workdir/$bkname"

    if [[ -d "$bkpath" ]]; then
        log "Já extraído em $bkpath, reaproveitando."
    else
        step "Extraindo backup..."
        tar -I zstd -xf "$tarball" -C "$workdir"
    fi

    if [[ ! -d "$bkpath" ]]; then
        err "Falha ao extrair o backup para $bkpath."
        return 1
    fi

    step "Pacotes nativos + AUR (via ASM, com fallback para install genérico)"
    local review_native="$bkpath/possible-duplicates-pkglist-native.txt"
    local review_aur="$bkpath/possible-duplicates-pkglist-aur.txt"
    : > "$review_native"; : > "$review_aur"
    local pkg
    if [[ -f "$bkpath/lists/pkglist-native.txt" ]]; then
        while IFS= read -r pkg; do
            [[ -z "$pkg" ]] && continue
            _migration_install_pkg "$pkg" "$review_native"
        done < "$bkpath/lists/pkglist-native.txt"
    fi
    if [[ -f "$bkpath/lists/pkglist-aur.txt" ]]; then
        while IFS= read -r pkg; do
            [[ -z "$pkg" ]] && continue
            _migration_install_pkg "$pkg" "$review_aur"
        done < "$bkpath/lists/pkglist-aur.txt"
    fi
    [[ -s "$review_native" || -s "$review_aur" ]] && \
        warn "Alguns pacotes ficaram de fora (nome sugere equivalente nativo do BigLinux, sem app correspondente no ASM). Veja $bkpath/possible-duplicates-*.txt"

    step "Flatpaks"
    if [[ -f "$bkpath/lists/flatpak-list.txt" ]]; then
        while IFS= read -r pkg; do
            [[ -z "$pkg" ]] && continue
            has_fpk "$pkg" && continue
            install_app "$pkg"
        done < "$bkpath/lists/flatpak-list.txt"
    fi

    step "npm globais"
    if has_cmd npm && [[ -f "$bkpath/lists/npm-global.txt" ]]; then
        sed -E 's/@[^@]+$//' "$bkpath/lists/npm-global.txt" | xargs -r npm install -g
    fi

    step "uv tools"
    if has_cmd uv && [[ -f "$bkpath/lists/uv-tools.txt" ]]; then
        xargs -r -n1 uv tool install < "$bkpath/lists/uv-tools.txt"
    fi

    step "Extensões VS Code"
    if has_cmd code && [[ -f "$bkpath/lists/vscode-extensions.txt" ]]; then
        xargs -r -n1 code --install-extension < "$bkpath/lists/vscode-extensions.txt"
    fi

    step "Dotfiles (backup do que já existir com sufixo .pre-migration)"
    for f in "$bkpath"/dotfiles/*; do
        [[ -e "$f" ]] || continue
        local name; name="$(basename "$f")"
        [[ -e "$HOME/$name" ]] && mv "$HOME/$name" "$HOME/$name.pre-migration"
        cp "$f" "$HOME/$name"
    done
    ok "Dotfiles restaurados."

    step "Configs (~/.config)"
    mkdir -p "$HOME/.config"
    rsync -a "$bkpath/config/" "$HOME/.config/"
    ok "Configs restauradas."

    if [[ -d "$bkpath/local-share/.hermes" ]]; then
        step ".hermes"
        rsync -a "$bkpath/local-share/.hermes/" "$HOME/.hermes/"
    fi

    step "Scripts pessoais (~/.local/bin)"
    mkdir -p "$HOME/.local/bin"
    cp -n "$bkpath/local-share/bin/"* "$HOME/.local/bin/" 2>/dev/null || true
    [[ -f "$bkpath/local-share/bin-listing.txt" ]] && \
        log "Veja $bkpath/local-share/bin-listing.txt para reinstalar/redownloadar binários grandes."

    if [[ -d "$bkpath/systemd/user" ]]; then
        step "systemd --user"
        mkdir -p "$HOME/.config/systemd/user"
        cp -r "$bkpath/systemd/user/"* "$HOME/.config/systemd/user/"
        systemctl --user daemon-reload
        warn "Unidades copiadas, NÃO habilitadas automaticamente — revise EXCLUDED.md ($bkpath) antes de habilitar."
    fi

    if has_cmd zsh && [[ "$SHELL" != "$(command -v zsh)" ]]; then
        step "Shell padrão"
        chsh -s "$(command -v zsh)"
        ok "Shell padrão trocado para zsh."
    fi

    touch "$RESTORE_MARKER"
    ok "Restauração concluída."
    log "Passos manuais que faltam: login gh/gcloud/Steam, mods do Discord, revisar EXCLUDED.md em $bkpath."
}
