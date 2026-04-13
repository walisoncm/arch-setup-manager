#!/usr/bin/env bash
APP_ID="goose"
APP_NAME="Goose"
APP_DESC="Agente de IA local open-source da Block — suporta Claude, GPT, Ollama e outros"

status_goose() {
    has_cmd "goose" || test -x "$HOME/.local/bin/goose"
}

install_goose() {
    export PATH="$HOME/.local/bin:$PATH"
    if getent passwd "$USER" | grep -q fish; then
        fish -c "fish_add_path '$HOME/.local/bin'" 2>/dev/null || true
    fi

    # Tenta AUR primeiro (binário pré-compilado)
    if need_aur; then
        step "Tentando instalar Goose via AUR..."
        if $AUR -S --needed --noconfirm goose-cli-bin 2>/dev/null || \
           $AUR -S --needed --noconfirm goose-ai-bin 2>/dev/null; then
            has_cmd "goose" && { log "Goose instalado via AUR!"; _goose_post_install; return 0; }
        fi
        warn "Pacote AUR não encontrado, usando script oficial..."
    fi

    # Script oficial de instalação (releases do GitHub)
    step "Baixando e instalando Goose via script oficial..."
    mkdir -p "$HOME/.local/bin"
    if curl -fsSL https://github.com/block/goose/releases/latest/download/download_cli.sh \
            -o /tmp/goose-install.sh; then
        GOOSE_BINARY_PATH="$HOME/.local/bin" bash /tmp/goose-install.sh
        rm -f /tmp/goose-install.sh
    else
        err "Falha ao baixar o script de instalação do Goose."
        return 1
    fi

    if has_cmd "goose"; then
        log "Goose instalado! Execute: goose"
        _goose_post_install
    else
        err "Instalação concluída, mas 'goose' não encontrado no PATH."
        warn "Tente executar: export PATH=\"\$HOME/.local/bin:\$PATH\""
        return 1
    fi
}

_goose_post_install() {
    # Cria config mínima se ainda não existir
    local conf="$HOME/.config/goose/config.yaml"
    if [[ ! -f "$conf" ]]; then
        mkdir -p "$(dirname "$conf")"
        cat > "$conf" << 'EOF'
# Goose configuration
# provider: anthropic | openai | ollama | groq | google
# model: nome do modelo correspondente ao provider
#
# Exemplo Anthropic:
#   provider: anthropic
#   model: claude-sonnet-4-5
#   ANTHROPIC_API_KEY: sk-ant-...
#
# Exemplo Ollama (local, sem chave):
#   provider: ollama
#   model: llama3.2:3b
EOF
        log "Arquivo de configuração criado em ~/.config/goose/config.yaml"
    fi
    warn "Configure o provider e modelo via o botão ⚙ ou editando ~/.config/goose/config.yaml"
}

