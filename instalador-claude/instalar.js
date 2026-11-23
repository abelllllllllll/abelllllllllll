#!/usr/bin/env node
// Instalador para Claude Code: skills, SkillSpector Guard, agentes y mods.
// Uso:  node instalar.js
// No borra nada: antes de tocar settings.json o CLAUDE.md guarda una copia en ~/.claude/backup-mods.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { execSync } = require('child_process');

const HOME = os.homedir();
const CLAUDE = path.join(HOME, '.claude');
const fwd = (p) => p.split(path.sep).join('/');
const esWindows = process.platform === 'win32';
const hecho = [];
const fallo = [];

const ok = (m) => { hecho.push(m); console.log('✅ ' + m); };
const mal = (m) => { fallo.push(m); console.log('⚠️  ' + m); };
const correr = (cmd) => execSync(cmd, { stdio: 'inherit', shell: true });
const existeCmd = (c) => {
  try { execSync(esWindows ? `where ${c}` : `command -v ${c}`, { stdio: 'ignore', shell: true }); return true; } catch { return false; }
};

const fecha = new Date().toISOString().slice(0, 19).replace(/[:T]/g, '-');
const BACKUP = path.join(CLAUDE, 'backup-mods');
fs.mkdirSync(BACKUP, { recursive: true });

function respaldar(ruta) {
  if (fs.existsSync(ruta)) fs.copyFileSync(ruta, path.join(BACKUP, `${path.basename(ruta)}.${fecha}`));
}

// Escribe un archivo; si ya existe con otro contenido, guarda el viejo en el backup.
function escribir(ruta, contenido, modo) {
  fs.mkdirSync(path.dirname(ruta), { recursive: true });
  if (fs.existsSync(ruta)) {
    if (fs.readFileSync(ruta, 'utf8') === contenido) return ok(`${fwd(path.relative(HOME, ruta))} ya estaba`);
    respaldar(ruta);
  }
  fs.writeFileSync(ruta, contenido);
  if (modo) fs.chmodSync(ruta, modo);
  ok(`${fwd(path.relative(HOME, ruta))} escrito`);
}

// ---------- 1. Agentes ----------
const AGENTES = {
  'Explore.md': `---
name: Explore
description: Portero. Busca archivos, lee fragmentos y ubica código o texto en el proyecto. Usalo para cualquier búsqueda o exploración que no requiera decidir ni escribir nada.
model: haiku
tools: Read, Grep, Glob, Bash
---

Sos el portero: hacés el trabajo fácil para que el modelo principal no gaste su límite en eso.

- Buscá con Grep y Glob antes de abrir archivos enteros. Leé solo los fragmentos que hacen falta.
- No edites ni crees archivos. No tomes decisiones de diseño.
- Devolvé lo encontrado corto y concreto: rutas, números de línea y el fragmento justo.
- Si la búsqueda pide razonar en serio (un bug difícil, una decisión de arquitectura), decilo y devolvé lo que encontraste para que lo resuelva el modelo principal.
`,
  'investigador.md': `---
name: investigador
description: Investiga un tema en la web y en los archivos del proyecto antes de redactar. Úsalo de forma proactiva cuando haga falta información.
tools: Read, Grep, Glob, WebSearch, WebFetch
model: sonnet
---
Eres un investigador. Busca fuentes fiables, contrasta cada dato y devuelve un resumen de 10 puntos con el enlace de cada fuente. No escribas archivos.
`,
  'redactor.md': `---
name: redactor
description: Escribe borradores (correos, posts, guiones, informes) a partir de la investigación. Úsalo después del investigador.
tools: Read, Write, Edit
model: sonnet
---
Eres un redactor. Escribe claro, con frases cortas y de tú a tú. Usa solo los datos que te pasen y guarda el borrador en la carpeta borradores/.
`,
  'revisor.md': `---
name: revisor
description: Revisa borradores y cambios antes de darlos por buenos. Úsalo siempre al final.
tools: Read, Grep, Glob
model: haiku
---
Eres un revisor exigente. Comprueba datos, tono y erratas. Devuelve una lista: qué está bien, qué cambiar y por qué. No edites nada.
`,
};
console.log('\n— Agentes —');
for (const [n, c] of Object.entries(AGENTES)) escribir(path.join(CLAUDE, 'agents', n), c);

