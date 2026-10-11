import UIKit

/// `UIInputView` that reports a real intrinsic height so iOS honors custom keyboard sizing.
/// A bare height constraint alone is often ignored; `allowsSelfSizing` + intrinsic size works.
final class SelfSizingInputView: UIInputView {
    var preferredHeight: CGFloat = 292 {
        didSet {
            guard abs(oldValue - preferredHeight) > 0.5 else { return }
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: preferredHeight)
    }
    // Never resize `bounds` here: the host owns this view's frame, and changing bounds
    // re-centers the content, pushing keys off the bottom of the keyboard.
}
