"""
AI News Fetcher - Scrapes and aggregates AI news from multiple RSS feeds and APIs.
Uses requests + BeautifulSoup for RSS parsing (no feedparser dependency).
"""

import re
import logging
from datetime import datetime, timezone
from difflib import SequenceMatcher
from xml.etree import ElementTree as ET

import requests
from bs4 import BeautifulSoup
from dateutil import parser as date_parser

logger = logging.getLogger(__name__)

# RSS Feed sources for AI news
RSS_FEEDS = [
    {
        "url": "https://techcrunch.com/category/artificial-intelligence/feed/",
        "source": "TechCrunch",
    },
    {
        "url": "https://www.technologyreview.com/topic/artificial-intelligence/feed",
        "source": "MIT Technology Review",
    },
    {
        "url": "https://www.theverge.com/rss/ai-artificial-intelligence/index.xml",
        "source": "The Verge",
    },
    {
        "url": "http://export.arxiv.org/rss/cs.AI",
        "source": "ArXiv AI",
    },
    {
        "url": "https://news.google.com/rss/search?q=artificial+intelligence+OR+AI+machine+learning&hl=en-US&gl=US&ceid=US:en",
        "source": "Google News",
    },
    {
        "url": "https://feeds.arstechnica.com/arstechnica/technology-lab",
        "source": "Ars Technica",
    },
    {
        "url": "https://venturebeat.com/category/ai/feed/",
        "source": "VentureBeat",
    },
]

HEADERS = {
    "User-Agent": "AI-News-Aggregator/1.0 (RSS Reader)"
}

# Common RSS/Atom namespaces
NAMESPACES = {
    "atom": "http://www.w3.org/2005/Atom",
    "media": "http://search.yahoo.com/mrss/",
    "dc": "http://purl.org/dc/elements/1.1/",
    "content": "http://purl.org/rss/1.0/modules/content/",
}


