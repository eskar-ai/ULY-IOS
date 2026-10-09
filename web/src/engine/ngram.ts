import { lookupKey } from "./uly";

export class NGramPredictor {
  private bigrams = new Map<string, Array<[string, number]>>();
  private unigrams: Array<[string, number]> = [];

  constructor(bigramTuples: Array<[string, string, number]>, unigrams: Array<[string, number]>) {
    const map = new Map<string, Array<[string, number]>>();
    for (const [a, b, c] of bigramTuples) {
      const key = lookupKey(a);
      const next = lookupKey(b);
      const list = map.get(key) ?? [];
      list.push([next, c]);
      map.set(key, list);
    }
    for (const [k, list] of map) {
      list.sort((x, y) => y[1] - x[1]);
      this.bigrams.set(k, list);
    }
    this.unigrams = [...unigrams].sort((a, b) => b[1] - a[1]);
  }

  nextWords(previous: string | null | undefined, limit = 6): string[] {
    if (previous) {
      const key = lookupKey(previous);
      const list = this.bigrams.get(key);
      if (list?.length) return list.slice(0, limit).map(([w]) => w);
    }
    return this.unigrams.slice(0, limit).map(([w]) => w);
  }
}
