# AI News Aggregator

A card-based AI news reader inspired by Inshorts. Swipe through the latest AI news from multiple sources, all in one place.

## Features

- **Card-based UI** - Swipeable news cards with touch, mouse, and keyboard support
- **Multiple Sources** - Aggregates news from TechCrunch, MIT Tech Review, The Verge, ArXiv, Google News, Ars Technica, and VentureBeat
- **Auto Refresh** - Background refresh every 6 hours with in-memory caching
- **Source Filtering** - Filter articles by news source
- **Responsive Design** - Works on mobile, tablet, and desktop
- **Deduplication** - Removes duplicate articles across sources
- **No Framework Dependencies** - Vanilla HTML/CSS/JS frontend

## Quick Start

### Prerequisites

- Python 3.8+

### Setup

```bash
# Navigate to the project
cd ai-news-aggregator

# Create a virtual environment (optional but recommended)
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r backend/requirements.txt

# Run the server
cd backend
python app.py
```

Open **http://localhost:5000** in your browser.

### Optional: NewsAPI Key

For additional news coverage, set a [NewsAPI](https://newsapi.org/) key:

```bash
export NEWSAPI_KEY=your_api_key_here
python app.py
```

## Project Structure

```
ai-news-aggregator/
├── backend/
│   ├── app.py              # Flask API server
│   ├── news_fetcher.py     # News fetching and parsing logic
│   └── requirements.txt    # Python dependencies
├── frontend/
│   ├── index.html          # Main page
│   ├── styles.css          # Styling
│   └── app.js              # Frontend logic
└── README.md
```

## API Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/` | GET | Serves the frontend |
| `/api/news` | GET | Returns all cached news articles |
| `/api/news?refresh=true` | GET | Forces a fresh fetch |
| `/api/news?source=TechCrunch` | GET | Filter by source |
| `/api/news?limit=10` | GET | Limit number of results |
| `/api/sources` | GET | List available sources |

## Keyboard Shortcuts

| Key | Action |
|---|---|
| `→` / `↓` | Next article |
| `←` / `↑` | Previous article |
| `Enter` | Open article in new tab |
| `R` | Refresh news |

## Tech Stack

- **Backend**: Python, Flask, feedparser, BeautifulSoup4, APScheduler
- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **News Sources**: RSS/Atom feeds, NewsAPI (optional)
