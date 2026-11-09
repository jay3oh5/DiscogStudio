import Foundation
import ImageIO
#if canImport(AppKit)
import AppKit
#endif

public protocol ArtworkServiceProtocol: Sendable {
    func inspectImageResolution(url: URL) -> CGSize?
    func fetchAppleArtwork(artist: String, album: String) async throws -> URL?
    func fetchGeniusArtwork(artist: String, album: String, geniusToken: String?) async throws -> URL?
    func fetchCoverArtArchive(musicBrainzReleaseGroupID: String) async throws -> URL?
    func resolveBestArtwork(artist: String, album: String, isMixtape: Bool, geniusToken: String?) async throws -> URL?
    func saveArtworkAsCoverJpg(sourceImageURL: URL, destinationDirectory: URL) async throws -> URL
}

public final class ArtworkService: ArtworkServiceProtocol, @unchecked Sendable {
    public static let shared = ArtworkService()
    public static let minimumResolution: CGFloat = 1000.0

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Read resolution directly from file headers using ImageIO without loading full uncompressed bitmap
    public func inspectImageResolution(url: URL) -> CGSize? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return nil
        }
        guard let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat else {
            return nil
        }
        return CGSize(width: width, height: height)
    }

    /// Primary Source: Apple CDN up to 3000x3000px
    public func fetchAppleArtwork(artist: String, album: String) async throws -> URL? {
        let results = try await MetadataService.shared.searchiTunes(artist: artist, album: album)
        return results.first?.highResArtworkURL
    }

    /// Secondary Source (Crucial for Mixtapes & Unreleased Drops): Genius API
    public func fetchGeniusArtwork(artist: String, album: String, geniusToken: String?) async throws -> URL? {
        guard let token = geniusToken, !token.isEmpty else { return nil }
        let query = "\(artist) \(album)"
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
                        let headerImageUrl: String?
                        let songArtImageUrl: String?
                        enum CodingKeys: String, CodingKey {
                            case headerImageUrl = "header_image_url"
                            case songArtImageUrl = "song_art_image_url"
                        }
                    }
                    let result: Result
                }
                let hits: [Hit]
            }
            let response: ResponseData
        }

        let decoded = try JSONDecoder().decode(GeniusSearchResponse.self, from: data)
        for hit in decoded.response.hits {
            if let art = hit.result.songArtImageUrl, !art.contains("default_cover"), let artURL = URL(string: art) {
                return artURL
            }
        }
        return nil
    }

    /// Tertiary Source: Cover Art Archive (MusicBrainz)
    public func fetchCoverArtArchive(musicBrainzReleaseGroupID: String) async throws -> URL? {
        let candidateURL = URL(string: "https://coverartarchive.org/release-group/\(musicBrainzReleaseGroupID)/front-1200.jpg")
        guard let url = candidateURL else { return nil }

        var req = URLRequest(url: url)
        req.httpMethod = "HEAD"
        let (_, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) {
            return url
        }
        return nil
    }

    /// Orchestrates resolution across sources with priority:
    /// - Commercial albums: Apple CDN (3000x3000) -> Genius -> Cover Art Archive
    /// - Mixtapes / Unofficial: Genius -> Cover Art Archive -> Apple CDN
    public func resolveBestArtwork(
        artist: String,
        album: String,
        isMixtape: Bool,
        geniusToken: String?
    ) async throws -> URL? {
        if isMixtape {
            // Priority for mixtapes: Genius -> CoverArtArchive -> Apple
            if let geniusURL = try? await fetchGeniusArtwork(artist: artist, album: album, geniusToken: geniusToken) {
                return geniusURL
            }
            if let appleURL = try? await fetchAppleArtwork(artist: artist, album: album) {
                return appleURL
            }
        } else {
            // Priority for commercial: Apple -> Genius
            if let appleURL = try? await fetchAppleArtwork(artist: artist, album: album) {
                return appleURL
            }
            if let geniusURL = try? await fetchGeniusArtwork(artist: artist, album: album, geniusToken: geniusToken) {
                return geniusURL
            }
        }
        return nil
    }

    /// Downloads artwork and writes local high-res `cover.jpg`
    public func saveArtworkAsCoverJpg(sourceImageURL: URL, destinationDirectory: URL) async throws -> URL {
        let (data, _) = try await session.data(from: sourceImageURL)
        let destinationURL = destinationDirectory.appendingPathComponent("cover.jpg")
        try data.write(to: destinationURL, options: .atomic)
        return destinationURL
    }
}
