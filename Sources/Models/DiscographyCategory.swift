import Foundation

public enum DiscographyCategory: String, CaseIterable, Identifiable, Codable {
    case soloStudioAlbums = "Solo Studio Albums"
    case mixtapes = "Mixtapes"
    case collaborativeAlbums = "Collaborative Albums"
    case epsAndSingles = "EPs & Singles"
    case compilations = "Compilations"
    case liveAlbums = "Live Albums"
    case bootlegsAndUnreleased = "Bootlegs & Unreleased"

    public var id: String { rawValue }

    /// Whether this category represents commercial retail releases using the copyright symbol (℗)
    public var usesCopyrightSymbol: Bool {
        switch self {
        case .soloStudioAlbums, .collaborativeAlbums, .epsAndSingles, .compilations, .liveAlbums:
            return true
        case .mixtapes, .bootlegsAndUnreleased:
            return false
        }
    }

    /// Formats the folder name following library conventions
    public func formattedFolderName(title: String, year: Int) -> String {
        if usesCopyrightSymbol {
            return "\(title) - ℗ \(year)"
        } else {
            return "\(title) - \(year)"
        }
    }
}
