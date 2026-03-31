import UIKit

/// Records user interactions (taps, swipes, text input) as replayable flows.
/// Activated via the Noober bubble's record button.
@MainActor
public final class FlowRecorder: ObservableObject {

    public static let shared = FlowRecorder()

    @Published public private(set) var isRecording = false
    @Published public private(set) var savedFlows: [NooberFlow] = []

    private var currentSteps: [NooberFlowStep] = []
    private var currentFlowName: String = ""
    private var touchStart: (point: CGPoint, time: Date, screen: String)?

    // MARK: - Public API

    private var currentFlowDescription: String = ""

    public func startRecording(name: String, description: String = "") {
        currentFlowName = name
        currentFlowDescription = description
        currentSteps = []
        isRecording = true
        TouchInterceptor.install(recorder: self)
    }

    public func stopRecording(description: String? = nil) {
        guard isRecording else { return }
        TouchInterceptor.uninstall()
        isRecording = false

        let screen = UIScreen.main.bounds
        let deviceInfo = NooberFlow.DeviceInfo(
            name: UIDevice.current.name,
            screenWidth: Int(screen.width),
            screenHeight: Int(screen.height),
            scale: Int(UIScreen.main.scale)
        )

        let flow = NooberFlow(
            name: currentFlowName.isEmpty ? "Flow \(savedFlows.count + 1)" : currentFlowName,
            description: description ?? currentFlowDescription,
            steps: currentSteps,
            recordedAt: Date(),
            device: deviceInfo
        )
        savedFlows.append(flow)
        persist()
    }

    public func deleteFlow(id: UUID) {
        savedFlows.removeAll { $0.id == id }
        persist()
    }

    // MARK: - Export / Import

    /// Export all flows as JSON Data (for sharing/backup)
    public func exportAllFlows() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(savedFlows)
    }

    /// Import flows from JSON Data (merges with existing, skips duplicates by name)
    public func importFlows(from data: Data) -> Int {
        guard let imported = try? JSONDecoder().decode([NooberFlow].self, from: data) else { return 0 }
        var count = 0
        for flow in imported {
            if !savedFlows.contains(where: { $0.name == flow.name }) {
                savedFlows.append(flow)
                count += 1
            }
        }
        if count > 0 { persist() }
        return count
    }

    // MARK: - Touch Handling (called with pre-extracted data from TouchInterceptor)

    func handleTouchBeganAt(_ point: CGPoint, screen: String) {
        touchStart = (point: point, time: Date(), screen: screen)
    }

    func handleTouchEndedAt(_ point: CGPoint, label: String?) {
        guard let start = touchStart else { return }
        let screen = start.screen  // use screen from when touch BEGAN

        let dx = point.x - start.point.x
        let dy = point.y - start.point.y
        let distance = sqrt(dx * dx + dy * dy)

        if distance > 50 {
            // Swipe
            let direction: String
            if abs(dx) > abs(dy) {
                direction = dx > 0 ? "right" : "left"
            } else {
                direction = dy > 0 ? "down" : "up"
            }
            currentSteps.append(NooberFlowStep(
                action: .swipe,
                screen: screen,
                startCoordinates: .init(x: start.point.x, y: start.point.y),
                endCoordinates: .init(x: point.x, y: point.y),
                extra: ["direction": direction]
            ))
        } else {
            // Tap
            currentSteps.append(NooberFlowStep(
                action: .tap,
                screen: screen,
                label: label,
                startCoordinates: .init(x: point.x, y: point.y)
            ))
        }

        touchStart = nil
    }

    // MARK: - Text Input Capture

    func handleTextInput(_ text: String) {
        guard isRecording else { return }
        let screen = ScreenTracker.shared.currentScreen
        currentSteps.append(NooberFlowStep(
            action: .typeText,
            screen: screen,
            text: text
        ))
    }

    // MARK: - Persistence

    private let fileURL: URL = {
        // Save to a shared location that survives app reinstalls on the simulator.
        // /tmp/noober/ persists across installs (it's the simulator's tmp, not the app's sandbox).
        // On a real device, falls back to Documents directory.
        #if targetEnvironment(simulator)
        let dir = URL(fileURLWithPath: "/tmp/noober")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("noober_flows.json")
        #else
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("noober_flows.json")
        #endif
    }()

    func loadSavedFlows() {
        guard let data = try? Data(contentsOf: fileURL),
              let flows = try? JSONDecoder().decode([NooberFlow].self, from: data) else { return }
        savedFlows = flows
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(savedFlows) else { return }
        try? data.write(to: fileURL)
    }

    private init() {
        loadSavedFlows()
    }
}

