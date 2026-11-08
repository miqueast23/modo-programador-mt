# Modo programador MT para Claude Code

Un mod para Claude Code que trabaja como programador: 20 atajos (`nuevo`, `bug`, `ui`, `revisar`, `probar`, `desplegar`, `video`, `escanear`…).
- Incluye 43 skills, 10 agentes, plugins (superpowers, ponytail, firecrawl, lemo-opuscar…) y MCP (context7, playwright, codebase-memory).
- Detalle completo en [INSTALAR.md](INSTALAR.md).

## Instalar

Requisitos: [Claude Code](https://docs.anthropic.com/claude-code), Node 20+, git. Opcionales: Python 3.11+, ffmpeg y Docker Desktop (para los extras).

**Windows (PowerShell):**
```powershell
git clone https://github.com/miqueast23/modo-programador-mt.git
cd modo-programador-mt
powershell -ExecutionPolicy Bypass -File .\instalar.ps1 -Extras
```

**macOS / Linux:**
```bash
git clone https://github.com/miqueast23/modo-programador-mt.git
cd modo-programador-mt
bash instalar.sh --extras
```

Opciones:
- `-Vault "<ruta>"` / `--vault "<ruta>"`: usar un vault de Obsidian como memoria.
- Sin `-Extras` / `--extras`: no instala FreeLLMAPI, SkillSpector ni omniroute.
- `-Forzar` / `--forzar`: reemplaza skills que ya existan.

**Otra forma:** abrir Claude Code en esta carpeta y decirle *"lee INSTALAR.md e instala"*.

Al terminar, reinicia Claude Code y prueba: `modo programador <tu-proyecto> estado`.

## Después de instalar

- `firecrawl login` si vas a usar `web` o `qa-vivo`.
- FreeLLMAPI: abrir http://127.0.0.1:3001 → **Keys** y poner tus claves de proveedores.
- Nunca pegues claves en el chat.

## Actualizar

```
git pull
```
Luego vuelve a correr el instalador con `-Forzar` / `--forzar`.
