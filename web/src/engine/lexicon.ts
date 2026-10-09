import { PrefixTrie } from "./trie";
import { SpellChecker } from "./spell";
import { NGramPredictor } from "./ngram";
import { lookupKey } from "./uly";

export type LexiconMeta = {
  version: string;
  script: string;
  wordCount: number;
  correctionCount: number;
  bigramCount: number;
  sources: string[];
  notes?: string;
};

export type LexiconBundle = {
  meta: LexiconMeta;
  words: Array<[string, number]>;
  corrections: Record<string, string>;
  bigrams: Array<[string, string, number]>;
};

export class LexiconStore {
  readonly meta: LexiconMeta;
  readonly trie: PrefixTrie;
  readonly spellChecker: SpellChecker;
  readonly predictor: NGramPredictor;
  readonly vocabulary: string[];

  constructor(bundle: LexiconBundle) {
    this.meta = bundle.meta;
    const trie = new PrefixTrie();
    const freqs = new Map<string, number>();
    const vocab: string[] = [];
    for (const [w, f] of bundle.words) {
      const key = lookupKey(w);
      freqs.set(key, f);
      vocab.push(key);
      trie.insert(key, f);
    }
    this.trie = trie;
    this.vocabulary = vocab;
    this.spellChecker = new SpellChecker(trie, vocab, bundle.corrections);
    const unigrams = [...freqs.entries()] as Array<[string, number]>;
    this.predictor = new NGramPredictor(bundle.bigrams, unigrams);
  }

  static async load(url = "/data/lexicon.json"): Promise<LexiconStore> {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`Failed to load lexicon: ${res.status}`);
    const bundle = (await res.json()) as LexiconBundle;
    return new LexiconStore(bundle);
  }
}
