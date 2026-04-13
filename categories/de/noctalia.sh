#!/usr/bin/env bash
APP_ID="noctalia"
APP_NAME="Noctalia Shell"
APP_DESC="Shell Wayland com widgets, plugins e temas (Niri/Hyprland)"

_NOCTALIA_PLUGINS_REPO="https://github.com/noctalia-dev/noctalia-plugins.git"
_NOCTALIA_PLUGIN_DIR="$HOME/.config/noctalia/plugins"
_NOCTALIA_PLUGINS_JSON="$HOME/.config/noctalia/plugins.json"
_NOCTALIA_LENS_MAIN="$HOME/.config/noctalia/plugins/screen-toolkit/Main.qml"

status_noctalia() { has_pkg "noctalia-shell"; }

install_noctalia() {
    step "Instalando Noctalia Shell..."
    install_pkg noctalia-shell

    step "Instalando dependências do valent-connect..."
    install_pkg valent gvfs gvfs-mtp openssh

    step "Instalando dependências do screen-toolkit..."
    # captura de tela e seleção de região
    install_pkg grim slurp
    # clipboard
    install_pkg wl-clipboard
    # OCR: binário + dados do idioma inglês
    install_pkg tesseract tesseract-data-eng
    # manipulação de imagem
    install_pkg imagemagick
    # leitor de QR/barcode
    install_pkg zbar
    # upload para Lens (fix) e URL encoding
    install_pkg curl python
    # tradução via CLI (OCR + tradução)
    install_pkg translate-shell
    # gravação de tela: instala wl-screenrec (preferido) e wf-recorder (fallback)
    install_pkg wl-screenrec wf-recorder-git
    # conversão de vídeo/GIF
    install_pkg ffmpeg

    step "Baixando e instalando plugins..."
    _noctalia_install_plugins

    step "Aplicando fix do Google Lens..."
    _noctalia_apply_lens_fix

    log "Noctalia instalado! Inicie com: noctalia-shell"
}

remove_noctalia() {
    remove_pkg noctalia-shell
    log "Noctalia removido. Configuração em ~/.config/noctalia mantida."
}

# ── Helpers ──────────────────────────────────────────────────────────────────

_noctalia_install_plugins() {
    mkdir -p "$_NOCTALIA_PLUGIN_DIR"

    local tmpdir
    tmpdir=$(mktemp -d)

    if ! git clone --depth=1 "$_NOCTALIA_PLUGINS_REPO" "$tmpdir" 2>/dev/null; then
        log "Aviso: falha ao clonar repositório de plugins."
        rm -rf "$tmpdir"
        return 1
    fi

    # Detecta estrutura do repo: raiz ou subdir plugins/
    local src="$tmpdir"
    [ -d "$tmpdir/plugins" ] && src="$tmpdir/plugins"

    for plugin in assistant-panel screen-toolkit; do
        if [ -d "$src/$plugin" ]; then
            rm -rf "${_NOCTALIA_PLUGIN_DIR:?}/$plugin"
            cp -r "$src/$plugin" "$_NOCTALIA_PLUGIN_DIR/"
            log "Plugin $plugin instalado."
        else
            log "Aviso: $plugin não encontrado no repositório."
        fi
    done

    rm -rf "$tmpdir"

    # Registrar plugins no plugins.json
    mkdir -p "$(dirname "$_NOCTALIA_PLUGINS_JSON")"
    cat > "$_NOCTALIA_PLUGINS_JSON" << 'EOF'
{
    "sources": [
        {
            "enabled": true,
            "name": "Noctalia Plugins",
            "url": "https://github.com/noctalia-dev/noctalia-plugins"
        }
    ],
    "states": {
        "assistant-panel": {
            "enabled": true,
            "sourceUrl": "https://github.com/noctalia-dev/noctalia-plugins"
        },
        "screen-toolkit": {
            "enabled": true,
            "sourceUrl": "https://github.com/noctalia-dev/noctalia-plugins"
        }
    },
    "version": 2
}
EOF
}

