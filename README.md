# DiscogStudio 🎵

A native macOS SwiftUI application designed to curate, standardize, and maintain a gold-standard music discography library.

Built to replace fragmented terminal scripts with a cohesive, visual pipeline engine for organizing audio files (`.m4a`), companion synced lyrics (`.lrc`), high-resolution square cover art (`cover.jpg`), and Apple Music FairPlay watermarking / mixtape neutralization.

---

## 🏛 Library Standard & Specification

Every processed release strictly adheres to the following discography architecture:

| Component | Standard |
| :--- | :--- |
| **Folder Hierarchy** | `Discography/<Artist>/<Category>/<Album Title> - ℗ <Year>/`<br>*(Mixtapes omit `℗`: `<Title> - <Year>`)* |
| **Track Filenames** | Zero-padded: `01 Track Title.m4a` |
| **Companion LRC** | Strictly paired `01 Track Title.lrc` with millisecond timestamps |
| **Album Artwork** | Square embedded `covr` atom + local `cover.jpg` ($\ge 1000 \times 1000$ px) |
| **Lyrics Standard** | **Dual lyrics**: Plain structured lyrics (`[Intro]`, `[Verse]`, `[Chorus]`) embedded into tags + companion `.lrc` file |
| **Watermarking** | FairPlay `pinf` atom + `apID` + `ownr` + `purd` (July 30, 2015 baseline cutoff) for commercial; **neutralized** for free mixtapes |
| **Encoder Hygiene** | Strips `©too` and `©enc` (XLD, Lavf, etc.) |
| **System Hygiene** | Automatic purge of `.DS_Store`, AppleDouble `._*`, `.cue`, `.m3u`, and empty folders |

---

## 🚀 The 8 Pipeline Stages

1. **Ingest & Category Detection**: Automatically detects artist, album title, release year, and routes to appropriate category (`Solo Studio Albums`, `Mixtapes`, `EPs & Singles`, `Collaborative Albums`, `Compilations`, `Live Albums`).
2. **Audio Container Verification**: Validates M4A (AAC / ALAC) containers.
3. **Metadata & Tag Mastery**: Queries iTunes Store API and MusicBrainz for canonical tracklists, composers, disc numbers, explicit ratings (`rtng`).
4. **Multi-Source High-Res Artwork**:
   - **Primary (Commercial)**: Apple Music CDN up to 3000x3000px.
   - **Secondary (Mixtapes / Underground)**: Genius API / CDN cover extraction.
   - **Tertiary**: Cover Art Archive (MusicBrainz).
   - **Fallback**: Local file tag extraction & resolution verification ($\ge 1000\times 1000$).
5. **Dual-Lyrics Engine**:
   - Fetches millisecond-synced `.lrc` companion files via LRCLIB open API.
   - Scrapes structured plain-text lyrics from Genius (`[Verse]`, `[Chorus]`) and embeds them into `©lyr`.
6. **FairPlay & Persona Watermarking**:
   - Injects FairPlay `pinf` atom and authentic post-2015 purchase dates.
   - Supports persona switching: **Personal** (`Jonathan Del Rio`) vs. **Public Sharing** (`Marcus Sterling`).
   - Neutralizes free mixtapes and SoundCloud drops so they remain genuine AAC audio files.
7. **File & Folder Standardization**: Renames all files and folders to exact library standards and purges OS junk.
8. **Apple Music Refresh & Mirror**: Triggers Music.app library refresh via AppleScript and syncs to remote SMB server via `rclone`.

---

## 🛠 Project Structure

```
DiscogStudio/
├── Package.swift               # Swift Package Manager manifest (macOS 14+)
├── README.md
├── .gitignore
└── Sources/
    ├── App/
    │   ├── DiscogStudioApp.swift   # Main app entrypoint
    │   └── AppState.swift          # Observable central state
    ├── Models/
    │   ├── Album.swift             # Album data model & compliance checks
    │   ├── Track.swift             # Track model & standard filename logic
    │   ├── Persona.swift           # Purchaser persona profiles
    │   ├── DiscographyCategory.swift # Categories & naming rules
    │   └── PipelineStatus.swift    # Stage definitions & progress tracking
    ├── Services/
    │   ├── MetadataService.swift   # iTunes Store API + MusicBrainz fallback
    │   ├── ArtworkService.swift    # Apple CDN + Genius + CoverArtArchive
    │   ├── LyricsService.swift     # LRCLIB synced .lrc + Genius plain lyrics
    │   ├── FairPlayService.swift   # FairPlay pinf injection & mixtape stripper
    │   └── FileOrganizerService.swift # Renamer & .DS_Store junk purger
    └── Views/
        ├── ContentView.swift       # NavigationSplitView sidebar layout
        ├── DashboardView.swift     # Health & metrics overview
        ├── AlbumDetailView.swift   # Album inspector & track dependency pills
        ├── IngestDropView.swift    # Drag-and-drop landing pad
        └── SettingsView.swift      # Personas & API configuration
```

---

## 💻 Building & Running

### Requirements
- macOS 14.0 (Sonoma) or newer
- Swift 6.0+ / Xcode 16+ or CommandLineTools

### Quick Build
```bash
# Build the project
swift build

# Run the app
swift run
```
Or open the package directly in Xcode:
```bash
open Package.swift
```

---

## 📄 License
MIT License.
