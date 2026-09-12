# PulseScore

Live football scores and stats. Flutter, iOS + Android.

## Running it

```bash
flutter pub get
flutter run
```

Out of the box it pulls real football from the Koora backend — no key, no
signup. With no network at all it falls back to bundled demo data generated
relative to launch time, so a match that is "78 minutes in" stays 78 minutes in
whenever you open it.

## Data

Two backends, picked per capability.

**Koora (default, no key).** `https://api-koora-production.up.railway.app` — a
hosted proxy over API-Football that holds the credential server-side, so the app
ships working:

```bash
flutter run          # that is it
```

Point it elsewhere with `--dart-define=KOORA_BASE_URL=https://your-host`.

It serves API-Football's exact payload shapes under a `{success, data}`
envelope, so the same parsers handle both backends.

| Endpoint | Content | Filter |
| --- | --- | --- |
| `/api/football/live` | every match in play (~180), each with an inline `events` array | none |
| `/api/football/today` | everything scheduled today (~1200 fixtures, ~330 competitions) | none |
| `/api/football/standings` | one league's full table | `?leagueId=` |
| `/api/football/health` | status and cache freshness | — |

**The filter parameter is `leagueId`, camelCase.** This matters more than it
looks: `?league=`, `?league_id=` and `?id=` are all accepted and then *silently
ignored*, so the backend answers with some other competition's table rather than
an error. Getting the name wrong is invisible, so it is pinned by a test, and
the repository drops any table whose league id doesn't match what was asked for.

`/live` and `/today` take no filter at all — they are whole-world snapshots. So
there is no per-league fixtures call to make: the client fetches each snapshot
once, caches it, and the repository narrows in memory. Consequences:

- **League and team fixtures** are today's snapshot filtered client-side. Good
  for "what is this league doing today", not a season's history.
- **Other dates** return empty rather than pretending today's rows apply.
- **Events** come only from the inline `events` on live rows — there is no
  events endpoint, so finished matches have none.
- `/api/football/matches` returns an empty list for every parameter combination
  tried, and `/teams` always returns the same 20 clubs, so neither is used.

**API-Football direct (optional).** Supply a key and the repository switches to
api-sports for everything, which adds arbitrary dates and full season history:

```bash
flutter run --dart-define=API_FOOTBALL_KEY=your_key_here
```

| Define | Default | Purpose |
| --- | --- | --- |
| `KOORA_BASE_URL` | the Railway host | Point at your own deployment. |
| `API_FOOTBALL_KEY` | *(empty)* | Set it to bypass Koora entirely. |
| `API_FOOTBALL_HOST` | `v3.football.api-sports.io` | Use `api-football-v1.p.rapidapi.com` for a RapidAPI subscription; auth headers switch automatically. |
| `API_FOOTBALL_SEASON` | `2023` | Season for direct queries. |

**Failures are reported, not papered over.** Three cases are kept distinct:

- *The backend answered with no data.* Its endpoints 404 with
  `{"success":false,"error":"No today's matches data available"}` whenever its
  cache is cold — that is a real answer, so the app treats it as an empty
  result and shows an ordinary empty state.
- *The backend could not be reached.* The screen stays empty and says so, with
  a prompt to pull down and retry.
- *Sample data.* Off by default. A scores app that quietly shows invented
  fixtures is worse than one that admits it has nothing, so the bundled sample
  set is opt-in for offline development:
  `--dart-define=USE_DEMO_DATA=true`.

When the backend answers but holds nothing at all, the screens say so directly
("The score service has no data right now") rather than implying the league has
no fixtures — the difference matters when diagnosing an outage.

The Live tab shows when the backend last refreshed ("UPDATED 2M AGO", read from
its own `lastUpdated`), so it is obvious whether data is current. Pull-to-refresh,
the refresh button and returning from the background all force a fetch that
bypasses the cache.

## Leagues

The catalog in `lib/data/models/league_catalog.dart` is deliberately short — the
five big European leagues plus the Champions League:

