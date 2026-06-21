import Foundation

/// Persists startup mode, the pinned/last station, and the schedule list.
@MainActor
final class SettingsStore: ObservableObject {
    @Published var startupMode: StartupMode {
        didSet { UserDefaults.standard.set(startupMode.rawValue, forKey: Keys.startupMode) }
    }
    @Published var fixedStationID: String? {
        didSet { UserDefaults.standard.set(fixedStationID, forKey: Keys.fixedStation) }
    }
    @Published private(set) var lastPlayedStationID: String? {
        didSet { UserDefaults.standard.set(lastPlayedStationID, forKey: Keys.lastPlayed) }
    }
    /// Recently played station IDs, most recent first (capped).
    @Published private(set) var recentStationIDs: [String] {
        didSet { UserDefaults.standard.set(recentStationIDs, forKey: Keys.recents) }
    }
    @Published var schedules: [Schedule] {
        didSet { persistSchedules() }
    }

    private let recentsLimit = 20

    private enum Keys {
        static let startupMode = "startupMode"
        static let fixedStation = "fixedStationID"
        static let lastPlayed = "lastPlayedStationID"
        static let recents = "recentStationIDs"
        static let schedules = "schedules"
    }

    init() {
        let defaults = UserDefaults.standard
        startupMode = StartupMode(rawValue: defaults.string(forKey: Keys.startupMode) ?? "")
            ?? .lastPlayed
        fixedStationID = defaults.string(forKey: Keys.fixedStation)
        lastPlayedStationID = defaults.string(forKey: Keys.lastPlayed)
        recentStationIDs = defaults.stringArray(forKey: Keys.recents) ?? []

        if let data = defaults.data(forKey: Keys.schedules),
           let decoded = try? JSONDecoder().decode([Schedule].self, from: data) {
            schedules = decoded
        } else {
            schedules = []
        }
    }

    func recordLastPlayed(_ stationID: String) {
        lastPlayedStationID = stationID
        var recents = recentStationIDs
        recents.removeAll { $0 == stationID }
        recents.insert(stationID, at: 0)
        if recents.count > recentsLimit {
            recents = Array(recents.prefix(recentsLimit))
        }
        recentStationIDs = recents
    }

    func addSchedule(_ schedule: Schedule) {
        schedules.append(schedule)
        sortSchedules()
    }

    func removeSchedule(_ id: UUID) {
        schedules.removeAll { $0.id == id }
    }

    func updateSchedule(_ schedule: Schedule) {
        guard let idx = schedules.firstIndex(where: { $0.id == schedule.id }) else { return }
        schedules[idx] = schedule
        sortSchedules()
    }

    private func sortSchedules() {
        schedules.sort { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
    }

    private func persistSchedules() {
        if let data = try? JSONEncoder().encode(schedules) {
            UserDefaults.standard.set(data, forKey: Keys.schedules)
        }
    }
}
