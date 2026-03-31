import SwiftUI
import UIKit

// MARK: - Command Palette (Raycast-style)

struct V2CommandPalette: View {

    @Binding var isPresented: Bool
    var onNavigate: (V2Section) -> Void

    @StateObject private var networkStore = NetworkActivityStore.shared
    @StateObject private var logStore = LogStore.shared
    @StateObject private var rulesStore = RulesStore.shared
    @StateObject private var envStore = EnvironmentStore.shared
    @StateObject private var actionStore = CustomActionStore.shared

    @State private var query = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // Backdrop
            DS.Background.overlay
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                // Search input
                searchBar
                V2Separator()

                // Results
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if query.isEmpty {
                            quickActionsSection
                            navigationSection
                            recentRequestsSection
                        } else {
                            searchResults
                        }
                    }
                }
                .frame(maxHeight: 420)
            }
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.l)
                    .fill(DS.Background.elevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.l)
                            .stroke(DS.Border.regular, lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
            )
            .padding(.horizontal, DS.Space.xl)
            .padding(.top, DS.Space.xxl)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .onAppear { isFocused = true }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: DS.Space.m) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(DS.Text.tertiary)

            TextField("Search requests, logs, actions...", text: $query)
                .font(DS.Font.body)
                .foregroundColor(DS.Text.primary)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .focused($isFocused)

            if !query.isEmpty {
                Button {
                    withAnimation(DS.snappy) { query = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(DS.Text.tertiary)
                }
                .buttonStyle(.plain)
            }

            Button {
                dismiss()
            } label: {
                Text("ESC")
                    .font(DS.Font.mono(10, weight: .semibold))
                    .foregroundColor(DS.Text.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.xs)
                            .fill(DS.Background.surface)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DS.Space.xl)
        .padding(.vertical, DS.Space.l)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(spacing: 0) {
            paletteHeader("Quick Actions")

            paletteRow(icon: "trash", label: "Clear all network logs", color: DS.Status.error) {
                networkStore.clearAll()
                dismiss()
            }
            paletteRow(icon: "trash", label: "Clear all app logs", color: DS.Status.error) {
                logStore.clearAll()
                dismiss()
            }

            if let active = envStore.environments.first(where: { $0.id == envStore.activeEnvironmentId }) {
                paletteRow(icon: "server.rack", label: "Environment: \(active.name)", color: DS.Accent.primary) {
                    onNavigate(.rules)
                    dismiss()
                }
            }

            ForEach(actionStore.actions.prefix(3)) { action in
                paletteRow(icon: action.icon, label: action.title, color: DS.Status.info) {
                    action.handler()
                    DS.hapticNotify(.success)
                    dismiss()
                }
            }
        }
    }

    // MARK: - Navigation

    private var navigationSection: some View {
        VStack(spacing: 0) {
            paletteHeader("Go To")

            ForEach(V2Section.allCases) { section in
                paletteRow(icon: section.icon, label: section.rawValue, color: DS.Text.secondary) {
                    onNavigate(section)
                    dismiss()
                }
            }
        }
    }

    // MARK: - Recent Requests

    private var recentRequestsSection: some View {
        let recent = Array(networkStore.requests.prefix(5))
        return Group {
            if !recent.isEmpty {
                VStack(spacing: 0) {
                    paletteHeader("Recent Requests")

                    ForEach(recent) { req in
                        requestRow(req)
                    }
                }
            }
        }
    }

    // MARK: - Search Results

    @ViewBuilder
    private var searchResults: some View {
        let q = query.lowercased()

        // Network matches
        let matchedRequests = networkStore.requests.filter { req in
            req.url.lowercased().contains(q)
            || req.method.lowercased().contains(q)
            || req.host.lowercased().contains(q)
            || req.path.lowercased().contains(q)
            || (req.statusCode.map { String($0) } ?? "").contains(q)
        }

        // Log matches
        let matchedLogs = logStore.entries.filter { entry in
            entry.message.lowercased().contains(q)
            || entry.level.rawValue.lowercased().contains(q)
            || entry.category.rawValue.lowercased().contains(q)
        }

        // Action matches
        let matchedActions = actionStore.actions.filter { $0.title.lowercased().contains(q) }

        if matchedRequests.isEmpty && matchedLogs.isEmpty && matchedActions.isEmpty {
            V2EmptyState(icon: "magnifyingglass", title: "No results", subtitle: "Try a different search term")
                .frame(height: 200)
        } else {
            if !matchedRequests.isEmpty {
                paletteHeader("Requests (\(matchedRequests.count))")
                ForEach(Array(matchedRequests.prefix(10))) { req in
                    requestRow(req)
                }
            }

            if !matchedLogs.isEmpty {
                paletteHeader("Logs (\(matchedLogs.count))")
                ForEach(Array(matchedLogs.prefix(8))) { entry in
                    logRow(entry)
                }
            }

            if !matchedActions.isEmpty {
                paletteHeader("Actions")
                ForEach(matchedActions) { action in
                    paletteRow(icon: action.icon, label: action.title, color: DS.Status.info) {
                        action.handler()
                        DS.hapticNotify(.success)
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Row Builders

    private func requestRow(_ req: NetworkRequestModel) -> some View {
        Button {
            onNavigate(.network)
            dismiss()
        } label: {
            HStack(spacing: DS.Space.m) {
                V2MethodBadge(method: req.method)

                Text(req.path)
                    .font(DS.Font.monoSmall)
                    .foregroundColor(DS.Text.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                V2StatusBadge(code: req.statusCode)

                V2Duration(duration: req.duration)
            }
            .padding(.horizontal, DS.Space.xl)
            .padding(.vertical, DS.Space.m)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func logRow(_ entry: LogEntry) -> some View {
        Button {
            onNavigate(.logs)
            dismiss()
        } label: {
            HStack(spacing: DS.Space.m) {
                StatusDot(color: DS.logLevelColor(entry.level))

                Text(entry.level.rawValue)
                    .font(DS.Font.mono(10, weight: .bold))
                    .foregroundColor(DS.logLevelColor(entry.level))
                    .frame(width: 36)

                Text(entry.message)
                    .font(DS.Font.monoSmall)
                    .foregroundColor(DS.Text.primary)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, DS.Space.xl)
            .padding(.vertical, DS.Space.m)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func paletteRow(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DS.Space.l) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 20)

                Text(label)
                    .font(DS.Font.body)
                    .foregroundColor(DS.Text.primary)

                Spacer()

                Image(systemName: "return")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(DS.Text.disabled)
            }
            .padding(.horizontal, DS.Space.xl)
            .padding(.vertical, DS.Space.m + 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func paletteHeader(_ title: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(DS.Font.micro)
                .foregroundColor(DS.Text.tertiary)
                .tracking(0.5)
            Spacer()
        }
        .padding(.horizontal, DS.Space.xl)
        .padding(.top, DS.Space.l)
        .padding(.bottom, DS.Space.s)
    }

    // MARK: - Helpers

    private func dismiss() {
        isFocused = false
        withAnimation(DS.smooth) { isPresented = false }
    }
}
