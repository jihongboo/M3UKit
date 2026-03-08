import Foundation

/// A parser for standard and extended M3U playlists.
public struct M3UParser: Sendable {
    /// Creates a parser instance.
    public init() {}

    /// Parses M3U content from a text string.
    /// - Parameters:
    ///   - text: Raw playlist text.
    ///   - options: Parser options controlling strictness and comment handling.
    /// - Returns: A parsed playlist model.
    /// - Throws: ``M3UParserError`` when input is invalid.
    public func parse(_ text: String, options: M3UParserOptions = .default) throws -> M3UPlaylist {
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        if normalized.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw M3UParserError.emptyInput
        }

        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false)

        var playlist = M3UPlaylist()
        var pendingEXTINF: (duration: Double?, title: String?, attributes: [String: String])?
        var pendingDirectives: [M3UDirective] = []
        var meaningfulLineIndex = 0
        var hasSeenExtendedHeader = false

        for (lineNumber, rawLine) in lines.enumerated() {
            var line = String(rawLine).trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty {
                continue
            }

            if line.hasPrefix("\u{FEFF}") {
                line.removeFirst()
            }

            meaningfulLineIndex += 1

            if line == "#EXTM3U" || line.hasPrefix("#EXTM3U ") {
                if options.strictMode && meaningfulLineIndex != 1 {
                    throw M3UParserError.invalidExtendedHeaderPosition(line: lineNumber + 1)
                }
                if options.strictMode && hasSeenExtendedHeader {
                    throw M3UParserError.duplicateExtendedHeader(line: lineNumber + 1)
                }
                playlist.isExtended = true
                hasSeenExtendedHeader = true
                let remainder = line.dropFirst("#EXTM3U".count)
                    .trimmingCharacters(in: .whitespaces)
                if !remainder.isEmpty {
                    playlist.headerAttributes.merge(Self.parseAttributes(remainder)) { _, new in new }
                }
                continue
            }

            if line.hasPrefix("#EXTENC:") {
                if options.strictMode && !playlist.isExtended {
                    throw M3UParserError.missingExtendedHeader(line: lineNumber + 1)
                }
                playlist.extendedEncoding = String(line.dropFirst("#EXTENC:".count))
                    .trimmingCharacters(in: .whitespaces)
                continue
            }

            if line.hasPrefix("#EXTINF:") {
                if options.strictMode && !playlist.isExtended {
                    throw M3UParserError.missingExtendedHeader(line: lineNumber + 1)
                }
                let payload = String(line.dropFirst("#EXTINF:".count))
                pendingEXTINF = Self.parseEXTINF(payload)
                continue
            }

            if line.hasPrefix("#") {
                if options.strictMode && line.hasPrefix("#EXT") && !playlist.isExtended {
                    throw M3UParserError.missingExtendedHeader(line: lineNumber + 1)
                }
                if let directive = Self.parseDirective(line) {
                    pendingDirectives.append(directive)
                    continue
                }
                if options.ignoreCommentLines && Self.looksLikeComment(line) {
                    continue
                }
                continue
            }

            let item = M3UItem(
                location: line,
                duration: pendingEXTINF?.duration,
                title: pendingEXTINF?.title,
                attributes: pendingEXTINF?.attributes ?? [:],
                directives: pendingDirectives
            )
            playlist.items.append(item)
            pendingEXTINF = nil
            pendingDirectives = []
        }

        return playlist
    }

    /// Parses M3U content from binary data.
    /// - Parameters:
    ///   - data: Playlist bytes.
    ///   - encoding: Text encoding used to decode the input data.
    ///   - options: Parser options controlling strictness and comment handling.
    /// - Returns: A parsed playlist model.
    /// - Throws: ``M3UParserError`` when decoding or parsing fails.
    public func parse(
        data: Data,
        encoding: String.Encoding = .utf8,
        options: M3UParserOptions = .default
    ) throws -> M3UPlaylist {
        guard let text = String(data: data, encoding: encoding) else {
            throw M3UParserError.emptyInput
        }
        return try parse(text, options: options)
    }

    /// Parses M3U content from a URL.
    /// - Parameters:
    ///   - url: Source URL. Supports both local `file://` and remote `http/https` URLs.
    ///   - encoding: Text encoding used to decode playlist bytes.
    ///   - options: Parser options controlling strictness and comment handling.
    ///   - session: URL session used for remote network requests.
    /// - Returns: A parsed playlist model.
    /// - Throws: ``M3UParserError`` for parser-level failures and URL loading errors.
    public func parse(
        url: URL,
        encoding: String.Encoding = .utf8,
        options: M3UParserOptions = .default,
        session: URLSession = .shared
    ) async throws -> M3UPlaylist {
        let data: Data
        if url.isFileURL {
            data = try Data(contentsOf: url)
        } else {
            let (remoteData, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw M3UParserError.invalidHTTPResponse
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                throw M3UParserError.httpStatusCode(httpResponse.statusCode)
            }
            data = remoteData
        }
        return try parse(data: data, encoding: encoding, options: options)
    }
}

