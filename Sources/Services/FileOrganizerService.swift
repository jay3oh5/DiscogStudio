import Foundation

public protocol FileOrganizerServiceProtocol: Sendable {
    func purgeJunkFiles(in directoryURL: URL) throws -> Int
    func standardizeTrackFilenames(in album: Album) throws -> [(oldURL: URL, newURL: URL)]
    func standardizeAlbumFolder(album: Album) throws -> URL
}

public final class FileOrganizerService: FileOrganizerServiceProtocol, @unchecked Sendable {
    public static let shared = FileOrganizerService()

    private let junkFileNames: Set<String> = [
        ".DS_Store",
        "Thumbs.db",
        "desktop.ini",
        ".localized"
    ]

    private let junkExtensions: Set<String> = [
        "m3u",
        "m3u8",
        "cue",
        "log",
        "nfo",
        "sfv"
    ]

    public init() {}

    /// Removes .DS_Store, AppleDouble ._* files, and stray playlist/log files
    public func purgeJunkFiles(in directoryURL: URL) throws -> Int {
        var purgedCount = 0
        let fm = FileManager.default
        let enumerator = fm.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: []
        )

        while let fileURL = enumerator?.nextObject() as? URL {
            let filename = fileURL.lastPathComponent
            let ext = fileURL.pathExtension.lowercased()

            if junkFileNames.contains(filename) ||
               filename.hasPrefix("._") ||
               junkExtensions.contains(ext) {
                try? fm.removeItem(at: fileURL)
                purgedCount += 1
            }
        }
        return purgedCount
    }

    /// Renames tracks and companion .lrc to the standard: "01 Track Title.m4a" and "01 Track Title.lrc"
    public func standardizeTrackFilenames(in album: Album) throws -> [(oldURL: URL, newURL: URL)] {
        let fm = FileManager.default
        var renamed: [(oldURL: URL, newURL: URL)] = []

        for track in album.tracks {
            let targetTrackName = track.standardFilename
            let targetTrackURL = album.directoryURL.appendingPathComponent(targetTrackName)

            if track.fileURL != targetTrackURL && !fm.fileExists(atPath: targetTrackURL.path) {
                try fm.moveItem(at: track.fileURL, to: targetTrackURL)
                renamed.append((track.fileURL, targetTrackURL))
            }

            // Rename companion LRC if exists
            if let lrcURL = track.companionLrcURL, fm.fileExists(atPath: lrcURL.path) {
                let targetLrcName = track.standardLrcFilename
                let targetLrcURL = album.directoryURL.appendingPathComponent(targetLrcName)
                if lrcURL != targetLrcURL && !fm.fileExists(atPath: targetLrcURL.path) {
                    try fm.moveItem(at: lrcURL, to: targetLrcURL)
                    renamed.append((lrcURL, targetLrcURL))
                }
            }
        }

        return renamed
    }

    /// Renames album folder according to category standard (e.g. "Tha Carter II - ℗ 2005" or "Dedication - 2005")
    public func standardizeAlbumFolder(album: Album) throws -> URL {
        guard let year = album.year else { return album.directoryURL }
        let standardName = album.category.formattedFolderName(title: album.title, year: year)
        let parentDir = album.directoryURL.deletingLastPathComponent()
        let newURL = parentDir.appendingPathComponent(standardName)

        if album.directoryURL != newURL && !FileManager.default.fileExists(atPath: newURL.path) {
            try FileManager.default.moveItem(at: album.directoryURL, to: newURL)
            return newURL
        }
        return album.directoryURL
    }
}
