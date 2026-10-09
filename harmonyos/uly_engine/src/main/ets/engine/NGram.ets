import { lookupKey } from './Uly';

export class NGramPredictor {
  private bigrams: Map<string, Array<[string, number]>> = new Map();
  private unigrams: Array<[string, number]> = [];

  constructor(bigramTuples: Array<[string, string, number]>, unigrams: Array<[string, number]>) {
    const map: Map<string, Array<[string, number]>> = new Map();
    for (let i = 0; i < bigramTuples.length; i++) {
      const a = lookupKey(bigramTuples[i][0]);
      const b = lookupKey(bigramTuples[i][1]);
      const c = bigramTuples[i][2];
      let list = map.get(a);
      if (!list) {
        list = [];
        map.set(a, list);
      }
      list.push([b, c]);
    }
    map.forEach((list, k) => {
      list.sort((x, y) => y[1] - x[1]);
      this.bigrams.set(k, list);
    });
    this.unigrams = unigrams.slice().sort((a, b) => b[1] - a[1]);
  }

  nextWords(previous: string | null | undefined, limit: number = 6): string[] {
    if (previous) {
      const key = lookupKey(previous);
      const list = this.bigrams.get(key);
      if (list && list.length) {
        return list.slice(0, limit).map((p) => p[0]);
      }
    }
    return this.unigrams.slice(0, limit).map((p) => p[0]);
  }
}
