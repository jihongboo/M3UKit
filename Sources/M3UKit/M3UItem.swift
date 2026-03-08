import Foundation

/// A single playable item in an M3U playlist.
public struct M3UItem: Sendable, Equatable {
    /// Where the player should load media from.
    ///
    /// Usually a streaming URL, but it can also be a local file path.
    public var location: String

    /// Optional duration hint in seconds.
    ///
    /// Live channels often use `-1` (unknown/infinite), while VOD content
    /// may provide an actual duration.
    public var duration: Double?

    /// Human-readable name shown in UI lists.
    ///
    /// Example: channel name like "CCTV-1 HD" or media title.
    public var title: String?

    /// Extra metadata used for grouping, search, or playback context.
    ///
    /// Common keys include channel id, logo URL, and category/group name.
    public var attributes: [String: String]

    /// Raw per-item directives that may affect playback behavior.
    ///
    /// Use this when you need advanced tags that are not promoted
    /// to first-class properties.
    public var directives: [M3UDirective]

    /// Creates a media item.
    /// - Parameters:
    ///   - location: Stream URL or local media path.
    ///   - duration: Optional duration hint.
    ///   - title: Display name for users.
    ///   - attributes: Extra metadata for this entry.
    ///   - directives: Additional low-level tags for this entry.
    public init(
        location: String,
        duration: Double? = nil,
        title: String? = nil,
        attributes: [String: String] = [:],
        directives: [M3UDirective] = []
    ) {
        self.location = location
        self.duration = duration
        self.title = title
        self.attributes = attributes
        self.directives = directives
    }
}
