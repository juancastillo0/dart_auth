import 'dart:convert' show jsonEncode;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:oauth/endpoint_models.dart';
import 'package:oauth/oauth.dart';

import 'auth_client.dart';
import 'base_widgets.dart';
import 'credentials_form.dart';
import 'main.dart';

class UserInfoWidget extends HookWidget {
  const UserInfoWidget({
    super.key,
    required this.userInfo,
  });

  final UserInfoMe userInfo;

  static const addMfaWidgetKey = Key('addMfa');

  @override
  Widget build(BuildContext context) {
    final t = getTranslations(context);
    final state = GlobalState.of(context).authState;
    final editedMFA = useState<MFAConfig?>(null);
    final isLoadingEditingMFA = useState(false);
    final optionalCountController = useTextEditingController(
      text: userInfo.user.multiFactorAuth.optionalCount.toString(),
    );
    final mfaItems = editedMFA.value ?? userInfo.user.multiFactorAuth;

    Widget authUserItem(AuthUserData data) {
      final e = data.authUser;
      final item = ProviderUserId(
        providerId: e.providerId,
        providerUserId: e.providerUserId,
      );
      final current = editedMFA.value;
      void updateKind(MFAProviderKind kind) {
        if (current == null) return;
        switch (kind) {
          case MFAProviderKind.required:
            editedMFA.value = current.addRequired(item);
            break;
          case MFAProviderKind.optional:
            editedMFA.value = current.addOptional(item);
            break;
          case MFAProviderKind.none:
            editedMFA.value = current.removeItem(item);
            break;
        }
      }

      final kind = mfaItems.kind(item);
      return AuthProviderWidget(
        key: Key(e.key),
        data: data,
        mfaItems: MFAChip(
          kind: kind,
          onTap: current != null ? updateKind : null,
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(38),
            child: Text(jsonEncode(userInfo)),
          ),
          ElevatedButton.icon(
            onPressed: state.signOut,
            icon: const Icon(Icons.close),
            label: Text(t.signOut),
          ),
          const SizedBox(height: 20),
          Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.authenticationProviders,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...userInfo.authUsers.map(authUserItem),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ElevatedButton.icon(
                    key: addMfaWidgetKey,
                    onPressed: state.addMFAProvider,
                    icon: const Icon(Icons.add),
                    label: Text(t.addMultiFactorAuthentication),
                  ),
                ),
              ],
            ),
          ),
          if (!mfaItems.isEmpty || editedMFA.value != null)
            MFAProvidersWidget(
              isLoadingEditingMFA: isLoadingEditingMFA,
              userMfaItems: userInfo.user.multiFactorAuth,
              editedMFA: editedMFA,
              optionalCountController: optionalCountController,
            ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }
}

class MFAProvidersWidget extends StatelessWidget {
  ///
  const MFAProvidersWidget({
    super.key,
    required this.isLoadingEditingMFA,
    required this.userMfaItems,
    required this.editedMFA,
    required this.optionalCountController,
  });

  final ValueNotifier<bool> isLoadingEditingMFA;
  final MFAConfig userMfaItems;
  final ValueNotifier<MFAConfig?> editedMFA;
  final TextEditingController optionalCountController;

