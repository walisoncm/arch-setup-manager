#!/usr/bin/env bash
APP_ID="fwupd"
APP_NAME="fwupd (Firmware Updates)"
APP_DESC="Atualização de BIOS e Hardware com UI de gerenciamento"

manage_fwupd() {
    local bbv_base="$1"
    echo "openFwupdModal()"
    cat << HTML
<!-- ── Modal fwupd ─────────────────────────────────────────────────── -->
<style>
  #fwupd-modal {
    display: none;
    position: fixed;
    inset: 0;
    z-index: 500;
    align-items: center;
    justify-content: center;
    background: rgba(0,0,0,0);
    backdrop-filter: blur(0px);
    transition: background .2s, backdrop-filter .2s;
  }
  #fwupd-modal.open {
    display: flex;
    background: rgba(0,0,0,.7);
    backdrop-filter: blur(3px);
  }
  #fwupd-modal .modal-panel {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    width: min(680px, 92vw);
    max-height: 80vh;
    display: flex;
    flex-direction: column;
    overflow: hidden;
    box-shadow: 0 20px 60px rgba(0,0,0,.7);
    transform: scale(.96);
    opacity: 0;
    transition: transform .2s, opacity .2s;
  }
  #fwupd-modal.open .modal-panel {
    transform: scale(1);
    opacity: 1;
  }
</style>
<div id="fwupd-modal">
  <div class="modal-panel">
    <div style="padding:14px 20px; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; gap:12px; flex-shrink:0;">
      <span style="font-weight:700; font-size:14px;">⚙ fwupd — Gerenciamento de Firmware</span>
      <button onclick="closeFwupdModal()" style="background:none; border:none; color:var(--muted); font-size:18px; cursor:pointer; line-height:1; padding:0 4px;">✕</button>
    </div>
    <div style="padding:14px 20px; border-bottom:1px solid var(--border); display:flex; gap:8px; flex-wrap:wrap; flex-shrink:0;">
      <button onclick="fwupdRun('refresh')"     class="btn btn-outline btn-sm">↻ Atualizar metadados</button>
      <button onclick="fwupdRun('get-updates')" class="btn btn-primary btn-sm">🔍 Verificar atualizações</button>
      <button id="fwupd-btn-install" onclick="fwupdRun('update')" class="btn btn-outline btn-sm" style="display:none; border-color:var(--success); color:var(--success);">⬇ Instalar atualizações</button>
    </div>
    <div id="fwupd-output"
         style="flex:1; overflow-y:auto; padding:14px 18px; font-family:'JetBrains Mono','Fira Code',monospace; font-size:12px; line-height:1.7; background:#090912; color:#c4c4dc; white-space:pre-wrap; word-break:break-word; min-height:180px;">
      Clique em <strong>Verificar atualizações</strong> para começar.
    </div>
  </div>
</div>
<script>
(function() {
  var bbv   = '${bbv_base}';
  var modal = document.getElementById('fwupd-modal');

  window.openFwupdModal = function() {
    modal.style.display = 'flex';
    requestAnimationFrame(function() { modal.classList.add('open'); });
    document.body.style.overflow = 'hidden';
  };
  window.closeFwupdModal = function() {
    modal.classList.remove('open');
    setTimeout(function() { modal.style.display = 'none'; }, 200);
    document.body.style.overflow = '';
  };
  window.fwupdRun = function(action) {
    var out   = document.getElementById('fwupd-output');
    var btnIn = document.getElementById('fwupd-btn-install');
    out.innerHTML = '<span style="color:var(--muted);">Executando...</span>';
    fetch(bbv + '/execute\$./fwupd-manage.sh ' + action)
      .then(function(r) { return r.text(); })
      .then(function(html) {
        out.innerHTML = html;
        if (action === 'get-updates')
          btnIn.style.display = out.innerHTML.includes('data-has-updates') ? 'inline-flex' : 'none';
      })
      .catch(function(err) { out.textContent = 'Erro ao executar: ' + err; });
  };
  document.addEventListener('keydown', function(e) { if (e.key === 'Escape') closeFwupdModal(); });
  document.getElementById('fwupd-modal').addEventListener('click', function(e) {
    if (e.target === this) closeFwupdModal();
  });
})();
</script>
HTML
}

install_fwupd() {
    step "Instalando fwupd..."
    install_pkg fwupd
    sudo systemctl enable --now fwupd-refresh.timer
    log "fwupd instalado."
}
remove_fwupd() {
    step "Removendo fwupd..."
    sudo systemctl disable --now fwupd-refresh.timer fwupd.service 2>/dev/null
    remove_pkg fwupd
    log "fwupd removido."
}
