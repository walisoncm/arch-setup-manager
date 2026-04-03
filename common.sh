#!/usr/bin/env bash
# common.sh — CSS global + funções HTML compartilhadas

# ─── CSS ──────────────────────────────────────────────────────────────────────
read -r -d '' APP_CSS << 'ENDCSS'
* { box-sizing: border-box; margin: 0; padding: 0; }
:root {
  --bg:       #11111e;
  --surface:  #18182a;
  --card:     #20203a;
  --card2:    #252540;
  --border:   #32325a;
  --primary:  #7c67fa;
  --primary2: #6051d8;
  --success:  #3ddc84;
  --warn:     #ffb74d;
  --danger:   #e06c75;
  --text:     #e2e2f0;
  --muted:    #7878a0;
  --radius:   12px;
}
html, body { height: 100%; scroll-behavior: smooth; }
body {
  background: var(--bg);
  color: var(--text);
  font-family: system-ui, "Segoe UI", Ubuntu, sans-serif;
  font-size: 14px;
  line-height: 1.5;
}

/* ── Nav ──────────────────────────────────────────────── */
.nav {
  background: var(--surface);
  border-bottom: 1px solid var(--border);
  padding: 0 20px;
  height: 56px;
  display: flex;
  align-items: center;
  gap: 12px;
  position: sticky;
  top: 0;
  z-index: 200;
}
.nav-title { font-size: 15px; font-weight: 700; letter-spacing: .3px; }
.nav-sub   { font-size: 11px; color: var(--muted); margin-left: auto; }

/* ── Buttons ──────────────────────────────────────────── */
.btn {
  padding: 7px 18px;
  border-radius: 20px;
  border: none;
  cursor: pointer;
  font-size: 13px;
  font-weight: 500;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  text-decoration: none;
  transition: opacity .15s, transform .1s;
  white-space: nowrap;
  user-select: none;
}
.btn:active { transform: scale(.97); }
.btn-primary  { background: var(--primary); color: #fff; }
.btn-primary:hover { background: var(--primary2); opacity: 1; }
.btn-outline  { background: transparent; border: 1px solid var(--border); color: var(--text); }
.btn-outline:hover  { background: rgba(255,255,255,.05); opacity: 1; }
.btn-danger   { background: transparent; border: 1px solid var(--danger); color: var(--danger); }
.btn-danger:hover   { background: rgba(224,108,117,.12); opacity: 1; }
.btn-back     { background: transparent; border: 1px solid var(--border); color: var(--muted); padding: 6px 14px; }
.btn-back:hover { background: rgba(255,255,255,.04); opacity: 1; }
.btn-sm { padding: 5px 13px; font-size: 12px; }

/* ── Category Cards (main menu) ───────────────────────── */
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(185px, 1fr));
  gap: 12px;
  padding: 20px;
}
.cat-card {
  background: var(--card);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 18px 16px;
  cursor: pointer;
  text-decoration: none;
  color: var(--text);
  display: flex;
  flex-direction: column;
  gap: 6px;
  transition: transform .15s, box-shadow .15s, border-color .15s;
}
.cat-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 8px 28px rgba(0,0,0,.5);
  border-color: var(--primary);
}
.cat-icon { font-size: 26px; line-height: 1; }
.cat-name { font-size: 14px; font-weight: 700; margin-top: 4px; }
.cat-desc { font-size: 11px; color: var(--muted); }
.cat-count { font-size: 11px; font-weight: 600; margin-top: 4px; }
.count-full    { color: var(--success); }
.count-partial { color: var(--warn); }
.count-none    { color: var(--muted); }

/* ── App list (category view) ─────────────────────────── */
.section { margin: 12px 16px; background: var(--card); border: 1px solid var(--border); border-radius: var(--radius); overflow: hidden; }
.section-header { padding: 12px 16px; border-bottom: 1px solid var(--border); font-size: 11px; font-weight: 600; color: var(--muted); text-transform: uppercase; letter-spacing: .8px; }
.app-row {
  display: flex;
  align-items: center;
  padding: 13px 16px;
  border-bottom: 1px solid var(--border);
  gap: 14px;
}
.app-row:last-child { border-bottom: none; }
.app-info { flex: 1; min-width: 0; }
.app-name { font-size: 14px; font-weight: 600; }
.app-desc { font-size: 12px; color: var(--muted); margin-top: 2px; }
.app-actions { display: flex; align-items: center; gap: 8px; flex-shrink: 0; }
.badge-ok {
  background: rgba(61,220,132,.12);
  border: 1px solid rgba(61,220,132,.3);
  color: var(--success);
  padding: 3px 10px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
}
.badge-no {
  background: rgba(255,255,255,.05);
  border: 1px solid var(--border);
  color: var(--muted);
  padding: 3px 10px;
  border-radius: 12px;
  font-size: 11px;
}

