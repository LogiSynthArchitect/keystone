import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KsAnalytics {
  KsAnalytics._();

  static Future<void> log(String eventName, {Map<String, dynamic>? properties}) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('app_events').insert({
        'user_id': user?.id,
        'event_name': eventName,
        'properties': properties ?? {},
      });
      debugPrint('[KS:ANALYTICS] logged — $eventName');
    } catch (e) {
      // Analytics must never throw — fire and forget
      debugPrint('[KS:ANALYTICS] failed silently — $eventName: $e');
    }
  }
}
