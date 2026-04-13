#!/usr/bin/env bash
APP_ID="aider"
APP_NAME="Aider"
APP_DESC="Pair programming com IA no terminal via Git — edita código usando Claude, GPT e outros"

status_aider() {
    has_cmd "aider" || test -x "$HOME/.local/bin/aider"
}

install_aider() {
    # Garante ~/.local/bin no PATH do processo atual
    export PATH="$HOME/.local/bin:$PATH"
    if getent passwd "$USER" | grep -q fish; then
        fish -c "fish_add_path '$HOME/.local/bin'" 2>/dev/null || true
    fi

    # Prefere uv (resolve melhor conflitos de versão)
    # Força Python 3.13: scipy/numpy não têm wheels para Python 3.14 ainda
    if has_cmd "uv"; then
        step "Instalando Aider via uv (Python 3.13)..."
        # audioop foi removido no Python 3.13; audioop-lts é o substituto de compatibilidade
        uv tool install aider-chat --with audioop-lts --python 3.13 \
            || uv tool install aider-chat --with audioop-lts --python 3.12 \
            || { err "Falha ao instalar Aider via uv."; return 1; }
    else
        if ! has_cmd "pipx"; then
            step "Instalando python-pipx..."
            install_pkg python-pipx || { err "Falha ao instalar pipx."; return 1; }
        fi

        step "Instalando Aider via pipx (Python 3.13)..."
        # Força Python 3.13: scipy/numpy não têm wheels para Python 3.14 ainda
        pipx install aider-chat --python python3.13 \
            || pipx install aider-chat --python python3.12 \
            || { err "Falha ao instalar Aider."; return 1; }
    fi

    if has_cmd "aider"; then
        log "Aider instalado! Execute: aider"
    else
        err "Instalação concluída, mas 'aider' não encontrado no PATH."
        warn "Tente executar: pipx ensurepath  (ou: uv tool update-shell)"
        return 1
    fi
}

manage_aider() {
    local bbv_base="$1"
    echo "openAiderModal()"
    cat << 'HTML'
<!-- ── Modal Aider ──────────────────────────────────────────────────── -->
<style>
  #aider-modal {
    display: none; position: fixed; inset: 0; z-index: 500;
    align-items: center; justify-content: center;
    background: rgba(0,0,0,0); backdrop-filter: blur(0px);
    transition: background .2s, backdrop-filter .2s;
  }
  #aider-modal.open {
    display: flex; background: rgba(0,0,0,.7); backdrop-filter: blur(3px);
  }
  #aider-modal .modal-panel {
    background: var(--surface); border: 1px solid var(--border);
    border-radius: var(--radius); width: min(620px, 92vw); max-height: 82vh;
    display: flex; flex-direction: column; overflow: hidden;
    box-shadow: 0 20px 60px rgba(0,0,0,.7);
    transform: scale(.96); opacity: 0; transition: transform .2s, opacity .2s;
  }
  #aider-modal.open .modal-panel { transform: scale(1); opacity: 1; }
  .adr-tabs { display: flex; gap: 4px; padding: 8px 16px; border-bottom: 1px solid var(--border); flex-shrink: 0; }
  .adr-tab  { padding: 5px 14px; border-radius: 6px; border: 1px solid transparent; cursor: pointer;
               font-size: 13px; background: none; color: var(--muted); transition: all .15s; }
  .adr-tab.active { background: rgba(124,103,250,.18); color: var(--primary); border-color: rgba(124,103,250,.3); }
  .adr-tab:hover:not(.active) { background: rgba(255,255,255,.05); color: var(--text); }
  .adr-pane { display: none; flex: 1; overflow-y: auto; padding: 16px;
               flex-direction: column; gap: 12px; min-height: 0; }
  .adr-pane.active { display: flex; }
  .adr-row { display: flex; align-items: center; gap: 10px; padding: 8px 12px;
              background: var(--card); border-radius: 6px; border: 1px solid var(--border); }
  .adr-sel { background: rgba(124,103,250,.15); border: none; color: var(--primary);
              border-radius: 4px; padding: 3px 9px; cursor: pointer; font-size: 12px;
              transition: background .15s; flex-shrink: 0; }
  .adr-sel:hover { background: rgba(124,103,250,.3); }
  .adr-input { flex: 1; background: var(--card); border: 1px solid var(--border);
                border-radius: 6px; padding: 8px 10px; color: var(--text);
                font-size: 13px; outline: none; transition: border-color .15s; }
  .adr-input:focus { border-color: var(--primary); }
  .adr-hint { font-size: 11px; color: var(--muted); line-height: 1.7; }
  .adr-current { padding: 10px 14px; background: rgba(124,103,250,.08);
                  border: 1px solid rgba(124,103,250,.2); border-radius: 6px;
                  font-size: 12px; display: flex; align-items: center; gap: 8px; }
