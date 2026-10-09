import { describe, it, expect } from '@ohos/hypium';
import { abilityDelegatorRegistry } from '@kit.TestKit';

/**
 * UI / ability smoke tests — run from DevEco:
 *   Run → Tests → ohosTest
 */
export default function hostAbilityTests() {
  describe('HostEntry', () => {
    it('abilityDelegator_isAvailable', 0, () => {
      const delegator = abilityDelegatorRegistry.getAbilityDelegator();
      expect(delegator !== null).assertTrue();
    });
  });
}
