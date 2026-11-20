# Ketsurēn implementation outcomes

- [x] Replace every user-facing Zangetsu brand, link, logo, splash, launcher, and metadata reference with Ketsurēn, preserving only legally required upstream attribution and documenting each exception. Remaining `zangetsu` strings are upstream package identifiers, persisted compatibility keys, test fixtures, or attribution.
- [x] Remove Discord and Telegram integrations, links, buttons, authentication flows, setup, dependencies, and provider references without breaking media playback or navigation. Static review found no remaining Discord/Telegram integration symbols or links; Flutter playback builds remain unverified locally.
- [x] Use the supplied Ketsurēn emblem for the Flutter startup splash and appearance preview; keep the existing Android package ID. The package ID was not changed.
- [ ] Verify the supplied emblem is used consistently for phone, Android TV, launcher, splash, and in-app branding.
- [x] Preserve unrelated providers and existing Anime, Manga, Novel, and Music routes while removing Zangetsu-linked providers. The upstream source bridge and existing route/provider code remain in place.
- [x] Keep analytics, tracking, ads, and mandatory account requirements disabled; no new telemetry or mandatory-account behavior was introduced.
- [x] Confirm the correct Supabase project URL/key and schema before changing account signup, login, profile, avatar, or sync storage. Target is `ketsurenDB` (`qrqyduziluhptyhyfoxa`); the reviewed schema/storage migrations are tracked but were not applied to production.
- [ ] Build and test search, playback, queue, mini-player, full player, favorites, recents, and background/notification controls; document YouTube Music reliability limits and unsupported features.
- [ ] Run formatting, static analysis, relevant Flutter/native tests, and Android phone/TV builds; report exact results and unverified environments.
- [ ] Diagnose GitHub Actions and produce a new private test APK release with ABI/package/version/SHA-256/release-page details once build tooling and signing inputs are available.

## Validation note

Static validation completed: ARB JSON parsing, Android manifest XML parsing, iOS `Info.plist` XML parsing, Python compilation of `tool/gen_l10n.py`, repository-wide retired-integration scans, and `git diff --check`. Flutter/Dart/Android SDK/ADB tooling is unavailable in this sandbox, so formatting, analyzer, automated tests, playback checks, and phone/Android TV builds remain unresolved until CI or a Flutter-enabled environment runs them.
