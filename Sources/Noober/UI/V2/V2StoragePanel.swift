import SwiftUI

// MARK: - Storage Panel

struct V2StoragePanel: View {

    @StateObject private var userDefaultsStore = UserDefaultsStore.shared
    @StateObject private var keychainStore = KeychainStore.shared

    @State private var activeTab: StorageTab = .userDefaults
    @State private var searchText = ""

    enum StorageTab: String, CaseIterable {
        case userDefaults = "Defaults"
        case keychain     = "Keychain"
        case appInfo      = "App Info"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab strip
            tabStrip

            // Search (for defaults + keychain)
            if activeTab != .appInfo {
                V2SearchField(text: $searchText, placeholder: "Filter \(activeTab.rawValue.lowercased())...")
                    .padding(.horizontal, DS.Space.xl)
                    .padding(.vertical, DS.Space.m)
            }

            V2Separator()

            // Content
            contentArea
        }
        .background(DS.Background.primary)
    }

    // MARK: - Tab Strip

    private var tabStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Space.xs) {
                ForEach(StorageTab.allCases, id: \.self) { tab in
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
        case .userDefaults: userDefaultsList
        case .keychain:     keychainList
        case .appInfo:      appInfoList
        }
    }

    // MARK: - UserDefaults

    private var filteredDefaults: [UserDefaultsEntry] {
        if searchText.isEmpty { return userDefaultsStore.entries }
        let q = searchText.lowercased()
        return userDefaultsStore.entries.filter {
            $0.key.lowercased().contains(q) || $0.displayValue.lowercased().contains(q)
        }
    }

    private var userDefaultsList: some View {
        ScrollView {
            if filteredDefaults.isEmpty {
                V2EmptyState(icon: "tray", title: "No entries", subtitle: searchText.isEmpty ? nil : "No matches")
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(filteredDefaults) { entry in
                        defaultsRow(entry)
                    }
                }
            }
        }
    }

    private func defaultsRow(_ entry: UserDefaultsEntry) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            HStack(spacing: DS.Space.m) {
                V2Tag(text: entry.valueType.rawValue.prefix(4).uppercased(), color: typeColor(entry.valueType))

                Text(entry.key)
                    .font(DS.Font.mono(11, weight: .medium))
                    .foregroundColor(DS.Text.primary)
                    .lineLimit(1)

                Spacer()
            }

            Text(entry.displayValue)
                .font(DS.Font.monoMicro)
                .foregroundColor(DS.Text.secondary)
                .lineLimit(2)
        }
        .padding(.horizontal, DS.Space.xl)
        .padding(.vertical, DS.Space.m)
        .contentShape(Rectangle())
        .onTapGesture {
            UIPasteboard.general.string = "\(entry.key): \(entry.displayValue)"
            DS.hapticNotify(.success)
        }
        .overlay(alignment: .bottom) { V2Separator(leading: DS.Space.xl) }
    }

    // MARK: - Keychain

    private var filteredKeychain: [KeychainEntry] {
        if searchText.isEmpty { return keychainStore.entries }
        let q = searchText.lowercased()
        return keychainStore.entries.filter {
            $0.service.lowercased().contains(q)
            || $0.account.lowercased().contains(q)
            || ($0.label ?? "").lowercased().contains(q)
        }
    }

    private var keychainList: some View {
        ScrollView {
            if filteredKeychain.isEmpty {
                V2EmptyState(icon: "key", title: "No keychain items", subtitle: searchText.isEmpty ? nil : "No matches")
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(filteredKeychain) { entry in
                        keychainRow(entry)
                    }
                }
            }
        }
    }

    private func keychainRow(_ entry: KeychainEntry) -> some View {
        HStack(spacing: DS.Space.l) {
            V2Tag(
                text: entry.classAbbreviation,
                color: entry.itemClass == .genericPassword ? DS.Status.info : DS.Status.purple
            )

            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text(entry.service)
                    .font(DS.Font.mono(11, weight: .medium))
                    .foregroundColor(DS.Text.primary)
                    .lineLimit(1)
                Text(entry.account)
                    .font(DS.Font.monoMicro)
                    .foregroundColor(DS.Text.secondary)
                    .lineLimit(1)
                if !entry.modifiedText.isEmpty {
                    Text(entry.modifiedText)
                        .font(DS.Font.monoMicro)
                        .foregroundColor(DS.Text.disabled)
                }
            }

            Spacer()
        }
        .padding(.horizontal, DS.Space.xl)
        .padding(.vertical, DS.Space.m)
        .overlay(alignment: .bottom) { V2Separator(leading: DS.Space.xl) }
    }

    // MARK: - App Info

    private var appInfoList: some View {
        AppInfoView()
    }

    // MARK: - Helpers

    private func tabCount(_ tab: StorageTab) -> Int? {
        switch tab {
        case .userDefaults: return userDefaultsStore.entries.count > 0 ? userDefaultsStore.entries.count : nil
        case .keychain:     return keychainStore.entries.count > 0 ? keychainStore.entries.count : nil
        case .appInfo:      return nil
        }
    }

    private func typeColor(_ type: UserDefaultsEntry.ValueType) -> Color {
        switch type {
        case .string:              return DS.Status.info
        case .int, .double:        return DS.Status.success
        case .bool:                return DS.Status.warning
        case .array, .dictionary:  return DS.Status.purple
        case .data:                return DS.Text.tertiary
        case .date:                return DS.Status.warning
        case .unknown:             return DS.Text.tertiary
        }
    }
}
