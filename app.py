# app.py
from collections import deque

# Keep a bounded in-memory cache to avoid unbounded growth in the demo app.
CACHE_MAX_ITEMS = 1000
cache = deque(maxlen=CACHE_MAX_ITEMS)

def handle_request(data):
    cache.append(data)
    return {"status": "ok", "cache_size": len(cache)}
