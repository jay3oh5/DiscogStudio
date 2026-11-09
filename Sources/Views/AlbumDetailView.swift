import SwiftUI

public struct AlbumDetailView: View {
    @EnvironmentObject var state: AppState
    let album: Album

    public init(album: Album) {
        self.album = album
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Banner
                HStack(spacing: 20) {
                    // Artwork Thumbnail with Badge
                    ZStack(alignment: .bottomTrailing) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(width: 140, height: 140)
                            .cornerRadius(10)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                            )

                        if let res = album.coverResolution {
                            Text("\(Int(res.width))x\(Int(res.height))")
                                .font(.system(size: 10, weight: .bold))
                                .padding(4)
                                .background(res.width >= 1000 ? Color.green : Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                                .padding(6)
                        } else {
                            Text("No Cover")
                                .font(.system(size: 10, weight: .bold))
                                .padding(4)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                                .padding(6)
                        }
                    }

                    // Metadata details
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(album.category.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                                .foregroundColor(.accentColor)

                            if let year = album.year {
                                Text(album.category.usesCopyrightSymbol ? "℗ \(year)" : "\(year)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Text(album.title)
                            .font(.system(size: 22, weight: .bold))

                        Text(album.artist)
                            .font(.title3)
                            .foregroundColor(.secondary)

                        Text("\(album.totalTracksCount) Tracks • \(album.missingLrcCount) Missing LRC • \(album.lowResArtworkCount) Low-Res")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.06)))

                // Quick Action Bar
                HStack(spacing: 12) {
                    Button {
                        // Action: Run pipeline
                    } label: {
                        Label("Run Full Pipeline", systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        // Action: Fetch lyrics
                    } label: {
                        Label("Generate LRCs", systemImage: "quote.bubble")
                    }

                    Button {
                        // Action: Fetch high-res art
                    } label: {
                        Label("Fetch High-Res Art", systemImage: "photo")
                    }

                    Button {
                        // Action: Watermark
                    } label: {
                        Label("Apply Watermark", systemImage: "lock.shield")
                    }

                    Button {
                        // Action: Purge Junk
                        _ = try? FileOrganizerService.shared.purgeJunkFiles(in: album.directoryURL)
                    } label: {
                        Label("Purge Junk", systemImage: "trash")
                    }
                }

                Divider()

                // Tracks List
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tracks & Dependencies (\(album.tracks.count))")
                        .font(.headline)

                    ForEach(album.tracks) { track in
                        HStack(spacing: 12) {
                            Text(String(format: "%02d", track.trackNumber))
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 28, alignment: .leading)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.title)
                                    .font(.body)
                                Text(track.standardFilename)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            // Status Pills
                            HStack(spacing: 6) {
                                StatusBadge(label: "M4A", isGreen: true)
                                StatusBadge(label: "LRC", isGreen: track.hasCompanionLrc)
                                StatusBadge(label: "Genius", isGreen: track.hasEmbeddedLyrics)
                                StatusBadge(label: "Pinf", isGreen: track.hasFairPlayAtom)
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.04)))
                    }
                }
            }
            .padding(24)
        }
    }
}

struct StatusBadge: View {
    let label: String
    let isGreen: Bool

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(isGreen ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
            .foregroundColor(isGreen ? .green : .red)
            .cornerRadius(4)
    }
}