manage_goose() {
    local bbv_base="$1"
    echo "openGooseModal()"
    cat << 'HTML'
<!-- ── Modal Goose ──────────────────────────────────────────────────── -->
<style>
  #goose-modal {
    display: none; position: fixed; inset: 0; z-index: 500;
    align-items: center; justify-content: center;
    background: rgba(0,0,0,0); backdrop-filter: blur(0px);
    transition: background .2s, backdrop-filter .2s;
  }
  #goose-modal.open {
    display: flex; background: rgba(0,0,0,.7); backdrop-filter: blur(3px);
  }
  #goose-modal .modal-panel {
    background: var(--surface); border: 1px solid var(--border);
    border-radius: var(--radius); width: min(640px, 92vw); max-height: 84vh;
    display: flex; flex-direction: column; overflow: hidden;
    box-shadow: 0 20px 60px rgba(0,0,0,.7);
    transform: scale(.96); opacity: 0; transition: transform .2s, opacity .2s;
  }
  #goose-modal.open .modal-panel { transform: scale(1); opacity: 1; }
  .gse-tabs { display: flex; gap: 4px; padding: 8px 16px; border-bottom: 1px solid var(--border); flex-shrink: 0; flex-wrap: wrap; }
  .gse-tab  { padding: 5px 14px; border-radius: 6px; border: 1px solid transparent; cursor: pointer;
               font-size: 13px; background: none; color: var(--muted); transition: all .15s; }
  .gse-tab.active { background: rgba(124,103,250,.18); color: var(--primary); border-color: rgba(124,103,250,.3); }
  .gse-tab:hover:not(.active) { background: rgba(255,255,255,.05); color: var(--text); }
  .gse-pane { display: none; flex: 1; overflow-y: auto; padding: 16px;
               flex-direction: column; gap: 12px; min-height: 0; }
  .gse-pane.active { display: flex; }
  .gse-row { display: flex; align-items: center; gap: 10px; padding: 8px 12px;
              background: var(--card); border-radius: 6px; border: 1px solid var(--border); }
  .gse-sel { background: rgba(124,103,250,.15); border: none; color: var(--primary);
              border-radius: 4px; padding: 3px 9px; cursor: pointer; font-size: 12px;
              transition: background .15s; flex-shrink: 0; }
  .gse-sel:hover { background: rgba(124,103,250,.3); }
  .gse-input { flex: 1; background: var(--card); border: 1px solid var(--border);
                border-radius: 6px; padding: 8px 10px; color: var(--text);
                font-size: 13px; outline: none; transition: border-color .15s; }
  .gse-input:focus { border-color: var(--primary); }
  .gse-key-row { display: flex; gap: 8px; align-items: center; }
  .gse-hint { font-size: 11px; color: var(--muted); line-height: 1.7; }
  .gse-current { padding: 10px 14px; background: rgba(124,103,250,.08);
                  border: 1px solid rgba(124,103,250,.2); border-radius: 6px;
                  font-size: 12px; display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
  .gse-section { font-size: 11px; color: var(--muted); text-transform: uppercase;
                  letter-spacing: .05em; margin-bottom: 4px; }
</style>
<div id="goose-modal">
  <div class="modal-panel">
    <div style="padding:14px 20px; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; gap:12px; flex-shrink:0;">
      <span style="font-weight:700; font-size:14px;">🪿 Goose — Configuração</span>
      <button onclick="closeGooseModal()" style="background:none; border:none; color:var(--muted); font-size:18px; cursor:pointer; line-height:1; padding:0 4px;">✕</button>
    </div>
    <div style="padding:10px 16px; border-bottom:1px solid var(--border); flex-shrink:0;">
      <div class="gse-current">
        <span style="color:var(--muted); flex-shrink:0;">Atual:</span>
        <span id="gse-current-cfg" style="flex:1;">Carregando...</span>
        <button onclick="gseClearConfig()" class="btn btn-outline btn-sm" style="color:var(--muted); font-size:11px; padding:2px 8px;">✕ Limpar</button>
      </div>
    </div>
    <div class="gse-tabs">
      <button class="gse-tab active" onclick="gseTab('anthropic')">Anthropic</button>
      <button class="gse-tab"        onclick="gseTab('openai')">OpenAI</button>
      <button class="gse-tab"        onclick="gseTab('ollama')">🦙 Ollama</button>
      <button class="gse-tab"        onclick="gseTab('groq')">Groq</button>
      <button class="gse-tab"        onclick="gseTab('custom')">✏ Custom</button>
    </div>

    <!-- Aba: Anthropic -->
    <div id="gse-pane-anthropic" class="gse-pane active">
      <div class="gse-hint">Selecione um modelo Claude e informe sua API Key da Anthropic.</div>
      <div style="display:flex;flex-direction:column;gap:6px;" id="gse-anthropic-models">
        <div class="gse-row" id="gse-arow-claude-opus-4-5">
          <span style="flex:1;font-family:monospace;font-size:13px;">claude-opus-4-5 <span style="color:var(--muted);font-size:11px;">(mais capaz)</span></span>
          <button class="gse-sel" onclick="gseSetProvider('anthropic','claude-opus-4-5')">✓ Usar</button>
        </div>
        <div class="gse-row" id="gse-arow-claude-sonnet-4-5">
          <span style="flex:1;font-family:monospace;font-size:13px;">claude-sonnet-4-5 <span style="color:var(--muted);font-size:11px;">(equilibrado)</span></span>
          <button class="gse-sel" onclick="gseSetProvider('anthropic','claude-sonnet-4-5')">✓ Usar</button>
        </div>
        <div class="gse-row" id="gse-arow-claude-haiku-4-5">
          <span style="flex:1;font-family:monospace;font-size:13px;">claude-haiku-4-5 <span style="color:var(--muted);font-size:11px;">(mais rápido)</span></span>
          <button class="gse-sel" onclick="gseSetProvider('anthropic','claude-haiku-4-5')">✓ Usar</button>
        </div>
      </div>
      <div>
        <div class="gse-section">API Key</div>
        <div class="gse-key-row">
          <input id="gse-anthropic-key" class="gse-input" type="password" placeholder="sk-ant-api03-...">
          <button onclick="gseSaveKey('anthropic', document.getElementById('gse-anthropic-key').value)" class="btn btn-outline btn-sm">✓ Salvar</button>
        </div>
        <div class="gse-hint" style="margin-top:4px;">Salva em <code>~/.config/goose/config.yaml</code></div>
      </div>
    </div>

    <!-- Aba: OpenAI -->
    <div id="gse-pane-openai" class="gse-pane">
      <div class="gse-hint">Selecione um modelo OpenAI e informe sua API Key.</div>
      <div style="display:flex;flex-direction:column;gap:6px;">
        <div class="gse-row">
          <span style="flex:1;font-family:monospace;font-size:13px;">gpt-4o <span style="color:var(--muted);font-size:11px;">(mais capaz)</span></span>
          <button class="gse-sel" onclick="gseSetProvider('openai','gpt-4o')">✓ Usar</button>
        </div>
        <div class="gse-row">
          <span style="flex:1;font-family:monospace;font-size:13px;">gpt-4o-mini <span style="color:var(--muted);font-size:11px;">(mais rápido/barato)</span></span>
          <button class="gse-sel" onclick="gseSetProvider('openai','gpt-4o-mini')">✓ Usar</button>
        </div>
        <div class="gse-row">
          <span style="flex:1;font-family:monospace;font-size:13px;">gpt-4-turbo <span style="color:var(--muted);font-size:11px;">(alternativa)</span></span>
          <button class="gse-sel" onclick="gseSetProvider('openai','gpt-4-turbo')">✓ Usar</button>
        </div>
      </div>
      <div>
        <div class="gse-section">API Key</div>
        <div class="gse-key-row">
          <input id="gse-openai-key" class="gse-input" type="password" placeholder="sk-...">
          <button onclick="gseSaveKey('openai', document.getElementById('gse-openai-key').value)" class="btn btn-outline btn-sm">✓ Salvar</button>
        </div>
      </div>
    </div>

    <!-- Aba: Ollama -->
    <div id="gse-pane-ollama" class="gse-pane">
      <div class="gse-hint">Selecione um modelo local instalado no Ollama (nenhuma API Key necessária).</div>
      <div id="gse-ollama-list" style="font-size:13px; color:var(--muted);">Carregando...</div>
      <div style="flex-shrink:0; padding-top:8px; border-top:1px solid var(--border);">
        <button onclick="gseLoadOllama()" class="btn btn-outline btn-sm">↻ Atualizar</button>
      </div>
    </div>

    <!-- Aba: Groq -->
    <div id="gse-pane-groq" class="gse-pane">
      <div class="gse-hint">Groq oferece inferência rápida gratuita. Crie uma chave em <code>console.groq.com</code>.</div>
      <div style="display:flex;flex-direction:column;gap:6px;">
        <div class="gse-row">
          <span style="flex:1;font-family:monospace;font-size:13px;">llama3-70b-8192 <span style="color:var(--muted);font-size:11px;">(maior)</span></span>
          <button class="gse-sel" onclick="gseSetProvider('groq','llama3-70b-8192')">✓ Usar</button>
        </div>
        <div class="gse-row">
          <span style="flex:1;font-family:monospace;font-size:13px;">llama3-8b-8192 <span style="color:var(--muted);font-size:11px;">(mais rápido)</span></span>
          <button class="gse-sel" onclick="gseSetProvider('groq','llama3-8b-8192')">✓ Usar</button>
        </div>
        <div class="gse-row">
          <span style="flex:1;font-family:monospace;font-size:13px;">mixtral-8x7b-32768 <span style="color:var(--muted);font-size:11px;">(Mistral)</span></span>
          <button class="gse-sel" onclick="gseSetProvider('groq','mixtral-8x7b-32768')">✓ Usar</button>
        </div>
      </div>
      <div>
        <div class="gse-section">API Key</div>
        <div class="gse-key-row">
          <input id="gse-groq-key" class="gse-input" type="password" placeholder="gsk_...">
          <button onclick="gseSaveKey('groq', document.getElementById('gse-groq-key').value)" class="btn btn-outline btn-sm">✓ Salvar</button>
        </div>
      </div>
    </div>

    <!-- Aba: Custom -->
    <div id="gse-pane-custom" class="gse-pane">
      <div class="gse-hint">
        Informe o provider e o nome do modelo manualmente.<br>
        Providers suportados: <code>anthropic</code> · <code>openai</code> · <code>ollama</code> · <code>groq</code> · <code>google</code>
      </div>
      <div style="display:flex; gap:8px; flex-wrap:wrap;">
        <input id="gse-custom-provider" class="gse-input" type="text" placeholder="provider (ex: anthropic)" style="max-width:180px;">
        <input id="gse-custom-model" class="gse-input" type="text" placeholder="modelo (ex: claude-sonnet-4-5)">
        <button onclick="gseSetCustom()" class="btn btn-primary btn-sm">✓ Salvar</button>
      </div>
      <div id="gse-custom-status" style="font-size:13px; min-height:20px;"></div>
    </div>

    <div id="gse-set-status" style="font-size:12px; min-height:16px; padding:8px 16px; flex-shrink:0;"></div>
  </div>
</div>
HTML
    cat << SCRIPT
<script>
(function() {
  var bbv   = '${bbv_base}';
  var modal = document.getElementById('goose-modal');
  var TABS  = ['anthropic','openai','ollama','groq','custom'];

  window.openGooseModal = function() {
    modal.style.display = 'flex';
    requestAnimationFrame(function() { modal.classList.add('open'); });
    document.body.style.overflow = 'hidden';
    gseLoadCurrent();
    gseLoadOllama();
  };
  window.closeGooseModal = function() {
    modal.classList.remove('open');
    setTimeout(function() { modal.style.display = 'none'; }, 200);
    document.body.style.overflow = '';
  };
  window.gseTab = function(tab) {
    document.querySelectorAll('.gse-tab').forEach(function(b, i) {
      b.classList.toggle('active', TABS[i] === tab);
    });
    TABS.forEach(function(t) {
      document.getElementById('gse-pane-' + t).classList.toggle('active', t === tab);
    });
    if (tab === 'ollama') gseLoadOllama();
  };
  function gseLoadCurrent() {
    fetch(bbv + '/execute\$./goose-manage.sh get-config')
      .then(function(r) { return r.text(); })
      .then(function(html) { document.getElementById('gse-current-cfg').innerHTML = html; })
      .catch(function() {});
  }
  window.gseLoadOllama = function() {
    var out = document.getElementById('gse-ollama-list');
    out.innerHTML = '<span style="color:var(--muted);">Carregando...</span>';
    fetch(bbv + '/execute\$./goose-manage.sh list-ollama')
      .then(function(r) { return r.text(); })
      .then(function(html) { out.innerHTML = html; })
      .catch(function(e) { out.textContent = 'Erro: ' + e; });
  };
  window.gseSetProvider = function(provider, model) {
    var st = document.getElementById('gse-set-status');
    st.innerHTML = '<span style="color:var(--muted);">Salvando...</span>';
    fetch(bbv + '/execute\$./goose-manage.sh set-provider ' +
          encodeURIComponent(provider) + ' ' + encodeURIComponent(model))
      .then(function(r) { return r.text(); })
      .then(function(html) {
        st.innerHTML = html;
        gseLoadCurrent();
        gseLoadOllama();
      });
  };
  window.gseSaveKey = function(provider, key) {
    var st = document.getElementById('gse-set-status');
    if (!key.trim()) { st.innerHTML = '<span style="color:var(--danger);">Informe a API Key.</span>'; return; }
    st.innerHTML = '<span style="color:var(--muted);">Salvando chave...</span>';
    fetch(bbv + '/execute\$./goose-manage.sh set-key ' +
          encodeURIComponent(provider) + ' ' + encodeURIComponent(key))
      .then(function(r) { return r.text(); })
      .then(function(html) { st.innerHTML = html; });
  };
  window.gseClearConfig = function() {
    var st = document.getElementById('gse-set-status');
    fetch(bbv + '/execute\$./goose-manage.sh clear-config')
      .then(function(r) { return r.text(); })
      .then(function(html) { st.innerHTML = html; gseLoadCurrent(); });
  };
  window.gseSetCustom = function() {
    var provider = document.getElementById('gse-custom-provider').value.trim();
    var model    = document.getElementById('gse-custom-model').value.trim();
    var st       = document.getElementById('gse-custom-status');
    if (!provider || !model) { st.innerHTML = '<span style="color:var(--danger);">Informe o provider e o modelo.</span>'; return; }
    st.innerHTML = '<span style="color:var(--muted);">Salvando...</span>';
    fetch(bbv + '/execute\$./goose-manage.sh set-provider ' +
          encodeURIComponent(provider) + ' ' + encodeURIComponent(model))
      .then(function(r) { return r.text(); })
      .then(function(html) {
        st.innerHTML = html;
        document.getElementById('gse-set-status').innerHTML = html;
        gseLoadCurrent();
      });
  };
  document.addEventListener('keydown', function(e) { if (e.key === 'Escape') closeGooseModal(); });
  document.getElementById('goose-modal').addEventListener('click', function(e) {
    if (e.target === this) closeGooseModal();
  });
})();
</script>
SCRIPT
}

remove_goose() {
    step "Removendo Goose..."

    # Instalado via pacman/AUR
    if has_pkg goose-cli-bin 2>/dev/null || has_pkg goose-ai-bin 2>/dev/null; then
        remove_pkg goose-cli-bin 2>/dev/null || remove_pkg goose-ai-bin 2>/dev/null || true
    else
        rm -f "$HOME/.local/bin/goose"
    fi

    log "Goose removido."
    warn "Configuração preservada em ~/.config/goose/ (remova manualmente se desejar)."
}
