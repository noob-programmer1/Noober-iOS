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

// MARK: - QA Tab

struct QATabContent: View {
    @StateObject private var store = QAChecklistStore.shared

    var body: some View {
        QAChecklistListView(store: store)
    }
}
