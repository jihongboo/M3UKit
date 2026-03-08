# M3UKit

[![Swift 6.1+](https://img.shields.io/badge/Swift-6.1%2B-F05138?logo=swift&logoColor=white)](https://www.swift.org)
[![SPM](https://img.shields.io/badge/SPM-supported-0A84FF)](https://swift.org/package-manager/)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-34C759)](https://developer.apple.com)
[![DocC](https://img.shields.io/badge/Docs-DocC-5AC8FA)](https://jihongboo.github.io/M3UKit/documentation/m3ukit/)
[![Pages](https://img.shields.io/github/actions/workflow/status/jihongboo/M3UKit/docc.yml?label=DocC%20Deploy)](https://github.com/jihongboo/M3UKit/actions/workflows/docc.yml)

`M3UKit` is a Swift 6.1+ M3U/M3U8 parser framework distributed as a Swift Package, with support for all Apple platforms.

## Features

- Standard M3U and extended M3U parsing (`#EXTM3U`, `#EXTINF`)
- Strict validation mode for header order and extended-tag placement
- IPTV-style `#EXTINF` parsing (supports optional duration and quoted/unquoted attributes)
- Additional directive preservation (for example `#EXTGRP`, `#EXTVLCOPT`, `#KODIPROP`)
- `#EXTENC` support
- `#EXT-X-*` key-value extraction for HLS tags
- Enum-based IPTV key access (`playlist[iptv:]`, `item[iptv:]`) to avoid raw string keys
- Input support from `String`, `Data`, and URL (`http/https` + `file://`)
- Full Apple platform support via Swift Package Manager

## Installation

Add the dependency in `Package.swift`:

```swift
.package(url: "https://github.com/jihongboo/M3UKit.git", from: "0.1.0")
```

Then add the product in your target:

```swift
.product(name: "M3UKit", package: "M3UKit")
```

## Quick Start

```swift
import M3UKit

let parser = M3UParser()
let playlist = try parser.parse("""
#EXTM3U x-tvg-url="https://epg.example.com/guide.xml"
#EXTINF:-1 tvg-id="cctv1" group-title="News",CCTV-1 HD
http://example.com/cctv1.m3u8
""")

print(playlist.isExtended)
print(playlist.headerAttributes)
print(playlist.items.first?.title ?? "")
print(playlist.items.first?.location ?? "")
```

Strict mode:

```swift
let strictPlaylist = try parser.parse(sourceText, options: .strict)
```

Parse from URL:

```swift
let playlistFromURL = try await parser.parse(
    url: URL(string: "https://example.com/live.m3u8")!
)
```

Typed IPTV access (no hard-coded string keys):

```swift
let playlist = try parser.parse(source)
let item = playlist.items[0]

print(playlist[iptv: .xTvgURL] ?? "")
print(item[iptv: .tvgID] ?? "")
print(item.groupTitle ?? "")
print(item.directive(named: .extvlcopt)?.attributes["http-user-agent"] ?? "")
```

## Documentation

- Online DocC: https://jihongboo.github.io/M3UKit/documentation/m3ukit/
- DocC source: `Sources/M3UKit/M3UKit.docc`

Generate docs locally:

```bash
swift package generate-documentation
```

## Data Models

- `M3UPlaylist`: playlist root object
- `M3UItem`: playable media entry
- `M3UDirective`: per-item directive/tag object
- `M3UParserOptions`: parser behavior options
- `M3UParserError`: parser error definitions

## Testing

```bash
swift test
```

Current tests cover plain/extended parsing, IPTV extensions, directives, strict mode, BOM/data input, URL input, `#EXTENC`, and `#EXT-X-*` attribute parsing.
