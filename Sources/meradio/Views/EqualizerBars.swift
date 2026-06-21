import SwiftUI

/// Animated equalizer bars shown for the currently playing station.
struct EqualizerBars: View {
    var color: Color = Slate.accent
    var animating: Bool = true

    private let bars = 4
    @State private var phase = false

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<bars, id: \.self) { i in
                Capsule()
                    .fill(color)
                    .frame(width: 2.5, height: barHeight(i))
            }
        }
        .frame(height: 14, alignment: .center)
        .onAppear { phase = animating }
        .onChange(of: animating) { _, newValue in phase = newValue }
        .animation(
            animating
                ? .easeInOut(duration: 0.45).repeatForever(autoreverses: true)
                : .default,
            value: phase
        )
    }

    private func barHeight(_ index: Int) -> CGFloat {
        guard animating else { return 4 }
        let lows: [CGFloat] = [4, 7, 5, 6]
        let highs: [CGFloat] = [13, 10, 14, 9]
        return phase ? highs[index % highs.count] : lows[index % lows.count]
    }
}
