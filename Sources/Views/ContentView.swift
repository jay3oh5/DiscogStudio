import SwiftUI

enum NavigationItem: Hashable {
    case dashboard
    case ingest
    case settings
    case album(String)
}

public struct ContentView: View {
    @EnvironmentObject var state: AppState
    @State private var selection: NavigationItem? = .dashboard

    public init() {}

    public var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Overview") {
                    NavigationLink(value: NavigationItem.dashboard) {
                        Label("Dashboard", systemImage: "gauge.with.needle")
                    }
                    NavigationLink(value: NavigationItem.ingest) {
                        Label("Ingest Drop Pad", systemImage: "arrow.down.doc")
                    }
                }

                Section("Albums & Mixtapes (\(state.albums.count))") {
                    ForEach(state.albums) { album in
                        NavigationLink(value: NavigationItem.album(album.id)) {
                            HStack {
                                Label(album.title, systemImage: album.category == .mixtapes ? "music.note" : "opticaldisc")
                                Spacer()
                                if !album.isFullyCompliant {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                    }
                }

                Section("Configuration") {
                    NavigationLink(value: NavigationItem.settings) {
                        Label("Settings & Personas", systemImage: "gearshape")
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("DiscogStudio")
        } detail: {
            switch selection {
            case .dashboard, .none:
                DashboardView()
            case .ingest:
                IngestDropView()
            case .settings:
                SettingsView()
            case .album(let albumID):
                if let album = state.albums.first(where: { $0.id == albumID }) {
                    AlbumDetailView(album: album)
                } else {
                    Text("Select an album to inspect")
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}