private extension M3UParser {
    private static func looksLikeComment(_ line: String) -> Bool {
        if line == "#" {
            return true
        }
        return line.hasPrefix("# ")
    }

    private static func parseDirective(_ line: String) -> M3UDirective? {
        let body = String(line.dropFirst())
        let pieces = body.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        guard let name = pieces.first.map(String.init), !name.isEmpty else {
            return nil
        }
        guard isLikelyDirectiveName(name) else {
            return nil
        }
        let isHLS = name.hasPrefix("EXT-X-")
        if pieces.count == 2 {
            let value = String(pieces[1])
            let attributes = parseUnquotedOrQuotedAttributes(value)
            return M3UDirective(name: name, value: value, attributes: attributes, isHLS: isHLS)
        }
        return M3UDirective(name: name, attributes: [:], isHLS: isHLS)
    }

    private static func parseEXTINF(_ payload: String) -> (duration: Double?, title: String?, attributes: [String: String]) {
        let (infoPart, titlePart) = splitOnceOutsideQuotes(payload, separator: ",")
        let title = titlePart?.trimmingCharacters(in: .whitespaces)

        let trimmedInfo = infoPart.trimmingCharacters(in: .whitespaces)
        let tokens = trimmedInfo.split(omittingEmptySubsequences: true, whereSeparator: { $0.isWhitespace })

        let durationToken = tokens.first.map(String.init)
        let duration = durationToken.flatMap(Double.init)

        if let first = tokens.first {
            let firstToken = String(first)
            if duration != nil, trimmedInfo.hasPrefix(firstToken) {
                let start = trimmedInfo.index(trimmedInfo.startIndex, offsetBy: firstToken.count)
                let attributesSource = String(trimmedInfo[start...]).trimmingCharacters(in: .whitespaces)
                return (duration: duration, title: title, attributes: parseAttributes(attributesSource))
            }
        } else {
            return (duration: nil, title: title, attributes: [:])
        }

        return (duration: nil, title: title, attributes: parseAttributes(trimmedInfo))
    }

    private static func parseAttributes(_ source: String) -> [String: String] {
        let pattern = #"([A-Za-z0-9._-]+)=(\"([^\"]*)\"|[^\s,]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [:]
        }

        let nsSource = source as NSString
        let range = NSRange(location: 0, length: nsSource.length)
        let matches = regex.matches(in: source, options: [], range: range)

        var result: [String: String] = [:]
        for match in matches where match.numberOfRanges >= 3 {
            let key = nsSource.substring(with: match.range(at: 1))
            let fullValue = nsSource.substring(with: match.range(at: 2))
            let normalizedValue: String
            if fullValue.hasPrefix("\""), fullValue.hasSuffix("\""), fullValue.count >= 2 {
                normalizedValue = String(fullValue.dropFirst().dropLast())
            } else {
                normalizedValue = fullValue
            }
            result[key] = normalizedValue
        }
        return result
    }

    private static func parseUnquotedOrQuotedAttributes(_ source: String) -> [String: String] {
        let pattern = #"([A-Za-z0-9._-]+)=(\"([^\"]*)\"|[^,]*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [:]
        }

        let nsSource = source as NSString
        let range = NSRange(location: 0, length: nsSource.length)
        let matches = regex.matches(in: source, options: [], range: range)

        var result: [String: String] = [:]
        for match in matches where match.numberOfRanges >= 3 {
            let key = nsSource.substring(with: match.range(at: 1))
            let fullValue = nsSource.substring(with: match.range(at: 2))
            let normalizedValue: String
            if fullValue.hasPrefix("\""), fullValue.hasSuffix("\""), fullValue.count >= 2 {
                normalizedValue = String(fullValue.dropFirst().dropLast())
            } else {
                normalizedValue = fullValue
            }
            result[key] = normalizedValue
        }
        return result
    }

    private static func splitOnceOutsideQuotes(_ source: String, separator: Character) -> (String, String?) {
        var inQuotes = false
        for index in source.indices {
            let character = source[index]
            if character == "\"" {
                inQuotes.toggle()
                continue
            }
            if character == separator, !inQuotes {
                let before = String(source[..<index])
                let afterIndex = source.index(after: index)
                let after = afterIndex < source.endIndex ? String(source[afterIndex...]) : ""
                return (before, after)
            }
        }
        return (source, nil)
    }

    private static func isLikelyDirectiveName(_ name: String) -> Bool {
        guard !name.isEmpty else {
            return false
        }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        guard name.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            return false
        }
        return name == name.uppercased()
    }
}