_noctalia_apply_lens_fix() {
    local file="$_NOCTALIA_LENS_MAIN"
    if [ ! -f "$file" ]; then
        log "Aviso: Main.qml não encontrado, pulando fix do Lens."
        return 1
    fi
    if grep -q "litterbox.catbox.moe" "$file"; then
        log "Fix do Lens já aplicado."
        return 0
    fi

    local patcher
    patcher=$(mktemp --suffix=.py)
    cat > "$patcher" << 'PYEOF'
import sys

def find_block(text, id_marker):
    idx = text.find(id_marker)
    if idx == -1:
        return None
    open_brace = text.rfind('{', 0, idx)
    if open_brace == -1:
        return None
    depth = 1
    pos = open_brace + 1
    while pos < len(text) and depth > 0:
        if text[pos] == '{':
            depth += 1
        elif text[pos] == '}':
            depth -= 1
        pos += 1
    return (open_brace, pos)

file_path = sys.argv[1]
with open(file_path, 'r') as f:
    content = f.read()

changed = False

NEW_LENS_PROC = '''{
        id: lensProc
        stdout: StdioCollector {}
        onExited: (code) => {
            root.isRunning = false
            root.activeTool = ""
            if (code !== 0) {
                ToastService.showError(pluginApi.tr("messages.lens-failed"))
                return
            }
            var hostedUrl = lensProc.stdout.text.trim()
            if (hostedUrl !== "") {
                var enc = encodeURIComponent(hostedUrl)
                Qt.openUrlExternally("https://www.google.com/searchbyimage?image_url=" + enc)
            }
        }
    }'''

span = find_block(content, 'id: lensProc')
if span:
    if 'StdioCollector' not in content[span[0]:span[1]]:
        content = content[:span[0]] + NEW_LENS_PROC + content[span[1]:]
        changed = True
        print('OK: lensProc fix aplicado')
    else:
        print('OK: lensProc já estava corrigido')
else:
    print('WARN: bloco lensProc não encontrado')

NEW_TRIGGER_BODY = '''{
            var file = "/tmp/screen-toolkit-lens.png"
            var cmd = _grimRegionCmd(file)
                    + " && magick " + file + " -background white -flatten " + file
                    + " && URL=$(curl -sS -F 'reqtype=fileupload' -F 'time=1h'"
                    + " -F 'fileToUpload=@" + file + "'"
                    + " 'https://litterbox.catbox.moe/resources/internals/api.php')"
                    + " && rm -f " + file
                    + " && [ -n \\"$URL\\" ] && echo \\"$URL\\""
            lensProc.exec({ command: ["bash", "-c", cmd] })
        }'''

span = find_block(content, 'id: launchLens')
if span:
    timer_block = content[span[0]:span[1]]
    if 'litterbox' not in timer_block:
        trig_idx = timer_block.find('onTriggered:')
        if trig_idx != -1:
            brace_idx = timer_block.find('{', trig_idx)
            if brace_idx != -1:
                depth = 1
                pos = brace_idx + 1
                while pos < len(timer_block) and depth > 0:
                    if timer_block[pos] == '{':
                        depth += 1
                    elif timer_block[pos] == '}':
                        depth -= 1
                    pos += 1
                new_timer = timer_block[:brace_idx] + NEW_TRIGGER_BODY + timer_block[pos:]
                content = content[:span[0]] + new_timer + content[span[1]:]
                changed = True
                print('OK: launchLens fix aplicado')
    else:
        print('OK: launchLens já estava corrigido')
else:
    print('WARN: bloco launchLens não encontrado')

if changed:
    with open(file_path, 'w') as f:
        f.write(content)
    print('Arquivo atualizado.')
PYEOF

    python3 "$patcher" "$file"
    rm -f "$patcher"
}

# ── Manage modal ──────────────────────────────────────────────────────────────

