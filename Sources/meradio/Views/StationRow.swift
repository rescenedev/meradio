import SwiftUI

/// A single row in the station list: artwork, name, metadata, favorite star.
struct StationRow: View {
    let station: Station
    let isPlaying: Bool
    let isConnecting: Bool
    let isFavorite: Bool
    let onTap: () -> Void
    let onToggleFavorite: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 11) {
            StationArtwork(station: station, size: 38)
                .overlay(playingOverlay)

            VStack(alignment: .leading, spacing: 2) {
                Text(station.name)
                    .font(.system(size: 13, weight: isPlaying ? .semibold : .medium))
                    .lineLimit(1)
                    .foregroundStyle(isPlaying ? Slate.accent : Slate.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Slate.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 13))
                    .foregroundStyle(isFavorite ? Slate.accent : Slate.s600)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(isFavorite ? "즐겨찾기 해제" : "즐겨찾기 추가")
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(rowFill)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }

    private var rowFill: Color {
        if isPlaying { return Slate.accent.opacity(0.10) }
        return hovering ? Slate.s100.opacity(0.06) : .clear
    }

    @ViewBuilder
    private var playingOverlay: some View {
        if isConnecting {
            ZStack {
                Color.black.opacity(0.45)
                ProgressView()
                    .controlSize(.small)
                    .tint(Slate.s200)
                    .scaleEffect(0.7)
            }
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        } else if isPlaying {
            ZStack {
                Color.black.opacity(0.40)
                EqualizerBars(color: Slate.accent)
            }
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
    }

    private var subtitle: String? {
        [station.frequency, station.genre]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
            .nilIfEmpty
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
