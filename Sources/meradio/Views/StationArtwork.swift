import SwiftUI

/// Rounded station logo with a graceful gradient placeholder fallback.
struct StationArtwork: View {
    let station: Station
    var size: CGFloat = 38
    var corner: CGFloat = 9

    var body: some View {
        Group {
            if let urlString = station.logoURL, let url = URL(string: urlString) {
                AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.2))) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
        )
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [Slate.s700, Slate.s800],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(initial)
                .font(.system(size: size * 0.40, weight: .semibold, design: .rounded))
                .foregroundStyle(Slate.s300)
        }
    }

    private var initial: String {
        let trimmed = station.name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "♪" : String(trimmed.prefix(1)).uppercased()
    }
}
