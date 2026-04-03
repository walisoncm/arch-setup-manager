#!/usr/bin/env bash
# backend.sh — Loader dinâmico de categorias e apps

source "./lib/helpers.sh"

# ─── ARRAYS GLOBAIS ───────────────────────────────────────────────────────────
declare -A CATS_TITLE CATS_ICON CATS_APPS CATS_DESC
declare -A APP_NAMES APP_DESCS
CATEGORIES=()

# ─── CARREGAMENTO DINÂMICO ────────────────────────────────────────────────────
# Cada categoria é uma pasta dentro de 'categories/':
#   category.sh  → metadados da categoria (CAT_ID, CAT_TITLE, CAT_ICON, CAT_DESC)
#   *.sh         → um arquivo por app (APP_ID, APP_NAME, APP_DESC + funções opcionais)
MOD_PATH="./categories"

if [[ -d "$MOD_PATH" ]]; then
    for cat_dir in "$MOD_PATH"/*/; do
        [[ -f "${cat_dir}category.sh" ]] || continue

        source "${cat_dir}category.sh"

        if [[ -n "$CAT_ID" ]]; then
            CATEGORIES+=("$CAT_ID")
            CATS_TITLE[$CAT_ID]="$CAT_TITLE"
            CATS_ICON[$CAT_ID]="$CAT_ICON"
            CATS_DESC[$CAT_ID]="$CAT_DESC"
            unset CAT_ID CAT_TITLE CAT_ICON CAT_DESC

            _cat_apps=""
            for app_file in "${cat_dir}"*.sh; do
                [[ "$(basename "$app_file")" == "category.sh" ]] && continue
                [[ -f "$app_file" ]] || continue

                source "$app_file"

                if [[ -n "$APP_ID" ]]; then
                    _cat_apps+=" $APP_ID"
                    APP_NAMES[$APP_ID]="$APP_NAME"
                    APP_DESCS[$APP_ID]="$APP_DESC"
                    unset APP_ID APP_NAME APP_DESC
                fi
            done

            CATS_APPS[${CATEGORIES[-1]}]="${_cat_apps# }"
            unset _cat_apps
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

name_app() {
    local app_id="$1" norm="${1//./_}"
    if declare -f "name_$norm" > /dev/null; then
        "name_$norm"
    elif [[ -n "${APP_NAMES[$app_id]+x}" ]]; then
        echo "${APP_NAMES[$app_id]}"
    else
        echo "$app_id"
    fi
}

desc_app() {
    local app_id="$1" norm="${1//./_}"
    if declare -f "desc_$norm" > /dev/null; then
        "desc_$norm"
    elif [[ -n "${APP_DESCS[$app_id]+x}" ]]; then
        echo "${APP_DESCS[$app_id]}"
    else
        echo ""
    fi
}

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
