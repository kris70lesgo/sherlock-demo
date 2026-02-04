# app.py
# app.py
cache = []

def handle_request(data):
    cache.append(data)  # BUG: unbounded growth
    return {"status": "ok"}
