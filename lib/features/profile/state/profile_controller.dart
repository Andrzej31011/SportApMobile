import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/core/network/api_exception.dart';
import 'package:sport_ap_mobile/features/profile/data/profile_repository.dart';
import 'package:sport_ap_mobile/features/profile/state/profile_state.dart';

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._repository) : super(ProfileState.initial()) {
    loadProfile();
  }

  final ProfileRepository _repository;

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await _repository.getProfile();
      state = state.copyWith(isLoading: false, user: user);
    } on ApiException catch (exception) {
      state = state.copyWith(isLoading: false, errorMessage: exception.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Nie udalo sie pobrac profilu.',
      );
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> payload) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final user = await _repository.updateProfile(payload);
      state = state.copyWith(isSaving: false, user: user);
      return true;
    } on ApiException catch (exception) {
      state = state.copyWith(isSaving: false, errorMessage: exception.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Nie udalo sie zapisac profilu.',
      );
      return false;
    }
  }

  Future<bool> updateLocation({
    required double latitude,
    required double longitude,
    required int radiusKm,
    required String locationName,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final updatedUser = await _repository.updateLocation(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        locationName: locationName,
      );

      try {
        final refreshedUser = await _repository.getProfile();
        state = state.copyWith(isSaving: false, user: refreshedUser);
      } catch (_) {
        state = state.copyWith(isSaving: false, user: updatedUser);
      }
      return true;
    } on ApiException catch (exception) {
      state = state.copyWith(isSaving: false, errorMessage: exception.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Nie udalo sie zapisac lokalizacji.',
      );
      return false;
    }
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
      return ProfileController(ref.watch(profileRepositoryProvider));
    });
