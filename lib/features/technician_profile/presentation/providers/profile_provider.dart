import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/share_profile_usecase.dart';

final profileRemoteDatasourceProvider = Provider<ProfileRemoteDatasource>(
  (ref) => ProfileRemoteDatasource(ref.watch(supabaseClientProvider)));

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ref.watch(profileRemoteDatasourceProvider), ref.watch(supabaseClientProvider)));

final getProfileUsecaseProvider = Provider<GetProfileUsecase>(
  (ref) => GetProfileUsecase(ref.watch(profileRepositoryProvider)));

final updateProfileUsecaseProvider = Provider<UpdateProfileUsecase>(
  (ref) => UpdateProfileUsecase(ref.watch(profileRepositoryProvider)));

final shareProfileUsecaseProvider = Provider<ShareProfileUsecase>(
  (ref) => ShareProfileUsecase(ref.watch(profileRepositoryProvider)));

class ProfileState {
  final ProfileEntity? profile;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  bool get hasProfile => profile != null;

  ProfileState copyWith({
    ProfileEntity? profile,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) => ProfileState(
    profile: profile ?? this.profile,
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  ProfileNotifier(this._repository, SupabaseClient _) : super(const ProfileState()) { load(); }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _repository.getProfile();
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Could not load profile.');
    }
  }

  Future<bool> update(ProfileEntity profile) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _repository.updateProfile(profile);
      state = state.copyWith(profile: updated, isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> shareProfile() async {
    if (state.profile == null) return;
    await Share.share(
      'Check out my locksmith profile: https://${state.profile!.profileUrl}',
      subject: 'My Keystone Profile',
    );
  }

  Future<String?> uploadPhoto(String filePath) async {
    try {
      final url = await _repository.uploadPhoto(filePath);
      return url;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Could not upload photo.');
      return null;
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(ref.watch(profileRepositoryProvider), ref.watch(supabaseClientProvider)));
