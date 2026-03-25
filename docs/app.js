/**
 * AI News Aggregator - Frontend Application (GitHub Pages version)
 * Inshorts-style card-based news reader with swipe navigation.
 */

const state = {
    articles: [], filteredArticles: [], currentIndex: 0, isLoading: false,
    touchStartX: 0, touchStartY: 0, touchCurrentX: 0,
    isDragging: false, dragThreshold: 80, hintShown: false,
};

const elements = {
    loading: document.getElementById("loading"),
    error: document.getElementById("error"),
    empty: document.getElementById("empty"),
    cardContainer: document.getElementById("card-container"),
    refreshBtn: document.getElementById("refresh-btn"),
    retryBtn: document.getElementById("retry-btn"),
    emptyRefreshBtn: document.getElementById("empty-refresh-btn"),
    prevBtn: document.getElementById("prev-btn"),
    nextBtn: document.getElementById("next-btn"),
    currentIndex: document.getElementById("current-index"),
    totalCount: document.getElementById("total-count"),
    sourceFilter: document.getElementById("source-filter"),
    swipeHint: document.getElementById("swipe-hint"),
};

const SOURCE_COLORS = {
    "techcrunch": "#0a9e01", "mit technology review": "#d32f2f",
    "the verge": "#7b2eff", "arxiv ai": "#b71c1c", "google news": "#4285f4",
    "ars technica": "#ff6600", "venturebeat": "#2196f3",
};
const SOURCE_GRADIENTS = {
    "techcrunch": "linear-gradient(135deg, #0a9e01, #00c853)",
    "mit technology review": "linear-gradient(135deg, #d32f2f, #ff5252)",
    "the verge": "linear-gradient(135deg, #7b2eff, #b388ff)",
    "arxiv ai": "linear-gradient(135deg, #b71c1c, #e57373)",
    "google news": "linear-gradient(135deg, #4285f4, #82b1ff)",
    "ars technica": "linear-gradient(135deg, #ff6600, #ffa040)",
    "venturebeat": "linear-gradient(135deg, #2196f3, #64b5f6)",
};
function getSourceColor(s) { return SOURCE_COLORS[s.toLowerCase()] || "#6c5ce7"; }
function getSourceGradient(s) { return SOURCE_GRADIENTS[s.toLowerCase()] || "linear-gradient(135deg, #6c5ce7, #a29bfe)"; }

const DEMO_ARTICLES = [
    { title: "OpenAI Announces GPT-5 with Breakthrough Reasoning Capabilities", summary: "OpenAI has unveiled GPT-5, featuring significant improvements in multi-step reasoning, mathematical problem solving, and code generation. The model demonstrates near-human performance on several professional benchmarks.", source: "TechCrunch", url: "https://techcrunch.com/", image_url: "", published: new Date(Date.now() - 2*3600000).toISOString() },
    { title: "Google DeepMind's AlphaFold 3 Predicts All Molecular Interactions of Life", summary: "DeepMind has released AlphaFold 3, extending protein structure prediction to all biomolecular interactions including DNA, RNA, and small molecules, potentially accelerating drug discovery by years.", source: "MIT Technology Review", url: "https://www.technologyreview.com/", image_url: "", published: new Date(Date.now() - 5*3600000).toISOString() },
    { title: "EU AI Act Enforcement Begins with Focus on High-Risk Systems", summary: "The European Union has started enforcing its landmark AI Act, requiring companies deploying high-risk AI systems to undergo conformity assessments and bias auditing mandates.", source: "The Verge", url: "https://www.theverge.com/", image_url: "", published: new Date(Date.now() - 8*3600000).toISOString() },
    { title: "Meta Releases Llama 4 as Open-Source, Rivaling Proprietary Models", summary: "Meta has open-sourced Llama 4, its most capable language model yet, offering performance that rivals leading proprietary models with variants for coding and multilingual tasks.", source: "VentureBeat", url: "https://venturebeat.com/", image_url: "", published: new Date(Date.now() - 12*3600000).toISOString() },
    { title: "Autonomous AI Agents Now Managing Enterprise Workflows End-to-End", summary: "A wave of startups and major tech companies are deploying autonomous AI agents that handle complex enterprise workflows including customer support, data analysis, and software testing.", source: "Ars Technica", url: "https://arstechnica.com/", image_url: "", published: new Date(Date.now() - 18*3600000).toISOString() },
    { title: "New Research Shows AI Can Detect Early-Stage Cancer with 95% Accuracy", summary: "A landmark study demonstrates that a new AI diagnostic system can detect early-stage cancers across 12 types with 95% accuracy using routine blood tests. Clinical trials begin at 50 hospitals.", source: "Google News", url: "https://news.google.com/", image_url: "", published: new Date(Date.now() - 24*3600000).toISOString() },
    { title: "Breakthrough in AI Chip Design Reduces Training Costs by 10x", summary: "Researchers developed a novel chip architecture for transformer models that reduces AI training costs by an order of magnitude using analog-digital hybrid matrix multiplication.", source: "ArXiv AI", url: "https://arxiv.org/", image_url: "", published: new Date(Date.now() - 30*3600000).toISOString() }
];

