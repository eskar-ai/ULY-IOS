import { lookupKey } from "./uly";
import type { LexiconStore } from "./lexicon";
import { PersonalDictionary } from "./personal";

export type SuggestionMode = "completion" | "nextWord" | "correction" | "empty";

export type SuggestionResult = {
  candidates: string[];
  isMisspelled: boolean;
  mode: SuggestionMode;
};

function unique(items: string[], limit: number): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const i of items) {
    const k = lookupKey(i);
    if (seen.has(k)) continue;
    seen.add(k);
    out.push(k);
    if (out.length >= limit) break;
  }
  return out;
}

export class SuggestionEngine {
  private personal = new PersonalDictionary();

  constructor(private store: LexiconStore) {}

  get meta() {
    return this.store.meta;
  }

  suggest(partial: string, previousWord: string | null, limit = 3): SuggestionResult {
    const p = lookupKey(partial);
    if (!p) {
      const next = this.store.predictor.nextWords(previousWord, limit);
      return {
        candidates: next,
        isMisspelled: false,
        mode: next.length ? "nextWord" : "empty",
      };
    }

    const comps = [
      ...this.personal.rankedPrefix(p, limit),
      ...this.store.trie.completions(p, limit * 3),
    ].sort((a, b) => b[1] - a[1]);
    const words = unique(
      comps.map(([w]) => w),
      limit,
    );

    if (words.length) {
      const exact = this.store.trie.contains(p) || this.personal.contains(p);
      return {
        candidates: words,
        isMisspelled: !exact && p.length > 2,
        mode: "completion",
      };
    }

    const corr = this.store.spellChecker.suggestions(p, limit);
    if (corr.length) {
      return { candidates: corr, isMisspelled: true, mode: "correction" };
    }

    return {
      candidates: [],
      isMisspelled: !this.store.trie.contains(p),
      mode: "empty",
    };
  }

  learnSelection(word: string): void {
    this.personal.learn(word, 5);
  }

  addToDictionary(word: string): void {
    this.personal.add(word);
  }

  clearPersonalDictionary(): void {
    this.personal.clear();
  }

  isKnown(word: string): boolean {
    return this.store.trie.contains(word) || this.personal.contains(word);
  }
}
