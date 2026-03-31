import SwiftUI

// MARK: - Network Tab

struct NetworkTabContent: View {
    @StateObject private var store = NetworkActivityStore.shared

    var body: some View {
        NetworkListView(store: store)
    }
}

// MARK: - Storage Tab (UserDefaults + Keychain)

struct StorageTabContent: View {
    @StateObject private var userDefaultsStore = UserDefaultsStore.shared
    @StateObject private var keychainStore = KeychainStore.shared
    @State private var selectedSection: StorageSection = .userDefaults

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $selectedSection) {
                Text("UserDefaults").tag(StorageSection.userDefaults)
                Text("Keychain").tag(StorageSection.keychain)
                Text("App Info").tag(StorageSection.appInfo)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .onChange(of: selectedSection) { _ in NooberTheme.hapticLight() }

            Group {
                switch selectedSection {
                case .userDefaults:
                    UserDefaultsListView(store: userDefaultsStore)
                case .keychain:
                    KeychainListView(store: keychainStore)
                case .appInfo:
                    AppInfoView()
                }
            }
            .animation(.easeInOut(duration: 0.15), value: selectedSection)
        }
    }
}

// MARK: - Logs Tab

struct LogsTabContent: View {
    @StateObject private var logStore = LogStore.shared

    var body: some View {
        LogListView(store: logStore)
    }
}

// MARK: - Rules Tab (URL Rewrite + Mocks + Intercept)

struct RulesTabContent: View {
    @StateObject private var rulesStore = RulesStore.shared
    @StateObject private var pendingStore = PendingInterceptStore.shared
    @StateObject private var envStore = EnvironmentStore.shared
    @StateObject private var deepLinkStore = DeepLinkStore.shared
    @State private var selectedSection: RulesSection = .rewrite
    @State private var reviewingIntercept: PendingIntercept?

    var body: some View {
        VStack(spacing: 0) {
            // Pending intercept banner
            if let first = pendingStore.pendingIntercepts.first {
                interceptBanner(first)
            }

            Picker("Section", selection: $selectedSection) {
                Text("Rewrite").tag(RulesSection.rewrite)
                Text("Mocks").tag(RulesSection.mocks)
                Text("Intercept").tag(RulesSection.intercept)
                Text("Env").tag(RulesSection.environment)
                Text("Links").tag(RulesSection.deepLink)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .onChange(of: selectedSection) { _ in NooberTheme.hapticLight() }

            Group {
                switch selectedSection {
                case .rewrite: RewriteRuleListView(store: rulesStore)
                case .mocks: MockRuleListView(store: rulesStore)
                case .intercept: InterceptRuleListView(store: rulesStore)
                case .environment: EnvironmentListView(store: envStore)
                case .deepLink: DeepLinkTesterView(store: deepLinkStore)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: selectedSection)
        }
        .sheet(item: $reviewingIntercept) { intercept in
            InterceptReviewView(intercept: intercept)
        }
    }

    private func interceptBanner(_ intercept: PendingIntercept) -> some View {
        Button {
            reviewingIntercept = intercept
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 14))
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(pendingStore.pendingIntercepts.count) request\(pendingStore.pendingIntercepts.count == 1 ? "" : "s") intercepted")
                        .font(.system(size: 13, weight: .semibold))
                    Text("\(intercept.method) \(intercept.path)")
                        .font(.system(size: 11, design: .monospaced))
                        .lineLimit(1)
                }
                Spacer()
                Text("Review")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.2)))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(red: 0.95, green: 0.55, blue: 0.15))
        }
    }

}

// MARK: - More Tab (QA, Actions, AI Flows)

struct MoreTabContent: View {
    @StateObject private var actionStore = CustomActionStore.shared
    @StateObject private var qaStore = QAChecklistStore.shared
    @State private var activeDestination: MoreDestination?

    var body: some View {
        if let dest = activeDestination {
            VStack(spacing: 0) {
                backBar(dest.title)
                switch dest {
                case .qa:
                    QAChecklistListView(store: qaStore)
                case .actions:
                    CustomActionListView(store: actionStore)
                case .aiFlows:
                    AIFlowsView()
                }
            }
        } else {
            menuList
        }
    }

    // MARK: - Menu

    private var menuList: some View {
        ScrollView {
            VStack(spacing: 0) {
                moreRow(
                    icon: "checklist",
                    title: "QA Checklist",
                    subtitle: qaStore.isEmpty ? "No checklist registered" : "\(qaStore.passedCount)/\(qaStore.totalCount) passed",
                    color: NooberTheme.success
                ) {
                    activeDestination = .qa
                }

                Divider().padding(.leading, 62)

                moreRow(
                    icon: "bolt.fill",
                    title: "Actions",
                    subtitle: actionStore.isEmpty ? "No actions registered" : "\(actionStore.actions.count) action\(actionStore.actions.count == 1 ? "" : "s")",
                    color: NooberTheme.accent
                ) {
                    activeDestination = .actions
                }

                Divider().padding(.leading, 62)

                moreRow(
                    icon: "brain.head.profile",
                    title: "AI Flows",
                    subtitle: "Record navigation flows",
                    color: Color(red: 0.61, green: 0.35, blue: 0.96)
                ) {
                    activeDestination = .aiFlows
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
            .padding(16)
        }
    }

    private func moreRow(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Back Bar

    private func backBar(_ title: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                activeDestination = nil
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Spacer()
            }
            .foregroundColor(NooberTheme.accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(uiColor: .secondarySystemBackground))
    }
}

private enum MoreDestination {
    case qa
    case actions
    case aiFlows

    var title: String {
        switch self {
        case .qa: return "QA Checklist"
        case .actions: return "Actions"
        case .aiFlows: return "AI Flows"
        }
    }
}