const API_BASE = window.location.origin;

async function fetchNews(forceRefresh = false) {
    if (state.isLoading) return;
    state.isLoading = true;
    showLoading();
    elements.refreshBtn.classList.add("spinning");
    try {
        const url = `${API_BASE}/api/news${forceRefresh ? "?refresh=true" : ""}`;
        const response = await fetch(url);
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        const data = await response.json();
        if (data.error) throw new Error(data.error);
        let articles = data.articles || [];
        if (articles.length === 0 && data.offline) articles = DEMO_ARTICLES;
        state.articles = articles;
        populateSourceFilter(); applyFilter();
        if (state.filteredArticles.length === 0) { showEmpty(); }
        else { state.currentIndex = 0; showCards(); renderCards(); showSwipeHint(); }
    } catch (error) {
        console.log("Loading demo articles for offline/static mode...");
        state.articles = DEMO_ARTICLES;
        populateSourceFilter(); applyFilter();
        if (state.filteredArticles.length === 0) { showEmpty(); }
        else { state.currentIndex = 0; showCards(); renderCards(); showSwipeHint(); }
    } finally { state.isLoading = false; elements.refreshBtn.classList.remove("spinning"); }
}

function populateSourceFilter() {
    const sources = [...new Set(state.articles.map(a => a.source))].sort();
    const current = elements.sourceFilter.value;
    elements.sourceFilter.innerHTML = '<option value="">All Sources</option>';
    sources.forEach(source => { const o = document.createElement("option"); o.value = source; o.textContent = source; elements.sourceFilter.appendChild(o); });
    if (sources.includes(current)) elements.sourceFilter.value = current;
}
function applyFilter() { const s = elements.sourceFilter.value; state.filteredArticles = s ? state.articles.filter(a => a.source === s) : [...state.articles]; }

function showLoading() { elements.loading.style.display="flex"; elements.error.style.display="none"; elements.empty.style.display="none"; elements.cardContainer.style.display="none"; }
function showError() { elements.loading.style.display="none"; elements.error.style.display="flex"; elements.empty.style.display="none"; elements.cardContainer.style.display="none"; }
function showEmpty() { elements.loading.style.display="none"; elements.error.style.display="none"; elements.empty.style.display="flex"; elements.cardContainer.style.display="none"; }
function showCards() { elements.loading.style.display="none"; elements.error.style.display="none"; elements.empty.style.display="none"; elements.cardContainer.style.display="block"; }
function showSwipeHint() { if (state.hintShown) return; state.hintShown = true; elements.swipeHint.style.display = "block"; setTimeout(() => { elements.swipeHint.style.display = "none"; }, 3000); }

