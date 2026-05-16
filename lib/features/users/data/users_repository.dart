import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/core/network/api_client.dart';
import 'package:sport_ap_mobile/core/network/paginated_response.dart';
import 'package:sport_ap_mobile/core/network/response_parser.dart';
import 'package:sport_ap_mobile/core/providers.dart';
import 'package:sport_ap_mobile/features/auth/models/user_model.dart';

class UsersRepository {
  UsersRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedResponse<UserModel>> getUsers({
    String? search,
    int page = 1,
    int perPage = 15,
  }) {
    return _apiClient.getPaginated<UserModel>(
      '/users',
      UserModel.fromJson,
      queryParameters: <String, dynamic>{
        'search': search,
        'page': page,
        'per_page': perPage,
      },
    );
  }

  Future<UserModel> getUser(String id) async {
    final response = await _apiClient.get('/users/$id');
    final json = ResponseParser.dataMap(response);
    return UserModel.fromJson(json);
  }
}

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(ref.watch(apiClientProvider));
});

final userDetailProvider = FutureProvider.family<UserModel, String>((ref, id) {
  return ref.watch(usersRepositoryProvider).getUser(id);
});
