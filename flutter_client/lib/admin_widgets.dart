import 'package:flutter/material.dart';
import 'package:flutter_client/base_widgets.dart';
import 'package:flutter_client/page_config.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:oauth/front_end_client.dart';
import 'package:oauth/oauth.dart';

class AdminUserList extends HookMobxWidget implements ToUriParams {
  ///
  const AdminUserList({super.key});

  static final page = PageValue<AdminUserList, void>(
    'admin/users'.split('/'),
    (uri) => const AdminUserList(),
    (params) => params,
  );

  @override
  UriParams toUriParams() => const UriParams([], null);

  @override
  Widget build(BuildContext context) {
    final admin = InheritedGeneric.depend<AdminClient>(context);
    final users = useValue(admin.users);
    final isLoading = useValue(admin.isLoading);

    return Column(
      children: [
        Visibility(
          visible: isLoading,
          maintainSize: true,
          child: const LinearProgressIndicator(),
        ),
        TextFormField(
          onChanged: admin.getUsersByTextDebounce,
          decoration: const InputDecoration(
            labelText: 'Search Query',
            helperText: 'Search by identifier, email or phone.',
            hintText: 'email@example +138920303 USER_ID',
          ),
        ),
        if (users == null)
          Text('Search by identifier, email or phone.')
        else if (users.isEmpty)
          Text('No users found.')
        else
          Expanded(
            child: ListView(
              children: [
                ...users.map(
                  (e) => Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            UserSessionsList.page.route(
                              UserSessionsList(
                                userId: e.user.userId,
                              ),
                            ),
                          );
                        },
                        child: Text('View Sessions'),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class UserSessionsList extends HookMobxWidget implements ToUriParams {
  ///
  const UserSessionsList({
    required this.userId,
    super.key,
  });
  final String userId;

  static final page = PageValue<UserSessionsList, void>(
    'admin/users'.split('/'),
    (uri) => UserSessionsList(
      userId: uri.pathSegments[3],
    ),
    (params) => params,
  );

  @override
  UriParams toUriParams() => UriParams([userId], null);

  @override
  Widget build(BuildContext context) {
    final admin = InheritedGeneric.depend<AdminClient>(context);
    final userState = useState(
      admin.allUsers[UserId(userId, UserIdKind.innerId)],
    );
    final isMounted = useIsMounted();
    final user = userState.value;

    void Function()? refresh() {
      admin.getUserWithSessionsById(userId).then((response) {
        if (!isMounted()) return;
        final users = response.data;
        if (users == null) {
          // TODO: error
        } else if (users.users.isEmpty) {
          // TODO: error not found
        } else {
          userState.value = users.users.first;
        }
      });
      return null;
    }

    useEffect(refresh, const []);

    if (user == null || user.sessions == null) {
      return const CircularProgressIndicator();
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              ...user.sessions!.map(
                (e) {
                  final data = e.clientData;
                  return Card(
                    child: Column(
                      children: [
                        SelectableText('SessionId: ${e.sessionId}'),
                        SelectableText('UserId: ${e.userId}'),
                        SelectableText('DeviceId: ${e.deviceId}'),
                        SelectableText(
                          'CreatedAt: ${e.createdAt.toIso8601String()}',
                        ),
                        SelectableText(
                          'LastTokenRefresh: ${e.lastRefreshAt.toIso8601String()}',
                        ),
                        SelectableText(
                          'EndedAt: ${e.endedAt?.toIso8601String()}',
                        ),
                        SelectableText('DeviceId: ${e.deviceId}'),
                        if (data == null)
                          const Text('No Data')
                        else
                          Column(
                            children: [
                              SelectableText('ApiVersion: ${data.apiVersion}'),
                              SelectableText('Country: ${data.country}'),
                              SelectableText('IpAddress: ${data.ipAddress}'),
                              SelectableText('Platform: ${data.platform}'),
                              SelectableText('UserAgent: ${data.userAgent}'),
                              SelectableText('DeviceId: ${data.deviceId}'),
                            ],
                          ),
                        Column(
                          children: [
                            Text('Authentication Providers'),
                            ...e.mfa.map(
                              (e) => Row(
                                children: [
                                  SelectableText('ProviderId: ${e.providerId}'),
                                  SelectableText(
                                    'ProviderUserId: ${e.providerUserId}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
