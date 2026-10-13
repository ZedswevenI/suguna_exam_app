import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:suguna_exam_app/core/constants/app_constants.dart';

class NetworkService {
  /// Cheap check: is any network interface up? Note that "connected to
  /// Wi-Fi" does not guarantee the internet is reachable.
  static Future<bool> hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    return connectivityResult != ConnectivityResult.none;
  }

  /// Strict check used before submitting an exam: the interface must be up
  /// AND the API host must answer an HTTP request (any status code counts —
  /// we only care that the server is reachable).
  static Future<bool> canReachServer({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    if (!await hasInternet()) return false;
    final dio = Dio(BaseOptions(
      connectTimeout: timeout,
      receiveTimeout: timeout,
      validateStatus: (_) => true,
    ));
    try {
      await dio.get(AppConstants.baseUrl);
      return true;
    } catch (_) {
      return false;
    } finally {
      dio.close(force: true);
    }
  }
}
