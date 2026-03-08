import Foundation

/// Errors thrown by ``M3UParser``.
public enum M3UParserError: Error, Sendable, Equatable {
    /// Input is empty or contains only whitespace/newlines.
    case emptyInput

    /// URL loading returned a non-HTTP response for a remote URL.
    case invalidHTTPResponse

    /// URL loading returned a non-success HTTP status code.
    case httpStatusCode(Int)

    /// Strict mode: `#EXTM3U` is not at the first meaningful line.
    case invalidExtendedHeaderPosition(line: Int)

    /// Strict mode: an extended tag appeared before `#EXTM3U`.
    case missingExtendedHeader(line: Int)

    /// Strict mode: duplicate `#EXTM3U` header found.
    case duplicateExtendedHeader(line: Int)
}
