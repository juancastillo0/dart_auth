import 'dart:convert' show jsonEncode;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:oauth/oauth.dart';

import 'auth_client.dart';
import 'hooks_mobx.dart';
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
    final isEditingMFA = useState<MFAConfig?>(null);
    final isLoadingEditingMFA = useState(false);
    final optionalCountController = useTextEditingController(
      text: userInfo.user.multiFactorAuth.optionalCount.toString(),
    );
    final mfaItems = isEditingMFA.value ?? userInfo.user.multiFactorAuth;

    Widget authUserItem(AuthUser<Object?> e) {
      final item = MFAItem(
        providerId: e.providerId,
        providerUserId: e.providerUserId,
      );
      final kind = mfaItems.kind(item);
      final current = isEditingMFA.value;
      void updateKind() {
        if (current == null) return;
        switch (kind) {
          case MFAProviderKind.required:
            isEditingMFA.value = current.addOptional(item);
            break;
          case MFAProviderKind.optional:
            isEditingMFA.value = current.removeItem(item);
            break;
          case MFAProviderKind.none:
            isEditingMFA.value = current.addRequired(item);
            break;
        }
      }

      return AuthProviderWidget(
        key: Key(e.key),
        e: e,
        mfaItems: MFAChip(
          kind: kind,
          onTap: current != null ? updateKind : null,
        ),
      );
    }

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
        if (!mfaItems.isEmpty)
          MFAProvidersWidget(
            isLoadingEditingMFA: isLoadingEditingMFA,
            mfaItems: mfaItems,
            isEditingMFA: isEditingMFA,
            optionalCountController: optionalCountController,
            state: state,
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
                        ...userInfo.authUsers.map(authUserItem),
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

class MFAProvidersWidget extends StatelessWidget {
  ///
  const MFAProvidersWidget({
    super.key,
    required this.isLoadingEditingMFA,
    required this.mfaItems,
    required this.isEditingMFA,
    required this.optionalCountController,
    required this.state,
  });

  final ValueNotifier<bool> isLoadingEditingMFA;
  final MFAConfig mfaItems;
  final ValueNotifier<MFAConfig?> isEditingMFA;
  final TextEditingController optionalCountController;
  final AuthState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          key: const Key('mfa'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoadingEditingMFA.value)
              const LinearProgressIndicator(key: Key('mfa-loading')),
            Center(
              child: Text(
                'MFA',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Required Providers',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            ...mfaItems.requiredItems.map(
              (e) => Padding(
                padding: const EdgeInsets.all(6),
                child: Text('- ${e.providerId}: ${e.providerUserId}'),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Optional Providers',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    key: const Key('mfa-optional-count'),
                    readOnly: isEditingMFA.value == null,
                    enabled: isEditingMFA.value != null,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Optional Count',
                    ),
                    controller: optionalCountController,
                    onChanged: (value) {
                      final intValue = int.tryParse(value);
                      if (intValue == null) return;
                      isEditingMFA.value =
                          isEditingMFA.value!.changeOptionalCount(intValue);
                    },
                  ),
                ),
              ],
            ),
            if (mfaItems.optionalItems.isEmpty)
              const Padding(
                padding: EdgeInsets.all(14),
                child: Text('No optional providers'),
              ),
            ...mfaItems.optionalItems.map(
              (e) => Padding(
                padding: const EdgeInsets.all(6),
                child: Text('- ${e.providerId}: ${e.providerUserId}'),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isEditingMFA.value == null)
                  ElevatedButton.icon(
                    key: const Key('mfa-edit'),
                    onPressed: () {
                      isEditingMFA.value = mfaItems;
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit MFA'),
                  )
                else
                  ElevatedButton.icon(
                    key: const Key('mfa-revert'),
                    onPressed: () {
                      isEditingMFA.value = null;
                      optionalCountController.text =
                          mfaItems.optionalCount.toString();
                      // showDialog(
                      //   context: context,
                      //   builder: (context) => SimpleDialog(
                      //     children: [],
                      //   ),
                      // );
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Revert MFA'),
                  ),
                if (isEditingMFA.value != null)
                  ElevatedButton.icon(
                    key: const Key('mfa-submit-update'),
                    onPressed: () async {
                      if (!isEditingMFA.value!.isValid) {
                        // TODO: validate fields
                      }
                      if (isLoadingEditingMFA.value) return;
                      isLoadingEditingMFA.value = true;
                      await state.setUserMFA(MFAPostData(isEditingMFA.value!));
                      // TODO: errors
                      isEditingMFA.value = null;
                      isLoadingEditingMFA.value = false;
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Submit MFA Update'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AuthProviderWidget extends HookMobxWidget {
  const AuthProviderWidget({
    super.key,
    required this.mfaItems,
    required this.e,
  });

  final Widget mfaItems;
  final AuthUser<void> e;

  @override
  Widget build(BuildContext context) {
    final memoryPicture = useMemoized(
      () {
        if (e.picture == null) return null;
        final data = Uri.parse(e.picture!).data;
        return data?.contentAsBytes();
      },
      [e.picture],
    );
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
                        mfaItems,
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
                  memoryPicture != null
                      ? Image.memory(
                          key: const Key('picture'),
                          memoryPicture,
                          width: 100,
                        )
                      : Image.network(
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

class MFAChip extends StatelessWidget {
  ///
  const MFAChip({
    super.key,
    required this.kind,
    this.onTap,
  });

  final MFAProviderKind kind;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    // TODO: use dropdown
    switch (kind) {
      case MFAProviderKind.required:
        return Chip(
          backgroundColor: Theme.of(context).colorScheme.primary,
          onDeleted: onTap,
          label: const Text('MFA req'),
        );
      case MFAProviderKind.optional:
        return Chip(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          onDeleted: onTap,
          label: const Text('MFA opt'),
        );
      case MFAProviderKind.none:
        return Chip(
          backgroundColor: Theme.of(context).colorScheme.background,
          onDeleted: onTap,
          label: const Text('no MFA'),
        );
    }
  }
}

extension MFAConfigChange on MFAConfig {
  MFAConfig addRequired(MFAItem item) {
    return MFAConfig(
      requiredItems: {...requiredItems, item},
      optionalCount: optionalCount,
      optionalItems: {...optionalItems}..remove(item),
    );
  }

  MFAConfig addOptional(MFAItem item) {
    return MFAConfig(
      optionalItems: {...optionalItems, item},
      optionalCount: optionalCount,
      requiredItems: {...requiredItems}..remove(item),
    );
  }

  MFAConfig removeItem(MFAItem item) {
    return MFAConfig(
      requiredItems: {...requiredItems}..remove(item),
      optionalCount: optionalCount,
      optionalItems: {...optionalItems}..remove(item),
    );
  }

  MFAConfig changeOptionalCount(int optionalCount) {
    return MFAConfig(
      requiredItems: requiredItems,
      optionalCount: optionalCount,
      optionalItems: optionalItems,
    );
  }
}
