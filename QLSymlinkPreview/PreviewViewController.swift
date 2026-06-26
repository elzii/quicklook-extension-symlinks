import Cocoa
import Quartz
import SwiftUI

// MARK: - Data model

enum SymlinkKind {
    case symlink
    case alias
}

struct SymlinkFileInfo {
    let fileURL: URL
    let kind: SymlinkKind
    /// Direct link destination (as written in the symlink), resolved to an absolute path.
    let targetURL: URL?
    /// Whether the resolved target path exists on disk.
    let targetExists: Bool

    static func detectKind(at url: URL) -> SymlinkKind? {
        // 1) Exact symlink detection (never follows links).
        var st = Darwin.stat()
        if Darwin.lstat(url.path, &st) == 0,
           (Int(st.st_mode) & Int(S_IFMT)) == Int(S_IFLNK) {
            return .symlink
        }

        // 2) If not a symlink, check Finder alias metadata first.
        if let values = try? url.resourceValues(forKeys: [.isAliasFileKey]),
           values.isAliasFile == true {
            return .alias
        }

        // 3) Fallback: some alias files may not report NSURLIsAliasFileKey
        // reliably in extension contexts. Resolve alias and only accept it
        // when the resolved path differs from the source path.
        if let resolved = try? URL(
            resolvingAliasFileAt: url,
            options: [.withoutUI, .withoutMounting]
        ) {
            if resolved.standardizedFileURL.path != url.standardizedFileURL.path {
                return .alias
            }
        }

        // 4) Everything else is regular.
        return nil
    }

    static func resolve(url: URL) -> SymlinkFileInfo {
        let kind = detectKind(at: url) ?? .symlink

        var targetURL: URL?
        if kind == .alias {
            targetURL = try? URL(resolvingAliasFileAt: url, options: [])
        } else {
            // For symlinks, show realpath when available.
            let resolved = url.resolvingSymlinksInPath()
            if resolved.standardized != url.standardized {
                targetURL = resolved
            }

            // For broken symlinks, keep showing the raw destination.
            if targetURL == nil,
               let dest = try? FileManager.default.destinationOfSymbolicLink(atPath: url.path) {
                targetURL = URL(fileURLWithPath: dest,
                                relativeTo: url.deletingLastPathComponent()).standardized
            }
        }

        let targetExists: Bool
        if let t = targetURL {
            targetExists = FileManager.default.fileExists(atPath: t.path)
        } else {
            targetExists = false
        }

        return SymlinkFileInfo(fileURL: url, kind: kind, targetURL: targetURL, targetExists: targetExists)
    }
}

// MARK: - QuickLook preview controller

final class PreviewViewController: NSViewController, QLPreviewingController {

    override var nibName: NSNib.Name? { nil }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 520, height: 300))
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        let kind = SymlinkFileInfo.detectKind(at: url)

        // If the file is neither a symlink nor an alias, bail out so QuickLook
        // can fall through to the next registered handler (e.g. the system folder preview).
        guard kind != nil else {
            handler(notSymlinkError())
            return
        }

        let info = SymlinkFileInfo.resolve(url: url)

        let hosting = NSHostingController(rootView: SymlinkPreviewView(info: info))
        addChild(hosting)

        let hv = hosting.view
        hv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hv)

        NSLayoutConstraint.activate([
            hv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hv.topAnchor.constraint(equalTo: view.topAnchor),
            hv.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        handler(nil)
    }

    func preparePreviewOfSearchableItem(identifier: String,
                                        queryString: String?,
                                        completionHandler handler: @escaping (Error?) -> Void) {
        let fileURL: URL?
        if identifier.hasPrefix("file://"),
           let url = URL(string: identifier),
           url.isFileURL {
            fileURL = url
        } else if identifier.hasPrefix("/") {
            fileURL = URL(fileURLWithPath: identifier)
        } else {
            fileURL = nil
        }

        guard let fileURL else {
            handler(notSymlinkError())
            return
        }

        preparePreviewOfFile(at: fileURL, completionHandler: handler)
    }

    // MARK: - Private

    private func notSymlinkError() -> NSError {
        NSError(domain: "com.azizzo.QLSymlinkPreview", code: 1)
    }
}
