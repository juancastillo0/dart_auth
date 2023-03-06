import 'package:oauth/flow.dart';
import 'package:oauth/oauth.dart';

// https://github.com/simolus3/drift/branches
// https://drift.simonbinder.eu/docs/advanced-features/
// https://pub.dev/packages/stormberry
class InMemoryPersistance extends Persistence {
  final Map<String, AuthStateModel> mapState = {};
  final Map<String, AuthUser<Object?>> mapAuthUser = {};
  final Map<String, AppUserComplete> mapAppUser = {};
  final Map<String, UserSession> mapSession = {};

  @override
  Future<AuthStateModel?> getState(String key) async {
    return mapState[key];
  }

  @override
  Future<void> setState(String key, AuthStateModel value) async {
    mapState[key] = value;
  }

  @override
  Future<List<AppUserComplete?>> getUsersById(List<UserId> ids) async {
    return ids.map((id) {
      if (id.kind == UserIdKind.innerId) {
        return mapAppUser[id.id];
      }
      // return mapAuthUser.values.cast<AuthUser?>().firstWhere(
      //       (user) => user!.userIds().contains(id),
      //       orElse: () => null,
      //     );
      return mapAppUser.values.cast<AppUserComplete?>().firstWhere(
            (user) => user!.userIds().contains(id),
            orElse: () => null,
          );
    }).toList();
  }

  @override
  Future<UserSession?> getAnySession(String sessionId) async {
    return mapSession[sessionId];
  }

  @override
  Future<void> saveSession(UserSession session) async {
    mapSession[session.sessionId] = session;
  }

  @override
  Future<AppUserComplete> saveUser(
    String userId,
    AuthUser<Object?> user,
  ) async {
    mapAuthUser[user.key] = user;
    final prevUser = mapAppUser[userId];
    final AppUserComplete newUser;
    if (prevUser == null) {
      // create new user
      newUser = AppUserComplete.merge(userId, [user]);
    } else {
      // update authUsers
      final index = prevUser.authUsers.indexWhere((u) => u.key == user.key);
      if (index == -1) {
        prevUser.authUsers.add(user);
      } else {
        prevUser.authUsers[index] = user;
      }
      // add info from new provider
      newUser = AppUserComplete.merge(
        userId,
        prevUser.authUsers,
        base: prevUser.user,
      );
    }
    mapAppUser[userId] = newUser;
    return newUser;
  }

  @override
  Future<List<UserSession>> getUserSessions(
    String userId, {
    required bool onlyValid,
  }) async {
    return mapSession.values
        .where((s) => s.userId == userId && (!onlyValid || s.isValid))
        .toList();
  }

  @override
  Future<void> updateUser(AppUser user) async {
    final prevUser = mapAppUser[user.userId]!;
    mapAppUser[user.userId] = AppUserComplete(
      user: user,
      authUsers: prevUser.authUsers,
    );
  }
}
