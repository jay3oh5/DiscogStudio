import SwiftUI
import UniformTypeIdentifiers

public struct IngestDropView: View {
    @EnvironmentObject var state: AppState
    @State private var isTargeted = false
    @State private var droppedPath: String?

    public init() {}

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: [8])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isTargeted ? Color.accentColor.opacity(0.08) : Color.clear)
                    )
                    .frame(maxWidth: 500, maxHeight: 280)

                VStack(spacing: 16) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 48))
                        .foregroundColor(isTargeted ? .accentColor : .secondary)

                    VStack(spacing: 6) {
                        Text("Drop Album or Mixtape Folder Here")
                            .font(.title3.weight(.semibold))
                        Text("Drag folders from Finder or 'Working ON it' to start ingestion")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let path = droppedPath {
                        Text("Ready to process: \(URL(fileURLWithPath: path).lastPathComponent)")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.green.opacity(0.15)))
                            .foregroundColor(.green)
                    }
                }
            }
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                guard let provider = providers.first else { return false }
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    guard let url = url else { return }
                    DispatchQueue.main.async {
                        self.droppedPath = url.path
                        Task {
                            await state.scanDirectory(url: url)
                        }
                    }
                }
                return true
            }

            Spacer()
        }
        .padding()
    }
}