// MARK: - Touch Interceptor (swizzles UIApplication.sendEvent)

private enum TouchInterceptor {
    nonisolated(unsafe) static var isInstalled = false
    nonisolated(unsafe) static var originalIMP: IMP?
    nonisolated(unsafe) static weak var recorder: FlowRecorder?

    static func install(recorder: FlowRecorder) {
        self.recorder = recorder
        guard !isInstalled else { return }
        isInstalled = true

        let sel = #selector(UIApplication.sendEvent(_:))
        guard let method = class_getInstanceMethod(UIApplication.self, sel) else { return }
        originalIMP = method_getImplementation(method)

        let block: @convention(block) (UIApplication, UIEvent) -> Void = { app, event in
            // Capture screen name BEFORE processing the event
            // (processing triggers navigation which changes the screen name)
            let screenBeforeTap = ScreenTracker.shared.currentScreen

            // Capture touch data BEFORE calling original (UITouch is recycled after)
            var touchData: [(phase: UITouch.Phase, point: CGPoint, label: String?, window: UIWindow)] = []
            if let touches = event.allTouches {
                for touch in touches {
                    guard let window = touch.window else { continue }
                    if window is BubbleWindow { continue }
                    let point = touch.location(in: window)
                    let hitView = window.hitTest(point, with: nil)
                    let label = hitView?.accessibilityLabel
                        ?? hitView?.accessibilityIdentifier
                        ?? Self.findLabel(hitView)
                    touchData.append((phase: touch.phase, point: point, label: label, window: window))
                }
            }

            // Call original — this processes the tap and may trigger navigation
            let original = unsafeBitCast(originalIMP!, to: (@convention(c) (UIApplication, Selector, UIEvent) -> Void).self)
            original(app, sel, event)

            // Now record the touches with the BEFORE-tap screen name
            for data in touchData {
                Task { @MainActor in
                    guard let rec = Self.recorder, rec.isRecording else { return }
                    if NooberWindow.shared.isNooberWindow(data.window) { return }
                    switch data.phase {
                    case .began:
                        rec.handleTouchBeganAt(data.point, screen: screenBeforeTap)
                    case .ended:
                        rec.handleTouchEndedAt(data.point, label: data.label)
                    default:
                        break
                    }
                }
            }
        }

        method_setImplementation(method, imp_implementationWithBlock(block))
    }

    /// Walk up the view hierarchy to find a label (called synchronously from sendEvent)
    private static func findLabel(_ view: UIView?) -> String? {
        var current = view
        for _ in 0..<5 {
            guard let v = current else { return nil }
            if let label = v.accessibilityLabel, !label.isEmpty { return label }
            if let id = v.accessibilityIdentifier, !id.isEmpty { return id }
            if let label = v as? UILabel, let text = label.text, !text.isEmpty { return text }
            if let button = v as? UIButton, let title = button.titleLabel?.text, !title.isEmpty { return title }
            current = v.superview
        }
        return nil
    }

    static func uninstall() {
        guard isInstalled, let imp = originalIMP else { return }
        isInstalled = false
        let sel = #selector(UIApplication.sendEvent(_:))
        guard let method = class_getInstanceMethod(UIApplication.self, sel) else { return }
        method_setImplementation(method, imp)
        originalIMP = nil
        recorder = nil
    }
}
