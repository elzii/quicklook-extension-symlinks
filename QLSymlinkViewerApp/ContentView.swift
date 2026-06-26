import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "link.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("QL Symlink Viewer")
                .font(.title)
                .fontWeight(.semibold)

            Text("Provides QuickLook previews for symbolic links and macOS aliases.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 380)

            Divider()
                .frame(maxWidth: 380)

            VStack(alignment: .leading, spacing: 8) {
                Label("Press **Space** on a symlink or alias in Finder", systemImage: "hand.point.up.left")
                Label("The preview shows the link path and its resolved target", systemImage: "scope")
            }
            .font(.subheadline)
            .frame(maxWidth: 380, alignment: .leading)

            Spacer()
        }
        .padding(32)
    }
}