  static const mfaLoadingWidgetKey = Key('mfaLoading');
  static const mfaWidgetKey = Key('mfa');
  static const mfaOptionalCountWidgetKey = Key('mfaOptionalCount');
  static const mfaEditWidgetKey = Key('mfaEdit');
  static const mfaRevertWidgetKey = Key('mfaRevert');
  static const mfaSubmitUpdateWidgetKey = Key('mfaSubmitUpdate');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = GlobalState.of(context).authState;
    final t = getTranslations(context);
    final mfaItems = editedMFA.value ?? userMfaItems;
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          key: mfaWidgetKey,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoadingEditingMFA.value)
              const LinearProgressIndicator(key: mfaLoadingWidgetKey),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                t.multiFactorAuthentication,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  t.requiredProviders,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            if (mfaItems.requiredItems.isEmpty)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(t.noRequiredProviders),
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
                  t.optionalProviders,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(
                  width: 135,
                  child: TextFormField(
                    key: mfaOptionalCountWidgetKey,
                    readOnly: editedMFA.value == null,
                    enabled: editedMFA.value != null,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: t.optionalAmount,
                    ),
                    controller: optionalCountController,
                    onChanged: (value) {
                      final intValue = int.tryParse(value);
                      if (intValue == null) return;
                      editedMFA.value =
                          editedMFA.value!.changeOptionalCount(intValue);
                    },
                  ),
                ),
              ],
            ),
            if (mfaItems.optionalItems.isEmpty)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(t.noOptionalProviders),
              ),
            ...mfaItems.optionalItems.map(
              (e) => Padding(
                padding: const EdgeInsets.all(6),
                child: Text('- ${e.providerId}: ${e.providerUserId}'),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (editedMFA.value == null)
                  ElevatedButton.icon(
                    key: mfaEditWidgetKey,
                    onPressed: () {
                      editedMFA.value = userMfaItems;
                    },
                    icon: const Icon(Icons.edit),
                    label: Text(t.editMFA),
                  )
                else
                  ElevatedButton.icon(
                    key: mfaRevertWidgetKey,
                    onPressed: () {
                      editedMFA.value = null;
                      optionalCountController.text =
                          userMfaItems.optionalCount.toString();
                    },
                    icon: const Icon(Icons.close),
                    label: Text(t.revertMFA),
                  ),
                if (editedMFA.value != null)
                  ElevatedButton.icon(
                    key: mfaSubmitUpdateWidgetKey,
                    onPressed: () async {
                      if (!editedMFA.value!.isValid) {
                        // TODO: validate fields
                      }
                      if (isLoadingEditingMFA.value) return;
                      final scaffold = ScaffoldMessenger.of(context);
                      isLoadingEditingMFA.value = true;
                      final response = await state.setUserMFA(
                        MFAPostData(editedMFA.value!),
                      );
                      isLoadingEditingMFA.value = false;
                      final error = response?.response?.error;
                      if (error != null) {
                        final message = error.allErrors
                            .map(state.globalState.translate)
                            .join('\n');
                        scaffold.showSnackBar(
                          SnackBar(
                            backgroundColor: theme.colorScheme.error,
                            content: Text(message),
                          ),
                        );
                      } else {
                        editedMFA.value = null;
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: Text(t.submitMFAUpdate),
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
  ///
  const AuthProviderWidget({
    super.key,
    required this.mfaItems,
    required this.data,
  });

  final Widget mfaItems;
  final AuthUserData data;

  static const editWidgetKey = Key('providerEdit');
  static const deleteWidgetKey = Key('providerDelete');
  static const providerWidgetKey = Key('provider');
  static const nameWidgetKey = Key('name');
  static const emailWidgetKey = Key('email');
  static const phoneWidgetKey = Key('phone');
  static const pictureWidgetKey = Key('picture');

  @override
  Widget build(BuildContext context) {
    final t = getTranslations(context);
    final state = GlobalState.of(context).authState;
    final userInfo = useValueListenable(state.userInfo);
    final isDeleting = useState(false);
    final e = data.authUser;
    final memoryPicture = useMemoized(
      () {
        if (e.picture == null) return null;
        final data = Uri.parse(e.picture!).data;
        return data?.contentAsBytes();
      },
      [e.picture],
    );
    final providerUserId = ProviderUserId(
      providerId: data.authUser.providerId,
      providerUserId: data.authUser.providerUserId,
    );
    final mounted = useIsMounted();
    final colorScheme = Theme.of(context).colorScheme;

    Future<void> deleteAuthProvider() async {
      isDeleting.value = true;
      Navigator.of(context).pop();
      final scaffold = ScaffoldMessenger.of(context);
      final result = await state.deleteAuthProvider(providerUserId);
      if (!mounted()) return;
      isDeleting.value = false;
      final error = result?.response?.error;
      if (error != null) {
        scaffold.showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.error,
            content: Text(
              error.allErrors.map(state.globalState.translate).join('\n'),
            ),
          ),
        );
      }
    }

    final buttons = Row(
      children: [
        if (data.updateParams != null)
          ElevatedButton.icon(
            key: editWidgetKey,
            onPressed: () {
              showDialog<dynamic>(
                context: context,
                builder: (context) {
                  final navigator = Navigator.of(context);
                  return Dialog(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: CredentialsProviderForm(
                        CredentialsProviderData(
                          paramDescriptions:
                              data.updateParams!.paramDescriptions,
                          providerName: data.providerName,
                          providerId: data.authUser.providerId,
                        ),
                        updateParams: UpdateCredentialsParams(
                          data: data,
                          onUpdate: navigator.pop,
                          onCancelFlow: navigator.pop,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            icon: const Icon(Icons.edit),
            label: Text(t.edit),
          ),
        if (userInfo != null && userInfo.authUsers.length > 1)
          AnimatedCrossFade(
            duration: const Duration(seconds: 2),
            crossFadeState: isDeleting.value
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            secondChild: const CircularProgressIndicator(),
            firstChild: IconButton(
              key: deleteWidgetKey,
              // TODO: Delete provider
              onPressed: userInfo.user.multiFactorAuth.kind(providerUserId) ==
                      MFAProviderKind.none
                  ? () async {
                      await showDialog<void>(
                        context: context,
                        builder: (context) {
                          final navigator = Navigator.of(context);
                          final colorScheme = Theme.of(context).colorScheme;
                          return AlertDialog(
                            content: Text(
                              t.deleteAuthenticationProviderConfirmation,
                            ),
                            actions: [
                              TextButton(
                                onPressed: navigator.pop,
                                child: Text(t.cancel),
                              ),
                              TextButton(
                                onPressed: deleteAuthProvider,
                                style: TextButton.styleFrom(
                                  backgroundColor: colorScheme.error,
                                  foregroundColor: colorScheme.onError,
                                ),
                                child: Text(t.delete),
                              )
                            ],
                          );
                        },
                      );
                    }
                  : null,
              icon: const Icon(Icons.delete),
            ),
          ),
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          children: [
            Column(
              key: providerWidgetKey,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: Text(
                            translate(context, data.providerName),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        mfaItems,
                      ],
                    ),
                    buttons,
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
                          Text('${t.identifier}: '),
                          Expanded(child: Text(e.providerUserId)),
                        ],
                      ),
                      if (e.name != null)
                        Row(
                          key: nameWidgetKey,
                          children: [
                            Text('${t.name}: '),
                            Expanded(
                              child: Text(
                                e.name!,
                              ),
                            ),
                          ],
                        ),
                      if (e.email != null)
                        Row(
                          key: emailWidgetKey,
                          children: [
                            Text('${t.email}: '),
                            Text(e.email!),
                            const SizedBox(width: 6),
                            Chip(
                              backgroundColor: !e.emailIsVerified
                                  ? Theme.of(context).colorScheme.errorContainer
                                  : null,
                              label: Text(
                                e.emailIsVerified ? t.verified : t.notVerified,
                              ),
                            ),
                          ],
                        ),
                      if (e.phone != null)
                        Row(
                          key: phoneWidgetKey,
                          children: [
                            Text('${t.phone}: '),
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(e.phone!),
                            ),
                            Chip(
                              backgroundColor: !e.phoneIsVerified
                                  ? Theme.of(context).colorScheme.errorContainer
                                  : null,
                              label: Text(
                                e.phoneIsVerified ? t.verified : t.notVerified,
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
                          key: pictureWidgetKey,
                          memoryPicture,
                          width: 100,
                        )
                      : Image.network(
                          key: pictureWidgetKey,
                          e.picture!,
                          width: 100,
                        ),
              ],
            ),
            const SizedBox(height: 6),
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
  final void Function(MFAProviderKind)? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: DropdownButtonFormField<MFAProviderKind>(
        items: MFAProviderKind.values.map(
          (e) {
            return DropdownMenuItem(
              value: e,
              child: Text(e.name),
            );
          },
        ).toList(),
        onChanged: onTap == null ? null : (value) => onTap!.call(value!),
        value: kind,
      ),
    );
  }
}

extension MFAConfigChange on MFAConfig {
  MFAConfig addRequired(ProviderUserId item) {
    return MFAConfig(
      requiredItems: {...requiredItems, item},
      optionalCount: optionalCount,
      optionalItems: {...optionalItems}..remove(item),
    );
  }

  MFAConfig addOptional(ProviderUserId item) {
    return MFAConfig(
      optionalItems: {...optionalItems, item},
      optionalCount: optionalCount,
      requiredItems: {...requiredItems}..remove(item),
    );
  }

  MFAConfig removeItem(ProviderUserId item) {
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
