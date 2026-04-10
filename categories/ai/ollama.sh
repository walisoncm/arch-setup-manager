#!/usr/bin/env bash
APP_ID="ollama"
APP_NAME="Ollama"
APP_DESC="IA Local com aceleração GPU"

status_ollama() { has_cmd "ollama"; }

manage_ollama() {
    local bbv_base="$1"
    echo "openOllamaModal()"
    cat << HTML
<!-- ── Modal Ollama ─────────────────────────────────────────────────── -->
<style>
  #ollama-modal {
    display: none; position: fixed; inset: 0; z-index: 500;
    align-items: center; justify-content: center;
    background: rgba(0,0,0,0); backdrop-filter: blur(0px);
    transition: background .2s, backdrop-filter .2s;
  }
  #ollama-modal.open {
    display: flex; background: rgba(0,0,0,.7); backdrop-filter: blur(3px);
  }
  #ollama-modal .modal-panel {
    background: var(--surface); border: 1px solid var(--border);
    border-radius: var(--radius); width: min(680px, 92vw); max-height: 82vh;
    display: flex; flex-direction: column; overflow: hidden;
    box-shadow: 0 20px 60px rgba(0,0,0,.7);
    transform: scale(.96); opacity: 0; transition: transform .2s, opacity .2s;
  }
  #ollama-modal.open .modal-panel { transform: scale(1); opacity: 1; }
  .olm-srv-bar { padding: 10px 16px; border-bottom: 1px solid var(--border);
                  display: flex; align-items: center; gap: 10px; flex-shrink: 0;
                  background: rgba(0,0,0,.18); }
  .olm-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
  .olm-dot.running { background: #3ddc84; box-shadow: 0 0 6px #3ddc84; }
  .olm-dot.stopped { background: var(--muted); }
  .olm-dot.starting { background: #ffb74d; animation: olm-blink .8s infinite; }
  @keyframes olm-blink { 0%,100%{opacity:1} 50%{opacity:.3} }
  .olm-tabs { display: flex; gap: 4px; padding: 8px 16px; border-bottom: 1px solid var(--border); flex-shrink: 0; }
  .olm-tab  { padding: 5px 14px; border-radius: 6px; border: 1px solid transparent; cursor: pointer;
               font-size: 13px; background: none; color: var(--muted); transition: all .15s; }
  .olm-tab.active { background: rgba(124,103,250,.18); color: var(--primary); border-color: rgba(124,103,250,.3); }
  .olm-tab:hover:not(.active) { background: rgba(255,255,255,.05); color: var(--text); }
  .olm-pane { display: none; flex: 1; overflow-y: auto; padding: 16px;
               flex-direction: column; gap: 12px; min-height: 0; }
  .olm-pane.active { display: flex; }
  .olm-row { display: flex; align-items: center; gap: 10px; padding: 8px 12px;
              background: var(--card); border-radius: 6px; border: 1px solid var(--border); }
  .olm-del { background: rgba(224,108,117,.15); border: none; color: var(--danger);
              border-radius: 4px; padding: 3px 9px; cursor: pointer; font-size: 12px;
              transition: background .15s; flex-shrink: 0; }
  .olm-del:hover { background: rgba(224,108,117,.3); }
  .olm-input { flex: 1; background: var(--card); border: 1px solid var(--border);
                border-radius: 6px; padding: 8px 10px; color: var(--text);
                font-size: 13px; outline: none; transition: border-color .15s; }
  .olm-input:focus { border-color: var(--primary); }
  .olm-hint { font-size: 11px; color: var(--muted); line-height: 1.7; }
  .olm-chips { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 4px; }
  .olm-chip { font-size: 11px; background: var(--card); border: 1px solid var(--border);
               border-radius: 4px; padding: 3px 8px; color: var(--muted); cursor: pointer;
               transition: border-color .15s, color .15s; }
  .olm-chip:hover { border-color: var(--primary); color: var(--primary); }
</style>
<div id="ollama-modal">
  <div class="modal-panel">
    <div style="padding:14px 20px; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; gap:12px; flex-shrink:0;">
      <span style="font-weight:700; font-size:14px;">🦙 Ollama — Gerenciamento de Modelos</span>
      <button onclick="closeOllamaModal()" style="background:none; border:none; color:var(--muted); font-size:18px; cursor:pointer; line-height:1; padding:0 4px;">✕</button>
    </div>
    <div class="olm-srv-bar">
      <div id="olm-dot" class="olm-dot stopped"></div>
      <span id="olm-srv-label" style="font-size:12px; color:var(--muted); flex:1;">Verificando serviço...</span>
      <button id="olm-btn-start" onclick="olmServiceStart()"
              class="btn btn-outline btn-sm" style="color:var(--success); border-color:rgba(61,220,132,.35);">▶ Iniciar</button>
      <button id="olm-btn-stop" onclick="olmServiceStop()"
              class="btn btn-outline btn-sm" style="color:var(--danger); border-color:rgba(224,108,117,.35); display:none;">■ Parar</button>
    </div>
    <div class="olm-tabs">
      <button class="olm-tab active" onclick="olmTab('models')">📦 Modelos instalados</button>
      <button class="olm-tab"        onclick="olmTab('pull')">⬇ Baixar modelo</button>
    </div>

    <!-- Aba: Modelos -->
    <div id="olm-pane-models" class="olm-pane active">
      <div id="olm-model-list" style="font-size:13px; color:var(--muted);">Carregando...</div>
      <div style="flex-shrink:0; padding-top:10px; border-top:1px solid var(--border);">
        <button onclick="olmLoadModels()" class="btn btn-outline btn-sm">↻ Atualizar</button>
      </div>
      <div id="olm-delete-status" style="font-size:12px; min-height:16px;"></div>
    </div>

    <!-- Aba: Baixar -->
    <div id="olm-pane-pull" class="olm-pane">
      <div class="olm-hint">
        Digite o nome do modelo no formato <code>nome:tag</code> — igual ao <code>ollama pull</code>.<br>
        Omitir a tag usa <code>latest</code>. Requer o serviço Ollama rodando.
      </div>
      <div style="display:flex; gap:8px;">
        <input id="olm-model-input" class="olm-input" type="text"
               placeholder="ex: gemma3:4b  ou  qwen2.5-coder:7b"
               onkeydown="if(event.key==='Enter') olmPull()">
        <button onclick="olmPull()" class="btn btn-primary btn-sm">⬇ Baixar</button>
      </div>
      <div id="olm-pull-status" style="font-size:13px; min-height:20px;"></div>
      <div>
        <div class="olm-hint" style="margin-bottom:4px;">Modelos populares (clique para preencher):</div>
        <div class="olm-chips">
          <span class="olm-chip" onclick="olmFill('gemma3:4b')">gemma3:4b</span>
          <span class="olm-chip" onclick="olmFill('gemma3:12b')">gemma3:12b</span>
          <span class="olm-chip" onclick="olmFill('qwen2.5-coder:7b')">qwen2.5-coder:7b</span>
          <span class="olm-chip" onclick="olmFill('llama3.2:3b')">llama3.2:3b</span>
          <span class="olm-chip" onclick="olmFill('mistral:7b')">mistral:7b</span>
          <span class="olm-chip" onclick="olmFill('phi4-mini')">phi4-mini</span>
          <span class="olm-chip" onclick="olmFill('deepseek-r1:7b')">deepseek-r1:7b</span>
        </div>
      </div>
    </div>
  </div>
</div>
<script>
(function() {
  var bbv   = '${bbv_base}';
  var modal = document.getElementById('ollama-modal');
  var _srvPoll = null;

  function olmApplySrvStatus(running) {
    var dot   = document.getElementById('olm-dot');
    var label = document.getElementById('olm-srv-label');
    dot.className = 'olm-dot ' + (running ? 'running' : 'stopped');
    label.textContent = running ? 'Serviço rodando' : 'Serviço parado';
    label.style.color = running ? '#3ddc84' : 'var(--muted)';
    document.getElementById('olm-btn-start').style.display = running ? 'none'        : 'inline-flex';
    document.getElementById('olm-btn-stop').style.display  = running ? 'inline-flex' : 'none';
  }
  function olmPollSrv() {
    fetch(bbv + '/execute\$./ollama-manage.sh service-status')
      .then(function(r) { return r.text(); })
      .then(function(s) { olmApplySrvStatus(s.trim() === 'running'); })
      .catch(function() {});
  }
  window.olmServiceStart = function() {
    var dot = document.getElementById('olm-dot');
    var lbl = document.getElementById('olm-srv-label');
    dot.className = 'olm-dot starting';
    lbl.textContent = 'Iniciando...'; lbl.style.color = '#ffb74d';
    document.getElementById('olm-btn-start').disabled = true;
    fetch(bbv + '/execute\$./ollama-manage.sh service-start')
      .then(function(r) { return r.text(); })
      .then(function(s) {
        document.getElementById('olm-btn-start').disabled = false;
        olmApplySrvStatus(s.trim() === 'running');
      });
  };
  window.olmServiceStop = function() {
    fetch(bbv + '/execute\$./ollama-manage.sh service-stop')
      .then(function() { olmPollSrv(); });
  };
  window.openOllamaModal = function() {
    modal.style.display = 'flex';
    requestAnimationFrame(function() { modal.classList.add('open'); });
    document.body.style.overflow = 'hidden';
    olmLoadModels();
    olmPollSrv();
  };
  window.closeOllamaModal = function() {
    modal.classList.remove('open');
    setTimeout(function() { modal.style.display = 'none'; }, 200);
    document.body.style.overflow = '';
  };
  window.olmTab = function(tab) {
    document.querySelectorAll('.olm-tab').forEach(function(b, i) {
      b.classList.toggle('active', ['models','pull'][i] === tab);
    });
    document.getElementById('olm-pane-models').classList.toggle('active', tab === 'models');
    document.getElementById('olm-pane-pull').classList.toggle('active', tab === 'pull');
  };
  window.olmLoadModels = function() {
    var out = document.getElementById('olm-model-list');
    out.innerHTML = '<span style="color:var(--muted);">Carregando...</span>';
    fetch(bbv + '/execute\$./ollama-manage.sh list')
      .then(function(r) { return r.text(); })
      .then(function(html) { out.innerHTML = html; })
      .catch(function(e) { out.textContent = 'Erro: ' + e; });
  };
  window.olmDelete = function(name) {
    if (!confirm('Remover o modelo "' + name + '"?\nIsso apaga o arquivo do disco.')) return;
    var st = document.getElementById('olm-delete-status');
    st.innerHTML = '<span style="color:var(--muted);">Removendo...</span>';
    fetch(bbv + '/execute\$./ollama-manage.sh delete ' + name)
      .then(function(r) { return r.text(); })
      .then(function(html) { st.innerHTML = html; olmLoadModels(); });
  };
  window.olmFill = function(name) {
    document.getElementById('olm-model-input').value = name;
    document.getElementById('olm-model-input').focus();
  };
  window.olmPull = function() {
    var model = document.getElementById('olm-model-input').value.trim();
    var st    = document.getElementById('olm-pull-status');
    if (!model) { st.innerHTML = '<span style="color:var(--danger);">Informe o nome do modelo.</span>'; return; }

    st.innerHTML = '<span style="color:var(--muted);">Conectando ao Ollama...</span>';

    fetch('http://localhost:11434/api/pull', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({name: model, stream: true})
    })
    .then(function(r) {
      if (!r.ok) throw new Error('Ollama não responde (status ' + r.status + '). Inicie o serviço primeiro.');
      var reader  = r.body.getReader();
      var decoder = new TextDecoder();
      var buf = '';
      function read() {
        reader.read().then(function(res) {
          if (res.done) {
            st.innerHTML = '<span style="color:#3ddc84;">✓ <strong>' + model + '</strong> pronto!</span>';
            olmLoadModels();
            return;
          }
          buf += decoder.decode(res.value, {stream: true});
          var lines = buf.split('\n');
          buf = lines.pop();
          lines.forEach(function(line) {
            if (!line.trim()) return;
            try {
              var obj = JSON.parse(line);
              if (obj.error) { st.innerHTML = '<span style="color:var(--danger);">✗ ' + obj.error + '</span>'; return; }
              var info = obj.status || '';
              var bar  = '';
              if (obj.total && obj.completed) {
                var pct   = Math.min(100, Math.round(obj.completed / obj.total * 100));
                var curGB = (obj.completed / 1073741824).toFixed(2);
                var totGB = (obj.total    / 1073741824).toFixed(2);
                info += ' — ' + curGB + ' / ' + totGB + ' GB (' + pct + '%)';
                bar   = '<div style="margin-top:6px;height:5px;background:var(--border);border-radius:3px;overflow:hidden;">'
                      + '<div style="height:5px;border-radius:3px;background:var(--primary);width:' + pct + '%;transition:width .3s;"></div></div>';
              }
              st.innerHTML = '<span style="color:var(--primary);">' + info + '</span>' + bar;
            } catch(e) {}
          });
          read();
        }).catch(function(e) {
          st.innerHTML = '<span style="color:var(--danger);">Conexão perdida: ' + e.message + '</span>';
        });
      }
      read();
    })
    .catch(function(e) {
      st.innerHTML = '<span style="color:var(--danger);">✗ ' + e.message + '</span>';
    });
  };
  document.addEventListener('keydown', function(e) { if (e.key === 'Escape') closeOllamaModal(); });
  document.getElementById('ollama-modal').addEventListener('click', function(e) {
    if (e.target === this) closeOllamaModal();
  });
})();
</script>
HTML
}

