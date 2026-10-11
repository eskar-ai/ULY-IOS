import { describe, it, expect } from '@ohos/hypium';
import { lookupKey, isWordChar, PrefixTrie, LexiconStore, SuggestionEngine } from 'uly_engine';

export default function ulyEngineTests() {
  describe('uly_engine', () => {
    it('lookupKey_foldsCaseAndAliases', 0, () => {
      expect(lookupKey('ÉlÉm')).assertEqual('ëlëm');
      expect(lookupKey("A\u2019B")).assertEqual("a'b");
    });

    it('isWordChar_acceptsUlyLetters', 0, () => {
      expect(isWordChar('ë')).assertTrue();
      expect(isWordChar("'")).assertTrue();
      expect(isWordChar(' ')).assertFalse();
    });

    it('trie_completionsRankByFrequency', 0, () => {
      const trie = new PrefixTrie();
      trie.insert('uyghur', 10);
      trie.insert('uyghurche', 5);
      const hits = trie.completions('uygh', 5);
      expect(hits.length > 0).assertTrue();
      expect(hits[0][0]).assertEqual('uyghur');
    });

    it('suggest_completesAndCorrects', 0, () => {
      const store = LexiconStore.fromJson(JSON.stringify({
        meta: {
          version: 'test',
          script: 'uly',
          wordCount: 3,
          correctionCount: 1,
          bigramCount: 1,
          sources: ['test'],
        },
        words: [['uyghur', 100], ['uyghurche', 50], ['bugun', 80]],
        corrections: { uygur: 'uyghur' },
        bigrams: [['bugun', 'uyghur', 9]],
      }));
      const engine = new SuggestionEngine(store);
      const completion = engine.suggest('uygh', null, 5);
      expect(completion.mode).assertEqual('completion');
      expect(completion.candidates.indexOf('uyghur') >= 0).assertTrue();

      const next = engine.suggest('', 'bugun', 3);
      expect(next.mode).assertEqual('nextWord');
      expect(next.candidates[0]).assertEqual('uyghur');

      const corr = engine.suggest('uygur', null, 3);
      expect(corr.mode).assertEqual('correction');
      expect(corr.candidates[0]).assertEqual('uyghur');
    });
  });
}
