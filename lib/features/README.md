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

## Migrating the next feature (recipe)

1. `git mv lib/pages/<x> lib/features/<x>/presentation/pages/<x>`
2. Fix import paths (the page paths + anything shared it pulls in).
3. Add `domain/` (entity + abstract repository) and `data/`
   (datasource + model + repository impl) wrapping the relevant service slice.
4. Add `core/di/<x>_locator.dart`.
5. Route the feature's own backend calls through the repository; leave
   cross-cutting calls on the shared service.
6. Run `flutter analyze` and fix any leftover import errors.
