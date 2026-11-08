# Instalador del mod "modo programador" para Claude Code (Windows).
# Uso (PowerShell, desde esta carpeta):
#   powershell -ExecutionPolicy Bypass -File .\instalar.ps1
#   powershell -ExecutionPolicy Bypass -File .\instalar.ps1 -Vault "D:\MiVault" -Extras -Forzar
# -Vault   ruta del vault de Obsidian (opcional; sin ella se usa la auto-memoria de Claude Code)
# -Extras  instala tambien FreeLLMAPI (Docker) y SkillSpector (uv) y los MCP opcionales
# -Forzar  sobrescribe skills/agentes que ya existan (por defecto se saltan)
# No escribe ninguna API key. Las claves las pone cada usuario despues.

param(
  [string]$Vault = "",
  [switch]$Extras,
  [switch]$Forzar
)

$ErrorActionPreference = "Continue"
$Pkg = $PSScriptRoot
$Claude = Join-Path $HOME ".claude"
$Log = @()

function Paso($t) { Write-Host "`n== $t" -ForegroundColor Cyan }
function Ok($t)   { Write-Host "  OK  $t" -ForegroundColor Green; $script:Log += "OK   $t" }
function Mal($t)  { Write-Host "  !!  $t" -ForegroundColor Yellow; $script:Log += "FALLA $t" }
function Tiene($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

# 1. Requisitos
Paso "Requisitos"
foreach ($c in "claude","node","npm","git") {
  if (Tiene $c) { Ok "$c encontrado" } else { Mal "$c NO esta instalado (necesario)" }
}
if (-not (Tiene "claude")) { Write-Host "Instala Claude Code primero: npm install -g @anthropic-ai/claude-code" -ForegroundColor Red; exit 1 }
if (Tiene "python") { Ok "python encontrado" } else { Mal "python no esta (lo usan proyectos.py, ui-ux-pro-max, brag)" }
if (Tiene "ffmpeg") { Ok "ffmpeg encontrado" } else { Mal "ffmpeg no esta (solo para video/pelicula): winget install Gyan.FFmpeg" }

# 2. Copiar skills, agentes y comandos
Paso "Copiando skills, agentes y comandos a $Claude"
foreach ($tipo in "skills","agents","commands") {
  $dst = Join-Path $Claude $tipo
  New-Item -ItemType Directory -Force $dst | Out-Null
  Get-ChildItem (Join-Path $Pkg $tipo) | ForEach-Object {
    $destino = Join-Path $dst $_.Name
    if ((Test-Path $destino) -and -not $Forzar) { Ok "$tipo/$($_.Name) ya existe, se deja (usa -Forzar para reemplazar)"; return }
    Copy-Item $_.FullName $destino -Recurse -Force
    Ok "$tipo/$($_.Name)"
  }
}

# 3. Adaptar rutas del autor a este PC
Paso "Adaptando rutas"
$valor = if ($Vault) { $Vault } else { "(sin vault: usar la auto-memoria de Claude Code)" }
foreach ($s in "modo-programador","memoria-vault") {
  $f = Join-Path $Claude "skills\$s\SKILL.md"
  if (Test-Path $f) {
    $t = [IO.File]::ReadAllText($f, [Text.Encoding]::UTF8).Replace('{{VAULT}}', $valor)
    [IO.File]::WriteAllText($f, $t, (New-Object Text.UTF8Encoding $false))
  }
}
Ok "vault -> $valor"

# 4. playwright-skill necesita sus paquetes y Chromium
Paso "playwright-skill (npm + Chromium)"
$pw = Join-Path $Claude "skills\playwright-skill"
if (Test-Path $pw) {
  Push-Location $pw
  npm run setup 2>&1 | Select-Object -Last 3
  if ($LASTEXITCODE -eq 0) { Ok "playwright-skill listo" } else { Mal "npm run setup fallo en $pw" }
  Pop-Location
}

# 5. Plugins
Paso "Plugins"
$marketplaces = @("anthropics/claude-plugins-official","DietrichGebert/ponytail","lemomo-ai/lemo-opuscar")
foreach ($m in $marketplaces) {
  claude plugin marketplace add $m 2>&1 | Out-Null
  Ok "marketplace $m"
}
$plugins = @(
  "superpowers@claude-plugins-official",
  "firecrawl@claude-plugins-official",
  "vercel@claude-plugins-official",
  "expo@claude-plugins-official",
  "supabase@claude-plugins-official",
  "netlify-skills@claude-plugins-official",
  "ponytail@ponytail",
  "lemo-opuscar@lemolab"
)
foreach ($p in $plugins) {
  claude plugin install $p 2>&1 | Select-Object -Last 1
  if ($LASTEXITCODE -eq 0) { Ok "plugin $p" } else { Mal "plugin $p (reintenta: claude plugin install $p)" }
}

# 6. MCP (alcance usuario)
Paso "Servidores MCP"
function AddMcp($nombre, [string[]]$cmd) {
  claude mcp remove -s user $nombre 2>&1 | Out-Null
  claude mcp add -s user $nombre -- @cmd 2>&1 | Out-Null
  if ($LASTEXITCODE -eq 0) { Ok "MCP $nombre" } else { Mal "MCP $nombre" }
}
AddMcp "context7"   @("cmd","/c","npx","-y","@upstash/context7-mcp")
AddMcp "playwright" @("cmd","/c","npx","-y","@playwright/mcp@latest")
npm install -g codebase-memory-mcp 2>&1 | Select-Object -Last 1
AddMcp "codebase-memory" @("cmd","/c","codebase-memory-mcp")

# 7. Extras opcionales
if ($Extras) {
  Paso "Extras: MCP opcionales"
  npm install -g omniroute 2>&1 | Select-Object -Last 1
  AddMcp "omniroute" @("cmd","/c","omniroute","--mcp")

  Paso "Extras: SkillSpector (escaner de seguridad)"
  $ss = Join-Path $HOME "skillspector"
  if (-not (Tiene "uv")) { Mal "falta uv: powershell -c `"irm https://astral.sh/uv/install.ps1 | iex`"" }
  else {
    if (-not (Test-Path $ss)) { git clone --depth 1 https://github.com/NVIDIA/SkillSpector.git $ss 2>&1 | Out-Null }
    Push-Location $ss; uv sync 2>&1 | Select-Object -Last 1; Pop-Location
    if (Test-Path "$ss\.venv\Scripts\skillspector.exe") { Ok "SkillSpector en $ss" } else { Mal "SkillSpector no quedo instalado" }
  }

  Paso "Extras: FreeLLMAPI (Docker)"
  $fl = Join-Path $HOME "freellmapi"
  if (-not (Tiene "docker")) { Mal "falta Docker Desktop: winget install Docker.DockerDesktop" }
  else {
    New-Item -ItemType Directory -Force $fl | Out-Null
    Copy-Item (Join-Path $Pkg "extras\freellmapi\docker-compose.yml") $fl -Force
    $envFile = Join-Path $fl ".env"
    if (-not (Test-Path $envFile)) {
      $bytes = New-Object byte[] 32; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
      $key = -join ($bytes | ForEach-Object { $_.ToString("x2") })
      [IO.File]::WriteAllText($envFile, "ENCRYPTION_KEY=$key`nPORT=3001`n")
    }
    Push-Location $fl; docker compose up -d 2>&1 | Select-Object -Last 2; Pop-Location
    Ok "FreeLLMAPI en $fl -> panel http://127.0.0.1:3001 (pon tus claves en Keys)"
  }
}

# Resumen
Paso "Resumen"
$Log | ForEach-Object { Write-Host "  $_" }
Write-Host "`nListo. Reinicia Claude Code y prueba: modo programador <proyecto> estado" -ForegroundColor Cyan
Write-Host "Pendiente manual: firecrawl login (si usas web/qa-vivo); claves de FreeLLMAPI en su panel." -ForegroundColor Cyan