// ---------- 2. Mods ----------
const VIGILANTE = `#!/usr/bin/env node
// Vigilante: gancho UserPromptSubmit. Si la caché ya se enfrió, frena tu mensaje UNA vez y avisa cuánto va a releer sin caché. Si lo mandás de nuevo, pasa.
const fs = require('fs');
const os = require('os');
const path = require('path');

let raw = '';
process.stdin.on('data', (c) => (raw += c));
process.stdin.on('end', () => {
  let d = {};
  try {
    d = JSON.parse(raw);
  } catch {
    process.exit(0);
  }
  const ahora = Date.now() / 1000;
  const sid = d.session_id || 'x';
  const marca = path.join(os.tmpdir(), \`claude-vigilante-\${sid}.avisado\`);

  if (fs.existsSync(marca)) {
    fs.unlinkSync(marca);
    process.exit(0);
  }

  let vence = null;
  let tokens = null;
  try {
    const e = JSON.parse(fs.readFileSync(path.join(os.tmpdir(), \`claude-vigilante-\${sid}.json\`), 'utf8'));
    vence = e.expires_at;
    tokens = e.recache_tokens_if_cold;
  } catch {}

  if (vence == null && d.transcript_path) {
    try {
      const lineas = fs.readFileSync(d.transcript_path, 'utf8').trim().split('\\n');
      for (let i = lineas.length - 1; i >= 0; i--) {
        const j = JSON.parse(lineas[i]);
        if (j.timestamp && j.type === 'assistant') {
          vence = Date.parse(j.timestamp) / 1000 + 60 * Number(process.env.VIGILANTE_TTL_MIN || 60);
          break;
        }
      }
    } catch {}
  }

  if (vence == null || ahora < vence) process.exit(0);

  const min = Math.round((ahora - vence) / 60);
  const cuanto = tokens ? \`\${Math.round(tokens).toLocaleString('es-AR')} tokens\` : 'toda la conversación';
  fs.writeFileSync(marca, String(ahora));
  process.stdout.write(
    JSON.stringify({
      decision: 'block',
      reason: \`Vigilante: la caché se enfrió hace \${min} min. Este mensaje relee \${cuanto} sin caché. Si es algo nuevo, mejor /clear; si querés seguir igual, mandalo de nuevo.\`,
    })
  );
  process.exit(0);
});
`;

const PANEL = `#!/usr/bin/env node
// Panel: barra de estado con límite de 5 h y semana, modelo, contexto y caché. Deja el estado de la caché para el vigilante.
const fs = require('fs');
const os = require('os');
const path = require('path');

let raw = '';
process.stdin.on('data', (c) => (raw += c));
process.stdin.on('end', () => {
  let d = {};
  try {
    d = JSON.parse(raw);
  } catch {}
  const pct = (x) => (x == null ? '–' : \`\${Math.round(x)}%\`);
  const barra = (x, n = 10) => {
    if (x == null) return '';
    const llenos = Math.max(0, Math.min(n, Math.round((x / 100) * n)));
    return '█'.repeat(llenos) + '░'.repeat(n - llenos);
  };
  const rl = d.rate_limits || {};
  const ctx = d.context_window || {};
  const pc = d.prompt_cache || {};
  const ahora = Date.now() / 1000;

  let cache = 'caché –';
  if (pc.expires_at && pc.warm) {
    const min = Math.max(0, Math.round((pc.expires_at - ahora) / 60));
    cache = \`caché caliente · \${min} min\`;
  } else if (pc.caching_observed) {
    cache = 'caché FRÍA';
  }

  const l1 = [
    \`[\${(d.model && d.model.display_name) || '?'}]\`,
    \`contexto \${barra(ctx.used_percentage)} \${pct(ctx.used_percentage)}\`,
    cache,
  ].join('  ');
  const l2 = [
    \`límite 5 h \${barra(rl.five_hour && rl.five_hour.used_percentage)} \${pct(rl.five_hour && rl.five_hour.used_percentage)}\`,
    \`semana \${barra(rl.seven_day && rl.seven_day.used_percentage)} \${pct(rl.seven_day && rl.seven_day.used_percentage)}\`,
  ].join('  ');
  process.stdout.write(l1 + '\\n' + l2 + '\\n');

  if (d.session_id && pc.caching_observed) {
    const f = path.join(os.tmpdir(), \`claude-vigilante-\${d.session_id}.json\`);
    try {
      fs.writeFileSync(f, JSON.stringify({expires_at: pc.expires_at || null, ttl: pc.ttl || null, recache_tokens_if_cold: pc.recache_tokens_if_cold || null, visto: ahora}));
    } catch {}
  }
});
`;

