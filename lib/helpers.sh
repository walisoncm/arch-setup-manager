#!/usr/bin/env bash
# lib/helpers.sh

AUR=""
for _h in paru yay; do command -v "$_h" &>/dev/null && AUR="$_h" && break; done

has_pkg()     { pacman -Qi "$1" &>/dev/null 2>&1; }
has_flatpak() { flatpak info "$1" &>/dev/null 2>&1; }
has_cmd()     { command -v "$1" &>/dev/null; }
svc_enabled() { systemctl is-enabled "$1" &>/dev/null 2>&1; }
in_group()    { id -nG "$USER" | grep -qw "$1"; }
need_aur()    { [[ -n "$AUR" ]]; }

install_pkg() {
  if need_aur; then
    $AUR -S --needed --noconfirm "$1"
    return $?
  fi

  sudo pacman -S --needed --noconfirm "$1";
}

install_flatpak() { sudo flatpak install --noninteractive flathub "$1"; }

log()  { echo -e "  \e[32m[+]\e[0m $*"; }
warn() { echo -e "  \e[33m[!]\e[0m $*"; }
err()  { echo -e "  \e[31m[✗]\e[0m $*"; }
step() { echo -e "\n  \e[36m──▸\e[0m \e[1m$*\e[0m"; }
ok()   { echo -e "  \e[32m[+]\e[0m $*"; }