function renderCards() {
    elements.cardContainer.innerHTML = "";
    const total = state.filteredArticles.length;
    if (total === 0) { showEmpty(); return; }
    const n = Math.min(3, total - state.currentIndex);
    for (let i = n - 1; i >= 0; i--) {
        const idx = state.currentIndex + i;
        if (idx >= total) continue;
        elements.cardContainer.appendChild(createCardElement(state.filteredArticles[idx], i));
    }
    updateCounter(); updateNavButtons();
}

function createCardElement(article, pos) {
    const card = document.createElement("div"); card.className = "news-card";
    const scale = 1 - pos * 0.04, ty = -50 + pos * 2;
    card.style.transform = `translate(-50%, ${ty}%) scale(${scale})`;
    card.style.zIndex = 10 - pos; card.style.opacity = pos > 1 ? 0.5 : 1;
    const img = document.createElement("div"); img.className = "card-image";
    if (article.image_url) {
        const i = document.createElement("img"); i.alt = article.title; i.loading = "lazy"; i.style.opacity = "0";
        i.onload = () => (i.style.opacity = "1");
        i.onerror = () => { img.innerHTML = `<div class="card-image-placeholder" style="background: ${getSourceGradient(article.source)}"><span>AI</span></div>`; };
        i.src = article.image_url; img.appendChild(i);
    } else { img.innerHTML = `<div class="card-image-placeholder" style="background: ${getSourceGradient(article.source)}"><span>AI</span></div>`; }
    const ov = document.createElement("div"); ov.className = "card-image-overlay"; img.appendChild(ov);
    const content = document.createElement("div"); content.className = "card-content";
    content.innerHTML = `<div class="card-meta"><span class="card-source" style="background: ${getSourceColor(article.source)}">${escapeHtml(article.source)}</span><span class="card-date">${formatRelativeDate(article.published)}</span></div><h2 class="card-title">${escapeHtml(article.title)}</h2><p class="card-summary">${escapeHtml(article.summary)}</p><a href="${escapeHtml(article.url)}" target="_blank" rel="noopener noreferrer" class="card-link">Read Full Article <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg></a>`;
    card.appendChild(img); card.appendChild(content);
    if (pos === 0) addSwipeHandlers(card);
    return card;
}

function addSwipeHandlers(card) {
    card.addEventListener("touchstart", handleTouchStart, { passive: true });
    card.addEventListener("touchmove", handleTouchMove, { passive: false });
    card.addEventListener("touchend", handleTouchEnd);
    card.addEventListener("mousedown", handleMouseDown);
}
function handleTouchStart(e) { const t = e.touches[0]; state.touchStartX = t.clientX; state.touchStartY = t.clientY; state.touchCurrentX = t.clientX; state.isDragging = true; this.classList.add("dragging"); }
function handleTouchMove(e) {
    if (!state.isDragging) return; const t = e.touches[0]; state.touchCurrentX = t.clientX;
    const dx = t.clientX - state.touchStartX, dy = Math.abs(t.clientY - state.touchStartY);
    if (dy > Math.abs(dx) && Math.abs(dx) < 20) return;
    e.preventDefault(); const r = dx * 0.08;
    this.style.transform = `translate(calc(-50% + ${dx}px), -50%) rotate(${r}deg)`;
    this.style.opacity = Math.max(0.3, 1 - Math.abs(dx) / 400);
}
function handleTouchEnd() {
    if (!state.isDragging) return; state.isDragging = false; this.classList.remove("dragging");
    const dx = state.touchCurrentX - state.touchStartX;
    if (Math.abs(dx) > state.dragThreshold) { swipeCard(this, dx > 0 ? "right" : "left"); }
    else { this.style.transform = "translate(-50%, -50%) scale(1)"; this.style.opacity = "1"; }
}
function handleMouseDown(e) {
    e.preventDefault(); const card = this, startX = e.clientX; card.classList.add("dragging");
    function onMove(e) { const dx = e.clientX - startX; card.style.transform = `translate(calc(-50% + ${dx}px), -50%) rotate(${dx*0.08}deg)`; card.style.opacity = Math.max(0.3, 1-Math.abs(dx)/400); }
    function onUp(e) { document.removeEventListener("mousemove", onMove); document.removeEventListener("mouseup", onUp); card.classList.remove("dragging"); const dx = e.clientX - startX; if (Math.abs(dx) > state.dragThreshold) { swipeCard(card, dx > 0 ? "right" : "left"); } else { card.style.transform = "translate(-50%, -50%) scale(1)"; card.style.opacity = "1"; } }
    document.addEventListener("mousemove", onMove); document.addEventListener("mouseup", onUp);
}
function swipeCard(card, dir) { card.classList.add(dir === "left" ? "swiping-left" : "swiping-right"); setTimeout(() => { dir === "left" ? goNext() : goPrev(); }, 300); }

