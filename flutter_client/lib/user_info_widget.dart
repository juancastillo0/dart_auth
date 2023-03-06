import 'dart:convert' show jsonEncode;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:oauth/oauth.dart';

import 'main.dart';

class UserInfoWidget extends HookWidget {
  const UserInfoWidget({
    super.key,
    required this.userInfo,
  });

  final UserInfoMe userInfo;

  @override
  Widget build(BuildContext context) {
    final state = GlobalState.of(context).authState;

    final mfaItems = userInfo.user.multiFactorAuth;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(38),
          child: Text(jsonEncode(userInfo)),
        ),
        ElevatedButton.icon(
          onPressed: state.signOut,
          icon: const Icon(Icons.close),
          label: const Text('Sign Out'),
        ),
        const SizedBox(height: 20),
        // TODO: Improve MFA. Configure required and optional providers
        if (mfaItems.isNotEmpty)
          Column(
            key: const Key('mfa'),
            children: [
              Text(
                'MFA',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              ...mfaItems.map(
                (e) => Row(
                  children: [
                    Text(e.providerId),
                    Text(e.providerUserId),
                  ],
                ),
              ),
            ],
          ),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Authentication Providers',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ...userInfo.authUsers.map(
                          (e) => AuthProviderWidget(
                            key: Key(e.key),
                            e: e,
                            mfaItems: mfaItems,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ElevatedButton.icon(
                    key: const Key('addMfa'),
                    onPressed: state.addMFAProvider,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Multi-Factor Authentication'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AuthProviderWidget extends StatelessWidget {
  const AuthProviderWidget({
    super.key,
    required this.mfaItems,
    required this.e,
  });

  final List<MFAItem> mfaItems;
  final AuthUser<void> e;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Column(
              key: const Key('provider'),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            e.providerId,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (mfaItems.any(
                          (mfa) =>
                              mfa ==
                              MFAItem(
                                providerId: e.providerId,
                                providerUserId: e.providerUserId,
                              ),
                        ))
                          const Chip(label: Text('MFA')),
                      ],
                    ),
                    ElevatedButton.icon(
                      key: const Key('provider-edit'),
                      // TODO: change email/phone/password. Delete provider
                      onPressed: () {},
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Identifier: '),
                          Expanded(child: Text(e.providerUserId)),
                        ],
                      ),
                      if (e.name != null)
                        Row(
                          key: const Key('name'),
                          children: [
                            const Text('Name: '),
                            Expanded(
                              child: Text(
                                e.name!,
                              ),
                            ),
                          ],
                        ),
                      // TODO: change email/phone/password
                      if (e.email != null)
                        Row(
                          key: const Key('email'),
                          children: [
                            const Text('Email: '),
                            Text(e.email!),
                            Chip(
                              backgroundColor: !e.emailIsVerified
                                  ? Theme.of(context).colorScheme.errorContainer
                                  : null,
                              label: Text(
                                e.emailIsVerified ? 'verified' : 'not verified',
                              ),
                            ),
                          ],
                        ),
                      if (e.phone != null)
                        Row(
                          key: const Key('phone'),
                          children: [
                            const Text('Phone: '),
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(e.phone!),
                            ),
                            Chip(
                              backgroundColor: !e.phoneIsVerified
                                  ? Theme.of(context).colorScheme.errorContainer
                                  : null,
                              label: Text(
                                e.phoneIsVerified ? 'verified' : 'not verified',
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (e.picture != null)
                  Image.network(
                    key: const Key('picture'),
                    e.picture!,
                    width: 100,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
