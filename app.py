# app.py
# app.py
cache = []

def handle_request(data):
    # Added lightweight input validation
    if data is None:
        return {"status": "error", "reason": "invalid input"}

    cache.append(data)  # BUG: unbounded growth
    return {"status": "ok"}
