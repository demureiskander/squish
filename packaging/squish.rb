# Homebrew Cask for Squish.
#
# This file belongs in a SEPARATE tap repository:
#   github.com/demureiskander/homebrew-tap  →  Casks/squish.rb
#
# After each release, update `version` and `sha256` (the DMG checksum is printed
# by the release workflow and by scripts/build-dmg.sh).

cask "squish" do
  version "1.0.0"
  sha256 "REPLACE_WITH_DMG_SHA256"

  url "https://github.com/demureiskander/squish/releases/download/v#{version}/Squish.dmg"
  name "Squish"
  desc "Image compressor, converter and resizer for macOS"
  homepage "https://github.com/demureiskander/squish"

  depends_on macos: ">= :sonoma"

  app "Squish.app"

  # The app is not notarized yet — strip the quarantine flag so it opens.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Squish.app"]
  end

  zap trash: [
    "~/Library/Application Support/Squish",
    "~/Library/Preferences/com.demureiskander.squish.plist",
  ]
end
