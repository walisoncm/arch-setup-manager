#!/usr/bin/env bash
APP_ID="waveterm-bin"
APP_NAME="WaveTerm"
APP_DESC="Terminal nativo com IA que visualiza todo o seu espaço de trabalho"

manage_waveterm_bin() {
    local bbv_base="$1"
    echo "openWavetermModal()"
    cat << 'HTML'
<!-- ── Modal WaveTerm AI ─────────────────────────────────────────────── -->
<style>
  #waveterm-modal {
    display: none; position: fixed; inset: 0; z-index: 500;
    align-items: center; justify-content: center;
    background: rgba(0,0,0,0); backdrop-filter: blur(0px);
    transition: background .2s, backdrop-filter .2s;
  }
  #waveterm-modal.open {
    display: flex; background: rgba(0,0,0,.7); backdrop-filter: blur(3px);
  }
  #waveterm-modal .modal-panel {
    background: var(--surface); border: 1px solid var(--border);
    border-radius: var(--radius); width: min(680px, 92vw); max-height: 82vh;
    display: flex; flex-direction: column; overflow: hidden;
    box-shadow: 0 20px 60px rgba(0,0,0,.7);
    transform: scale(.96); opacity: 0; transition: transform .2s, opacity .2s;
  }
  #waveterm-modal.open .modal-panel { transform: scale(1); opacity: 1; }
  .wtm-tabs { display: flex; gap: 4px; padding: 8px 16px; border-bottom: 1px solid var(--border); flex-shrink: 0; }
  .wtm-tab  { padding: 5px 14px; border-radius: 6px; border: 1px solid transparent; cursor: pointer;
               font-size: 13px; background: none; color: var(--muted); transition: all .15s; }
  .wtm-tab.active { background: rgba(124,103,250,.18); color: var(--primary); border-color: rgba(124,103,250,.3); }
  .wtm-tab:hover:not(.active) { background: rgba(255,255,255,.05); color: var(--text); }
  .wtm-pane { display: none; flex: 1; overflow-y: auto; padding: 16px;
               flex-direction: column; gap: 12px; min-height: 0; }
  .wtm-pane.active { display: flex; }
  .wtm-row { display: flex; align-items: center; gap: 10px; padding: 8px 12px;
              background: var(--card); border-radius: 6px; border: 1px solid var(--border); }
  .wtm-del { background: rgba(224,108,117,.15); border: none; color: var(--danger);
              border-radius: 4px; padding: 3px 9px; cursor: pointer; font-size: 12px;
              transition: background .15s; flex-shrink: 0; }
  .wtm-del:hover { background: rgba(224,108,117,.3); }
  .wtm-add { background: rgba(61,220,132,.12); border: none; color: #3ddc84;
              border-radius: 4px; padding: 3px 9px; cursor: pointer; font-size: 12px;
              transition: background .15s; flex-shrink: 0; }
  .wtm-add:hover { background: rgba(61,220,132,.25); }
  .wtm-hint { font-size: 11px; color: var(--muted); line-height: 1.7; }
  .wtm-input { flex: 1; background: var(--card); border: 1px solid var(--border);
                border-radius: 6px; padding: 8px 10px; color: var(--text);
                font-size: 13px; outline: none; transition: border-color .15s; }
  .wtm-input:focus { border-color: var(--primary); }
</style>
<div id="waveterm-modal">
  <div class="modal-panel">
    <div style="padding:14px 20px; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; gap:12px; flex-shrink:0;">
      <span style="font-weight:700; font-size:14px;">🌊 WaveTerm — IAs do Ollama</span>
      <button onclick="closeWavetermModal()" style="background:none; border:none; color:var(--muted); font-size:18px; cursor:pointer; line-height:1; padding:0 4px;">✕</button>
    </div>
    <div class="wtm-tabs">
      <button class="wtm-tab active" onclick="wtmTab('configs')">⚙ Configuradas</button>
      <button class="wtm-tab"        onclick="wtmTab('add')">➕ Adicionar</button>
      <button class="wtm-tab"        onclick="wtmTab('manual')">✏ Manual</button>
    </div>

    <!-- Aba: Configuradas -->
    <div id="wtm-pane-configs" class="wtm-pane active">
      <div id="wtm-config-list" style="font-size:13px; color:var(--muted);">Carregando...</div>
      <div style="flex-shrink:0; padding-top:10px; border-top:1px solid var(--border);">
        <button onclick="wtmLoadConfigs()" class="btn btn-outline btn-sm">↻ Atualizar</button>
      </div>
      <div id="wtm-remove-status" style="font-size:12px; min-height:16px;"></div>
    </div>

    <!-- Aba: Adicionar (modelos Ollama instalados) -->
    <div id="wtm-pane-add" class="wtm-pane">
      <div class="wtm-hint">
        Selecione um modelo Ollama instalado para adicioná-lo como IA no WaveTerm.<br>
        O WaveTerm precisa ser reiniciado para aplicar as mudanças.
      </div>
      <div id="wtm-model-list" style="font-size:13px; color:var(--muted);">Carregando...</div>
      <div style="flex-shrink:0; padding-top:10px; border-top:1px solid var(--border);">
        <button onclick="wtmLoadModels()" class="btn btn-outline btn-sm">↻ Atualizar</button>
      </div>
      <div id="wtm-add-status" style="font-size:12px; min-height:16px;"></div>
    </div>

    <!-- Aba: Manual -->
    <div id="wtm-pane-manual" class="wtm-pane">
      <div class="wtm-hint">
        Adicione qualquer modelo Ollama manualmente, mesmo que não esteja instalado ainda.
      </div>
      <div style="display:flex; flex-direction:column; gap:8px;">
        <div style="display:flex; gap:8px; align-items:center;">
          <label style="font-size:12px; color:var(--muted); width:80px; flex-shrink:0;">Modelo</label>
          <input id="wtm-manual-model" class="wtm-input" type="text"
                 placeholder="ex: gemma3:4b  ou  qwen2.5-coder:7b">
        </div>
        <div style="display:flex; gap:8px; align-items:center;">
          <label style="font-size:12px; color:var(--muted); width:80px; flex-shrink:0;">Nome</label>
          <input id="wtm-manual-name" class="wtm-input" type="text"
                 placeholder="ex: Gemma 3 4B  (deixe vazio para padrão)">
        </div>
        <div style="display:flex; justify-content:flex-end;">
          <button onclick="wtmManualAdd()" class="btn btn-primary btn-sm">➕ Adicionar</button>
        </div>
      </div>
      <div id="wtm-manual-status" style="font-size:13px; min-height:20px;"></div>
    </div>
  </div>
