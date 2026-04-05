#!/usr/bin/env bash
# category.sh CAT — lista os apps de uma categoria

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/backend.sh"

cat="${1:-gaming}"
title="${CATS_TITLE[$cat]:-Categoria}"
icon="${CATS_ICON[$cat]}"
cat_type="${CATS_TYPE[$cat]:-app}"
read -ra apps <<< "${CATS_APPS[$cat]}"
bbv_base="http://127.0.0.1:${bbv_port:-6482}"

html_header "$title — Arch Setup Manager"

cat << HTML
<div class="nav">
  <a href="/execute\$./main.sh" class="btn btn-back">← Voltar</a>
  <span class="nav-title">$icon&nbsp; $title</span>
</div>
<div class="section" style="margin-top:16px;">
  <div class="section-header">$([[ $cat_type == config ]] && echo "Configurações" || echo "Apps disponíveis")</div>
HTML

manage_htmls=()

for key in "${apps[@]}"; do
    nm="$(name_app "$key")"
    ds="$(desc_app "$key")"

    if [[ $cat_type == config ]]; then
        if status_app "$key" 2>/dev/null; then
            installed=true
            action_btn="<a href=\"/execute\$./action.sh install $key $cat\" class=\"btn-icon btn-icon-config\" title=\"Reaplicar $nm\">↺</a>"
        else
            installed=false
            action_btn="<a href=\"/execute\$./action.sh install $key $cat\" class=\"btn-icon btn-icon-primary\" title=\"Aplicar $nm\">▶</a>"
        fi
    elif status_app "$key" 2>/dev/null; then
        installed=true
        action_btn="<a href=\"/execute\$./confirm.sh $key $cat\" class=\"btn-icon btn-icon-danger\" title=\"Remover $nm\">🗑</a>"
    else
        installed=false
        action_btn="<a href=\"/execute\$./action.sh install $key $cat\" class=\"btn-icon btn-icon-primary\" title=\"Instalar $nm\">⬇</a>"
    fi

    manage_btn=""
    launch_btn=""
    if [[ $installed == true ]]; then
        manage_app "$key" "$bbv_base"
        if [[ -n "$MANAGE_FN" ]]; then
            manage_out=$("$MANAGE_FN")
            manage_onclick=${manage_out%%$'\n'*}
            manage_htmls+=("${manage_out#*$'\n'}")
            manage_btn="<button onclick=\"$manage_onclick\" class=\"btn-manage\" title=\"Gerenciar $nm\">⚙</button>"
        fi

        launch_url=$(launch_app "$key")
        if [[ -n "$launch_url" ]]; then
            launch_btn="<button onclick=\"fetch('${bbv_base}/execute\$./launch.sh ${launch_url}')\" class=\"btn-launch\" title=\"Abrir $nm\">↗</button>"
        fi
    fi

    cat << HTML
  <div class="app-row">
    <div class="app-info">
      <div class="app-name">$nm</div>
      <div class="app-desc">$ds</div>
    </div>
    <div class="app-actions">
      $launch_btn
      $manage_btn
      $action_btn
    </div>
  </div>
HTML
done

cat << 'HTML'
</div>

<style>
.btn-launch {
    background: none;
    border: none;
    cursor: pointer;
    width: 30px;
    height: 30px;
    padding: 3px;
    border-radius: 6px;
    font-size: 16px;
    line-height: 1;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    transition: color .15s, background .15s;
    color: var(--primary);
  }
  .btn-launch:hover { background: rgba(124,103,250,.15); }

.btn-manage {
    background: none;
    border: none;
    cursor: pointer;
    width: 30px;
    height: 30px;
    padding: 4px;
    border-radius: 6px;
    font-size: 20px;
    line-height: 1;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    transition: color .15s, background .15s;
    color: var(--muted);
  }
  .btn-manage:hover { color: var(--text); background: rgba(255,255,255,.07); }

  .btn-icon {
    width: 30px;
    height: 30px;
    border-radius: 8px;
    border: none;
    cursor: pointer;
    font-size: 14px;
    line-height: 1;
    text-decoration: none;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    transition: background .15s, opacity .15s;
  }
  .btn-icon:active { opacity: .7; }
  .btn-icon-danger  { background: rgba(224,108,117,.18); color: var(--danger); }
  .btn-icon-primary { background: rgba(61,220,132,.18);  color: var(--success); }
  .btn-icon-config  { background: rgba(124,103,250,.18); color: var(--primary); }
  .btn-icon-danger:hover  { background: rgba(224,108,117,.3); }
  .btn-icon-primary:hover { background: rgba(61,220,132,.3); }
  .btn-icon-config:hover  { background: rgba(124,103,250,.3); }
</style>
HTML

for html in "${manage_htmls[@]}"; do
    echo "$html"
done

html_footer
