/* Scaffold — views and routing.
 *
 * Plain DOM, no framework. Views return HTML; a single delegated click handler
 * dispatches on data-act. Re-rendering only happens on explicit actions, so
 * typing into a field is never interrupted mid-keystroke.
 */

/* SF Symbol names in the shared content map onto emoji here — universally
   available on iOS, legible at small sizes, and no icon font to download. */
const ICONS = {
  'lightbulb': '💡', 'bolt.heart': '⚡', 'slider.horizontal.3': '🎛',
  'clock.badge.exclamationmark': '⏰', 'chart.line.uptrend.xyaxis': '📈',
  'shield.lefthalf.filled': '🧱', 'person.2.fill': '👥', 'pause.circle': '⏸',
  'eye.slash': '🙈', 'list.clipboard': '📋', 'heart.slash': '💔',
  'cloud.rain': '🌧', 'moon.stars': '🌙', 'figure.run': '🏃', 'scope': '🎯',
  'person.crop.circle.badge.questionmark': '🎭', 'questionmark.circle': '❓',
  'stethoscope': '🩺', 'tornado': '🌀', 'iphone.slash': '📵',
  'questionmark.bubble': '💭', 'waveform.path': '📶', 'phone.badge.waveform': '📞',
  'moon.zzz': '😴', 'arrow.triangle.swap': '🔄', 'flame': '🔥',
  'arrow.triangle.branch': '🔀', 'shippingbox': '📦', 'arrow.triangle.2.circlepath': '🔁',
  'sun.max': '☀️', 'figure.walk': '🚶', 'circle': '⭕',
  'book.closed': '📖', 'clock': '🕐', 'checkmark.circle': '✅', 'heart': '❤️',
  'bed.double': '🛏', 'timer': '⏱',
};
const icon = name => ICONS[name] || '•';

const TINTS = { violet: 'violet', sky: 'sky', coral: 'coral', amber: 'amber', mint: 'mint' };
const tint = t => TINTS[t] || 'violet';

const COSTS = [
  null,
  { label: 'I could just do it', short: 'Low' },
  { label: 'Needs a run-up', short: 'Medium' },
  { label: "There's a wall in front of it", short: 'Wall' },
];

const MODES = [
  { key: 'sprint', title: 'Sprint', icon: '⚡', tint: 'violet',
    blurb: 'A short, bounded block. The end is visible from the start.',
    lengths: [5, 10, 15, 25, 45], def: 25 },
  { key: 'bodyDouble', title: 'Body double', icon: '👥', tint: 'sky',
    blurb: 'Work alongside a presence that checks in. Borrowed activation.',
    lengths: [25, 45, 60, 90], def: 45 },
  { key: 'hyperfocusGuard', title: 'Hyperfocus guard', icon: '🛡', tint: 'amber',
    blurb: "For when you'll disappear into it. Nudges you to eat, drink, move.",
    lengths: [60, 90, 120, 180], def: 90 },
];
const mode = k => MODES.find(m => m.key === k) || MODES[0];

/* ---------------------------------------------------------------- helpers */

