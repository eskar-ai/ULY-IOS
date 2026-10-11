import { Want } from '@kit.AbilityKit';
import { InputMethodExtensionAbility } from '@kit.IMEKit';
import { KeyboardController } from './KeyboardController';

/**
 * HarmonyOS NEXT Input Method Extension entry.
 * Open the project in DevEco Studio to link against the device IMEKit SDK.
 */
export default class UlyInputMethodAbility extends InputMethodExtensionAbility {
  private keyboardController: KeyboardController = new KeyboardController();

  onCreate(want: Want): void {
    this.keyboardController.onCreate(this.context);
  }

  onDestroy(): void {
    this.keyboardController.onDestroy();
  }
}
