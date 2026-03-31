import SwiftUI

// MARK: - Rules Panel

struct V2RulesPanel: View {

    @StateObject private var rulesStore = RulesStore.shared
    @StateObject private var pendingStore = PendingInterceptStore.shared
    @StateObject private var envStore = EnvironmentStore.shared
    @StateObject private var deepLinkStore = DeepLinkStore.shared

    @State private var activeTab: RuleTab = .rewrite
    @State private var reviewingIntercept: PendingIntercept?

    enum RuleTab: String, CaseIterable {
        case rewrite  = "Rewrite"
        case mocks    = "Mocks"
        case intercept = "Intercept"
        case env       = "Env"
        case links     = "Links"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Pending intercept banner
            if let first = pendingStore.pendingIntercepts.first {
                interceptBanner(first)
            }

            // Tab strip
            tabStrip

            V2Separator()

            // Content
            contentArea
        }
        .background(DS.Background.primary)
        .sheet(item: $reviewingIntercept) { intercept in
            InterceptReviewView(intercept: intercept)
        }
    }

    // MARK: - Tab Strip

    private var tabStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Space.xs) {
                ForEach(RuleTab.allCases, id: \.self) { tab in
                    V2FilterChip(
                        title: tab.rawValue,
                        isSelected: activeTab == tab,
                        count: tabCount(tab)
                    ) {
                        withAnimation(DS.snappy) { activeTab = tab }
                    }
                }
            }
            .padding(.horizontal, DS.Space.xl)
            .padding(.vertical, DS.Space.m)
        }
    }

    @ViewBuilder
    private var contentArea: some View {
        switch activeTab {
        case .rewrite:  RewriteRuleListView(store: rulesStore)
        case .mocks:    MockRuleListView(store: rulesStore)
        case .intercept: InterceptRuleListView(store: rulesStore)
        case .env:      v2EnvironmentList
        case .links:    DeepLinkTesterView(store: deepLinkStore)
        }
    }

    // MARK: - Environment List (restyled)

    private var v2EnvironmentList: some View {
        ScrollView {
            if envStore.environments.isEmpty {
                V2EmptyState(
                    icon: "server.rack",
                    title: "No environments",
                    subtitle: "Register environments via\nNoober.shared.registerEnvironments()"
                )
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(envStore.environments) { env in
                        envRow(env)
                    }
                }
            }
        }
    }

    private func envRow(_ env: NooberEnvironment) -> some View {
        let isActive = envStore.activeEnvironmentId == env.id
        return Button {
            DS.haptic(.medium)
            withAnimation(DS.snappy) {
                envStore.activate(id: env.id)
            }
        } label: {
            HStack(spacing: DS.Space.l) {
                StatusDot(color: isActive ? DS.Accent.primary : DS.Text.disabled, size: 8)

                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Text(env.name)
                        .font(DS.Font.label(13, weight: isActive ? .semibold : .regular))
                        .foregroundColor(isActive ? DS.Text.primary : DS.Text.secondary)
                    Text(env.baseURLs.first ?? "")
                        .font(DS.Font.monoMicro)
                        .foregroundColor(DS.Text.tertiary)
                        .lineLimit(1)
                }

                Spacer()

                if isActive {
                    Text("ACTIVE")
                        .font(DS.Font.mono(9, weight: .bold))
                        .foregroundColor(DS.Accent.primary)
                        .padding(.horizontal, DS.Space.m)
                        .padding(.vertical, DS.Space.xs)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.xs)
                                .fill(DS.Accent.subtle)
                        )
                }
            }
            .padding(.horizontal, DS.Space.xl)
            .padding(.vertical, DS.Space.l)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { V2Separator(leading: DS.Space.xl + 20) }
    }

    // MARK: - Intercept Banner

    private func interceptBanner(_ intercept: PendingIntercept) -> some View {
        Button {
            reviewingIntercept = intercept
        } label: {
            HStack(spacing: DS.Space.m) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 13))

                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Text("\(pendingStore.pendingIntercepts.count) intercepted")
                        .font(DS.Font.label(12, weight: .semibold))
                    Text("\(intercept.method) \(intercept.path)")
                        .font(DS.Font.monoMicro)
                        .lineLimit(1)
                }

                Spacer()

                Text("Review")
                    .font(DS.Font.label(11, weight: .bold))
                    .padding(.horizontal, DS.Space.m)
                    .padding(.vertical, DS.Space.s)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.xs)
                            .fill(Color.white.opacity(0.15))
                    )
            }
            .foregroundColor(.white)
            .padding(.horizontal, DS.Space.xl)
            .padding(.vertical, DS.Space.l)
            .background(DS.Status.warning)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func tabCount(_ tab: RuleTab) -> Int? {
        switch tab {
        case .rewrite:  return rulesStore.rewriteRules.count > 0 ? rulesStore.rewriteRules.count : nil
        case .mocks:    return rulesStore.mockRules.count > 0 ? rulesStore.mockRules.count : nil
        case .intercept: return rulesStore.interceptRules.count > 0 ? rulesStore.interceptRules.count : nil
        case .env:      return envStore.environments.count > 0 ? envStore.environments.count : nil
        case .links:    return nil
        }
    }
}
