import { lookupKey } from './Uly';
import { PrefixTrie } from './Trie';

const MIN_STEM: number = 3;

const SUFFIXES: string[] = [
  'turdigizmu', 'turdingizmu', 'turdingiz', 'turdigiz', 'turding',
  'turdum', 'turduq', 'turdi', 'turdu', 'tur',
  'digizmu', 'dingizmu', 'dingiz', 'digiz', 'gizmu', 'izmu',
  'watimen', 'watisen', 'watisiz', 'watidu', 'watimiz',
  'ding', 'dum', 'duq', 'di', 'du',
  'musiler', 'musiz', 'misiz', 'musen',
  'siler', 'siz', 'sen', 'men', 'miz',
  'imen', 'isen', 'isiz', 'idu', 'imiz',
  'lar', 'ler', 'ning', 'ni', 'gha', 'qa', 'da', 'de', 'din', 'tin',
  'mu', 'chu', 'ghu', 'ken', 'im',
];

const FAMILIES: string[][] = [
  ['mu', 'musiz', 'misiz', 'musen', 'musiler'],
  ['siz', 'sen', 'men', 'siler', 'miz'],
  ['ding', 'dingiz', 'dingizmu', 'digizmu', 'digiz', 'gizmu', 'izmu'],
  ['turding', 'turdingiz', 'turdingizmu', 'turdigizmu', 'turdigiz', 'turdi', 'turdu', 'turdum'],
  ['watimen', 'watisen', 'watisiz', 'watidu', 'watimiz'],
  ['imen', 'isen', 'isiz', 'idu', 'imiz'],
  ['lar', 'ler', 'ning', 'ni', 'gha', 'qa', 'da', 'de', 'din', 'tin'],
  ['chu', 'ghu', 'ken', 'mu'],
];

export class MorphologyExpander {
  private trie: PrefixTrie;

  constructor(trie: PrefixTrie) {
    this.trie = trie;
  }

  expansions(partial: string, limit: number): Array<[string, number]> {
    if (limit <= 0) {
      return [];
    }
    const key = lookupKey(partial);
    if (key.length < MIN_STEM) {
      return [];
    }
    const ranked: Array<[string, number]> = [];
    const seen: Set<string> = new Set();

    const consider = (word: string, score: number): void => {
      const w = lookupKey(word);
      if (w === key) {
        return;
      }
      if (!(w.startsWith(key) || this.isRelatedAlternate(key, w))) {
        return;
      }
      if (seen.has(w)) {
        return;
      }
      seen.add(w);
      ranked.push([w, score]);
    };

    let stemEnd = key.length;
    let stemsFound = 0;
    while (stemEnd >= MIN_STEM && stemsFound < 4) {
      const stem = key.substring(0, stemEnd);
      if (this.trie.contains(stem)) {
        stemsFound++;
        const stemFreq = Math.max(1, this.trie.frequency(stem));
        this.expand(stem, key.substring(stemEnd), stemFreq, consider);
      }
      stemEnd--;
    }

    ranked.sort((a, b) => b[1] - a[1]);
    return ranked.slice(0, limit);
  }

  private expand(
    stem: string,
    remainder: string,
    stemFreq: number,
    consider: (word: string, score: number) => void
  ): void {
    for (let i = 0; i < SUFFIXES.length; i++) {
      const suffix = SUFFIXES[i];
      const form = stem + suffix;
      if (!remainder) {
        consider(form, stemFreq / 4 - suffix.length * 10);
      } else if (suffix.startsWith(remainder)) {
        consider(form, stemFreq / 2 - (suffix.length - remainder.length) * 5);
      }
    }
    if (remainder) {
      for (let f = 0; f < FAMILIES.length; f++) {
        const family = FAMILIES[f];
        let matched = false;
        for (let j = 0; j < family.length; j++) {
          const s = family[j];
          if (s === remainder || s.startsWith(remainder) || remainder.startsWith(s)) {
            matched = true;
            break;
          }
        }
        if (!matched) {
          continue;
        }
        for (let j = 0; j < family.length; j++) {
          const alt = family[j];
          if (alt === remainder) {
            continue;
          }
          consider(stem + alt, stemFreq / 3 - Math.abs(alt.length - remainder.length) * 8);
        }
      }
    }
  }

  private isRelatedAlternate(typed: string, candidate: string): boolean {
    if (candidate.startsWith(typed)) {
      return true;
    }
    let stemEnd = typed.length;
    while (stemEnd >= MIN_STEM) {
      const stem = typed.substring(0, stemEnd);
      if (candidate.startsWith(stem) && this.trie.contains(stem)) {
        const typedRem = typed.substring(stemEnd);
        const candRem = candidate.substring(stem.length);
        for (let f = 0; f < FAMILIES.length; f++) {
          const family = FAMILIES[f];
          if (family.indexOf(typedRem) >= 0 && family.indexOf(candRem) >= 0) {
            return true;
          }
        }
      }
      stemEnd--;
    }
    return false;
  }
}
