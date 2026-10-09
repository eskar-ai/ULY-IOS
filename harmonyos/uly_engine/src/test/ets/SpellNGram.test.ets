import { describe, it, expect } from '@ohos/hypium';
import { PrefixTrie, SpellChecker, NGramPredictor, PersonalDictionary } from 'uly_engine';

export default function spellNGramTests() {
  describe('uly_engine_spell_ngram', () => {
    it('spellChecker_usesCorrectionMap', 0, () => {
      const trie = new PrefixTrie();
      trie.insert('uyghur', 100);
      trie.insert('aq', 90);
      const spell = new SpellChecker(trie, ['uyghur', 'aq'], { uygur: 'uyghur' });
      expect(spell.isCorrect('uyghur')).assertTrue();
      expect(spell.isCorrect('uygur')).assertFalse();
      const hits = spell.suggestions('uygur', 3);
      expect(hits.length > 0).assertTrue();
      expect(hits[0]).assertEqual('uyghur');
    });

    it('ngram_prefersBigramThenUnigram', 0, () => {
      const predictor = new NGramPredictor(
        [['bügün', 'uyghur', 9], ['bügün', 'aq', 2]],
        [['aq', 100], ['uyghur', 50]],
      );
      const next = predictor.nextWords('bügün', 2);
      expect(next[0]).assertEqual('uyghur');
      const fallback = predictor.nextWords(null, 2);
      expect(fallback[0]).assertEqual('aq');
    });

    it('personalDictionary_learnClear', 0, () => {
      const personal = new PersonalDictionary();
      personal.learn('uyghurlar', 5);
      expect(personal.contains('Uyghurlar')).assertTrue();
      const ranked = personal.rankedPrefix('uygh', 5);
      expect(ranked.length > 0).assertTrue();
      personal.clear();
      expect(personal.contains('uyghurlar')).assertFalse();
    });
  });
}
