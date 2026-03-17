import SwiftUI
import UIKit

struct KeychainListView: View {

    @ObservedObject var store: KeychainStore
    @State private var searchText = ""
    @State private var editingEntry: KeychainEntry?
    @State private var showAddSheet = false
    @State private var showClearAlert = false
    @State private var selectedClassFilter: KeychainEntry.ItemClass?
    @State private var revealedValue: (entry: KeychainEntry, value: String)?
    @State private var copiedKey: String?

    private var filtered: [KeychainEntry] {
        var result = store.entries

        // Class filter
        if let classFilter = selectedClassFilter {
            result = result.filter { $0.itemClass == classFilter }
        }

        // Search filter
        if !searchText.isEmpty {
            result = result.filter {
                $0.account.localizedCaseInsensitiveContains(searchText) ||
                $0.service.localizedCaseInsensitiveContains(searchText) ||
                ($0.label ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    private var genericCount: Int {
        store.entries.filter { $0.itemClass == .genericPassword }.count
    }

    private var internetCount: Int {
        store.entries.filter { $0.itemClass == .internetPassword }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            NooberSearchBar(text: $searchText, placeholder: "Search account, service...")
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    classFilterChip("All", count: store.entries.count, filter: nil)
                    classFilterChip("Generic", count: genericCount, filter: .genericPassword)
                    classFilterChip("Internet", count: internetCount, filter: .internetPassword)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }

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
            KeychainEditView(store: store, existingEntry: nil)
        }
        .sheet(item: $editingEntry) { entry in
            KeychainEditView(store: store, existingEntry: entry)
        }
        .alert("Keychain Value", isPresented: Binding(
            get: { revealedValue != nil },
            set: { if !$0 { revealedValue = nil } }
        )) {
            Button("Copy") {
                if let val = revealedValue?.value {
                    UIPasteboard.general.string = val
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            if let rv = revealedValue {
                Text("\(rv.entry.account)\n\n\(rv.value)")
            }
        }
        .alert("Clear All Keychain Items?", isPresented: $showClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) { store.clearAll() }
        } message: {
            Text("This will remove all generic and internet password items. This cannot be undone.")
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Button { showAddSheet = true } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                    Divider()
                    Button(role: .destructive) { showClearAlert = true } label: {
                        Label("Clear All", systemImage: "trash")
                    }
                    .disabled(store.entries.isEmpty)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundColor(NooberTheme.accent)
                }
            }
        }
    }

    // MARK: - Filter Chip

    private func classFilterChip(_ title: String, count: Int, filter: KeychainEntry.ItemClass?) -> some View {
        let isSelected = selectedClassFilter == filter
        return Button {
            withAnimation(.spring(response: 0.25)) { selectedClassFilter = filter }
        } label: {
            HStack(spacing: 4) {
                Text(title)
                Text("\(count)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(isSelected ? NooberTheme.accent : Color(uiColor: .tertiarySystemFill))
            )
        }
    }

    // MARK: - List

    private var listContent: some View {
        List {
            ForEach(filtered) { entry in
                KeychainRowView(entry: entry, copiedKey: copiedKey)
                    .contentShape(Rectangle())
                    .onTapGesture { editingEntry = entry }
                    .contextMenu {
                        Button {
                            let val = store.retrieveValue(for: entry) ?? "(unable to read)"
                            revealedValue = (entry, val)
                        } label: {
                            Label("View Value", systemImage: "eye")
                        }
                        Button { editingEntry = entry } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button {
                            let val = store.retrieveValue(for: entry) ?? ""
                            UIPasteboard.general.string = val
                            NooberTheme.hapticSuccess()
                            withAnimation { copiedKey = entry.id }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation { copiedKey = nil }
                            }
                        } label: {
                            Label("Copy Value", systemImage: "doc.on.doc")
                        }
                        Divider()
                        Button(role: .destructive) { store.deleteEntry(entry) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            NooberTheme.hapticMedium()
                            store.deleteEntry(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
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
                    .fill(Color(uiColor: .tertiarySystemFill))
                    .frame(width: 80, height: 80)
                Image(systemName: "key")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            Text("No Keychain Items")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.secondary)
            Text("Generic and Internet password items\nwill appear here.")
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
                .multilineTextAlignment(.center)
            Button { showAddSheet = true } label: {
                Text("Add Item")
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
                .foregroundColor(Color(uiColor: .tertiaryLabel))
            Text("No results")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Row View

private struct KeychainRowView: View {
    let entry: KeychainEntry
    let copiedKey: String?

    var body: some View {
        HStack(spacing: 10) {
            // Color strip
            RoundedRectangle(cornerRadius: 2)
                .fill(NooberTheme.keychainClassColor(entry.itemClass))
                .frame(width: 3, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    TypeBadge(
                        text: entry.classAbbreviation,
                        color: NooberTheme.keychainClassColor(entry.itemClass)
                    )

                    Text(entry.account)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    Text(entry.service)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    if !entry.modifiedText.isEmpty {
                        Text("·")
                            .font(.system(size: 11))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                        Text(entry.modifiedText)
                            .font(.system(size: 10))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                }
            }

            Spacer(minLength: 0)

            if copiedKey == entry.id {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(NooberTheme.success)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
        }
        .padding(.vertical, 4)
    }
}
