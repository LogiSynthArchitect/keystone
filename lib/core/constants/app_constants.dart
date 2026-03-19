enum AppEnvironment { development, production }

class AppConstants {
  AppConstants._();

  static AppEnvironment get environment {
    const env = String.fromEnvironment('APP_ENV', defaultValue: 'development');
    return env == 'production' ? AppEnvironment.production : AppEnvironment.development;
  }

  static bool get isDev  => environment == AppEnvironment.development;
  static bool get isProd => environment == AppEnvironment.production;

  static const String appName    = String.fromEnvironment('APP_NAME', defaultValue: 'Keystone (Dev)');
  static const String appVersion = '1.0.0';

  static const String webBaseUrl = 'https://keystone-inky-five.vercel.app';
  static const String profileBaseUrl = '$webBaseUrl/p';
}
