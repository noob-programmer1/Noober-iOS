import UIKit

/// Synthesizes touch events in-process for remote tap/swipe/type.
/// Uses UIApplication's sendEvent API to inject touches directly.
@MainActor
enum TouchSynthesizer {

    // MARK: - Tap

    static func tap(at point: CGPoint) {
        guard let window = targetWindow(for: point) else { return }

        // Find the view at this point for hitTest
        let hitView = window.hitTest(point, with: nil) ?? window

        // Simulate tap via first responder chain
        // Use performSelector to avoid private API at compile time
        let sel = NSSelectorFromString("_firstResponder")
        _ = hitView

        // Dispatch touch down + touch up using UIKit gesture
        let touch = syntheticTouch(at: point, in: window, phase: .began)
        let downEvent = syntheticEvent(with: touch)
        UIApplication.shared.sendEvent(downEvent)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            updateTouch(touch, phase: .ended, at: point)
            let upEvent = syntheticEvent(with: touch)
            UIApplication.shared.sendEvent(upEvent)
        }
    }

    // MARK: - Swipe

    static func swipe(from start: CGPoint, to end: CGPoint, duration: TimeInterval = 0.3) {
        guard let window = targetWindow(for: start) else { return }

        let steps = max(5, Int(duration / 0.016))  // ~60fps
        let dx = (end.x - start.x) / CGFloat(steps)
        let dy = (end.y - start.y) / CGFloat(steps)

        let touch = syntheticTouch(at: start, in: window, phase: .began)
        let downEvent = syntheticEvent(with: touch)
        UIApplication.shared.sendEvent(downEvent)

        for i in 1...steps {
            let delay = duration * Double(i) / Double(steps)
            let point = CGPoint(x: start.x + dx * CGFloat(i), y: start.y + dy * CGFloat(i))
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                updateTouch(touch, phase: .moved, at: point)
                let moveEvent = syntheticEvent(with: touch)
                UIApplication.shared.sendEvent(moveEvent)

                if i == steps {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                        updateTouch(touch, phase: .ended, at: end)
                        let upEvent = syntheticEvent(with: touch)
                        UIApplication.shared.sendEvent(upEvent)
                    }
                }
            }
        }
    }

    // MARK: - Type Text

    static func typeText(_ text: String) {
        // Insert text into the current first responder's text input
        guard let keyWindow = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow }) else { return }

        // Try to find the first responder that accepts text input
        if let responder = findFirstResponder(in: keyWindow) {
            if let textInput = responder as? UITextInput {
                // Insert at current selection
                if let range = textInput.selectedTextRange {
                    textInput.replace(range, withText: text)
                } else {
                    // Fallback: insert at end
                    let end = textInput.endOfDocument
                    if let range = textInput.textRange(from: end, to: end) {
                        textInput.replace(range, withText: text)
                    }
                }
            } else if let textField = responder as? UITextField {
                textField.text = (textField.text ?? "") + text
            } else if let textView = responder as? UITextView {
                textView.text = (textView.text ?? "") + text
            }
        } else {
            // No first responder — try using UIKeyInput on the key window
            // This handles custom text input views
            if let textInput = keyWindow.value(forKey: "firstResponder") as? UIKeyInput {
                for char in text {
                    textInput.insertText(String(char))
                }
            }
        }
    }

    // MARK: - Synthetic Touch (Private API wrappers)

    // We use KVC to set properties on UITouch since direct init is private
    private static func syntheticTouch(at point: CGPoint, in window: UIWindow, phase: UITouch.Phase) -> UITouch {
        let touch = UITouch()
        touch.setValue(point, forKey: "locationInWindow")
        touch.setValue(point, forKey: "previousLocationInWindow")
        touch.setValue(phase.rawValue, forKey: "phase")
        touch.setValue(window, forKey: "window")
        touch.setValue(window.hitTest(point, with: nil) ?? window, forKey: "view")
        touch.setValue(NSNumber(value: ProcessInfo.processInfo.systemUptime), forKey: "timestamp")
        touch.setValue(1, forKey: "tapCount")
        touch.setValue(0, forKey: "_touchIdentifier")
        return touch
    }

    private static func updateTouch(_ touch: UITouch, phase: UITouch.Phase, at point: CGPoint) {
        let prevPoint = touch.value(forKey: "locationInWindow") as? CGPoint ?? point
        touch.setValue(prevPoint, forKey: "previousLocationInWindow")
        touch.setValue(point, forKey: "locationInWindow")
        touch.setValue(phase.rawValue, forKey: "phase")
        touch.setValue(NSNumber(value: ProcessInfo.processInfo.systemUptime), forKey: "timestamp")
    }

    private static func syntheticEvent(with touch: UITouch) -> UIEvent {
        // Create a UIEvent containing our synthetic touch
        let event = UIEvent()
        let touches = NSSet(object: touch)
        event.setValue(touches, forKey: "allTouches")
        return event
    }

    // MARK: - Helpers

    private static func targetWindow(for point: CGPoint) -> UIWindow? {
        AccessibilityScanner.appWindows.first { $0.isKeyWindow }
            ?? AccessibilityScanner.appWindows.first
    }

    private static func findFirstResponder(in view: UIView) -> UIResponder? {
        if view.isFirstResponder { return view }
        for subview in view.subviews {
            if let responder = findFirstResponder(in: subview) {
                return responder
            }
        }
        return nil
    }
}
