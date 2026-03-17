import Foundation
import UIKit

@MainActor
final class DeepLinkStore: ObservableObject {

    static let shared = DeepLinkStore()

    @Published private(set) var history: [DeepLinkEntry] = []
    @Published private(set) var favorites: [DeepLinkEntry] = []

    private let historyKey = "com.noober.deeplink.history"
    private let favoritesKey = "com.noober.deeplink.favorites"
    private let maxHistoryCount = 100

    private init() {
        loadData()
    }

    // MARK: - Actions

    func fireDeepLink(_ urlString: String) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let url = URL(string: trimmed) else {
            recordEntry(url: trimmed, result: .failed)
            NooberTheme.hapticError()
            return
        }

        UIApplication.shared.open(url, options: [:]) { [weak self] success in
            Task { @MainActor in
                guard let self else { return }
                let result: DeepLinkResult = success ? .opened : .failed
                self.recordEntry(url: trimmed, result: result)
                if success {
                    NooberTheme.hapticSuccess()
                } else {
                    NooberTheme.hapticError()
                }
            }
        }
    }

    func toggleFavorite(id: UUID) {
        // Check history first
        if let index = history.firstIndex(where: { $0.id == id }) {
            history[index].isFavorite.toggle()
            if history[index].isFavorite {
                favorites.insert(history[index], at: 0)
            } else {
                favorites.removeAll { $0.id == id }
            }
            save()
            return
        }
        // Check favorites
        if let index = favorites.firstIndex(where: { $0.id == id }) {
            let entry = favorites[index]
            favorites.remove(at: index)
            // Also unfavorite in history if present
            if let historyIndex = history.firstIndex(where: { $0.id == entry.id }) {
                history[historyIndex].isFavorite = false
            }
            save()
        }
    }

    func deleteEntry(id: UUID) {
        history.removeAll { $0.id == id }
        favorites.removeAll { $0.id == id }
        save()
    }

    func clearHistory() {
        history.removeAll()
        save()
    }

    // MARK: - Private

    private func recordEntry(url: String, result: DeepLinkResult) {
        var entry = DeepLinkEntry(url: url, timestamp: Date(), lastResult: result)

        // If this URL is already favorited, update the favorite entry too
        if let favIndex = favorites.firstIndex(where: { $0.url == url }) {
            favorites[favIndex].lastResult = result
            favorites[favIndex].timestamp = Date()
            entry.isFavorite = true
        }

        history.insert(entry, at: 0)
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        save()
    }

    // MARK: - Persistence

    private func loadData() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let entries = try? decoder.decode([DeepLinkEntry].self, from: data) {
            history = entries
        }
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let entries = try? decoder.decode([DeepLinkEntry].self, from: data) {
            favorites = entries
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
        if let data = try? encoder.encode(favorites) {
            UserDefaults.standard.set(data, forKey: favoritesKey)
        }
    }
}
