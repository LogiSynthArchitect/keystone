/// Compile-time constant for developer mode.
///
/// Set to `true` via `--dart-define=DEV_MODE=true` during development.
/// Defaults to `false` — release builds tree-shake all guarded code.
const bool kDevMode = bool.fromEnvironment('DEV_MODE', defaultValue: false);
