import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var state: AppState

    public init() {}

    public var body: some View {
        Form {
            Section(header: Text("Purchaser Watermark & Personas")) {
                Picker("Active Persona", selection: $state.activePersonaIndex) {
                    ForEach(0..<state.personas.count, id: \.self) { idx in
                        Text("\(state.personas[idx].name) (\(state.personas[idx].email))")
                            .tag(idx)
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    Text("Sharing Profile:")
                    Spacer()
                    Text(state.activePersona.isPublicSharing ? "Public (Soulseek QT Mode)" : "Personal (Commercial iTunes Mode)")
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("API Integrations")) {
                SecureField("Genius Access Token", text: $state.geniusToken)
                    .textFieldStyle(.roundedBorder)

                Text("Used for fetching structured plain lyrics ([Intro], [Verse]) and high-res cover art for mixtapes.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Section(header: Text("Quality Standards & Thresholds")) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Minimum Cover Art Resolution:")
                        Spacer()
                        Text("\(Int(state.minimumArtworkResolution)) x \(Int(state.minimumArtworkResolution)) px")
                            .bold()
                    }
                    Slider(value: $state.minimumArtworkResolution, in: 500...3000, step: 100)
                }

                if let root = state.libraryRootURL {
                    HStack {
                        Text("Discography Root:")
                        Spacer()
                        Text(root.path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(28)
    }
}
