import Foundation

/// A single radio station with its decrypted live stream endpoint.
struct Station: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let streamURL: String
    let streamType: String
    let alternateURLs: [String]
    let logoURL: String?
    let frequency: String?
    let genre: String?

    /// Ordered list of stream candidates: primary first, then fallbacks.
    var streamCandidates: [URL] {
        ([streamURL] + alternateURLs).compactMap { URL(string: $0) }
    }
}
