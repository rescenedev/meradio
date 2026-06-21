import SwiftUI

/// Footer card showing the current station, live metadata, and controls.
struct NowPlayingBar: View {
    @ObservedObject var player: RadioPlayer

    var body: some View {
        if let station = player.currentStation {
            HStack(spacing: 11) {
                StationArtwork(station: station, size: 44, corner: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(station.name)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Slate.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: 5) {
                        statusDot
                        Text(statusText)
                            .font(.system(size: 11))
                            .foregroundStyle(Slate.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 6)

                controls(for: station)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Slate.s850)
        }
    }

    @ViewBuilder
    private func controls(for station: Station) -> some View {
        VStack(alignment: .trailing, spacing: 6) {
            Button(action: { player.toggle(station) }) {
                Image(systemName: player.isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Slate.s950)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Slate.accent))
            }
            .buttonStyle(.plain)

            HStack(spacing: 5) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(Slate.s500)
                Slider(value: $player.volume, in: 0...1)
                    .controlSize(.mini)
                    .tint(Slate.accent)
                    .frame(width: 72)
            }
        }
    }

    private var statusDot: some View {
        Circle()
            .fill(dotColor)
            .frame(width: 6, height: 6)
    }

    private var dotColor: Color {
        switch player.state {
        case .playing: return Slate.accent
        case .connecting: return Slate.s400
        case .failed: return Color(hex: 0xF87171)
        case .idle: return Slate.s600
        }
    }

    private var statusText: String {
        switch player.state {
        case .connecting: return "연결 중…"
        case .failed(let message): return message
        case .playing: return player.nowPlaying ?? "재생 중"
        case .idle: return "정지됨"
        }
    }
}
