import { lookupKey } from './Uly';
import { PrefixTrie } from './Trie';

function foldDiacritics(s: string): string {
  return s.replace(/ö/g, 'o').replace(/ü/g, 'u').replace(/ë/g, 'e').replace(/é/g, 'e');
}

function editDistance(a: string, b: string, max: number): number {
  const n = a.length;
  const m = b.length;
  if (Math.abs(n - m) > max) {
    return -1;
  }
  if (n === 0) {
    return m;
  }
  if (m === 0) {
    return n;
  }
  let prev: number[] = [];
  for (let i = 0; i <= m; i++) {
    prev.push(i);
  }
  let cur: number[] = new Array(m + 1);
  for (let i = 1; i <= n; i++) {
    cur[0] = i;
    let rowMin = cur[0];
    for (let j = 1; j <= m; j++) {
      const cost = a.charAt(i - 1) === b.charAt(j - 1) ? 0 : 1;
      cur[j] = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost);
      rowMin = Math.min(rowMin, cur[j]);
    }
    if (rowMin > max) {
      return -1;
    }
    const tmp = prev;
    prev = cur;
    cur = tmp;
  }
  const d = prev[m];
  return d > max ? -1 : d;
}

export class SpellChecker {
  private byLength: Map<number, string[]> = new Map();
  private trie: PrefixTrie;
  private corrections: Map<string, string>;

  constructor(trie: PrefixTrie, vocabulary: string[], corrections: Record<string, string>) {
    this.trie = trie;
    this.corrections = new Map();
    const keys = Object.keys(corrections);
    for (let i = 0; i < keys.length; i++) {
      this.corrections.set(keys[i], corrections[keys[i]]);
    }
    const buckets: Map<number, string[]> = new Map();
    for (let i = 0; i < vocabulary.length; i++) {
      const w = vocabulary[i];
      let list = buckets.get(w.length);
      if (!list) {
        list = [];
        buckets.set(w.length, list);
      }
      list.push(w);
    }
    buckets.forEach((list, len) => {
      list.sort((a, b) => this.trie.frequency(b) - this.trie.frequency(a));
      this.byLength.set(len, list);
    });
  }

  isCorrect(word: string): boolean {
    return this.trie.contains(word);
  }

  suggestions(word: string, limit: number = 6): string[] {
    const key = lookupKey(word);
    if (!key) {
      return [];
    }
    if (this.trie.contains(key)) {
      return [key];
    }

    const ranked: Array<[string, number]> = [];
    const seen: Set<string> = new Set();

    const mapped = this.corrections.get(key);
    if (mapped && !seen.has(mapped)) {
      seen.add(mapped);
      ranked.push([mapped, 1000000 + this.trie.frequency(mapped)]);
    }

    const candidates: string[] = [];
    for (let len = Math.max(1, key.length - 2); len <= key.length + 2; len++) {
      const bucket = this.byLength.get(len);
      if (bucket) {
        for (let i = 0; i < bucket.length; i++) {
          candidates.push(bucket[i]);
        }
      }
    }
    const capped = candidates.slice(0, 3500);
    for (let i = 0; i < capped.length; i++) {
      const cand = capped[i];
      if (seen.has(cand)) {
        continue;
      }
      const d = editDistance(key, cand, 2);
      if (d < 0 || d > 2) {
        continue;
      }
      seen.add(cand);
      ranked.push([cand, this.trie.frequency(cand) - d * 50000]);
    }

    if (ranked.length < limit) {
      const folded = foldDiacritics(key);
      const sameLen = this.byLength.get(key.length) ?? [];
      for (let i = 0; i < sameLen.length; i++) {
        const cand = sameLen[i];
        if (seen.has(cand)) {
          continue;
        }
        if (foldDiacritics(cand) === folded) {
          seen.add(cand);
          ranked.push([cand, this.trie.frequency(cand) + 10000]);
        }
      }
    }

    ranked.sort((a, b) => b[1] - a[1]);
    return ranked.slice(0, limit).map((p) => p[0]);
  }
}
