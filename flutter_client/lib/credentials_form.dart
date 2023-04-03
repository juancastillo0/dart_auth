import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_client/base_widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:oauth/endpoint_models.dart';
import 'package:oauth/front_end_client.dart';
import 'package:oauth/oauth.dart';

class UpdateCredentialsParams {
  final AuthUserData data;
  final void Function() onUpdate;
  final void Function() onCancelFlow;

  ///
  UpdateCredentialsParams({
    required this.data,
    required this.onUpdate,
    required this.onCancelFlow,
  });
}

class CredentialsProviderForm extends HookWidget {
  final CredentialsProviderData data;
  final UpdateCredentialsParams? updateParams;

  ///
  const CredentialsProviderForm(
    this.data, {
    super.key,
    this.updateParams,
  });

  @override
  Widget build(BuildContext context) {
    final t = getTranslations(context);
    final globalState = globalStateOf(context);
    final state = globalState.authState;
    // TODO: extract state into a separate class
    final leftMfaItems = useValue(state.leftMfaItems);
    final isSignIn = useValue(state.isSignIn);
    final providerUserIdState = useState<String?>(null);
    final mfa = useMemoized(
      () =>
          leftMfaItems
              ?.where((e) => e.mfa.providerId == data.providerId)
              .toList() ??
          const [],
      [leftMfaItems, data.providerId],
    );
    final mfaItem = useMemoized(
      () => mfa.isEmpty
          ? null
          : mfa.length == 1
              ? mfa.first
              : mfa.firstWhere(
                  (e) => e.mfa.providerUserId == providerUserIdState.value,
                  orElse: () => mfa.first,
                ),
      [mfa, providerUserIdState.value],
    );
    final params = useState(<String, String>{});
    final visibility = useMemoized(() => <String>{});
    final errorMessage = useState<String?>(null);
    final fieldErrorMessage = useState<Map<String, String>?>(null);
    final credentials = useState<ResponseContinueFlow?>(null);
    final cred = useMemoized(
      () =>
          credentials.value ??
          updateParams?.data.updateParams ??
          mfaItem?.credentialsInfo,
      [credentials.value, mfaItem?.credentialsInfo],
    );
    final paramDescriptions = cred?.paramDescriptions ??
        (isSignIn ? data.paramDescriptionsSignIn : null) ??
        data.paramDescriptions;
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isLoading = useState(false);
    final isMounted = useIsMounted();
    Future<void> onSubmit() async {
      if (!formKey.currentState!.validate()) return;
      if (isLoading.value) return;
      isLoading.value = true;
      try {
        // TODO: handle required
        errorMessage.value = null;
        fieldErrorMessage.value = null;
        final AuthResponse? response;
        final reqParams = CredentialsParams(data.providerId, {
          if (cred != null) 'state': cred.state,
          // TODO: maybe use an opaque id?
          if (updateParams != null)
            'providerUserId': updateParams!.data.authUser.providerUserId
          else if (mfa.isNotEmpty)
            'providerUserId': mfaItem!.mfa.providerUserId,
          ...?(paramDescriptions
              ?.map((key, value) => MapEntry(key, value.initialValue)))
            ?..removeWhere(
              (key, value) => value == null || params.value.containsKey(key),
            ),
          ...params.value,
        });
        if (updateParams != null) {
          final user = await state.updateCredentials(reqParams);
          if (user == null) {
            // TODO: manage errors
            return;
          } else if (user.response != null) {
            response = user.response;
          } else {
            return updateParams!.onUpdate();
          }
          // TODO: properly handle isAddingMFAProvider vs singIn/signUp/duplicate user/same credentials
        } else if (isSignIn ||
            (mfa.isNotEmpty && !state.isAddingMFAProvider.value)) {
          response = await state.signInWithCredentials(reqParams);
        } else {
          response = await state.signUpWithCredentials(reqParams);
        }
        if (response == null || !isMounted()) return;
        final error = response.error;
        if (error != null) {
          final message = [error.error, ...?error.otherErrors]
              .map(globalState.translate)
              .where((text) => text.isNotEmpty)
              .join('\n');
          errorMessage.value = message.isEmpty ? null : message;

          if (error.fieldErrors != null) {
            fieldErrorMessage.value = error.fieldErrors!.map(
              (key, value) => MapEntry(key, globalState.translate(value)),
            );
          }
        }
        if (response.credentials != null) {
          credentials.value = response.credentials;
        }
      } finally {
        isLoading.value = false;
      }
    }

    final providerName = globalState.translate(data.providerName);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${updateParams == null ? '' : '${t.update} '}$providerName',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Form(
          key: formKey,
          child: Column(
            children: [
              if (mfa.length == 1)
                // TODO: maybe use an opaque id?
                Text(mfaItem!.mfa.providerUserId)
              else if (mfa.length > 1)
                DropdownButton<String>(
                  items: mfa.map(
                    (e) {
                      final providerUserId = e.mfa.providerUserId;
                      return DropdownMenuItem(
                        key: Key(providerUserId),
                        value: providerUserId,
                        child: Text(providerUserId),
                      );
                    },
                  ).toList(),
                  value: mfaItem!.mfa.providerUserId,
                  onChanged: (v) => providerUserIdState.value = v,
                ),
              const SizedBox(height: 10),
              ...?paramDescriptions?.entries.expand((e) sync* {
                final value = e.value;
                final regExp = value.regExp;

                yield StatefulBuilder(
                  key: Key('${e.key}StatefulBuilder'),
                  builder: (context, setState) => TextFormField(
                    key: Key(e.key),
                    decoration: InputDecoration(
                      labelText: globalState.translate(value.name),
                      helperText: value.description == null
                          ? null
                          : globalState.translate(value.description!),
                      hintText: value.hint,
                      errorText: fieldErrorMessage.value?[e.key],
                      errorMaxLines: 100,
                      helperMaxLines: 100,
                      suffixIcon: value.obscureText
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  if (visibility.contains(e.key)) {
                                    visibility.remove(e.key);
                                  } else {
                                    visibility.add(e.key);
                                  }
                                });
                              },
                              icon: visibility.contains(e.key)
                                  ? const Icon(Icons.visibility_off)
                                  : const Icon(Icons.visibility),
                            )
                          : null,
                    ),
                    keyboardType: getKeyboardType(value),
                    readOnly: value.readOnly,
                    initialValue: value.initialValue,
                    textCapitalization: TextCapitalization.values
                        .byName(value.textCapitalization.name),
                    obscureText:
                        !visibility.contains(e.key) && value.obscureText,
                    // TODO: validate on
                    validator: regExp == null
                        ? null
                        : (str) => regExp.hasMatch(str ?? '')
                            ? null
                            : globalState.translate(
                                value.description ?? Translation.empty,
                              ),
                    onChanged: (value) {
                      params.value[e.key] = value;
                      fieldErrorMessage.value = null;
                    },
                  ),
                );
                yield const SizedBox(height: 10);
              }),
            ],
          ),
        ),
        if (cred != null)
          Column(
            children: [
              if (cred.userMessage.key.isNotEmpty ||
                  cred.userMessage.msg != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(globalState.translate(cred.userMessage)),
                ),
              if (cred.qrUrl != null)
                BarcodeWidget(
                  barcode: Barcode.qrCode(
                    errorCorrectLevel: BarcodeQRCorrectionLevel.high,
                  ),
                  data: cred.qrUrl!,
                  width: 200,
                  height: 200,
                ),
            ],
          )
        else
          const SizedBox(),
        if (errorMessage.value != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              errorMessage.value!,
              style: const TextStyle(color: Colors.red),
            ),
          )
        else
          const SizedBox(),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (cred != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: () {
                    params.value = {};
                    credentials.value = null;
                    errorMessage.value = null;
                    fieldErrorMessage.value = null;
                    if (updateParams != null) {
                      updateParams!.onCancelFlow();
                    } else if (credentials.value == null &&
                        state.leftMfaItems.value != null) {
                      state.cancelCurrentFlow();
                    }
                  },
                  child: Text(t.cancel),
                ),
              ),
            ElevatedButton(
              onPressed: onSubmit,
              child: credentials.value?.buttonText != null
                  ? Text(globalState.translate(credentials.value!.buttonText!))
                  : Text(t.submit),
            ),
          ],
        ),
        Visibility(
          visible: isLoading.value,
          child: const Padding(
            padding: EdgeInsets.only(top: 4),
            child: LinearProgressIndicator(),
          ),
        ),
      ],
    );
  }
}

TextInputType? getKeyboardType(ParamDescription value) {
  return value.keyboardType == ParamKeyboardType.number
      ? TextInputType.numberWithOptions(
          decimal: value.numberKeyboardType?.decimal,
          signed: value.numberKeyboardType?.signed,
        )
      : const {
          ParamKeyboardType.text: TextInputType.text,
          ParamKeyboardType.multiline: TextInputType.multiline,
          ParamKeyboardType.number: TextInputType.number,
          ParamKeyboardType.phone: TextInputType.phone,
          ParamKeyboardType.datetime: TextInputType.datetime,
          ParamKeyboardType.emailAddress: TextInputType.emailAddress,
          ParamKeyboardType.url: TextInputType.url,
          ParamKeyboardType.visiblePassword: TextInputType.visiblePassword,
          ParamKeyboardType.name: TextInputType.name,
          ParamKeyboardType.streetAddress: TextInputType.streetAddress,
          ParamKeyboardType.none: TextInputType.none,
        }[value.keyboardType];
}
