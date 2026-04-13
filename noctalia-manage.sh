#!/usr/bin/env bash
# noctalia-manage.sh ACTION
# Backend para o manage modal do Noctalia no arch-setup-manager.

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
export SUDO_ASKPASS="$SCRIPT_DIR/askpass.sh"

PLUGIN_DIR="$HOME/.config/noctalia/plugins"
LENS_MAIN="$PLUGIN_DIR/screen-toolkit/Main.qml"

esc() {
    local s="$1"
    s="${s//&/&amp;}"; s="${s//</&lt;}"; s="${s//>/&gt;}"
    echo -n "$s"
}

action="${1:-plugin-status}"

case "$action" in

    plugin-status)
        declare -A PLUGIN_LABELS=(
            ["assistant-panel"]="Assistant Panel"
            ["screen-toolkit"]="Screen Toolkit"
        )
        declare -A PLUGIN_DESC=(
            ["assistant-panel"]="Chat IA e tradução"
            ["screen-toolkit"]="Captura, OCR, Lens, gravação e mais"
        )

        echo "<div style='display:flex;flex-direction:column;gap:8px;'>"
        for plugin in assistant-panel screen-toolkit; do
            label="${PLUGIN_LABELS[$plugin]}"
            desc="${PLUGIN_DESC[$plugin]}"
            version=""
            badge=""

            if [ -d "$PLUGIN_DIR/$plugin" ]; then
                version=$(jq -r '.version // ""' "$PLUGIN_DIR/$plugin/manifest.json" 2>/dev/null)
                badge="<span class='noc-badge-ok'>✓ instalado$([ -n "$version" ] && echo " v$version")</span>"
            else
                badge="<span class='noc-badge-warn'>✗ não instalado</span>"
            fi

            echo "<div class='noc-row'>"
            echo "  <div style='flex:1;'>"
            echo "    <span style='font-size:13px;font-weight:600;'>$(esc "$label")</span>"
            echo "    <span style='font-size:11px;color:var(--muted);margin-left:8px;'>$(esc "$desc")</span>"
            echo "  </div>"
            echo "  $badge"
            echo "</div>"
        done
        echo "</div>"
        ;;

    lens-fix-status)
        if [ ! -f "$LENS_MAIN" ]; then
            echo "<div class='noc-row'><span class='noc-badge-warn'>⚠ screen-toolkit não instalado</span></div>"
            exit 0
        fi
        if grep -q "litterbox.catbox.moe" "$LENS_MAIN"; then
            echo "<div class='noc-row'><span class='noc-badge-ok'>✓ Fix aplicado</span><span style='font-size:12px;color:var(--muted);margin-left:8px;'>Upload via litterbox.catbox.moe + searchbyimage</span></div>"
        else
            echo "<div class='noc-row'><span class='noc-badge-warn'>✗ Fix não aplicado</span><span style='font-size:12px;color:var(--muted);margin-left:8px;'>Versão original — pode ter erro de sessão no Lens</span></div>"
        fi
        ;;

    apply-lens-fix)
        if [ ! -f "$LENS_MAIN" ]; then
            echo "<span style='color:var(--danger);'>Erro: screen-toolkit não encontrado em $PLUGIN_DIR</span>"
            exit 1
        fi

        if grep -q "litterbox.catbox.moe" "$LENS_MAIN"; then
            echo "<span style='color:#3ddc84;'>✓ Fix já estava aplicado.</span>"
            exit 0
        fi

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
errors = []

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
else:
    errors.append('lensProc')

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
else:
    errors.append('launchLens')

if changed:
    with open(file_path, 'w') as f:
        f.write(content)
    print('ok')
elif errors:
    print('warn:' + ','.join(errors))
else:
    print('already')
PYEOF

        result=$(python3 "$patcher" "$LENS_MAIN")
        rm -f "$patcher"

        case "$result" in
            ok)
                echo "<span style='color:#3ddc84;'>✓ Fix aplicado com sucesso. Reinicie o Quickshell para ativar.</span>"
                ;;
            already)
                echo "<span style='color:#3ddc84;'>✓ Fix já estava aplicado.</span>"
                ;;
            warn:*)
                blocos="${result#warn:}"
                echo "<span style='color:var(--danger);'>⚠ Blocos não encontrados: $(esc "$blocos"). O plugin pode ter mudado de versão.</span>"
                ;;
            *)
                echo "<span style='color:var(--danger);'>Erro inesperado ao aplicar fix.</span>"
                ;;
        esac
        ;;

    restart-quickshell)
        pkill -f "quickshell --path" 2>/dev/null || true
        sleep 1
        WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}" \
        XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" \
        DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}" \
        quickshell --path "$HOME/.config/noctalia" &disown 2>/dev/null

        sleep 1
        if pgrep -f "quickshell --path" > /dev/null; then
            echo "<span style='color:#3ddc84;'>✓ Quickshell reiniciado com sucesso.</span>"
        else
            echo "<span style='color:var(--danger);'>⚠ Quickshell pode não ter iniciado. Verifique manualmente.</span>"
        fi
        ;;

    *)
        echo "<span style='color:var(--danger);'>Ação desconhecida: $(esc "$action")</span>"
        ;;
esac
