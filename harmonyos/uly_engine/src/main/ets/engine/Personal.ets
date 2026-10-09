import { lookupKey } from './Uly';

export class PersonalDictionary {
  private words: Map<string, number> = new Map();

  learn(word: string, boost: number = 1): void {
    const key = lookupKey(word);
    if (!key) {
      return;
    }
    this.words.set(key, (this.words.get(key) ?? 0) + boost);
  }

  add(word: string): void {
    this.learn(word, 100);
  }

  clear(): void {
    this.words.clear();
  }

  contains(word: string): boolean {
    return this.words.has(lookupKey(word));
  }

  rankedPrefix(prefix: string, limit: number): Array<[string, number]> {
    const p = lookupKey(prefix);
    if (!p) {
      return [];
    }
    const out: Array<[string, number]> = [];
    this.words.forEach((f, w) => {
      if (w.startsWith(p)) {
        out.push([w, f + 100000]);
      }
    });
    out.sort((a, b) => b[1] - a[1]);
    return out.slice(0, limit);
  }
}
