import Foundation
import Testing
@testable import M3UKit

@Test("Parse plain M3U")
func parsePlainM3U() throws {
    let parser = M3UParser()
    let text = """
    # this is a comment
    https://example.com/live/stream.m3u8
    local/path/song.mp3
    """

    let playlist = try parser.parse(text)

    #expect(playlist.isExtended == false)
    #expect(playlist.items.count == 2)
    #expect(playlist.items[0].location == "https://example.com/live/stream.m3u8")
    #expect(playlist.items[0].title == nil)
    #expect(playlist.items[1].location == "local/path/song.mp3")
}

@Test("Parse extended M3U with EXTINF attributes")
func parseExtendedM3U() throws {
    let parser = M3UParser()
    let text = """
    #EXTM3U x-tvg-url="https://epg.example.com/guide.xml"
    #EXTINF:-1 tvg-id="cctv1" tvg-name="CCTV-1" group-title="News",CCTV-1 HD
    http://example.com/cctv1.m3u8
    """

    let playlist = try parser.parse(text)

    #expect(playlist.isExtended == true)
    #expect(playlist.headerAttributes["x-tvg-url"] == "https://epg.example.com/guide.xml")
    #expect(playlist.items.count == 1)

    let item = playlist.items[0]
    #expect(item.duration == -1)
    #expect(item.title == "CCTV-1 HD")
    #expect(item.attributes["tvg-id"] == "cctv1")
    #expect(item.attributes["group-title"] == "News")
}

@Test("Keep additional directives with each item")
func parseDirectives() throws {
    let parser = M3UParser()
    let text = """
    #EXTM3U
    #EXTINF:9,Sample artist - Sample title
    #EXTGRP:Music
    #EXTVLCOPT:http-user-agent=MyAgent
    http://example.com/audio.mp3
    """

    let playlist = try parser.parse(text)

    #expect(playlist.items.count == 1)
    let directives = playlist.items[0].directives
    #expect(directives.count == 2)
    #expect(directives[0] == M3UDirective(name: "EXTGRP", value: "Music"))
    #expect(directives[1] == M3UDirective(name: "EXTVLCOPT", value: "http-user-agent=MyAgent", attributes: ["http-user-agent": "MyAgent"]))
}

@Test("Ignore non-standard comment lines by default")
func ignoreCommentLines() throws {
    let parser = M3UParser()
    let text = """
    # this is a comment
    # note: keep parsing
    #EXTM3U
    #EXTINF:10,Sample
    https://example.com/a.mp3
    """

    let playlist = try parser.parse(text)

    #expect(playlist.items.count == 1)
    #expect(playlist.items[0].directives.isEmpty)
}

@Test("Parse EXTENC in extended playlists")
func parseEXTENC() throws {
    let parser = M3UParser()
    let text = """
    #EXTM3U
    #EXTENC:UTF-8
    #EXTINF:10,Sample
    https://example.com/a.mp3
    """

    let playlist = try parser.parse(text)

    #expect(playlist.extendedEncoding == "UTF-8")
}

@Test("Parse HLS EXT-X attributes")
func parseHLSAttributes() throws {
    let parser = M3UParser()
    let text = """
    #EXTM3U
    #EXT-X-KEY:METHOD=AES-128,URI="https://example.com/key.bin",IV=0x1234
    #EXTINF:5,Seg 1
    https://example.com/seg1.ts
    """

    let playlist = try parser.parse(text)
    let directive = try #require(playlist.items.first?.directives.first)

    #expect(directive.isHLS == true)
    #expect(directive.name == "EXT-X-KEY")
    #expect(directive.attributes["METHOD"] == "AES-128")
    #expect(directive.attributes["URI"] == "https://example.com/key.bin")
    #expect(directive.attributes["IV"] == "0x1234")
}

