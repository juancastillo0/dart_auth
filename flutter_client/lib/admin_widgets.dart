import 'package:flutter/material.dart';
import 'package:flutter_client/base_widgets.dart';
import 'package:flutter_client/page_config.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
    final admin = globalStateOf(context).adminState;
    final t = getTranslations(context);
    final users = useValue(admin.users);
    final isLoading = useValue(admin.isLoading);
    final controller = useTextEditingController();

    return Center(
      child: Container(
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          children: [
            TextFormField(
              controller: controller,
              onChanged: admin.getUsersByTextDebounce,
              decoration: InputDecoration(
                labelText: t.adminSearchLabel,
                helperText: t.adminSearchHelperText,
                hintText: t.adminSearchHint,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    admin.debouncer.cancel();
                  },
                ),
              ),
            ),
            Visibility(
              visible: isLoading,
              child: const LinearProgressIndicator(),
            ),
            if (users == null)
              Padding(
                padding: const EdgeInsets.all(28),
                child: Text(t.adminSearchMainPrompt),
              )
            else if (users.isEmpty)
              Padding(
                padding: const EdgeInsets.all(28),
                child: Text(t.adminNoUsersFound),
              )
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
                            child: Text(t.adminViewSessions),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
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
    'users/sessions'.split('/'),
    (uri) => UserSessionsList(
      userId: uri.pathSegments[3],
    ),
    (params) => params,
  );

  @override
  UriParams toUriParams() => UriParams([userId], null);

  @override
  Widget build(BuildContext context) {
    final admin = globalStateOf(context).adminState;
    final t = getTranslations(context);
    final userState = useState(
      admin.allUsers[UserId(userId, UserIdKind.innerId)],
    );
    final isMounted = useIsMounted();
    final user = userState.value;

    void Function()? refresh() {
      Future<void>.delayed(Duration.zero)
          .then((value) => admin.getUserWithSessionsById(userId))
          .then((response) {
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

    Widget title(String e) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 2,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            ),
            const SizedBox(height: 4),
            Text(
              e,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      );
    }

    Widget item(String title, String? content) {
      return SelectableText('$title: $content');
    }

    Widget sessionWidget(UserSessionBase e) {
      final data = e.clientData;
      return Card(
        key: Key(e.sessionId),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              item(t.adminSessionId, e.sessionId),
              item(t.adminUserId, e.userId),
              title(t.adminDates),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  item(t.adminCreatedAt, e.createdAt.toIso8601String()),
                  item(
                    t.adminLastTokenRefresh,
                    e.lastRefreshAt.toIso8601String(),
                  ),
                  item(
                    t.adminEndedAt,
                    e.endedAt?.toIso8601String(),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title(t.adminClientNetworkData),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      item(t.adminIpAddress, data.ipAddress),
                      item(t.adminHost, data.host),
                      item(t.adminCountry, data.country),
                      item(t.adminLanguages, data.languages.toString()),
                      item(t.adminTimezone, data.timezone),
                    ],
                  ),
                  title(t.adminClientDevice),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      item(t.adminDeviceId, data.deviceId),
                      item(t.adminPlatform, data.platform),
                      item(t.adminUserAgent, data.userAgent),
                      item(t.adminApiVersion, data.apiVersion),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  title(t.adminAuthenticationProviders),
                  ...e.mfa.map(
                    (e) => Padding(
                      key: Key(e.userId.id),
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          item(t.adminProviderId, e.providerId),
                          item(
                            t.adminProviderUserId,
                            e.providerUserId,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      );
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                t.adminSessions,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ...user.sessions!.map(sessionWidget),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
