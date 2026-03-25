/**
 * AI News Aggregator - Service Worker (GitHub Pages version)
 * Cache-first for static assets, network-first for API calls.
 */

const CACHE_VERSION = 'v1';
const STATIC_CACHE = `ai-news-static-${CACHE_VERSION}`;
const API_CACHE = `ai-news-api-${CACHE_VERSION}`;

const STATIC_ASSETS = [
    './',
    './index.html',
    './styles.css',
    './app.js',
    './manifest.json',
    './icons/icon-192.svg',
    './icons/icon-512.svg'
];

// ==================== Install ====================

self.addEventListener('install', (event) => {
    event.waitUntil(
        caches.open(STATIC_CACHE)
            .then((cache) => cache.addAll(STATIC_ASSETS))
            .then(() => self.skipWaiting())
    );
});

// ==================== Activate ====================

self.addEventListener('activate', (event) => {
    event.waitUntil(
        caches.keys().then((keys) => {
            return Promise.all(
                keys
                    .filter((key) => key !== STATIC_CACHE && key !== API_CACHE)
                    .map((key) => caches.delete(key))
            );
        }).then(() => self.clients.claim())
    );
});

// ==================== Fetch ====================

self.addEventListener('fetch', (event) => {
    const { request } = event;
    const url = new URL(request.url);

    // API calls: network-first strategy
    if (url.pathname.includes('/api/')) {
        event.respondWith(networkFirst(request));
        return;
    }

    // Static assets: cache-first strategy
    event.respondWith(cacheFirst(request));
});

// ==================== Strategies ====================

async function cacheFirst(request) {
    const cached = await caches.match(request);
    if (cached) return cached;

    try {
        const response = await fetch(request);
        if (response.ok) {
            const cache = await caches.open(STATIC_CACHE);
            cache.put(request, response.clone());
        }
        return response;
    } catch (error) {
        // Offline fallback
        if (request.mode === 'navigate') {
            const fallback = await caches.match('./index.html');
            if (fallback) return fallback;
        }
        return new Response('Offline', { status: 503, statusText: 'Service Unavailable' });
    }
}

async function networkFirst(request) {
    try {
        const response = await fetch(request);
        if (response.ok) {
            const cache = await caches.open(API_CACHE);
            cache.put(request, response.clone());
        }
        return response;
    } catch (error) {
        const cached = await caches.match(request);
        if (cached) return cached;

        return new Response(
            JSON.stringify({ articles: [], cached: false, offline: true }),
            {
                status: 200,
                headers: { 'Content-Type': 'application/json' }
            }
        );
    }
}

// ==================== Background Sync ====================

self.addEventListener('sync', (event) => {
    if (event.tag === 'sync-news') {
        event.waitUntil(
            fetch('./api/news?refresh=true')
                .then((response) => {
                    if (response.ok) {
                        const cache = caches.open(API_CACHE);
                        return cache.then((c) => c.put('./api/news', response));
                    }
                })
                .catch(() => {})
        );
    }
});
