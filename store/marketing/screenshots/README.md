# Screenshot files

| Pattern | Size | Use |
|---------|------|-----|
| `01-setup.png` … `05-*.png` | 1290×2796 | iPhone 6.7" |
| `*-iphone-65.png` | 1284×2778 | iPhone 6.5" |
| `*-iphone-61.png` | 1179×2556 | iPhone 6.1" |

Regenerate masters:

```bash
python3 tools/make_store_screenshots.py
python3 tools/resize_store_screenshots.py
```

Replace with Simulator/device captures before final App Store submit when possible.
