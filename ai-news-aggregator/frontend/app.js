/**
 * AI News Aggregator - Frontend Application
 * Inshorts-style card-based news reader with swipe navigation.
 */

// ==================== State ====================

const state = {
    articles: [],
    filteredArticles: [],
    currentIndex: 0,
    isLoading: false,
    touchStartX: 0,
    touchStartY: 0,
    touchCurrentX: 0,
    isDragging: false,
    dragThreshold: 80,
    hintShown: false,
};

// ==================== DOM Elements ====================

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

// ==================== Source Colors ====================

const SOURCE_COLORS = {
    "techcrunch": "#0a9e01",
    "mit technology review": "#d32f2f",
    "the verge": "#7b2eff",
    "arxiv ai": "#b71c1c",
    "google news": "#4285f4",
    "ars technica": "#ff6600",
    "venturebeat": "#2196f3",
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

function getSourceColor(source) {
    return SOURCE_COLORS[source.toLowerCase()] || "#6c5ce7";
}

function getSourceGradient(source) {
    return SOURCE_GRADIENTS[source.toLowerCase()] || "linear-gradient(135deg, #6c5ce7, #a29bfe)";
}

// ==================== API ====================

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

        state.articles = data.articles || [];
        populateSourceFilter();
        applyFilter();

        if (state.filteredArticles.length === 0) {
            showEmpty();
        } else {
            state.currentIndex = 0;
            showCards();
            renderCards();
            showSwipeHint();
        }
    } catch (error) {
        console.error("Failed to fetch news:", error);
        showError();
    } finally {
        state.isLoading = false;
        elements.refreshBtn.classList.remove("spinning");
    }
}

// ==================== Source Filter ====================

function populateSourceFilter() {
    const sources = [...new Set(state.articles.map((a) => a.source))].sort();
    const current = elements.sourceFilter.value;

    elements.sourceFilter.innerHTML = '<option value="">All Sources</option>';
    sources.forEach((source) => {
        const opt = document.createElement("option");
        opt.value = source;
        opt.textContent = source;
        elements.sourceFilter.appendChild(opt);
    });

    // Restore previous selection if still valid
    if (sources.includes(current)) {
        elements.sourceFilter.value = current;
    }
}

function applyFilter() {
    const source = elements.sourceFilter.value;
    state.filteredArticles = source
        ? state.articles.filter((a) => a.source === source)
        : [...state.articles];
}

// ==================== UI States ====================

function showLoading() {
    elements.loading.style.display = "flex";
    elements.error.style.display = "none";
    elements.empty.style.display = "none";
    elements.cardContainer.style.display = "none";
}

function showError() {
    elements.loading.style.display = "none";
    elements.error.style.display = "flex";
    elements.empty.style.display = "none";
    elements.cardContainer.style.display = "none";
}

function showEmpty() {
    elements.loading.style.display = "none";
    elements.error.style.display = "none";
    elements.empty.style.display = "flex";
    elements.cardContainer.style.display = "none";
}

function showCards() {
    elements.loading.style.display = "none";
    elements.error.style.display = "none";
    elements.empty.style.display = "none";
    elements.cardContainer.style.display = "block";
}

function showSwipeHint() {
    if (state.hintShown) return;
    state.hintShown = true;
    elements.swipeHint.style.display = "block";
    setTimeout(() => {
        elements.swipeHint.style.display = "none";
    }, 3000);
}

// ==================== Card Rendering ====================

function renderCards() {
    elements.cardContainer.innerHTML = "";

    const total = state.filteredArticles.length;
    if (total === 0) {
        showEmpty();
        return;
    }

    // Render up to 3 cards in the stack
    const cardsToRender = Math.min(3, total - state.currentIndex);

    for (let i = cardsToRender - 1; i >= 0; i--) {
        const articleIndex = state.currentIndex + i;
        if (articleIndex >= total) continue;

        const article = state.filteredArticles[articleIndex];
        const card = createCardElement(article, i);
        elements.cardContainer.appendChild(card);
    }

    updateCounter();
    updateNavButtons();
}

