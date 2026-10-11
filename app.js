/* AI News - Instagram-style PWA */
const SOURCES={
"TechCrunch":{short:"TC",grad:"linear-gradient(135deg,#0a9e01,#00c853)"},
"MIT Technology Review":{short:"MIT",grad:"linear-gradient(135deg,#b71c1c,#ff5252)"},
"The Verge":{short:"VRG",grad:"linear-gradient(135deg,#5b16d0,#e040fb)"},
"ArXiv AI":{short:"arX",grad:"linear-gradient(135deg,#7f0000,#e57373)"},
"Google News":{short:"GN",grad:"linear-gradient(135deg,#1a73e8,#34a853)"},
"Ars Technica":{short:"ARS",grad:"linear-gradient(135deg,#e65100,#ffb74d)"},
"VentureBeat":{short:"VB",grad:"linear-gradient(135deg,#0d47a1,#4fc3f7)"}
};
const FALLBACK={short:"AI",grad:"linear-gradient(135deg,#833ab4,#fd1d1d,#fcb045)"};
const PAGE=10;
const ICONS={
heart:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20.8 4.6a5.5 5.5 0 00-7.8 0L12 5.7l-1-1.1a5.5 5.5 0 00-7.8 7.8l1 1.1L12 21l7.8-7.5 1-1.1a5.5 5.5 0 000-7.8z"/></svg>',
heartFill:'<svg viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="2"><path d="M20.8 4.6a5.5 5.5 0 00-7.8 0L12 5.7l-1-1.1a5.5 5.5 0 00-7.8 7.8l1 1.1L12 21l7.8-7.5 1-1.1a5.5 5.5 0 000-7.8z"/></svg>',
comment:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M21 11.5a8.4 8.4 0 01-12.4 7.4L3 21l2.1-5.6A8.4 8.4 0 1121 11.5z"/></svg>',
share:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><line x1="22" y1="3" x2="9.2" y2="10.1"/><polygon points="22 3 15 21 11 13 3 9.6 22 3"/></svg>',
save:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M19 21l-7-5-7 5V5a2 2 0 012-2h10a2 2 0 012 2z"/></svg>',
saveFill:'<svg viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M19 21l-7-5-7 5V5a2 2 0 012-2h10a2 2 0 012 2z"/></svg>',
more:'<svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><circle cx="5" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="19" cy="12" r="1.6"/></svg>',
verified:'<svg class="verified" viewBox="0 0 24 24" fill="currentColor"><path d="M12 1l2.6 2.2 3.4-.4.9 3.3 3 1.7-1.3 3.2 1.3 3.2-3 1.7-.9 3.3-3.4-.4L12 23l-2.6-2.2-3.4.4-.9-3.3-3-1.7L3.4 13 2.1 9.8l3-1.7.9-3.3 3.4.4z"/><path d="M10.5 15.5l-3-3 1.4-1.4 1.6 1.6 4.6-4.6 1.4 1.4z" fill="#000"/></svg>',
search:'<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>'
};

const store={
get(k,d){try{const v=localStorage.getItem(k);return v?JSON.parse(v):d}catch{return d}},
set(k,v){try{localStorage.setItem(k,JSON.stringify(v))}catch{}}
};
const state={articles:[],source:"",tab:"home",shown:0,liked:new Set(store.get("liked",[])),saved:new Set(store.get("saved",[])),seen:new Set(store.get("seen",[])),loading:false,query:""};
const $=id=>document.getElementById(id);
const el={feed:$("feed"),cards:$("feed-cards"),loading:$("loading"),error:$("error"),empty:$("empty"),stories:$("stories-bar"),refresh:$("refresh-btn")};
let observer=null;

