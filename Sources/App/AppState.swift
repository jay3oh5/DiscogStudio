import SwiftUI
import Foundation

@MainActor
public final class AppState: ObservableObject {
    @Published public var albums: [Album] = []
    @Published public var selectedAlbumID: String?
    @Published public var isScanning: Bool = false
    @Published public var progress: PipelineProgress = PipelineProgress()
    
    // Settings & Personas
    @Published public var personas: [Persona] = Persona.standardPersonas
    @Published public var activePersonaIndex: Int = 0
    @Published public var geniusToken: String = ""
    @Published public var libraryRootURL: URL? = URL(fileURLWithPath: "/Users/jd/Music/Discography")
    @Published public var minimumArtworkResolution: CGFloat = 1000.0

    public var activePersona: Persona {
        guard activePersonaIndex >= 0 && activePersonaIndex < personas.count else {
            return Persona.standardPersonas[0]
        }
        return personas[activePersonaIndex]
    }

    public var selectedAlbum: Album? {
        albums.first { $0.id == selectedAlbumID }
    }

    public init() {
        loadGeniusToken()
    }

    public func loadGeniusToken() {
        let tokenPath = ("~/.genius_token" as NSString).expandingTildeInPath
        if let token = try? String(contentsOfFile: tokenPath, encoding: .utf8) {
            self.geniusToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    public func scanDirectory(url: URL) async {
        isScanning = true
        progress = PipelineProgress(
            currentStep: .verifyAudio,
            totalItems: 1,
            completedItems: 0,
            message: "Scanning directory: \(url.lastPathComponent)...",
            isRunning: true
        )

        var scanned: [Album] = []
        let fm = FileManager.default
        let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        var albumURLs: [URL] = []
        while let item = enumerator?.nextObject() as? URL {
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: item.path, isDirectory: &isDir), isDir.boolValue {
                // Check if directory contains audio files
                if let files = try? fm.contentsOfDirectory(atPath: item.path) {
                    if files.contains(where: { $0.hasSuffix(".m4a") || $0.hasSuffix(".mp3") || $0.hasSuffix(".flac") }) {
                        albumURLs.append(item)
                    }
                }
            }
        }

        // Parse found albums
        for albumURL in albumURLs {
            let albumName = albumURL.lastPathComponent
            let tracks = parseTracks(in: albumURL)
            let coverURL = albumURL.appendingPathComponent("cover.jpg")
            let hasCover = fm.fileExists(atPath: coverURL.path)
            let res = hasCover ? ArtworkService.shared.inspectImageResolution(url: coverURL) : nil

            // Detect category from path
            var cat: DiscographyCategory = .soloStudioAlbums
            let pathLower = albumURL.path.lowercased()
            if pathLower.contains("mixtape") {
                cat = .mixtapes
            } else if pathLower.contains("single") || pathLower.contains("ep") {
                cat = .epsAndSingles
            }

            let album = Album(
                directoryURL: albumURL,
                artist: tracks.first?.artist ?? "Unknown Artist",
                title: albumName,
                year: tracks.first?.year,
                category: cat,
                coverImageURL: hasCover ? coverURL : nil,
                coverResolution: res,
                tracks: tracks
            )
            scanned.append(album)
        }

        self.albums = scanned
        if selectedAlbumID == nil, let first = scanned.first {
            selectedAlbumID = first.id
        }
        isScanning = false
        progress.isRunning = false
        progress.message = "Scan complete. Found \(scanned.count) albums."
    }

    private func parseTracks(in albumURL: URL) -> [Track] {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: albumURL.path) else { return [] }
        let audioFiles = files.filter { $0.hasSuffix(".m4a") || $0.hasSuffix(".mp3") }
        
        return audioFiles.sorted().enumerated().map { index, file in
            let trackURL = albumURL.appendingPathComponent(file)
            let lrcName = (file as NSString).deletingPathExtension + ".lrc"
            let lrcURL = albumURL.appendingPathComponent(lrcName)
            let hasLrc = FileManager.default.fileExists(atPath: lrcURL.path)

            return Track(
                fileURL: trackURL,
                companionLrcURL: hasLrc ? lrcURL : nil,
                title: (file as NSString).deletingPathExtension,
                trackNumber: index + 1,
                totalTracks: audioFiles.count,
                hasCompanionLrc: hasLrc
            )
        }
    }
}
