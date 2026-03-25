"""
AI News Aggregator - Flask API Server
Serves AI news from multiple sources with caching and background refresh.
"""

import os
import time
import logging
import threading

from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
from apscheduler.schedulers.background import BackgroundScheduler

from news_fetcher import NewsFetcher

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger(__name__)

# Initialize Flask app - serve frontend static files
FRONTEND_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "frontend")
app = Flask(__name__, static_folder=FRONTEND_DIR, static_url_path="")
CORS(app)

# News fetcher instance
newsapi_key = os.environ.get("NEWSAPI_KEY")
fetcher = NewsFetcher(newsapi_key=newsapi_key)

# In-memory cache
CACHE_TTL = 3600  # 1 hour
_cache = {
    "articles": [],
    "last_fetched": 0,
}
_cache_lock = threading.Lock()


def refresh_cache():
    """Fetch fresh news and update the cache."""
    try:
        logger.info("Refreshing news cache...")
        articles = fetcher.fetch_all()
        with _cache_lock:
            _cache["articles"] = articles
            _cache["last_fetched"] = time.time()
        logger.info(f"Cache refreshed with {len(articles)} articles.")
    except Exception as e:
        logger.error(f"Error refreshing cache: {e}")


def get_cached_articles(force_refresh=False):
    """Return cached articles, refreshing if stale or forced."""
    with _cache_lock:
        age = time.time() - _cache["last_fetched"]
        has_data = len(_cache["articles"]) > 0

    if force_refresh or not has_data or age > CACHE_TTL:
        refresh_cache()

    with _cache_lock:
        return list(_cache["articles"])


# --- Routes ---

@app.route("/")
def serve_index():
    """Serve the frontend index.html."""
    return send_from_directory(FRONTEND_DIR, "index.html")


@app.route("/<path:filename>")
def serve_static(filename):
    """Serve static frontend files."""
    return send_from_directory(FRONTEND_DIR, filename)


@app.route("/api/news")
def get_news():
    """Return AI news articles as JSON."""
    try:
        force_refresh = request.args.get("refresh", "").lower() == "true"
        articles = get_cached_articles(force_refresh=force_refresh)

        # Optional: filter by source
        source = request.args.get("source", "").strip()
        if source:
            articles = [a for a in articles if a["source"].lower() == source.lower()]

        # Optional: limit results
        limit = request.args.get("limit", type=int)
        if limit and limit > 0:
            articles = articles[:limit]

        return jsonify({
            "count": len(articles),
            "articles": articles,
            "cached_at": _cache["last_fetched"],
        })
    except Exception as e:
        logger.error(f"Error serving news: {e}")
        return jsonify({"error": "Failed to fetch news. Please try again."}), 500


@app.route("/api/sources")
def get_sources():
    """Return available news sources."""
    with _cache_lock:
        sources = list(set(a["source"] for a in _cache["articles"]))
    sources.sort()
    return jsonify({"sources": sources})


# --- Background Scheduler ---

scheduler = BackgroundScheduler()
scheduler.add_job(refresh_cache, "interval", hours=6, id="news_refresh")


# --- Startup ---

def initial_fetch():
    """Run initial fetch in a background thread so server starts fast."""
    refresh_cache()


if __name__ == "__main__":
    # Start initial fetch in background
    thread = threading.Thread(target=initial_fetch, daemon=True)
    thread.start()

    # Start scheduler
    scheduler.start()

    logger.info("Starting AI News Aggregator server on http://0.0.0.0:5000")
    app.run(host="0.0.0.0", port=5000, debug=False)
