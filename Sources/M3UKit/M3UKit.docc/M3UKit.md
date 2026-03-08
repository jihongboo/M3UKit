# ``M3UKit``

`M3UKit` is a Swift 6 parser framework for M3U and Extended M3U playlists.

## Overview

Use ``M3UParser`` to parse playlist content from text, `Data`, or URL.

```swift
import M3UKit

let parser = M3UParser()
let playlist = try parser.parse("""
#EXTM3U
#EXTINF:-1 tvg-id="cctv1" group-title="News",CCTV-1 HD
https://example.com/live/cctv1.m3u8
""")

print(playlist.items.count)
```

## Topics

### Essentials

- <doc:Getting-Started>

### Core Types

- ``M3UParser``
- ``M3UParserOptions``
- ``M3UPlaylist``
- ``M3UItem``
- ``M3UDirective``
- ``M3UParserError``