function createCardElement(article, stackPosition) {
    const card = document.createElement("div");
    card.className = "news-card";
    card.dataset.stackPosition = stackPosition;

    // Stack positioning
    const scale = 1 - stackPosition * 0.04;
    const translateY = -50 + stackPosition * 2;
    card.style.transform = `translate(-50%, ${translateY}%) scale(${scale})`;
    card.style.zIndex = 10 - stackPosition;
    card.style.opacity = stackPosition > 1 ? 0.5 : 1;

    // Image section
    const imageSection = document.createElement("div");
    imageSection.className = "card-image";

    if (article.image_url) {
        const img = document.createElement("img");
        img.alt = article.title;
        img.loading = "lazy";
        img.style.opacity = "0";
        img.onload = () => (img.style.opacity = "1");
        img.onerror = () => {
            imageSection.innerHTML = `
                <div class="card-image-placeholder" style="background: ${getSourceGradient(article.source)}">
                    <span>AI</span>
                </div>`;
        };
        img.src = article.image_url;
        imageSection.appendChild(img);
    } else {
        imageSection.innerHTML = `
            <div class="card-image-placeholder" style="background: ${getSourceGradient(article.source)}">
                <span>AI</span>
            </div>`;
    }

    const overlay = document.createElement("div");
    overlay.className = "card-image-overlay";
    imageSection.appendChild(overlay);

    // Content section
    const content = document.createElement("div");
    content.className = "card-content";

    const sourceColor = getSourceColor(article.source);

    content.innerHTML = `
        <div class="card-meta">
            <span class="card-source" style="background: ${sourceColor}">${escapeHtml(article.source)}</span>
            <span class="card-date">${formatRelativeDate(article.published)}</span>
        </div>
        <h2 class="card-title">${escapeHtml(article.title)}</h2>
        <p class="card-summary">${escapeHtml(article.summary)}</p>
        <a href="${escapeHtml(article.url)}" target="_blank" rel="noopener noreferrer" class="card-link">
            Read Full Article
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <line x1="5" y1="12" x2="19" y2="12"></line>
                <polyline points="12 5 19 12 12 19"></polyline>
            </svg>
        </a>
    `;

    card.appendChild(imageSection);
    card.appendChild(content);

    // Add swipe handlers only to top card
    if (stackPosition === 0) {
        addSwipeHandlers(card);
    }

    return card;
}

// ==================== Swipe Handling ====================

function addSwipeHandlers(card) {
    // Touch events
    card.addEventListener("touchstart", handleTouchStart, { passive: true });
    card.addEventListener("touchmove", handleTouchMove, { passive: false });
    card.addEventListener("touchend", handleTouchEnd);

    // Mouse events
    card.addEventListener("mousedown", handleMouseDown);
}

function handleTouchStart(e) {
    const touch = e.touches[0];
    state.touchStartX = touch.clientX;
    state.touchStartY = touch.clientY;
    state.touchCurrentX = touch.clientX;
    state.isDragging = true;
    this.classList.add("dragging");
}

function handleTouchMove(e) {
    if (!state.isDragging) return;
    const touch = e.touches[0];
    state.touchCurrentX = touch.clientX;
    const deltaX = touch.clientX - state.touchStartX;
    const deltaY = Math.abs(touch.clientY - state.touchStartY);

    // If vertical scroll is dominant, don't swipe
    if (deltaY > Math.abs(deltaX) && Math.abs(deltaX) < 20) return;

    e.preventDefault();
    const rotation = deltaX * 0.08;
    this.style.transform = `translate(calc(-50% + ${deltaX}px), -50%) rotate(${rotation}deg)`;
    this.style.opacity = Math.max(0.3, 1 - Math.abs(deltaX) / 400);
}

function handleTouchEnd(e) {
    if (!state.isDragging) return;
    state.isDragging = false;
    this.classList.remove("dragging");

    const deltaX = state.touchCurrentX - state.touchStartX;
    if (Math.abs(deltaX) > state.dragThreshold) {
        swipeCard(this, deltaX > 0 ? "right" : "left");
    } else {
        // Snap back
        this.style.transform = "translate(-50%, -50%) scale(1)";
        this.style.opacity = "1";
    }
}

