# Ketsurēn v0.1.1 implementation plan

## Scope

Continue from `v0.1.0-test` without changing the Android package ID or rewriting the existing Anime, Manga, Novel, and Music flows. The first safe change set standardizes the supplied Ketsurēn emblem across Flutter startup and appearance previews, while keeping network/account behavior unchanged until the correct Supabase project configuration is confirmed.

## Design

- **Style candidates:** Quiet media-console (0.04); ink-and-coral editorial (0.08); utilitarian TV launcher (0.03).
- **Chosen movement:** ink-and-coral editorial, using the supplied traced emblem as the single source of truth.
- **Core principles:** brand-led first frame; high-contrast dark surfaces; restrained motion; no invented service URLs.
- **Color philosophy:** retain the emblem’s black, white, and red/coral contrast so the mark remains legible on phone and TV dark themes.
- **Layout paradigm:** centered first-frame mark with generous negative space, then the existing content shell and navigation.
- **Signature elements:** supplied emblem, existing wordmark, and the existing accent glow used only as motion support.
- **Interaction and animation:** a short opacity/scale reveal for the emblem; no geometry derived from the retired mark.
- **Typography and voice:** preserve the existing Inter/Nunito system and existing product copy until the wider copy cleanup is separately verified.
- **Brand essence:** a private, music-first media hub for phone and Android TV; focused, calm, personal.

## Implementation boundaries

- Reuse `assets/brand/ketsuren-emblem-source.png` for the Flutter splash and appearance preview.
- Do not guess or replace Supabase URLs/keys. The repository currently references a project unavailable in the connected project list; account storage remains a configuration blocker.
- Do not remove source-bridge dependencies or provider implementations in this first pass; those require an upstream/license review and regression coverage.
- Remove retired logo geometry from the Flutter startup path and keep package identity stable.

## Project structure

- `lib/features/onboarding/`: startup splash and onboarding.
- `lib/features/settings/`: appearance preview and account settings.
- `lib/core/environment.dart`: build-time service and redirect configuration.
- `assets/brand/` and `assets/icon/`: supplied brand artwork and runtime assets.
- `android/`: phone/TV launcher and native player integration.
- `supabase/`: database/functions owned by the repository, to be changed only after project identity is confirmed.

## Ketsurēn account backend status

The app is configured for Supabase project `ketsurenDB` (`qrqyduziluhptyhyfoxa`) through build-time `SUPABASE_URL` and `SUPABASE_ANON_KEY` values; no secret key is committed. The project was empty when this migration was started. The existing contract is captured by the tracked `supabase/migrations/0001_schema.sql` through `0007_mylist_incremental_sync.sql` and later bridge migrations: `public.profiles`, the viewer-profile/sync tables, and the public `avatars` Storage bucket with authenticated owner-write policies are required before production account and profile sync is enabled. Production DDL has intentionally not been applied from this task until that contract is reviewed.

The `zangetsu_source_bridge` package remains because it is the upstream source-provider dependency and its package/repository identifier is legally and technically required. Any remaining `zangetsu_*` names in server migration roles, persisted local keys, tests, or upstream identifiers are compatibility or attribution identifiers, not user-facing branding. Discord and Telegram application integrations, links, buttons, native bridges, and dependencies are retired.