manage_noctalia() {
    local bbv_base="$1"
    echo "openNoctaliaModal()"
    cat << 'HTML'
<style>
  #noc-modal {
    display: none; position: fixed; inset: 0; z-index: 500;
    align-items: center; justify-content: center;
    background: rgba(0,0,0,0); backdrop-filter: blur(0px);
    transition: background .2s, backdrop-filter .2s;
  }
  #noc-modal.open {
    display: flex; background: rgba(0,0,0,.7); backdrop-filter: blur(3px);
  }
  #noc-modal .modal-panel {
    background: var(--surface); border: 1px solid var(--border);
    border-radius: var(--radius); width: min(620px, 92vw); max-height: 80vh;
    display: flex; flex-direction: column; overflow: hidden;
    box-shadow: 0 20px 60px rgba(0,0,0,.7);
    transform: scale(.96); opacity: 0; transition: transform .2s, opacity .2s;
  }
  #noc-modal.open .modal-panel { transform: scale(1); opacity: 1; }
  .noc-tabs { display: flex; gap: 4px; padding: 8px 16px; border-bottom: 1px solid var(--border); flex-shrink: 0; }
  .noc-tab  { padding: 5px 14px; border-radius: 6px; border: 1px solid transparent; cursor: pointer;
               font-size: 13px; background: none; color: var(--muted); transition: all .15s; }
  .noc-tab.active { background: rgba(124,103,250,.18); color: var(--primary); border-color: rgba(124,103,250,.3); }
  .noc-tab:hover:not(.active) { background: rgba(255,255,255,.05); color: var(--text); }
  .noc-pane { display: none; flex: 1; overflow-y: auto; padding: 16px;
               flex-direction: column; gap: 12px; min-height: 0; }
  .noc-pane.active { display: flex; }
  .noc-row { display: flex; align-items: center; gap: 10px; padding: 10px 14px;
              background: var(--card); border-radius: 6px; border: 1px solid var(--border); }
  .noc-badge-ok   { font-size: 11px; color: #3ddc84; background: rgba(61,220,132,.12);
                     border-radius: 4px; padding: 2px 8px; flex-shrink: 0; }
  .noc-badge-warn { font-size: 11px; color: var(--danger); background: rgba(224,108,117,.12);
                     border-radius: 4px; padding: 2px 8px; flex-shrink: 0; }
  .noc-hint { font-size: 12px; color: var(--muted); line-height: 1.7; }
</style>

<div id="noc-modal">
  <div class="modal-panel">
    <div style="padding:14px 20px; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; flex-shrink:0;">
      <span style="font-weight:700; font-size:14px;">🖥️ Noctalia Shell</span>
      <button onclick="closeNoctaliaModal()" style="background:none; border:none; color:var(--muted); font-size:18px; cursor:pointer; line-height:1; padding:0 4px;">✕</button>
    </div>
    <div class="noc-tabs">
      <button class="noc-tab active" onclick="nocTab('plugins')">🧩 Plugins</button>
      <button class="noc-tab"        onclick="nocTab('lens')">🔍 Lens Fix</button>
      <button class="noc-tab"        onclick="nocTab('sistema')">⚙ Sistema</button>
    </div>

    <!-- Plugins -->
    <div id="noc-pane-plugins" class="noc-pane active">
      <div id="noc-plugin-list" style="font-size:13px; color:var(--muted);">Carregando...</div>
      <div style="flex-shrink:0; padding-top:10px; border-top:1px solid var(--border);">
        <button onclick="nocLoadPlugins()" class="btn btn-outline btn-sm">↻ Atualizar</button>
      </div>
    </div>

    <!-- Lens Fix -->
    <div id="noc-pane-lens" class="noc-pane">
      <div id="noc-lens-status" style="font-size:13px; color:var(--muted);">Verificando...</div>
      <div class="noc-hint">
        O fix redireciona o Google Lens para usar upload via litterbox.catbox.moe,
        evitando o erro "imagem não associada à sua conta".<br>
        Pode ser necessário reaplicar após atualizações do plugin.
      </div>
      <div style="flex-shrink:0; padding-top:10px; border-top:1px solid var(--border); display:flex; gap:8px;">
        <button onclick="nocCheckLens()" class="btn btn-outline btn-sm">↻ Verificar</button>
        <button onclick="nocApplyLens()" class="btn btn-primary btn-sm">⚡ Aplicar Fix</button>
      </div>
      <div id="noc-lens-apply-status" style="font-size:12px; min-height:16px;"></div>
    </div>

    <!-- Sistema -->
    <div id="noc-pane-sistema" class="noc-pane">
      <div class="noc-row" style="flex-direction:column; align-items:flex-start; gap:8px;">
        <span style="font-weight:600; font-size:13px;">Reiniciar Quickshell</span>
        <span class="noc-hint">Necessário após mudanças em arquivos QML para aplicar as alterações.</span>
        <button onclick="nocRestart()" class="btn btn-primary btn-sm">↺ Reiniciar</button>
      </div>
      <div id="noc-restart-status" style="font-size:12px; min-height:16px;"></div>
    </div>
  </div>
