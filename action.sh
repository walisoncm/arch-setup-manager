#!/usr/bin/env bash
# action.sh ACTION APP CAT

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/backend.sh"

action="${1:-install}"
app="${2:-}"
cat_key="${3:-}"

[[ -z "$app" ]] && { echo "Erro: app não especificado"; exit 1; }

nm; nm="$(name_app "$app")"
[[ "$action" == "install" ]] && verb="Instalando" || verb="Removendo"

html_header "$verb $nm"

bbv_base="http://127.0.0.1:${bbv_port:-6482}"

cat << HTML
<div class="nav">
  <a href="/execute\$./category.sh $cat_key" id="btn-back" class="btn btn-back disabled">← Voltar</a>
  <span class="nav-title">$verb $nm...</span>
</div>

<div class="action-wrap">

  <div class="status-container">
    <!-- Estado: Carregando -->
    <div id="state-loading" class="status-box">
      <div class="loading-content">
        <div class="spinner"></div>
        <div class="loading-text">
          <span style="font-size:14px; font-weight:600; display:block;">$verb, aguarde...</span>
          <span style="font-size:11px; color:var(--muted);">Isso pode levar alguns minutos</span>
        </div>
      </div>
      <button class="btn btn-outline" style="visibility:hidden;">← Menu Principal</button>
    </div>

    <!-- Estado: Concluído -->
    <div id="state-result" class="status-box" style="display:none;">
      <div class="result-msg">✓ Operação concluída com sucesso!</div>
      <a href="/execute\$./main.sh" class="btn btn-outline">← Menu Principal</a>
    </div>
  </div>

  <div class="terminal-container">
    <div class="terminal-header">
      <div class="dots">
        <span class="dot red"></span>
        <span class="dot yellow"></span>
        <span class="dot green"></span>
      </div>
      <span class="terminal-title">Console Output</span>
    </div>
    <div id="terminal-output"></div>
    <div class="stdin-area">
      <span class="stdin-label">↳</span>
      <input type="text" id="stdin-input"
        placeholder="Responder prompt do terminal…"
        autocomplete="off" autocorrect="off" spellcheck="false">
      <button id="stdin-send">Enviar ↵</button>
    </div>
  </div>

</div>

