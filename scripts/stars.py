import json, urllib.request

repos = ["termux/termux-app", "fossify/Notes", "python/cpython"]
print("GitHub stars, fetched from this device:")
for r in repos:
    try:
        with urllib.request.urlopen("https://api.github.com/repos/" + r, timeout=20) as f:
            d = json.load(f)
        print(r.ljust(20), str(d["stargazers_count"]).rjust(8), "stars")
    except Exception as e:
        print(r.ljust(20), "error:", e)