</div>
HTML

    cat << SCRIPT
<script>
(function() {
  var bbv   = '${bbv_base}';
  var modal = document.getElementById('noc-modal');

  window.openNoctaliaModal = function() {
    modal.style.display = 'flex';
    requestAnimationFrame(function() { modal.classList.add('open'); });
    document.body.style.overflow = 'hidden';
    nocLoadPlugins();
  };
  window.closeNoctaliaModal = function() {
    modal.classList.remove('open');
    setTimeout(function() { modal.style.display = 'none'; }, 200);
    document.body.style.overflow = '';
  };
  window.nocTab = function(tab) {
    var tabs = ['plugins', 'lens', 'sistema'];
    document.querySelectorAll('.noc-tab').forEach(function(b, i) {
      b.classList.toggle('active', tabs[i] === tab);
    });
    tabs.forEach(function(t) {
      document.getElementById('noc-pane-' + t).classList.toggle('active', t === tab);
    });
    if (tab === 'lens') nocCheckLens();
  };

  window.nocLoadPlugins = function() {
    var out = document.getElementById('noc-plugin-list');
    out.innerHTML = '<span style="color:var(--muted);">Carregando...</span>';
    fetch(bbv + '/execute\$./noctalia-manage.sh plugin-status')
      .then(function(r) { return r.text(); })
      .then(function(html) { out.innerHTML = html; })
      .catch(function(e) { out.textContent = 'Erro: ' + e; });
  };

  window.nocCheckLens = function() {
    var out = document.getElementById('noc-lens-status');
    out.innerHTML = '<span style="color:var(--muted);">Verificando...</span>';
    fetch(bbv + '/execute\$./noctalia-manage.sh lens-fix-status')
      .then(function(r) { return r.text(); })
      .then(function(html) { out.innerHTML = html; })
      .catch(function(e) { out.textContent = 'Erro: ' + e; });
  };

  window.nocApplyLens = function() {
    var st = document.getElementById('noc-lens-apply-status');
    st.innerHTML = '<span style="color:var(--muted);">Aplicando...</span>';
    fetch(bbv + '/execute\$./noctalia-manage.sh apply-lens-fix')
      .then(function(r) { return r.text(); })
      .then(function(html) {
        st.innerHTML = html;
        nocCheckLens();
      })
      .catch(function(e) { st.textContent = 'Erro: ' + e; });
  };

  window.nocRestart = function() {
    var st = document.getElementById('noc-restart-status');
    st.innerHTML = '<span style="color:var(--muted);">Reiniciando...</span>';
    fetch(bbv + '/execute\$./noctalia-manage.sh restart-quickshell')
      .then(function(r) { return r.text(); })
      .then(function(html) { st.innerHTML = html; })
      .catch(function(e) { st.textContent = 'Erro: ' + e; });
  };

  document.addEventListener('keydown', function(e) { if (e.key === 'Escape') closeNoctaliaModal(); });
  document.getElementById('noc-modal').addEventListener('click', function(e) {
    if (e.target === this) closeNoctaliaModal();
  });
})();
</script>
SCRIPT
}
