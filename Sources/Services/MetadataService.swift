import Foundation

public protocol MetadataServiceProtocol: Sendable {
    func searchiTunes(artist: String, album: String) async throws -> [AlbumMetadataResult]
    func searchMusicBrainz(artist: String, album: String) async throws -> [AlbumMetadataResult]
}

public struct AlbumMetadataResult: Identifiable, Codable, Sendable {
    public var id: String
    public var artistName: String
    public var collectionName: String
    public var releaseDate: String?
    public var releaseYear: Int?
    public var primaryGenreName: String?
    public var artworkUrl100: String?
    public var trackCount: Int?
    public var isCommercial: Bool
    public var copyright: String?

    public init(
        id: String,
        artistName: String,
        collectionName: String,
        releaseDate: String? = nil,
        releaseYear: Int? = nil,
        primaryGenreName: String? = nil,
        artworkUrl100: String? = nil,
        trackCount: Int? = nil,
        isCommercial: Bool = true,
        copyright: String? = nil
    ) {
        self.id = id
        self.artistName = artistName
        self.collectionName = collectionName
        self.releaseDate = releaseDate
        self.releaseYear = releaseYear
        self.primaryGenreName = primaryGenreName
        self.artworkUrl100 = artworkUrl100
        self.trackCount = trackCount
        self.isCommercial = isCommercial
        self.copyright = copyright
    }

    /// Highest resolution artwork URL from Apple CDN (3000x3000)
    public var highResArtworkURL: URL? {
        guard let raw = artworkUrl100 else { return nil }
        let highResStr = raw.replacingOccurrences(of: "100x100bb.jpg", with: "3000x3000bb.jpg")
            .replacingOccurrences(of: "100x100bb", with: "3000x3000bb")
        return URL(string: highResStr)
    }
}

public final class MetadataService: MetadataServiceProtocol, @unchecked Sendable {
    public static let shared = MetadataService()

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Queries iTunes Store API for commercial release verification and full metadata
    public func searchiTunes(artist: String, album: String) async throws -> [AlbumMetadataResult] {
        let term = "\(artist) \(album)"
        guard let encodedTerm = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?term=\(encodedTerm)&entity=album&limit=10") else {
            return []
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }

        struct iTunesResponse: Decodable {
            struct iTunesItem: Decodable {
                let collectionId: Int?
                let artistName: String?
                let collectionName: String?
                let releaseDate: String?
                let primaryGenreName: String?
                let artworkUrl100: String?
                let trackCount: Int?
                let copyright: String?
            }
            let resultCount: Int
            let results: [iTunesItem]
        }

        let decoded = try JSONDecoder().decode(iTunesResponse.self, from: data)
        return decoded.results.compactMap { item in
            guard let id = item.collectionId, let artist = item.artistName, let name = item.collectionName else {
                return nil
            }
            var year: Int?
            if let dateStr = item.releaseDate, dateStr.count >= 4, let y = Int(dateStr.prefix(4)) {
                year = y
            }
            return AlbumMetadataResult(
                id: String(id),
                artistName: artist,
                collectionName: name,
                releaseDate: item.releaseDate,
                releaseYear: year,
                primaryGenreName: item.primaryGenreName,
                artworkUrl100: item.artworkUrl100,
                trackCount: item.trackCount,
                isCommercial: true,
                copyright: item.copyright
            )
        }
    }

    /// Fallback query using MusicBrainz for mixtapes, unofficial bootlegs, or rare vinyl
    public func searchMusicBrainz(artist: String, album: String) async throws -> [AlbumMetadataResult] {
        let query = "artist:\(artist) AND releasegroup:\(album)"
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://musicbrainz.org/ws/2/release-group/?query=\(encodedQuery)&fmt=json&limit=5") else {
            return []
        }

        var request = URLRequest(url: url)
        request.setValue("DiscogStudio/1.0.0 ( contact@example.com )", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }

        struct MBResponse: Decodable {
            struct ReleaseGroup: Decodable {
                let id: String
                let title: String
                let firstReleaseDate: String?
                let primaryType: String?
                enum CodingKeys: String, CodingKey {
                    case id, title
                    case firstReleaseDate = "first-release-date"
                    case primaryType = "primary-type"
                }
            }
            let releaseGroups: [ReleaseGroup]?
            enum CodingKeys: String, CodingKey {
                case releaseGroups = "release-groups"
            }
        }

        let decoded = try JSONDecoder().decode(MBResponse.self, from: data)
        return (decoded.releaseGroups ?? []).map { rg in
            var year: Int?
            if let dateStr = rg.firstReleaseDate, dateStr.count >= 4, let y = Int(dateStr.prefix(4)) {
                year = y
            }
            return AlbumMetadataResult(
                id: rg.id,
                artistName: artist,
                collectionName: rg.title,
                releaseDate: rg.firstReleaseDate,
                releaseYear: year,
                primaryGenreName: rg.primaryType,
                artworkUrl100: nil,
                trackCount: nil,
                isCommercial: false,
                copyright: nil
            )
        }
    }
}
