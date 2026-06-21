import SwiftUI

/// Root popover content for the menu bar: tabs, search, station list, controls.
struct MenuBarRootView: View {
    @EnvironmentObject var store: StationStore
    @EnvironmentObject var player: RadioPlayer
    @EnvironmentObject var favorites: Favorites
    @EnvironmentObject var settings: SettingsStore

    enum Tab: String, CaseIterable, Identifiable {
        case favorites, recent, all
        var id: String { rawValue }
        var label: String {
            switch self {
            case .favorites: return "즐겨찾기"
            case .recent: return "최근"
            case .all: return "전체"
            }
        }
        var icon: String {
            switch self {
            case .favorites: return "star.fill"
            case .recent: return "clock.fill"
            case .all: return "square.grid.2x2.fill"
            }
        }
    }

    @State private var query = ""
    @State private var tab: Tab = .all
    @State private var showSettings = false

    var body: some View {
        content
            .frame(width: 340)
            .background(Slate.background)
            .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var content: some View {
        if showSettings {
            SettingsView(onClose: { showSettings = false })
        } else {
            mainView.frame(height: 480)
        }
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            titleBar
            searchField
            tabBar
            stationList
            if player.currentStation != nil {
                NowPlayingBar(player: player)
            }
            footer
        }
    }

    // MARK: - Title bar

    private var titleBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Slate.accent)
            Text("meradio")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Slate.textPrimary)
            Spacer()
            Text("\(store.stations.count)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Slate.textTertiary)
                + Text(" 방송국")
                .font(.system(size: 11))
                .foregroundStyle(Slate.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    // MARK: - Search

    private var searchField: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Slate.s500)
                .font(.system(size: 12, weight: .medium))
            TextField("방송국 검색", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(Slate.textPrimary)
            if !query.isEmpty {
                Button(action: { query = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Slate.s500)
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Slate.s800.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(Slate.s700.opacity(0.6), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 12)
    }

    // MARK: - Tabs

    private var tabBar: some View {
        HStack(spacing: 3) {
            ForEach(Tab.allCases) { t in
                tabButton(t)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Slate.s900.opacity(0.6))
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func tabButton(_ t: Tab) -> some View {
        let selected = tab == t
        return Button {
            withAnimation(.easeOut(duration: 0.15)) { tab = t }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: t.icon)
                    .font(.system(size: 9, weight: .semibold))
                Text(t.label)
                    .font(.system(size: 12, weight: selected ? .semibold : .medium))
            }
            .foregroundStyle(selected ? Slate.s50 : Slate.s400)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(selected ? Slate.s700 : .clear)
                    .shadow(color: selected ? .black.opacity(0.2) : .clear, radius: 2, y: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - List

    private var displayedStations: [Station] {
        let base: [Station]
        switch tab {
        case .favorites:
            base = store.stations.filter { favorites.contains($0.id) }
        case .recent:
            base = settings.recentStationIDs.compactMap { store.station(withID: $0) }
        case .all:
            base = store.stations
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return base }
        return base.filter {
            $0.name.lowercased().contains(trimmed)
                || ($0.genre?.lowercased().contains(trimmed) ?? false)
                || ($0.frequency?.lowercased().contains(trimmed) ?? false)
        }
    }

    private var stationList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                if let error = store.loadError {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: 0xF87171))
                        .padding()
                }

                let results = displayedStations
                ForEach(results) { row(for: $0) }

                if results.isEmpty && store.loadError == nil {
                    emptyState
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 6)
        }
        .frame(maxHeight: .infinity)
    }

    private var emptyState: some View {
        let icon: String
        let message: String
        if !query.isEmpty {
            icon = "magnifyingglass"
            message = "검색 결과가 없습니다"
        } else {
            switch tab {
            case .favorites:
                icon = "star"
                message = "즐겨찾기한 방송국이 없습니다\n별표를 눌러 추가하세요"
            case .recent:
                icon = "clock"
                message = "최근 재생한 방송국이 없습니다"
            case .all:
                icon = "radio"
                message = "방송국이 없습니다"
            }
        }
        return VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Slate.s600)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(Slate.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 56)
    }

    private func row(for station: Station) -> some View {
        StationRow(
            station: station,
            isPlaying: player.currentStation?.id == station.id && player.state == .playing,
            isConnecting: player.currentStation?.id == station.id && player.state == .connecting,
            isFavorite: favorites.contains(station.id),
            onTap: { player.toggle(station) },
            onToggleFavorite: { favorites.toggle(station.id) }
        )
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 14) {
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Slate.s400)
            }
            .buttonStyle(.plain)
            .help("설정")

            Button { NSApplication.shared.terminate(nil) } label: {
                Image(systemName: "power")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Slate.s400)
            }
            .buttonStyle(.plain)
            .help("종료")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Slate.s950.opacity(0.5))
    }
}
