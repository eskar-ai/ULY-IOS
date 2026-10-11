import { lookupKey } from "./uly";
import type { PrefixTrie } from "./trie";

function foldDiacritics(s: string): string {
  return s.replaceAll("ö", "o").replaceAll("ü", "u").replaceAll("ë", "e").replaceAll("é", "e");
}

function editDistance(a: string, b: string, max: number): number {
  const n = a.length;
  const m = b.length;
  if (Math.abs(n - m) > max) return -1;
  if (n === 0) return m;
  if (m === 0) return n;
  let prev = Array.from({ length: m + 1 }, (_, i) => i);
  let cur = new Array<number>(m + 1);
  for (let i = 1; i <= n; i++) {
    cur[0] = i;
    let rowMin = cur[0];
    for (let j = 1; j <= m; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      cur[j] = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost);
      rowMin = Math.min(rowMin, cur[j]);
    }
    if (rowMin > max) return -1;
    [prev, cur] = [cur, prev];
  }
  const d = prev[m];
  return d > max ? -1 : d;
}

export class SpellChecker {
  private byLength = new Map<number, string[]>();

  constructor(
    private trie: PrefixTrie,
    vocabulary: string[],
    private corrections: Record<string, string>,
  ) {
    const buckets = new Map<number, string[]>();
    for (const w of vocabulary) {
      const list = buckets.get(w.length) ?? [];
      list.push(w);
      buckets.set(w.length, list);
    }
    for (const [len, list] of buckets) {
      list.sort((a, b) => this.trie.frequency(b) - this.trie.frequency(a));
      this.byLength.set(len, list);
    }
  }

  isCorrect(word: string): boolean {
    return this.trie.contains(word);
  }

  suggestions(word: string, limit = 6): string[] {
    const key = lookupKey(word);
    if (!key) return [];
    if (this.trie.contains(key)) return [key];

    const ranked: Array<[string, number]> = [];
    const seen = new Set<string>();

    const mapped = this.corrections[key];
    if (mapped && !seen.has(mapped)) {
      seen.add(mapped);
      ranked.push([mapped, 1_000_000 + this.trie.frequency(mapped)]);
    }

    const candidates: string[] = [];
    for (let len = Math.max(1, key.length - 2); len <= key.length + 2; len++) {
      candidates.push(...(this.byLength.get(len) ?? []));
    }
    candidates.splice(3500);
    for (const cand of candidates) {
      if (seen.has(cand)) continue;
      const d = editDistance(key, cand, 2);
      if (d < 0 || d > 2) continue;
      seen.add(cand);
      ranked.push([cand, this.trie.frequency(cand) - d * 50_000]);
    }

    if (ranked.length < limit) {
      const folded = foldDiacritics(key);
      for (const cand of this.byLength.get(key.length) ?? []) {
        if (seen.has(cand)) continue;
        if (foldDiacritics(cand) === folded) {
          seen.add(cand);
          ranked.push([cand, this.trie.frequency(cand) + 10_000]);
        }
      }
    }

    ranked.sort((a, b) => b[1] - a[1]);
    return ranked.slice(0, limit).map(([w]) => w);
  }
}
