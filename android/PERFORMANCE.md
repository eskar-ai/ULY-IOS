# Android IME performance notes

Optimizations applied for soft-keyboard latency (key → glyph → candidates).

## Principles

1. **Never block the key path** — `commitText` / delete stay synchronous and light.
2. **Suggestions are opportunistic** — debounce (~16ms) + background compute + generation cancel.
3. **Pay for spell only when needed** — completions first; edit-distance only if trie misses and length ≥ 3.
4. **Load lexicon off UI thread** — 120k-word JSON must not stall `onCreateInputView`.
5. **Respect private fields** — password editors get no candidates / no learning.

## Engine

| Change | Why |
|--------|-----|
| `HashMap` trie children + `bestFrequency` | Faster walk; prune low-value subtrees |
| Bounded heap completions | Avoid DFS materialize + full sort each key |
| Spell candidate cap + first-letter reject | Cut O(vocab) edit-distance on the IME thread pool |
| Suggestion result cache | Collapse `onUpdateSelection` storms |

## IME shell

| Change | Why |
|--------|-----|
| Async lexicon load | First keyboard show stays responsive |
| Debounced async suggest | 60fps typing; drop stale results |
| `beginBatchEdit` on candidate commit | One text update for replace+space |
| Shorter `getTextBeforeCursor(64)` | Less IPC per key |

## Measure locally

```bash
# Unit tests still gate correctness after perf changes
./scripts/run-unit-tests.sh

# Manual: type `uygh` / `bügün` and confirm candidates update without key lag
```
