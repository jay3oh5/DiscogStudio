import Foundation

public protocol LyricsServiceProtocol: Sendable {
    func cleanTrackTitle(_ title: String) -> String
    func fetchGeniusPlainLyrics(artist: String, title: String, geniusToken: String?) async throws -> String?
    func fetchSyncedLrcLyrics(artist: String, title: String, album: String?, durationSeconds: Double?) async throws -> String?
    func saveCompanionLrc(lyricsText: String, audioFileURL: URL) throws -> URL
}

public final class LyricsService: LyricsServiceProtocol, @unchecked Sendable {
    public static let shared = LyricsService()

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Strips feat, ft, remastered, bonus track qualifiers for maximum search match accuracy
    public func cleanTrackTitle(_ title: String) -> String {
        var clean = title
        let patterns = [
            #"\s*[\(\[\{]\s*(?:feat|featuring|ft\.?)\s+[^()\]\}]+[\)\]\}]"#,
            #"\s*-\s*(?:feat|featuring|ft\.?)\s+.*$"#,
            #"\s*[\(\[\{]\s*(?:remastered|deluxe|bonus|explicit|clean|anniversary|edition)[^()\]\}]*[\)\]\}]"#,
            #"\s*-\s*(?:remastered|deluxe|bonus|explicit|clean)[^$]*$"#
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: clean.utf16.count)
                clean = regex.stringByReplacingMatches(in: clean, options: [], range: range, withTemplate: "")
            }
        }
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Primary Source for Synced `.lrc` with timestamps: LRCLIB Open API
    public func fetchSyncedLrcLyrics(
        artist: String,
        title: String,
        album: String? = nil,
        durationSeconds: Double? = nil
    ) async throws -> String? {
        let cleanedTitle = cleanTrackTitle(title)
        var components = URLComponents(string: "https://lrclib.net/api/get")
        var queryItems = [
            URLQueryItem(name: "artist_name", value: artist),
            URLQueryItem(name: "track_name", value: cleanedTitle)
        ]
        if let alb = album, !alb.isEmpty {
            queryItems.append(URLQueryItem(name: "album_name", value: alb))
        }
        if let dur = durationSeconds, dur > 0 {
            queryItems.append(URLQueryItem(name: "duration", value: String(Int(dur))))
        }
        components?.queryItems = queryItems

        guard let url = components?.url else { return nil }

        var request = URLRequest(url: url)
        request.setValue("DiscogStudio/1.0.0 (https://github.com/jay3oh5/DiscogStudio)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }

        struct LRCLIBResponse: Decodable {
            let syncedLyrics: String?
            let plainLyrics: String?
        }

        let decoded = try JSONDecoder().decode(LRCLIBResponse.self, from: data)
        return decoded.syncedLyrics ?? decoded.plainLyrics
    }

    /// Secondary / Plain structured lyrics with [Intro], [Verse], [Chorus] from Genius
    public func fetchGeniusPlainLyrics(artist: String, title: String, geniusToken: String?) async throws -> String? {
        guard let token = geniusToken, !token.isEmpty else { return nil }
        let cleanedTitle = cleanTrackTitle(title)
        let query = "\(artist) \(cleanedTitle)"
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.genius.com/search?q=\(encoded)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }

        struct GeniusSearchResponse: Decodable {
            struct ResponseData: Decodable {
                struct Hit: Decodable {
                    struct Result: Decodable {
                        let path: String
                        let title: String
                    }
                    let result: Result
                }
                let hits: [Hit]
            }
            let response: ResponseData
        }

        let decoded = try JSONDecoder().decode(GeniusSearchResponse.self, from: data)
        guard let firstHit = decoded.response.hits.first else { return nil }

        // Fetch HTML page to scrape container
        guard let pageURL = URL(string: "https://genius.com\(firstHit.result.path)") else { return nil }
        var pageReq = URLRequest(url: pageURL)
        pageReq.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (htmlData, _) = try await session.data(for: pageReq)
        guard let html = String(data: htmlData, encoding: .utf8) else { return nil }

        return extractGeniusLyricsFromHTML(html)
    }

    /// Saves companion .lrc file matching track name: "01 Watch Them People (Intro).lrc"
    public func saveCompanionLrc(lyricsText: String, audioFileURL: URL) throws -> URL {
        let parentDir = audioFileURL.deletingLastPathComponent()
        let baseName = audioFileURL.deletingPathExtension().lastPathComponent
        let lrcURL = parentDir.appendingPathComponent("\(baseName).lrc")
        try lyricsText.write(to: lrcURL, atomically: true, encoding: .utf8)
        return lrcURL
    }

    private func extractGeniusLyricsFromHTML(_ html: String) -> String? {
        // Basic pattern matching for Genius lyrics containers
        let pattern = #"<div[^>]*data-lyrics-container="true"[^>]*>(.*?)</div>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return nil
        }
        let nsHtml = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsHtml.length))
        guard !matches.isEmpty else { return nil }

        var rawLyrics = ""
        for match in matches {
            let containerHTML = nsHtml.substring(with: match.range(at: 1))
            let textWithNewlines = containerHTML.replacingOccurrences(of: "<br/>", with: "\n")
                .replacingOccurrences(of: "<br>", with: "\n")
            // Strip remaining HTML tags
            let cleanChunk = textWithNewlines.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            rawLyrics += cleanChunk + "\n"
        }
        let trimmed = rawLyrics.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