install_ollama() {
    step "Instalando Ollama (com suporte CUDA)..."
    if ! install_pkg ollama-cuda 2>/dev/null; then
        warn "ollama-cuda não disponível, tentando ollama..."
        if ! install_pkg ollama 2>/dev/null; then
            curl -fsSL https://ollama.ai/install.sh | sh
        fi
    fi

    step "Configurando Ollama (conexões externas + GPU NVIDIA)..."
    sudo mkdir -p /etc/systemd/system/ollama.service.d
    sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null <<'EOF'
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="LD_LIBRARY_PATH=/usr/lib/nvidia:/usr/lib"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/bin"
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable --now ollama.service 2>/dev/null || true
    log "Ollama instalado com suporte a GPU NVIDIA!"
    warn "Nenhum modelo foi baixado. Execute: ollama pull <modelo> (ex: ollama pull llama3)"
}
remove_ollama() {
    sudo systemctl stop ollama.service 2>/dev/null || true
    sudo systemctl disable ollama.service 2>/dev/null || true

    # Instalado via pacman/AUR ou via script curl
    if has_pkg ollama; then
        remove_pkg ollama
    else
        sudo rm -f /usr/local/bin/ollama
        sudo rm -f /etc/systemd/system/ollama.service
        sudo rm -rf /usr/share/ollama
    fi

    sudo rm -f /etc/systemd/system/ollama.service.d/override.conf
    sudo systemctl daemon-reload
    log "Ollama removido."
}
