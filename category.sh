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
HTML

_render_app_row() {
    local key="$1"
    local nm ds action_btn manage_btn launch_btn installed dep row_style dep_label
    nm="$(name_app "$key")"
    ds="$(desc_app "$key")"
    dep="${APP_DEPS[$key]}"
    row_style=""
    dep_label=""

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

    # Estilo especial para dependências
    if [[ -n "$dep" ]]; then
        dep_label="<span style='font-size:10px; color:var(--primary); opacity:0.8; margin-right:6px;'>Requires: ${APP_NAMES[$dep]}</span>"
        # Só indentamos se o pai estiver no mesmo grupo/tipo (mesma aba)
        if [[ "${APP_TYPES[$key]}" == "${APP_TYPES[$dep]}" ]]; then
            row_style="margin-left: 20px; border-left: 2px solid var(--border); padding-left: 15px;"
        fi
    fi

    cat << HTML
  <div class="app-row" style="$row_style">
    <div class="app-info">
      <div class="app-name">$nm</div>
      <div class="app-desc">$dep_label$ds</div>
    </div>
    <div class="app-actions">
      $launch_btn
      $manage_btn
      $action_btn
    </div>
  </div>
HTML
}

declare -A rendered_apps

_render_tree() {
    local key="$1"
    local filter_type="$2"
    
    [[ "${rendered_apps[$key]}" == "true" ]] && return
    
    local type="${APP_TYPES[$key]}"
    # No modo 4 abas, filtramos pelo tipo exato
    [[ "$type" != "$filter_type" ]] && return
    
    _render_app_row "$key"
    rendered_apps[$key]=true
    
    # Renderizar filhos (mesmo que sejam de outro tipo, mantemos a hierarquia visual se solicitado)
    # Mas para o usuário, "Open WebUI" deve estar em Interface mesmo que Ollama esteja em Serviços.
    # Então na verdade não chamamos recursivo aqui se quisermos abas puras por tipo.
    # Se o usuário quer separação total, removemos o recursivo de árvore nas abas.
}

# ─── Renderização com Abas ───────────────────────────────────────────────────

cat << HTML
<style>
  .cat-tabs { display: flex; gap: 4px; padding: 0 20px; margin-top: 16px; border-bottom: 1px solid var(--border); overflow-x: auto; scrollbar-width: none; }
  .cat-tabs::-webkit-scrollbar { display: none; }
  .cat-tab  { padding: 8px 16px; border-radius: 8px 8px 0 0; border: 1px solid transparent; cursor: pointer;
               font-size: 13px; background: none; color: var(--muted); transition: all .15s; margin-bottom: -1px; white-space: nowrap; }
  .cat-tab.active { background: var(--surface); color: var(--primary); border-color: var(--border); border-bottom-color: var(--surface); font-weight: 600; }
  .cat-tab:hover:not(.active) { color: var(--text); background: rgba(255,255,255,.05); }
  .tab-content { display: none; padding-top: 8px; }
  .tab-content.active { display: block; }
</style>

<div class="cat-tabs">
  <button id="tab-btn-interface" class="cat-tab active" onclick="showTab('interface')">🖥 Interface</button>
  <button id="tab-btn-service"   class="cat-tab" onclick="showTab('service')">⚙ Serviços</button>
  <button id="tab-btn-cli"       class="cat-tab" onclick="showTab('cli')">⌨ CLI</button>
  <button id="tab-btn-agent"     class="cat-tab" onclick="showTab('agent')">🤖 Agentes</button>
</div>

<div id="tab-interface" class="tab-content active"><div class="section">
HTML
unset rendered_apps; declare -A rendered_apps
for key in "${apps[@]}"; do [[ "${APP_TYPES[$key]}" == "interface" ]] && _render_app_row "$key"; done
cat << HTML
</div></div>

<div id="tab-service" class="tab-content"><div class="section">
HTML
for key in "${apps[@]}"; do [[ "${APP_TYPES[$key]}" == "service" ]] && _render_app_row "$key"; done
cat << HTML
</div></div>

<div id="tab-cli" class="tab-content"><div class="section">
HTML
for key in "${apps[@]}"; do [[ "${APP_TYPES[$key]}" == "cli" ]] && _render_app_row "$key"; done
cat << HTML
</div></div>

<div id="tab-agent" class="tab-content"><div class="section">
HTML
for key in "${apps[@]}"; do [[ "${APP_TYPES[$key]}" == "agent" ]] && _render_app_row "$key"; done
cat << HTML
</div></div>

<script>
function showTab(type) {
  document.querySelectorAll('.cat-tab').forEach(b => b.classList.remove('active'));
  document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
  
  document.getElementById('tab-btn-' + type).classList.add('active');
  document.getElementById('tab-' + type).classList.add('active');
}
</script>
HTML

cat << 'HTML'
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
