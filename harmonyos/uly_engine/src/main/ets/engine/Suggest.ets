import { lookupKey } from './Uly';
import { LexiconStore } from './Lexicon';
import { PersonalDictionary } from './Personal';

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
  private personal: PersonalDictionary = new PersonalDictionary();

  constructor(store: LexiconStore) {
    this.store = store;
  }

  get meta() {
    return this.store.meta;
  }

  suggest(partial: string, previousWord: string | null, limit: number = 3): SuggestionResult {
    const p = lookupKey(partial);
    if (!p) {
      const next = this.store.predictor.nextWords(previousWord, limit);
      return {
        candidates: next,
        isMisspelled: false,
        mode: next.length ? 'nextWord' : 'empty',
      };
    }

    const personalHits = this.personal.rankedPrefix(p, limit);
    const trieHits = this.store.trie.completions(p, limit * 3);
    const comps = personalHits.concat(trieHits);
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

    const corr = this.store.spellChecker.suggestions(p, limit);
    if (corr.length) {
      return { candidates: corr, isMisspelled: true, mode: 'correction' };
    }

    return {
      candidates: [],
      isMisspelled: !this.store.trie.contains(p),
      mode: 'empty',
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