/* ── Action page ──────────────────────────────────────── */
.action-wrap { padding: 20px; }
.spinner-wrap {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  gap: 16px;
  color: var(--muted);
}
.spinner {
  width: 42px;
  height: 42px;
  border: 3px solid var(--border);
  border-top-color: var(--primary);
  border-radius: 50%;
  animation: spin .8s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }
.terminal {
  background: #090912;
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 14px 16px;
  font-family: "JetBrains Mono", "Fira Code", "Cascadia Code", monospace;
  font-size: 12px;
  line-height: 1.7;
  white-space: pre-wrap;
  word-break: break-all;
  max-height: 440px;
  overflow-y: auto;
  color: #c4c4dc;
  margin-bottom: 16px;
}
.t-ok   { color: #3ddc84; }
.t-warn { color: #ffb74d; }
.t-err  { color: #e06c75; }
.t-step { color: #82aaff; font-weight: bold; }
.result-ok  { background: rgba(61,220,132,.08); border: 1px solid rgba(61,220,132,.25); border-radius: 8px; padding: 12px 16px; margin-bottom: 16px; color: var(--success); font-weight: 600; }
.result-err { background: rgba(224,108,117,.08); border: 1px solid rgba(224,108,117,.25); border-radius: 8px; padding: 12px 16px; margin-bottom: 16px; color: var(--danger); font-weight: 600; }

/* ── Misc ─────────────────────────────────────────────── */
.sep { height: 1px; background: var(--border); margin: 0 16px; }
.page-footer { padding: 16px 20px; display: flex; gap: 10px; }
a { text-decoration: none; }
ENDCSS

# ─── HTML header / footer ─────────────────────────────────────────────────────
html_header() {
    local title="${1:-Arch Setup Manager}"
    cat << HTML
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>$title</title>
<style>$APP_CSS</style>
</head>
<body>
HTML
}

html_footer() {
    cat << 'HTML'
<script>
// Loading feedback em qualquer link que navega para o menu principal
document.addEventListener('click', function(e) {
    var link = e.target.closest('a[href*="main.sh"]');
    if (!link || link.classList.contains('disabled')) return;
    link.style.pointerEvents = 'none';
    link.style.opacity = '0.65';
    link.innerHTML = '<span style="display:inline-block;width:11px;height:11px;border:2px solid currentColor;border-top-color:transparent;border-radius:50%;animation:spin .7s linear infinite;vertical-align:middle;margin-right:6px;"></span>Carregando...';
});
</script>
</body></html>
HTML
}

# ─── formata saída de install/remove para HTML ────────────────────────────────
format_output() {
    while IFS= read -r line; do
        # Remove códigos ANSI e carriage return (barra de progresso do pacman)
        local clean; clean="$(printf '%s' "$line" | sed 's/\x1b\[[0-9;]*[mGKHF]//g; s/\r//g')"
        [[ -z "$clean" ]] && echo "" && continue

        # Linhas já formatadas em HTML passam direto (evita double-escape)
        if [[ "$clean" =~ \<span ]]; then echo "$clean"; continue; fi

        # Escapa HTML
        clean="${clean//&/&amp;}"
        clean="${clean//</&lt;}"
        clean="${clean//>/&gt;}"

        if   [[ "$clean" =~ ^\s*\[+\]  ]]; then echo "<span class=\"t-ok\">$clean</span>"
        elif [[ "$clean" =~ ^\s*\[!\]  ]]; then echo "<span class=\"t-warn\">$clean</span>"
        elif [[ "$clean" =~ ^\s*\[✗\]  ]]; then echo "<span class=\"t-err\">$clean</span>"
        elif [[ "$clean" =~ ──▸        ]]; then echo "<span class=\"t-step\">$clean</span>"
        elif [[ "$clean" =~ ^\s*\[=+\] ]]; then echo "<span class=\"t-ok\">$clean</span>"
        else echo "$clean"
        fi
    done
}