console.log('\n— Mods —');
const rutaVigilante = path.join(CLAUDE, 'mods', 'vigilante.js');
const rutaPanel = path.join(CLAUDE, 'mods', 'panel.js');
escribir(rutaVigilante, VIGILANTE);
escribir(rutaPanel, PANEL);

// ---------- 3. SkillSpector Guard (script) ----------
const GUARD = `#!/usr/bin/env bash
# ~/.claude/hooks/skillspector-guard.sh
# Hook PreToolUse (Bash) para Claude Code:
# escanea con NVIDIA SkillSpector (modo estático, --no-llm, sin gastar tokens)
# cualquier skill/plugin de GitHub antes de que Claude lo clone o instale.
#
# Decisión:
#   DO_NOT_INSTALL  -> bloquea (deny)
#   CAUTION         -> te pregunta (ask)
#   SAFE            -> deja pasar sin molestar
#   error / no instalado / timeout -> te pregunta (ask)
#
# Por defecto solo actúa con repos que parecen skills/plugins.
# Para escanear TODO clone: export SKILLSPECTOR_GUARD_ALL=1

set -uo pipefail

INPUT="$(cat)"

# --- leer el comando que Claude quiere ejecutar ---
if command -v jq >/dev/null 2>&1; then
  CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')"
else
  CMD="$(printf '%s' "$INPUT" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null)"
fi
[ -z "$CMD" ] && exit 0

# --- respuesta en el formato de hooks de Claude Code ---
decide() { # $1 = allow|ask|deny  $2 = motivo
  local reason="\${2//\\"/\\'}"
  reason="\${reason//$'\\n'/ }"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\\n' "$1" "$reason"
  exit 0
}

# --- ¿es un comando de clonar/instalar? ---
if ! printf '%s' "$CMD" | grep -Eq '(^|[;&|[:space:]])(git[[:space:]]+clone|gh[[:space:]]+repo[[:space:]]+clone|npx[[:space:]]+(-y[[:space:]]+)?skills[[:space:]]+add|claude[[:space:]]+plugin[[:space:]]+(install|add)|claude[[:space:]]+mcp[[:space:]]+add)([[:space:]]|$)'; then
  exit 0
fi

# --- sacar el repo de GitHub ---
URL="$(printf '%s' "$CMD" | grep -Eo 'https?://github\\.com/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+' | head -n1)"
if [ -z "$URL" ]; then
  URL="$(printf '%s' "$CMD" | grep -Eo 'git@github\\.com:[A-Za-z0-9._-]+/[A-Za-z0-9._-]+' | head -n1 | sed 's#git@github.com:#https://github.com/#')"
fi
if [ -z "$URL" ]; then
  # gh repo clone owner/repo
  OR="$(printf '%s' "$CMD" | grep -Eo 'gh[[:space:]]+repo[[:space:]]+clone[[:space:]]+[A-Za-z0-9._-]+/[A-Za-z0-9._-]+' | awk '{print $4}' | head -n1)"
  [ -n "$OR" ] && URL="https://github.com/$OR"
fi
URL="\${URL%.git}"
[ -z "$URL" ] && exit 0   # no es GitHub (o no se entiende): no molesta

# --- ¿parece skill/plugin? (salvo que pidas escanear todo) ---
if [ "\${SKILLSPECTOR_GUARD_ALL:-0}" != "1" ]; then
  if ! printf '%s %s' "$CMD" "$URL" | grep -Eiq 'skill|plugin|mcp|agent|claude|hook|npx[[:space:]]+(-y[[:space:]]+)?skills'; then
    exit 0
  fi
fi

# --- ¿está instalado SkillSpector? ---
export PATH="$HOME/.local/bin:$PATH"
if ! command -v skillspector >/dev/null 2>&1; then
  decide ask "SkillSpector no está instalado, no pude escanear $URL. Instalalo con: uv tool install git+https://github.com/NVIDIA/skillspector.git"
fi

# --- escanear ---
REPORT="$(mktemp -t skillspector.XXXXXX.json)"
trap 'rm -f "$REPORT"' EXIT

if command -v timeout >/dev/null 2>&1; then
  timeout 110 skillspector scan "$URL" --no-llm --format json --output "$REPORT" >/dev/null 2>&1
else
  skillspector scan "$URL" --no-llm --format json --output "$REPORT" >/dev/null 2>&1
fi
RC=$?

REC=""
SCORE=""
if [ -s "$REPORT" ] && command -v jq >/dev/null 2>&1; then
  REC="$(jq -r '[.. | objects | .recommendation? // empty] | first // empty' "$REPORT" 2>/dev/null)"
  SCORE="$(jq -r '[.. | objects | .risk_score? // empty] | first // empty' "$REPORT" 2>/dev/null)"
fi
INFO="\${REC:-sin dato}\${SCORE:+, riesgo $SCORE/100}"

case "$RC" in
  0)
    if printf '%s' "$REC" | grep -qi 'caution'; then
      decide ask "SkillSpector: $URL dio CAUTION ($INFO). Revisalo antes de instalar."
    fi
    exit 0   # SAFE: pasa sin preguntar
    ;;
  1)
    decide deny "SkillSpector BLOQUEÓ $URL ($INFO). Para ver el detalle: skillspector scan $URL --no-llm"
    ;;
  124)
    decide ask "SkillSpector tardó demasiado escaneando $URL (timeout). ¿Seguís igual?"
    ;;
  *)
    decide ask "SkillSpector no pudo escanear $URL (error $RC). ¿Seguís igual?"
    ;;
esac
`;

