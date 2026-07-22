# Releasing Squish

## One-time setup: your Homebrew tap

1. Create a public repo named **`homebrew-tap`** under your account:
   `github.com/demureiskander/homebrew-tap`
2. Add `packaging/squish.rb` from this repo to it as **`Casks/squish.rb`**.

That's it — users can then install with:

```bash
brew install --cask demureiskander/tap/squish
```

## Cutting a release

1. Bump the version:
   - `MARKETING_VERSION` in `Squish.xcodeproj` (or in Xcode → target → General)
   - `version` in `packaging/squish.rb`
2. Commit and push.
3. Tag and push the tag:

   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

4. The **Release** GitHub Action builds `Squish.dmg`, creates a GitHub Release,
   and attaches the DMG. It prints the DMG **SHA-256** in the release notes.

5. Update your tap: set `version` and `sha256` in `homebrew-tap/Casks/squish.rb`
   to the new values, commit and push.

6. Verify:

   ```bash
   brew update
   brew install --cask demureiskander/tap/squish
   ```

## Building a DMG locally

```bash
./scripts/build-dmg.sh
```

Produces `dist/Squish.dmg` and prints its SHA-256.

## Notes on signing

The app is currently **ad-hoc signed and not notarized**. Users must right-click →
**Open** on first launch (the cask strips the quarantine flag automatically).

To distribute without Gatekeeper friction — and to submit to the official
`homebrew/cask` — you need an **Apple Developer Program** membership ($99/yr),
then sign with a **Developer ID** certificate and notarize with `notarytool`.
That can be wired into `scripts/build-dmg.sh` and the release workflow later.
