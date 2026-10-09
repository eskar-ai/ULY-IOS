# Screenshot guide

App Store Connect requires screenshots for the devices you support. For a phone-first keyboard app, prepare at least **iPhone 6.7"** (e.g. iPhone 15 Pro Max) and ideally **6.1"** as well. iPad screenshots only if you keep iPad support enabled.

## What to capture (5 frames)

Shoot on a real device or Simulator with the **system-looking** keyboard visible in Notes / Messages.

1. **Host app setup screen** — shows how to enable the keyboard  
2. **Keyboard Light mode** — empty field + system-gray keyboard  
3. **Suggestions** — type `uygh`, show `uyghur` in the candidate bar  
4. **Spell check** — type `bugun`, show correction to `bügün`  
5. **Dark mode** — same keyboard in Dark appearance  

Optional sixth: long-press popup for `ë / ö / ü`.

## How to capture on Mac

```bash
cd ios
xcodegen generate
open UyghurLatin.xcodeproj
# Run on Simulator → open Notes → switch to ULY Künupka
# Device → Screenshot (⌘S) or File → Save Screen
```

Export **PNG**, no status-bar clutter if possible (Simulator → wait for clean clock, or use App Store screenshot framing tools).

## Required pixel sizes (common)

| Display | Portrait size |
|---------|----------------|
| iPhone 6.7" | 1290 × 2796 |
| iPhone 6.5" | 1284 × 2778 |
| iPhone 6.1" | 1179 × 2556 |

If Apple asks for a size you don’t have, scale from a larger capture with care (avoid stretching).

## Marketing folder

Place final exports under:

```
store/marketing/screenshots/
  01-setup.png
  02-keyboard-light.png
  03-suggestions.png
  04-spellcheck.png
  05-keyboard-dark.png
```

App icon master: `store/marketing/app-icon-1024.png`
