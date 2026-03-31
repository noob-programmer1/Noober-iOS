import SwiftUI

// MARK: - Navigation Section

enum V2Section: String, CaseIterable, Identifiable {
    case network  = "Network"
    case logs     = "Logs"
    case rules    = "Rules"
    case storage  = "Storage"
    case more     = "More"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .network: return "arrow.up.arrow.down"
        case .logs:    return "text.alignleft"
        case .rules:   return "slider.horizontal.3"
        case .storage: return "cylinder.split.1x2"
        case .more:    return "ellipsis"
        }
    }
}

// MARK: - Root View

struct NooberV2Root: View {

    @StateObject private var networkStore = NetworkActivityStore.shared
    @StateObject private var logStore = LogStore.shared
    @StateObject private var rulesStore = RulesStore.shared

    @State private var activeSection: V2Section = .network
    @State private var showCommandPalette = false

    var body: some View {
        VStack(spacing: 0) {
            topBar
            navStrip
            V2Separator()
            contentArea
        }
        .darkContainer()
        .overlay {
            if showCommandPalette {
                V2CommandPalette(isPresented: $showCommandPalette, onNavigate: { section in
                    activeSection = section
                })
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(DS.smooth, value: showCommandPalette)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: DS.Space.m) {
            // Noober branding — minimal
            HStack(spacing: DS.Space.s) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.Accent.primary)
                Text("Noober")
                    .font(DS.Font.label(15, weight: .semibold))
                    .foregroundColor(DS.Text.primary)
            }

            Spacer()

            // Command palette trigger
            Button {
                DS.haptic()
                showCommandPalette = true
            } label: {
                HStack(spacing: DS.Space.s) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12, weight: .medium))
                    Text("Search")
                        .font(DS.Font.caption)
                }
                .foregroundColor(DS.Text.tertiary)
                .padding(.horizontal, DS.Space.l)
                .padding(.vertical, DS.Space.s + 1)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.s)
                        .fill(DS.Background.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.s)
                                .stroke(DS.Border.subtle, lineWidth: 0.5)
                        )
                )
            }
            .buttonStyle(.plain)

            // Close button
            V2ToolbarButton(icon: "xmark", color: DS.Text.tertiary) {
                NooberWindow.shared.hideDebugger()
            }
        }
        .padding(.horizontal, DS.Space.xl)
        .padding(.vertical, DS.Space.m)
        .background(DS.Background.primary)
    }

    // MARK: - Navigation Strip (Linear-style)

    private var navStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Space.xs) {
                ForEach(V2Section.allCases) { section in
                    V2NavItem(
                        icon: section.icon,
                        label: section.rawValue,
                        count: badgeCount(for: section),
                        dotColor: dotColor(for: section),
                        isSelected: activeSection == section
                    ) {
                        withAnimation(DS.snappy) { activeSection = section }
                    }
                }
            }
            .padding(.horizontal, DS.Space.xl)
            .padding(.vertical, DS.Space.s)
        }
        .background(DS.Background.primary)
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        switch activeSection {
        case .network:
            V2NetworkPanel()
        case .logs:
            V2LogConsole()
        case .rules:
            V2RulesPanel()
        case .storage:
            V2StoragePanel()
        case .more:
            V2MorePanel()
        }
    }

    // MARK: - Badge Helpers

    private func badgeCount(for section: V2Section) -> Int? {
        switch section {
        case .network: return networkStore.requests.count + networkStore.webSocketConnections.count
        case .logs:    return logStore.entries.count
        case .rules:
            let total = rulesStore.rewriteRules.count + rulesStore.mockRules.count + rulesStore.interceptRules.count
            return total > 0 ? total : nil
        default: return nil
        }
    }

    private func dotColor(for section: V2Section) -> Color? {
        switch section {
        case .network:
            if networkStore.activeRequestCount > 0 { return DS.Accent.primary }
            if !networkStore.lastRequestSucceeded { return DS.Status.error }
            return DS.Status.success
        case .logs:
            if logStore.entries.contains(where: { $0.level == .error }) { return DS.Status.error }
            if logStore.entries.contains(where: { $0.level == .warning }) { return DS.Status.warning }
            return nil
        default: return nil
        }
    }
}
