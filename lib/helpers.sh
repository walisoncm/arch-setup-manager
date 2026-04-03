#!/usr/bin/env bash
# lib/helpers.sh

AUR=""
for _h in paru yay; do command -v "$_h" &>/dev/null && AUR="$_h" && break; done

has_pkg()     { pacman -Qi "$1" &>/dev/null 2>&1; }
has_fpk()     { flatpak info "$1" &>/dev/null 2>&1; }
has_cmd()     { command -v "$1" &>/dev/null; }
svc_enabled() { systemctl is-enabled "$1" &>/dev/null 2>&1; }
in_group()    { id -nG "$USER" | grep -qw "$1"; }
need_aur()    { [[ -n "$AUR" ]]; }

pacman_unlock() {
  local lock="/var/lib/pacman/db.lck"
  if [[ -f "$lock" ]] && ! pgrep -x pacman &>/dev/null; then
    warn "Lock stale encontrado. Removendo $lock..."
    sudo rm -f "$lock"
  fi
}

install_pkg() {
  pacman_unlock
  if need_aur; then
    $AUR -S --needed --noconfirm "$@"
    return $?
  fi
  sudo pacman -S --needed --noconfirm "$@"
}

install_fpk() { sudo flatpak install --noninteractive flathub "$1"; }
uninstall_fpk() { sudo flatpak uninstall --noninteractive "$@" 2>/dev/null || true; }

remove_pkg() {
  pacman_unlock
  if need_aur; then
    $AUR -Rns --noconfirm "$@" 2>/dev/null || sudo pacman -Rns --noconfirm "$@" 2>/dev/null || true
  else
    sudo pacman -Rns --noconfirm "$@" 2>/dev/null || true
  fi
  local orphans
  orphans="$(pacman -Qdtq 2>/dev/null)"
  if [[ -n "$orphans" ]]; then
    step "Removendo pacotes órfãos..."
    sudo pacman -Rns --noconfirm $orphans 2>/dev/null || true
  fi
}

log()  { echo -e "  \e[32m[+]\e[0m $*"; }
warn() { echo -e "  \e[33m[!]\e[0m $*"; }
err()  { echo -e "  \e[31m[✗]\e[0m $*"; }
step() { echo -e "\n  \e[36m──▸\e[0m \e[1m$*\e[0m"; }
ok()   { echo -e "  \e[32m[+]\e[0m $*"; }
