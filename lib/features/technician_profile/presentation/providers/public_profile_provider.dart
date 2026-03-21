import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/models/profile_model.dart';
import '../../domain/entities/profile_entity.dart';

final publicProfileProvider = FutureProvider.family<ProfileEntity?, String>((ref, slug) async {
  final supabase = ref.watch(supabaseClientProvider);
  
  try {
    // Exact match on slug, with case-insensitive fallback
    final data = await supabase
        .from('profiles')
        .select()
        .ilike('profile_url', '%$slug')
        .eq('is_public', true)
        .maybeSingle();
        
    if (data == null) return null;
    return ProfileModel.fromJson(data).toEntity();
  } catch (e) {
    throw Exception('Could not load profile: $e');
  }
});
