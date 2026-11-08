"""Panorama de todos los sistemas del usuario a partir de la memoria de Claude Code.

Uso:
  python proyectos.py              # tabla: ruta, git, sin subir, último commit, bloqueos
  python proyectos.py bloqueos     # solo las líneas BLOQUEADO / falta / pendiente de cada proyecto
  python proyectos.py buscar <txt> # proyecto cuyo nombre/disparador contiene <txt> -> ruta
"""
import re
import subprocess
import sys
from pathlib import Path

MEMS = list((Path.home() / ".claude/projects").glob("*/memory"))
RUTA = re.compile(r"[A-Z]:[\\/][^\n`\"'*)(<>|]+")
BLOQ = re.compile(r"(bloquead[oa]|🔴|falta[n]? |pendiente)", re.I)


def leer(f):
    try:
        return f.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return f.read_text(encoding="cp1252", errors="replace")


def proyectos():
    for f in sorted(p for m in MEMS for p in m.glob("*.md")):
        t = leer(f)
        if "type: project" not in t or f.name.startswith("caso-"):
            continue
        desc = re.search(r"^description:\s*(.+)$", t, re.M)
        yield f.stem, (desc.group(1).strip('"') if desc else ""), t


def repo(texto):
    """Primera ruta existente con .git (sube por los padres por si apunta a un subdirectorio)."""
    for m in RUTA.finditer(texto):
        p = Path(m.group(0).strip().rstrip(".,;:"))
        for c in [p, *p.parents][:4]:
            try:
                if (c / ".git").exists():
                    return c
            except OSError:
                break
    return None


def git(r, *a):
    try:
        return subprocess.run(["git", "-C", str(r), *a], capture_output=True, text=True,
                              encoding="utf-8", errors="replace", timeout=15).stdout.strip()
    except Exception:
        return ""


def tabla():
    print(f"{'proyecto':28} {'rama':10} {'cambios':>7} {'sin subir':>9} {'último commit':12} bloqueos  ruta")
    for nombre, _, t in proyectos():
        r = repo(t)
        nb = sum(1 for l in t.splitlines() if BLOQ.search(l))
        if not r:
            if "app" not in nombre:  # notas de casos/documentos, no sistemas
                continue
            print(f"{nombre[:28]:28} {'-':10} {'-':>7} {'-':>9} {'-':12} {nb:>8}  (sin repo local)")
            continue
        rama = git(r, "branch", "--show-current") or "?"
        cambios = len([l for l in git(r, "status", "--porcelain").splitlines() if l])
        arriba = git(r, "rev-list", "--count", "@{u}..HEAD") or "s/rem"
        fecha = git(r, "log", "-1", "--format=%cs") or "-"
        print(f"{nombre[:28]:28} {rama[:10]:10} {cambios:>7} {arriba:>9} {fecha:12} {nb:>8}  {r}")


def bloqueos():
    for nombre, _, t in proyectos():
        ls = [l.strip()[:160] for l in t.splitlines() if re.search(r"bloquead[oa]|🔴", l, re.I)]
        if ls:
            print(f"\n## {nombre}")
            for l in ls[:6]:
                print(f"- {l}")


def buscar(txt):
    txt = txt.lower()
    for nombre, desc, t in proyectos():
        if txt in nombre.lower() or txt in desc.lower():
            print(f"{nombre}: {repo(t) or '(sin repo local)'}\n  {desc[:200]}")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    a = sys.argv[1:]
    if not a:
        tabla()
    elif a[0] == "bloqueos":
        bloqueos()
    elif a[0] == "buscar" and len(a) > 1:
        buscar(" ".join(a[1:]))
    else:
        print(__doc__)
