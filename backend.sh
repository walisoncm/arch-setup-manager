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
            has_fpk "$app_id"
        else
            has_pkg "$app_id"
        fi
    fi
}

launch_app() {
    local app_id="$1"
    local normalize_id="${app_id//./_}"
    if declare -f "launch_$normalize_id" > /dev/null; then
        "launch_$normalize_id"
    fi
}

manage_app() {
    local app_id="$1" bbv_base="$2"
    local normalize_id="${app_id//./_}"
    MANAGE_FN=""
    if declare -f "manage_$normalize_id" > /dev/null; then
        eval "_mbound_${normalize_id}() { manage_${normalize_id} $(printf '%q' "$bbv_base"); }"
        MANAGE_FN="_mbound_${normalize_id}"
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
        if ! status_app flatpak; then 
            install_app flatpak
        fi

        install_fpk "$app_id"
    else
        step "Instalando $name via Repositórios..."
        install_pkg "$app_id"
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
        uninstall_fpk "$app_id"
        [[ $? -eq 0 ]] && ok "$name removido." || warn "A remoção de $app_id reportou algo (ou já não existia)."
    else
        step "Removendo $name..."
        remove_pkg "$app_id"
        [[ $? -eq 0 ]] && ok "$name removido." || warn "A remoção de $app_id reportou algo (ou já não existia)."
    fi
}
