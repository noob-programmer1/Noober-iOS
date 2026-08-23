import SwiftUI
import Combine

struct FloatingBubbleView: View {

    let onTap: () -> Void

    @ObservedObject private var store = NetworkActivityStore.shared
    @State private var lastSeenPulseID: UInt = NetworkActivityStore.shared.pulseID

    // MARK: - Drag state

    @State private var position = CGPoint(x: UIScreen.main.bounds.width - 40, y: 120)
    @State private var isDragging = false

    // MARK: - Appearance state

    /// Fades the bubble back once the user leaves it alone, the way AssistiveTouch does.
    @State private var isDimmed = false
    @State private var idleToken = 0

    /// Brief outline flash — failures only, so a healthy app stays visually quiet.
    @State private var alertOpacity: Double = 0

    /// Slow arc that only exists while requests are in flight.
    @State private var arcRotation: Double = 0
    @State private var isSpinning = false

    private let size: CGFloat = 46
    private let idleOpacity: Double = 0.4
    private let idleDelay: TimeInterval = 3

    var body: some View {
        GeometryReader { geometry in
            bubbleContent
                .position(position)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isDragging && hypot(value.translation.width, value.translation.height) > 4 {
                                isDragging = true
                            }
                            wake()
                            if isDragging {
                                position = CGPoint(
                                    x: value.startLocation.x + value.translation.width,
                                    y: value.startLocation.y + value.translation.height
                                )
                                reportFrame()
                            }
                        }
                        .onEnded { _ in
                            if !isDragging {
                                onTap()
                            } else {
                                let screenWidth = geometry.size.width
                                let snappedX = position.x < screenWidth / 2
                                    ? (size / 2 + 4)
                                    : (screenWidth - size / 2 - 4)
                                let clampedY = max(60, min(geometry.size.height - 60, position.y))

                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    position = CGPoint(x: snappedX, y: clampedY)
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    reportFrame()
                                }
                            }
                            isDragging = false
                            wake()
                        }
                )
                .onReceive(store.$pulseID) { newValue in
                    guard newValue != lastSeenPulseID else { return }
                    lastSeenPulseID = newValue
                    guard !store.lastRequestSucceeded else { return }
                    flashFailure()
                }
                .onReceive(store.$activeRequestCount) { count in
                    count > 0 ? startArc() : stopArc()
                }
                .onAppear {
                    reportFrame()
                    scheduleDim()
                }
        }
        .edgesIgnoringSafeArea(.all)
    }

    // MARK: - Bubble content

    private var bubbleContent: some View {
        ZStack {
            Circle()
                .fill(NooberTheme.accent)
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "ant.fill")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundColor(.white)
                )
                .overlay(
                    Circle()
                        .stroke(NooberTheme.error, lineWidth: 2)
                        .opacity(alertOpacity)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 5, x: 0, y: 2)

            if store.activeRequestCount > 0 {
                Circle()
                    .trim(from: 0, to: 0.22)
                    .stroke(
                        Color.white.opacity(0.5),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: size - 8, height: size - 8)
                    .rotationEffect(.degrees(arcRotation))
            }

            if FlowRecorder.shared.isRecording {
                Circle()
                    .fill(Color.red)
                    .frame(width: 9, height: 9)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    .offset(x: -size / 2.6, y: -size / 2.6)
            }
        }
        .scaleEffect(isDragging ? 1.06 : 1.0)
        .opacity(isDragging || !isDimmed ? 1 : idleOpacity)
    }

    /// When recording and bubble is tapped, stop recording instead of opening debugger
    var isRecording: Bool { FlowRecorder.shared.isRecording }

    // MARK: - Frame reporting

    private func reportFrame() {
        NooberWindow.shared.bubbleFrame = CGRect(
            x: position.x - size / 2,
            y: position.y - size / 2,
            width: size,
            height: size
        )
    }

    // MARK: - Idle dimming

    private func wake() {
        if isDimmed {
            withAnimation(.easeOut(duration: 0.15)) { isDimmed = false }
        }
        scheduleDim()
    }

    private func scheduleDim() {
        idleToken &+= 1
        let token = idleToken
        DispatchQueue.main.asyncAfter(deadline: .now() + idleDelay) {
            guard token == idleToken, !isDragging else { return }
            withAnimation(.easeInOut(duration: 0.5)) { isDimmed = true }
        }
    }

    // MARK: - Failure flash

    private func flashFailure() {
        withAnimation(.easeOut(duration: 0.12)) { alertOpacity = 0.85 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.6)) { alertOpacity = 0 }
        }
    }

    // MARK: - In-flight arc

    private func startArc() {
        guard !isSpinning else { return }
        isSpinning = true
        arcRotation = 0
        withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
            arcRotation = 360
        }
    }

    private func stopArc() {
        guard isSpinning else { return }
        isSpinning = false
        // Replace the repeating animation with an instant one so it doesn't keep running.
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { arcRotation = 0 }
    }
}
