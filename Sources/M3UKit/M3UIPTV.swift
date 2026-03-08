import Foundation

/// Typed keys for IPTV playlist-level attributes on `#EXTM3U`.
public enum M3UIPTVHeaderAttributeKey: String, CaseIterable, Sendable {
    case xTvgURL = "x-tvg-url"
    case urlTvg = "url-tvg"
    case tvgShift = "tvg-shift"
    case catchup = "catchup"
    case catchupDays = "catchup-days"
    case catchupSource = "catchup-source"
}

/// Typed keys for IPTV item-level attributes on `#EXTINF`.
public enum M3UIPTVItemAttributeKey: String, CaseIterable, Sendable {
    case tvgID = "tvg-id"
    case tvgName = "tvg-name"
    case tvgLanguage = "tvg-language"
    case tvgCountry = "tvg-country"
    case tvgLogo = "tvg-logo"
    case groupTitle = "group-title"
    case channelNumber = "channel-number"
    case catchup = "catchup"
    case catchupDays = "catchup-days"
    case catchupSource = "catchup-source"
}

/// Typed names for common IPTV directives.
public enum M3UIPTVDirectiveName: String, CaseIterable, Sendable {
    case extgrp = "EXTGRP"
    case extvlcopt = "EXTVLCOPT"
    case kodiprop = "KODIPROP"
}

public extension M3UPlaylist {
    /// Typed access to IPTV header attributes.
    subscript(iptv key: M3UIPTVHeaderAttributeKey) -> String? {
        get { headerAttributes[key.rawValue] }
        set { headerAttributes[key.rawValue] = newValue }
    }

    /// A convenience EPG URL field that checks both `url-tvg` and `x-tvg-url`.
    var epgURL: String? {
        self[iptv: .urlTvg] ?? self[iptv: .xTvgURL]
    }
}

public extension M3UItem {
    /// Typed access to IPTV item attributes.
    subscript(iptv key: M3UIPTVItemAttributeKey) -> String? {
        get { attributes[key.rawValue] }
        set { attributes[key.rawValue] = newValue }
    }

    /// Looks up the first directive matching a typed IPTV directive name.
    func directive(named name: M3UIPTVDirectiveName) -> M3UDirective? {
        directives.first { $0.name == name.rawValue }
    }

    /// Commonly used IPTV aliases.
    var tvgID: String? { self[iptv: .tvgID] }
    var tvgName: String? { self[iptv: .tvgName] }
    var tvgLogo: String? { self[iptv: .tvgLogo] }
    var groupTitle: String? { self[iptv: .groupTitle] }
}
