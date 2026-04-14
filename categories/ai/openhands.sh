#!/usr/bin/env bash
APP_ID="openhands"
APP_NAME="OpenHands"
APP_DESC="Agente de desenvolvimento de software com IA — executa tarefas em sandbox Docker"

OH_IMAGE="ghcr.io/all-hands-ai/openhands:latest"
OH_BASE_IMAGE="nikolaik/python-nodejs:python3.12-nodejs22"
OH_CONTAINER="openhands-app"
OH_STATE="$HOME/.openhands-state"

status_openhands() {
    has_cmd "docker" || return 1
    # Tenta sem sudo (grupo docker), cai em sudo se necessário
    { docker image ls --format '{{.Repository}}' 2>/dev/null \
      || sudo docker image ls --format '{{.Repository}}' 2>/dev/null; } \
    | grep -q "openhands"
}

launch_openhands() { echo "http://localhost:13000"; }

install_openhands() {
    step "Verificando Docker..."
    if ! has_cmd "docker"; then
        install_pkg docker || { err "Falha ao instalar Docker."; return 1; }
    fi

    step "Criando diretório de estado..."
    mkdir -p "$OH_STATE"

    # Todas as operações privilegiadas em um único sudo para pedir senha só uma vez.
    # O ambiente BigBashView não tem TTY, então sudo não armazena credenciais entre
    # chamadas separadas — cada sudo distinto pede senha novamente.
    step "Configurando Docker, baixando imagens e iniciando container..."
    warn "Este passo pode demorar vários minutos (download das imagens)."
    sudo bash -c "
        set -e
        systemctl enable --now docker.service
        usermod -aG docker '${USER}'
        echo '[+] Baixando imagem base do runtime...'
        docker pull '${OH_BASE_IMAGE}'
        echo '[+] Baixando OpenHands...'
        docker pull '${OH_IMAGE}'
        docker stop '${OH_CONTAINER}' 2>/dev/null || true
        docker rm   '${OH_CONTAINER}' 2>/dev/null || true
        docker run -d \
            --name '${OH_CONTAINER}' \
            --restart always \
            -e SANDBOX_BASE_CONTAINER_IMAGE='${OH_BASE_IMAGE}' \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v '${OH_STATE}:/.openhands-state' \
            -v '${OH_STATE}/.openhands:/.openhands' \
            -p 13000:3000 \
            --add-host host.docker.internal:host-gateway \
            '${OH_IMAGE}'
    " || { err "Falha ao configurar/iniciar o OpenHands."; return 1; }
    log "Usuário adicionado ao grupo 'docker' (efetivo após novo login)."

    step "Criando lançador..."
    mkdir -p "$HOME/.local/share/applications"
    cat > "$HOME/.local/share/applications/openhands.desktop" << 'DESKTOP'
[Desktop Entry]
Name=OpenHands
Comment=Agente de desenvolvimento de software com IA
Exec=xdg-open http://localhost:13000
Icon=internet-web-browser
Terminal=false
Type=Application
Categories=Development;Utility;
DESKTOP

    log "OpenHands instalado! Acesse em http://localhost:13000"
    warn "Configure o LLM provider via o botão ⚙ antes de usar."
}

