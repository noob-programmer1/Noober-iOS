import SwiftUI

// MARK: - More Panel (QA, Actions, AI Flows)

struct V2MorePanel: View {

    @StateObject private var qaStore = QAChecklistStore.shared
    @StateObject private var actionStore = CustomActionStore.shared

    @State private var activeDestination: Destination?

    enum Destination {
        case qa
        case actions
        case aiFlows
    }

    var body: some View {
        if let dest = activeDestination {
            destinationContent(dest)
        } else {
            menuList
        }
    }

    // MARK: - Menu

    private var menuList: some View {
        ScrollView {
            VStack(spacing: 0) {
                menuRow(
                    icon: "checklist",
                    title: "QA Checklist",
                    subtitle: qaStore.isEmpty ? "No checklist registered" : "\(qaStore.passedCount)/\(qaStore.totalCount) passed",
                    color: DS.Status.success,
                    badge: qaStore.isEmpty ? nil : progressText
                ) {
                    activeDestination = .qa
                }

                V2Separator(leading: 52)

                menuRow(
                    icon: "bolt.fill",
                    title: "Actions",
                    subtitle: actionStore.isEmpty ? "No actions registered" : "\(actionStore.actions.count) action\(actionStore.actions.count == 1 ? "" : "s")",
                    color: DS.Status.info
                ) {
                    activeDestination = .actions
                }

                V2Separator(leading: 52)

                menuRow(
                    icon: "brain.head.profile",
                    title: "AI Flows",
                    subtitle: "Record navigation flows",
                    color: DS.Status.purple
                ) {
                    activeDestination = .aiFlows
                }
            }
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.l)
                    .fill(DS.Background.elevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.l)
                            .stroke(DS.Border.subtle, lineWidth: 0.5)
                    )
            )
            .padding(DS.Space.xl)
        }
        .background(DS.Background.primary)
    }

    private var progressText: String {
        "\(qaStore.passedCount)/\(qaStore.totalCount)"
    }

    private func menuRow(icon: String, title: String, subtitle: String, color: Color, badge: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: {
            DS.haptic()
            withAnimation(DS.snappy) { action() }
        }) {
            HStack(spacing: DS.Space.l) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.s)
                            .fill(color.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Text(title)
                        .font(DS.Font.label(14, weight: .medium))
                        .foregroundColor(DS.Text.primary)
                    Text(subtitle)
                        .font(DS.Font.caption)
                        .foregroundColor(DS.Text.tertiary)
                }

                Spacer()

                if let badge {
                    Text(badge)
                        .font(DS.Font.mono(10, weight: .bold))
                        .foregroundColor(DS.Accent.primary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(DS.Text.disabled)
            }
            .padding(.horizontal, DS.Space.xl)
            .padding(.vertical, DS.Space.l)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Destination Content

    @ViewBuilder
    private func destinationContent(_ dest: Destination) -> some View {
        VStack(spacing: 0) {
            // Back bar
            Button {
                DS.haptic()
                withAnimation(DS.snappy) { activeDestination = nil }
            } label: {
                HStack(spacing: DS.Space.s) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text(destinationTitle(dest))
                        .font(DS.Font.label(14, weight: .medium))
                    Spacer()
                }
                .foregroundColor(DS.Accent.primary)
                .padding(.horizontal, DS.Space.xl)
                .padding(.vertical, DS.Space.l)
            }
            .buttonStyle(.plain)
            .background(DS.Background.elevated)

            V2Separator()

            switch dest {
            case .qa:      QAChecklistListView(store: qaStore)
            case .actions: v2ActionList
            case .aiFlows: AIFlowsView()
            }
        }
    }

    // MARK: - Action List (restyled)

    private var v2ActionList: some View {
        ScrollView {
            if actionStore.isEmpty {
                V2EmptyState(
                    icon: "bolt.slash",
                    title: "No actions",
                    subtitle: "Register actions via\nNoober.shared.registerActions()"
                )
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(actionStore.actions) { action in
                        Button {
                            DS.haptic(.medium)
                            action.handler()
                            DS.hapticNotify(.success)
                        } label: {
                            HStack(spacing: DS.Space.l) {
                                Image(systemName: action.icon)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(DS.Status.info)
                                    .frame(width: 24)

                                Text(action.title)
                                    .font(DS.Font.label(13, weight: .medium))
                                    .foregroundColor(DS.Text.primary)

                                Spacer()

                                Image(systemName: "play.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(DS.Text.disabled)
                            }
                            .padding(.horizontal, DS.Space.xl)
                            .padding(.vertical, DS.Space.l)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .overlay(alignment: .bottom) { V2Separator(leading: 52) }
                    }
                }
            }
        }
    }

    private func destinationTitle(_ dest: Destination) -> String {
        switch dest {
        case .qa: return "QA Checklist"
        case .actions: return "Actions"
        case .aiFlows: return "AI Flows"
        }
    }
}