@Test("Parse IPTV extended tags and unquoted attributes")
func parseIPTVExtendedFormat() throws {
    let parser = M3UParser()
    let text = """
    #EXTM3U url-tvg=https://epg.example.com/guide.xml catchup=append
    #EXTINF:tvg-id=cctv1 tvg-name="CCTV 1" group-title=News,China,CCTV-1 HD
    #KODIPROP:inputstream.adaptive.license_type=com.widevine.alpha
    #EXTVLCOPT:http-user-agent=IPTVPro
    http://example.com/cctv1.m3u8
    """

    let playlist = try parser.parse(text)
    let item = try #require(playlist.items.first)

    #expect(playlist.headerAttributes["url-tvg"] == "https://epg.example.com/guide.xml")
    #expect(playlist.headerAttributes["catchup"] == "append")
    #expect(item.duration == nil)
    #expect(item.title == "China,CCTV-1 HD")
    #expect(item.attributes["tvg-id"] == "cctv1")
    #expect(item.attributes["tvg-name"] == "CCTV 1")
    #expect(item.attributes["group-title"] == "News")
    #expect(item.directives.count == 2)
    #expect(item.directives[0].name == "KODIPROP")
    #expect(item.directives[0].attributes["inputstream.adaptive.license_type"] == "com.widevine.alpha")
    #expect(item.directives[1].name == "EXTVLCOPT")
    #expect(item.directives[1].attributes["http-user-agent"] == "IPTVPro")
}

@Test("Use enum keys for IPTV metadata access")
func typedIPTVMetadataAccess() throws {
    let parser = M3UParser()
    let text = """
    #EXTM3U x-tvg-url=https://epg.example.com/guide.xml
    #EXTINF:-1 tvg-id=cctv1 tvg-name="CCTV 1" tvg-logo=https://img.example.com/cctv1.png group-title=News,CCTV-1
    #KODIPROP:inputstream.adaptive.license_type=com.widevine.alpha
    http://example.com/cctv1.m3u8
    """

    var playlist = try parser.parse(text)
    var item = try #require(playlist.items.first)

    #expect(playlist[iptv: .xTvgURL] == "https://epg.example.com/guide.xml")
    #expect(playlist.epgURL == "https://epg.example.com/guide.xml")

    #expect(item[iptv: .tvgID] == "cctv1")
    #expect(item.tvgID == "cctv1")
    #expect(item.tvgName == "CCTV 1")
    #expect(item.tvgLogo == "https://img.example.com/cctv1.png")
    #expect(item.groupTitle == "News")
    #expect(item.directive(named: .kodiprop)?.attributes["inputstream.adaptive.license_type"] == "com.widevine.alpha")

    item[iptv: .groupTitle] = "Documentary"
    playlist[iptv: .catchup] = "append"
    #expect(item.attributes["group-title"] == "Documentary")
    #expect(playlist.headerAttributes["catchup"] == "append")
}

@Test("Parse UTF-8 BOM and data input")
func parseDataWithBOM() throws {
    let parser = M3UParser()
    let text = "\u{FEFF}#EXTM3U\n#EXTINF:123,Example\nhttps://example.com/test.mp4"
    let data = text.data(using: .utf8)!

    let playlist = try parser.parse(data: data)

    #expect(playlist.isExtended == true)
    #expect(playlist.items.count == 1)
    #expect(playlist.items[0].duration == 123)
    #expect(playlist.items[0].title == "Example")
}

@Test("Parse M3U from file URL")
func parseFromFileURL() async throws {
    let parser = M3UParser()
    let directory = FileManager.default.temporaryDirectory
    let fileURL = directory.appendingPathComponent(UUID().uuidString).appendingPathExtension("m3u")
    let text = """
    #EXTM3U
    #EXTINF:8,File URL Item
    https://example.com/file-url.mp3
    """

    try text.write(to: fileURL, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: fileURL) }

    let playlist = try await parser.parse(url: fileURL)
    #expect(playlist.isExtended == true)
    #expect(playlist.items.count == 1)
    #expect(playlist.items[0].title == "File URL Item")
    #expect(playlist.items[0].location == "https://example.com/file-url.mp3")
}

@Test("Empty input throws")
func emptyInputThrows() {
    let parser = M3UParser()
    #expect(throws: M3UParserError.self) {
        _ = try parser.parse("")
    }
}

@Test("Strict mode requires EXTM3U before EXT tags")
func strictModeRequiresHeader() {
    let parser = M3UParser()
    let text = """
    #EXTINF:10,Sample
    https://example.com/a.mp3
    """

    #expect(throws: M3UParserError.missingExtendedHeader(line: 1)) {
        _ = try parser.parse(text, options: .strict)
    }
}

@Test("Strict mode enforces EXTM3U first meaningful line")
func strictModeHeaderPosition() {
    let parser = M3UParser()
    let text = """
    # comment
    #EXTM3U
    #EXTINF:10,Sample
    https://example.com/a.mp3
    """

    #expect(throws: M3UParserError.invalidExtendedHeaderPosition(line: 2)) {
        _ = try parser.parse(text, options: .strict)
    }
}
