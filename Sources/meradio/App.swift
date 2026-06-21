import SwiftUI

/// Owns all long-lived stores and the scheduler; constructed once at launch.
@MainActor
final class AppState: ObservableObject {
    let store: StationStore
    let player: RadioPlayer
    let favorites: Favorites
    let settings: SettingsStore
    let scheduler: Scheduler

    init() {
        let store = StationStore()
        let player = RadioPlayer()
        let settings = SettingsStore()
        self.store = store
        self.player = player
        self.favorites = Favorites()
        self.settings = settings
        self.scheduler = Scheduler(store: store, settings: settings, player: player)

        player.onStationPlayed = { station in
            settings.recordLastPlayed(station.id)
        }
        scheduler.start()
    }
}

@main
struct MeradioApp: App {
    @StateObject private var app = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarRootView()
                .environmentObject(app.store)
                .environmentObject(app.player)
                .environmentObject(app.favorites)
                .environmentObject(app.settings)
        } label: {
            MenuBarLabel(player: app.player)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Menu bar icon that reflects current playback state.
private struct MenuBarLabel: View {
    @ObservedObject var player: RadioPlayer

    var body: some View {
        Image(systemName: player.isPlaying
              ? "dot.radiowaves.left.and.right"
              : "radio")
    }
}