manage_openhands() {
    local bbv_base="$1"
    echo "openOpenHandsModal()"
    cat << 'HTML'
<!-- ── Modal OpenHands ──────────────────────────────────────────────── -->
<style>
  #openhands-modal {
    display: none; position: fixed; inset: 0; z-index: 500;
    align-items: center; justify-content: center;
    background: rgba(0,0,0,0); backdrop-filter: blur(0px);
    transition: background .2s, backdrop-filter .2s;
  }
  #openhands-modal.open {
    display: flex; background: rgba(0,0,0,.7); backdrop-filter: blur(3px);
  }
  #openhands-modal .modal-panel {
    background: var(--surface); border: 1px solid var(--border);
    border-radius: var(--radius); width: min(640px, 92vw); max-height: 84vh;
    display: flex; flex-direction: column; overflow: hidden;
    box-shadow: 0 20px 60px rgba(0,0,0,.7);
    transform: scale(.96); opacity: 0; transition: transform .2s, opacity .2s;
  }
  #openhands-modal.open .modal-panel { transform: scale(1); opacity: 1; }
  .ohd-srv-bar { padding: 10px 16px; border-bottom: 1px solid var(--border);
                  display: flex; align-items: center; gap: 10px; flex-shrink: 0;
                  background: rgba(0,0,0,.18); }
  .ohd-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
  .ohd-dot.running { background: #3ddc84; box-shadow: 0 0 6px #3ddc84; }
  .ohd-dot.stopped { background: var(--muted); }
  .ohd-dot.starting { background: #ffb74d; animation: ohd-blink .8s infinite; }
  @keyframes ohd-blink { 0%,100%{opacity:1} 50%{opacity:.3} }
  .ohd-tabs { display: flex; gap: 4px; padding: 8px 16px; border-bottom: 1px solid var(--border); flex-shrink: 0; flex-wrap: wrap; }
  .ohd-tab  { padding: 5px 14px; border-radius: 6px; border: 1px solid transparent; cursor: pointer;
               font-size: 13px; background: none; color: var(--muted); transition: all .15s; }
  .ohd-tab.active { background: rgba(124,103,250,.18); color: var(--primary); border-color: rgba(124,103,250,.3); }
  .ohd-tab:hover:not(.active) { background: rgba(255,255,255,.05); color: var(--text); }
  .ohd-pane { display: none; flex: 1; overflow-y: auto; padding: 16px;
               flex-direction: column; gap: 12px; min-height: 0; }
  .ohd-pane.active { display: flex; }
  .ohd-row { display: flex; align-items: center; gap: 10px; padding: 8px 12px;
              background: var(--card); border-radius: 6px; border: 1px solid var(--border); }
  .ohd-sel { background: rgba(124,103,250,.15); border: none; color: var(--primary);
              border-radius: 4px; padding: 3px 9px; cursor: pointer; font-size: 12px;
              transition: background .15s; flex-shrink: 0; }
  .ohd-sel:hover { background: rgba(124,103,250,.3); }
  .ohd-input { flex: 1; background: var(--card); border: 1px solid var(--border);
                border-radius: 6px; padding: 8px 10px; color: var(--text);
                font-size: 13px; outline: none; transition: border-color .15s; }
  .ohd-input:focus { border-color: var(--primary); }
  .ohd-hint { font-size: 11px; color: var(--muted); line-height: 1.7; }
  .ohd-current { padding: 10px 14px; background: rgba(124,103,250,.08);
                  border: 1px solid rgba(124,103,250,.2); border-radius: 6px;
                  font-size: 12px; }
  .ohd-section { font-size: 11px; color: var(--muted); text-transform: uppercase;
                  letter-spacing: .05em; margin-bottom: 4px; }
  .ohd-key-row { display: flex; gap: 8px; align-items: center; }
</style>
<div id="openhands-modal">
  <div class="modal-panel">
    <div style="padding:14px 20px; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; gap:12px; flex-shrink:0;">
      <span style="font-weight:700; font-size:14px;">🙌 OpenHands — Configuração</span>
      <button onclick="closeOpenHandsModal()" style="background:none; border:none; color:var(--muted); font-size:18px; cursor:pointer; line-height:1; padding:0 4px;">✕</button>
    </div>

    <!-- Barra de serviço -->
    <div class="ohd-srv-bar">
      <div id="ohd-dot" class="ohd-dot stopped"></div>
      <span id="ohd-srv-label" style="font-size:12px; color:var(--muted); flex:1;">Verificando...</span>
      <button id="ohd-open-btn" onclick="ohdOpen()"
         class="btn btn-outline btn-sm" style="color:var(--primary); border-color:rgba(124,103,250,.35); display:none;">↗ Abrir</button>
      <button id="ohd-btn-start" onclick="ohdServiceStart()"
              class="btn btn-outline btn-sm" style="color:var(--success); border-color:rgba(61,220,132,.35);">▶ Iniciar</button>
      <button id="ohd-btn-stop" onclick="ohdServiceStop()"
              class="btn btn-outline btn-sm" style="color:var(--danger); border-color:rgba(224,108,117,.35); display:none;">■ Parar</button>
    </div>

    <!-- Config atual -->
    <div style="padding:10px 16px; border-bottom:1px solid var(--border); flex-shrink:0;">
      <div class="ohd-current">
        <span style="color:var(--muted);">LLM atual: </span>
        <span id="ohd-current-cfg">Carregando...</span>
      </div>
    </div>

    <div class="ohd-tabs">
      <button class="ohd-tab active" onclick="ohdTab('anthropic')">Anthropic</button>
      <button class="ohd-tab"        onclick="ohdTab('openai')">OpenAI</button>
      <button class="ohd-tab"        onclick="ohdTab('ollama')">🦙 Ollama</button>
      <button class="ohd-tab"        onclick="ohdTab('groq')">Groq</button>
      <button class="ohd-tab"        onclick="ohdTab('custom')">✏ Custom</button>
    </div>

    <!-- Aba: Anthropic -->
    <div id="ohd-pane-anthropic" class="ohd-pane active">
      <div class="ohd-hint">Selecione um modelo Claude. A chave é salva em <code>~/.openhands-state/config.toml</code>.</div>
      <div style="display:flex;flex-direction:column;gap:6px;">
        <div class="ohd-row">
          <span style="flex:1;font-family:monospace;font-size:13px;">claude-opus-4-5 <span style="color:var(--muted);font-size:11px;">(mais capaz)</span></span>
          <button class="ohd-sel" onclick="ohdSetLLM('anthropic','anthropic/claude-opus-4-5')">✓ Usar</button>
        </div>
        <div class="ohd-row">
          <span style="flex:1;font-family:monospace;font-size:13px;">claude-sonnet-4-5 <span style="color:var(--muted);font-size:11px;">(equilibrado)</span></span>
          <button class="ohd-sel" onclick="ohdSetLLM('anthropic','anthropic/claude-sonnet-4-5')">✓ Usar</button>
        </div>
        <div class="ohd-row">
          <span style="flex:1;font-family:monospace;font-size:13px;">claude-haiku-4-5 <span style="color:var(--muted);font-size:11px;">(mais rápido)</span></span>
          <button class="ohd-sel" onclick="ohdSetLLM('anthropic','anthropic/claude-haiku-4-5')">✓ Usar</button>
        </div>
      </div>
      <div>
        <div class="ohd-section">API Key</div>
        <div class="ohd-key-row">
          <input id="ohd-anthropic-key" class="ohd-input" type="password" placeholder="sk-ant-api03-...">
          <button onclick="ohdSaveKey('ANTHROPIC_API_KEY', document.getElementById('ohd-anthropic-key').value)" class="btn btn-outline btn-sm">✓ Salvar</button>
        </div>
      </div>
    </div>

    <!-- Aba: OpenAI -->
    <div id="ohd-pane-openai" class="ohd-pane">
      <div class="ohd-hint">Modelos da OpenAI via API.</div>
      <div style="display:flex;flex-direction:column;gap:6px;">
        <div class="ohd-row">
          <span style="flex:1;font-family:monospace;font-size:13px;">gpt-4o</span>
          <button class="ohd-sel" onclick="ohdSetLLM('openai','openai/gpt-4o')">✓ Usar</button>
        </div>
        <div class="ohd-row">
          <span style="flex:1;font-family:monospace;font-size:13px;">gpt-4o-mini <span style="color:var(--muted);font-size:11px;">(mais barato)</span></span>
          <button class="ohd-sel" onclick="ohdSetLLM('openai','openai/gpt-4o-mini')">✓ Usar</button>
        </div>
      </div>
      <div>
        <div class="ohd-section">API Key</div>
        <div class="ohd-key-row">
          <input id="ohd-openai-key" class="ohd-input" type="password" placeholder="sk-...">
          <button onclick="ohdSaveKey('OPENAI_API_KEY', document.getElementById('ohd-openai-key').value)" class="btn btn-outline btn-sm">✓ Salvar</button>
        </div>
      </div>
    </div>

    <!-- Aba: Ollama -->
    <div id="ohd-pane-ollama" class="ohd-pane">
      <div class="ohd-hint">Usa modelos locais via Ollama — nenhuma API Key necessária. O container acessa o host via <code>host.docker.internal:11434</code>.</div>
      <div id="ohd-ollama-list" style="font-size:13px; color:var(--muted);">Carregando...</div>
      <div style="flex-shrink:0; padding-top:8px; border-top:1px solid var(--border);">
        <button onclick="ohdLoadOllama()" class="btn btn-outline btn-sm">↻ Atualizar</button>
      </div>
    </div>

    <!-- Aba: Groq -->
    <div id="ohd-pane-groq" class="ohd-pane">
      <div class="ohd-hint">Inferência rápida e gratuita via Groq.</div>
      <div style="display:flex;flex-direction:column;gap:6px;">
        <div class="ohd-row">
          <span style="flex:1;font-family:monospace;font-size:13px;">llama3-70b-8192</span>
          <button class="ohd-sel" onclick="ohdSetLLM('groq','groq/llama3-70b-8192')">✓ Usar</button>
        </div>
        <div class="ohd-row">
          <span style="flex:1;font-family:monospace;font-size:13px;">llama3-8b-8192 <span style="color:var(--muted);font-size:11px;">(rápido)</span></span>
          <button class="ohd-sel" onclick="ohdSetLLM('groq','groq/llama3-8b-8192')">✓ Usar</button>
        </div>
      </div>
      <div>
        <div class="ohd-section">API Key</div>
        <div class="ohd-key-row">
          <input id="ohd-groq-key" class="ohd-input" type="password" placeholder="gsk_...">
          <button onclick="ohdSaveKey('GROQ_API_KEY', document.getElementById('ohd-groq-key').value)" class="btn btn-outline btn-sm">✓ Salvar</button>
        </div>
      </div>
    </div>

    <!-- Aba: Custom -->
    <div id="ohd-pane-custom" class="ohd-pane">
      <div class="ohd-hint">
        Informe o modelo no formato <code>provider/modelo</code>.<br>
        Exemplos: <code>anthropic/claude-sonnet-4-5</code> · <code>ollama/qwen2.5-coder:7b</code> · <code>openrouter/deepseek/deepseek-r1</code>
      </div>
      <div style="display:flex; gap:8px;">
        <input id="ohd-custom-model" class="ohd-input" type="text" placeholder="provider/modelo"
               onkeydown="if(event.key==='Enter') ohdSetCustom()">
        <button onclick="ohdSetCustom()" class="btn btn-primary btn-sm">✓ Salvar</button>
      </div>
      <div id="ohd-custom-status" style="font-size:13px; min-height:20px;"></div>
    </div>

    <div id="ohd-set-status" style="font-size:12px; min-height:16px; padding:8px 16px; flex-shrink:0;"></div>
  </div>
</div>
HTML
    cat << SCRIPT
<script>
(function() {
  var bbv   = '${bbv_base}';
  var modal = document.getElementById('openhands-modal');
  var TABS  = ['anthropic','openai','ollama','groq','custom'];

  function ohdApplySrvStatus(running) {
    var dot   = document.getElementById('ohd-dot');
    var label = document.getElementById('ohd-srv-label');
    dot.className = 'ohd-dot ' + (running ? 'running' : 'stopped');
    label.textContent = running ? 'Container rodando' : 'Container parado';
    label.style.color = running ? '#3ddc84' : 'var(--muted)';
    document.getElementById('ohd-btn-start').style.display = running ? 'none'        : 'inline-flex';
    document.getElementById('ohd-btn-stop').style.display  = running ? 'inline-flex' : 'none';
    document.getElementById('ohd-open-btn').style.display  = running ? 'inline-flex' : 'none';
  }
  function ohdPollSrv() {
    fetch(bbv + '/execute\$./openhands-manage.sh service-status')
      .then(function(r) { return r.text(); })
      .then(function(s) { ohdApplySrvStatus(s.trim() === 'running'); })
      .catch(function() {});
  }
  window.ohdServiceStart = function() {
    var dot = document.getElementById('ohd-dot');
    var lbl = document.getElementById('ohd-srv-label');
    dot.className = 'ohd-dot starting';
    lbl.textContent = 'Iniciando...'; lbl.style.color = '#ffb74d';
    document.getElementById('ohd-btn-start').disabled = true;
    fetch(bbv + '/execute\$./openhands-manage.sh service-start')
      .then(function(r) { return r.text(); })
      .then(function(s) {
        document.getElementById('ohd-btn-start').disabled = false;
        ohdApplySrvStatus(s.trim() === 'running');
      });
  };
  window.ohdServiceStop = function() {
    fetch(bbv + '/execute\$./openhands-manage.sh service-stop')
      .then(function() { ohdPollSrv(); });
  };
  window.ohdOpen = function() {
    fetch(bbv + '/execute\$./launch.sh http://localhost:13000');
  };
  window.openOpenHandsModal = function() {
    modal.style.display = 'flex';
    requestAnimationFrame(function() { modal.classList.add('open'); });
    document.body.style.overflow = 'hidden';
    ohdLoadCurrent();
    ohdPollSrv();
    ohdLoadOllama();
  };
  window.closeOpenHandsModal = function() {
    modal.classList.remove('open');
    setTimeout(function() { modal.style.display = 'none'; }, 200);
    document.body.style.overflow = '';
  };
  window.ohdTab = function(tab) {
    document.querySelectorAll('.ohd-tab').forEach(function(b, i) {
      b.classList.toggle('active', TABS[i] === tab);
    });
    TABS.forEach(function(t) {
      document.getElementById('ohd-pane-' + t).classList.toggle('active', t === tab);
    });
    if (tab === 'ollama') ohdLoadOllama();
  };
  function ohdLoadCurrent() {
    fetch(bbv + '/execute\$./openhands-manage.sh get-config')
      .then(function(r) { return r.text(); })
      .then(function(html) { document.getElementById('ohd-current-cfg').innerHTML = html; })
      .catch(function() {});
  }
  window.ohdLoadOllama = function() {
    var out = document.getElementById('ohd-ollama-list');
    out.innerHTML = '<span style="color:var(--muted);">Carregando...</span>';
    fetch(bbv + '/execute\$./openhands-manage.sh list-ollama')
      .then(function(r) { return r.text(); })
      .then(function(html) { out.innerHTML = html; })
      .catch(function(e) { out.textContent = 'Erro: ' + e; });
  };
  window.ohdSetLLM = function(provider, model) {
    var st = document.getElementById('ohd-set-status');
    st.innerHTML = '<span style="color:var(--muted);">Salvando...</span>';
    fetch(bbv + '/execute\$./openhands-manage.sh set-llm ' +
          encodeURIComponent(provider) + ' ' + encodeURIComponent(model))
      .then(function(r) { return r.text(); })
      .then(function(html) { st.innerHTML = html; ohdLoadCurrent(); });
  };
  window.ohdSaveKey = function(keyName, keyVal) {
    var st = document.getElementById('ohd-set-status');
    if (!keyVal.trim()) { st.innerHTML = '<span style="color:var(--danger);">Informe a API Key.</span>'; return; }
    st.innerHTML = '<span style="color:var(--muted);">Salvando chave...</span>';
    fetch(bbv + '/execute\$./openhands-manage.sh set-key ' +
          encodeURIComponent(keyName) + ' ' + encodeURIComponent(keyVal))
      .then(function(r) { return r.text(); })
      .then(function(html) { st.innerHTML = html; });
  };
  window.ohdSetCustom = function() {
    var model = document.getElementById('ohd-custom-model').value.trim();
    var st    = document.getElementById('ohd-custom-status');
    if (!model) { st.innerHTML = '<span style="color:var(--danger);">Informe o modelo.</span>'; return; }
    var provider = model.split('/')[0] || 'custom';
    st.innerHTML = '<span style="color:var(--muted);">Salvando...</span>';
    fetch(bbv + '/execute\$./openhands-manage.sh set-llm ' +
          encodeURIComponent(provider) + ' ' + encodeURIComponent(model))
      .then(function(r) { return r.text(); })
      .then(function(html) {
        st.innerHTML = html;
        document.getElementById('ohd-set-status').innerHTML = html;
        ohdLoadCurrent();
      });
  };
  document.addEventListener('keydown', function(e) { if (e.key === 'Escape') closeOpenHandsModal(); });
  document.getElementById('openhands-modal').addEventListener('click', function(e) {
    if (e.target === this) closeOpenHandsModal();
  });
})();
</script>
SCRIPT
}

remove_openhands() {
    step "Parando e removendo containers..."
    sudo bash -c "
        docker stop '${OH_CONTAINER}' 2>/dev/null || true
        docker rm   '${OH_CONTAINER}' 2>/dev/null || true
        docker ps -a --format '{{.Names}}' | grep '^openhands-runtime-' \
            | xargs -r docker rm -f
    "

    step "Removendo imagens..."
    sudo bash -c "
        docker rmi '${OH_IMAGE}' 2>/dev/null || true
        docker rmi '${OH_BASE_IMAGE}' 2>/dev/null || true
        docker images --format '{{.Repository}}:{{.Tag}}' \
            | grep 'all-hands-ai/runtime' \
            | xargs -r docker rmi -f
    "

    step "Removendo estado e dados..."
    sudo rm -rf "${OH_STATE}"

    step "Removendo lançador..."
    rm -f "$HOME/.local/share/applications/openhands.desktop"

    log "OpenHands removido por completo."
}
