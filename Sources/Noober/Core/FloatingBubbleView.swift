import SwiftUI

struct FloatingBubbleView: View {

    let onTap: () -> Void

    @StateObject private var store = NetworkActivityStore.shared

    // MARK: - Drag state

    @State private var position = CGPoint(x: UIScreen.main.bounds.width - 40, y: 120)
    @State private var isDragging = false

    // MARK: - Animation state

    @State private var pulseScale: CGFloat = 1.0
    @State private var ringScale: CGFloat = 1.0
    @State private var ringOpacity: Double = 0
    @State private var ringColor: Color = .green
    @State private var iconRotation: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var requestCountBadge: Int = 0
    @State private var showBadge = false

    private let size: CGFloat = 54

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
                            if isDragging {
                                let newPos = CGPoint(
                                    x: value.startLocation.x + value.translation.width,
                                    y: value.startLocation.y + value.translation.height
                                )
                                position = newPos
                                reportFrame()
                            }
                        }
                        .onEnded { value in
                            if !isDragging {
                                // It was a tap
                                onTap()
                            } else {
                                // Snap to edge
                                let screenWidth = geometry.size.width
                                let snappedX = position.x < screenWidth / 2
                                    ? (size / 2 + 4)
                                    : (screenWidth - size / 2 - 4)
                                let clampedY = max(60, min(geometry.size.height - 60, position.y))

                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    position = CGPoint(x: snappedX, y: clampedY)
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    reportFrame()
                                }
                            }
                            isDragging = false
                        }
                )
                .onChange(of: store.pulseID) { _ in
                    triggerPulse()
                }
                .onChange(of: store.activeRequestCount) { count in
                    withAnimation(.spring(response: 0.3)) {
                        requestCountBadge = count
                        showBadge = count > 0
                    }
                    if count > 0 {
                        startSpinner()
                    }
                }
                .onAppear {
                    reportFrame()
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                        pulseScale = 1.0
                    }
                }
        }
        .ignoresSafeArea()
    }

    // MARK: - Bubble content

    private var bubbleContent: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .stroke(ringColor, lineWidth: 2.5)
                .frame(width: size, height: size)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            // Glow layer
            Circle()
                .fill(ringColor)
                .frame(width: size, height: size)
                .blur(radius: 12)
                .opacity(glowOpacity)

            // Main bubble
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.25, green: 0.48, blue: 1.0),
                            Color(red: 0.15, green: 0.30, blue: 0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    ZStack {
                        Image(systemName: "ant.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 24, weight: .medium))
                            .rotationEffect(.degrees(iconRotation))

                        if store.activeRequestCount > 0 {
                            Circle()
                                .trim(from: 0, to: 0.3)
                                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                                .frame(width: size - 6, height: size - 6)
                                .rotationEffect(.degrees(iconRotation * 3))
                        }
                    }
                )
                .scaleEffect(isDragging ? 1.15 : pulseScale)
                .shadow(
                    color: Color(red: 0.15, green: 0.30, blue: 0.85).opacity(isDragging ? 0.5 : 0.3),
                    radius: isDragging ? 12 : 8,
                    x: 0,
                    y: isDragging ? 6 : 4
                )

            // Request count badge
            if showBadge && requestCountBadge > 0 {
                Text(requestCountBadge > 99 ? "99+" : "\(requestCountBadge)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.red))
                    .offset(x: size / 2.5, y: -size / 2.5)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Frame reporting

    private func reportFrame() {
        NooberWindow.shared.bubbleFrame = CGRect(
            x: position.x - size / 2,
            y: position.y - size / 2,
            width: size,
            height: size
        )
    }

    // MARK: - Pulse animation

    private func triggerPulse() {
        let success = store.lastRequestSucceeded
        ringColor = success ? .green : .red

        ringScale = 1.0
        ringOpacity = 0.9
        withAnimation(.easeOut(duration: 0.6)) {
            ringScale = 2.2
            ringOpacity = 0
        }

        glowOpacity = success ? 0.4 : 0.5
        withAnimation(.easeOut(duration: 0.5)) {
            glowOpacity = 0
        }

        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            pulseScale = 1.12
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                pulseScale = 1.0
            }
        }

        withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) {
            iconRotation += (success ? 15 : -15)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                iconRotation = 0
            }
        }
    }

    // MARK: - Spinner

    private func startSpinner() {
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            iconRotation = 360
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if store.activeRequestCount == 0 {
                withAnimation(.spring(response: 0.2)) {
                    iconRotation = 0
                }
            }
        }
    }
}
