import { lookupKey } from './Uly';
import { LexiconStore } from './Lexicon';
import { PersonalDictionary } from './Personal';
import { MorphologyExpander } from './Morph';

export type SuggestionMode = 'completion' | 'nextWord' | 'correction' | 'empty';

export interface SuggestionResult {
  candidates: string[];
  isMisspelled: boolean;
  mode: SuggestionMode;
}

function unique(items: string[], limit: number): string[] {
  const seen: Set<string> = new Set();
  const out: string[] = [];
  for (let i = 0; i < items.length; i++) {
    const k = lookupKey(items[i]);
    if (seen.has(k)) {
      continue;
    }
    seen.add(k);
    out.push(k);
    if (out.length >= limit) {
      break;
    }
  }
  return out;
}

export class SuggestionEngine {
  private store: LexiconStore;
  private personal: PersonalDictionary;
  private morphology: MorphologyExpander;
  private cacheKey: string = '';
  private cacheValue: SuggestionResult | null = null;

  constructor(store: LexiconStore, personal: PersonalDictionary = new PersonalDictionary()) {
    this.store = store;
    this.personal = personal;
    this.morphology = new MorphologyExpander(store.trie);
  }

  get meta() {
    return this.store.meta;
  }

  suggest(
    partial: string,
    previousWord: string | null,
    limit: number = 3,
    sentenceStart: boolean = false
  ): SuggestionResult {
    const p = lookupKey(partial);
    const prevKey = previousWord ? lookupKey(previousWord) : '';
    const key = `${p}|${prevKey}|${sentenceStart}|${limit}`;
    if (p && this.cacheValue && this.cacheKey === key) {
      return this.cacheValue;
    }
    const result = this.suggestUncached(p, previousWord ? prevKey : null, limit, sentenceStart);
    if (p) {
      this.cacheKey = key;
      this.cacheValue = result;
    }
    return result;
  }

  invalidateCache(): void {
    this.cacheKey = '';
    this.cacheValue = null;
  }

  private suggestUncached(
    p: string,
    previousWord: string | null,
    limit: number,
    sentenceStart: boolean
  ): SuggestionResult {
    if (!p) {
      const ranked: Array<[string, number]> = [];
      if (sentenceStart || !previousWord) {
        const openers = this.personal.rankedOpeners(limit * 2);
        for (let i = 0; i < openers.length; i++) {
          ranked.push(openers[i]);
        }
        const top = this.personal.wordScoresEntries(limit);
        for (let i = 0; i < top.length; i++) {
          ranked.push([top[i][0], top[i][1] + 40000]);
        }
      } else {
        const next = this.personal.nextWords(previousWord, limit);
        for (let i = 0; i < next.length; i++) {
          ranked.push(next[i]);
        }
      }
      const staticNext = this.store.predictor.nextWords(sentenceStart ? null : previousWord, limit * 2);
      for (let i = 0; i < staticNext.length; i++) {
        ranked.push([staticNext[i], 10000 - i]);
      }
      ranked.sort((a, b) => b[1] - a[1]);
      const words = unique(ranked.map((c) => c[0]), limit);
      return {
        candidates: words,
        isMisspelled: false,
        mode: words.length ? 'nextWord' : 'empty',
      };
    }

    let comps = this.personal.rankedPrefix(p, limit).concat(this.store.trie.completions(p, limit * 3));
    if (comps.length < limit) {
      comps = comps.concat(this.morphology.expansions(p, limit * 2));
    }
    comps.sort((a, b) => b[1] - a[1]);
    const words = unique(comps.map((c) => c[0]), limit);

    if (words.length) {
      const exact = this.store.trie.contains(p) || this.personal.contains(p);
      return {
        candidates: words,
        isMisspelled: !exact && p.length > 2,
        mode: 'completion',
      };
    }

    if (p.length >= 3) {
      const corr = this.store.spellChecker.suggestions(p, limit);
      if (corr.length) {
        return { candidates: corr, isMisspelled: true, mode: 'correction' };
      }
    }

    return {
      candidates: [],
      isMisspelled: !this.store.trie.contains(p),
      mode: 'empty',
    };
  }

  learnSelection(word: string, previous: string | null = null, sentenceStart: boolean = false): void {
    this.personal.learn(word, 6);
    if (sentenceStart || !previous) {
      this.personal.learnOpener(word, 22);
    } else {
      this.personal.learnBigram(previous, word, 4);
    }
    this.invalidateCache();
  }

  learnCommittedWord(word: string, previous: string | null, sentenceStart: boolean = false): void {
    const key = lookupKey(word);
    if (key.length < 2) {
      return;
    }
    let boost = 12;
    if (this.personal.contains(key)) {
      boost = 2;
    } else if (this.store.trie.contains(key)) {
      boost = 1;
    }
    this.personal.learn(key, boost);
    if (sentenceStart || !previous) {
      this.personal.learnOpener(key, sentenceStart ? 24 : 14);
    } else {
      this.personal.learnBigram(previous, key, boost >= 12 ? 4 : 2);
    }
    this.invalidateCache();
  }

  addToDictionary(word: string): void {
    this.personal.add(word);
    this.invalidateCache();
  }

  clearPersonalDictionary(): void {
    this.personal.clear();
    this.invalidateCache();
  }

  isKnown(word: string): boolean {
    return this.store.trie.contains(word) || this.personal.contains(word);
  }
}
