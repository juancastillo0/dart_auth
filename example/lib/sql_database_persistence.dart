import 'dart:async' show Completer, FutureOr, Zone, runZoned;
import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:oauth/flow.dart';
import 'package:oauth/oauth.dart';
import 'package:sqlite3/sqlite3.dart';

class SQLTables {
  final String authState;
  final String session;
  final String user;
  final String account;

  ///
  const SQLTables({
    this.authState = 'authState',
    this.session = 'session',
    this.user = 'user',
    this.account = 'account',
  });
}

class SQLitePersistence extends Persistence {
  final Database database;
  final SQLTables tables;
  final Map<String, AuthenticationProvider<dynamic>> providers;

  ///
  SQLitePersistence({
    required this.database,
    required this.providers,
    this.tables = const SQLTables(),
  });

  Future<SQLitePersistence> init() async {
    const jsonType = 'TEXT';
    database.execute(
      '''
CREATE TABLE IF NOT EXISTS ${tables.user} (
  userId TEXT NOT NULL,
  name TEXT NULL,
  picture TEXT NULL,
  createdAt DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  multiFactorAuth $jsonType NOT NULL,
  PRIMARY KEY (userId)
);''',
    );
    // TODO: encrypt data
    database.execute('''
CREATE TABLE IF NOT EXISTS ${tables.account} (
  userId TEXT NOT NULL,
  providerId TEXT NOT NULL,
  providerUserId TEXT NOT NULL,
  name TEXT NULL,
  picture TEXT NULL,
  email TEXT NULL,
  emailIsVerified BOOL NOT NULL,
  phone TEXT NULL,
  phoneIsVerified BOOL NOT NULL,
  rawUserData $jsonType NOT NULL,
  createdAt DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (providerId, providerUserId),
  FOREIGN KEY (userId) REFERENCES ${tables.user} (userId)
);''');
    database.execute('''
CREATE TABLE IF NOT EXISTS ${tables.session} (
  sessionId TEXT NOT NULL,
  deviceId TEXT NULL,
  refreshToken TEXT NULL,
  userId TEXT NOT NULL,
  meta $jsonType NULL,
  mfa $jsonType NOT NULL,
  endedAt DATE NULL,
  createdAt DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (sessionId),
  FOREIGN KEY (userId) REFERENCES ${tables.user} (userId)
);''');
    database.execute('''
CREATE TABLE IF NOT EXISTS ${tables.authState} (
  key TEXT NOT NULL,
  value $jsonType NOT NULL,
  createdAt DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (key)
);''');

    // TODO: information_schema.columns for MySQL and Postgres
    final infoResult = database.select('PRAGMA table_info(${tables.user});');
    print(infoResult.columnNames);
    print(infoResult.rows);
    return this;
  }

  @override
  Future<AuthStateModel?> getState(String key) async {
    await waitTransaction();
    final result = database.select(
      'SELECT * FROM ${tables.authState} WHERE key = ?;',
      [key],
    );
    if (result.isEmpty) return null;
    final valueIndex = result.columnNames.indexOf('value');
    return AuthStateModel.fromJson(
      valueIndex == -1
          ? Map.fromIterables(result.columnNames, result.rows.first)
          : jsonDecode(result.rows.first[valueIndex]! as String)
              as Map<String, Object?>,
    );
  }

  @override
  Future<void> setState(String key, AuthStateModel value) async {
    await waitTransaction();
    database.execute(
      '''INSERT OR REPLACE INTO ${tables.authState} ('key', 'value', 'createdAt') VALUES (?, ?, ?);''',
      [key, jsonEncode(value), value.createdAt.toIso8601String()],
    );
  }

  @override
  Future<void> saveSession(UserSession session) async {
    await waitTransaction();
    _insertOrReplace(tables.session, session.toJson());
  }