| League | Id | Table |
| --- | --- | --- |
| Premier League | 39 | yes |
| La Liga | 140 | yes |
| Serie A | 135 | yes |
| Bundesliga | 78 | yes |
| Ligue 1 | 61 | yes |
| Champions League | 2 | yes |

Having a real league table was the entry requirement: the backend serves
standings for these six and returns nothing for the likes of Eredivisie,
Primeira Liga, MLS or the Brasileirão, so promoting those would mean shipping a
permanently empty Standings tab.

All six ship **unlocked** — no league is behind Premium. The `premium` flag on
`CatalogLeague` is still wired through `AppState.canAccess`, so a competition
can be gated later without touching any screen, but nothing uses it today.
Premium now gates only the pin limit and the news feed.

Changing the catalog is safe for existing installs: `AppState.defaultLeagueId`
validates the stored id against the catalog and falls back to the default, so an
install that still has V-League saved lands on the Premier League instead of
selecting a chip that no longer exists.

## Layout

```
lib/
  core/
    config/      backend URLs, optional key, poll intervals
    theme/       colours, type scale, ThemeData
    utils/       date and duration formatting
    widgets/     match cards, crests, section headers, logo
  data/
    api/         Koora + API-Football REST clients
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

## Legal pages

Privacy policy and terms of service live in `web/legal/`, written in all 14 app
languages and generated into static pages:

```bash
python3 web/legal/build.py          # dist/        one page per language, no JS
python3 web/legal/build_bundle.py   # dist_bundle/ two pages, all languages inline
```

`content/*.json` holds the text — one file per language, all with the same
section structure, so a change to one is easy to mirror. `content_long/` keeps a
longer-form draft of the same documents if you ever want fuller wording.

The app links to them from Settings in the reader's own language:

```
https://<host>/privacy.html?lang=fr
```

Change the host with `--dart-define=LEGAL_BASE_URL=https://your-domain`. The
language is a query parameter rather than a path segment so a link still
resolves (falling back to English) if a language has not been published.

**Before publishing, edit two things** in `web/legal/build.py`: `CONTACT_EMAIL`
(currently the placeholder `support@pulsescore.app`) and, in the terms, the
governing-law sentence, which says "the country where the developer is
established" rather than naming one. The documents describe what the app
actually does — no accounts, no analytics, no ads, local-only storage — so they
should stay accurate as long as that remains true.

## App Store review prompt

Asked once per install, a few seconds after the main screen appears — never
during the splash or first-run flow. `lib/features/review/` holds it:

- `ReviewPrompter` decides whether to ask and records that it did.
- `ReviewPromptHost` wraps `HomeShell` in the router, so the ask can only
  happen once the user is actually in the app.

It uses the platform's own dialog (`SKStoreReviewController` on iOS, In-App
Review on Android) via `in_app_review` — the icon, "Enjoying PulseScore?", the
five stars and Cancel/Submit are drawn by iOS, and the rating goes straight to
the App Store. A look-alike of our own could not submit a real rating, and
Apple rejects apps that imitate this dialog.

Two consequences of using the system dialog, both by design:

- **iOS decides whether to draw it.** It is rate limited and simply does
  nothing when it declines — no callback, no error. So `hasShownReviewPrompt`
  is written when the request is *made*, not on any outcome; asking again
  because iOS stayed quiet is exactly the nagging the once-only rule prevents.
- **The stars and Submit belong to iOS.** Tapping Submit posts the rating; the
  app is never told what was chosen and nothing navigates away.

**The iOS request is made in `AppDelegate.swift`, not by the plugin.**
`in_app_review` resolves the window scene with
`UIApplication.shared.connectedScenes.first`, and `connectedScenes` is a Set —
`first` is whatever the hash order yields, frequently a background scene.
StoreKit then does nothing at all: no dialog, no error, and the Dart call still
returns normally, so the failure is completely silent. Our channel picks the
foreground-active scene instead. The plugin is still used for `isAvailable`
and on Android, where the problem does not exist.

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

Covers parsing against **payloads recorded from the live Koora backend**
(`test/fixtures/koora_*.json`, trimmed but otherwise untouched), the in-memory
filtering the snapshots force, the demo fallback when the backend is down, and
the launch and language-picker flows.
