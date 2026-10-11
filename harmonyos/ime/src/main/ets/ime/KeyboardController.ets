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
    const ctx = KeyboardController.contextWords(clipped);
    return this.engine.suggest(ctx.partial, ctx.previous, limit, ctx.sentenceStart);
  }

  suggestFromBefore(before: string, limit: number = 8): string[] {
    return this.suggestDetailed(before, limit).candidates;
  }

  learnSelection(word: string, before: string = ''): void {
    if (this.privateField) {
      return;
    }
    const ctx = KeyboardController.contextWords(before);
    this.engine?.learnSelection(word, ctx.previous, ctx.sentenceStart);
  }

  learnCommitted(before: string): void {
    if (this.privateField) {
      return;
    }
    const ctx = KeyboardController.contextWords(before);
    if (ctx.partial.length > 0) {
      this.engine?.learnCommittedWord(ctx.partial, ctx.previous, ctx.sentenceStart);
    }
  }

  static contextWords(before: string): { partial: string; previous: string | null; sentenceStart: boolean } {
    let i = before.length;
    while (i > 0 && isWordChar(before.charAt(i - 1))) {
      i--;
    }
    const partial = before.substring(i);

    let boundary = i;
    while (boundary > 0 && /\s/.test(before.charAt(boundary - 1))) {
      boundary--;
    }
    let sentenceStart = boundary === 0;
    if (!sentenceStart) {
      const ch = before.charAt(boundary - 1);
      sentenceStart = ch === '.' || ch === '!' || ch === '?' || ch === '…' ||
        ch === ':' || ch === ';' || ch === '\n';
    }
    if (sentenceStart) {
      return { partial, previous: null, sentenceStart: true };
    }

    let j = i;
    while (j > 0 && /\s/.test(before.charAt(j - 1))) {
      j--;
    }
    let k = j;
    while (k > 0 && isWordChar(before.charAt(k - 1))) {
      k--;
    }
    const previous = k < j ? lookupKey(before.substring(k, j)) : null;
    return { partial, previous, sentenceStart: false };
  }
}
