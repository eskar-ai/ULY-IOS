import { lookupKey } from "./uly";
import type { LexiconStore } from "./lexicon";
import { PersonalDictionary } from "./personal";
import { MorphologyExpander } from "./morph";

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
  private morphology: MorphologyExpander;

  constructor(private store: LexiconStore) {
    this.morphology = new MorphologyExpander(store.trie);
  }

  get meta() {
    return this.store.meta;
  }

  suggest(
    partial: string,
    previousWord: string | null,
    limit = 3,
    sentenceStart = false,
  ): SuggestionResult {
    const p = lookupKey(partial);
    if (!p) {
      const ranked: Array<[string, number]> = [];
      if (sentenceStart || !previousWord) {
        ranked.push(...this.personal.rankedOpeners(limit * 2));
        ranked.push(
          ...Object.entries(this.personal.wordScores)
            .sort((a, b) => b[1] - a[1])
            .slice(0, limit)
            .map(([w, f]) => [w, f + 40_000] as [string, number]),
        );
      } else {
        ranked.push(...this.personal.nextWords(previousWord, limit));
      }
      const staticNext = this.store.predictor.nextWords(sentenceStart ? null : previousWord, limit * 2);
      staticNext.forEach((w, idx) => ranked.push([w, 10_000 - idx]));
      ranked.sort((a, b) => b[1] - a[1]);
      const next = unique(
        ranked.map(([w]) => w),
        limit,
      );
      return {
        candidates: next,
        isMisspelled: false,
        mode: next.length ? "nextWord" : "empty",
      };
    }

    let comps: Array<[string, number]> = [
      ...this.personal.rankedPrefix(p, limit),
      ...this.store.trie.completions(p, limit * 3),
    ];
    if (comps.length < limit) {
      comps = [...comps, ...this.morphology.expansions(p, limit * 2)];
    }
    comps.sort((a, b) => b[1] - a[1]);
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

    if (p.length >= 3) {
      const corr = this.store.spellChecker.suggestions(p, limit);
      if (corr.length) {
        const ranked: Array<[string, number]> = [];
        corr.forEach((c, idx) => {
          ranked.push([c, 500_000 - idx * 10]);
          for (const [m, score] of this.morphology.expansions(c, limit)) {
            ranked.push([m, score + 100_000 - idx * 10]);
          }
        });
        ranked.sort((a, b) => b[1] - a[1]);
        const morphWords = unique(
          ranked.map(([w]) => w),
          limit,
        );
        if (morphWords.length) {
          return { candidates: morphWords, isMisspelled: true, mode: "correction" };
        }
      }
    }

    return {
      candidates: [],
      isMisspelled: !this.store.trie.contains(p),
      mode: "empty",
    };
  }

  learnSelection(word: string, previous: string | null = null, sentenceStart = false): void {
    this.personal.learn(word, 6);
    if (sentenceStart || !previous) {
      this.personal.learnOpener(word, 22);
    } else {
      this.personal.learnBigram(previous, word, 4);
    }
  }

  learnCommittedWord(word: string, previous: string | null, sentenceStart = false): void {
    const key = lookupKey(word);
    if (key.length < 2) return;
    let boost = 12;
    if (this.personal.contains(key)) boost = 2;
    else if (this.store.trie.contains(key)) boost = 1;
    this.personal.learn(key, boost);
    if (sentenceStart || !previous) {
      this.personal.learnOpener(key, sentenceStart ? 24 : 14);
    } else {
      this.personal.learnBigram(previous, key, boost >= 12 ? 4 : 2);
    }
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
