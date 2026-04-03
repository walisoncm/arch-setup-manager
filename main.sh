#!/usr/bin/env bash
# main.sh — menu principal

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/backend.sh"

html_header "Arch Setup Manager"

kernel="$(uname -r | cut -d- -f1)"
cat << HTML
<style>
  body { display: flex; flex-direction: column; }
  .main-scroll { flex: 1; overflow-y: auto; min-height: 0; }
  .main-footer {
    flex-shrink: 0;
    padding: 16px 20px;
    border-top: 1px solid var(--border);
    display: flex;
    align-items: center;
    justify-content: space-between;
    background: var(--surface);
  }
</style>

<div class="nav">
  <span class="nav-title">Arch Setup Manager</span>
  <span class="nav-sub">Acer Nitro V15 &nbsp;·&nbsp; CachyOS &nbsp;·&nbsp; $kernel</span>
</div>

<div class="main-scroll">
  <div style="padding:8px 20px 0; color:var(--muted); font-size:12px;">
    Selecione uma categoria para gerenciar os apps
  </div>
  <div class="grid">
HTML

for cat in "${CATEGORIES[@]}"; do
    read -r inst total < <(count_installed "$cat")

    if   (( inst == total && total > 0 )); then color_class="count-full"
    elif (( inst > 0 ));                   then color_class="count-partial"
    else                                        color_class="count-none"
    fi

    icon="${CATS_ICON[$cat]}"
    title="${CATS_TITLE[$cat]}"
    desc="${CATS_DESC[$cat]}"

    cat << HTML
    <a class="cat-card" href="/execute$./category.sh $cat">
      <div class="cat-icon">$icon</div>
      <div class="cat-name">$title</div>
      <div class="cat-desc">$desc</div>
      <div class="cat-count $color_class">$inst / $total instalados</div>
    </a>
HTML
done

cat << 'HTML'
  </div>
</div>

<div class="main-footer">
  <span style="font-size:12px; color:var(--muted);">Arch Setup Manager &nbsp;·&nbsp; Acer Nitro V15 (ANV15-41)</span>
  <a href="/execute close$" class="btn btn-outline btn-sm">Fechar</a>
</div>
HTML

html_footer
