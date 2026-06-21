import AVFoundation
import Combine
import Foundation

/// Drives AVPlayer for live radio streaming with fallback URL handling
/// and live ICY/ID3 "now playing" metadata extraction.
@MainActor
final class RadioPlayer: NSObject, ObservableObject {
    enum PlaybackState: Equatable {
        case idle
        case connecting
        case playing
        case failed(String)
    }

    @Published private(set) var state: PlaybackState = .idle
    @Published private(set) var currentStation: Station?
    @Published private(set) var nowPlaying: String?
    @Published var volume: Double {
        didSet {
            player?.volume = Float(volume)
            UserDefaults.standard.set(volume, forKey: volumeKey)
        }
    }

    /// Invoked whenever a station starts playing (used to record "last played").
    var onStationPlayed: ((Station) -> Void)?

    private let volumeKey = "playerVolume"
    private var player: AVPlayer?
    private var item: AVPlayerItem?
    private var statusObservation: NSKeyValueObservation?
    private var metadataOutput: AVPlayerItemMetadataOutput?

    /// Remaining stream candidates to try if the current one fails.
    private var pendingCandidates: [URL] = []

    var isPlaying: Bool { state == .playing || state == .connecting }

    override init() {
        let stored = UserDefaults.standard.object(forKey: volumeKey) as? Double
        volume = stored ?? 1.0
        super.init()
    }

    func toggle(_ station: Station) {
        if currentStation?.id == station.id, isPlaying {
            stop()
        } else {
            play(station)
        }
    }

    func play(_ station: Station) {
        stop()
        currentStation = station
        nowPlaying = nil
        onStationPlayed?(station)
        pendingCandidates = station.streamCandidates
        guard !pendingCandidates.isEmpty else {
            state = .failed("재생 가능한 스트림이 없습니다")
            return
        }
        startNextCandidate()
    }

    private func startNextCandidate() {
        guard !pendingCandidates.isEmpty else {
            state = .failed("스트림에 연결할 수 없습니다")
            return
        }
        let url = pendingCandidates.removeFirst()
        state = .connecting

        let asset = AVURLAsset(url: url)
        let newItem = AVPlayerItem(asset: asset)
        item = newItem
        attachMetadataOutput(to: newItem)
        observeStatus(of: newItem)

        let newPlayer = AVPlayer(playerItem: newItem)
        newPlayer.volume = Float(volume)
        newPlayer.automaticallyWaitsToMinimizeStalling = true
        player = newPlayer
        newPlayer.play()
    }

    private func observeStatus(of item: AVPlayerItem) {
        statusObservation?.invalidate()
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] observed, _ in
            Task { @MainActor in
                guard let self else { return }
                switch observed.status {
                case .readyToPlay:
                    self.state = .playing
                case .failed:
                    self.handleFailure()
                default:
                    break
                }
            }
        }
    }

    private func handleFailure() {
        if !pendingCandidates.isEmpty {
            startNextCandidate()
        } else {
            state = .failed("재생할 수 없습니다")
        }
    }

    private func attachMetadataOutput(to item: AVPlayerItem) {
        let output = AVPlayerItemMetadataOutput(identifiers: nil)
        output.setDelegate(self, queue: .main)
        item.add(output)
        metadataOutput = output
    }

    func stop() {
        statusObservation?.invalidate()
        statusObservation = nil
        player?.pause()
        player = nil
        item = nil
        metadataOutput = nil
        pendingCandidates = []
        nowPlaying = nil
        state = .idle
    }
}

extension RadioPlayer: AVPlayerItemMetadataOutputPushDelegate {
    nonisolated func metadataOutput(
        _ output: AVPlayerItemMetadataOutput,
        didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup],
        from track: AVPlayerItemTrack?
    ) {
        let values: [String] = groups
            .flatMap { $0.items }
            .compactMap { $0.stringValue }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard let title = values.first else { return }
        Task { @MainActor in
            self.nowPlaying = title
        }
    }
}
