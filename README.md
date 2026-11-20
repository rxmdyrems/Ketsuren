# Ketsurēn

**Free, open-source media app for Android and Android TV — Music, Manga & Novels**

Ketsurēn is a Flutter-based, music-first adaptation of Zangetsu v2.3.6. It retains the inherited streaming, manga, and novel modes and uses the supplied sword-and-floral emblem as its app mark. The source code is hosted in the private repository [rxmdyrems/Ketsuren](https://github.com/rxmdyrems/Ketsuren).

> Ketsurēn does not host media. Music search and playback depend on third-party YouTube Music/YouTube services; availability and applicable terms are controlled by those services.

## Music status

The current Music mode defaults to YouTube Music search. It includes a local favorites list, recently played tracks, queue insertion, and a `just_audio`/`audio_service` playback path intended to provide notification and background controls. Music favorites and recents are stored locally and do not require an account. The stream resolver currently uses `youtube_explode_dart`; service-side format/cipher changes can break playback, and device-level playback/background behavior still needs validation.

Not implemented yet: curated or personalized home discovery, album/artist/playlist browsing, user-created playlists, offline audio downloads, music-account sync, and robust cipher/PoToken stream handling. The Music Downloads destination is an explicit not-available-yet placeholder. Search currently parses song results only.

The Manga and Novel modes retain their upstream provider mechanisms and features. Music does not use their provider list or legacy video-library sync.

## Build

Install Flutter 3.50.1, Java 17, and the Android SDK, then run:

```sh
flutter pub get
KETSUREN_NO_DISCORD=1 flutter build apk --debug
```

`KETSUREN_NO_DISCORD=1` omits the proprietary Discord SDK, which is not included in this repository. The Android application ID is `com.rxmdyrems.ketsuren` (minimum Android version 7.0 / API 24). GitHub Actions builds a debug APK on pushes to `main`; a `v*` tag builds arm64 and ARM universal-compatible release APKs and publishes them to a GitHub Release. The repository and its release assets remain private.

## Privacy

The app includes no ads, analytics, or tracking SDK initialization. Music search is anonymous and does not require login; requests go to YouTube Music and stream URLs are resolved through YouTube services, which may process standard network metadata. Music favorites and recents stay on-device. Existing account-backed features for the retained legacy modes are separate and optional.

## License and attribution

The complete upstream `LICENSE` is retained byte-for-byte, along with required attribution. Review it for the full applicable terms, including its project-specific Section 7. This derivative uses distinct Ketsurēn branding.

**Credits:** Ketsurēn is based on [Zangetsu by Spyou](https://github.com/Spyou/Zangetsu) (GPL-3.0). The upstream license and attribution are preserved.