const meta=s=>SOURCES[s]||FALLBACK;
const keyOf=a=>a.url+"|"+a.title;
function hash(s){let h=0;for(let i=0;i<s.length;i++)h=(h*31+s.charCodeAt(i))|0;return Math.abs(h)}
function esc(t){const d=document.createElement("div");d.textContent=t??"";return d.innerHTML}
function safeUrl(u){try{const x=new URL(u);return x.protocol==="http:"||x.protocol==="https:"?x.href:"#"}catch{return"#"}}
function fmtNum(n){return n>=1e6?(n/1e6).toFixed(1)+"M":n>=1e4?Math.round(n/1e3)+"K":n.toLocaleString("en-US")}
function relTime(d){const t=new Date(d);if(isNaN(t))return"";const m=Math.floor((Date.now()-t)/6e4);if(m<1)return"Just now";if(m<60)return m+" minutes ago";const h=Math.floor(m/60);if(h<24)return h+(h===1?" hour ago":" hours ago");const dd=Math.floor(h/24);if(dd<7)return dd+(dd===1?" day ago":" days ago");return t.toLocaleDateString("en-US",{month:"long",day:"numeric"})}
function toast(msg){let t=document.querySelector(".toast");if(!t){t=document.createElement("div");t.className="toast";document.body.appendChild(t)}t.textContent=msg;t.classList.add("show");clearTimeout(t._h);t._h=setTimeout(()=>t.classList.remove("show"),1800)}
function show(which){el.loading.style.display=which==="loading"?"block":"none";el.error.style.display=which==="error"?"flex":"none";el.empty.style.display=which==="empty"?"flex":"none";el.cards.style.display=which==="cards"?"block":"none"}

async function load(force=false){
if(state.loading)return;state.loading=true;el.refresh.classList.add("spinning");if(!state.articles.length)show("loading");
let articles=[];
try{const r=await fetch(`./api/news${force?"?refresh=true":""}`);if(r.ok){const d=await r.json();articles=d.articles||[]}}catch{}
if(!articles.length)articles=DEMO_ARTICLES;
state.articles=articles.slice().sort((a,b)=>new Date(b.published)-new Date(a.published));
state.loading=false;el.refresh.classList.remove("spinning");
renderStories();render();
if(force)toast("Feed updated");
}

function renderStories(){
const sources=[...new Set(state.articles.map(a=>a.source))];
const item=(src,label,short,grad)=>`<div class="story-item${state.source===src?" active":""}${src&&state.seen.has(src)?" seen":""}" data-source="${esc(src)}"><div class="story-ring"><div class="story-avatar" style="background:${grad}">${esc(short)}</div></div><span class="story-name">${esc(label)}</span></div>`;
el.stories.innerHTML=item("","All","ALL","linear-gradient(135deg,#833ab4,#fd1d1d)")+sources.map(s=>item(s,s,meta(s).short,meta(s).grad)).join("");
}
el.stories.addEventListener("click",e=>{const it=e.target.closest(".story-item");if(!it)return;const src=it.dataset.source;state.source=state.source===src?"":src;if(src){state.seen.add(src);store.set("seen",[...state.seen])}setTab("home");renderStories()});

function postHTML(a){
const k=keyOf(a),m=meta(a.source),liked=state.liked.has(k),saved=state.saved.has(k);
const likes=(hash(a.title)%9000)+800+(liked?1:0);
const img=a.image_url?`<img src="${esc(safeUrl(a.image_url))}" alt="" loading="lazy" onerror="this.remove()">`:"";
return `<article class="post" data-key="${esc(k)}">
<div class="post-header"><div class="post-avatar"><div style="background:${m.grad}">${esc(m.short)}</div></div>
<div class="post-meta"><div class="post-source">${esc(a.source)} ${ICONS.verified}</div><div class="post-sub">Artificial Intelligence</div></div>
<button class="post-more" data-act="open" aria-label="Open">${ICONS.more}</button></div>
<div class="post-media" data-act="media" style="background:${m.grad}">${img}${img?"":`<div class="media-headline">${esc(a.title)}</div>`}<span class="media-tag">${esc(m.short)} · AI</span><div class="heart-burst">${ICONS.heartFill}</div></div>
<div class="post-actions">
<button class="act${liked?" liked":""}" data-act="like" aria-label="Like">${liked?ICONS.heartFill:ICONS.heart}</button>
<button class="act" data-act="open" aria-label="Read">${ICONS.comment}</button>
<button class="act" data-act="share" aria-label="Share">${ICONS.share}</button>
<span class="act-spacer"></span>
<button class="act" data-act="save" aria-label="Save">${saved?ICONS.saveFill:ICONS.save}</button></div>
<div class="post-likes" data-likes="${likes-(liked?1:0)}">${fmtNum(likes)} likes</div>
<div class="post-caption"><b>${esc(m.short.toLowerCase())}_news</b><span class="caption-text clamped"><strong>${esc(a.title)}</strong> — ${esc(a.summary)}</span> <button class="more-btn" data-act="expand">more</button></div>
<a class="post-link" href="${esc(safeUrl(a.url))}" target="_blank" rel="noopener noreferrer">Read full article</a>
<div class="post-time">${esc(relTime(a.published))}</div></article>`;
}