  @override
  Future<UserSession?> getAnySession(String sessionId) async {
    await waitTransaction();
    final result = database.select(
      'SELECT * FROM ${tables.session} WHERE sessionId = ?;',
      [sessionId],
    );
    if (result.isEmpty) return null;
    return UserSession.fromJson(
      Map.fromIterables(result.columnNames, result.rows.first),
    );
  }

  @override
  Future<List<UserSession>> getUserSessions(
    String userId, {
    required bool onlyValid,
  }) async {
    await waitTransaction();
    final result = database.select(
      'SELECT * FROM ${tables.session} WHERE userId = ?;',
      [userId],
    );
    return result.rows
        .map(
          (row) => UserSession.fromJson(
            Map.fromIterables(result.columnNames, row),
          ),
        )
        .where((element) => !onlyValid || element.isValid)
        .toList();
  }

  @override
  Future<void> updateUser(AppUser user) async {
    await waitTransaction();
    database.execute(
      // TODO: do not replace other values
      '''
INSERT OR REPLACE INTO ${tables.user} 
('userId', 'name', 'picture', 'createdAt', 'multiFactorAuth') VALUES (?, ?, ?, ?, ?);''',
      [
        user.userId,
        user.name,
        user.picture,
        user.createdAt.toIso8601String(),
        // TODO: maybe save it for each account?
        jsonEncode(user.multiFactorAuth),
      ],
    );
  }

  String userIdCondition(UserId userId) {
    switch (userId.kind) {
      case UserIdKind.innerId:
        return '${tables.user}.userId = ?';
      case UserIdKind.providerId:
        return '${tables.account}.providerId = ? AND ${tables.account}.providerUserId = ?';
      case UserIdKind.verifiedEmail:
        return '${tables.account}.email = ? AND ${tables.account}.emailIsVerified = true';
      case UserIdKind.verifiedPhone:
        return '${tables.account}.phone = ? AND ${tables.account}.phoneIsVerified = true';
    }
  }

  @override
  Future<List<AppUserComplete?>> getUsersById(List<UserId> ids) async {
    await waitTransaction();
    final result = database.select(
// TODO: use json_group_array(json_object(${tables.account}2))
      '''
SELECT ${tables.user}.userId, ${tables.user}.name, ${tables.user}.picture, ${tables.user}.createdAt, ${tables.user}.multiFactorAuth, 
${tables.account}2.* FROM ${tables.user} 
INNER JOIN ${tables.account} ON ${tables.account}.userId = ${tables.user}.userId
INNER JOIN ${tables.account} ${tables.account}2 ON ${tables.account}2.userId = ${tables.user}.userId
WHERE ${ids.map(userIdCondition).join(' OR ')}
GROUP BY ${tables.account}2.providerId, ${tables.account}2.providerUserId;
''',
      ids
          .expand(
            (e) => e.kind == UserIdKind.providerId ? e.id.split(':') : [e.id],
          )
          .toList(),
    );
    const userIdIndex = 0;
    final providerIdIndex = result.columnNames.indexOf('providerId');

    final Map<String, List<MapEntry<List<Object?>, AuthUser<Object?>>>>
        listMap = result.rows
            .map(
      (row) => MapEntry(
        row,
        AuthUser.fromJson(
          // TODO: named tables
          Map.fromIterables(result.columnNames, row),
          providers[row[providerIdIndex]]!,
        ),
      ),
    )
            .fold(
      {},
      (m, v) => m..putIfAbsent(v.key[userIdIndex]! as String, () => []).add(v),
    );

    final usersComplete = listMap.entries.map(
      (e) {
        final userColumns = e.value.first.key;
        return AppUserComplete.merge(
          e.key,
          e.value.map((e) => e.value).toList(),
          base: AppUser(
            userId: e.key,
            emailIsVerified: false,
            phoneIsVerified: false,
            name: userColumns[1] as String?,
            picture: userColumns[2] as String?,
            createdAt: DateTime.parse(userColumns[3]! as String),
            multiFactorAuth: MFAConfig.fromJson(
              jsonDecode(userColumns[4]! as String) as Map<String, Object?>,
            ),
          ),
        );
      },
    );
    final Map<UserId, AppUserComplete> map = Map.fromEntries(
      usersComplete.expand((e) => e.userIds().map((id) => MapEntry(id, e))),
    );
    return ids.map((e) => map[e]).toList();
  }