function esc(s) {
  return String(s == null ? '' : s)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

/* Preserves paragraph breaks from the source prose. */
const para = s => esc(s).split('\n').filter(Boolean).map(p => `<p>${p}</p>`).join('');

const el = id => document.getElementById(id);
const val = id => (el(id) ? el(id).value : '');

function card(inner, t = 'violet', cls = '') {
  return `<div class="card tint-${tint(t)} ${cls}">${inner}</div>`;
}

function btn(label, act, opts = {}) {
  const style = opts.style || 'filled';
  const v = opts.tint ? ` v-${tint(opts.tint)}` : '';
  const data = opts.arg ? ` data-arg="${esc(opts.arg)}"` : '';
  return `<button class="btn ${style}${v}" data-act="${act}"${data}>${opts.icon ? opts.icon + ' ' : ''}${esc(label)}</button>`;
}

function bar(value, t = 'violet') {
  const pct = Math.max(0, Math.min(1, value)) * 100;
  return `<div class="bar v-${tint(t)}"><i style="width:${pct}%"></i></div>`;
}

function empty(t, m, ic = '✨') {
  return `<div class="empty"><span class="ic">${ic}</span><div class="t">${esc(t)}</div><div class="m">${esc(m)}</div></div>`;
}

const note = t => `<div class="note"><span>ℹ️</span><span>${esc(t)}</span></div>`;

function relDate(ts) {
  const d = new Date(ts);
  if (isToday(ts)) return 'Today';
  const y = new Date(Date.now() - 86400000);
  if (d.toDateString() === y.toDateString()) return 'Yesterday';
  return d.toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' });
}

const fmtMin = m => (m >= 60 ? (m % 60 ? `${Math.floor(m / 60)}h${m % 60}` : `${m / 60}h`) : `${m}m`);

/* ---------------------------------------------------------------- timer */

/* Date-based rather than tick-accumulating: a phone that locks or an app that
   backgrounds must not make the countdown quietly wrong. */
const Timer = {
  endAt: null, total: 0, pausedLeft: null, running: false, finished: false,
  iv: null, onFinish: null,

  start(seconds) {
    this.total = Math.max(1, seconds);
    this.endAt = Date.now() + this.total * 1000;
    this.pausedLeft = null;
    this.running = true;
    this.finished = false;
    this._tick();
    clearInterval(this.iv);
    this.iv = setInterval(() => this._tick(), 250);
  },
  remaining() {
    if (this.pausedLeft != null) return this.pausedLeft;
    if (!this.endAt) return 0;
    return Math.max(0, (this.endAt - Date.now()) / 1000);
  },
  progress() { return this.total ? 1 - this.remaining() / this.total : 0; },
  pause() { if (this.running) { this.pausedLeft = this.remaining(); this.running = false; clearInterval(this.iv); this._paint(); } },
  resume() {
    if (this.running || this.pausedLeft == null) return;
    this.endAt = Date.now() + this.pausedLeft * 1000;
    this.pausedLeft = null;
    this.running = true;
    clearInterval(this.iv);
    this.iv = setInterval(() => this._tick(), 250);
    this._paint();
  },
  add(seconds) {
    this.total += seconds;
    if (this.pausedLeft != null) this.pausedLeft += seconds;
    else if (this.endAt) this.endAt += seconds * 1000;
    this.finished = false;
    this._paint();
  },
  stop() { clearInterval(this.iv); this.iv = null; this.endAt = null; this.pausedLeft = null; this.running = false; },
  display() {
    const t = Math.max(0, Math.round(this.remaining()));
    return `${Math.floor(t / 60)}:${String(t % 60).padStart(2, '0')}`;
  },
  _tick() {
    this._paint();
    if (this.running && this.remaining() <= 0 && !this.finished) {
      this.finished = true;
      this.running = false;
      clearInterval(this.iv);
      haptic();
      if (this.onFinish) this.onFinish();
    }
  },
  _paint() {
    const fill = document.querySelector('.ring .fill');
    const time = document.querySelector('.ring .time');
    if (!fill || !time) return;
    const C = 2 * Math.PI * 110;
    fill.setAttribute('stroke-dasharray', C);
    fill.setAttribute('stroke-dashoffset', C * Math.min(1, Math.max(0, this.progress())));
    time.textContent = this.display();
  },
};

function ring(t = 'violet', caption = '') {
  return `<svg class="ring v-${tint(t)}" viewBox="0 0 250 250">
    <circle class="track" cx="125" cy="125" r="110"></circle>
    <circle class="fill" cx="125" cy="125" r="110" stroke-dasharray="691" stroke-dashoffset="0"></circle>
    <text class="time" x="125" y="${caption ? 118 : 128}" text-anchor="middle" dominant-baseline="middle">0:00</text>
    ${caption ? `<text class="cap" x="125" y="152" text-anchor="middle">${esc(caption)}</text>` : ''}
  </svg>`;
}

/* ---------------------------------------------------------------- routing */

let V = {};   // transient per-view state, cleared on navigation

const go = hash => { location.hash = hash; };
const back = () => history.length > 1 ? history.back() : go('#/today');

const TABS = [
  { key: 'today',   label: 'Today',   icon: '🌤' },
  { key: 'focus',   label: 'Focus',   icon: '⏱' },
  { key: 'toolbox', label: 'Toolbox', icon: '🧰' },
  { key: 'learn',   label: 'Learn',   icon: '📚' },
  { key: 'path',    label: 'Path',    icon: '🧭' },
];

let lastRoute = null;

function render() {
  if (!S.onboarded) return renderOnboarding();

  const raw = location.hash.replace(/^#\/?/, '') || 'today';
  const [name, arg] = raw.split('/');
  const view = (VIEWS[name] || VIEWS.today)(arg);

  /* Re-rendering rebuilds the DOM, which would otherwise discard whatever the
     user had half-typed — picking a duration would silently eat the task name
     they'd just entered. Snapshot field values and put them back, but only
     within the same screen, so navigating away still starts clean. */
  const keep = {};
  if (lastRoute === raw) {
    document.querySelectorAll('input[id], textarea[id]').forEach(n => {
      if (n.type !== 'checkbox' && n.value) keep[n.id] = n.value;
    });
  }
  lastRoute = raw;

  const isTab = TABS.some(t => t.key === name);
  document.body.innerHTML = `
    <header class="topbar">
      <div class="slot">${isTab ? '' : '<button data-act="back">‹ Back</button>'}</div>
      <h1>${esc(view.title || '')}</h1>
      <div class="slot right">${view.right || ''}</div>
    </header>
    <main class="wrap">${view.html}</main>
    ${isTab ? `<nav class="tabbar">${TABS.map(t =>
      `<button data-act="tab" data-arg="${t.key}" aria-current="${t.key === name}">
        <span class="ic">${t.icon}</span><span>${t.label}</span></button>`).join('')}</nav>` : ''}
  `;
  Object.keys(keep).forEach(id => {
    const n = el(id);
    if (n && !n.value) n.value = keep[id];
  });

  window.scrollTo(0, 0);
  if (view.mount) view.mount();
}

function navigate() {
  Timer.stop();
  Timer.onFinish = null;
  V = {};
  render();
}

/* ---------------------------------------------------------------- actions */

const ACTIONS = {
  back, tab: a => go('#/' + a), goto: a => go('#/' + a),

  /* capture */
  saveCapture() {
    const text = val('capture-text');
    if (!text.trim()) return back();
    text.trim().split('\n').filter(l => l.trim()).forEach(capture);
    toast('Saved');
    back();
  },
  saveCaptureMore() {
    const text = val('capture-text');
    if (!text.trim()) return;
    text.trim().split('\n').filter(l => l.trim()).forEach(capture);
    el('capture-text').value = '';
    el('capture-text').focus();
    toast('Saved — keep going');
  },
  triageTask(a) { const c = S.captures.find(x => x.id === a); if (c) promoteToTask(c); render(); },
  triageWin(a)  { const c = S.captures.find(x => x.id === a); if (c) { logWin(c.text, 'capture'); markTriaged(a); } render(); },
  triageKeep(a) { markTriaged(a); render(); },
  triageBin(a)  { deleteCapture(a); render(); },

  /* tasks */
  newTaskCost(a) { V.cost = +a; render(); },
  newTaskToday() { V.today = !V.today; render(); },
  createTask() {
    const title = val('task-title').trim();
    if (!title) return toast('Give it a name first');
    addTask(newTask(title, { cost: V.cost || 2, today: V.today !== false }));
    back();
  },
  completeTask(a) { completeTask(a); render(); },
  toggleStep(a) { const [t, s] = a.split(':'); toggleStep(t, s); render(); },
  addStep(a) {
    const t = task(a), text = val('new-step').trim();
    if (!t || !text) return;
    t.steps.push({ id: uid(), text, done: false });
    save(); render();
  },
  predict(a) {
    const [id, m] = a.split(':');
    const t = task(id);
    if (t) { t.predicted = +m; save(); haptic(); render(); }
  },
  toggleToday(a) { const t = task(a); if (t) { t.today = !t.today; save(); render(); } },
  deleteTask(a) { if (confirm('Delete this task?')) { deleteTask(a); go('#/tasks'); } },
  pickActual(a) { V.actual = +a; render(); },
  finishTask(a) {
    const t = task(a);
    if (t && V.actual) t.actual = V.actual;
    completeTask(a);
    toast('Logged');
    go('#/tasks');
  },
  skipActual(a) { completeTask(a); go('#/tasks'); },

  /* breakdown */
  bdPrompt() { V.prompt = ((V.prompt || 0) + 1) % CONTENT.breakdownQuestions.length; render(); },
  bdAdd() { V.drafts = readDrafts().concat(['']); render(); },
  bdRemove(a) { const d = readDrafts(); d.splice(+a, 1); V.drafts = d.length ? d : ['']; render(); },
  bdPattern(a) { V.drafts = CONTENT.breakdownPatterns[+a].steps.slice(); render(); },
  bdSave(a) {
    const t = task(a);
    const steps = readDrafts().map(s => s.trim()).filter(Boolean);
    if (!t || !steps.length) return back();
    t.steps = steps.map(text => ({ id: uid(), text, done: false }));
    save(); toast('Steps saved'); back();
  },

  /* focus */
  pickLength(a) { V.minutes = +a; render(); },
  startFocus(a) {
    const m = mode(a);
    V.minutes = V.minutes || m.def;
    V.taskText = val('focus-task') || '';
    V.session = startSession(m.key, V.minutes, V.taskText);
    V.started = true;
    V.checks = 0;
    // Start the clock before painting — rendering first would read
    // Timer.running as false and label a live session "Resume"/"Paused".
    Timer.onFinish = () => { if (m.key === 'hyperfocusGuard') { V.check = true; } render(); };
    Timer.start(V.minutes * 60);
    render();
    haptic();
  },
  pauseFocus() { Timer.running ? Timer.pause() : Timer.resume(); render(); },
  addFive() { Timer.add(300); toast('+5 minutes'); },
  againFocus() { V.check = false; Timer.start(15 * 60); render(); },
  closeCheck() { V.check = false; render(); },
  endFocus(a) {
    if (V.session) finishSession(V.session.id, a === 'full');
    Timer.stop();
    go('#/focus');
  },

  /* routines */
  routineNext(a) {
    const r = routine(a);
    if (!r) return;
    if ((V.step || 0) + 1 < r.steps.length) { V.step = (V.step || 0) + 1; haptic(); }
    else { logWin(`${r.name} routine`, 'routine'); V.done = true; }
    render();
  },
  routineToggle(a) { const r = routine(a); if (r) { r.enabled = !r.enabled; save(); render(); } },
  routineAddStep(a) {
    const r = routine(a), text = val('rstep-' + a).trim();
    if (r && text) { r.steps.push({ id: uid(), text, minutes: 2 }); save(); render(); }
  },
  routineDelStep(a) {
    const [rid, sid] = a.split(':');
    const r = routine(rid);
    if (r) { r.steps = r.steps.filter(s => s.id !== sid); save(); render(); }
  },
  routineNew() {
    const name = val('new-routine').trim();
    if (!name) return;
    S.routines.push({ id: uid(), name, symbol: 'circle', enabled: true, steps: [] });
    save(); render();
  },
  routineDelete(a) {
    if (!confirm('Delete this anchor?')) return;
    S.routines = S.routines.filter(r => r.id !== a);
    save(); render();
  },

  /* mood */
  setValence(a) { V.valence = +a; render(); },
  setEnergy(a) { V.energy = +a; render(); },
  toggleFeeling(a) {
    V.feelings = V.feelings || [];
    V.feelings = V.feelings.includes(a) ? V.feelings.filter(f => f !== a) : V.feelings.concat([a]);
    render();
  },
  saveMood() {
    const feelings = V.feelings || [];
    logMood({
      valence: V.valence || 3, energy: V.energy || 3, feelings,
      note: val('mood-note').trim(), rsd: feelings.includes('Rejected'),
    });
    toast('Logged');
    back();
  },

  /* dopamine menu */
  menuAdd() {
    const t = val('menu-new').trim();
    if (!t) return;
    S.dopamineMenu.push(t); save(); render();
  },
  menuDel(a) { S.dopamineMenu.splice(+a, 1); save(); render(); },

  /* wins */
  addWin() {
    const t = val('win-text').trim();
    if (!t) return;
    logWin(t); toast('Logged'); render();
  },

  /* toolbox */
  toolTimer(a) { V.timing = true; render(); Timer.start(+a); },
  toolNext(a) {
    const tool = CONTENT.interventions.find(t => t.id === a);
    const step = tool.steps[V.step || 0];
    if (step.prompt) {
      V.responses = (V.responses || []).concat([val('tool-input').trim()]);
    }
    Timer.stop();
    V.timing = false;
    if ((V.step || 0) + 1 < tool.steps.length) { V.step = (V.step || 0) + 1; haptic(); }
    else { logWin(`Worked through: ${tool.trigger}`, 'toolbox'); V.done = true; }
    render();
  },
  toolSave() {
    (V.responses || []).filter(Boolean).forEach(capture);
    toast('Saved to your notes');
    go('#/toolbox');
  },
  toolLogRsd() {
    logMood({ valence: 2, energy: 3, feelings: ['Rejected'],
      note: (V.responses || []).filter(Boolean).join(' / '), rsd: true });
    toast('Logged');
    go('#/toolbox');
  },

  /* screener */
  answer(a) {
    V.answers[V.q] = +a;
    haptic();
    if (V.q + 1 < 18) { V.q++; render(); }
    else { saveScreener(V.answers.slice()); go('#/result'); }
  },
  prevQ() { if (V.q > 0) { V.q--; render(); } },
  toggleSources() { V.sources = !V.sources; render(); },

  /* evidence */
  evDomain(a) { V.domain = a; render(); },
  evChildhood() { V.childhood = !V.childhood; render(); },
  evSave() {
    const text = val('ev-text').trim();
    if (!text) return toast('Write what happened first');
    addEvidence(V.domain || 'work', text, V.childhood);
    toast('Saved');
    back();
  },
  evDelete(a) { deleteEvidence(a); render(); },

  /* summary */
  async share() {
    const text = buildSummary();
    try {
      if (navigator.share) { await navigator.share({ title: 'Scaffold summary', text }); return; }
      await navigator.clipboard.writeText(text);
      toast('Copied to clipboard');
    } catch (e) {
      if (e && e.name === 'AbortError') return;   // user dismissed the share sheet
      toast('Could not share — select the text and copy it');
    }
  },

  /* settings */
  erase() {
    if (!confirm('Erase everything? This cannot be undone.')) return;
    eraseEverything();
    go('#/today');
    location.reload();
  },

  /* onboarding */
  obNext() { V.page = (V.page || 0) + 1; renderOnboarding(); },
  obDone() { S.onboarded = true; save(); location.hash = '#/today'; render(); },
};

function readDrafts() {
  const nodes = document.querySelectorAll('[data-draft]');
  return nodes.length ? Array.from(nodes).map(n => n.value) : (V.drafts || ['']);
}

document.addEventListener('click', e => {
  const t = e.target.closest('[data-act]');
  if (!t) return;
  const fn = ACTIONS[t.dataset.act];
  if (!fn) return;
  e.preventDefault();
  fn(t.dataset.arg);
});

window.addEventListener('hashchange', navigate);

/* ---------------------------------------------------------------- views */

const VIEWS = {};

/* ---- Today ---- */

VIEWS.today = () => {
  const h = new Date().getHours();
  const greet = h < 5 || h >= 22 ? "It's late." : h < 12 ? 'Morning.' : h < 17 ? 'Afternoon.' : 'Evening.';
  const mins = focusMinutesToday();
  const sub = (h >= 22 || h < 5)
    ? 'No judgement. If you\'re winding down, there\'s a script for that in the Toolbox.'
    : mins > 0 ? `${mins} minutes of focus logged today. That's real.`
               : 'Nothing logged yet. That\'s a neutral fact, not a verdict.';

  const tasks = todayTasks();
  const inbox = untriaged();

  return {
    title: new Date().toLocaleDateString(undefined, { weekday: 'long' }),
    right: '<button data-act="goto" data-arg="capture">✎</button>',
    html: `
      ${card(`<div class="head">${greet}</div><div class="sub" style="margin:0">${esc(sub)}</div>`, 'amber')}

      <button class="card tint-sky tappable" data-act="goto" data-arg="capture">
        <div class="row"><span style="font-size:22px">🧠</span>
          <div class="grow"><div class="head" style="margin:0">Get it out of your head</div>
            <div class="tiny">Don't organise it. Just put it down.</div></div>
          <span class="chev">›</span></div>
      </button>

      ${card(`
        <div class="head">Today</div>
        <div class="sub">${tasks.length ? 'One at a time. The rest can wait.' : 'Nothing on today\'s list.'}</div>
        ${tasks.length ? tasks.slice(0, 3).map(taskRow).join('')
          : btn('Pick something', 'goto', { arg: 'tasks', style: 'tonal', icon: '＋' })}
        ${tasks.length ? `<button class="btn link" data-act="goto" data-arg="tasks" style="text-align:left;justify-content:flex-start;color:var(--violet);font-weight:600">All tasks ›</button>` : ''}
      `, 'violet')}

      ${inbox.length ? `<button class="card tint-sky tappable" data-act="goto" data-arg="triage">
        <div class="row"><span class="chip sky filled" style="min-width:34px;text-align:center">${inbox.length}</span>
        <div class="grow"><div class="head" style="margin:0">In your inbox</div>
        <div class="tiny">Sort them when you've got the capacity</div></div><span class="chev">›</span></div></button>` : ''}

      ${card(`
        <div class="head">Anchors</div><div class="sub">Short on purpose</div>
        ${S.routines.filter(r => r.enabled).map(r => `
          <button class="list-item" data-act="goto" data-arg="routine/${r.id}">
            <span class="tick">${icon(r.symbol)}</span>
            <span class="grow">${esc(r.name)}</span>
            <span class="tiny">${routineMinutes(r)} min ›</span>
          </button>`).join('') || '<div class="tiny">No anchors yet.</div>'}
        <button class="btn link" data-act="goto" data-arg="routines" style="justify-content:flex-start;color:var(--mint);font-weight:600">Edit anchors</button>
      `, 'mint')}

      <div class="grid wide" style="margin-bottom:14px">
        <button class="card tint-coral tappable" data-act="goto" data-arg="mood" style="margin:0;text-align:center">
          <div style="font-size:22px">💗</div><div class="small" style="font-weight:600">How am I?</div></button>
        <button class="card tint-amber tappable" data-act="goto" data-arg="menu" style="margin:0;text-align:center">
          <div style="font-size:22px">📋</div><div class="small" style="font-weight:600">Dopamine menu</div></button>
      </div>

      <button class="card tint-amber tappable" data-act="goto" data-arg="wins">
        <div class="head">Wins</div>
        <div class="sub">No streaks here. This number only goes up.</div>
        <div class="row"><span class="big-num" style="color:var(--amber)">${S.wins.length}</span>
          <span class="grow muted small">logged</span>
          ${winsToday().length ? `<span class="chip amber filled">${winsToday().length} today</span>` : ''}</div>
      </button>`,
  };
};

function taskRow(t) {
  return `<div class="list-item">
    <button class="tick" data-act="completeTask" data-arg="${t.id}" style="color:var(--violet)">○</button>
    <button class="grow" data-act="goto" data-arg="task/${t.id}" style="text-align:left">
      <div>${esc(t.title)}</div>
      ${t.steps.length ? `<div class="tiny">${t.steps.filter(s => s.done).length}/${t.steps.length} steps</div>`
        : t.cost === 3 ? '<div class="tiny">There\'s a wall on this one</div>' : ''}
    </button>
    <span class="chev">›</span></div>`;
}

/* ---- Capture ---- */

VIEWS.capture = () => ({
  title: 'Brain dump',
  html: `
    <p class="sub">Whatever's in there. It doesn't have to make sense, and you don't have to sort it now. One thought per line.</p>
    <textarea class="field" id="capture-text" placeholder="…"></textarea>
    <div style="height:14px"></div>
    ${btn('Save and keep going', 'saveCaptureMore', { tint: 'sky', icon: '＋' })}
    ${btn('Save and close', 'saveCapture', { tint: 'sky', style: 'tonal', icon: '✓' })}`,
  mount() { const t = el('capture-text'); if (t) t.focus(); },
});

VIEWS.triage = () => {
  const item = untriaged()[0];
  if (!item) return { title: 'Sort it out', html: empty('Inbox clear', 'Nothing waiting. Genuinely a good place to be.', '📥') };
  return {
    title: 'Sort it out',
    html: `
      ${card(`<div style="font-size:19px">${esc(item.text)}</div><div class="tiny" style="margin-top:8px">${relDate(item.at)}</div>`, 'sky')}
      ${btn("It's a task — add it", 'triageTask', { arg: item.id, icon: '☑️' })}
      ${btn('Already done it', 'triageWin', { arg: item.id, tint: 'amber', style: 'tonal', icon: '🏆' })}
      ${btn('Keep it, no action', 'triageKeep', { arg: item.id, tint: 'mint', style: 'tonal', icon: '📦' })}
      ${btn('Bin it', 'triageBin', { arg: item.id, tint: 'coral', style: 'tonal', icon: '🗑' })}
      <div class="tiny" style="text-align:center;margin:6px 0 14px">${untriaged().length} left</div>
      ${note('Binning things is allowed and it isn\'t failure. A thought you had at 1am is not a commitment you signed.')}`,
  };
};

/* ---- Tasks ---- */

VIEWS.tasks = () => {
  const open = openTasks();
  const today = open.filter(t => t.today);
  const later = open.filter(t => !t.today);
  const done = S.tasks.filter(t => t.completedAt);
  return {
    title: 'Tasks',
    right: '<button data-act="goto" data-arg="newtask">＋</button>',
    html: `
      ${!open.length ? empty('Nothing here', 'Add something, or pull it through from your inbox.', '☑️') : ''}
      ${today.length ? card(`<div class="head">On today</div>${today.map(taskRow).join('')}`, 'violet') : ''}
      ${later.length ? card(`<div class="head">Later</div>${later.map(taskRow).join('')}`, 'sky') : ''}
      ${done.length ? card(`<div class="head">Done</div><div class="sub">${done.length} finished</div>
        ${done.slice(0, 10).map(t => `<div class="list-item"><span class="tick" style="color:var(--mint)">✓</span>
          <span class="grow done">${esc(t.title)}</span></div>`).join('')}`, 'mint') : ''}`,
  };
};

VIEWS.newtask = () => {
  if (V.cost === undefined) V.cost = 2;
  if (V.today === undefined) V.today = true;
  return {
    title: 'New task',
    html: `
      ${card(`<div class="head">What is it?</div>
        <input class="field" id="task-title" placeholder="The thing" autocomplete="off">`)}
      ${card(`<div class="head">How hard is it to start?</div>
        <div class="sub">Starting, not doing. These are different things and only one of them predicts avoidance.</div>
        ${[1, 2, 3].map(c => `<button class="opt" data-act="newTaskCost" data-arg="${c}" aria-pressed="${V.cost === c}">
          <span class="mark">${V.cost === c ? '◉' : '○'}</span><span>${esc(COSTS[c].label)}</span></button>`).join('')}`)}
      ${card(`<div class="row"><span class="grow">Put it on today</span>
        <label class="switch"><input type="checkbox" ${V.today ? 'checked' : ''} data-act="newTaskToday">
        <span class="track"></span><span class="knob"></span></label></div>`)}
      ${btn('Add it', 'createTask', { icon: '＋' })}`,
    mount() { const i = el('task-title'); if (i) i.focus(); },
  };
};

VIEWS.task = id => {
  const t = task(id);
  if (!t) return { title: 'Task', html: empty('Gone', 'This task no longer exists.', '❓') };
  const mult = timeMultiplier();
  const next = t.steps.find(s => !s.done);
  return {
    title: 'Task',
    html: `
      ${card(`<div style="font-size:19px;font-weight:650;margin-bottom:10px">${esc(t.title)}</div>
        <span class="chip">${COSTS[t.cost].short} to start</span>
        ${t.today ? '<span class="chip amber filled">Today</span>' : ''}`)}

      ${t.cost === 3 ? card(`<div class="head">You marked this a wall</div>
        <div class="sub">Then the obstacle probably isn't the work.</div>
        <p class="small muted">Tasks that are objectively small and still undoable usually have something emotional stacked in front of them. Productivity techniques bounce off that. The guided script does something different.</p>
        ${btn('Work through it', 'goto', { arg: 'tool/cant-start', tint: 'coral', style: 'tonal', icon: '→' })}`, 'coral') : ''}

      ${card(`<div class="head">Steps</div>
        ${t.steps.length ? '' : '<div class="sub">A task with no steps is a task you\'ll stare at.</div>'}
        ${t.steps.length ? t.steps.map(s => `
          <button class="list-item" data-act="toggleStep" data-arg="${t.id}:${s.id}">
            <span class="tick" style="color:${s.done ? 'var(--mint)' : 'var(--violet)'}">${s.done ? '✓' : '○'}</span>
            <span class="grow ${s.done ? 'done' : ''}">${esc(s.text)}</span></button>`).join('')
          : btn('Break it down', 'goto', { arg: 'breakdown/' + t.id, style: 'tonal', icon: '✨' })}
        ${next ? `<div style="margin-top:10px;padding-top:10px;border-top:1px solid var(--line)">
          <div class="tiny">Only this one matters right now</div>
          <div style="font-weight:650;color:var(--violet)">${esc(next.text)}</div></div>` : ''}
        ${t.steps.length ? `<div class="row" style="margin-top:12px">
          <input class="field" id="new-step" placeholder="Add a step" autocomplete="off">
          <button data-act="addStep" data-arg="${t.id}" style="font-size:26px;color:var(--violet)">＋</button></div>` : ''}`)}

      ${card(`<div class="head">Time</div>
        <div class="sub">Guess before you start. That's how the multiplier gets built.</div>
        <div class="grid">${[5, 15, 30, 60, 120].map(m =>
          `<button class="pick v-sky" data-act="predict" data-arg="${t.id}:${m}" aria-pressed="${t.predicted === m}">${fmtMin(m)}</button>`).join('')}</div>
        ${t.predicted && mult ? `<p class="small" style="color:var(--sky);margin:10px 0 0">Your history says this is more likely ${Math.round(t.predicted * mult)} minutes — you run about ${mult.toFixed(1)}× your estimates.</p>` : ''}`, 'sky')}

      ${btn('Start a focus block', 'goto', { arg: 'session/sprint', icon: '⏱' })}
      ${btn('Mark it done', 'goto', { arg: 'finish/' + t.id, tint: 'mint', style: 'tonal', icon: '✓' })}
      ${btn(t.today ? 'Take it off today' : 'Put it on today', 'toggleToday', { arg: t.id, tint: 'amber', style: 'tonal', icon: '🌤' })}
      <button class="btn link" data-act="deleteTask" data-arg="${t.id}" style="color:var(--coral)">Delete</button>`,
  };
};

VIEWS.finish = id => {
  const t = task(id);
  if (!t) return { title: 'Done', html: empty('Gone', 'This task no longer exists.') };
  return {
    title: 'Nice one',
    html: `
      <h2 style="margin:4px 0 10px">Done. How long did it actually take?</h2>
      ${t.predicted ? `<p class="sub">You guessed ${t.predicted} minutes.</p>` : ''}
      <p class="small muted">This is the only way the app learns your real multiplier. A rough answer is fine — precision isn't the point, the ratio is.</p>
      <div class="grid" style="margin-bottom:16px">${[5, 10, 15, 30, 45, 60, 90, 120, 180].map(m =>
        `<button class="pick v-mint" data-act="pickActual" data-arg="${m}" aria-pressed="${V.actual === m}">${fmtMin(m)}</button>`).join('')}</div>
      ${btn('Log it', 'finishTask', { arg: t.id, tint: 'mint', icon: '✓' })}
      <button class="btn link" data-act="skipActual" data-arg="${t.id}">Skip — just mark it done</button>`,
  };
};

VIEWS.breakdown = id => {
  const t = task(id);
  if (!t) return { title: 'Break it down', html: empty('Gone', 'This task no longer exists.') };
  if (!V.drafts) V.drafts = [''];
  const p = V.prompt || 0;
  return {
    title: 'Break it down',
    html: `
      ${card(`<div style="font-weight:650">${esc(t.title)}</div>`)}
      ${card(`<p class="small" style="margin:0 0 10px">${esc(CONTENT.breakdownQuestions[p])}</p>
        <button class="btn link" data-act="bdPrompt" style="color:var(--sky);justify-content:flex-start">🔁 Another prompt</button>`, 'sky')}
      ${card(`<div class="head">The steps</div>
        <div class="sub">Small enough that you'd be slightly embarrassed to call them steps.</div>
        ${V.drafts.map((d, i) => `<div class="row" style="margin-bottom:8px">
          <span class="tiny" style="width:14px">${i + 1}</span>
          <input class="field" data-draft value="${esc(d)}" placeholder="e.g. open the folder" autocomplete="off">
          ${V.drafts.length > 1 ? `<button data-act="bdRemove" data-arg="${i}" style="color:var(--text-3);font-size:20px">−</button>` : ''}
        </div>`).join('')}
        <button class="btn link" data-act="bdAdd" style="color:var(--violet);font-weight:600;justify-content:flex-start">＋ Another step</button>`)}
      ${card(`<div class="head">Or start from a shape</div>
        <div class="sub">Adjust it after — a rough starting point beats a blank box.</div>
        ${CONTENT.breakdownPatterns.map((pt, i) => `<button class="list-item" data-act="bdPattern" data-arg="${i}">
          <span class="grow">${esc(pt.label)}</span><span style="color:var(--amber)">↓</span></button>`).join('')}`, 'amber')}
      ${btn('Save steps', 'bdSave', { arg: t.id, icon: '✓' })}`,
  };
};

/* ---- Focus ---- */

VIEWS.focus = () => {
  const mult = timeMultiplier();
  const n = calibrationCount();
  return {
    title: 'Focus',
    html: `
      ${MODES.map(m => `<button class="card tint-${m.tint} tappable" data-act="goto" data-arg="session/${m.key}">
        <div class="row"><span style="font-size:22px">${m.icon}</span>
        <div class="grow"><div class="head" style="margin:0">${m.title}</div>
        <div class="tiny">${esc(m.blurb)}</div></div><span class="chev">›</span></div></button>`).join('')}

      ${card(`<div class="head">Your time multiplier</div>
        <div class="sub">How far your estimates sit from reality</div>
        ${mult ? `<div class="row"><span class="big-num" style="color:var(--sky)">${mult.toFixed(1)}×</span>
            <span class="tiny">from ${n} tasks</span></div>
          <p class="small muted" style="margin:8px 0 0">${esc(
            mult < 1.2 ? 'Your estimates are close to reality, which is genuinely unusual. Keep logging — a few more samples will confirm it.'
            : mult < 1.8 ? 'You run moderately over. Multiply your gut estimate by this before you commit to anything and you\'ll stop overpromising.'
            : 'You run well over — which is common and not a character flaw. Plan with this number instead of the number in your head, and days start fitting.')}</p>`
        : `<p class="small muted">Needs ${Math.max(0, 3 - n)} more timed task${3 - n === 1 ? '' : 's'} before it means anything.</p>
           <p class="small muted">Guess before you start, log what it actually took, and the ratio does the rest. Estimating better isn't the goal — knowing your error is.</p>`}`, 'sky')}

      ${card(`<div class="row"><div class="grow"><div class="tiny">Focused today</div>
        <div style="font-size:22px;font-weight:700">${focusMinutesToday()} min</div></div>
        <span style="font-size:26px;opacity:.4">⏱</span></div>`)}`,
  };
};

VIEWS.session = key => {
  const m = mode(key);
  if (!V.started) {
    const mins = V.minutes || m.def;
    return {
      title: m.title,
      html: `
        ${card(`<p class="small muted" style="margin:0">${esc(m.blurb)}</p>`, m.tint)}
        ${card(`<div class="head">What are you doing?</div>
          <div class="sub">Naming it out loud is doing real work — it's the same mechanism body doubling runs on.</div>
          <input class="field" id="focus-task" placeholder="The thing" autocomplete="off">`, m.tint)}
        ${card(`<div class="head">How long?</div>
          <div class="grid">${m.lengths.map(l =>
            `<button class="pick v-${m.tint}" data-act="pickLength" data-arg="${l}" aria-pressed="${mins === l}">${fmtMin(l)}</button>`).join('')}</div>
          ${m.key === 'sprint' ? '<p class="tiny" style="margin:10px 0 0">Shorter than feels right is usually the correct call. A block you finish is worth more than one you abandon at minute nine.</p>' : ''}`, m.tint)}
        ${m.key === 'hyperfocusGuard' ? card(`<div class="head">You'll be interrupted</div>
          <p class="small muted" style="margin:0">When the block ends this breaks in to ask about water, food, posture and eyes. That's the point of the mode — once you're in, you won't think to check any of it yourself.</p>
          <p class="tiny" style="margin:8px 0 0">Keep the screen on for this to fire. Web apps on iOS can't reliably wake you in the background — the native build uses real notifications.</p>`, 'amber') : ''}
        ${btn('Start', 'startFocus', { arg: m.key, tint: m.tint, icon: '▶' })}`,
    };
  }

  if (V.check) {
    return {
      title: 'Body check',
      html: `
        <h2>Body check</h2>
        <p class="sub">You've been at this a while. Quick pass, then straight back in.</p>
        ${['💧 Have some water', '🍽 When did you last eat?', '🧍 Stand up and stretch',
           '👁 Look at something 6 metres away for 20 seconds']
          .map(x => `<div class="list-item"><span class="grow">${x}</span></div>`).join('')}
        <div style="height:14px"></div>
        ${btn('Done — back to it', 'againFocus', { tint: 'amber', icon: '→' })}
        ${btn('Stop here', 'endFocus', { arg: 'full', tint: 'mint', style: 'tonal', icon: '✓' })}`,
    };
  }

  const finished = Timer.finished;
  return {
    title: m.title,
    html: `
      ${V.taskText ? `<h2 style="text-align:center;font-size:17px">${esc(V.taskText)}</h2>` : ''}
      ${ring(m.tint, finished ? 'Done' : (Timer.running ? '' : 'Paused'))}
      ${m.key === 'bodyDouble' && !finished ? card(
        `<p class="small" style="margin:0 0 6px">Still here, still working alongside you.</p>
         <p class="tiny" style="margin:0">A real person is better than this. If you have someone, put them on a silent call and work alongside them.</p>`, 'sky') : ''}
      ${finished ? `<h2 style="text-align:center">Block finished.</h2>
        ${btn('Log it and stop', 'endFocus', { arg: 'full', tint: 'mint', icon: '✓' })}
        ${btn('Another 15 minutes', 'againFocus', { tint: m.tint, style: 'tonal', icon: '↻' })}`
      : `${btn(Timer.running ? 'Pause' : 'Resume', 'pauseFocus', { tint: m.tint, style: 'tonal', icon: Timer.running ? '⏸' : '▶' })}
         ${btn('Stop', 'endFocus', { arg: 'partial', tint: 'coral', style: 'tonal', icon: '⏹' })}
         <button class="btn link" data-act="addFive" style="color:var(--violet)">+5 minutes</button>`}`,
    mount() { Timer._paint(); },
  };
};

/* ---- Routines ---- */

VIEWS.routine = id => {
  const r = routine(id);
  if (!r) return { title: 'Routine', html: empty('Gone', 'This anchor no longer exists.') };
  if (!r.steps.length) return { title: r.name, html: empty('Nothing in here yet', 'Add a couple of steps and this becomes usable.', '📝') };
  if (V.done) {
    return {
      title: r.name,
      html: `<div class="empty"><span class="ic">✅</span>
        <div class="t">${esc(r.name)} done</div>
        <div class="m">Logged as a win. Partial counts — skipping steps doesn't cancel it.</div></div>
        ${btn('Close', 'goto', { arg: 'today', tint: 'mint', icon: '✓' })}`,
    };
  }
  const i = V.step || 0;
  const s = r.steps[i];
  return {
    title: r.name,
    html: `
      <div class="row" style="margin-bottom:8px"><span class="tiny grow">Step ${i + 1} of ${r.steps.length}</span>
        <span class="tiny">~${s.minutes} min</span></div>
      ${bar(i / r.steps.length, 'mint')}
      <div style="height:14px"></div>
      ${card(`<div style="font-size:19px;padding:16px 0">${esc(s.text)}</div>`, 'mint')}
      ${btn('Done — next', 'routineNext', { arg: r.id, tint: 'mint', icon: '→' })}
      <button class="btn link" data-act="routineNext" data-arg="${r.id}">Skip this one</button>`,
  };
};

VIEWS.routines = () => ({
  title: 'Anchors',
  html: `
    ${note('Keep these short. A four-step routine survives a bad week; an eleven-step routine gets abandoned and then becomes another thing to feel bad about.')}
    ${S.routines.map(r => card(`
      <div class="row" style="margin-bottom:10px">
        <span>${icon(r.symbol)}</span><span class="grow" style="font-weight:650">${esc(r.name)}</span>
        <label class="switch"><input type="checkbox" ${r.enabled ? 'checked' : ''} data-act="routineToggle" data-arg="${r.id}">
        <span class="track"></span><span class="knob"></span></label></div>
      ${r.steps.map(s => `<div class="row" style="padding:3px 0">
        <span style="color:var(--mint)">•</span><span class="grow small">${esc(s.text)}</span>
        <button data-act="routineDelStep" data-arg="${r.id}:${s.id}" style="color:var(--text-3)">−</button></div>`).join('')}
      <div class="row" style="margin-top:10px">
        <input class="field" id="rstep-${r.id}" placeholder="Add a step" autocomplete="off">
        <button data-act="routineAddStep" data-arg="${r.id}" style="font-size:24px;color:var(--mint)">＋</button></div>
      <button class="btn link" data-act="routineDelete" data-arg="${r.id}" style="color:var(--coral);justify-content:flex-start">Delete anchor</button>
    `, 'mint')).join('')}
    ${card(`<div class="head">New anchor</div>
      <div class="row"><input class="field" id="new-routine" placeholder="Name" autocomplete="off">
      <button data-act="routineNew" style="font-size:24px;color:var(--violet)">＋</button></div>`)}`,
});

/* ---- Mood ---- */

VIEWS.mood = () => {
  const v = V.valence || 3, e = V.energy || 3, f = V.feelings || [];
  const scale = (labels, cur, act, cls) => `<div class="scale ${cls}">${labels.map((l, i) =>
    `<button data-act="${act}" data-arg="${i + 1}" aria-pressed="${cur === i + 1}">
      <span class="dot"></span><span class="lbl">${l}</span></button>`).join('')}</div>`;
  return {
    title: 'Check in',
    html: `
      ${card(`<div class="head">How's it going?</div><div class="sub">Rough on the left, good on the right.</div>
        ${scale(['Rough', 'Low', 'OK', 'Good', 'Great'], v, 'setValence', '')}`, 'coral')}
      ${card(`<div class="head">Energy</div><div class="sub">Flat and empty, or wired and can't settle. Both ends are hard.</div>
        ${scale(['Flat', 'Low', 'Steady', 'Busy', 'Wired'], e, 'setEnergy', 'energy')}`, 'amber')}
      ${card(`<div class="head">Any of these?</div>
        <div class="sub">Specific words help. "Bad" doesn't point anywhere; "resentful" does.</div>
        <div class="chips">${CONTENT.feelings.map(x =>
          `<button class="chip selectable ${f.includes(x) ? 'filled' : ''}" data-act="toggleFeeling" data-arg="${esc(x)}">${esc(x)}</button>`).join('')}</div>`)}
      ${card(`<div class="head">Anything else?</div><div class="sub">Optional.</div>
        <textarea class="field" id="mood-note" style="min-height:80px" placeholder="What's going on"></textarea>`, 'sky')}
      ${v <= 2 ? card(`<div class="head">That sounds like a hard one</div>
        <p class="small muted">Nothing here is a fix, and it isn't pretending to be. But if it's a spiral, catching it early is worth more than reasoning with it later.</p>
        ${btn('Work through the overwhelm', 'goto', { arg: 'tool/overwhelmed', tint: 'mint', style: 'tonal', icon: '🧰' })}
        ${btn('If it\'s worse than that — crisis support', 'goto', { arg: 'crisis', tint: 'coral', style: 'tonal', icon: '🛟' })}`, 'mint') : ''}
      ${btn('Log it', 'saveMood', { tint: 'coral', icon: '✓' })}`,
  };
};

VIEWS.menu = () => ({
  title: 'Dopamine menu',
  html: `
    ${card(`<p class="small muted" style="margin:0">Understimulation isn't mild boredom for an ADHD brain — it's urgent, and if you don't answer it deliberately it gets answered by whatever's nearest. Which is usually a phone designed by people who are very good at their jobs.</p>`, 'amber')}
    ${card(`<div class="head">Take one</div>
      ${S.dopamineMenu.map((x, i) => `<div class="row" style="padding:4px 0">
        <span style="color:var(--amber)">•</span><span class="grow small">${esc(x)}</span>
        <button data-act="menuDel" data-arg="${i}" style="color:var(--text-3)">−</button></div>`).join('')}
      <div class="row" style="margin-top:10px">
        <input class="field" id="menu-new" placeholder="Add your own" autocomplete="off">
        <button data-act="menuAdd" style="font-size:24px;color:var(--amber)">＋</button></div>`, 'amber')}
    ${note('Games and scrolling aren\'t banned — they\'re the dessert course. The problem was never that you wanted them, it\'s that they were the only thing on the menu.')}`,
});

VIEWS.wins = () => {
  const groups = [];
  S.wins.forEach(w => {
    const key = relDate(w.at);
    const g = groups.find(x => x[0] === key);
    g ? g[1].push(w) : groups.push([key, [w]]);
  });
  return {
    title: 'Wins',
    html: `
      ${card(`<div class="row"><span class="big-num" style="color:var(--amber)">${S.wins.length}</span>
        <span class="grow" style="font-weight:650;color:var(--text-2)">things you did</span></div>
        <p class="small muted" style="margin:8px 0 0">There's no streak to break. Miss a week and this number doesn't move — it certainly doesn't reset.</p>`, 'amber')}
      ${card(`<div class="head">Add one</div><div class="sub">Counts if it was hard for you. That's the only bar.</div>
        <div class="row"><input class="field" id="win-text" placeholder="What you did" autocomplete="off">
        <button data-act="addWin" style="font-size:24px;color:var(--amber)">＋</button></div>`, 'amber')}
      ${!S.wins.length ? empty('Nothing logged yet', 'Made a call you\'d been avoiding? Got out of bed on a bad day? That\'s the level.', '🏆')
        : groups.map(([day, ws]) => card(`<div class="tiny" style="font-weight:700;margin-bottom:6px">${esc(day)}</div>
          ${ws.map(w => `<div class="list-item"><span class="tick" style="color:var(--amber);font-size:14px">✓</span>
            <span class="grow small">${esc(w.text)}</span></div>`).join('')}`, 'amber')).join('')}`,
  };
};

/* ---- Toolbox ---- */

VIEWS.toolbox = () => ({
  title: 'Toolbox',
  html: `
    ${card(`<div class="head">What's happening right now?</div>
      <p class="small muted" style="margin:0">Pick the one that matches. Each is a short script — one thing at a time, no reading required.</p>`)}
    ${CONTENT.interventions.map(t => `<button class="card tint-${tint(t.tint)} tappable" data-act="goto" data-arg="tool/${t.id}">
      <div class="row"><span style="font-size:21px">${icon(t.symbol)}</span>
      <div class="grow"><div class="head" style="margin:0">${esc(t.trigger)}</div>
      <div class="tiny">${esc(t.subtitle)}</div></div><span class="chev">›</span></div></button>`).join('')}
    <button class="card tint-coral tappable" data-act="goto" data-arg="crisis">
      <div class="row"><span>📞</span><span class="grow" style="font-weight:650">If things are worse than this</span>
      <span class="chev">›</span></div></button>`,
});

VIEWS.tool = id => {
  const t = CONTENT.interventions.find(x => x.id === id);
  if (!t) return { title: 'Toolbox', html: empty('Not found', 'That script no longer exists.') };

  if (V.done) {
    const written = (V.responses || []).filter(Boolean);
    return {
      title: t.trigger,
      html: `
        <div class="empty"><span class="ic">✅</span><div class="t">You worked through it</div>
          <div class="m">That's the win, whether or not the thing itself got done. Following a script while depleted is harder than it sounds.</div></div>
        ${t.closingNote ? note(t.closingNote) : ''}
        ${written.length ? card(`<div class="head">What you wrote</div>
          ${written.map(r => `<p class="small muted" style="margin:0 0 6px">• ${esc(r)}</p>`).join('')}`, t.tint) : ''}
        ${written.length ? btn('Save to my notes', 'toolSave', { tint: t.tint, style: 'tonal', icon: '📥' }) : ''}
        ${t.id === 'spiralling' ? btn('Log this as a rejection episode', 'toolLogRsd', { tint: 'coral', style: 'tonal', icon: '💔' }) : ''}
        ${btn('Close', 'goto', { arg: 'toolbox', tint: t.tint, style: 'tonal', icon: '✕' })}`,
    };
  }

  const i = V.step || 0;
  const s = t.steps[i];
  return {
    title: t.trigger,
    html: `
      <div class="tiny" style="margin-bottom:6px">${i + 1} of ${t.steps.length}</div>
      ${bar(i / t.steps.length, t.tint)}
      <div style="height:14px"></div>
      ${card(`<div style="font-size:19px;font-weight:650;margin-bottom:10px">${esc(s.title)}</div>
        <div class="muted">${para(s.detail)}</div>`, t.tint)}
      ${s.prompt ? card(`<div class="tiny" style="font-weight:600;margin-bottom:8px">${esc(s.prompt)}</div>
        <textarea class="field" id="tool-input" style="min-height:90px"></textarea>`, t.tint) : ''}
      ${s.seconds ? (V.timing
        ? ring(t.tint, Timer.finished ? 'Done' : '')
        : btn(s.seconds >= 60 ? `Start ${Math.round(s.seconds / 60)} min` : `Start ${s.seconds} sec`,
            'toolTimer', { arg: s.seconds, tint: t.tint, style: 'tonal', icon: '⏱' })) : ''}
      ${btn(i + 1 < t.steps.length ? 'Next' : 'Finish', 'toolNext',
        { arg: t.id, tint: t.tint, icon: i + 1 < t.steps.length ? '→' : '✓' })}`,
    mount() { if (V.timing) Timer._paint(); },
  };
};

/* ---- Learn ---- */

VIEWS.learn = () => ({
  title: 'Learn',
  html: CONTENT.categories.map(c => {
    const arts = CONTENT.articles.filter(a => a.category === c.key);
    if (!arts.length) return '';
    return card(`<div class="head" style="margin-bottom:8px">${esc(c.label)}</div>
      ${arts.map(a => `<button class="list-item" data-act="goto" data-arg="article/${a.id}">
        <span class="tick">${icon(a.symbol)}</span>
        <div class="grow"><div style="font-weight:600">${esc(a.title)}</div>
          <div class="tiny">${esc(a.subtitle)}</div></div>
        <span class="tiny">${a.readMinutes}m</span></button>`).join('')}`);
  }).join(''),
});

VIEWS.article = id => {
  const a = CONTENT.articles.find(x => x.id === id);
  if (!a) return { title: 'Learn', html: empty('Not found', 'That article no longer exists.') };
  const body = a.body.map(b => {
    if (b.t === 'heading') return `<h2>${esc(b.v)}</h2>`;
    if (b.t === 'paragraph') return para(b.v);
    if (b.t === 'bullets') return `<ul>${b.v.map(x => `<li>${esc(x)}</li>`).join('')}</ul>`;
    if (b.t === 'callout') return `<div class="callout"><span>✨</span><span>${esc(b.v)}</span></div>`;
    return `<div class="quote"><p>${esc(b.v)}</p><div class="by">— ${esc(b.by)}</div></div>`;
  }).join('');
  return {
    title: '',
    html: `<article class="article">
      <div style="font-size:30px">${icon(a.symbol)}</div>
      <h1>${esc(a.title)}</h1>
      <div class="lede">${esc(a.subtitle)}</div>
      ${body}
      <div style="height:10px"></div>
      ${note('General information, not medical advice, and not specific to you. Anything here that sounds like your life is worth taking to a clinician rather than acting on alone.')}
      <button class="btn link" data-act="toggleSources" style="color:var(--violet);font-weight:600;justify-content:flex-start">
        ${V.sources ? '▾' : '▸'} Where this comes from</button>
      ${V.sources ? `<div class="tiny">${a.sources.map(s => `<div style="margin-bottom:6px">· ${esc(s)}</div>`).join('')}</div>` : ''}
    </article>`,
  };
};

/* ---- Path ---- */

VIEWS.path = () => {
  const run = latestScreener();
  return {
    title: 'Path',
    html: `
      ${card(`<div class="head">Towards an answer</div>
        <p class="small muted" style="margin:0">Most adults who get diagnosed start exactly here — recognising themselves in something. The gap between that and an assessment is mostly organised information, which is what this section builds.</p>`)}

      <button class="card tint-sky tappable" data-act="goto" data-arg="screener">
        <div class="row"><span style="font-size:21px">📝</span>
          <div class="grow"><div class="head" style="margin:0">Screening questionnaire</div>
          <div class="tiny">ASRS v1.1 — the WHO's adult self-report scale</div></div><span class="chev">›</span></div>
        ${run ? `<div style="margin-top:10px;padding-top:10px;border-top:1px solid var(--line)">
          <span class="chip ${partAFlags(run.answers) >= 4 ? 'amber' : 'mint'} filled">${partAFlags(run.answers)}/6 flagged</span>
          <span class="tiny">${relDate(run.at)}</span></div>` : ''}
      </button>

      <button class="card tint-amber tappable" data-act="goto" data-arg="evidence">
        <div class="row"><span style="font-size:21px">🔍</span>
        <div class="grow"><div class="head" style="margin:0">Evidence log</div>
        <div class="tiny">${S.evidence.length ? `${S.evidence.length} example${S.evidence.length === 1 ? '' : 's'} logged`
          : 'Concrete examples beat adjectives in an assessment'}</div></div><span class="chev">›</span></div></button>

      <button class="card tint-mint tappable" data-act="goto" data-arg="summary">
        <div class="row"><span style="font-size:21px">📤</span>
        <div class="grow"><div class="head" style="margin:0">Summary to take in</div>
        <div class="tiny">Everything organised the way a clinician will ask for it</div></div><span class="chev">›</span></div></button>

      <button class="card tint-coral tappable" data-act="goto" data-arg="crisis">
        <div class="row"><span style="font-size:21px">🛟</span>
        <span class="grow" style="font-weight:650">Crisis support</span><span class="chev">›</span></div></button>

      <button class="card tint-violet tappable" data-act="goto" data-arg="settings">
        <div class="row"><span style="font-size:21px">⚙️</span>
        <span class="grow" style="font-weight:650">Settings & privacy</span><span class="chev">›</span></div></button>`,
  };
};

VIEWS.screener = () => ({
  title: 'Screener',
  html: `
    ${card(`<div class="head">Before you start</div>
      <p class="small muted" style="margin:0">This is the Adult ADHD Self-Report Scale (ASRS v1.1), developed by the World Health Organization with the Workgroup on Adult ADHD. It's used in clinical practice and research, and the items map onto the diagnostic criteria.</p>`, 'sky')}
    ${card(`<div class="head">What it can't tell you</div>
      <div class="muted small">${para("It cannot diagnose you. A screener sorts people into \"worth assessing\" and \"less likely\" — nothing finer than that.\n\nA diagnosis additionally needs evidence the pattern predates age 12, impairment in more than one setting, and the other conditions that look identical ruled out. That last part is genuinely difficult and it needs a clinician.")}</div>`, 'coral')}
    ${card(`<div class="head">Answering it usefully</div>
      <div class="muted small">${para("Answer for the last 6 months, and answer for how things actually are — not how they are once your workarounds are running.\n\nIf you only remember appointments because you set four alarms, the honest answer to \"do you have problems remembering appointments\" is yes. The alarms are the evidence, not the counter-evidence.")}</div>`)}
    ${btn('Start — 18 questions', 'goto', { arg: 'questions', tint: 'sky', icon: '→' })}
    <p class="tiny">ASRS-v1.1 © 2003 World Health Organization. Reproduced unmodified for personal screening use.</p>`,
});

VIEWS.questions = () => {
  if (!V.answers) { V.answers = new Array(18).fill(-1); V.q = 0; }
  const items = CONTENT.asrs.partA.concat(CONTENT.asrs.partB);
  const i = V.q;
  return {
    title: 'Questions',
    html: `
      <div class="row" style="margin-bottom:8px"><span class="tiny grow">${i + 1} of 18</span>
        <span class="chip ${i < 6 ? 'sky' : ''}">${i < 6 ? 'Screening section' : 'Additional'}</span></div>
      ${bar(i / 18, 'sky')}
      <div style="height:14px"></div>
      ${card(`<div style="font-size:19px;padding:8px 0">${esc(items[i].text)}</div>`, 'sky')}
      ${CONTENT.asrs.responseLabels.map((l, v) => `<button class="opt" data-act="answer" data-arg="${v}" aria-pressed="${V.answers[i] === v}">
        <span class="mark">${V.answers[i] === v ? '◉' : '○'}</span><span>${esc(l)}</span></button>`).join('')}
      ${i > 0 ? '<button class="btn link" data-act="prevQ">← Back</button>' : ''}`,
  };
};

VIEWS.result = () => {
  const run = latestScreener();
  if (!run) return { title: 'Result', html: empty('Nothing yet', 'Take the questionnaire first.') };
  const flags = partAFlags(run.answers);
  const over = flags >= CONTENT.asrs.threshold;
  const ina = subscale(run.answers, CONTENT.asrs.inattentiveIndices);
  const hyp = subscale(run.answers, CONTENT.asrs.hyperactiveIndices);

  const headline = over ? 'Worth taking to a clinician' : 'Below the screening threshold';
  const body = over
    ? `You flagged ${flags} of 6 on the screening section. The published threshold is 4. That means your answers fall in the range the screener was built to detect — the range where a proper assessment is considered warranted.\n\nThis is not a diagnosis, and it isn't close to one. What it is: a reason to book the appointment, and something concrete to hand over when you do.`
    : `You flagged ${flags} of 6 on the screening section, and the threshold is 4.\n\nRead that carefully, because it doesn't mean nothing is going on. Screeners miss people — particularly adults who've spent decades building workarounds, whose presentation is mainly inattentive, or who were never flagged as children because they were quiet rather than disruptive. If your life is genuinely harder than it looks like it should be, that's still worth raising with a clinician. A below-threshold score is not a verdict on your experience.`;

  const sub = (label, score, t) => `<div style="margin-bottom:10px">
    <div class="row"><span class="grow small">${label}</span><span class="small" style="font-weight:650;color:var(--${t})">${score}/36</span></div>
    ${bar(score / 36, t)}</div>`;

  return {
    title: 'Result',
    html: `
      ${card(`<div class="row"><span class="big-num" style="color:var(--${over ? 'amber' : 'mint'})">${flags}</span>
        <span class="grow" style="font-weight:650;color:var(--text-2)">of 6 flagged</span></div>
        <div class="head" style="margin-top:10px">${headline}</div>
        <div class="muted small">${para(body)}</div>`, over ? 'amber' : 'mint')}

      ${card(`<div class="head">Your profile</div>
        <div class="sub">Descriptive only — there's no published cut-off for these two.</div>
        ${sub('Inattentive', ina, 'sky')}
        ${sub('Hyperactive / impulsive', hyp, 'coral')}
        <p class="tiny" style="margin:0">Adults are frequently much higher on one than the other. A low hyperactivity score is not evidence against anything — the predominantly inattentive presentation is the one that gets missed for decades precisely because it never disrupted anybody.</p>`)}

      ${card(`<div class="head">Read this part</div>
        <div class="muted small">${para("This is not a diagnosis and it is not close to one. Sleep disorders, thyroid problems, iron deficiency, depression, anxiety, trauma and autism all produce overlapping pictures, and several of them commonly co-occur with ADHD rather than replacing it.\n\nSorting that out is what an assessment is for.")}</div>
        ${btn('What else looks like this →', 'goto', { arg: 'article/not-adhd', tint: 'coral', style: 'tonal' })}`, 'coral')}

      ${btn('Next: log some real examples', 'goto', { arg: 'evidence', icon: '📄' })}
      <p class="tiny">ASRS-v1.1 © 2003 World Health Organization.</p>`,
  };
};

VIEWS.evidence = () => {
  const groups = DOMAINS.map(d => [d, S.evidence.filter(e => e.domain === d.key)]).filter(g => g[1].length);
  const promptGroup = (title, list) => `<div style="margin-bottom:14px">
    <div class="tiny" style="font-weight:700;color:var(--violet);margin-bottom:8px">${title}</div>
    ${list.map(p => `<div style="margin-bottom:10px"><div class="small">${esc(p.q)}</div>
      <div class="tiny">${esc(p.why)}</div></div>`).join('')}</div>`;
  return {
    title: 'Evidence',
    right: '<button data-act="goto" data-arg="newevidence">＋</button>',
    html: `
      ${card(`<div class="head">Why bother with this</div>
        <div class="muted small">${para("You will forget the specifics. Not might — will. Then you'll sit in a 45-minute appointment trying to summarise 30 years from memory, with a clinician who needs examples, and you'll produce adjectives instead.\n\nWrite them down as they happen. Two lines is plenty.")}</div>`, 'amber')}
      ${btn('Add an example', 'goto', { arg: 'newevidence', tint: 'amber', icon: '＋' })}
      ${!S.evidence.length ? empty('Nothing logged yet', 'Next time something happens that\'s part of the pattern, put it here.', '📄')
        : groups.map(([d, notes]) => card(`<div class="head">${d.icon} ${esc(d.label)}</div>
          ${notes.map(n => `<div style="padding:6px 0">
            <div class="row">${n.childhood ? '<span class="chip">Childhood</span>' : ''}
              <span class="tiny grow">${relDate(n.at)}</span>
              <button data-act="evDelete" data-arg="${n.id}" style="color:var(--text-3)">−</button></div>
            <div class="small">${esc(n.text)}</div></div>`).join('')}`, 'amber')).join('')}
      ${card(`<div class="head">Things they'll ask about</div>
        <div class="sub">Worth thinking through before you're in the room</div>
        ${promptGroup('Childhood', CONTENT.asrs.context.childhood)}
        ${promptGroup('Impact', CONTENT.asrs.context.impairment)}
        ${promptGroup('The differential', CONTENT.asrs.context.differential)}`)}`,
  };
};

VIEWS.newevidence = () => {
  const d = V.domain || 'work';
  return {
    title: 'New example',
    html: `
      ${card(`<div class="head">What happened?</div>
        <div class="sub">Specific and concrete. Numbers and names if you have them.</div>
        <textarea class="field" id="ev-text" style="min-height:100px" placeholder="e.g. Missed the dentist twice this month despite two reminders"></textarea>`)}
      ${card(`<div class="head">Which part of life?</div>
        <div class="grid wide">${DOMAINS.map(x =>
          `<button class="pick v-amber" data-act="evDomain" data-arg="${x.key}" aria-pressed="${d === x.key}"
            style="text-align:left">${x.icon} ${esc(x.label)}</button>`).join('')}</div>`, 'amber')}
      ${card(`<div class="row"><span class="grow small">This is from before I was 12</span>
        <label class="switch"><input type="checkbox" ${V.childhood ? 'checked' : ''} data-act="evChildhood">
        <span class="track"></span><span class="knob"></span></label></div>
        <p class="tiny" style="margin:8px 0 0">Childhood examples carry disproportionate weight — the criteria require the pattern to predate age 12, and that's often the hardest part to evidence.</p>`)}
      ${btn('Save', 'evSave', { tint: 'amber', icon: '✓' })}`,
    mount() { const t = el('ev-text'); if (t) t.focus(); },
  };
};

VIEWS.summary = () => ({
  title: 'Summary',
  html: `
    ${card(`<div class="head">For your appointment</div>
      <p class="small muted" style="margin:0">Everything you've logged, arranged the way an assessment moves. Share it, mail it to yourself, or read it off your phone.</p>`, 'mint')}
    ${card(`<div class="head">One thing before you go in</div>
      <div class="muted small">${para("Don't present the polished version. You have decades of practice at appearing fine and it runs without you deciding to — which is the most common reason capable adults get turned away.\n\nThey need the cost, not the coping. Describe what it takes to hold it together, not how well it's held.")}</div>`, 'coral')}
    ${card(`<pre class="summary">${esc(buildSummary())}</pre>`)}
    ${btn('Share or copy', 'share', { tint: 'mint', icon: '📤' })}
    ${note('Self-reported information, generated on this device. It is not a diagnosis, not a clinical record, and carries no medical authority — it\'s your notes, tidied up.')}`,
});

function buildSummary() {
  const out = [];
  const d = ts => new Date(ts).toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' });
  const items = CONTENT.asrs.partA.concat(CONTENT.asrs.partB);

  out.push('SELF-REPORTED SUMMARY FOR CLINICAL DISCUSSION');
  out.push(`Prepared ${d(Date.now())} using Scaffold`);
  out.push('Self-reported by the patient. Not a diagnosis or clinical assessment.', '');

  out.push('— SCREENING (ASRS v1.1, WHO) —');
  const run = latestScreener();
  if (run) {
    out.push(`Completed: ${d(run.at)}`);
    out.push(`Part A (screener): ${partAFlags(run.answers)} of 6 items at or above threshold (published cut-off: 4).`);
    out.push(`Inattentive item total: ${subscale(run.answers, CONTENT.asrs.inattentiveIndices)}/36`);
    out.push(`Hyperactive/impulsive item total: ${subscale(run.answers, CONTENT.asrs.hyperactiveIndices)}/36`, '');
    out.push('Item-level responses (0=Never, 4=Very Often):');
    items.forEach((it, i) => {
      const a = run.answers[i];
      if (a < 0) return;
      const flag = i < 6 && a >= it.threshold ? ' *' : '';
      out.push(`  ${i + 1}. [${a}]${flag} ${it.text}`);
    });
  } else out.push('Not completed.');
  out.push('');

  out.push('— FUNCTIONAL IMPACT (self-reported examples) —');
  const adult = S.evidence.filter(e => !e.childhood);
  if (!adult.length) out.push('None logged.');
  else DOMAINS.forEach(dom => {
    const ns = adult.filter(e => e.domain === dom.key);
    if (!ns.length) return;
    out.push(dom.label.toUpperCase() + ':');
    ns.forEach(n => out.push(`  · [${d(n.at)}] ${n.text}`));
  });
  out.push('');

  out.push('— REPORTED BEFORE AGE 12 —');
  const kid = S.evidence.filter(e => e.childhood);
  if (!kid.length) out.push('None logged.');
  else kid.forEach(n => out.push(`  · [${domainLabel(n.domain)}] ${n.text}`));
  out.push('');

  out.push('— MOOD & EMOTIONAL REGULATION —');
  if (!S.moods.length) out.push('No entries logged.');
  else {
    const avg = S.moods.reduce((a, m) => a + m.valence, 0) / S.moods.length;
    out.push(`Entries logged: ${S.moods.length} since ${d(S.moods[S.moods.length - 1].at)}`);
    out.push(`Mean self-rated mood: ${avg.toFixed(1)}/5`);
    out.push(`Entries flagged by the patient as rejection-sensitivity episodes: ${S.moods.filter(m => m.rsd).length}`);
    const counts = {};
    S.moods.forEach(m => (m.feelings || []).forEach(f => { counts[f] = (counts[f] || 0) + 1; }));
    const top = Object.entries(counts).sort((a, b) => b[1] - a[1]).slice(0, 5);
    if (top.length) out.push(`Most frequently selected states: ${top.map(([k, v]) => `${k} (${v})`).join(', ')}`);
  }
  out.push('');

  out.push('— TIME ESTIMATION —');
  const mult = timeMultiplier();
  out.push(mult
    ? `Across ${calibrationCount()} timed tasks, actual duration averaged ${mult.toFixed(1)}× the patient's own prior estimate.`
    : 'Insufficient data logged.');
  out.push('');

  out.push('— SELF-MANAGEMENT ATTEMPTS —');
  out.push(`Focus sessions logged: ${S.sessions.length}`);
  out.push(`Tasks broken into sub-steps: ${S.tasks.filter(t => t.steps.length).length}`);
  out.push(`Tasks marked as high activation cost ("a wall"): ${S.tasks.filter(t => t.cost === 3).length}`, '');

  out.push('— NOTES —');
  out.push("Generated locally on the patient's device from their own entries.");
  out.push('The ASRS v1.1 is a screening instrument (© 2003 WHO) and is not diagnostic.');
  return out.join('\n');
}

VIEWS.crisis = () => {
  const regions = [];
  CONTENT.crisis.forEach(r => {
    const g = regions.find(x => x[0] === r.region);
    g ? g[1].push(r) : regions.push([r.region, [r]]);
  });
  const href = c => (c.contact.includes('.') && !c.contact.includes(' '))
    ? 'https://' + c.contact
    : 'tel:' + c.contact.replace(/[^\d+]/g, '');
  return {
    title: 'Crisis support',
    html: `
      ${card(`<div class="head">You don't have to be in crisis to call</div>
        <p class="small muted" style="margin:0">${esc(CONTENT.crisisMessage)}</p>`, 'coral')}
      ${regions.map(([region, list]) => card(`
        <div class="tiny" style="font-weight:700;margin-bottom:8px">${esc(region)}</div>
        ${list.map(c => `<a class="list-item" href="${esc(href(c))}" style="color:inherit;text-decoration:none">
          <div class="grow"><div style="font-weight:650">${esc(c.name)}</div>
          <div class="tiny">${esc(c.detail)}</div></div>
          <span style="font-weight:700;color:var(--coral)">${esc(c.contact)}</span></a>`).join('')}`, 'coral')).join('')}
      ${note('Numbers change. If one doesn\'t connect, findahelpline.com lists verified services worldwide, or use your local emergency number.')}`,
  };
};

VIEWS.settings = () => ({
  title: 'Settings',
  html: `
    ${card(`<div class="head">Where your data lives</div>
      <div class="muted small">${para("In this browser's storage on this device. No account, no server, no analytics — nothing is uploaded, because there's nowhere for it to go.\n\nThe only way anything leaves is if you tap Share on your clinician summary, and that's you sending it, not the app.")}</div>
      <p class="tiny" style="margin:8px 0 0">Practical consequence: clearing your browser data, or deleting the app from your Home Screen along with its website data, erases everything. There's no backup to restore from.</p>`, 'mint')}

    ${card(`<div class="head">What's in here</div>
      ${[['Tasks', S.tasks.length], ['Captured thoughts', S.captures.length], ['Mood entries', S.moods.length],
         ['Focus sessions', S.sessions.length], ['Evidence examples', S.evidence.length], ['Wins', S.wins.length]]
        .map(([k, v]) => `<div class="stat"><span class="muted">${k}</span><span style="font-weight:650">${v}</span></div>`).join('')}`, 'sky')}

    ${card(`<div class="head">What this app isn't</div>
      <div class="muted small">${para("Scaffold does not diagnose, treat, or provide medical advice. It includes a screening questionnaire and general information drawn from published research, and neither of those is a substitute for a clinician who can assess you properly.\n\nIf you're struggling with your mental health, please talk to a professional. If you're in crisis, use the numbers under Crisis support.")}</div>`, 'coral')}

    ${card(`<div class="head">Erase everything</div>
      <p class="small muted">Deletes every task, note, mood entry, screener result and piece of evidence. Immediate and irreversible.</p>
      ${btn('Erase all my data', 'erase', { tint: 'coral', style: 'tonal', icon: '🗑' })}`, 'coral')}

    <p class="tiny" style="text-align:center">Scaffold · web build. Built on published ADHD research — sources are listed at the bottom of every article in Learn.</p>`,
});

/* ---------------------------------------------------------------- onboarding */

const OB = [
  { icon: '🧱', title: 'Scaffold', lines: [
    "Built for adults who suspect they have ADHD and haven't been assessed — or who were assessed a long time ago and never got much beyond the label.",
    'The idea is simple. If your brain struggles to hold structure internally, put the structure outside it: visible, immediate, and present at the moment you need it.',
    'Nothing in here asks you to try harder.'] },
  { icon: '🔒', title: 'It stays on this device', lines: [
    'No account. No sign-in. No servers. Nothing you write here is uploaded anywhere, because there is nowhere for it to go.',
    'That matters more than usual here — this app holds notes about your mental health that you may not have told anyone. The safest place for those is one device.',
    "You can export a summary to take to a clinician when you want to. That's a deliberate action you take, never something that happens on its own."] },
  { icon: '🩺', title: "What this can't do", lines: [
    'Scaffold cannot diagnose you. No app can, and any that implies otherwise is worth deleting.',
    "It includes a validated screening questionnaire, and a screener tells you whether it's worth seeing someone — not what you have. Diagnosis needs a clinician who can rule out the other things that look identical from the inside.",
    'What this app is genuinely for: making daily life work better, and helping you arrive at that appointment with something more useful than "I think I might have ADHD".'],
    footnote: "If you're in crisis, please use the resources under Path → Crisis support." },
];

function renderOnboarding() {
  const i = V.page || 0;
  const p = OB[i];
  document.body.innerHTML = `<main class="wrap" style="padding-top:56px;max-width:560px">
    <div style="font-size:42px">${p.icon}</div>
    <h1 style="font-size:32px;margin:12px 0 18px">${esc(p.title)}</h1>
    ${p.lines.map(l => `<p class="muted" style="margin-bottom:14px">${esc(l)}</p>`).join('')}
    ${p.footnote ? note(p.footnote) : ''}
    <div style="height:20px"></div>
    ${i < OB.length - 1
      ? btn('Next', 'obNext', { icon: '→' }) + '<button class="btn link" data-act="obDone">Skip</button>'
      : btn('Start', 'obDone', { icon: '✓' })}
    <div class="tiny" style="text-align:center;margin-top:10px">${i + 1} of ${OB.length}</div>
  </main>`;
  window.scrollTo(0, 0);
}

/* ---------------------------------------------------------------- boot */

load();
render();

if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('./sw.js').catch(e => console.warn('SW failed', e));
  });
}
