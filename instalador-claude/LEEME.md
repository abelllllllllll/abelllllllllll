# Instalador para Claude Code

Instala de una vez, en tu `~/.claude`:

- **Skills:** find-skills, content-strategy, social y baoyu-youtube-transcript (con `npx skills`).
- **SkillSpector Guard:** revisa skills y plugins de GitHub antes de instalarlos (instala `uv` y `skillspector`).
- **Agentes:** Explore (búsquedas con Haiku), investigador, redactor y revisor.
- **Mods:** panel (barra de estado con límites y caché) y vigilante (avisa si la caché se enfrió).
- **Regla `# Skills`** al final de `~/.claude/CLAUDE.md`.

No borra nada: guarda copias en `~/.claude/backup-mods` y no pisa hooks que ya tengas.
Se puede correr dos veces sin duplicar nada.

**Requisitos:** Node 22.20 o más nuevo. En Windows, Git for Windows (trae `bash`).

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/abelllllllllll/abelllllllllll/claude/nifty-gates-7dsj4h/instalador-claude/instalar.js -OutFile instalar.js; node instalar.js
```

**Mac / Linux:**
```bash
curl -fsSLo instalar.js https://raw.githubusercontent.com/abelllllllllll/abelllllllllll/claude/nifty-gates-7dsj4h/instalador-claude/instalar.js && node instalar.js
```

Al final te muestra los 4 comandos para Codex (pide iniciar sesión con ChatGPT).
