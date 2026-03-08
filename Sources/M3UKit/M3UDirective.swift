import Foundation

/// Additional directive lines (for example, `#EXTGRP`, `#EXTVLCOPT`) that precede an item.
public struct M3UDirective: Sendable, Equatable {
    /// Directive tag name (without the leading `#`).
    ///
    /// Example: `EXTVLCOPT`, `EXT-X-KEY`.
    public var name: String

    /// Original directive payload as plain text.
    ///
    /// Useful when you need full-fidelity access to source content.
    public var value: String?

    /// Parsed key-value options for tags that use `KEY=VALUE` syntax.
    ///
    /// This is especially helpful for HLS tags such as encryption settings.
    public var attributes: [String: String]

    /// `true` when the directive belongs to the HLS family (`#EXT-X-*`).
    public var isHLS: Bool

    /// Creates a directive model.
    /// - Parameters:
    ///   - name: Tag name (without `#`).
    ///   - value: Raw payload text.
    ///   - attributes: Parsed options map.
    ///   - isHLS: Whether this tag is HLS-specific.
    public init(
        name: String,
        value: String? = nil,
        attributes: [String: String] = [:],
        isHLS: Bool = false
    ) {
        self.name = name
        self.value = value
        self.attributes = attributes
        self.isHLS = isHLS
    }
}