function goNext() { if (state.currentIndex < state.filteredArticles.length - 1) { state.currentIndex++; renderCards(); } }
function goPrev() { if (state.currentIndex > 0) { state.currentIndex--; renderCards(); } }
function updateCounter() { const t = state.filteredArticles.length; elements.currentIndex.textContent = t > 0 ? state.currentIndex + 1 : 0; elements.totalCount.textContent = t; }
function updateNavButtons() { elements.prevBtn.disabled = state.currentIndex <= 0; elements.nextBtn.disabled = state.currentIndex >= state.filteredArticles.length - 1; }

function formatRelativeDate(dateStr) {
    if (!dateStr) return "";
    try {
        const date = new Date(dateStr.replace(" ", "T") + (dateStr.includes("+") ? "" : "Z"));
        const ms = Date.now() - date, m = Math.floor(ms/60000), h = Math.floor(ms/3600000), d = Math.floor(ms/86400000);
        if (m < 1) return "Just now"; if (m < 60) return `${m}m ago`; if (h < 24) return `${h}h ago`;
        if (d === 1) return "Yesterday"; if (d < 7) return `${d}d ago`;
        return date.toLocaleDateString("en-US", { month: "short", day: "numeric" });
    } catch { return dateStr; }
}
function escapeHtml(t) { if (!t) return ""; const d = document.createElement("div"); d.textContent = t; return d.innerHTML; }

elements.refreshBtn.addEventListener("click", () => fetchNews(true));
elements.retryBtn.addEventListener("click", () => fetchNews(true));
elements.emptyRefreshBtn.addEventListener("click", () => fetchNews(true));
elements.prevBtn.addEventListener("click", goPrev);
elements.nextBtn.addEventListener("click", goNext);
elements.sourceFilter.addEventListener("change", () => { applyFilter(); state.currentIndex = 0; state.filteredArticles.length > 0 ? (showCards(), renderCards()) : showEmpty(); });

document.addEventListener("keydown", (e) => {
    switch (e.key) {
        case "ArrowRight": case "ArrowDown": e.preventDefault(); goNext(); break;
        case "ArrowLeft": case "ArrowUp": e.preventDefault(); goPrev(); break;
        case "Enter": if (state.filteredArticles[state.currentIndex]) window.open(state.filteredArticles[state.currentIndex].url, "_blank"); break;
        case "r": if (!e.ctrlKey && !e.metaKey) fetchNews(true); break;
    }
});
setInterval(() => fetchNews(false), 30 * 60 * 1000);

if ('serviceWorker' in navigator) { window.addEventListener('load', () => { navigator.serviceWorker.register('./sw.js').then(r => { setInterval(() => r.update(), 3600000); }).catch(e => console.log('SW registration failed:', e)); }); }

let deferredPrompt = null; const installBtn = document.getElementById('install-btn');
window.addEventListener('beforeinstallprompt', (e) => { e.preventDefault(); deferredPrompt = e; if (installBtn) installBtn.style.display = 'flex'; });
if (installBtn) { installBtn.addEventListener('click', async () => { if (!deferredPrompt) return; deferredPrompt.prompt(); const { outcome } = await deferredPrompt.userChoice; deferredPrompt = null; installBtn.style.display = 'none'; }); }
window.addEventListener('appinstalled', () => { deferredPrompt = null; if (installBtn) installBtn.style.display = 'none'; });

fetchNews();