import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:oauth/endpoint_models.dart';
import 'package:oauth/providers.dart';

import 'auth_client.dart';
import 'main.dart';

class CredentialsProviderForm extends HookWidget {
  final CredentialsProviderData data;

  const CredentialsProviderForm(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    final params = useState(<String, String>{});
    final errorMessage = useState<String?>(null);
    final fieldErrorMessage = useState<Map<String, String>?>(null);
    final credentials = useState<CredentialsResponse<Object?>?>(null);
    final cred = credentials.value;
    final paramDescriptions = cred?.paramDescriptions ?? data.paramDescriptions;

    return Column(
      children: [
        Text(data.providerId),
        Form(
          child: Column(
            children: [
              ...paramDescriptions.entries.map((e) {
                final value = e.value;
                final regExp = value.regExp;

                return TextFormField(
                  key: Key(e.key),
                  decoration: InputDecoration(
                    label: Text(value.name),
                    helperText: value.description,
                    errorText: fieldErrorMessage.value?[e.key],
                  ),
                  validator: regExp == null
                      ? null
                      : (value) => regExp.hasMatch(value ?? '') ? null : '',
                  onChanged: (value) => params.value[e.key] = value,
                );
              }),
            ],
          ),
        ),
        if (cred != null)
          Column(
            children: [
              if (cred.userMessage != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(cred.userMessage!),
                ),
              TextButton(
                onPressed: () {
                  credentials.value = null;
                },
                child: const Text('Cancel Flow'),
              )
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
        ElevatedButton(
          onPressed: () async {
            errorMessage.value = null;
            fieldErrorMessage.value = null;
            final authState = GlobalState.of(context).authState;
            final response = await authState.signUpWithCredentials(
              CredentialsParams(data.providerId, {
                if (cred != null) 'state': cred.state,
                ...params.value,
              }),
            );
            if (response == null) return;
            if (response.error != null) {
              final message =
                  response.message == null || response.message!.isEmpty
                      ? response.error
                      : '${response.error}: ${response.message}';
              errorMessage.value = message;
            }
            if (response.fieldErrors != null) {
              fieldErrorMessage.value = response.fieldErrors;
            }
            if (response.credentials != null) {
              credentials.value = response.credentials;
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
