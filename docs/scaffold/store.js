/* Scaffold — state and persistence.
 *
 * Mirrors the iOS DataStore: one blob, saved locally, never transmitted.
 * On the web that means localStorage. Same reasoning as the native app — this
 * holds someone's un-assessed mental health notes, so it stays on the device.
 */

const KEY = 'scaffold.v1';

const uid = () => Math.random().toString(36).slice(2, 10) + Date.now().toString(36);

function seedRoutines() {
  return CONTENT.routines.map(r => ({
    id: uid(),
    name: r.name,
    symbol: r.symbol,
    enabled: true,
    steps: r.steps.map(s => ({ id: uid(), text: s.text, minutes: s.minutes })),
  }));
}

function blank() {
  return {
    tasks: [],
    captures: [],
    moods: [],
    routines: seedRoutines(),
    sessions: [],
    wins: [],
    screenerRuns: [],
    evidence: [],
    dopamineMenu: CONTENT.dopamineMenu.slice(),
    onboarded: false,
  };
}

let S = blank();

function load() {
  try {
    const raw = localStorage.getItem(KEY);
    if (raw) S = Object.assign(blank(), JSON.parse(raw));
  } catch (e) {
    console.warn('could not read saved data', e);
  }
}

let saveTimer = null;
function save() {
  clearTimeout(saveTimer);
  saveTimer = setTimeout(() => {
    try {
      localStorage.setItem(KEY, JSON.stringify(S));
    } catch (e) {
      // Private-browsing or a full quota. Better to keep working than to crash.
      console.warn('could not save', e);
      toast('Could not save — storage is unavailable');
    }
  }, 250);
}

/* ---------------------------------------------------------------- capture */

function capture(text) {
  const t = (text || '').trim();
  if (!t) return;
  S.captures.unshift({ id: uid(), text: t, at: Date.now(), triaged: false });
  save();
}

const untriaged = () => S.captures.filter(c => !c.triaged);

function markTriaged(id) {
  const c = S.captures.find(x => x.id === id);
  if (c) { c.triaged = true; save(); }
}

function deleteCapture(id) {
  S.captures = S.captures.filter(x => x.id !== id);
  save();
}

function promoteToTask(item) {
  S.tasks.unshift(newTask(item.text, { today: true }));
  markTriaged(item.id);
}

/* ---------------------------------------------------------------- tasks */

function newTask(title, opts = {}) {
  return {
    id: uid(),
    title: title.trim(),
    steps: [],
    cost: opts.cost || 2,       // 1 easy, 2 medium, 3 wall
    predicted: null,
    actual: null,
    today: !!opts.today,
    createdAt: Date.now(),
    completedAt: null,
  };
}

const task = id => S.tasks.find(t => t.id === id);
const openTasks = () => S.tasks.filter(t => !t.completedAt);
const todayTasks = () => openTasks().filter(t => t.today);

function addTask(t) { S.tasks.unshift(t); save(); }
function deleteTask(id) { S.tasks = S.tasks.filter(t => t.id !== id); save(); }

function completeTask(id) {
  const t = task(id);
  if (!t) return;
  t.completedAt = Date.now();
  logWin(t.title, 'task');
  save();
}

function stepProgress(t) {
  if (!t.steps.length) return t.completedAt ? 1 : 0;
  return t.steps.filter(s => s.done).length / t.steps.length;
}

function toggleStep(taskId, stepId) {
  const t = task(taskId);
  if (!t) return;
  const s = t.steps.find(x => x.id === stepId);
  if (s) { s.done = !s.done; save(); haptic(); }
}

/* ---------------------------------------------------------------- wins */

function logWin(text, source = 'manual') {
  const t = (text || '').trim();
  if (!t) return;
  S.wins.unshift({ id: uid(), text: t, at: Date.now(), source });
  save();
}

const isToday = ts => new Date(ts).toDateString() === new Date().toDateString();
const winsToday = () => S.wins.filter(w => isToday(w.at));

