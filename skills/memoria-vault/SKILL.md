---
name: memoria-vault
description: Leer y escribir la memoria del usuario en su vault de Obsidian (AI Brain). Úsala al empezar o terminar cualquier tarea de un proyecto, o cuando el usuario diga "recuerda", "anota", "qué sabemos de", "guarda esta decisión".
---
# Memoria en el vault (AI Brain)

Ruta del vault: `{{VAULT}}`. Las reglas completas están en `{{VAULT}}/_AI/README.md` — léelo si no lo has leído en esta sesión.

## Leer
1. `_AI/index.md` para ubicarte.
2. `01-Proyectos/<proyecto>.md` para el estado.
3. Busca antes de preguntar: `Grep` por nombre del proyecto, etiqueta o palabra clave en el vault.

## Escribir — elige el destino
| Qué es | Dónde | Plantilla |
|---|---|---|
| Estado / próximos pasos | `01-Proyectos/<proyecto>.md` (editar secciones) | proyecto |
| Decisión | `03-Decisiones/AAAA-MM-DD titulo.md` | decision |
| Lección | `04-Lecciones/AAAA-MM-DD titulo.md` | leccion |
| Idea | `05-Ideas/AAAA-MM-DD titulo.md` | idea |
| Nota/reunión/investigación | `02-Notas/AAAA-MM-DD titulo.md` | nota |
| Pendiente | línea en `00-Bandeja/bandeja.md` | `- [ ] texto #proyecto 📅 fecha` |

Reglas: copia la plantilla de `99-Plantillas/`, sustituye `{{title}}` y `{{date:YYYY-MM-DD}}`, rellena el frontmatter, enlaza `[[proyecto]]`. Añade líneas en lugar de reescribir. Nunca borres (mueve a `00-Bandeja/archivo/`). Nunca guardes secretos.

Al terminar, di en una línea qué guardaste y dónde.
