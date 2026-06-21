import SwiftUI

/// Preferences pane: startup mode and scheduled on/off actions.
struct SettingsView: View {
    @EnvironmentObject var store: StationStore
    @EnvironmentObject var settings: SettingsStore
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            VStack(alignment: .leading, spacing: 16) {
                startupSection
                scheduleSection
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var header: some View {
        ZStack {
            Text("설정")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Slate.textPrimary)
            HStack {
                Button(action: onClose) {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("뒤로")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(Slate.accent)
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Startup

    private var startupSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("시작 모드", icon: "power")

            Picker("", selection: $settings.startupMode) {
                ForEach(StartupMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .tint(Slate.accent)

            if settings.startupMode == .fixed {
                Picker("고정 방송국", selection: fixedBinding) {
                    Text("선택 안 함").tag(String?.none)
                    ForEach(store.stations) { station in
                        Text(station.name).tag(String?.some(station.id))
                    }
                }
                .pickerStyle(.menu)
                .tint(Slate.accent)
                .font(.system(size: 12))
            }

            Text(startupHint)
                .font(.system(size: 11))
                .foregroundStyle(Slate.textTertiary)
        }
        .padding(12)
        .background(card)
    }

    private var startupHint: String {
        switch settings.startupMode {
        case .off: return "앱을 실행해도 자동으로 재생하지 않습니다."
        case .random: return "앱 실행 시 무작위 방송국을 재생합니다."
        case .lastPlayed: return "앱 실행 시 마지막으로 들었던 방송을 재생합니다."
        case .fixed: return "앱 실행 시 지정한 방송국을 재생합니다."
        }
    }

    // MARK: - Schedules

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionTitle("예약 켜기 / 끄기", icon: "alarm")
                Spacer()
                Button(action: addSchedule) {
                    HStack(spacing: 3) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text("추가")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Slate.s950)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Slate.accent))
                }
                .buttonStyle(.plain)
            }

            if settings.schedules.isEmpty {
                Text("예약된 항목이 없습니다.\n특정 시간에 라디오를 켜거나 끌 수 있습니다.")
                    .font(.system(size: 11))
                    .foregroundStyle(Slate.textTertiary)
                    .padding(.vertical, 6)
            } else {
                ForEach($settings.schedules) { $schedule in
                    ScheduleRowEditor(
                        schedule: $schedule,
                        stations: store.stations,
                        onDelete: { settings.removeSchedule(schedule.id) }
                    )
                }
            }
        }
        .padding(12)
        .background(card)
    }

    private func addSchedule() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let schedule = Schedule(
            hour: comps.hour ?? 8,
            minute: comps.minute ?? 0,
            action: .turnOn,
            onSource: .lastPlayed
        )
        settings.addSchedule(schedule)
    }

    // MARK: - Helpers

    private func sectionTitle(_ text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Slate.s500)
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Slate.s300)
        }
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Slate.s800.opacity(0.45))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Slate.s700.opacity(0.5), lineWidth: 0.5)
            )
    }

    private var fixedBinding: Binding<String?> {
        Binding { settings.fixedStationID } set: { settings.fixedStationID = $0 }
    }
}