  @override
  Future<AppUserComplete> saveUser(
    String userId,
    AuthUser<Object?> user,
  ) async {
    final result = await transaction(() async {
      AppUserComplete? prevUser =
          await getUserById(UserId(userId, UserIdKind.innerId));
      if (prevUser == null) {
        prevUser = AppUserComplete.merge(userId, [user]);
        // TODO: maybe insert
        await updateUser(prevUser.user);
      } else {
        prevUser = AppUserComplete.merge(
          userId,
          [...prevUser.authUsers.where((e) => e.key != user.key), user],
          base: prevUser.user,
        );
      }
      final fields = {
        'userId': userId,
        'providerId': user.providerId,
        'providerUserId': user.providerUserId,
        'name': user.name,
        'picture': user.picture,
        'email': user.email,
        'emailIsVerified': user.emailIsVerified,
        'phone': user.phone,
        'phoneIsVerified': user.phoneIsVerified,
        // TODO: always use "rawUserData" key in toJson?
        'rawUserData': jsonEncode(user.rawUserData),
      };
      database.execute(
        '''
INSERT OR REPLACE INTO ${tables.account} ('${fields.keys.join("','")}') 
VALUES (${Iterable.generate(fields.length, (_) => '?').join(',')});
''',
        fields.values.toList(),
      );
      return prevUser;
    });
    if (result.isErr()) throw result.unwrapErr();
    return result.unwrap();
  }

  @override
  Future<void> deleteAuthUser(String userId, AuthUser<Object?> authUser) async {
    await waitTransaction();
    database.execute(
      '''DELETE FROM ${tables.account} WHERE providerId = ? AND providerUserId = ?;''',
      [
        authUser.providerId,
        authUser.providerUserId,
      ],
    );
  }

  static Future<void>? _transactionFuture;
  static final _inTransactionZoneKey = Object();

  static bool get inTransaction =>
      Zone.current[_inTransactionZoneKey] as bool? ?? false;

  static FutureOr<void> waitTransaction() {
    // TODO: support multiple client processes by using sqlite transaction error codes
    if (inTransaction) return null;
    return _transactionFuture;
  }

  Future<Result<T, ErrorWithStackTrace>> transaction<T extends Object>(
    Future<T> Function() fn,
  ) async {
    if (_transactionFuture != null) {
      if (!inTransaction) {
        // other external transaction
        await _transactionFuture!;
        return transaction(fn);
      }
      // same transaction, but nested
      try {
        final result = await fn();
        return Ok(result);
      } catch (e, s) {
        return Err(ErrorWithStackTrace(e, s));
      }
    }
    final completer = Completer<void>();
    _transactionFuture = completer.future;
    try {
      database.execute('BEGIN TRANSACTION;');
      final result =
          await runZoned(fn, zoneValues: {_inTransactionZoneKey: true});
      database.execute('COMMIT TRANSACTION;');
      return Ok(result);
    } catch (e, s) {
      try {
        database.execute('ROLLBACK TRANSACTION;');
      } catch (_) {}
      return Err(ErrorWithStackTrace(e, s));
    } finally {
      completer.complete();
      _transactionFuture = null;
    }
  }

  void _insertOrReplace(String table, Map<String, Object?> fields) {
    database.execute(
      '''
INSERT OR REPLACE INTO ${table} ('${fields.keys.join("','")}') 
VALUES (${Iterable.generate(fields.length, (_) => '?').join(',')});
''',
      fields.values.map((v) {
        if (v is List || v is Map || v is SerializableToJson) {
          return jsonEncode(v);
        } else if (v is DateTime) {
          // TODO:
          return v.toIso8601String();
        } else {
          return v;
        }
      }).toList(),
    );
  }
}