</div>
HTML
    # Injeta bbv_base via shell (fora do heredoc single-quote)
    cat << SCRIPT
<script>
(function() {
  var bbv   = '${bbv_base}';
  var modal = document.getElementById('waveterm-modal');

  window.openWavetermModal = function() {
    modal.style.display = 'flex';
    requestAnimationFrame(function() { modal.classList.add('open'); });
    document.body.style.overflow = 'hidden';
    wtmLoadConfigs();
  };
  window.closeWavetermModal = function() {
    modal.classList.remove('open');
    setTimeout(function() { modal.style.display = 'none'; }, 200);
    document.body.style.overflow = '';
  };
  window.wtmTab = function(tab) {
    var tabs  = ['configs', 'add', 'manual'];
    document.querySelectorAll('.wtm-tab').forEach(function(b, i) {
      b.classList.toggle('active', tabs[i] === tab);
    });
    tabs.forEach(function(t) {
      document.getElementById('wtm-pane-' + t).classList.toggle('active', t === tab);
    });
    if (tab === 'add') wtmLoadModels();
  };

  window.wtmLoadConfigs = function() {
    var out = document.getElementById('wtm-config-list');
    out.innerHTML = '<span style="color:var(--muted);">Carregando...</span>';
    fetch(bbv + '/execute\$./waveterm-manage.sh list-configs')
      .then(function(r) { return r.text(); })
      .then(function(html) { out.innerHTML = html; })
      .catch(function(e) { out.textContent = 'Erro: ' + e; });
  };

  window.wtmLoadModels = function() {
    var out = document.getElementById('wtm-model-list');
    out.innerHTML = '<span style="color:var(--muted);">Carregando...</span>';
    fetch(bbv + '/execute\$./waveterm-manage.sh list-models')
      .then(function(r) { return r.text(); })
      .then(function(html) { out.innerHTML = html; })
      .catch(function(e) { out.textContent = 'Erro: ' + e; });
  };

  window.wtmAddModel = function(model) {
    var st = document.getElementById('wtm-add-status');
    st.innerHTML = '<span style="color:var(--muted);">Adicionando...</span>';
    fetch(bbv + '/execute\$./waveterm-manage.sh add ' + encodeURIComponent(model))
      .then(function(r) { return r.text(); })
      .then(function(html) {
        st.innerHTML = html;
        wtmLoadModels();
      });
  };

  window.wtmRemoveConfig = function(key) {
    if (!confirm('Remover esta configuração do WaveTerm?')) return;
    var st = document.getElementById('wtm-remove-status');
    st.innerHTML = '<span style="color:var(--muted);">Removendo...</span>';
    fetch(bbv + '/execute\$./waveterm-manage.sh remove ' + encodeURIComponent(key))
      .then(function(r) { return r.text(); })
      .then(function(html) {
        st.innerHTML = html;
        wtmLoadConfigs();
      });
  };

  window.wtmManualAdd = function() {
    var model = document.getElementById('wtm-manual-model').value.trim();
    var name  = document.getElementById('wtm-manual-name').value.trim();
    var st    = document.getElementById('wtm-manual-status');
    if (!model) { st.innerHTML = '<span style="color:var(--danger);">Informe o nome do modelo.</span>'; return; }
    if (!name) name = 'Ollama (' + model + ')';
    st.innerHTML = '<span style="color:var(--muted);">Adicionando...</span>';
    fetch(bbv + '/execute\$./waveterm-manage.sh add ' + encodeURIComponent(model) + ' ' + encodeURIComponent(name))
      .then(function(r) { return r.text(); })
      .then(function(html) {
        st.innerHTML = html;
        document.getElementById('wtm-manual-model').value = '';
        document.getElementById('wtm-manual-name').value  = '';
      });
  };

  document.addEventListener('keydown', function(e) { if (e.key === 'Escape') closeWavetermModal(); });
  document.getElementById('waveterm-modal').addEventListener('click', function(e) {
    if (e.target === this) closeWavetermModal();
  });
})();
</script>
SCRIPT
}