<style>
  /* Layout em coluna para o terminal crescer até o fim da janela */
  body        { display: flex; flex-direction: column; }
  .action-wrap { flex: 1; display: flex; flex-direction: column; min-height: 0; }

  /* Container com altura fixa — o terminal nunca se move */
  .status-container {
    margin-top: 20px;
    position: relative;
    height: 108px;
  }

  /* Estados posicionados absolutamente para não afetarem o fluxo */
  .status-box {
    position: absolute;
    top: 0; left: 0; right: 0;
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    gap: 14px;
    width: 100%;
  }

  .loading-content {
    width: 100%;
    padding: 16px 20px;
    background: rgba(255,255,255,0.03);
    border: 1px solid #333;
    border-radius: 8px;
    display: flex;
    align-items: center;
    gap: 15px;
  }

  .result-msg {
    width: 100%;
    padding: 16px 20px;
    background: rgba(46, 204, 113, 0.1);
    border: 1px dashed rgba(46, 204, 113, 0.4);
    border-radius: 8px;
    color: #2ecc71;
    font-weight: 600;
    font-size: 15px;
  }

  .result-msg.failed {
    background: rgba(224, 108, 117, 0.1);
    border-color: rgba(224, 108, 117, 0.4);
    color: #e06c75;
  }

  .btn-back.disabled {
    opacity: 0.3;
    pointer-events: none;
    cursor: not-allowed;
  }

  /* Terminal */
  .terminal-container {
    margin-top: 20px;
    flex: 1;
    display: flex;
    flex-direction: column;
    min-height: 0;
    background: #181818;
    border-radius: 8px;
    box-shadow: 0 8px 25px rgba(0,0,0,0.5);
    overflow: hidden;
    border: 1px solid #333;
  }
  .terminal-header {
    background: #252525;
    padding: 10px 15px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    border-bottom: 1px solid #333;
  }
  .dots { display: flex; gap: 6px; }
  .dot { width: 10px; height: 10px; border-radius: 50%; }
  .red { background: #ff5f56; } .yellow { background: #ffbd2e; } .green { background: #27c93f; }
  .terminal-title { color: #888; font-family: monospace; font-size: 10px; font-weight: bold; text-transform: uppercase; }

  #terminal-output {
    width: 100%;
    flex: 1;
    min-height: 0;
    overflow-y: auto;
    background: #181818;
    padding: 10px 14px;
    box-sizing: border-box;
    font-family: "JetBrains Mono", "Fira Code", monospace;
    font-size: 12px;
    line-height: 1.6;
    color: #dcdcdc;
    white-space: pre-wrap;
    word-break: break-word;
  }
  /* Campo de stdin */
  .stdin-area {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 8px 12px;
    background: #1a1a1a;
    border-top: 1px solid #2a2a2a;
  }
  .stdin-label { color: #5fb3b3; font-family: monospace; font-size: 13px; flex-shrink: 0; }
  .stdin-area input {
    flex: 1;
    background: #111;
    border: 1px solid #333;
    border-radius: 4px;
    padding: 5px 10px;
    color: #dcdcdc;
    font-family: monospace;
    font-size: 12px;
    outline: none;
  }
  .stdin-area input:focus { border-color: #5fb3b3; }
  .stdin-area input:disabled, .stdin-area button:disabled { opacity: 0.35; cursor: not-allowed; }
  #stdin-send {
    background: transparent;
    border: 1px solid #5fb3b3;
    color: #5fb3b3;
    border-radius: 4px;
    padding: 5px 12px;
    font-size: 11px;
    cursor: pointer;
    white-space: nowrap;
  }
  #stdin-send:hover:not(:disabled) { background: rgba(95,179,179,0.12); }

  /* Classes de cor usadas pelo run.sh (sudo check) e format_output */
  #terminal-output .step, #terminal-output .t-step {
    color: #5fb3b3; font-weight: bold; display: block; margin-top: 8px;
  }
  #terminal-output .ok, #terminal-output .t-ok { color: #99c794; }
  #terminal-output .err, #terminal-output .t-err { color: #ec5f67; }
  #terminal-output .t-warn { color: #ffb74d; }

  .spinner {
    width: 24px; height: 24px;
    border: 3px solid rgba(255,255,255,0.1);
    border-top-color: #3498db;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }
  @keyframes spin { to { transform: rotate(360deg); } }
</style>

<script>
// Evita bfcache: se a página for restaurada do cache (persisted), recarrega do servidor
window.addEventListener('pageshow', function(e) {
  if (e.persisted) window.location.reload();
});

(function() {
  var LOG_URL   = '${bbv_base}/execute\$./log-tail.sh ${app}';
  var RUN_URL   = '${bbv_base}/execute\$./run.sh ${action} ${app} ${cat_key}';
  var STDIN_URL = '${bbv_base}/execute\$./stdin-relay.sh ${app}';
  var terminal  = document.getElementById('terminal-output');
  var stdinInput = document.getElementById('stdin-input');
  var stdinSend  = document.getElementById('stdin-send');

  // Garante que o input começa habilitado (bfcache pode restaurar estado desabilitado)
  stdinInput.disabled = false;
  stdinSend.disabled  = false;

  var byteOffset = 0;
  var fragment   = '';
  var pollTimer;

  // ── Inicia o processo ────────────────────────────────────────────────────
  fetch(RUN_URL).catch(function() {});

  // ── Polling do log a cada 500ms ──────────────────────────────────────────
  pollTimer = setInterval(function() {
    fetch(LOG_URL + ' ' + byteOffset)
      .then(function(r) { return r.arrayBuffer(); })
      .then(function(ab) {
        if (!ab.byteLength) return;
        byteOffset += ab.byteLength;
        fragment += new TextDecoder().decode(ab);

        var m = fragment.match(/___DONE_(\d+)___/);
        if (m) {
          var content = fragment.slice(0, fragment.indexOf('___DONE_'));
          if (content) appendContent(content);
          onProcessComplete(m[1] === '0');
          return;
        }

        var KEEP = 15;
        if (fragment.length > KEEP) {
          appendContent(fragment.slice(0, -KEEP));
          fragment = fragment.slice(-KEEP);
        }
      })
      .catch(function() {});
  }, 500);

  // ── Relay de stdin ────────────────────────────────────────────────────────
  function sendInput() {
    var val = stdinInput.value;
    stdinInput.value = '';
    // Ecoa o input no terminal para o usuário ver o que foi enviado
    appendContent('<span style="color:#888;font-style:italic">'
      + val.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
      + '\n</span>');
    // Envia via POST para o FIFO do processo
    fetch(STDIN_URL, {
      method: 'POST',
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'input=' + encodeURIComponent(val)
    }).catch(function() {});
  }

  stdinSend.addEventListener('click', sendInput);
  stdinInput.addEventListener('keydown', function(e) {
    if (e.key === 'Enter') sendInput();
  });

  // ── Helpers ───────────────────────────────────────────────────────────────
  function appendContent(html) {
    terminal.insertAdjacentHTML('beforeend', html);
    terminal.scrollTop = terminal.scrollHeight;
  }

  function onProcessComplete(success) {
    clearInterval(pollTimer);
    stdinInput.disabled = true;
    stdinSend.disabled  = true;

    document.getElementById('state-loading').style.display = 'none';
    var result = document.getElementById('state-result');
    result.style.display = 'flex';

    if (!success) {
      var msg = result.querySelector('.result-msg');
      msg.textContent = '✗ O processo falhou. Verifique o console acima.';
      msg.classList.add('failed');
    }

    document.getElementById('btn-back').classList.remove('disabled');
    document.querySelector('.nav-title').innerText = 'Concluído: ${nm}';
  }
})();
</script>
HTML

html_footer
