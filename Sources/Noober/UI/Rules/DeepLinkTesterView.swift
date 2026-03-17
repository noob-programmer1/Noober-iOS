import SwiftUI

struct DeepLinkTesterView: View {

    @ObservedObject var store: DeepLinkStore
    @State private var urlText = ""

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .medium
        return f
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            inputBar
            Divider()
            if store.favorites.isEmpty && store.history.isEmpty {
                emptyState
            } else {
                linkList
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                TextField("Enter deep link URL...", text: $urlText)
                    .font(.system(size: 15))
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .onSubmit { fire() }
                if !urlText.isEmpty {
                    Button { urlText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(uiColor: .tertiarySystemFill)))

            Button { fire() } label: {
                Text("Fire")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : NooberTheme.accent))
            }
            .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    // MARK: - List

    private var linkList: some View {
        List {
            if !store.favorites.isEmpty {
                Section {
                    ForEach(store.favorites) { entry in
                        DeepLinkRow(entry: entry, formatter: Self.dateTimeFormatter) {
                            reFire(entry)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                NooberTheme.hapticMedium()
                                withAnimation { store.deleteEntry(id: entry.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                NooberTheme.hapticLight()
                                withAnimation { store.toggleFavorite(id: entry.id) }
                            } label: {
                                Label("Unfavorite", systemImage: "star.slash")
                            }
                            .tint(NooberTheme.warning)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                        .listRowSeparator(.hidden)
                    }
                } header: {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(NooberTheme.warning)
                        Text("Favorites")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 16)
                }
            }

            if !store.history.isEmpty {
                Section {
                    ForEach(store.history) { entry in
                        DeepLinkRow(entry: entry, formatter: Self.timeFormatter) {
                            reFire(entry)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                NooberTheme.hapticMedium()
                                withAnimation { store.deleteEntry(id: entry.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                NooberTheme.hapticLight()
                                withAnimation { store.toggleFavorite(id: entry.id) }
                            } label: {
                                Label(entry.isFavorite ? "Unfavorite" : "Favorite",
                                      systemImage: entry.isFavorite ? "star.slash" : "star.fill")
                            }
                            .tint(NooberTheme.warning)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                        .listRowSeparator(.hidden)
                    }
                } header: {
                    HStack {
                        Text("History")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        if !store.history.isEmpty {
                            Button {
                                NooberTheme.hapticMedium()
                                withAnimation { store.clearHistory() }
                            } label: {
                                Text("Clear All")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(NooberTheme.error)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle().fill(Color(uiColor: .tertiarySystemFill)).frame(width: 80, height: 80)
                Image(systemName: "link.badge.plus")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            Text("No Deep Links")
                .font(.system(size: 17, weight: .semibold)).foregroundColor(.secondary)
            Text("Enter a URL scheme or universal link\nand tap Fire to test it.")
                .font(.system(size: 14)).foregroundColor(Color(uiColor: .tertiaryLabel)).multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func fire() {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        NooberTheme.hapticMedium()
        store.fireDeepLink(trimmed)
        urlText = ""
    }

    private func reFire(_ entry: DeepLinkEntry) {
        NooberTheme.hapticMedium()
        store.fireDeepLink(entry.url)
    }
}

// MARK: - Row

private struct DeepLinkRow: View {
    let entry: DeepLinkEntry
    let formatter: DateFormatter
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(resultColor)
                    .frame(width: 4)
                    .padding(.vertical, 4)

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 4) {
                            if entry.isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(NooberTheme.warning)
                            }
                            resultBadge
                            Spacer()
                            Text(formatter.string(from: entry.timestamp))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Color(uiColor: .tertiaryLabel))
                        }
                        Text(entry.url)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                }
                .padding(.leading, 10)
                .padding(.vertical, 8)
            }
            .padding(.leading, 16)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { Divider().padding(.leading, 30) }
    }

    private var resultColor: Color {
        switch entry.lastResult {
        case .opened: return NooberTheme.success
        case .failed:  return NooberTheme.error
        case .none:    return Color(uiColor: .tertiaryLabel)
        }
    }

    @ViewBuilder
    private var resultBadge: some View {
        switch entry.lastResult {
        case .opened:
            TypeBadge(text: "OPENED", color: NooberTheme.success)
        case .failed:
            TypeBadge(text: "FAILED", color: NooberTheme.error)
        case .none:
            TypeBadge(text: "PENDING", color: Color(uiColor: .tertiaryLabel))
        }
    }
}
