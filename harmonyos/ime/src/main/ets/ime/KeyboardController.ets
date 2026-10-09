import { common } from '@kit.AbilityKit';
import { inputMethodEngine } from '@kit.IMEKit';
import { LexiconStore, SuggestionEngine, SuggestionResult, isWordChar, lookupKey } from 'uly_engine';
import { util } from '@kit.ArkTS';

/**
 * IME controller — performance rules:
 * - Lexicon JSON parse stays off the first paint path (async onCreate).
 * - suggestFromBefore is cheap to call; engine caches identical queries.
 * - privateField disables learning / candidates (password-style editors).
 */
export class KeyboardController {
  private engine: SuggestionEngine | null = null;
  private panelPort: inputMethodEngine.InputMethodAbility | null = null;
  private privateField: boolean = false;
  private suggestGen: number = 0;
  private debounceTimer: number = -1;

  async onCreate(context: common.BaseContext): Promise<void> {
    try {
      const rm = context.resourceManager;
      const raw = await rm.getRawFileContent('lexicon.json');
      const text = util.TextDecoder.create('utf-8').decodeWithStream(raw);
      const store = LexiconStore.fromJson(text);
      this.engine = new SuggestionEngine(store);
    } catch (_e) {
      this.engine = null;
    }
    this.panelPort = null;
  }

  onDestroy(): void {
    if (this.debounceTimer >= 0) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = -1;
    }
    this.engine = null;
    this.panelPort = null;
  }

  setPrivateField(isPrivate: boolean): void {
    this.privateField = isPrivate;
    if (isPrivate) {
      this.engine?.invalidateCache();
    }
  }

  getEngine(): SuggestionEngine | null {
    return this.engine;
  }

  /**
   * Debounced suggest for key storms. Callback receives candidates for the panel.
   */
  scheduleSuggest(before: string, limit: number, onResult: (result: SuggestionResult) => void): void {
    if (this.debounceTimer >= 0) {
      clearTimeout(this.debounceTimer);
    }
    const gen = ++this.suggestGen;
    this.debounceTimer = setTimeout(() => {
      this.debounceTimer = -1;
      if (gen !== this.suggestGen) {
        return;
      }
      onResult(this.suggestDetailed(before, limit));
    }, 16) as number;
  }

  suggestDetailed(before: string, limit: number = 8): SuggestionResult {
    if (this.privateField || !this.engine) {
      return { candidates: [], isMisspelled: false, mode: 'empty' };
    }
    const clipped = before.length > 64 ? before.substring(before.length - 64) : before;
    const { partial, previous } = KeyboardController.contextWords(clipped);
    return this.engine.suggest(partial, previous, limit);
  }

  suggestFromBefore(before: string, limit: number = 8): string[] {
    return this.suggestDetailed(before, limit).candidates;
  }

  learnSelection(word: string): void {
    if (this.privateField) {
      return;
    }
    this.engine?.learnSelection(word);
  }

  static contextWords(before: string): { partial: string; previous: string | null } {
    let i = before.length;
    while (i > 0 && isWordChar(before.charAt(i - 1))) {
      i--;
    }
    const partial = before.substring(i);

    let j = i;
    while (j > 0 && /\s/.test(before.charAt(j - 1))) {
      j--;
    }
    let k = j;
    while (k > 0 && isWordChar(before.charAt(k - 1))) {
      k--;
    }
    const previous = k < j ? lookupKey(before.substring(k, j)) : null;
    return { partial, previous };
  }
}