class NewsFetcher:
    """Fetches and aggregates AI news from multiple sources."""

    def __init__(self, newsapi_key=None):
        self.newsapi_key = newsapi_key
        self.session = requests.Session()
        self.session.headers.update(HEADERS)

    def fetch_all(self):
        """Fetch news from all sources, deduplicate, and sort by date."""
        all_articles = []

        for feed_config in RSS_FEEDS:
            try:
                articles = self._fetch_rss(feed_config["url"], feed_config["source"])
                all_articles.extend(articles)
                logger.info(f"Fetched {len(articles)} articles from {feed_config['source']}")
            except Exception as e:
                logger.warning(f"Failed to fetch from {feed_config['source']}: {e}")

        if self.newsapi_key:
            try:
                articles = self._fetch_newsapi()
                all_articles.extend(articles)
                logger.info(f"Fetched {len(articles)} articles from NewsAPI")
            except Exception as e:
                logger.warning(f"Failed to fetch from NewsAPI: {e}")

        articles = self._deduplicate(all_articles)
        articles.sort(key=lambda a: a.get("published_ts", 0), reverse=True)

        for article in articles:
            article.pop("published_ts", None)

        logger.info(f"Total unique articles: {len(articles)}")
        return articles

    def _fetch_rss(self, url, source_name):
        """Fetch and parse an RSS/Atom feed."""
        resp = self.session.get(url, timeout=15)
        resp.raise_for_status()

        # Parse XML
        root = ET.fromstring(resp.content)
        articles = []

        # Detect feed type: RSS 2.0 or Atom
        if root.tag == "rss" or root.find("channel") is not None:
            articles = self._parse_rss2(root, source_name)
        elif root.tag.endswith("feed") or root.tag == "{http://www.w3.org/2005/Atom}feed":
            articles = self._parse_atom(root, source_name)
        elif root.tag == "{http://www.w3.org/1999/02/22-rdf-syntax-ns#}RDF" or "rdf" in root.tag.lower():
            articles = self._parse_rdf(root, source_name)
        else:
            # Fallback: try RSS2 parsing
            articles = self._parse_rss2(root, source_name)

        return articles[:25]

    def _parse_rss2(self, root, source_name):
        """Parse RSS 2.0 feed."""
        articles = []
        channel = root.find("channel")
        if channel is None:
            return articles

        for item in channel.findall("item"):
            try:
                title = self._get_text(item, "title")
                if not title:
                    continue

                link = self._get_text(item, "link")
                description = self._get_text(item, "description") or self._get_text(item, f"{{{NAMESPACES['content']}}}encoded") or ""
                pub_date = self._get_text(item, "pubDate") or self._get_text(item, f"{{{NAMESPACES['dc']}}}date") or ""

                summary = self._clean_html(description)
                summary = self._truncate_summary(summary, 200)
                published, published_ts = self._normalize_date(pub_date)
                image_url = self._extract_image_rss(item, description)

                articles.append({
                    "title": title.strip(),
                    "summary": summary if summary else "Click to read the full article.",
                    "source": source_name,
                    "published": published,
                    "published_ts": published_ts,
                    "url": link,
                    "image_url": image_url,
                })
            except Exception as e:
                logger.debug(f"Skipping RSS2 entry from {source_name}: {e}")

        return articles

    def _parse_atom(self, root, source_name):
        """Parse Atom feed."""
        articles = []
        ns = "{http://www.w3.org/2005/Atom}"

        for entry in root.findall(f"{ns}entry"):
            try:
                title_el = entry.find(f"{ns}title")
                title = title_el.text if title_el is not None and title_el.text else ""
                if not title:
                    continue

                # Get link
                link = ""
                for link_el in entry.findall(f"{ns}link"):
                    rel = link_el.get("rel", "alternate")
                    if rel == "alternate" or not link:
                        link = link_el.get("href", "")

                # Summary
                summary_el = entry.find(f"{ns}summary") or entry.find(f"{ns}content")
                description = summary_el.text if summary_el is not None and summary_el.text else ""
                summary = self._clean_html(description)
                summary = self._truncate_summary(summary, 200)

                # Date
                date_el = entry.find(f"{ns}published") or entry.find(f"{ns}updated")
                date_str = date_el.text if date_el is not None and date_el.text else ""
                published, published_ts = self._normalize_date(date_str)

                # Image
                image_url = self._extract_image_atom(entry, description)

                articles.append({
                    "title": title.strip(),
                    "summary": summary if summary else "Click to read the full article.",
                    "source": source_name,
                    "published": published,
                    "published_ts": published_ts,
                    "url": link,
                    "image_url": image_url,
                })
            except Exception as e:
                logger.debug(f"Skipping Atom entry from {source_name}: {e}")

        return articles

    def _parse_rdf(self, root, source_name):
        """Parse RDF/RSS 1.0 feed (used by ArXiv)."""
        articles = []

        # Try common RDF item patterns
        for ns_prefix in ["", "{http://purl.org/rss/1.0/}", "{http://www.w3.org/1999/02/22-rdf-syntax-ns#}"]:
            items = root.findall(f"{ns_prefix}item")
            if items:
                for item in items:
                    try:
                        title = ""
                        for tag in ["title", f"{ns_prefix}title", "{http://purl.org/rss/1.0/}title"]:
                            el = item.find(tag)
                            if el is not None and el.text:
                                title = el.text
                                break
                        if not title:
                            continue

                        link = ""
                        for tag in ["link", f"{ns_prefix}link", "{http://purl.org/rss/1.0/}link"]:
                            el = item.find(tag)
                            if el is not None and el.text:
                                link = el.text
                                break
                        if not link:
                            link = item.get("{http://www.w3.org/1999/02/22-rdf-syntax-ns#}about", "")

                        description = ""
                        for tag in ["description", f"{ns_prefix}description", "{http://purl.org/rss/1.0/}description"]:
                            el = item.find(tag)
                            if el is not None and el.text:
                                description = el.text
                                break

                        date_str = ""
                        for tag in [f"{{{NAMESPACES['dc']}}}date", "pubDate"]:
                            el = item.find(tag)
                            if el is not None and el.text:
                                date_str = el.text
                                break

                        summary = self._clean_html(description)
                        summary = self._truncate_summary(summary, 200)
                        published, published_ts = self._normalize_date(date_str)

                        articles.append({
                            "title": title.strip(),
                            "summary": summary if summary else "Click to read the full article.",
                            "source": source_name,
                            "published": published,
                            "published_ts": published_ts,
                            "url": link,
                            "image_url": None,
                        })
                    except Exception as e:
                        logger.debug(f"Skipping RDF entry from {source_name}: {e}")
                break

        return articles

    def _fetch_newsapi(self):
        """Fetch articles from NewsAPI (requires API key)."""
        url = "https://newsapi.org/v2/everything"
        params = {
            "q": "artificial intelligence OR machine learning OR deep learning",
            "sortBy": "publishedAt",
            "language": "en",
            "pageSize": 20,
            "apiKey": self.newsapi_key,
        }

        resp = self.session.get(url, params=params, timeout=15)
        resp.raise_for_status()
        data = resp.json()

        articles = []
        for item in data.get("articles", []):
            try:
                published_dt = date_parser.parse(item["publishedAt"])
                articles.append({
                    "title": item.get("title", "").strip(),
                    "summary": self._truncate_summary(item.get("description", "") or "", 200),
                    "source": item.get("source", {}).get("name", "NewsAPI"),
                    "published": published_dt.strftime("%Y-%m-%d %H:%M"),
                    "published_ts": published_dt.timestamp(),
                    "url": item.get("url", ""),
                    "image_url": item.get("urlToImage"),
                })
            except Exception as e:
                logger.debug(f"Skipping NewsAPI entry: {e}")

        return articles

    def _get_text(self, element, tag):
        """Safely get text content of a child element."""
        el = element.find(tag)
        if el is not None:
            return el.text or ""
        return ""

    def _clean_html(self, raw_html):
        """Strip HTML tags and decode entities."""
        if not raw_html:
            return ""
        soup = BeautifulSoup(raw_html, "html.parser")
        text = soup.get_text(separator=" ")
        text = re.sub(r"\s+", " ", text).strip()
        return text

    def _truncate_summary(self, text, max_len=200):
        """Truncate text to max_len, breaking at word boundary."""
        if not text or len(text) <= max_len:
            return text
        truncated = text[:max_len].rsplit(" ", 1)[0]
        return truncated.rstrip(".,;:!?") + "..."

    def _normalize_date(self, date_str):
        """Parse date string. Returns (formatted_str, timestamp)."""
        if date_str:
            try:
                dt = date_parser.parse(date_str)
                if dt.tzinfo is None:
                    dt = dt.replace(tzinfo=timezone.utc)
                return dt.strftime("%Y-%m-%d %H:%M"), dt.timestamp()
            except Exception:
                pass

        now = datetime.now(timezone.utc)
        return now.strftime("%Y-%m-%d %H:%M"), now.timestamp()

    def _extract_image_rss(self, item, description_html):
        """Extract image from RSS item."""
        # Check media:content
        for ns_uri in [NAMESPACES["media"], "http://search.yahoo.com/mrss/"]:
            media = item.find(f"{{{ns_uri}}}content")
            if media is not None:
                url = media.get("url", "")
                if url:
                    return url
            thumb = item.find(f"{{{ns_uri}}}thumbnail")
            if thumb is not None:
                url = thumb.get("url", "")
                if url:
                    return url

        # Check enclosure
        enclosure = item.find("enclosure")
        if enclosure is not None:
            enc_type = enclosure.get("type", "")
            if enc_type.startswith("image/"):
                return enclosure.get("url", "")

        # Try to find image in description HTML
        return self._extract_image_from_html(description_html)

    def _extract_image_atom(self, entry, description_html):
        """Extract image from Atom entry."""
        ns = "{http://search.yahoo.com/mrss/}"
        media = entry.find(f"{ns}content")
        if media is not None:
            url = media.get("url", "")
            if url:
                return url
        thumb = entry.find(f"{ns}thumbnail")
        if thumb is not None:
            url = thumb.get("url", "")
            if url:
                return url

        return self._extract_image_from_html(description_html)

    def _extract_image_from_html(self, html):
        """Extract first image URL from HTML content."""
        if not html or "<img" not in html.lower():
            return None
        try:
            soup = BeautifulSoup(html, "html.parser")
            img = soup.find("img")
            if img and img.get("src"):
                return img["src"]
        except Exception:
            pass
        return None

    def _deduplicate(self, articles):
        """Remove duplicate articles based on title similarity."""
        seen_titles = []
        unique = []

        for article in articles:
            title = article.get("title", "")
            normalized = re.sub(r"[^a-z0-9\s]", "", title.lower()).strip()

            if not normalized:
                continue

            is_dup = False
            for seen in seen_titles:
                ratio = SequenceMatcher(None, normalized, seen).ratio()
                if ratio > 0.75:
                    is_dup = True
                    break

            if not is_dup:
                seen_titles.append(normalized)
                unique.append(article)

        return unique
