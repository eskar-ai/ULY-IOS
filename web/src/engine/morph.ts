import { lookupKey } from "./uly";
import type { PrefixTrie } from "./trie";

const MIN_STEM = 3;

const SUFFIXES = [
  "turdigizmu",
  "turdingizmu",
  "turdingiz",
  "turdigiz",
  "turding",
  "turdum",
  "turduq",
  "turdi",
  "turdu",
  "tur",
  "digizmu",
  "dingizmu",
  "dingiz",
  "digiz",
  "gizmu",
  "izmu",
  "watimen",
  "watisen",
  "watisiz",
  "watidu",
  "watimiz",
  "watidilar",
  "uwatimen",
  "uwatidu",
  "iwatimen",
  "iwatidu",
  "ding",
  "dum",
  "duq",
  "di",
  "du",
  "musiler",
  "musiz",
  "misiz",
  "musen",
  "siler",
  "siz",
  "sen",
  "men",
  "miz",
  "imen",
  "isen",
  "isiz",
  "idu",
  "imiz",
  "idilar",
  "ayli",
  "eyli",
  "ay",
  "ey",
  "ingiz",
  "ing",
  "sun",
  "lar",
  "ler",
  "ning",
  "ni",
  "gha",
  "qa",
  "da",
  "de",
  "din",
  "tin",
  "mu",
  "chu",
  "ghu",
  "ken",
  "im",
];

const FAMILIES = [
  ["mu", "musiz", "misiz", "musen", "musiler"],
  ["siz", "sen", "men", "siler", "miz"],
  ["ding", "dingiz", "dingizmu", "digizmu", "digiz", "gizmu", "izmu"],
  ["di", "du", "dum", "duq", "ding", "dingiz"],
  ["turding", "turdingiz", "turdingizmu", "turdigizmu", "turdigiz", "turdi", "turdu", "turdum", "turduq"],
  ["watimen", "watisen", "watisiz", "watidu", "watimiz", "watidilar"],
  ["imen", "isen", "isiz", "idu", "imiz", "idilar"],
  ["lar", "ler", "ning", "ni", "gha", "qa", "da", "de", "din", "tin"],
  ["chu", "ghu", "ken", "mu"],
];

export class MorphologyExpander {
  constructor(private trie: PrefixTrie) {}

  expansions(partial: string, limit: number): Array<[string, number]> {
    if (limit <= 0) return [];
    const key = lookupKey(partial);
    if (key.length < MIN_STEM) return [];

    const ranked: Array<[string, number]> = [];
    const seen = new Set<string>();

    const consider = (word: string, score: number) => {
      const w = lookupKey(word);
      if (w === key) return;
      if (!(w.startsWith(key) || this.isRelatedAlternate(key, w))) return;
      if (seen.has(w)) return;
      seen.add(w);
      ranked.push([w, score]);
    };

    let stemEnd = key.length;
    let stemsFound = 0;
    while (stemEnd >= MIN_STEM && stemsFound < 4) {
      const stem = key.slice(0, stemEnd);
      if (this.trie.contains(stem)) {
        stemsFound++;
        const stemFreq = Math.max(1, this.trie.frequency(stem));
        this.expand(stem, key.slice(stemEnd), stemFreq, consider);
      }
      stemEnd--;
    }

    if (stemsFound === 0) {
      stemEnd = key.length - 1;
      while (stemEnd >= MIN_STEM) {
        const stem = key.slice(0, stemEnd);
        if (this.trie.contains(stem)) {
          const stemFreq = Math.max(1, this.trie.frequency(stem));
          this.expand(stem, key.slice(stemEnd), stemFreq, consider);
          break;
        }
        stemEnd--;
      }
    }

    ranked.sort((a, b) => b[1] - a[1] || a[0].length - b[0].length);
    return ranked.slice(0, limit);
  }

  private expand(
    stem: string,
    remainder: string,
    stemFreq: number,
    consider: (word: string, score: number) => void,
  ): void {
    for (const suffix of SUFFIXES) {
      const form = stem + suffix;
      if (!remainder) {
        consider(form, stemFreq / 4 - suffix.length * 10);
      } else if (suffix.startsWith(remainder)) {
        consider(form, stemFreq / 2 - (suffix.length - remainder.length) * 5);
      }
    }
    if (remainder) {
      for (const family of FAMILIES) {
        const matched = family.some(
          (s) => s === remainder || s.startsWith(remainder) || remainder.startsWith(s),
        );
        if (!matched) continue;
        for (const alt of family) {
          if (alt === remainder) continue;
          const boost = family.includes(remainder) ? 200 : 0;
          consider(stem + alt, stemFreq / 3 - Math.abs(alt.length - remainder.length) * 8 + boost);
        }
      }
    }
  }

  private isRelatedAlternate(typed: string, candidate: string): boolean {
    if (candidate.startsWith(typed)) return true;
    let stemEnd = typed.length;
    while (stemEnd >= MIN_STEM) {
      const stem = typed.slice(0, stemEnd);
      if (candidate.startsWith(stem) && this.trie.contains(stem)) {
        const typedRem = typed.slice(stemEnd);
        const candRem = candidate.slice(stem.length);
        for (const family of FAMILIES) {
          if (family.includes(typedRem) && family.includes(candRem)) return true;
        }
      }
      stemEnd--;
    }
    return false;
  }
}
