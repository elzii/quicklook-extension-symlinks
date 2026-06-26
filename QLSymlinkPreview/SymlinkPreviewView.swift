import SwiftUI
import AppKit

// MARK: - Main preview view

struct SymlinkPreviewView: View {
    let info: SymlinkFileInfo

    private var typeEmoji: String { info.kind == .alias ? "↔️" : "🔗" }
    private var typeLabel: String { info.kind == .alias ? "ALIAS" : "SYMLINK" }
    private var fileIcon: NSImage { NSWorkspace.shared.icon(forFile: info.fileURL.path) }
    private var sourceButtonTitle: String { "Show \(info.kind == .alias ? "Alias" : "Symlink") in Finder" }

    private var targetSizeText: String? {
        guard let target = info.targetURL else { return nil }
        guard let values = try? target.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .totalFileSizeKey]) else {
            return nil
        }
        if values.isDirectory == true {
            return nil
        }

        guard let bytes = values.totalFileSize ?? values.fileSize else {
            return nil
        }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // ── Header: icon + name ──────────────────────────────────
                HStack(spacing: 16) {
                    Image(nsImage: fileIcon)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 64, height: 64)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(info.fileURL.lastPathComponent)
                            .font(.title2.weight(.semibold))
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Label(typeLabel, systemImage: info.kind == .alias ? "arrow.triangle.swap" : "link")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)

                Divider().padding(.horizontal, 24)

                // ── Info rows ─────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 18) {

                    // 🔗 / ↔️  source path
                    PathRow(
                        label: "\(typeEmoji)  \(typeLabel)",
                        path:  info.fileURL.path,
                        color: .blue
                    )
                    Button(sourceButtonTitle) {
                        NSWorkspace.shared.activateFileViewerSelecting([info.fileURL])
                    }

                    Divider()

                    // 🎯 target
                    if let target = info.targetURL {
                        PathRow(
                            label: "🎯  TARGET",
                            path:  target.path,
                            color: info.targetExists ? .green : .red
                        )
                        if let targetSizeText {
                            Text(targetSizeText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Button("Show Target in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([target])
                        }

                        if !info.targetExists {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("Target does not exist (broken link)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, -8)
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(.orange)
                            Text("Could not resolve target")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(24)

                Spacer(minLength: 0)
            }
        }
        .frame(minWidth: 480, minHeight: 220)
    }
}

// MARK: - Reusable path row

private struct PathRow: View {
    let label: String
    let path: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)

            Text(path)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
