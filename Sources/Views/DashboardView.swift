import SwiftUI

public struct DashboardView: View {
    @EnvironmentObject var state: AppState

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Discography Health Dashboard")
                        .font(.system(size: 26, weight: .bold))
                    Text("Live inspection and curation metrics for your lossless library")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Metric Cards
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 16) {
                    MetricCard(
                        title: "Total Albums",
                        value: "\(state.albums.count)",
                        icon: "square.stack",
                        color: .blue
                    )
                    MetricCard(
                        title: "Total Tracks",
                        value: "\(state.albums.reduce(0) { $0 + $1.totalTracksCount })",
                        icon: "music.note.list",
                        color: .purple
                    )
                    MetricCard(
                        title: "Missing LRC Files",
                        value: "\(state.albums.reduce(0) { $0 + $1.missingLrcCount })",
                        icon: "quote.bubble",
                        color: .orange
                    )
                    MetricCard(
                        title: "Low-Res Covers (<1000px)",
                        value: "\(state.albums.filter { !$0.isCoverSufficient }.count)",
                        icon: "photo.badge.exclamationmark",
                        color: .red
                    )
                }

                Divider()

                // Active Persona Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Active Purchaser Persona")
                        .font(.headline)
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 32))
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(state.activePersona.name)
                                .font(.headline)
                            Text(state.activePersona.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(state.activePersona.isPublicSharing ? "Public (Soulseek QT)" : "Personal (Commercial)")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.secondary.opacity(0.15)))
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
                }

                // Quick Scan Trigger
                Button {
                    if let root = state.libraryRootURL {
                        Task {
                            await state.scanDirectory(url: root)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text(state.isScanning ? "Auditing Library..." : "Audit Discography Library")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(state.isScanning)
            }
            .padding(28)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            Text(value)
                .font(.system(size: 28, weight: .bold))
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
    }
}