console.log('\n— SkillSpector Guard —');
const rutaGuard = path.join(CLAUDE, 'hooks', 'skillspector-guard.sh');
const hayBash = existeCmd('bash');
if (hayBash) escribir(rutaGuard, GUARD, 0o755);
else mal('No encontré bash (en Windows instalá Git for Windows). SkillSpector Guard queda sin instalar.');

// Instalar uv + skillspector
if (hayBash) {
  try {
    const localBin = path.join(HOME, '.local', 'bin');
    process.env.PATH = localBin + path.delimiter + process.env.PATH;
    if (!existeCmd('uv')) {
      console.log('Instalando uv…');
      if (esWindows) correr('powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"');
      else correr('curl -LsSf https://astral.sh/uv/install.sh | sh');
    }
    if (!existeCmd('skillspector')) correr('uv tool install git+https://github.com/NVIDIA/skillspector.git');
    ok('SkillSpector instalado');
  } catch (e) {
    mal('No se pudo instalar SkillSpector (uv). El hook igual queda y te va a preguntar antes de instalar skills.');
  }
  if (!existeCmd('jq')) mal('Falta jq: el guard funciona igual, pero sin mostrar el puntaje de riesgo (opcional: instalá jq).');
}

// ---------- 4. settings.json ----------
console.log('\n— settings.json —');
const rutaSettings = path.join(CLAUDE, 'settings.json');
respaldar(rutaSettings);
let settings = {};
if (fs.existsSync(rutaSettings)) {
  try {
    settings = JSON.parse(fs.readFileSync(rutaSettings, 'utf8'));
  } catch {
    mal('settings.json no es JSON válido: no lo toqué. Arreglalo y volvé a correr el instalador.');
    settings = null;
  }
}
if (settings) {
  const cmdPanel = `node "${fwd(rutaPanel)}"`;
  const cmdVigilante = `node "${fwd(rutaVigilante)}"`;
  const cmdGuard = `bash "${fwd(rutaGuard)}"`;

  if (!settings.statusLine) {
    settings.statusLine = { type: 'command', command: cmdPanel };
    ok('Barra de estado (panel) activada');
  } else if (!JSON.stringify(settings.statusLine).includes('panel.js')) {
    mal('Ya tenías otra barra de estado; no la reemplacé. Si querés el panel, poné en statusLine: ' + cmdPanel);
  } else ok('Barra de estado ya estaba');

  settings.hooks = settings.hooks || {};
  const agregarHook = (evento, entrada, marca) => {
    settings.hooks[evento] = settings.hooks[evento] || [];
    if (JSON.stringify(settings.hooks[evento]).includes(marca)) return ok(`Hook ${evento} (${marca}) ya estaba`);
    settings.hooks[evento].push(entrada);
    ok(`Hook ${evento} (${marca}) agregado`);
  };
  agregarHook('UserPromptSubmit', { hooks: [{ type: 'command', command: cmdVigilante }] }, 'vigilante.js');
  if (hayBash) agregarHook('PreToolUse', { matcher: 'Bash', hooks: [{ type: 'command', command: cmdGuard, timeout: 120 }] }, 'skillspector-guard');

  const texto = JSON.stringify(settings, null, 2) + '\n';
  JSON.parse(texto);
  fs.writeFileSync(rutaSettings, texto);
}

