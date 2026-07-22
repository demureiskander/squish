<div align="center">

<img src="docs/icon.png" width="128" alt="Squish icon">

# Squish

**Fast image compression, conversion and resizing for macOS.**
No subscriptions, no limits, no ads.

[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-black)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/license-GPL%20v3-green)](LICENSE)
[![Made with Swift](https://img.shields.io/badge/Swift%206-orange)](https://swift.org)

<!-- Replace with a real demo GIF -->
<img src="docs/demo.gif" width="720" alt="Squish demo">

</div>

## Features

- **Drag & drop** — drop images or folders, they queue up instantly
- **Quality presets** — 5 clear levels from max compression to minimal
- **Format conversion** — JPEG · PNG · HEIC · **WebP**
- **Resize** — by width/height in pixels, aspect ratio preserved
- **Before/after preview** — split slider with zoom and metrics
- **Batch processing** — compress the whole queue at once, cancel anytime
- **Custom presets** — create, rename and delete your own
- **Metadata viewer & editor** — EXIF/IPTC, rename files, AI-provenance check
- **Flexible output** — original folder, ask each time, or a fixed folder; subfolders and suffixes
- **Multi-select** — click, ⌘-click, ⇧-range, marquee; drag results out to Finder
- **Native macOS** — dark mode, menu bar icon, notifications, English & Русский

## Install 📥

### Homebrew (recommended)

```bash
brew install --cask demureiskander/tap/squish
```

### Manual

1. Download `Squish.dmg` from the [latest release](https://github.com/demureiskander/squish/releases/latest)
2. Open it and drag **Squish** to **Applications**
3. First launch: right-click the app → **Open** (the app is not notarized yet)

## Build from source

Requires **Xcode 16+** on **macOS 14+**.

```bash
git clone https://github.com/demureiskander/squish.git
cd squish
open Squish.xcodeproj   # then ⌘R
```

Dependencies (resolved automatically via Swift Package Manager):
- [libwebp](https://github.com/SDWebImage/libwebp-Xcode) — WebP encoding

## Tech

Swift 6 · SwiftUI · Core Image · ImageIO · vImage. MVVM architecture, zero heavyweight dependencies.

## Support

If Squish is useful to you, you can [support development ❤️](https://web.tribute.tg/d/GLT).

## License

[GPL v3](LICENSE) © 2026 demureiskander
