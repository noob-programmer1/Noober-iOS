import SwiftUI

struct EnvironmentListView: View {

    @ObservedObject var store: EnvironmentStore
    @State private var confirmingEnv: NooberEnvironment?

    var body: some View {
        if store.environments.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(store.environments) { env in
                        EnvironmentCard(
                            env: env,
                            isActive: env.id == store.activeEnvironmentId,
                            isDefault: env.id == store.defaultEnvironment?.id
                        ) {
                            if env.id == store.activeEnvironmentId { return }
                            if env.notes.isEmpty {
                                store.activate(id: env.id)
                            } else {
                                confirmingEnv = env
                            }
                        }
                    }
                }
                .padding(16)
            }
            .alert(
                "Switch to \(confirmingEnv?.name ?? "")?",
                isPresented: Binding(
                    get: { confirmingEnv != nil },
                    set: { if !$0 { confirmingEnv = nil } }
                )
            ) {
                Button("Cancel", role: .cancel) { confirmingEnv = nil }
                Button("Switch") {
                    NooberTheme.hapticMedium()
                    if let env = confirmingEnv {
                        store.activate(id: env.id)
                    }
                    confirmingEnv = nil
                }
            } message: {
                Text(confirmingEnv?.notes ?? "")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle().fill(Color(uiColor: .tertiarySystemFill)).frame(width: 80, height: 80)
                Image(systemName: "server.rack")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            Text("No environments")
                .font(.system(size: 17, weight: .semibold)).foregroundColor(.secondary)
            Text("Register environments in your app:\nNoober.shared.registerEnvironments([...])")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Environment Card

private struct EnvironmentCard: View {

    let env: NooberEnvironment
    let isActive: Bool
    let isDefault: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Active indicator
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isActive ? NooberTheme.success : Color(uiColor: .tertiaryLabel))

                VStack(alignment: .leading, spacing: 4) {
                    // Name + default badge
                    HStack(spacing: 6) {
                        Text(env.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        if isDefault {
                            Text("DEFAULT")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(Color(uiColor: .tertiaryLabel))
                                )
                        }
                        if isActive && !isDefault {
                            Text("ACTIVE")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(NooberTheme.success)
                                )
                        }
                    }

                    // Base URLs
                    ForEach(env.baseURLs, id: \.self) { url in
                        Text(url)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    // Notes
                    if !env.notes.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(NooberTheme.warning)
                            Text(env.notes)
                                .font(.system(size: 11))
                                .foregroundColor(NooberTheme.warning)
                                .lineLimit(2)
                        }
                        .padding(.top, 2)
                    }
                }

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isActive ? NooberTheme.success : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