// ---------- 5. CLAUDE.md ----------
console.log('\n— CLAUDE.md —');
const rutaMd = path.join(CLAUDE, 'CLAUDE.md');
const actual = fs.existsSync(rutaMd) ? fs.readFileSync(rutaMd, 'utf8') : '';
if (actual.includes('# Skills')) ok('Regla de skills ya estaba');
else {
  respaldar(rutaMd);
  fs.writeFileSync(rutaMd, (actual ? actual.replace(/\s*$/, '\n\n') : '') + `# Skills
Antes de empezar una tarea:
1. Mirá si alguna skill instalada sirve. Si sirve, usala y decime cuál.
2. Si no hay ninguna y la tarea se va a repetir, buscá con find-skills.
3. Proponé como máximo 3, con autor, instalaciones y enlace.
4. No instales nada sin mi OK. Antes leé su SKILL.md y decime si ejecuta scripts.
5. Para búsquedas usá el subagente Explore; para investigar, redactar y revisar, los subagentes investigador, redactor y revisor.
`);
  ok('Regla de skills agregada a CLAUDE.md');
}

// ---------- 6. Skills con npx ----------
console.log('\n— Skills —');
const [ma, mi] = process.versions.node.split('.').map(Number);
if (ma < 22 || (ma === 22 && mi < 20)) {
  mal(`Tu Node es ${process.versions.node}; npx skills necesita 22.20 o más. Actualizá Node (nodejs.org) y volvé a correr esto.`);
} else {
  const SKILLS = [
    ['https://github.com/vercel-labs/skills', 'find-skills'],
    ['https://github.com/coreyhaines31/marketingskills', 'content-strategy'],
    ['https://github.com/coreyhaines31/marketingskills', 'social'],
    ['https://github.com/jimliu/baoyu-skills', 'baoyu-youtube-transcript'],
  ];
  for (const [repo, skill] of SKILLS) {
    try {
      correr(`npx -y skills add ${repo} --skill ${skill} -g -a claude-code -y`);
      ok(`Skill ${skill} instalada`);
    } catch {
      mal(`No se pudo instalar la skill ${skill}`);
    }
  }
}

// ---------- Resumen ----------
console.log('\n================ RESUMEN ================');
console.log(`Listo: ${hecho.length} cosas.`);
if (fallo.length) {
  console.log('Revisar:');
  fallo.forEach((f) => console.log('  - ' + f));
}
console.log(`Copias de seguridad en: ${fwd(BACKUP)}`);
console.log(`
FALTA SOLO CODEX (pide iniciar sesión con tu ChatGPT, eso lo hacés vos).
Abrí Claude Code y escribí, uno por uno:
  /plugin marketplace add openai/codex-plugin-cc
  /plugin install codex@openai-codex
  /reload-plugins
  /codex:setup

Después cerrá y volvé a abrir Claude Code y mirá la barra de abajo.`);
