import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../constants/supabase_constants.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    final hasInterface = result.contains(ConnectivityResult.mobile) ||
                         result.contains(ConnectivityResult.wifi) ||
                         result.contains(ConnectivityResult.ethernet);
    if (!hasInterface) return false;

    // Reachability probe — verify actual internet access
    return _reachable();
  }

  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.asyncMap((results) async {
      final hasInterface = results.contains(ConnectivityResult.mobile) ||
                           results.contains(ConnectivityResult.wifi) ||
                           results.contains(ConnectivityResult.ethernet);
      if (!hasInterface) return false;

      // Reachability probe — verify actual internet access
      return _reachable();
    });
  }

  Future<bool> _reachable() async {
    try {
      final url = SupabaseConstants.url.isNotEmpty
          ? SupabaseConstants.url
          : 'https://ifzpdizxitlvjbmzozew.supabase.co';
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);
      final request = await client.headUrl(Uri.parse(url));
      final response = await request.close();
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }
}
