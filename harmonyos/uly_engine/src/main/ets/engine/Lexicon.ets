import { PrefixTrie } from './Trie';
import { SpellChecker } from './Spell';
import { NGramPredictor } from './NGram';
import { lookupKey } from './Uly';

export interface LexiconMeta {
  version: string;
  script: string;
  wordCount: number;
  correctionCount: number;
  bigramCount: number;
  sources: string[];
  notes?: string;
}

export interface LexiconBundle {
  meta: LexiconMeta;
  words: Array<[string, number]>;
  corrections: Record<string, string>;
  bigrams: Array<[string, string, number]>;
}

export class LexiconStore {
  readonly meta: LexiconMeta;
  readonly trie: PrefixTrie;
  readonly spellChecker: SpellChecker;
  readonly predictor: NGramPredictor;
  readonly vocabulary: string[];

  constructor(bundle: LexiconBundle) {
    this.meta = bundle.meta;
    const trie = new PrefixTrie();
    const freqs: Map<string, number> = new Map();
    const vocab: string[] = [];
    for (let i = 0; i < bundle.words.length; i++) {
      const w = bundle.words[i][0];
      const f = bundle.words[i][1];
      const key = lookupKey(w);
      freqs.set(key, f);
      vocab.push(key);
      trie.insert(key, f);
    }
    this.trie = trie;
    this.vocabulary = vocab;
    this.spellChecker = new SpellChecker(trie, vocab, bundle.corrections);
    const unigrams: Array<[string, number]> = [];
    freqs.forEach((f, w) => {
      unigrams.push([w, f]);
    });
    this.predictor = new NGramPredictor(bundle.bigrams, unigrams);
  }

  static fromJson(text: string): LexiconStore {
    const bundle = JSON.parse(text) as LexiconBundle;
    return new LexiconStore(bundle);
  }
}
