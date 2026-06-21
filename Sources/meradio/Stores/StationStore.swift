import Foundation

/// Loads the bundled station catalog and exposes filtering helpers.
@MainActor
final class StationStore: ObservableObject {
    @Published private(set) var stations: [Station] = []
    @Published var loadError: String?

    init() {
        load()
    }

    private func load() {
        // Prefer the app bundle's Resources (release .app); fall back to the
        // SwiftPM module bundle for `swift run` during development.
        let url = Bundle.main.url(forResource: "stations", withExtension: "json")
            ?? Bundle.module.url(forResource: "stations", withExtension: "json")
        guard let url else {
            loadError = "stations.json not found in bundle"
            return
        }
        do {
            let data = try Data(contentsOf: url)
            stations = try JSONDecoder().decode([Station].self, from: data)
        } catch {
            loadError = "Failed to load stations: \(error.localizedDescription)"
        }
    }

    func filtered(by query: String) -> [Station] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return stations }
        let q = trimmed.lowercased()
        return stations.filter {
            $0.name.lowercased().contains(q)
                || ($0.genre?.lowercased().contains(q) ?? false)
                || ($0.frequency?.lowercased().contains(q) ?? false)
        }
    }

    func station(withID id: String) -> Station? {
        stations.first { $0.id == id }
    }
}
