# Exam Duel status, 2026-10-12
## Working
- Snap → Map → Duel prototype (README "Where the project is", run with `flutter run -d chrome -t lib/main_prototype.dart`), on sample data with no backend.
- Party-trivia app still in `lib/` (online rooms, Quick Fire, Fact of the Day, streaks, Eve); on hold per README.
- Supabase schema `supabase/migrations/20261009000000_init.sql` (587 lines). Run on PostgreSQL 16 against stubs only; not on a real Supabase project.
- Edge function `supabase/functions/generate-questions/index.ts` (Anthropic call, writes questions via admin client).
- Build scripts `tool/build_android.sh`, `tool/build_web.sh` generate the platform folders at build time (`android/`, `ios/` absent is expected).

## Changed since last status
- Last status recorded 5 Flutter tests, all in `test/player_store_test.dart`. Now 16 pass across `a11y_test.dart`, `player_store_test.dart`, `progress_test.dart`, `snap_screen_test.dart`.
- Commits since then: `dc67ee7` Snap → Map → Duel prototype, `e811557` wait/offline/error states, `bb7dc97` solo/duel wiring, `6e603bb` keyboard-accessible Pressable and timer contrast, `b84d7eb` neutral starter content and README.
- The "Open issues" entry saying Flutter tests cover only `PlayerStore` is stale.

## Health
- `flutter analyze`: 3 info-level issues, 0 errors, 0 warnings. Running it rewrites `analysis_options.yaml`; this run's rewrite was reverted with `git checkout`.
- `flutter test`: 16 of 16 passed.
- CI: `.github/workflows/android-apk.yml` runs `flutter test` (line 33) before building the APK. `.github/workflows/web.yml` builds and deploys to GitHub Pages. Neither runs `flutter analyze`.
- Git: branch `main`, working tree clean.

## Open issues
- `lib/main.dart:17` uses deprecated `anonKey`; switch to `publishableKey`.
- `lib/screens/profile_screen.dart:247` uses deprecated `activeColor`; switch to `activeThumbColor`.
- `lib/widgets/common.dart:600` type parameter `T` shadows a visible type (`avoid_types_as_parameter_names`).
- No TODO/FIXME/HACK markers in `lib`, `supabase`, `tool` or `test`.
- No `supabase/tests` folder; SQL has only been checked by hand against stubs.
- No tests yet for the room repository or controller (`lib/data/game_repository.dart`, `lib/state/room_controller.dart`).

## Blocked on the owner
- Supabase project URL and anon key: GitHub secrets `SUPABASE_URL` and `SUPABASE_ANON_KEY` for CI, and `--dart-define` locally. Without them the app runs offline only.
- Edge function secrets: `ANTHROPIC_API_KEY` (optional `ANTHROPIC_MODEL`) and `SUPABASE_SERVICE_ROLE_KEY`.
- Android package/org decision (`tool/build_web.sh` uses `com.mctech`; `tool/build_android.sh` takes an org value).
- GitHub Pages must be enabled for the web deploy job.

## Suggested next 3 steps
1. Get a real Supabase project running: apply the migration, deploy `generate-questions`, and play one online game end to end.
2. Clear the three analyzer infos and add `flutter analyze` to both CI workflows.
3. Add tests for the room repository and controller, plus a SQL test script for the migration's rules.
