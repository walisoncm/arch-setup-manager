#!/usr/bin/env bash
# confirm.sh APP CAT — página de confirmação antes de remover

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/backend.sh"

app="${1:-}"
cat_key="${2:-}"

[[ -z "$app" ]] && exit 1

nm="$(name_$app 2>/dev/null || echo "$app")"
cat_title="${CAT_TITLE[$cat_key]:-}"

html_header "Remover $nm"

cat << HTML
<div class="nav">
  <a href="/execute\$./category.sh $cat_key" class="btn btn-back">← Voltar</a>
  <span class="nav-title">Confirmar remoção</span>
</div>

<div style="padding:24px 20px; max-width:560px; margin:0 auto;">
  <div style="background:rgba(224,108,117,.08); border:1px solid rgba(224,108,117,.3); border-radius:12px; padding:20px 22px; margin-bottom:20px;">
    <div style="font-size:15px; font-weight:700; color:var(--danger); margin-bottom:10px;">
      Remover $nm?
    </div>
    <div style="font-size:13px; color:var(--muted); line-height:1.6;">
      Isso irá desinstalar os pacotes e remover todas as configurações
      exclusivas deste app do seu sistema. Essa ação não pode ser desfeita.
    </div>
  </div>

  <div style="display:flex; gap:10px;">
    <a href="/execute\$./action.sh remove $app $cat_key" class="btn btn-danger">
      Sim, remover
    </a>
    <a href="/execute\$./category.sh $cat_key" class="btn btn-outline">
      Cancelar
    </a>
  </div>
</div>
HTML

html_footer
