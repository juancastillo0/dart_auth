import 'dart:async';

import 'package:oauth/front_end_client.dart';
import 'package:oauth/oauth.dart';

class AdminClient {
  ///
  AdminClient(this.globalState);

  final GlobalState globalState;

  final Map<UserId, UserInfoMe> allUsers = {};
  final ValueNotifierStream<List<UserInfoMe>?> users =
      ValueNotifierStream(null);

  final isLoading = ValueNotifierStream(false);
  late final debouncer = Debouncer(
    const Duration(milliseconds: 500),
    (String query) async {
      final values =
          query.trim().split(RegExp(r'\s+')).map(UserId.fromString).toList();
      final response = await getUsersByQuery(
        UsersInfoQuery(values, const []),
        overrideUserList: true,
      );
      return response;
    },
  );

  Future<ResponseData<UsersInfoQuery, UsersInfo>> getUserWithSessionsById(
    String id,
  ) async {
    final userId = UserId(id, UserIdKind.innerId);
    final response = await getUsersByQuery(
      UsersInfoQuery([userId], const []),
      overrideUserList: false,
    );
    // final data = response.data;
    // if (data == null || data.users.isEmpty) {
    //   return null;
    // }
    return response;
  }

  Future<ResponseData<UsersInfoQuery, UsersInfo>> getUsersByTextDebounce(
    String query,
  ) {
    return debouncer.get(query);
  }

  Future<ResponseData<UsersInfoQuery, UsersInfo>> getUsersByQuery(
    UsersInfoQuery query, {
    required bool overrideUserList,
  }) async {
    isLoading.value = true;
    final cachedValues = query.ids
        .where(allUsers.containsKey)
        .map((id) => allUsers[id]!)
        .toList();
    if (overrideUserList && cachedValues.isNotEmpty) users.value = cachedValues;

    final response = await endpointUsersInfoAdmin.request(
      globalState.authState.client,
      query,
    );
    final found = response.data?.users;
    if (found != null) {
      if (overrideUserList) users.value = found;
      allUsers.addEntries(
        found.expand(
          (e) => e.userIds.map((id) => MapEntry(id, e)),
        ),
      );
    }
    isLoading.value = false;
    return response;
  }

  static final endpointUsersInfoAdmin = Endpoint<UsersInfoQuery, UsersInfo>(
    path: 'admin/users',
    method: 'GET',
    deserialize: UsersInfo.fromJson,
    serialize: (data) => ReqParams(const [], data.toJson()),
  );
}
