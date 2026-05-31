#!/usr/bin/env bash
# categories/ai/llama-manage.sh
# Llama.cpp App definition - Redone from scratch

APP_ID="llama-cpp"
APP_NAME="Llama.cpp"
APP_DESC="Inferência de LLMs em C/C++ de alta performance — suporte a GGUF, CUDA e Vulkan"

# ── Status ────────────────────────────────────────────────────────────────────
status_llama_cpp() {
    # Verifica se o pacote AUR ou os binários principais estão presentes
    has_pkg "llama.cpp" || \
    has_pkg "llama.cpp-cuda" || \
    has_pkg "llama.cpp-vulkan" || \
    has_cmd "llama-cli" || \
    has_cmd "llama-server"
}

# ── Instalação ────────────────────────────────────────────────────────────────
install_llama_cpp() {
    step "Iniciando instalação do Llama.cpp..."

    # Detecta Hardware para escolher a melhor versão
    local gpu_type="cpu"
    if lspci | grep -iq "nvidia"; then
        gpu_type="cuda"
    elif lspci | grep -iq "amd" || lspci | grep -iq "ati" || lspci | grep -iq "intel"; then
        gpu_type="vulkan"
    fi

    case "$gpu_type" in
        cuda)
            log "GPU NVIDIA detectada. Tentando instalar versão com suporte CUDA..."
            if install_pkg "llama.cpp-cuda"; then
                ok "Llama.cpp (CUDA) instalado com sucesso!"
                return 0
            fi
            warn "Falha ao instalar versão CUDA. Tentando versão Vulkan..."
            ;& # Fallthrough para vulkan
        vulkan)
            log "Tentando instalar versão com suporte Vulkan..."
            if install_pkg "llama.cpp-vulkan"; then
                ok "Llama.cpp (Vulkan) instalado com sucesso!"
                return 0
            fi
            warn "Falha ao instalar versão Vulkan. Tentando versão base..."
            ;& # Fallthrough para base
        *)
            log "Instalando versão base (CPU/OpenBLAS)..."
            if install_pkg "llama.cpp"; then
                ok "Llama.cpp (Base) instalado com sucesso!"
                return 0
            fi
            ;;
    esac

    err "Não foi possível instalar o Llama.cpp via repositórios/AUR."
    return 1
}

# ── Remoção ───────────────────────────────────────────────────────────────────
remove_llama_cpp() {
    step "Removendo Llama.cpp e variantes..."
    
    # Tenta remover todas as variantes comuns do AUR
    remove_pkg "llama.cpp-cuda" 2>/dev/null
    remove_pkg "llama.cpp-vulkan" 2>/dev/null
    remove_pkg "llama.cpp" 2>/dev/null
    
    ok "Llama.cpp removido."
}

