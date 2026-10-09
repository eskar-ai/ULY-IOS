# Screenshot files

| Pattern | Size | Use |
|---------|------|-----|
| `01-setup.png` … `05-*.png` | 1290×2796 | iPhone 6.7" |
| `*-iphone-65.png` | 1284×2778 | iPhone 6.5" |
| `*-iphone-61.png` | 1179×2556 | iPhone 6.1" |

Regenerate masters (from repo root):

```bash
# 1) Capture live demo frames → /opt/cursor/artifacts/screenshots/
python3 tools/capture_demo_for_store.py
# Optional: DEMO_URL=http://127.0.0.1:4173/ python3 tools/capture_demo_for_store.py

# 2) Compose App Store marketing frames (1290×2796)
python3 tools/make_store_screenshots.py

# 3) Resize to 6.5" / 6.1"
python3 tools/resize_store_screenshots.py
```

Replace with Simulator/device captures before final App Store submit when possible.