function visible(){
if(state.tab==="saved")return state.articles.filter(a=>state.saved.has(keyOf(a)));
return state.source?state.articles.filter(a=>a.source===state.source):state.articles;
}

function render(){
if(observer){observer.disconnect();observer=null}
el.stories.style.display=state.tab==="home"?"flex":"none";
if(state.tab==="explore")return renderExplore();
if(state.tab==="profile")return renderProfile();
const list=visible();
if(!list.length){show(state.tab==="saved"?"cards":"empty");if(state.tab==="saved")el.cards.innerHTML=`<div class="state-message"><div class="state-icon">🔖</div><h2>No saved posts yet</h2><p>Tap the bookmark on any post to save it here.</p></div>`;return}
show("cards");
el.cards.innerHTML=state.tab==="saved"?`<div class="tab-title">Saved</div>`:"";
state.shown=0;appendPage(list);
}
function appendPage(list){
const next=list.slice(state.shown,state.shown+PAGE);
el.cards.insertAdjacentHTML("beforeend",next.map(postHTML).join(""));
state.shown+=next.length;
document.getElementById("sentinel")?.remove();
if(state.shown<list.length){
el.cards.insertAdjacentHTML("beforeend",'<div id="sentinel" style="height:1px"></div>');
observer=new IntersectionObserver(es=>{if(es[0].isIntersecting){observer.disconnect();appendPage(list)}},{rootMargin:"600px"});
observer.observe(document.getElementById("sentinel"));
}else if(state.tab==="home"){
el.cards.insertAdjacentHTML("beforeend",`<div class="state-message" style="padding:40px 24px"><div class="state-icon">✅</div><h2>You're all caught up</h2><p>You've seen all ${list.length} posts.</p></div>`);
}
}

function renderExplore(){
show("cards");
const q=state.query.toLowerCase();
const list=state.articles.filter(a=>!q||a.title.toLowerCase().includes(q)||a.summary.toLowerCase().includes(q)||a.source.toLowerCase().includes(q));
el.cards.innerHTML=`<label class="search-box">${ICONS.search}<input id="search" type="search" placeholder="Search AI news" value="${esc(state.query)}" autocomplete="off"></label>`+
(list.length?`<div class="grid">${list.map(a=>`<div class="grid-cell" data-key="${esc(keyOf(a))}" style="background:${meta(a.source).grad}"><span>${esc(a.title)}</span></div>`).join("")}</div>`:`<div class="state-message"><div class="state-icon">🔍</div><h2>No results</h2><p>Try another keyword.</p></div>`);
const input=$("search");
input.addEventListener("input",()=>{state.query=input.value;const pos=input.selectionStart;renderExplore();const i=$("search");i.focus();i.setSelectionRange(pos,pos)});
}

function renderProfile(){
show("cards");
const sources=new Set(state.articles.map(a=>a.source)).size;
el.cards.innerHTML=`<div class="profile"><div class="profile-top"><div class="profile-pic"><div>🤖</div></div>
<div class="profile-stats"><div><b>${state.articles.length}</b><span>posts</span></div><div><b>${state.liked.size}</b><span>liked</span></div><div><b>${state.saved.size}</b><span>saved</span></div></div></div>
<div class="profile-name">AI News Reader</div>
<div class="profile-bio">Your daily AI briefing from ${sources} sources.<br>Double-tap a post to like it. Tap a story to filter.</div>
<button class="profile-btn" id="clear-btn">Clear likes &amp; saved</button></div>`;
$("clear-btn").addEventListener("click",()=>{state.liked.clear();state.saved.clear();store.set("liked",[]);store.set("saved",[]);renderProfile();toast("Cleared")});
}

