# Getting Started

Learn how to parse M3U playlists with ``M3UKit``.

## Parse from String

```swift
import M3UKit

let parser = M3UParser()
let playlist = try parser.parse("""
#EXTM3U
#EXTINF:9,Sample title
https://example.com/audio.mp3
""")

let item = playlist.items[0]
print(item.title ?? "")
print(item.location)
```

## Parse from URL

```swift
import M3UKit

let parser = M3UParser()
let url = URL(string: "https://example.com/playlist.m3u8")!
let playlist = try await parser.parse(url: url)
```

## Strict Mode

Use strict mode to enforce extended header rules:

```swift
let strictPlaylist = try parser.parse(sourceText, options: .strict)
```

## What Is Parsed

- `#EXTM3U` header and header attributes
- `#EXTENC` value into ``M3UPlaylist/extendedEncoding``
- `#EXTINF` duration, title, and quoted/unquoted attributes (duration can be omitted)
- Additional directives attached to the following item (including IPTV tags such as `#KODIPROP`)
- `#EXT-X-*` directives with extracted key-value attributes
