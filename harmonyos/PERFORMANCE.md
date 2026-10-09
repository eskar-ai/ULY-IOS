# HarmonyOS IME performance notes

Optimizations for Input Method Extension latency (key → glyph → candidates).

## Principles

1. **Async lexicon load** in `KeyboardController.onCreate` — never parse 2.6MB JSON on panel first frame synchronously beyond the await boundary.
2. **Debounced suggest** (`scheduleSuggest` ~16ms) with generation cancel.
3. **Completions before spell** — edit-distance only when trie misses and length ≥ 3.
4. **Result cache** on identical `(partial|previous|limit)`.
5. **Private fields** — `setPrivateField(true)` clears candidates / skips learning.

## Engine

| Change | Why |
|--------|-----|
| `bestFrequency` + bounded heap completions | Fewer DFS visits per key |
| Spell scan cap + first-letter reject | Keep correction path IME-safe |
| Skip spell for len &lt; 3 | Avoid useless edit-distance |

## Controller

| Change | Why |
|--------|-----|
| `scheduleSuggest` | Collapse selection/key storms |
| Clip `before` to 64 chars | Less string work per query |
| `learnSelection` gated | Privacy + less prefs churn |

## Verify

```bash
./scripts/check-quality.sh
# DevEco: type uygh / bügün and confirm candidates without key lag
```
