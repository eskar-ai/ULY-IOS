# iOS IME — systematic performance audit & fixes

Branch work for keyboard latency (key → glyph → candidates). Aligns with Android / HarmonyOS IME rules.

## Audit findings (before)

| Area | Issue | Risk |
|------|--------|------|
| Lexicon load | `LexiconStore(bundle:)` on main thread in `viewDidLoad` | First keyboard show janks (2.6MB JSON + 120k inserts) |
| Suggest path | Sync `refreshSuggestions()` on every key / `textDidChange` | Spell scan up to 3500 edit-distances on UI thread |
| Trie | DFS collect then full sort; no subtree frequency prune | Extra work on short prefixes with huge fan-out |
| Spell | No short-prefix skip; flat `.prefix(3500)` scan | Worst-case typing lag when trie misses |
| Cache | None | Repeated identical queries during selection storms |
| Context | Full `documentContextBeforeInput` scanned | Unnecessary string work |
| Secure fields | Keyboard hidden (good) | Keep; still skip learning if ever shown |

## Fixes applied

1. **Async lexicon load** — background queue; keys work before engine ready.
2. **Debounced async suggest** (~16ms) + generation cancel — UI thread only updates candidates.
3. **Bounded best-first trie completions** (`bestFrequency` + heap).
4. **Spell caps** — len &lt; 3 → correction map only; first-letter reject; scan cap 600/1200.
5. **Suggestion cache** on `(partial|previous|limit)`.
6. **Clip context** to last 64 characters before parsing partial/previous.

## Measure

```bash
# Engine unit tests (SwiftPM)
swift test --package-path .

# Manual (Mac): type uygh / bügün; confirm no key lag; secure fields hide keyboard
```
