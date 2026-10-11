import { lookupKey } from './Uly';

const SEP: string = '\u001f';

export class PersonalDictionary {
  private words: Map<string, number> = new Map();
  private bigrams: Map<string, number> = new Map();
  private openers: Map<string, number> = new Map();

  learn(word: string, boost: number = 1): void {
    const key = lookupKey(word);
    if (!key) {
      return;
    }
    this.softDecay();
    this.words.set(key, (this.words.get(key) ?? 0) + boost);
  }

  add(word: string): void {
    this.learn(word, 100);
  }

  learnBigram(previous: string, word: string, boost: number = 1): void {
    const a = lookupKey(previous);
    const b = lookupKey(word);
    if (!a || !b) {
      return;
    }
    const key = `${a}${SEP}${b}`;
    this.bigrams.set(key, (this.bigrams.get(key) ?? 0) + boost);
  }

  learnOpener(word: string, boost: number = 18): void {
    const key = lookupKey(word);
    if (key.length < 2) {
      return;
    }
    this.openers.set(key, (this.openers.get(key) ?? 0) + boost);
    this.words.set(key, (this.words.get(key) ?? 0) + Math.max(1, Math.floor(boost / 4)));
  }

  rankedOpeners(limit: number): Array<[string, number]> {
    if (limit <= 0) {
      return [];
    }
    const out: Array<[string, number]> = [];
    this.openers.forEach((f, w) => {
      out.push([w, f + 120000]);
    });
    out.sort((a, b) => b[1] - a[1]);
    return out.slice(0, limit);
  }

  nextWords(after: string | null, limit: number): Array<[string, number]> {
    if (!after || limit <= 0) {
      return [];
    }
    const prev = lookupKey(after);
    const needle = `${prev}${SEP}`;
    const out: Array<[string, number]> = [];
    this.bigrams.forEach((c, k) => {
      if (k.startsWith(needle)) {
        const next = k.substring(needle.length);
        if (next.length > 0) {
          out.push([next, c + 50000]);
        }
      }
    });
    out.sort((a, b) => b[1] - a[1]);
    return out.slice(0, limit);
  }

  clear(): void {
    this.words.clear();
    this.bigrams.clear();
    this.openers.clear();
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

  wordScoresEntries(limit: number): Array<[string, number]> {
    const out: Array<[string, number]> = [];
    this.words.forEach((f, w) => {
      out.push([w, f]);
    });
    out.sort((a, b) => b[1] - a[1]);
    return out.slice(0, limit);
  }

  private softDecay(): void {
    if (this.words.size <= 400) {
      return;
    }
    const keys: string[] = [];
    this.words.forEach((_f, w) => {
      keys.push(w);
    });
    for (let i = 0; i < keys.length; i++) {
      const k = keys[i];
      const v = this.words.get(k) ?? 0;
      if (v > 0 && v < 20) {
        const next = v - 1;
        if (next <= 0) {
          this.words.delete(k);
        } else {
          this.words.set(k, next);
        }
      }
    }
  }
}
