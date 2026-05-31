#!/bin/bash

# Pi Code Harness App definition
APP_ID="pi-harness"
APP_NAME="Pi (Coding Harness)"
APP_DESC="Pi is a minimal terminal coding harness"
APP_TYPE="agent"

# Default status check is based on package presence

status_pi_harness() {
    has_pkg "pi" || has_cmd "pi"
}

# Default install logic
install_pi_harness() {
    if has_cmd "pi"; then
        ok "Pi já está instalado via binário."
        return 0
    fi
    step "Instalando Pi Coding Harness..."
    # Se não houver pacote, tenta o método curl como fallback
    if ! install_pkg "pi" 2>/dev/null; then
        warn "Pacote 'pi' não encontrado. Tentando instalação via curl..."
        curl -fsSL https://raw.githubusercontent.com/antirez/pi/master/install.sh | sh
    fi
}

# Default remove logic
remove_pi_harness() {
    step "Removendo Pi Coding Harness..."
    if has_pkg "pi"; then
        remove_pkg "pi"
    fi
    # Remove binário se foi instalado via curl/manual
    if [[ -f "$HOME/.local/bin/pi" ]]; then
        rm -f "$HOME/.local/bin/pi"
        ok "Binário ~/.local/bin/pi removido."
    elif [[ -f "/usr/local/bin/pi" ]]; then
        sudo rm -f "/usr/local/bin/pi"
        ok "Binário /usr/local/bin/pi removido."
    fi
}

manage_pi_harness() {
    local bbv_base="$1"
    echo "openPiModal()"
    cat << HTML
<!-- ── Modal Pi Harness ────────────────────────────────────────────── -->
<style>
  #pi-modal {
    display: none; position: fixed; inset: 0; z-index: 500;
    align-items: center; justify-content: center;
    background: rgba(0,0,0,0); backdrop-filter: blur(0px);
    transition: background .2s, backdrop-filter .2s;
  }
  #pi-modal.open {
    display: flex; background: rgba(0,0,0,.7); backdrop-filter: blur(3px);
  }
  #pi-modal .modal-panel {
    background: var(--surface); border: 1px solid var(--border);
    border-radius: var(--radius); width: min(580px, 92vw); max-height: 82vh;
    display: flex; flex-direction: column; overflow: hidden;
    box-shadow: 0 20px 60px rgba(0,0,0,.7);
    transform: scale(.96); opacity: 0; transition: transform .2s, opacity .2s;
  }
  #pi-modal.open .modal-panel { transform: scale(1); opacity: 1; }
  .pi-section { padding: 16px; border-bottom: 1px solid var(--border); }
  .pi-section:last-child { border-bottom: none; }
  .pi-label { font-size: 11px; color: var(--muted); text-transform: uppercase; letter-spacing: .5px; margin-bottom: 8px; font-weight: 600; }
  .pi-current { padding: 10px 14px; background: rgba(124,103,250,.08); border: 1px solid rgba(124,103,250,.2); border-radius: 6px; font-size: 13px; display: flex; align-items: center; gap: 8px; }
  .pi-btn-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-top: 10px; }
  .pi-hint { font-size: 11px; color: var(--muted); margin-top: 8px; line-height: 1.5; }
</style>

<div id="pi-modal">
  <div class="modal-panel">
    <div style="padding:14px 20px; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; gap:12px; flex-shrink:0;">
      <span style="font-weight:700; font-size:14px;">🥧 Pi Harness — Configuração de Backend</span>
      <button onclick="closePiModal()" style="background:none; border:none; color:var(--muted); font-size:18px; cursor:pointer; line-height:1; padding:0 4px;">✕</button>
    </div>

    <div class="pi-section">
      <div class="pi-label">Status Atual</div>
      <div class="pi-current">
        <span style="color:var(--muted);">Provedor:</span>
        <span id="pi-current-prov" style="font-weight:600; color:var(--primary);">Carregando...</span>
      </div>
    </div>

    <div class="pi-section">
      <div class="pi-label">Alternar Provedor Local</div>
      <div class="pi-btn-grid">
        <button onclick="piSetBackend('ollama')" class="btn btn-outline" style="justify-content:center; padding:12px;">🦙 Ollama</button>
        <button onclick="piSetBackend('llama-cpp')" class="btn btn-outline" style="justify-content:center; padding:12px;">🏗 Llama.cpp</button>
      </div>
      <div class="pi-hint">
        Isso configurará o Pi para usar a API local selecionada (OpenAI-compatible).<br>
        Certifique-se de que o servidor correspondente esteja rodando.
      </div>
    </div>

    <div class="pi-section" style="background: rgba(0,0,0,0.1);">
      <div style="display:flex; justify-content:space-between; align-items:center;">
        <span style="font-size:12px; color:var(--muted);">Limpar configurações personalizadas</span>
        <button onclick="piClear()" class="btn btn-sm btn-danger">Resetar Padrão</button>
      </div>
    </div>
    
    <div id="pi-status-msg" style="padding:10px 20px; font-size:12px; min-height:16px;"></div>
  </div>
</div>

<script>
(function() {
  var bbv = '${bbv_base}';
  var modal = document.getElementById('pi-modal');

  window.openPiModal = function() {
    modal.style.display = 'flex';
    requestAnimationFrame(function() { modal.classList.add('open'); });
    document.body.style.overflow = 'hidden';
    piLoadConfig();
  };

  window.closePiModal = function() {
    modal.classList.remove('open');
    setTimeout(function() { modal.style.display = 'none'; }, 200);
    document.body.style.overflow = '';
  };

  function piLoadConfig() {
    fetch(bbv + '/execute\$./pi-manage.sh get-config')
      .then(function(r) { return r.text(); })
      .then(function(t) { document.getElementById('pi-current-prov').textContent = t.trim(); });
  }

  window.piSetBackend = function(type) {
    var msg = document.getElementById('pi-status-msg');
    msg.innerHTML = '<span style="color:var(--muted);">Configurando...</span>';
    
    var endpoint = type === 'ollama' ? 'set-ollama' : 'set-llama-cpp';
    var model = type === 'ollama' ? 'llama3' : 'model';
    
    fetch(bbv + '/execute\$./pi-manage.sh ' + endpoint + ' ' + model)
      .then(function(r) { return r.text(); })
      .then(function(t) {
        msg.innerHTML = '<span style="color:#3ddc84;">' + t.trim() + '</span>';
        piLoadConfig();
      });
  };

  window.piClear = function() {
    if(!confirm('Deseja resetar as configurações do Pi para o padrão?')) return;
    fetch(bbv + '/execute\$./pi-manage.sh clear')
      .then(function() { piLoadConfig(); });
  };

  document.addEventListener('keydown', function(e) { if (e.key === 'Escape') closePiModal(); });
})();
</script>
HTML
}