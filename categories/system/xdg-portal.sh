#!/usr/bin/env bash
APP_ID="xdg-portal"
APP_NAME="XDG Desktop Portal"
APP_DESC="Diálogos de arquivo e integração desktop"

PORTAL_CONF="$HOME/.config/xdg-desktop-portal/portals.conf"

_portal_conf_ok() {
    [[ -f "$PORTAL_CONF" ]] && grep -q "^default=gtk" "$PORTAL_CONF"
}

status_xdg_portal() {
    has_pkg "xdg-desktop-portal-gtk" && has_pkg "xdg-desktop-portal-wlr" && _portal_conf_ok
}

install_xdg_portal() {
    step "Instalando xdg-desktop-portal backends..."
    install_pkg xdg-desktop-portal-gtk xdg-desktop-portal-wlr

    mkdir -p "$(dirname "$PORTAL_CONF")"
    cat > "$PORTAL_CONF" <<'EOF'
[preferred]
default=gtk
org.freedesktop.impl.portal.ScreenCast=wlr
org.freedesktop.impl.portal.Screenshot=wlr
EOF

    systemctl --user restart xdg-desktop-portal 2>/dev/null || true
    log "XDG Portal configurado (GTK para diálogos, wlr para screencasting)."
}

remove_xdg_portal() {
    remove_pkg xdg-desktop-portal-gtk xdg-desktop-portal-wlr
    rm -f "$PORTAL_CONF"
    log "XDG Portal removido."
}
