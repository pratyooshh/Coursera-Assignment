/**
 * AI News Aggregator - Service Worker
 */
const CACHE_VERSION='v1',STATIC_CACHE=`ai-news-static-${CACHE_VERSION}`,API_CACHE=`ai-news-api-${CACHE_VERSION}`;
const STATIC_ASSETS=['./', './index.html', './styles.css', './app.js', './manifest.json', './icons/icon-192.svg', './icons/icon-512.svg'];
self.addEventListener('install',e=>{e.waitUntil(caches.open(STATIC_CACHE).then(c=>c.addAll(STATIC_ASSETS)).then(()=>self.skipWaiting()));});
self.addEventListener('activate',e=>{e.waitUntil(caches.keys().then(k=>Promise.all(k.filter(x=>x!==STATIC_CACHE&&x!==API_CACHE).map(x=>caches.delete(x)))).then(()=>self.clients.claim()));});
self.addEventListener('fetch',e=>{const u=new URL(e.request.url);if(u.pathname.includes('/api/')){e.respondWith(networkFirst(e.request));return;}e.respondWith(cacheFirst(e.request));});
async function cacheFirst(r){const c=await caches.match(r);if(c)return c;try{const res=await fetch(r);if(res.ok){(await caches.open(STATIC_CACHE)).put(r,res.clone());}return res;}catch(e){if(r.mode==='navigate'){const f=await caches.match('./index.html');if(f)return f;}return new Response('Offline',{status:503});}}
async function networkFirst(r){try{const res=await fetch(r);if(res.ok){(await caches.open(API_CACHE)).put(r,res.clone());}return res;}catch(e){const c=await caches.match(r);if(c)return c;return new Response(JSON.stringify({articles:[],offline:true}),{status:200,headers:{'Content-Type':'application/json'}});}}