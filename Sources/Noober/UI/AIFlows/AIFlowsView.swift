import SwiftUI

/// AI Flows tab — record navigation flows for NoobQA to replay.
struct AIFlowsView: View {
    @StateObject private var recorder = FlowRecorder.shared
    @State private var flowName = ""
    @State private var flowDescription = ""
    @State private var showNameForm = false
    @State private var expandedFlowId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            header
            if showNameForm { nameForm } else { recordButton.padding(.horizontal, 16) }
            Divider().padding(.top, 12)
            if recorder.savedFlows.isEmpty { emptyState } else { flowsList }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.purple)
                Text("AI Flows")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                if !recorder.savedFlows.isEmpty {
                    Text("\(recorder.savedFlows.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.purple))
                }
            }
            Text("Record your navigation. NoobQA replays it instantly — AI handles the verification part.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
    }

    // MARK: - Record Button

    private var recordButton: some View {
        Button { withAnimation(.spring(response: 0.3)) { showNameForm = true } } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(Color.purple.opacity(0.15)).frame(width: 32, height: 32)
                    Image(systemName: "record.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.purple)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Record New Flow")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Tap here, then navigate the app")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.4))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Name Form

    private var nameForm: some View {
        VStack(spacing: 12) {
            HStack {
                Circle().fill(Color.red).frame(width: 8, height: 8)
                Text("New Recording")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Button("Cancel") {
                    flowName = ""; flowDescription = ""
                    withAnimation { showNameForm = false }
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("NAME").font(.system(size: 9, weight: .bold)).foregroundColor(.secondary)
                TextField("e.g. Book Single Ride", text: $flowName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("DESCRIPTION FOR AI (optional)").font(.system(size: 9, weight: .bold)).foregroundColor(.secondary)
                TextField("e.g. Navigates from home to booking confirmation", text: $flowDescription)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))
            }

            Button {
                recorder.startRecording(name: flowName.isEmpty ? "Flow" : flowName, description: flowDescription)
                flowName = ""; flowDescription = ""
                showNameForm = false
                NooberWindow.shared.hideDebugger()
            } label: {
                HStack {
                    Spacer()
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                    Text("Start Recording")
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                }
                .padding(.vertical, 10)
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)

            HStack(spacing: 4) {
                Image(systemName: "info.circle").font(.system(size: 9))
                Text("After starting, navigate the app normally. Tap the red Noober bubble to stop recording.")
                    .font(.system(size: 10))
            }
            .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color.purple.opacity(0.03))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Flows List

    private var flowsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(recorder.savedFlows) { flow in
                    flowCard(flow)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
    }

    private func flowCard(_ flow: NooberFlow) -> some View {
        let isExpanded = expandedFlowId == flow.id

        return VStack(alignment: .leading, spacing: 0) {
            // Header row
            Button {
                withAnimation(.spring(response: 0.25)) {
                    expandedFlowId = isExpanded ? nil : flow.id
                }
            } label: {
                HStack(spacing: 10) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.1))
                            .frame(width: 36, height: 36)
                        Image(systemName: "point.topleft.down.to.point.bottomright.curvepath.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.purple)
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(flow.name)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            Label("\(flow.steps.count)", systemImage: "arrow.turn.down.right")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.purple)
                            if !flow.description.isEmpty {
                                Text("·").foregroundColor(.gray.opacity(0.4))
                                Text(flow.description)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    Spacer()

                    // Expand arrow
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.gray.opacity(0.4))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 10)

            // Expanded detail
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    // Screen path
                    screenPath(flow)

                    // Steps
                    VStack(alignment: .leading, spacing: 3) {
                        Text("STEPS").font(.system(size: 9, weight: .bold)).foregroundColor(.secondary)
                        ForEach(Array(flow.steps.enumerated()), id: \.offset) { i, step in
                            stepRow(i + 1, step)
                        }
                    }

                    // Device info
                    if let device = flow.device {
                        HStack(spacing: 4) {
                            Image(systemName: "iphone").font(.system(size: 9))
                            Text("\(device.name) · \(device.screenWidth)×\(device.screenHeight) @\(device.scale)x")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(.gray.opacity(0.4))
                        .padding(.top, 2)
                    }

                    // Recorded date
                    HStack(spacing: 4) {
                        Image(systemName: "clock").font(.system(size: 9))
                        Text(flow.recordedAt, style: .relative)
                            .font(.system(size: 9))
                        Text("ago").font(.system(size: 9))
                    }
                    .foregroundColor(.gray.opacity(0.4))

                    // Actions
                    HStack {
                        Spacer()
                        Button {
                            recorder.deleteFlow(id: flow.id)
                            expandedFlowId = nil
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .font(.system(size: 11))
                                .foregroundColor(.red.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
                .padding(.leading, 46)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()
        }
    }

    // MARK: - Screen path visualization

    private func screenPath(_ flow: NooberFlow) -> some View {
        let screens = flow.steps.map(\.screen).reduce(into: [String]()) { result, screen in
            if result.last != screen { result.append(screen) }
        }

        return VStack(alignment: .leading, spacing: 3) {
            Text("NAVIGATION PATH").font(.system(size: 9, weight: .bold)).foregroundColor(.secondary)
            HStack(spacing: 0) {
                ForEach(Array(screens.enumerated()), id: \.offset) { i, screen in
                    if i > 0 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.gray.opacity(0.4))
                            .padding(.horizontal, 4)
                    }
                    Text(screen.isEmpty ? "?" : screen)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.purple)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }

    // MARK: - Step row

    private func stepRow(_ number: Int, _ step: NooberFlowStep) -> some View {
        HStack(spacing: 6) {
            Text("\(number)")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 16, height: 16)
                .background(Circle().fill(Color.purple.opacity(0.6)))

            HStack(spacing: 4) {
                // Action badge
                Text(step.action.rawValue)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.purple)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 3))

                // Label or coordinates
                if let label = step.label {
                    Text("\"\(label)\"")
                        .font(.system(size: 10))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                } else if let coords = step.startCoordinates {
                    Text("(\(Int(coords.x)), \(Int(coords.y)))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                if let extra = step.extra, let dir = extra["direction"] {
                    Text(dir)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.orange)
                }

                Spacer()

                // Screen name
                Text(step.screen.isEmpty ? "" : step.screen)
                    .font(.system(size: 8))
                    .foregroundColor(.gray.opacity(0.4))
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle().fill(Color.purple.opacity(0.06)).frame(width: 80, height: 80)
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.purple.opacity(0.25))
            }

            VStack(spacing: 4) {
                Text("No Recorded Flows")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)
                Text("Record how you navigate the app.\nNoobQA replays it for faster testing.")
                    .font(.system(size: 12))
                    .foregroundColor(.gray.opacity(0.4))
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
    }
}
