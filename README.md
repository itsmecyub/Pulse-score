# PulseScore

Live football scores and stats. Flutter, iOS + Android.

## Running it

```bash
flutter pub get
flutter run
```

With no API key the app runs on the bundled demo data — every screen is
browsable, and content is generated relative to launch time so a match that is
"78 minutes in" stays 78 minutes in whenever you open it.

## Live data

Data comes from [API-Football](https://www.api-football.com) (api-sports.io).
Grab a key and pass it at build time so it never lands in source control:

```bash
flutter run --dart-define=API_FOOTBALL_KEY=your_key_here
```

Other build-time knobs, all optional:

| Define | Default | Purpose |
| --- | --- | --- |
| `API_FOOTBALL_KEY` | *(empty)* | Your key. Empty means demo mode. |
| `API_FOOTBALL_HOST` | `v3.football.api-sports.io` | Set to `api-football-v1.p.rapidapi.com` if you subscribe via RapidAPI — the client switches auth headers and path prefix automatically. |
| `API_FOOTBALL_SEASON` | `2023` | The free tier is pinned to 2023. Paid plans can move this forward. |

For day-to-day work, put them in a run configuration rather than retyping:

```bash
flutter run \
  --dart-define=API_FOOTBALL_KEY=... \
  --dart-define=API_FOOTBALL_SEASON=2023
```

When a live call fails — no network, rate limit, bad key — the repository falls
back to demo data and the Live tab shows an amber notice saying so. The app
never renders a dead end.

## Layout

```
lib/
  core/
    config/      API host, key, poll intervals
    theme/       colours, type scale, ThemeData
    utils/       date and duration formatting
    widgets/     match cards, crests, section headers, logo
  data/
    api/         API-Football REST client
    local/       SharedPreferences wrapper, demo data
    models/      Fixture, Team, League, Standing, MatchEvent
    repositories/  the seam: live API or demo, decided here
  features/      one directory per screen
  l10n/          14 languages, map-based
  state/         AppState (prefs, pins, entitlement), MatchesState (live feed)
```

The important seam is `FootballRepository`. Screens ask it for data and get back
a `Result<T>` carrying both the data and where it came from. Nothing above that
layer knows whether a key exists.

## Languages

14 languages ship with full translations: Vietnamese, Hindi, English,
Portuguese (BR), Spanish, French, Indonesian, Korean, Japanese, Chinese, Thai,
Turkish, German, Arabic. Any key missing from a language falls back to English,
so adding a string never breaks a locale.

Strings live in `lib/l10n/translations.dart` as plain maps — deliberately not
ARB/gen-l10n, since the set is small and flat and this keeps adding a language
to one paste.

Latin and Vietnamese glyphs come from the bundled Inter and JetBrains Mono
subsets in `assets/fonts/`. Devanagari, Korean, Japanese, Chinese, Thai and
Arabic fall through to the platform's system fonts, which every target OS ships.

## Not built yet

Two things the onboarding advertises are iOS-native work and are not in this
codebase:

- **Live Activities / Dynamic Island** — needs a Swift widget extension plus
  `ActivityKit`, driven by push updates.
- **Home Screen widgets** — needs a WidgetKit extension and an app group to
  share fixture data with the main app.

Also stubbed rather than implemented:

- **Premium** is a local flag on `AppState`. There is no store integration —
  "unlock" just grants it. Wiring in `in_app_purchase` or RevenueCat means
  replacing the two handlers in `PaywallScreen`; nothing else changes.
- **Notifications** persist the user's preference and drive the settings UI, but
  nothing registers for push yet. `NotificationPermissionScreen.onEnable` is the
  hook.

## Tests

```bash
flutter test
```

Covers response parsing against realistic API payloads — including the loose
typing the API is prone to (numeric strings, absent branches, null goals) — and
the language picker's select-and-confirm flow.
