import Foundation

public enum PipelineStep: String, CaseIterable, Identifiable {
    case verifyAudio = "Audio Verification"
    case fetchMetadata = "Metadata & Tagging"
    case fetchArtwork = "Artwork Resolution Check & Fetch"
    case fetchLyrics = "Genius & Synced LRC Generation"
    case applyWatermark = "FairPlay Watermark / Mixtape Neutralization"
    case purgeEncoder = "Encoder Signature Stripping"
    case organizeFiles = "File Renaming & Junk Purge"
    case refreshLibrary = "Apple Music Sync"

    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .verifyAudio: return "waveform"
        case .fetchMetadata: return "tag"
        case .fetchArtwork: return "photo.artframe"
        case .fetchLyrics: return "quote.bubble"
        case .applyWatermark: return "lock.shield"
        case .purgeEncoder: return "wand.and.stars"
        case .organizeFiles: return "folder.badge.gearshape"
        case .refreshLibrary: return "arrow.triangle.2.circlepath"
        }
    }
}

public struct PipelineProgress: Identifiable {
    public var id = UUID()
    public var currentStep: PipelineStep
    public var totalItems: Int
    public var completedItems: Int
    public var message: String
    public var isRunning: Bool
    public var hasError: Bool

    public var percentage: Double {
        guard totalItems > 0 else { return 0 }
        return Double(completedItems) / Double(totalItems)
    }

    public init(
        currentStep: PipelineStep = .verifyAudio,
        totalItems: Int = 0,
        completedItems: Int = 0,
        message: String = "Ready",
        isRunning: Bool = false,
        hasError: Bool = false
    ) {
        self.currentStep = currentStep
        self.totalItems = totalItems
        self.completedItems = completedItems
        self.message = message
        self.isRunning = isRunning
        self.hasError = hasError
    }
}
