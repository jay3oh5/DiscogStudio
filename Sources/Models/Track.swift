import Foundation

public struct Track: Identifiable, Codable, Hashable {
    public var id: String { fileURL.path }
    public var fileURL: URL
    public var companionLrcURL: URL?
    
    // Tag metadata
    public var title: String
    public var artist: String
    public var albumArtist: String
    public var album: String
    public var trackNumber: Int
    public var totalTracks: Int
    public var discNumber: Int
    public var totalDiscs: Int
    public var year: Int?
    public var releaseDate: String?
    public var genre: String?
    public var composer: String?
    public var isExplicit: Bool?
    
    // Artwork & Dependencies
    public var artworkResolution: CGSize?
    public var hasEmbeddedLyrics: Bool
    public var hasCompanionLrc: Bool { companionLrcURL != nil && FileManager.default.fileExists(atPath: companionLrcURL!.path) }
    
    // FairPlay / Watermark info
    public var hasFairPlayAtom: Bool
    public var purchaserEmail: String?
    public var purchaserName: String?
    public var purchaseDate: String?
    public var encoderTag: String?

    public init(
        fileURL: URL,
        companionLrcURL: URL? = nil,
        title: String = "",
        artist: String = "",
        albumArtist: String = "",
        album: String = "",
        trackNumber: Int = 1,
        totalTracks: Int = 1,
        discNumber: Int = 1,
        totalDiscs: Int = 1,
        year: Int? = nil,
        releaseDate: String? = nil,
        genre: String? = nil,
        composer: String? = nil,
        isExplicit: Bool? = nil,
        artworkResolution: CGSize? = nil,
        hasEmbeddedLyrics: Bool = false,
        hasFairPlayAtom: Bool = false,
        purchaserEmail: String? = nil,
        purchaserName: String? = nil,
        purchaseDate: String? = nil,
        encoderTag: String? = nil
    ) {
        self.fileURL = fileURL
        self.companionLrcURL = companionLrcURL
        self.title = title
        self.artist = artist
        self.albumArtist = albumArtist
        self.album = album
        self.trackNumber = trackNumber
        self.totalTracks = totalTracks
        self.discNumber = discNumber
        self.totalDiscs = totalDiscs
        self.year = year
        self.releaseDate = releaseDate
        self.genre = genre
        self.composer = composer
        self.isExplicit = isExplicit
        self.artworkResolution = artworkResolution
        self.hasEmbeddedLyrics = hasEmbeddedLyrics
        self.hasFairPlayAtom = hasFairPlayAtom
        self.purchaserEmail = purchaserEmail
        self.purchaserName = purchaserName
        self.purchaseDate = purchaseDate
        self.encoderTag = encoderTag
    }

    /// Expected filename formatted to library standard: "01 Watch Them People (Intro).m4a"
    public var standardFilename: String {
        let pad = totalTracks >= 100 ? 3 : 2
        let num = String(format: "%0*d", pad, trackNumber)
        let ext = fileURL.pathExtension
        let safeTitle = title.isEmpty ? fileURL.deletingPathExtension().lastPathComponent : title
        return "\(num) \(safeTitle).\(ext)"
    }

    /// Expected companion LRC filename: "01 Watch Them People (Intro).lrc"
    public var standardLrcFilename: String {
        let pad = totalTracks >= 100 ? 3 : 2
        let num = String(format: "%0*d", pad, trackNumber)
        let safeTitle = title.isEmpty ? fileURL.deletingPathExtension().lastPathComponent : title
        return "\(num) \(safeTitle).lrc"
    }
}
