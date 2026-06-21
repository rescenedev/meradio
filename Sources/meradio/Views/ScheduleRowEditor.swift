import SwiftUI

/// Inline editor for a single schedule entry.
struct ScheduleRowEditor: View {
    @Binding var schedule: Schedule
    let stations: [Station]
    let onDelete: () -> Void

    private static let weekdayPresets: [(String, Set<Int>)] = [
        ("매일", []),
        ("평일", [2, 3, 4, 5, 6]),
        ("주말", [1, 7]),
    ]

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Toggle("", isOn: $schedule.enabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.mini)

                DatePicker("", selection: timeBinding, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .frame(width: 90)

                Picker("", selection: $schedule.action) {
                    Text("켜기").tag(Schedule.Action.turnOn)
                    Text("끄기").tag(Schedule.Action.turnOff)
                }
                .labelsHidden()
                .frame(width: 64)

                Spacer(minLength: 0)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(Slate.s500)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Picker("", selection: weekdayPresetBinding) {
                    ForEach(Self.weekdayPresets, id: \.0) { preset in
                        Text(preset.0).tag(preset.1)
                    }
                }
                .labelsHidden()
                .frame(width: 90)

                if schedule.action == .turnOn {
                    Picker("", selection: $schedule.onSource) {
                        Text("랜덤").tag(Schedule.OnSource.random)
                        Text("마지막").tag(Schedule.OnSource.lastPlayed)
                        Text("고정").tag(Schedule.OnSource.fixed)
                    }
                    .labelsHidden()
                    .frame(width: 72)

                    if schedule.onSource == .fixed {
                        Picker("", selection: fixedStationBinding) {
                            Text("선택").tag(String?.none)
                            ForEach(stations) { station in
                                Text(station.name).tag(String?.some(station.id))
                            }
                        }
                        .labelsHidden()
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .tint(Slate.accent)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Slate.s900.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(Slate.s700.opacity(0.5), lineWidth: 0.5)
                )
        )
    }

    private var timeBinding: Binding<Date> {
        Binding {
            var comps = DateComponents()
            comps.hour = schedule.hour
            comps.minute = schedule.minute
            return Calendar.current.date(from: comps) ?? Date()
        } set: { newValue in
            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            schedule.hour = comps.hour ?? schedule.hour
            schedule.minute = comps.minute ?? schedule.minute
        }
    }

    private var weekdayPresetBinding: Binding<Set<Int>> {
        Binding {
            schedule.weekdays
        } set: { schedule.weekdays = $0 }
    }

    private var fixedStationBinding: Binding<String?> {
        Binding { schedule.stationID } set: { schedule.stationID = $0 }
    }
}