/* ---------------------------------------------------------------- mood */

function logMood(m) {
  S.moods.unshift(Object.assign({ id: uid(), at: Date.now() }, m));
  save();
}

/* ---------------------------------------------------------------- focus */

function startSession(mode, minutes, taskTitle) {
  const s = { id: uid(), mode, minutes, taskTitle: taskTitle || null, start: Date.now(), end: null, full: false };
  S.sessions.unshift(s);
  save();
  return s;
}

function finishSession(id, full) {
  const s = S.sessions.find(x => x.id === id);
  if (!s) return;
  s.end = Date.now();
  s.full = full;
  if (full) logWin(`Focused for ${s.minutes} minutes`, 'focus');
  save();
}

function focusMinutesToday() {
  return S.sessions
    .filter(s => isToday(s.start))
    .reduce((sum, s) => sum + Math.max(0, Math.round(((s.end || Date.now()) - s.start) / 60000)), 0);
}

/* ------------------------------------------------------- time calibration */

/* The user's personal "everything takes longer than I think" factor.
   Duration estimation leans on working memory and prospective timing, so the
   error tends to be systematic rather than random — and systematic error is
   correctable. Returns null until there's enough data to be honest about. */
function timeMultiplier() {
  const ratios = S.tasks
    .filter(t => t.predicted > 0 && t.actual > 0)
    .map(t => t.actual / t.predicted);
  if (ratios.length < 3) return null;
  return ratios.reduce((a, b) => a + b, 0) / ratios.length;
}

const calibrationCount = () => S.tasks.filter(t => t.predicted > 0 && t.actual > 0).length;

/* ---------------------------------------------------------------- screener */

function partAFlags(answers) {
  return CONTENT.asrs.partA.reduce(
    (n, item, i) => n + (answers[i] >= item.threshold ? 1 : 0), 0);
}

function subscale(answers, indices) {
  return indices.reduce((n, i) => n + Math.max(0, answers[i] || 0), 0);
}

function saveScreener(answers) {
  S.screenerRuns.unshift({ id: uid(), at: Date.now(), answers });
  save();
}

const latestScreener = () => S.screenerRuns[0] || null;

/* ---------------------------------------------------------------- evidence */

function addEvidence(domain, text, childhood) {
  S.evidence.unshift({ id: uid(), at: Date.now(), domain, text: text.trim(), childhood: !!childhood });
  save();
}

function deleteEvidence(id) {
  S.evidence = S.evidence.filter(e => e.id !== id);
  save();
}

const DOMAINS = [
  { key: 'work',          label: 'Work or study',    icon: '💼' },
  { key: 'home',          label: 'Home & admin',     icon: '🏠' },
  { key: 'money',         label: 'Money',            icon: '💳' },
  { key: 'relationships', label: 'Relationships',    icon: '❤️' },
  { key: 'health',        label: 'Health & sleep',   icon: '🛏️' },
  { key: 'selfEsteem',    label: 'How I see myself', icon: '🪞' },
];

const domainLabel = k => (DOMAINS.find(d => d.key === k) || {}).label || k;

/* ---------------------------------------------------------------- routines */

const routine = id => S.routines.find(r => r.id === id);
const routineMinutes = r => r.steps.reduce((n, s) => n + s.minutes, 0);

function eraseEverything() {
  S = blank();
  try { localStorage.removeItem(KEY); } catch (e) { /* nothing to do */ }
  save();
}

/* ---------------------------------------------------------------- feedback */

function haptic() {
  if (navigator.vibrate) navigator.vibrate(8);
}

let toastTimer = null;
function toast(msg) {
  let el = document.getElementById('toast');
  if (!el) {
    el = document.createElement('div');
    el.id = 'toast';
    el.className = 'toast';
    document.body.appendChild(el);
  }
  el.textContent = msg;
  el.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.classList.remove('show'), 2200);
}
