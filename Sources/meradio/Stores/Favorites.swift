import Foundation

/// Persists the user's favorite station IDs in UserDefaults.
@MainActor
final class Favorites: ObservableObject {
    private let key = "favoriteStationIDs"
    @Published private(set) var ids: Set<String>

    init() {
        let stored = UserDefaults.standard.stringArray(forKey: key) ?? []
        ids = Set(stored)
    }

    func contains(_ id: String) -> Bool {
        ids.contains(id)
    }

    func toggle(_ id: String) {
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(Array(ids), forKey: key)
    }
}
