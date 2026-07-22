# Contributing to Squish

Thanks for your interest in improving Squish!

## Getting started

1. Fork and clone the repo
2. Open `Squish.xcodeproj` in **Xcode 16+** (macOS 14+)
3. Build & run with **⌘R**

Swift Package dependencies (libwebp) resolve automatically on first build.

## Project structure

```
Squish/
├── App/            # Entry point, scenes, commands
├── Models/         # ImageItem, CompressionPreset, CompressionResult
├── ViewModels/     # MainViewModel, PresetViewModel
├── Views/          # SwiftUI views
├── Services/       # ImageProcessor, WebPEncoder, PresetManager, Metadata, Localization
└── Resources/      # Assets.xcassets
```

Architecture is **MVVM**. Views observe view models; view models own the state and call services.

## Guidelines

- Match the surrounding code style (naming, spacing, comment density).
- Keep changes focused and small where possible.
- User-facing strings must be added to `Services/Localization.swift` (RU + EN).
- Build in **Swift 6 language mode** — no concurrency warnings.
- Test your change by actually running the app, not just compiling.

## Pull requests

- One logical change per PR with a clear description.
- Reference any related issue.
- Make sure the app builds and runs before submitting.

## License

By contributing, you agree that your contributions are licensed under the **GPL v3**.