function findByKey(k){return state.articles.find(a=>keyOf(a)===k)}
function toggleLike(post,force){
const k=post.dataset.key,btn=post.querySelector('[data-act="like"]'),likesEl=post.querySelector(".post-likes");
const on=force??!state.liked.has(k);
on?state.liked.add(k):state.liked.delete(k);store.set("liked",[...state.liked]);
btn.classList.toggle("liked",on);btn.innerHTML=on?ICONS.heartFill:ICONS.heart;
likesEl.textContent=fmtNum(+likesEl.dataset.likes+(on?1:0))+" likes";
}
let lastTap={key:null,t:0};
el.cards.addEventListener("click",async e=>{
const cell=e.target.closest(".grid-cell");
if(cell){const a=findByKey(cell.dataset.key);if(a){el.cards.innerHTML=`<button class="tab-title" id="back-btn">‹ Explore</button>`+postHTML(a);$("back-btn").addEventListener("click",renderExplore)}return}
const btn=e.target.closest("[data-act]");if(!btn)return;
const post=btn.closest(".post");if(!post)return;
const a=findByKey(post.dataset.key);if(!a)return;
switch(btn.dataset.act){
case"like":toggleLike(post);break;
case"media":{const now=Date.now();if(lastTap.key===post.dataset.key&&now-lastTap.t<320){toggleLike(post,true);const h=post.querySelector(".heart-burst");h.classList.remove("show");void h.offsetWidth;h.classList.add("show");lastTap={key:null,t:0}}else lastTap={key:post.dataset.key,t:now};break}
case"save":{const k=post.dataset.key,on=!state.saved.has(k);on?state.saved.add(k):state.saved.delete(k);store.set("saved",[...state.saved]);btn.innerHTML=on?ICONS.saveFill:ICONS.save;toast(on?"Saved to your collection":"Removed from saved");if(!on&&state.tab==="saved"){post.remove();if(!visible().length)render()}break}
case"share":{const data={title:a.title,text:a.summary,url:safeUrl(a.url)};try{if(navigator.share){await navigator.share(data)}else{await navigator.clipboard.writeText(`${a.title} ${data.url}`);toast("Link copied")}}catch{}break}
case"expand":{post.querySelector(".caption-text").classList.remove("clamped");btn.remove();break}
case"open":window.open(safeUrl(a.url),"_blank","noopener");break;
}
});

function setTab(tab){
state.tab=tab;
document.querySelectorAll(".nav-item").forEach(n=>n.classList.toggle("active",n.dataset.tab===tab));
render();window.scrollTo({top:0});
}
document.querySelector(".bottom-nav").addEventListener("click",e=>{const n=e.target.closest(".nav-item");if(!n)return;if(n.dataset.tab==="home"&&state.tab==="home"){window.scrollTo({top:0,behavior:"smooth"});return}setTab(n.dataset.tab)});
document.querySelector(".header-logo").addEventListener("click",()=>{state.source="";renderStories();setTab("home")});
el.refresh.addEventListener("click",()=>load(true));
$("retry-btn").addEventListener("click",()=>load(true));
$("empty-refresh-btn").addEventListener("click",()=>{state.source="";renderStories();render()});

if("serviceWorker"in navigator)window.addEventListener("load",()=>navigator.serviceWorker.register("./sw.js").catch(()=>{}));
let deferredPrompt=null;const installBtn=$("install-btn");
window.addEventListener("beforeinstallprompt",e=>{e.preventDefault();deferredPrompt=e;installBtn.style.display="flex"});
installBtn.addEventListener("click",async()=>{if(!deferredPrompt)return;deferredPrompt.prompt();await deferredPrompt.userChoice;deferredPrompt=null;installBtn.style.display="none"});

load();
