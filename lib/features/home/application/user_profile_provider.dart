import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_provider.dart';
import '../data/user_profile_repository.dart';
import '../modal/user_profile_modal.dart';

class UserProfileState {
  const UserProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.profile,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final UserProfileModal? profile;
  final String? errorMessage;

  UserProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    UserProfileModal? profile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UserProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(
    ref.read(apiClientProvider),
    ref.read(sessionManagerProvider),
  );
});

class UserProfileController extends StateNotifier<UserProfileState> {
  UserProfileController(this._repository) : super(const UserProfileState());

  final UserProfileRepository _repository;

  Future<void> loadProfile({bool forceRefresh = false}) async {
    if (state.isLoading) {
      return;
    }

    if (!forceRefresh && state.profile != null) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _repository.getProfile();
      state = state.copyWith(isLoading: false, profile: profile);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<void> completeProfile({
    required String fullName,
    String? email,
  }) async {
    if (state.isSaving) {
      return;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repository.completeProfile(
        fullName: fullName,
        email: email,
      );
      final profile = await _repository.getProfile();
      state = state.copyWith(
        isSaving: false,
        profile: profile,
      );
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
    }
  }
}

final userProfileControllerProvider =
    StateNotifierProvider<UserProfileController, UserProfileState>((ref) {
      return UserProfileController(ref.read(userProfileRepositoryProvider));
    });
