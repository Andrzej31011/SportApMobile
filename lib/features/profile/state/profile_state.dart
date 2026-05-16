import 'package:sport_ap_mobile/features/auth/models/user_model.dart';

class ProfileState {
  const ProfileState({
    this.user,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final UserModel? user;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  ProfileState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return ProfileState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  factory ProfileState.initial() {
    return const ProfileState(isLoading: true);
  }
}
