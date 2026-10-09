import { common } from '@kit.AbilityKit';
import { inputMethodEngine } from '@kit.IMEKit';
import { LexiconStore, SuggestionEngine, isWordChar, lookupKey } from 'uly_engine';
import { util } from '@kit.ArkTS';

/**
 * Loads the bundled lexicon and drives text insert / suggestions.
 * Panel UI lives in pages/KeyboardPanel.ets.
 */
export class KeyboardController {
  private engine: SuggestionEngine | null = null;
  private panelPort: inputMethodEngine.InputMethodAbility | null = null;

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

    // Bind to IME panel when the system attaches the soft keyboard.
    // Full InputMethodAbility wiring is completed in DevEco against IMEKit.
    this.panelPort = null;
  }

  onDestroy(): void {
    this.engine = null;
    this.panelPort = null;
  }

  getEngine(): SuggestionEngine | null {
    return this.engine;
  }

  suggestFromBefore(before: string, limit: number = 8): string[] {
    if (!this.engine) {
      return [];
    }
    const { partial, previous } = KeyboardController.contextWords(before);
    return this.engine.suggest(partial, previous, limit).candidates;
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
