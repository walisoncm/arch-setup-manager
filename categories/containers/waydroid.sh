#!/usr/bin/env bash
APP_ID="waydroid"
APP_NAME="Waydroid"
APP_DESC="Android em container"

status_waydroid() {
    has_pkg "waydroid" && svc_enabled "waydroid-container.service" && [[ -d "/var/lib/waydroid/images" ]]
}

install_waydroid() {
    step "Instalando dependências..."
    install_pkg wl-clipboard python || { err "Falha ao instalar dependências."; return 1; }

    step "Instalando Waydroid..."
    install_pkg waydroid || { err "Falha ao instalar waydroid."; return 1; }

    step "Carregando módulo binder_linux..."
    if ! lsmod 2>/dev/null | grep -q binder; then
        sudo modprobe binder_linux 2>/dev/null || sudo modprobe binder 2>/dev/null || \
            warn "Módulo binder não carregado — verifique se o kernel tem suporte a binder."
    fi
    echo "binder_linux" | sudo tee /etc/modules-load.d/waydroid.conf > /dev/null

    step "Habilitando serviço de container..."
    sudo systemctl enable --now waydroid-container.service || { err "Falha ao habilitar waydroid-container.service."; return 1; }

    step "Inicializando imagem Android (vanilla AOSP)..."
    warn "O download da imagem pode demorar alguns minutos (~500 MB)."
    if ! sudo waydroid init; then
        err "Falha na inicialização. Verifique a conectividade e tente 'sudo waydroid init' manualmente."
        return 1
    fi

    log "Waydroid instalado!"
    log "Configure as otimizações na seção Configurações > Waydroid."
}

manage_waydroid() {
    local bbv_base="$1"
    echo "openWaydroidModal()"
    cat << HTML
<div id="waydroid-modal" style="display:none; position:fixed; inset:0; z-index:500; align-items:center; justify-content:center; background:rgba(0,0,0,0); backdrop-filter:blur(0px); transition:background .2s,backdrop-filter .2s;">
  <div class="modal-panel" style="background:var(--surface); border:1px solid var(--border); border-radius:var(--radius); width:min(520px,92vw); display:flex; flex-direction:column; overflow:hidden; box-shadow:0 20px 60px rgba(0,0,0,.7); transform:scale(.96); opacity:0; transition:transform .2s,opacity .2s;">
    <div style="padding:14px 20px; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; flex-shrink:0;">
      <span style="font-weight:700; font-size:14px;">🤖 Waydroid — Gerenciamento</span>
      <button onclick="closeWaydroidModal()" style="background:none; border:none; color:var(--muted); font-size:18px; cursor:pointer; line-height:1; padding:0 4px;">✕</button>
    </div>
    <div style="padding:16px 20px; display:flex; flex-direction:column; gap:10px;">
      <a href="/execute\$./action.sh install waydroid-opts configs" style="display:flex; align-items:center; gap:12px; padding:14px 16px; background:rgba(124,103,250,.08); border:1px solid rgba(124,103,250,.25); border-radius:10px; text-decoration:none; color:var(--text); transition:background .15s;" onmouseover="this.style.background='rgba(124,103,250,.16)'" onmouseout="this.style.background='rgba(124,103,250,.08)'">
        <span style="font-size:22px;">⚙</span>
        <div>
          <div style="font-weight:600; font-size:13px;">Aplicar Otimizações</div>
          <div style="font-size:11px; color:var(--muted); margin-top:2px;">Multi-janela, GPU integrada, clipboard e resolução</div>
        </div>
      </a>
      <div onclick="waydroidRun('upgrade')" style="display:flex; align-items:center; gap:12px; padding:14px 16px; background:rgba(61,220,132,.08); border:1px solid rgba(61,220,132,.25); border-radius:10px; cursor:pointer; transition:background .15s;" onmouseover="this.style.background='rgba(61,220,132,.16)'" onmouseout="this.style.background='rgba(61,220,132,.08)'">
        <span style="font-size:22px;">↑</span>
        <div>
          <div style="font-weight:600; font-size:13px; color:var(--success);">Atualizar Imagem Android</div>
          <div style="font-size:11px; color:var(--muted); margin-top:2px;">Baixa e aplica a versão mais recente do sistema</div>
        </div>
      </div>
      <div onclick="waydroidRun('stop')" style="display:flex; align-items:center; gap:12px; padding:14px 16px; background:rgba(224,108,117,.08); border:1px solid rgba(224,108,117,.25); border-radius:10px; cursor:pointer; transition:background .15s;" onmouseover="this.style.background='rgba(224,108,117,.16)'" onmouseout="this.style.background='rgba(224,108,117,.08)'">
        <span style="font-size:22px;">⏹</span>
        <div>
          <div style="font-weight:600; font-size:13px; color:var(--danger);">Parar Waydroid</div>
          <div style="font-size:11px; color:var(--muted); margin-top:2px;">Encerra a sessão e para o container</div>
        </div>
      </div>
      <div id="waydroid-action-out" style="display:none; background:#090912; border:1px solid var(--border); border-radius:8px; padding:12px 14px; font-family:'JetBrains Mono','Fira Code',monospace; font-size:11px; line-height:1.7; color:#c4c4dc; white-space:pre-wrap; word-break:break-word; max-height:200px; overflow-y:auto;"></div>
    </div>
  </div>
</div>
<script>
(function() {
  var bbv   = '${bbv_base}';
  var modal = document.getElementById('waydroid-modal');
  var panel = modal.querySelector('.modal-panel');

  window.openWaydroidModal = function() {
    modal.style.display = 'flex';
    requestAnimationFrame(function() {
      modal.style.background = 'rgba(0,0,0,.7)';
      modal.style.backdropFilter = 'blur(3px)';
      panel.style.transform = 'scale(1)';
      panel.style.opacity = '1';
    });
  };
  window.closeWaydroidModal = function() {
    modal.style.background = 'rgba(0,0,0,0)';
    modal.style.backdropFilter = 'blur(0px)';
    panel.style.transform = 'scale(.96)';
    panel.style.opacity = '0';
    setTimeout(function() { modal.style.display = 'none'; }, 200);
  };
  window.waydroidRun = function(action) {
    var out = document.getElementById('waydroid-action-out');
    out.style.display = 'block';
    out.innerHTML = '<span style="color:var(--muted);">Executando...</span>';
    fetch(bbv + '/execute\$./waydroid-manage.sh ' + action)
      .then(function(r) { return r.text(); })
      .then(function(html) { out.innerHTML = html; out.scrollTop = out.scrollHeight; })
      .catch(function(e) { out.textContent = 'Erro: ' + e; });
  };
  modal.addEventListener('click', function(e) { if (e.target === modal) closeWaydroidModal(); });
  document.addEventListener('keydown', function(e) { if (e.key === 'Escape') closeWaydroidModal(); });
})();
</script>
HTML
}

remove_waydroid() {
    step "Parando sessão..."
    waydroid session stop 2>/dev/null || true
    sudo systemctl stop waydroid-container.service 2>/dev/null || true
    sudo systemctl disable waydroid-container.service 2>/dev/null || true

    step "Removendo pacote..."
    remove_pkg waydroid

    step "Limpando dados e entradas do launcher..."
    sudo rm -rf /var/lib/waydroid
    rm -rf "$HOME/.local/share/waydroid"
    rm -rf "$HOME/.local/share/applications/waydroid"
    rm -rf "$HOME/.local/share/waydroid-launchers"
    sudo rm -f /etc/modules-load.d/waydroid.conf
    rm -f "$HOME/.config/waydroid/.opts-applied"

    log "Waydroid removido."
}
