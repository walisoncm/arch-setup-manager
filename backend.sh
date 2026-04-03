#!/usr/bin/env bash
# backend.sh — Loader dinâmico de categorias e apps

source "./lib/helpers.sh"

# ─── ARRAYS GLOBAIS ───────────────────────────────────────────────────────────
declare -A CATS_TITLE CATS_ICON CATS_APPS CATS_DESC
CATEGORIES=()

# ─── CARREGAMENTO DINÂMICO ────────────────────────────────────────────────────
# Procura por arquivos .sh dentro da pasta 'categories'
MOD_PATH="./categories"

if [[ -d "$MOD_PATH" ]]; then
    for module in "$MOD_PATH"/*.sh; do
        if [[ -f "$module" ]]; then
            # Carrega o arquivo da categoria
            source "$module"
            
            # As variáveis abaixo devem ser definidas dentro de cada arquivo de categoria
            if [[ -n "$CAT_ID" ]]; then
                CATEGORIES+=("$CAT_ID")
                CATS_TITLE[$CAT_ID]="$CAT_TITLE"
                CATS_ICON[$CAT_ID]="$CAT_ICON"
                CATS_DESC[$CAT_ID]="$CAT_DESC"
                CATS_APPS[$CAT_ID]="$CAT_APPS"
                
                # Limpa as variáveis para o próximo loop não herdar lixo
                unset CAT_ID CAT_TITLE CAT_ICON CAT_DESC CAT_APPS
            fi
        fi
    done
else
    err "Diretório de categorias '$MOD_PATH' não encontrado!"
fi

count_installed() {
    local cat="$1" total=0 installed=0
    local -a apps; read -ra apps <<< "${CATS_APPS[$cat]}"
    for key in "${apps[@]}"; do
        (( total++ ))
        status_app "$key" && (( installed++ )) || true
    done
    echo "$installed $total"
}

name_app() { echo "$( "name_${1//./_}" 2>/dev/null || echo "$1" )"; }
desc_app() { echo "$( "desc_${1//./_}" 2>/dev/null || echo "" )"; }

status_app() {
    local app_id="$1"
    local normalize_id="${app_id//./_}"
    if declare -f "status_$normalize_id" > /dev/null; then
        "status_$normalize_id"
    else
        if [[ "$app_id" == *.* ]]; then
            has_flatpak "$app_id"
        else
            has_pkg "$app_id"
        fi
    fi
}

install_app() {
    local app_id="$1"
    local normalize_id="${app_id//./_}"
    local name; name="$(name_app "$app_id")"

    if declare -f "install_$normalize_id" > /dev/null; then
        "install_$normalize_id"
        return $?
    fi

    if [[ "$app_id" == *.* ]]; then
        step "Instalando $name via Flatpak..."
        install_flatpak "$app_id"
    else
        step "Instalando $name via Repositórios..."
        if need_aur; then
            $AUR -S --needed --noconfirm "$app_id"
        else
            sudo pacman -S --needed --noconfirm "$app_id"
        fi
    fi

    [[ $? -eq 0 ]] && ok "$name configurado!" || err "Falha ao instalar $app_id."
}

remove_app() {
    local app_id="$1"
    local normalize_id="${app_id//./_}"
    local name; name="$(name_app "$app_id")"

    if declare -f "remove_$normalize_id" > /dev/null; then
        "remove_$normalize_id"
    elif [[ "$app_id" == *.* ]]; then
        step "Removendo $name (Flatpak)..."
        sudo flatpak uninstall --noninteractive "$app_id"
        [[ $? -eq 0 ]] && ok "$name removido." || warn "A remoção de $app_id reportou algo (ou já não existia)."
    else
        step "Removendo $name..."
        if [[ -n "$AUR" ]]; then
            $AUR -Rns --noconfirm "$app_id" 2>/dev/null || sudo pacman -Rns --noconfirm "$app_id"
        else
            sudo pacman -Rns --noconfirm "$app_id"
        fi
        [[ $? -eq 0 ]] && ok "$name removido." || warn "A remoção de $app_id reportou algo (ou já não existia)."
    fi

    local orphans
    orphans="$(pacman -Qdtq 2>/dev/null)"
    if [[ -n "$orphans" ]]; then
        step "Removendo pacotes órfãos..."
        sudo pacman -Rns --noconfirm $orphans 2>/dev/null || true
    fi
}
