# Ketsurēn implementation outcomes

- [ ] Replace every user-facing Zangetsu brand, link, logo, splash, launcher, and metadata reference with Ketsurēn, preserving only legally required upstream attribution and documenting each exception.
- [ ] Remove Discord and Telegram integrations, links, buttons, authentication flows, setup, dependencies, and provider references without breaking media playback or navigation.
- [x] Use the supplied Ketsurēn emblem for the Flutter startup splash and appearance preview; keep the existing Android package ID. The package ID was not changed.
- [ ] Verify the supplied emblem is used consistently for phone, Android TV, launcher, splash, and in-app branding.
- [ ] Preserve unrelated providers and existing Anime, Manga, Novel, and Music routes while removing Zangetsu-linked providers.
- [ ] Keep analytics, tracking, ads, and mandatory account requirements disabled.
- [ ] Confirm the correct Supabase project URL/key and schema before changing account signup, login, profile, avatar, or sync storage.
- [ ] Build and test search, playback, queue, mini-player, full player, favorites, recents, and background/notification controls; document YouTube Music reliability limits and unsupported features.
- [ ] Run formatting, static analysis, relevant Flutter/native tests, and Android phone/TV builds; report exact results and unverified environments.
- [ ] Diagnose GitHub Actions and produce a new private test APK release with ABI/package/version/SHA-256/release-page details once build tooling and signing inputs are available.
