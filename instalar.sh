#!/usr/bin/env bash
# Instalador del mod "modo programador" para Claude Code (macOS / Linux).
# Uso:  bash instalar.sh [--vault "/ruta/vault"] [--extras] [--forzar]
#  --vault   ruta del vault de Obsidian (opcional; sin ella se usa la auto-memoria de Claude Code)
#  --extras  instala tambien omniroute (MCP), SkillSpector (uv) y FreeLLMAPI (Docker)
#  --forzar  sobrescribe skills/agentes que ya existan
# No escribe ninguna API key.
set -u
PKG="$(cd "$(dirname "$0")" && pwd)"
CLAUDE="$HOME/.claude"
VAULT=""; EXTRAS=0; FORZAR=0
while [ $# -gt 0 ]; do
  case "$1" in
    --vault) VAULT="$2"; shift 2 ;;
    --extras) EXTRAS=1; shift ;;
    --forzar) FORZAR=1; shift ;;
    *) echo "opcion desconocida: $1"; exit 1 ;;
  esac
done
LOG=()
paso() { printf '\n== %s\n' "$1"; }
ok()   { printf '  OK  %s\n' "$1"; LOG+=("OK    $1"); }
mal()  { printf '  !!  %s\n' "$1"; LOG+=("FALLA $1"); }
tiene() { command -v "$1" >/dev/null 2>&1; }

paso "Requisitos"
for c in claude node npm git; do tiene "$c" && ok "$c encontrado" || mal "$c NO esta instalado (necesario)"; done
tiene claude || { echo "Instala Claude Code primero: npm install -g @anthropic-ai/claude-code"; exit 1; }
tiene python3 && ok "python3 encontrado" || mal "python3 no esta (lo usan proyectos.py, ui-ux-pro-max)"
tiene ffmpeg && ok "ffmpeg encontrado" || mal "ffmpeg no esta (solo video/pelicula): brew install ffmpeg"

paso "Copiando skills, agentes y comandos a $CLAUDE"
for tipo in skills agents commands; do
  mkdir -p "$CLAUDE/$tipo"
  for src in "$PKG/$tipo"/*; do
    n="$(basename "$src")"
    if [ -e "$CLAUDE/$tipo/$n" ] && [ $FORZAR -eq 0 ]; then ok "$tipo/$n ya existe, se deja (usa --forzar)"; continue; fi
    rm -rf "$CLAUDE/$tipo/$n"; cp -R "$src" "$CLAUDE/$tipo/$n" && ok "$tipo/$n"
  done
done

paso "Adaptando rutas"
VALOR="${VAULT:-(sin vault: usar la auto-memoria de Claude Code)}"
for s in modo-programador memoria-vault; do
  f="$CLAUDE/skills/$s/SKILL.md"
  [ -f "$f" ] && python3 - "$f" "$VALOR" <<'EOF'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); t = p.read_text(encoding="utf-8")
t = t.replace("{{VAULT}}", sys.argv[2]).replace(".venv/Scripts/skillspector.exe", ".venv/bin/skillspector")
p.write_text(t, encoding="utf-8")
EOF
done
ok "vault -> $VALOR"

paso "playwright-skill (npm + Chromium)"
if [ -d "$CLAUDE/skills/playwright-skill" ]; then
  (cd "$CLAUDE/skills/playwright-skill" && npm run setup >/dev/null 2>&1) && ok "playwright-skill listo" || mal "npm run setup fallo"
fi

paso "Plugins"
for m in anthropics/claude-plugins-official DietrichGebert/ponytail lemomo-ai/lemo-opuscar; do
  claude plugin marketplace add "$m" >/dev/null 2>&1; ok "marketplace $m"
done
for p in superpowers@claude-plugins-official firecrawl@claude-plugins-official vercel@claude-plugins-official \
         expo@claude-plugins-official supabase@claude-plugins-official netlify-skills@claude-plugins-official \
         ponytail@ponytail lemo-opuscar@lemolab; do
  claude plugin install "$p" >/dev/null 2>&1 && ok "plugin $p" || mal "plugin $p (reintenta: claude plugin install $p)"
done

paso "Servidores MCP"
add_mcp() { n="$1"; shift; claude mcp remove -s user "$n" >/dev/null 2>&1; claude mcp add -s user "$n" -- "$@" >/dev/null 2>&1 && ok "MCP $n" || mal "MCP $n"; }
add_mcp context7 npx -y @upstash/context7-mcp
add_mcp playwright npx -y @playwright/mcp@latest
npm install -g codebase-memory-mcp >/dev/null 2>&1 || mal "npm install -g codebase-memory-mcp (prueba con sudo o nvm)"
add_mcp codebase-memory codebase-memory-mcp

if [ $EXTRAS -eq 1 ]; then
  paso "Extras: omniroute"
  npm install -g omniroute >/dev/null 2>&1 && add_mcp omniroute omniroute --mcp || mal "omniroute"

  paso "Extras: SkillSpector"
  if tiene uv; then
    [ -d "$HOME/skillspector" ] || git clone --depth 1 https://github.com/NVIDIA/SkillSpector.git "$HOME/skillspector" >/dev/null 2>&1
    (cd "$HOME/skillspector" && uv sync >/dev/null 2>&1) && ok "SkillSpector en ~/skillspector" || mal "SkillSpector"
  else mal "falta uv: curl -LsSf https://astral.sh/uv/install.sh | sh"; fi

  paso "Extras: FreeLLMAPI (Docker)"
  if tiene docker; then
    mkdir -p "$HOME/freellmapi"; cp "$PKG/extras/freellmapi/docker-compose.yml" "$HOME/freellmapi/"
    [ -f "$HOME/freellmapi/.env" ] || printf 'ENCRYPTION_KEY=%s\nPORT=3001\n' "$(openssl rand -hex 32)" > "$HOME/freellmapi/.env"
    (cd "$HOME/freellmapi" && docker compose up -d >/dev/null 2>&1) && ok "FreeLLMAPI -> http://127.0.0.1:3001 (pon tus claves en Keys)" || mal "FreeLLMAPI (Docker Desktop encendido?)"
  else mal "falta Docker Desktop: https://www.docker.com/products/docker-desktop"; fi
fi

paso "Resumen"
printf '  %s\n' "${LOG[@]}"
echo; echo "Listo. Reinicia Claude Code y prueba: modo programador <proyecto> estado"
echo "Pendiente manual: firecrawl login (si usas web/qa-vivo); claves de FreeLLMAPI en su panel."
