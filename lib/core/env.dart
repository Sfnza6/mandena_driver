class Env {
  // استخدم www إذا كان الدومين لا يفتح من المحاكي بدونها.
  static const String baseUrl = 'https://www.mandena.ly/mandena/api/driver';
  static int driverId = 0;
  static const Duration pollInterval = Duration(seconds: 5);
}
