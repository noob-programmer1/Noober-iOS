import SwiftUI
import UIKit

struct UserDefaultsListView: View {

    @ObservedObject var store: UserDefaultsStore
    @State private var searchText = ""
    @State private var editingEntry: UserDefaultsEntry?
    @State private var showAddSheet = false
    @State private var showClearAlert = false
    @State private var showActionSheet = false
    @State private var copiedKey: String?

    private var filtered: [UserDefaultsEntry] {
        guard !searchText.isEmpty else { return store.entries }
        return store.entries.filter {
            $0.key.localizedCaseInsensitiveContains(searchText) ||
            $0.displayValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            NooberSearchBar(text: $searchText, placeholder: "Search keys, values...")
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

            // Stats bar
            statsBar

            Divider()

            if store.entries.isEmpty {
                emptyState
            } else if filtered.isEmpty {
                noResultsState
            } else {
                listContent
            }
        }
        .onAppear { store.refresh() }
        .sheet(isPresented: $showAddSheet) {
            UserDefaultsEditView(store: store, existingEntry: nil)
        }
        .sheet(item: $editingEntry) { entry in
            UserDefaultsEditView(store: store, existingEntry: entry)
        }
        .alert(isPresented: $showClearAlert) {
            Alert(
                title: Text("Clear All UserDefaults?"),
                message: Text("This will remove all non-system UserDefaults entries. This cannot be undone."),
                primaryButton: .destructive(Text("Clear All")) { store.clearAll() },
                secondaryButton: .cancel()
            )
        }
        .navigationBarItems(trailing: moreButton)
    }

    // MARK: - More Button

    @ViewBuilder
    private var moreButton: some View {
        if #available(iOS 14, *) {
            Menu {
                Button { showAddSheet = true } label: {
                    NooberLabel("Add Entry", systemImage: "plus")
                }
                Button { store.shareExport() } label: {
                    NooberLabel("Export JSON", systemImage: "square.and.arrow.up")
                }
                Divider()
                Toggle("Show System Keys", isOn: $store.showSystemKeys)
                Divider()
                NooberDestructiveButton("Clear All", systemImage: "trash") { showClearAlert = true }
                    .disabled(store.entries.isEmpty)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 18))
                    .foregroundColor(NooberTheme.accent)
            }
        } else {
            Button { showActionSheet = true } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 18))
                    .foregroundColor(NooberTheme.accent)
            }
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(title: Text("Actions"), buttons: [
                    .default(Text("Add Entry")) { showAddSheet = true },
                    .default(Text("Export JSON")) { store.shareExport() },
                    .default(Text(store.showSystemKeys ? "Hide System Keys" : "Show System Keys")) {
                        store.showSystemKeys.toggle()
                    },
                    .destructive(Text("Clear All")) { showClearAlert = true },
                    .cancel()
                ])
            }
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Text("\(store.entries.count)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(NooberTheme.accent)
                Text("entries")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            if !searchText.isEmpty {
                HStack(spacing: 4) {
                    Text("\(filtered.count)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(NooberTheme.accent)
                    Text("shown")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            if store.showSystemKeys {
                Text("incl. system")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(NooberTheme.warning)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(NooberTheme.warning.opacity(0.12)))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    // MARK: - List

    private var listContent: some View {
        List {
            ForEach(filtered) { entry in
                UserDefaultsRowView(entry: entry, copiedKey: copiedKey)
                    .contentShape(Rectangle())
                    .onTapGesture { editingEntry = entry }
                    .contextMenu {
                        Button { editingEntry = entry } label: {
                            NooberLabel("Edit", systemImage: "pencil")
                        }
                        Button {
                            UIPasteboard.general.string = "\(entry.key): \(entry.displayValue)"
                            NooberTheme.hapticSuccess()
                            withAnimation { copiedKey = entry.key }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation { copiedKey = nil }
                            }
                        } label: {
                            NooberLabel("Copy", systemImage: "doc.on.doc")
                        }
                        Button { store.duplicateEntry(entry) } label: {
                            NooberLabel("Duplicate", systemImage: "plus.square.on.square")
                        }
                        Divider()
                        NooberDestructiveButton("Delete", systemImage: "trash") { store.deleteEntry(entry) }
                    }
                    .nooberSwipeAction(edge: .trailing, isDestructive: true, allowsFullSwipe: true, label: "Delete", systemImage: "trash") {
                        NooberTheme.hapticMedium()
                        store.deleteEntry(entry)
                    }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty States

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 80, height: 80)
                Image(systemName: "externaldrive")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            Text("No UserDefaults")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.secondary)
            Text("Entries will appear here once\nyour app writes to UserDefaults.")
                .font(.system(size: 14))
                .foregroundColor(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
            Button { showAddSheet = true } label: {
                Text("Add Entry")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(NooberTheme.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(NooberTheme.accent.opacity(0.1)))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28, weight: .thin))
                .foregroundColor(Color(.tertiaryLabel))
            Text("No results for \"\(searchText)\"")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Row View

private struct UserDefaultsRowView: View {
    let entry: UserDefaultsEntry
    let copiedKey: String?

    var body: some View {
        HStack(spacing: 10) {
            // Color strip
            RoundedRectangle(cornerRadius: 2)
                .fill(NooberTheme.userDefaultsTypeColor(entry.valueType))
                .frame(width: 3, height: 38)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    TypeBadge(
                        text: entry.valueType.rawValue,
                        color: NooberTheme.userDefaultsTypeColor(entry.valueType)
                    )

                    Text(entry.key)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                Text(entry.displayValue)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            if copiedKey == entry.key {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(NooberTheme.success)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .padding(.vertical, 4)
    }
}
