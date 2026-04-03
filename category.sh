#!/usr/bin/env bash
# category.sh CAT — lista os apps de uma categoria

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/backend.sh"

cat="${1:-gaming}"
title="${CATS_TITLE[$cat]:-Categoria}"
icon="${CATS_ICON[$cat]}"
read -ra apps <<< "${CATS_APPS[$cat]}"
bbv_base="http://127.0.0.1:${bbv_port:-6482}"

html_header "$title — Arch Setup Manager"

cat << HTML
<div class="nav">
  <a href="/execute\$./main.sh" class="btn btn-back">← Voltar</a>
  <span class="nav-title">$icon&nbsp; $title</span>
</div>
<div class="section" style="margin-top:16px;">
  <div class="section-header">Apps disponíveis</div>
HTML

for key in "${apps[@]}"; do
    nm="$(name_app "$key")"
    ds="$(desc_app "$key")"

    if status_app "$key" 2>/dev/null; then
        installed=true
        action_btn="<a href=\"/execute\$./confirm.sh $key $cat\" class=\"btn-icon btn-icon-danger\" title=\"Remover $nm\">🗑</a>"
    else
        installed=false
        action_btn="<a href=\"/execute\$./action.sh install $key $cat\" class=\"btn-icon btn-icon-primary\" title=\"Instalar $nm\">⬇</a>"
    fi

    manage_btn=""
    [[ "$key" == "fwupd" && $installed == true ]] && \
        manage_btn='<button onclick="openFwupdModal()" class="btn-manage" title="Gerenciar fwupd">⚙</button>'

    cat << HTML
  <div class="app-row">
    <div class="app-info">
      <div class="app-name">$nm</div>
      <div class="app-desc">$ds</div>
    </div>
    <div class="app-actions">
      $manage_btn
      $action_btn
    </div>
  </div>
HTML
done

cat << 'HTML'
</div>

<!-- ── Modal fwupd ─────────────────────────────────────────────────── -->
<div id="fwupd-modal" style="display:none; position:fixed; inset:0; background:rgba(0,0,0,.65); z-index:500; align-items:center; justify-content:center;">
  <div style="background:var(--surface); border:1px solid var(--border); border-radius:var(--radius); width:min(680px,92vw); max-height:80vh; display:flex; flex-direction:column; overflow:hidden; box-shadow:0 20px 60px rgba(0,0,0,.6);">

    <!-- cabeçalho -->
    <div style="padding:14px 20px; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; gap:12px; flex-shrink:0;">
      <span style="font-weight:700; font-size:14px;">⚙ fwupd — Gerenciamento de Firmware</span>
      <button onclick="closeFwupdModal()" style="background:none; border:none; color:var(--muted); font-size:18px; cursor:pointer; line-height:1; padding:0 4px;">✕</button>
    </div>

    <!-- ações -->
    <div style="padding:14px 20px; border-bottom:1px solid var(--border); display:flex; gap:8px; flex-wrap:wrap; flex-shrink:0;">
      <button onclick="fwupdRun('refresh')"     class="btn btn-outline btn-sm">↻ Atualizar metadados</button>
      <button onclick="fwupdRun('get-updates')" class="btn btn-primary btn-sm">🔍 Verificar atualizações</button>
      <button id="fwupd-btn-install" onclick="fwupdRun('update')" class="btn btn-outline btn-sm" style="display:none; border-color:var(--success); color:var(--success);">⬇ Instalar atualizações</button>
    </div>

    <!-- console -->
    <div id="fwupd-output"
         style="flex:1; overflow-y:auto; padding:14px 18px; font-family:'JetBrains Mono','Fira Code',monospace; font-size:12px; line-height:1.7; background:#090912; color:#c4c4dc; white-space:pre-wrap; word-break:break-word; min-height:180px;">
      Clique em <strong>Verificar atualizações</strong> para começar.
    </div>

  </div>
</div>

<style>
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
  .btn-icon-danger:hover  { background: rgba(224,108,117,.3); }
  .btn-icon-primary:hover { background: rgba(61,220,132,.3); }
</style>
HTML

cat << HTML
<script>
(function() {
  var bbv = '${bbv_base}';

  window.openFwupdModal = function() {
    document.getElementById('fwupd-modal').style.display = 'flex';
  };

  window.closeFwupdModal = function() {
    document.getElementById('fwupd-modal').style.display = 'none';
  };

  window.fwupdRun = function(action) {
    var out    = document.getElementById('fwupd-output');
    var btnIn  = document.getElementById('fwupd-btn-install');
    out.innerHTML = '<span style="color:var(--muted);">Executando...</span>';

    fetch(bbv + '/execute\$./fwupd-manage.sh ' + action)
      .then(function(r) { return r.text(); })
      .then(function(html) {
        out.innerHTML = html;
        if (action === 'get-updates') {
          btnIn.style.display = out.innerHTML.includes('data-has-updates') ? 'inline-flex' : 'none';
        }
      })
      .catch(function(err) {
        out.textContent = 'Erro ao executar: ' + err;
      });
  };

  // Fecha modal com Esc
  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') closeFwupdModal();
  });

  // Fecha ao clicar fora do painel
  document.getElementById('fwupd-modal').addEventListener('click', function(e) {
    if (e.target === this) closeFwupdModal();
  });
})();
</script>
HTML

html_footer
