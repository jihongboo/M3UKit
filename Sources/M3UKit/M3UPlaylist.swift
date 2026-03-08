import Foundation

/// A parsed M3U playlist.
public struct M3UPlaylist: Sendable, Equatable {
    /// `true` when the file uses extended M3U format.
    ///
    /// In practice this means the playlist starts with metadata tags
    /// (for example channel names and durations), not just raw URLs.
    public var isExtended: Bool

    /// Global playlist-level metadata.
    ///
    /// Typical examples include EPG settings or provider metadata that apply
    /// to many items in the list.
    public var headerAttributes: [String: String]

    /// Preferred text encoding for this playlist, when provided by the source.
    public var extendedEncoding: String?

    /// Playable entries in display order.
    ///
    /// Each entry usually represents one channel, one stream, or one media file.
    public var items: [M3UItem]

    /// Creates a playlist model.
    /// - Parameters:
    ///   - isExtended: Whether the playlist includes rich metadata tags.
    ///   - headerAttributes: Global metadata for the whole playlist.
    ///   - extendedEncoding: Preferred source text encoding.
    ///   - items: Playable entries in original order.
    public init(
        isExtended: Bool = false,
        headerAttributes: [String: String] = [:],
        extendedEncoding: String? = nil,
        items: [M3UItem] = []
    ) {
        self.isExtended = isExtended
        self.headerAttributes = headerAttributes
        self.extendedEncoding = extendedEncoding
        self.items = items
    }
}
