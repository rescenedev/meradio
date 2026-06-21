import Foundation

/// What the app should do with playback when it launches.
enum StartupMode: String, Codable, CaseIterable, Identifiable {
    case off          // do nothing
    case random       // play a random station
    case lastPlayed   // resume the last station that was playing
    case fixed        // always play one pinned station

    var id: String { rawValue }

    var label: String {
        switch self {
        case .off: return "끄기"
        case .random: return "랜덤 재생"
        case .lastPlayed: return "마지막 방송"
        case .fixed: return "고정 방송국"
        }
    }
}

/// A single scheduled action that fires at a given local time.
struct Schedule: Codable, Identifiable, Hashable {
    enum Action: String, Codable {
        case turnOn
        case turnOff
    }

    /// How the "turn on" target station is chosen.
    enum OnSource: String, Codable {
        case random
        case lastPlayed
        case fixed
    }

    var id: UUID
    var enabled: Bool
    var hour: Int          // 0...23
    var minute: Int        // 0...59
    /// Calendar weekday numbers (1 = Sunday ... 7 = Saturday). Empty == every day.
    var weekdays: Set<Int>
    var action: Action
    var onSource: OnSource
    var stationID: String?  // used when onSource == .fixed

    init(
        id: UUID = UUID(),
        enabled: Bool = true,
        hour: Int,
        minute: Int,
        weekdays: Set<Int> = [],
        action: Action,
        onSource: OnSource = .lastPlayed,
        stationID: String? = nil
    ) {
        self.id = id
        self.enabled = enabled
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
        self.action = action
        self.onSource = onSource
        self.stationID = stationID
    }

    var timeLabel: String {
        String(format: "%02d:%02d", hour, minute)
    }

    var weekdayLabel: String {
        if weekdays.isEmpty || weekdays.count == 7 { return "매일" }
        if weekdays == [2, 3, 4, 5, 6] { return "평일" }
        if weekdays == [1, 7] { return "주말" }
        let names = ["일", "월", "화", "수", "목", "금", "토"]
        return weekdays.sorted().map { names[$0 - 1] }.joined(separator: ",")
    }

    /// True if this schedule should fire on the given weekday (1...7).
    func matches(weekday: Int) -> Bool {
        weekdays.isEmpty || weekdays.contains(weekday)
    }
}