</style>
<div id="aider-modal">
  <div class="modal-panel">
    <div style="padding:14px 20px; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; gap:12px; flex-shrink:0;">
      <span style="font-weight:700; font-size:14px;">⚡ Aider — Modelo Local</span>
      <button onclick="closeAiderModal()" style="background:none; border:none; color:var(--muted); font-size:18px; cursor:pointer; line-height:1; padding:0 4px;">✕</button>
    </div>
    <div style="padding:10px 16px; border-bottom:1px solid var(--border); flex-shrink:0;">
      <div class="adr-current">
        <span style="color:var(--muted); flex-shrink:0;">Modelo atual:</span>
        <span id="adr-current-model" style="flex:1;">Carregando...</span>
        <button onclick="adrClearModel()" class="btn btn-outline btn-sm" style="color:var(--muted); font-size:11px; padding:2px 8px;">✕ Limpar</button>
      </div>
    </div>
    <div class="adr-tabs">
      <button class="adr-tab active" onclick="adrTab('ollama')">🦙 Ollama (local)</button>
      <button class="adr-tab"        onclick="adrTab('custom')">✏ Personalizado</button>
    </div>

    <!-- Aba: Ollama -->
    <div id="adr-pane-ollama" class="adr-pane active">
      <div class="adr-hint">
        Selecione um modelo instalado no Ollama para usar como backend do aider.<br>
        O modelo será salvo em <code>~/.aider.conf.yml</code>.
      </div>
      <div id="adr-ollama-list" style="font-size:13px; color:var(--muted);">Carregando...</div>
      <div style="flex-shrink:0; padding-top:8px; border-top:1px solid var(--border);">
        <button onclick="adrLoadOllama()" class="btn btn-outline btn-sm">↻ Atualizar</button>
      </div>
    </div>

    <!-- Aba: Personalizado -->
    <div id="adr-pane-custom" class="adr-pane">
      <div class="adr-hint">
        Informe qualquer string de modelo compatível com aider.<br>
        Exemplos: <code>ollama/qwen2.5-coder:7b</code> · <code>openrouter/deepseek/deepseek-r1</code> · <code>groq/llama3-70b-8192</code>
      </div>
      <div style="display:flex; gap:8px;">
        <input id="adr-custom-input" class="adr-input" type="text"
               placeholder="ex: ollama/llama3.2:3b"
               onkeydown="if(event.key==='Enter') adrSaveCustom()">
        <button onclick="adrSaveCustom()" class="btn btn-primary btn-sm">✓ Salvar</button>
      </div>
      <div id="adr-custom-status" style="font-size:13px; min-height:20px;"></div>
    </div>

    <div id="adr-set-status" style="font-size:12px; min-height:16px; padding:8px 16px; flex-shrink:0;"></div>
  </div>
</div>
HTML
    cat << SCRIPT
<script>
(function() {
  var bbv   = '${bbv_base}';
  var modal = document.getElementById('aider-modal');

  window.openAiderModal = function() {
    modal.style.display = 'flex';
    requestAnimationFrame(function() { modal.classList.add('open'); });
    document.body.style.overflow = 'hidden';
    adrLoadCurrent();
    adrLoadOllama();
  };
  window.closeAiderModal = function() {
    modal.classList.remove('open');
    setTimeout(function() { modal.style.display = 'none'; }, 200);
    document.body.style.overflow = '';
  };
  window.adrTab = function(tab) {
    var tabs = ['ollama', 'custom'];
    document.querySelectorAll('.adr-tab').forEach(function(b, i) {
      b.classList.toggle('active', tabs[i] === tab);
    });
    tabs.forEach(function(t) {
      document.getElementById('adr-pane-' + t).classList.toggle('active', t === tab);
    });
  };
  function adrLoadCurrent() {
    fetch(bbv + '/execute\$./aider-manage.sh get-config')
      .then(function(r) { return r.text(); })
      .then(function(html) { document.getElementById('adr-current-model').innerHTML = html; })
      .catch(function() {});
  }
  window.adrLoadOllama = function() {
    var out = document.getElementById('adr-ollama-list');
    out.innerHTML = '<span style="color:var(--muted);">Carregando...</span>';
    fetch(bbv + '/execute\$./aider-manage.sh list-ollama')
      .then(function(r) { return r.text(); })
      .then(function(html) { out.innerHTML = html; })
      .catch(function(e) { out.textContent = 'Erro: ' + e; });
  };
  window.adrSetModel = function(model) {
    var st = document.getElementById('adr-set-status');
    st.innerHTML = '<span style="color:var(--muted);">Salvando...</span>';
    fetch(bbv + '/execute\$./aider-manage.sh set-model ' + encodeURIComponent(model))
      .then(function(r) { return r.text(); })
      .then(function(html) {
        st.innerHTML = html;
        adrLoadCurrent();
        adrLoadOllama();
      });
  };
  window.adrClearModel = function() {
    var st = document.getElementById('adr-set-status');
    fetch(bbv + '/execute\$./aider-manage.sh clear-model')
      .then(function(r) { return r.text(); })
      .then(function(html) { st.innerHTML = html; adrLoadCurrent(); adrLoadOllama(); });
  };
  window.adrSaveCustom = function() {
    var model = document.getElementById('adr-custom-input').value.trim();
    var st    = document.getElementById('adr-custom-status');
    if (!model) { st.innerHTML = '<span style="color:var(--danger);">Informe o modelo.</span>'; return; }
    st.innerHTML = '<span style="color:var(--muted);">Salvando...</span>';
    fetch(bbv + '/execute\$./aider-manage.sh set-model ' + encodeURIComponent(model))
      .then(function(r) { return r.text(); })
      .then(function(html) {
        st.innerHTML = html;
        document.getElementById('adr-custom-input').value = '';
        document.getElementById('adr-set-status').innerHTML = html;
        adrLoadCurrent();
      });
  };
  document.addEventListener('keydown', function(e) { if (e.key === 'Escape') closeAiderModal(); });
  document.getElementById('aider-modal').addEventListener('click', function(e) {
    if (e.target === this) closeAiderModal();
  });
})();
</script>
SCRIPT
}

remove_aider() {
    step "Removendo Aider..."
    if has_cmd "uv"; then
        uv tool uninstall aider-chat 2>/dev/null || true
    fi
    pipx uninstall aider-chat 2>/dev/null || true
    log "Aider removido."
}
