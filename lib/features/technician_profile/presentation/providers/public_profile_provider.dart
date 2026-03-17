import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/models/profile_model.dart';
import '../../domain/entities/profile_entity.dart';

final publicProfileProvider = FutureProvider.family<ProfileEntity?, String>((ref, slug) async {
  final supabase = ref.watch(supabaseClientProvider);
  
  try {
    final fullUrl = 'keystone.app/p/$slug';
    final data = await supabase
        .from('profiles')
        .select()
        .eq('profile_url', fullUrl)
        .eq('is_public', true)
        .maybeSingle();
        
    if (data == null) return null;
    return ProfileModel.fromJson(data).toEntity();
  } catch (e) {
    throw Exception('Could not load profile: $e');
  }
});
