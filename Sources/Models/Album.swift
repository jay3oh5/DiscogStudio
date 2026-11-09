import Foundation

public struct Album: Identifiable, Codable, Hashable {
    public var id: String { directoryURL.path }
    public var directoryURL: URL
    public var artist: String
    public var title: String
    public var year: Int?
    public var category: DiscographyCategory
    public var coverImageURL: URL?
    public var coverResolution: CGSize?
    public var tracks: [Track]

    public init(
        directoryURL: URL,
        artist: String = "",
        title: String = "",
        year: Int? = nil,
        category: DiscographyCategory = .soloStudioAlbums,
        coverImageURL: URL? = nil,
        coverResolution: CGSize? = nil,
        tracks: [Track] = []
    ) {
        self.directoryURL = directoryURL
        self.artist = artist
        self.title = title
        self.year = year
        self.category = category
        self.coverImageURL = coverImageURL
        self.coverResolution = coverResolution
        self.tracks = tracks
    }

    public var totalTracksCount: Int {
        tracks.count
    }

    public var missingLrcCount: Int {
        tracks.filter { !$0.hasCompanionLrc }.count
    }

    public var missingEmbeddedLyricsCount: Int {
        tracks.filter { !$0.hasEmbeddedLyrics }.count
    }

    public var lowResArtworkCount: Int {
        tracks.filter {
            guard let res = $0.artworkResolution else { return true }
            return res.width < 1000 || res.height < 1000
        }.count
    }

    public var isCoverSufficient: Bool {
        guard let res = coverResolution else { return false }
        return res.width >= 1000 && res.height >= 1000
    }

    public var isFullyCompliant: Bool {
        missingLrcCount == 0 &&
        missingEmbeddedLyricsCount == 0 &&
        isCoverSufficient &&
        lowResArtworkCount == 0
    }
}