# ── Gerenciamento ─────────────────────────────────────────────────────────────
manage_llama_cpp() {
    local bbv_base="$1"
    echo "openLlamaModal()"
    cat << HTML
<!-- ── Modal Llama.cpp ────────────────────────────────────────────────── -->
<style>
  #llama-modal {
    display: none; position: fixed; inset: 0; z-index: 500;
    align-items: center; justify-content: center;
    background: rgba(0,0,0,0); backdrop-filter: blur(0px);
    transition: background .2s, backdrop-filter .2s;
  }
  #llama-modal.open {
    display: flex; background: rgba(0,0,0,.7); backdrop-filter: blur(3px);
  }
  #llama-modal .modal-panel {
    background: var(--surface); border: 1px solid var(--border);
    border-radius: var(--radius); width: min(680px, 92vw); max-height: 82vh;
    display: flex; flex-direction: column; overflow: hidden;
    box-shadow: 0 20px 60px rgba(0,0,0,.7);
    transform: scale(.96); opacity: 0; transition: transform .2s, opacity .2s;
  }
  #llama-modal.open .modal-panel { transform: scale(1); opacity: 1; }
  .llm-srv-bar { padding: 10px 16px; border-bottom: 1px solid var(--border);
                  display: flex; align-items: center; gap: 10px; flex-shrink: 0;
                  background: rgba(0,0,0,.18); }
  .llm-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
  .llm-dot.running { background: #3ddc84; box-shadow: 0 0 6px #3ddc84; }
  .llm-dot.stopped { background: var(--muted); }
  .llm-dot.starting { background: #ffb74d; animation: llm-blink .8s infinite; }
  @keyframes llm-blink { 0%,100%{opacity:1} 50%{opacity:.3} }
  .llm-pane { display: flex; flex: 1; overflow-y: auto; padding: 16px;
               flex-direction: column; gap: 12px; min-height: 0; }
  .selected-model { border-color: var(--primary) !important; background: rgba(124,103,250,.08) !important; }
  .llm-hint { font-size: 11px; color: var(--muted); line-height: 1.7; margin-bottom: 8px; }
</style>

<div id="llama-modal">
  <div class="modal-panel">
    <div style="padding:14px 20px; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; gap:12px; flex-shrink:0;">
      <span style="font-weight:700; font-size:14px;">🦙 Llama.cpp — Server & Modelos</span>
      <button onclick="closeLlamaModal()" style="background:none; border:none; color:var(--muted); font-size:18px; cursor:pointer; line-height:1; padding:0 4px;">✕</button>
    </div>
    
    <div class="llm-srv-bar">
      <div id="llm-dot" class="llm-dot stopped"></div>
      <span id="llm-srv-label" style="font-size:12px; color:var(--muted); flex:1;">Verificando servidor...</span>
      <button id="llm-btn-web" onclick="llmOpenWeb()" 
              class="btn btn-outline btn-sm" style="display:none; margin-right:4px; color:var(--primary); border-color:rgba(124,103,250,.35);">🌐 Abrir UI</button>
      <button id="llm-btn-start" onclick="llmServiceStart()"
              class="btn btn-primary btn-sm">▶ Iniciar Server</button>
      <button id="llm-btn-stop" onclick="llmServiceStop()"
              class="btn btn-outline btn-sm" style="color:var(--danger); border-color:rgba(224,108,117,.35); display:none;">■ Parar Server</button>
    </div>

    <div class="llm-pane">
      <div class="llm-hint">
        Coloque seus modelos <code>.gguf</code> em:<br>
        <code style="color:var(--primary); font-size:10px;">~/.local/share/llama.cpp/models</code>
      </div>
      
      <div style="font-weight:600; font-size:12px; color:var(--text); margin-bottom:4px;">Modelos GGUF Disponíveis:</div>
      <div id="llm-model-list" style="font-size:13px; color:var(--muted);">Carregando modelos...</div>
      
      <div id="llm-status-msg" style="font-size:12px; min-height:16px; margin-top:8px;"></div>
      
      <div style="flex-shrink:0; padding-top:10px; border-top:1px solid var(--border); display:flex; gap:8px;">
        <button onclick="llmLoadModels()" class="btn btn-outline btn-sm">↻ Atualizar Lista</button>
        <button id="llm-btn-autostart" onclick="llmToggleAutostart()" class="btn btn-outline btn-sm" title="Iniciar servidor automaticamente no boot">🚀 Autostart: ...</button>
        <div style="flex:1;"></div>
        <span style="font-size:11px; color:var(--muted); align-self:center;">Porta: 8080</span>
      </div>
    </div>
  </div>
</div>

<script>
(function() {
  var bbv = '${bbv_base}';
  var modal = document.getElementById('llama-modal');

  window.openLlamaModal = function() {
    modal.style.display = 'flex';
    requestAnimationFrame(function() { modal.classList.add('open'); });
    document.body.style.overflow = 'hidden';
    llmLoadModels();
    llmPollSrv();
    llmCheckAutostart();
  };

  window.closeLlamaModal = function() {
    modal.classList.remove('open');
    setTimeout(function() { modal.style.display = 'none'; }, 200);
    document.body.style.overflow = '';
  };

  window.llmCheckAutostart = function() {
    fetch(bbv + '/execute\$./llama-manage.sh autostart-status')
      .then(function(r) { return r.text(); })
      .then(function(s) {
        var btn = document.getElementById('llm-btn-autostart');
        var enabled = s.trim() === 'enabled';
        btn.innerHTML = '🚀 Autostart: ' + (enabled ? '<span style="color:#3ddc84;font-weight:bold;">ON</span>' : '<span style="color:var(--muted);">OFF</span>');
      });
  };

  window.llmToggleAutostart = function() {
    var btn = document.getElementById('llm-btn-autostart');
    btn.innerHTML = '🚀 Autostart: <span style="color:var(--muted);">...</span>';
    fetch(bbv + '/execute\$./llama-manage.sh autostart-toggle')
      .then(function(r) { return r.text(); })
      .then(function() {
        llmCheckAutostart();
      });
  };

  function llmApplySrvStatus(running) {
    var dot = document.getElementById('llm-dot');
    var label = document.getElementById('llm-srv-label');
    dot.className = 'llm-dot ' + (running ? 'running' : 'stopped');
    label.textContent = running ? 'Servidor rodando (Porta 8080)' : 'Servidor parado';
    label.style.color = running ? '#3ddc84' : 'var(--muted)';
    document.getElementById('llm-btn-start').style.display = running ? 'none' : 'inline-flex';
    document.getElementById('llm-btn-stop').style.display = running ? 'inline-flex' : 'none';
    document.getElementById('llm-btn-web').style.display = running ? 'inline-flex' : 'none';
  }

  window.llmOpenWeb = function() {
    fetch(bbv + '/execute\$./launch.sh http://127.0.0.1:8080');
  };

  window.llmPollSrv = function() {
    fetch(bbv + '/execute\$./llama-manage.sh service-status')
      .then(function(r) { return r.text(); })
      .then(function(s) { llmApplySrvStatus(s.trim() === 'running'); })
      .catch(function() {});
  };

  window.llmServiceStart = function() {
    var dot = document.getElementById('llm-dot');
    var lbl = document.getElementById('llm-srv-label');
    dot.className = 'llm-dot starting';
    lbl.textContent = 'Iniciando servidor...';
    
    fetch(bbv + '/execute\$./llama-manage.sh service-start')
      .then(function(r) { return r.text(); })
      .then(function(s) {
        var res = s.trim();
        if (res === 'error_no_model') {
           document.getElementById('llm-status-msg').innerHTML = '<span style="color:var(--danger);">Erro: Selecione um modelo antes de iniciar.</span>';
           llmApplySrvStatus(false);
        } else {
           llmApplySrvStatus(res === 'running');
        }
      });
  };

  window.llmServiceStop = function() {
    fetch(bbv + '/execute\$./llama-manage.sh service-stop')
      .then(function() { llmPollSrv(); });
  };

  window.llmLoadModels = function() {
    var out = document.getElementById('llm-model-list');
    out.innerHTML = '<span style="color:var(--muted);">Carregando...</span>';
    fetch(bbv + '/execute\$./llama-manage.sh list')
      .then(function(r) { return r.text(); })
      .then(function(html) { out.innerHTML = html; })
      .catch(function(e) { out.textContent = 'Erro ao carregar modelos.'; });
  };

  window.llmSetActive = function(name) {
    var st = document.getElementById('llm-status-msg');
    st.innerHTML = '<span style="color:var(--muted);">Selecionando...</span>';
    fetch(bbv + '/execute\$./llama-manage.sh set-active ' + encodeURIComponent(name))
      .then(function(r) { return r.text(); })
      .then(function(html) {
        st.innerHTML = html;
        llmLoadModels();
      });
  };

  window.llmDelete = function(name) {
    if (!confirm('Excluir o arquivo "' + name + '" permanentemente?')) return;
    fetch(bbv + '/execute\$./llama-manage.sh delete ' + encodeURIComponent(name))
      .then(function() { llmLoadModels(); });
  };

  document.addEventListener('keydown', function(e) { if (e.key === 'Escape') closeLlamaModal(); });
})();
</script>
HTML
}

