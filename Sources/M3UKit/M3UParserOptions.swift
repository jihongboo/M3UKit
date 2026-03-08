import Foundation

/// Parser behavior configuration.
public struct M3UParserOptions: Sendable, Equatable {
    /// Enables validation for stricter playlist hygiene.
    ///
    /// Turn this on when you want to reject loosely formatted inputs early.
    public var strictMode: Bool

    /// Skips free-form comment lines that are not known M3U tags.
    ///
    /// Keep this enabled for noisy real-world playlists.
    public var ignoreCommentLines: Bool

    /// Creates parser options.
    /// - Parameters:
    ///   - strictMode: Whether to reject format violations.
    ///   - ignoreCommentLines: Whether to drop non-tag comments.
    public init(strictMode: Bool = false, ignoreCommentLines: Bool = true) {
        self.strictMode = strictMode
        self.ignoreCommentLines = ignoreCommentLines
    }

    /// Balanced behavior for common real-world playlists.
    public static let `default` = M3UParserOptions()

    /// Strict validation profile for quality-sensitive pipelines.
    public static let strict = M3UParserOptions(strictMode: true, ignoreCommentLines: true)
}
