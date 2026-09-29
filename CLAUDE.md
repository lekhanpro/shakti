# Shakti: working conventions

Read the spec in `docs/specs/2026-09-29-shakti-design.md` and the plan in `docs/plans/2026-09-29-shakti-implementation-plan.md` first.

## Toolchain (Windows)
- Flutter: `D:\tools\flutter\bin\flutter` (3.47.5, Dart 3.13). Always set `PUB_CACHE=D:\tools\pub-cache`. The default cache under the user profile fails because of the space in the path.
- JDK 21: `D:\tools\jdk\jdk-21.0.12.1+1`. Android SDK: `D:\tools\android-sdk`.
- Supabase CLI: `D:\tools\supabase-cli\supabase.exe`.
- In Git Bash: `export PUB_CACHE="D:\\tools\\pub-cache"` before running any flutter or dart command.

## Commands (from `app/`)
- `flutter analyze` must report no issues.
- `flutter test` / `flutter test --coverage`
- `dart run build_runner build --delete-conflicting-outputs` (Drift)
- `flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

## Architecture rules
- `lib/domain/**` is pure Dart: no Flutter or plugin imports.
- Plugins are imported only in `lib/data/**` and `lib/bootstrap.dart`.
- Features get dependencies only through `lib/core/di/providers.dart`.
- Riverpod 3 `Notifier`/`AsyncNotifier`, written by hand, no codegen.
- Styling uses `lib/core/theme/tokens.dart` only. Minimum tap target 48 dp. Semantics labels everywhere. Respect `ShaktiMotion.reduced(context)`.
- The SOS path never awaits the network before the SMS is handed off.
- Helplines: 112, 181 (women), 1091 (women police), 1098 (child).
