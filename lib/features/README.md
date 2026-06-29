# Feature-first architecture (migration in progress)

The app is migrating from a layer-first FlutterFlow layout (`lib/pages`, `lib/services`, …)
to a **feature-first** layout. `auth` is the first migrated feature and serves as the
template for the rest.

## Target structure

```
lib/
├── core/            # cross-cutting infra (DI, errors, network, routing, theme tokens)
│   └── di/          # manual service locators (interim DI — see below)
├── features/
│   └── <feature>/
│       ├── data/
│       │   ├── datasources/   # thin wrappers over the backend (e.g. SupabaseService)
│       │   ├── models/        # DTO <-> entity mapping
│       │   └── repositories/  # *RepositoryImpl
│       ├── domain/
│       │   ├── entities/      # pure Dart, no Flutter/Supabase imports
│       │   └── repositories/  # abstract contracts
│       └── presentation/
│           └── pages/<page>/  # FlutterFlow _widget + _model kept together
└── shared/          # widgets/services/theme used by 2+ features (e.g. auth_theme)
```

## Conventions established by the `auth` migration

1. **Shared services stay shared.** `SupabaseService` is a god-class that mixes
   auth + profile + device concerns and is used app-wide. It is NOT moved into a
   feature. Each feature's `data/datasources` wraps the slice it needs.
2. **Only put a concern in the feature it belongs to.** Auth widgets still call
   `SupabaseService.ensureUserProfileFromAuth` / `getDeviceId` /
   `upsertDeviceInfoForCurrentUser` directly — those belong to future `profile`
   and `device` features, not `auth`. Don't absorb them into `AuthRepository`.
3. **Repositories are pass-throughs first.** The impl delegates to the existing
   service with zero behavior change. Tighten types (return domain entities
   instead of Supabase `AuthResponse`) in a later pass.
4. **A file imported by many features is `shared/`, not a feature.** `auth_theme`
   was imported by 31 files → moved to `lib/shared/theme/auth_theme.dart`.
5. **DI is an interim manual locator** (`core/di/*_locator.dart`) — a mutable
   top-level `authRepository` so tests can override it. Swap for get_it /
   Riverpod / Provider injection once several features are migrated.
6. **Move with `git mv`** to preserve history; keep each FlutterFlow page's
   `_widget` + `_model` in the same folder so same-folder imports survive.

## Composition-view features (e.g. `home`)

Some features are aggregator/dashboard views with **no domain data of their own** —
they compose data owned by other features. `home` is the first example: it shows
stories, desires and profile data. Such a feature gets a `presentation/` layer but
**no `domain`/`data` layer**. It consumes other features' repositories (e.g.
`profileRepository.getUserProfile`). Story/desire calls stay on the shared
`BackendClient` until those features are migrated, then `home` switches to their
repositories. Do NOT create a `HomeRepository` that absorbs story/desire logic —
that data belongs to those features, not to home.

## Layer-first folders retired (`services`, `models`, `widgets`, `utils`, `constants`)

The old layer-first dumps have been categorized and removed. `lib/widgets/`
moved to `shared/widgets/`; `lib/models/` (only `Story`) was deleted as dead
code; `lib/utils/` was split — `platform_utils*` (the web-safe `isIOS`/
`isAndroid` conditional-import shim) went to `core/platform/`, and the
agent-injected `agent_debug_log` debug logger (hardcoded local path + localhost
endpoint) was deleted along with all its call sites; and `lib/constants/`
(app-wide `legal_urls` config) moved to `core/constants/`.

### Services categorization

The old layer-first `lib/services/` dump has been categorized and removed:

- **Infra → `lib/core/`** — `backend_client` is now `core/network/backend_client.dart`.
- **Cross-cutting → `lib/shared/services/`** — app-wide services owned by no single
  feature, or depended on by other shared code: `supabase_service` (+ its
  `apple_sign_in_cache`, `persistent_device_id_service`, `onboarding_service`
  deps), `app_toast`, `server_toast`, `app_upgrader`, `fcm_service`,
  `ai_consent_service`, `timezone_sync_service`, and the app-shell notifiers
  (`nav_lock_notifier`, `shell_player_navigation`, `sleep_mode_notifier`).
- **Feature-owned → `features/<x>/data/datasources/`** — moved into the feature
  that owns the concern (cross-feature consumers import from there, same as
  composition views): `player` got `last_played_service`, `rating_prompt_*`;
  `onboarding` got `desire_speech_service`, `voice_recording_service`;
  `subscription` got `revenuecat_service`. `profile_day_streak` (a pure parser)
  went to `features/profile/domain/`.

Rule of thumb applied: if **shared** code depends on a service, it must live in
`shared/` (shared cannot import a feature). NOTE: `theta_wave_generator` and
`voice_service` were moved to `player` but are currently **dead code** (zero
importers) — delete or wire them up. The old `lib/models/` folder (just
`Story`) and its sole consumer `story_service` were both deleted as dead code;
re-add a proper `Story` entity under `features/player/` when story/player data
is migrated.

## Migrating the next feature (recipe)

1. `git mv lib/pages/<x> lib/features/<x>/presentation/pages/<x>`
2. Fix import paths (the page paths + anything shared it pulls in).
3. Add `domain/` (entity + abstract repository) and `data/`
   (datasource + model + repository impl) wrapping the relevant service slice.
4. Add `core/di/<x>_locator.dart`.
5. Route the feature's own backend calls through the repository; leave
   cross-cutting calls on the shared service.
6. Run `flutter analyze` and fix any leftover import errors.
