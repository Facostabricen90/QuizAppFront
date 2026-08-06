/// Build-time configuration for environment-specific values.
///
/// Pass values with Flutter's `--dart-define` or
/// `--dart-define-from-file=config/env.json`. Do not place credentials in
/// this file: values compiled into a client application are not secrets.
class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://localhost:7126',
  );
}
