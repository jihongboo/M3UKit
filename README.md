# M3UKit

`M3UKit` is a Swift 6 M3U parser framework distributed as a Swift Package, with support for all Apple platforms.

## Features

- Swift Package Manager integration
- Supports iOS / macOS / tvOS / watchOS / visionOS
- Supports standard M3U and extended M3U (`#EXTM3U` / `#EXTINF`)
- Supports strict mode (`#EXTM3U` position and extended-tag ordering validation)
- Parses common `#EXTINF` attributes (for example `tvg-id`, `group-title`)
- Preserves additional directives before each media item (for example `#EXTGRP`, `#EXTVLCOPT`)
- Supports `#EXTENC` parsing
- Supports key-value extraction for `#EXT-X-*` tags (for example HLS `METHOD/URI/IV`)
- Supports parsing playlists from text, `Data`, and URL (`http/https` + `file://`)

## Installation

Add the dependency to your `Package.swift`:

```swift
.package(url: "https://github.com/your-org/M3UKit.git", from: "0.1.0")
```

Then add the product to your target:

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

print(playlist.isExtended)              // true
print(playlist.headerAttributes)        // ["x-tvg-url": "..."]
print(playlist.items.first?.location ?? "")
print(playlist.items.first?.attributes ?? [:])
```

Strict mode:

```swift
let strictPlaylist = try parser.parse(sourceText, options: .strict)
```

Parse from URL (`http/https` and `file://`):

```swift
let playlistFromURL = try await parser.parse(url: URL(string: "https://example.com/live.m3u")!)
```

## Data Models

- `M3UPlaylist`: Root playlist model
  - `isExtended`: Whether the playlist contains an extended header
  - `headerAttributes`: Attributes parsed from `#EXTM3U`
  - `extendedEncoding`: Value parsed from `#EXTENC`
  - `items`: Parsed media items
- `M3UItem`: Media item
  - `location`: Media URL or local path
  - `duration`: Duration from `#EXTINF`
  - `title`: Title from `#EXTINF`
  - `attributes`: Parsed key-value attributes from `#EXTINF`
  - `directives`: Additional directives attached to the item
- `M3UDirective`: Additional directive model
  - `attributes`: Parsed key-value pairs (primarily for `#EXT-X-*`)
  - `isHLS`: Whether the directive is an `#EXT-X-*` tag

## Supported Spec Scope

Current implementation focuses on common M3U practices:

1. Normal lines are parsed as media locations.
2. `#EXTM3U` is parsed as the extended header with optional attributes.
3. `#EXTINF:<duration> [attrs],<title>` is parsed.
4. Other `#TAG[:value]` lines are preserved as directives for the following media item.
5. `#EXTENC:<encoding>` is parsed into `M3UPlaylist.extendedEncoding`.
6. `#EXT-X-*` tags parse `KEY=VALUE` attributes (including quoted values).
7. Strict mode requires `#EXTM3U` to be the first meaningful line and requires extended tags to appear after the header.

## DocC

DocC sources are included at:

- `Sources/M3UKit/M3UKit.docc`

Published documentation:

- https://jihongboo.github.io/M3UKit/documentation/m3ukit/

To generate documentation (requires a local DocC-capable toolchain):

```bash
swift package generate-documentation
```

## Testing

Run tests with:

```bash
swift test
```

Current test coverage includes:

- Plain M3U parsing
- Extended M3U and attribute extraction
- Additional directive binding
- UTF-8 BOM / `Data` input
- Empty input error handling
- Strict mode validation
- `#EXTENC` parsing
- `#EXT-X-*` attribute parsing
- URL parsing via local file URL
