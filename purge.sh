#!/usr/bin/env bash

# # 1) Unregister any currently known entries
# pluginkit -m -A -D -v -p com.apple.quicklook.preview 2>/dev/null \
# | grep -i 'com.azizzo.QLSymlinkViewer.Preview' \
# | awk -F'\t' '{print $4}' \
# | while read -r p; do [ -n "$p" ] && pluginkit -r "$p" 2>/dev/null || true; done

# # 2) Remove all leftover app bundles that can be rediscovered
# find /Applications "$HOME/Applications" "$HOME/Library/Developer/Xcode" \
#   -name 'QLSymlinkViewerApp.app' -type d -prune -exec rm -rf {} +

# # 3) Rebuild LaunchServices database
# /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
#   -delete -seed -r -domain local -domain system -domain user

# # 4) Restart relevant processes
# killall "System Settings" Finder lsd quicklookd 2>/dev/null || true
# qlmanage -r
# qlmanage -r cache


# Remove all known registrations for this extension
pluginkit -m -A -D -v -p com.apple.quicklook.preview 2>/dev/null \
| grep -i 'com.azizzo.QLSymlinkViewer.Preview' \
| awk -F'\t' '{print $4}' \
| while read -r p; do [ -n "$p" ] && pluginkit -r "$p" 2>/dev/null || true; done

# Remove leftover app bundles that can be rediscovered
find /Applications "$HOME/Applications" "$HOME/Library/Developer/Xcode" \
  -name 'QLSymlinkViewerApp.app' -type d -prune -exec rm -rf {} +

# Rebuild LS DB (modern way)
LSREG="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
"$LSREG" -delete
# reboot is required after -delete


# # RUN AFTER REBOOT
# "$LSREG" -seed -r -apps u,s,l
# qlmanage -r
# qlmanage -r cache
# killall "System Settings" Finder 2>/dev/null || true
