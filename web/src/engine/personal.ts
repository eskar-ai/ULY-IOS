import { lookupKey } from "./uly";

const STORAGE_KEY = "uyghurlatin.personalWords";

export class PersonalDictionary {
  private words: Record<string, number> = {};

  constructor() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) this.words = JSON.parse(raw) as Record<string, number>;
    } catch {
      this.words = {};
    }
  }

  learn(word: string, boost = 1): void {
    const key = lookupKey(word);
    if (!key) return;
    this.words[key] = (this.words[key] ?? 0) + boost;
    this.persist();
  }

  add(word: string): void {
    this.learn(word, 100);
  }

  clear(): void {
    this.words = {};
    this.persist();
  }

  contains(word: string): boolean {
    return lookupKey(word) in this.words;
  }

  rankedPrefix(prefix: string, limit: number): Array<[string, number]> {
    const p = lookupKey(prefix);
    if (!p) return [];
    return Object.entries(this.words)
      .filter(([w]) => w.startsWith(p))
      .map(([w, f]) => [w, f + 100_000] as [string, number])
      .sort((a, b) => b[1] - a[1])
      .slice(0, limit);
  }

  private persist(): void {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(this.words));
    } catch {
      /* ignore quota */
    }
  }
}
