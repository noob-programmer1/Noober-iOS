import SwiftUI

struct CustomActionListView: View {

    @ObservedObject var store: CustomActionStore
    @State private var runningActionId: UUID?
    @State private var completedActionId: UUID?

    var body: some View {
        if store.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(store.groupedActions, id: \.group) { group in
                        actionSection(group: group.group, actions: group.actions)
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - Section

    private func actionSection(group: String, actions: [RegisteredAction]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !group.isEmpty {
                Text(group.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }

            VStack(spacing: 0) {
                ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                    if index > 0 {
                        Divider().padding(.leading, 44)
                    }
                    actionRow(action)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Row

    private func actionRow(_ action: RegisteredAction) -> some View {
        let isRunning = runningActionId == action.id
        let isCompleted = completedActionId == action.id

        return Button {
            run(action)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(NooberTheme.accent.opacity(0.12))
                        .frame(width: 32, height: 32)

                    if isRunning {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(NooberTheme.success)
                    } else {
                        Image(systemName: action.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(NooberTheme.accent)
                    }
                }

                Text(action.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(isRunning ? .secondary : NooberTheme.accent)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(NooberTheme.PressScale())
        .disabled(isRunning)
    }

    // MARK: - Run

    private func run(_ action: RegisteredAction) {
        NooberTheme.hapticLight()
        NooberSound.playAreBaapRe()
        runningActionId = action.id

        // Run the handler, then show brief completion feedback
        action.handler()

        withAnimation(.spring(response: 0.3)) {
            runningActionId = nil
            completedActionId = action.id
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                if completedActionId == action.id {
                    completedActionId = nil
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color(uiColor: .tertiarySystemFill))
                    .frame(width: 80, height: 80)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            Text("No actions registered")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.secondary)
            Text("Register actions in your app:\nNoober.shared.registerActions([...])")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
