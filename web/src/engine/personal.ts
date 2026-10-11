import { lookupKey } from "./uly";

const WORDS_KEY = "uyghurlatin.personalWords";
const BIGRAMS_KEY = "uyghurlatin.personalBigrams";
const OPENERS_KEY = "uyghurlatin.personalOpeners";
const SEP = "\u001f";

function loadMap(key: string): Record<string, number> {
  try {
    const raw = localStorage.getItem(key);
    if (raw) return JSON.parse(raw) as Record<string, number>;
  } catch {
    /* ignore */
  }
  return {};
}

function saveMap(key: string, map: Record<string, number>): void {
  try {
    localStorage.setItem(key, JSON.stringify(map));
  } catch {
    /* ignore quota */
  }
}

export class PersonalDictionary {
  private words: Record<string, number> = loadMap(WORDS_KEY);
  private bigrams: Record<string, number> = loadMap(BIGRAMS_KEY);
  private openers: Record<string, number> = loadMap(OPENERS_KEY);

  learn(word: string, boost = 1): void {
    const key = lookupKey(word);
    if (!key) return;
    this.softDecay();
    this.words[key] = (this.words[key] ?? 0) + boost;
    this.persist();
  }

  add(word: string): void {
    this.learn(word, 100);
  }

  learnBigram(previous: string, word: string, boost = 1): void {
    const a = lookupKey(previous);
    const b = lookupKey(word);
    if (!a || !b) return;
    const key = `${a}${SEP}${b}`;
    this.bigrams[key] = (this.bigrams[key] ?? 0) + boost;
    this.persist();
  }

  learnOpener(word: string, boost = 18): void {
    const key = lookupKey(word);
    if (key.length < 2) return;
    this.openers[key] = (this.openers[key] ?? 0) + boost;
    this.words[key] = (this.words[key] ?? 0) + Math.max(1, Math.floor(boost / 4));
    this.persist();
  }

  rankedOpeners(limit: number): Array<[string, number]> {
    if (limit <= 0) return [];
    return Object.entries(this.openers)
      .map(([w, f]) => [w, f + 120_000] as [string, number])
      .sort((a, b) => b[1] - a[1])
      .slice(0, limit);
  }

  nextWords(after: string | null | undefined, limit: number): Array<[string, number]> {
    if (!after || limit <= 0) return [];
    const prev = lookupKey(after);
    const needle = `${prev}${SEP}`;
    return Object.entries(this.bigrams)
      .filter(([k]) => k.startsWith(needle))
      .map(([k, c]) => [k.slice(needle.length), c + 50_000] as [string, number])
      .filter(([w]) => w.length > 0)
      .sort((a, b) => b[1] - a[1])
      .slice(0, limit);
  }

  clear(): void {
    this.words = {};
    this.bigrams = {};
    this.openers = {};
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

  get wordScores(): Record<string, number> {
    return { ...this.words };
  }

  private softDecay(): void {
    const keys = Object.keys(this.words);
    if (keys.length <= 400) return;
    for (const k of keys) {
      const v = this.words[k] ?? 0;
      if (v > 0 && v < 20) {
        const next = v - 1;
        if (next <= 0) delete this.words[k];
        else this.words[k] = next;
      }
    }
  }

  private persist(): void {
    saveMap(WORDS_KEY, this.words);
    saveMap(BIGRAMS_KEY, this.bigrams);
    saveMap(OPENERS_KEY, this.openers);
  }
}
