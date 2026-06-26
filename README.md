# QL Symlink Viewer

QuickLook extension for macOS that previews **symlinks** and **Finder aliases**.

When you press <kbd>Space</kbd> in Finder on a symlink/alias, it shows:

- item name + icon
- `🔗 SYMLINK: <path>` or `↔️ ALIAS: <path>`
- `🎯 TARGET: <resolved absolute target>`

Regular files and folders keep their normal system QuickLook previews.

## Requirements

- macOS 15+ (Sequoia or newer)
- Xcode 16+
- Apple Development signing identity (for loading app extensions)

## Build

1. Open `QLSymlinkViewer.xcodeproj` in Xcode.
2. Select scheme: **QLSymlinkViewerApp**.
3. Build or Archive.

## Install

Use the helper script from this repo root:

```bash
./install.sh "/absolute/path/to/QLSymlinkViewerApp.app"
```

You can also pass an archive path directly:

```bash
./install.sh "/absolute/path/to/SomeArchive.xcarchive"
```

The script will:

- replace `/Applications/QLSymlinkViewerApp.app`
- register LaunchServices + pluginkit
- reset QuickLook cache/daemon
- relaunch Finder

## Use

1. In Finder, select a symlink or alias.
2. Press <kbd>Space</kbd>.
3. View the source link path and resolved target path.

## Troubleshooting

- If extension does not load, verify signing:

```bash
codesign -dv /Applications/QLSymlinkViewerApp.app/Contents/PlugIns/QLSymlinkPreview.appex 2>&1 | grep TeamIdentifier
```

- Check extension registration:

```bash
pluginkit -m -A -D -v -p com.apple.quicklook.preview | grep com.azizzo.QLSymlinkViewer.Preview
```