function handleMouseDown(e) {
    e.preventDefault();
    const card = this;
    const startX = e.clientX;

    card.classList.add("dragging");

    function onMouseMove(e) {
        const deltaX = e.clientX - startX;
        const rotation = deltaX * 0.08;
        card.style.transform = `translate(calc(-50% + ${deltaX}px), -50%) rotate(${rotation}deg)`;
        card.style.opacity = Math.max(0.3, 1 - Math.abs(deltaX) / 400);
    }

    function onMouseUp(e) {
        document.removeEventListener("mousemove", onMouseMove);
        document.removeEventListener("mouseup", onMouseUp);
        card.classList.remove("dragging");

        const deltaX = e.clientX - startX;
        if (Math.abs(deltaX) > state.dragThreshold) {
            swipeCard(card, deltaX > 0 ? "right" : "left");
        } else {
            card.style.transform = "translate(-50%, -50%) scale(1)";
            card.style.opacity = "1";
        }
    }

    document.addEventListener("mousemove", onMouseMove);
    document.addEventListener("mouseup", onMouseUp);
}

function swipeCard(card, direction) {
    card.classList.add(direction === "left" ? "swiping-left" : "swiping-right");

    setTimeout(() => {
        if (direction === "left") {
            goNext();
        } else {
            goPrev();
        }
    }, 300);
}

// ==================== Navigation ====================

function goNext() {
    if (state.currentIndex < state.filteredArticles.length - 1) {
        state.currentIndex++;
        renderCards();
    }
}

function goPrev() {
    if (state.currentIndex > 0) {
        state.currentIndex--;
        renderCards();
    }
}

function updateCounter() {
    const total = state.filteredArticles.length;
    elements.currentIndex.textContent = total > 0 ? state.currentIndex + 1 : 0;
    elements.totalCount.textContent = total;
}

function updateNavButtons() {
    elements.prevBtn.disabled = state.currentIndex <= 0;
    elements.nextBtn.disabled = state.currentIndex >= state.filteredArticles.length - 1;
}

// ==================== Utilities ====================

function formatRelativeDate(dateStr) {
    if (!dateStr) return "";

    try {
        const date = new Date(dateStr.replace(" ", "T") + (dateStr.includes("+") ? "" : "Z"));
        const now = new Date();
        const diffMs = now - date;
        const diffMins = Math.floor(diffMs / 60000);
        const diffHours = Math.floor(diffMs / 3600000);
        const diffDays = Math.floor(diffMs / 86400000);

        if (diffMins < 1) return "Just now";
        if (diffMins < 60) return `${diffMins}m ago`;
        if (diffHours < 24) return `${diffHours}h ago`;
        if (diffDays === 1) return "Yesterday";
        if (diffDays < 7) return `${diffDays}d ago`;

        return date.toLocaleDateString("en-US", { month: "short", day: "numeric" });
    } catch {
        return dateStr;
    }
}

function escapeHtml(text) {
    if (!text) return "";
    const div = document.createElement("div");
    div.textContent = text;
    return div.innerHTML;
}

// ==================== Event Listeners ====================

// Refresh button
elements.refreshBtn.addEventListener("click", () => fetchNews(true));

// Retry button
elements.retryBtn.addEventListener("click", () => fetchNews(true));

// Empty state refresh
elements.emptyRefreshBtn.addEventListener("click", () => fetchNews(true));

// Navigation buttons
elements.prevBtn.addEventListener("click", goPrev);
elements.nextBtn.addEventListener("click", goNext);

// Source filter
elements.sourceFilter.addEventListener("change", () => {
    applyFilter();
    state.currentIndex = 0;
    if (state.filteredArticles.length > 0) {
        showCards();
        renderCards();
    } else {
        showEmpty();
    }
});

// Keyboard navigation
document.addEventListener("keydown", (e) => {
    switch (e.key) {
        case "ArrowRight":
        case "ArrowDown":
            e.preventDefault();
            goNext();
            break;
        case "ArrowLeft":
        case "ArrowUp":
            e.preventDefault();
            goPrev();
            break;
        case "Enter":
            // Open current article
            if (state.filteredArticles[state.currentIndex]) {
                window.open(state.filteredArticles[state.currentIndex].url, "_blank");
            }
            break;
        case "r":
            if (!e.ctrlKey && !e.metaKey) {
                fetchNews(true);
            }
            break;
    }
});

// Auto-refresh every 30 minutes
setInterval(() => fetchNews(false), 30 * 60 * 1000);

// ==================== Initialize ====================

fetchNews();
