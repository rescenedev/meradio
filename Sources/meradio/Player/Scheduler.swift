import Foundation

/// Fires scheduled turn-on / turn-off actions and handles startup autoplay.
@MainActor
final class Scheduler: ObservableObject {
    private let store: StationStore
    private let settings: SettingsStore
    private let player: RadioPlayer

    private var timer: Timer?
    /// Guards against firing the same schedule twice within one minute.
    private var lastFiredKey: [UUID: String] = [:]

    init(store: StationStore, settings: SettingsStore, player: RadioPlayer) {
        self.store = store
        self.settings = settings
        self.player = player
    }

    // MARK: - Lifecycle

    func start() {
        runStartupMode()
        let timer = Timer(timeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Startup

    private func runStartupMode() {
        switch settings.startupMode {
        case .off:
            return
        case .random:
            playRandom()
        case .lastPlayed:
            playLast()
        case .fixed:
            playFixed(settings.fixedStationID)
        }
    }

    // MARK: - Tick

    private func tick() {
        let now = Date()
        let comps = Calendar.current.dateComponents([.hour, .minute, .weekday], from: now)
        guard let hour = comps.hour, let minute = comps.minute, let weekday = comps.weekday else {
            return
        }
        let minuteKey = "\(hour):\(minute)"

        for schedule in settings.schedules where schedule.enabled {
            guard schedule.hour == hour, schedule.minute == minute else { continue }
            guard schedule.matches(weekday: weekday) else { continue }
            guard lastFiredKey[schedule.id] != minuteKey else { continue }
            lastFiredKey[schedule.id] = minuteKey
            fire(schedule)
        }
    }

    private func fire(_ schedule: Schedule) {
        switch schedule.action {
        case .turnOff:
            player.stop()
        case .turnOn:
            switch schedule.onSource {
            case .random: playRandom()
            case .lastPlayed: playLast()
            case .fixed: playFixed(schedule.stationID)
            }
        }
    }

    // MARK: - Resolution helpers

    private func playRandom() {
        guard let station = store.stations.randomElement() else { return }
        player.play(station)
    }

    private func playLast() {
        if let id = settings.lastPlayedStationID, let station = store.station(withID: id) {
            player.play(station)
        } else {
            playRandom()
        }
    }

    private func playFixed(_ id: String?) {
        if let id, let station = store.station(withID: id) {
            player.play(station)
        }
    }
}
