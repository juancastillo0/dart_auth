import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:oauth/endpoint_models.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'credentials_form.dart';
import 'main.dart';

class OAuthProviderSignInButton extends StatelessWidget {
  final OAuthProviderData data;

  const OAuthProviderSignInButton(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(data.providerId),
            Text(data.defaultScopes.toString()),
          ],
        ),
        if (data.deviceCodeFlowSupported)
          ElevatedButton(
            onPressed: () async {
              final authState = GlobalState.of(context).authState;
              await authState.getProviderDeviceCode(data.providerId);
            },
            child: const Text('Sign Up with Device'),
          ),
        ElevatedButton(
          onPressed: () async {
            final authState = GlobalState.of(context).authState;
            final url = await authState.getProviderUrl(data.providerId);
            if (url != null) {
              // TODO:
              final success = await launchUrlString(url);
            }
          },
          child: const Text('Sign Up'),
        ),
      ],
    );
  }
}

class OAuthFlowWidget extends StatelessWidget {
  const OAuthFlowWidget({super.key, required this.currentFlow});

  final OAuthProviderFlowData? currentFlow;

  @override
  Widget build(BuildContext context) {
    final currentFlow = this.currentFlow;
    final state = GlobalState.of(context).authState;
    if (currentFlow is OAuthProviderUrl) {
      return Card(
        child: Column(
          children: [
            InkWell(
              onTap: () {
                launchUrlString(currentFlow.url);
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SelectableText(
                  currentFlow.url,
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: state.cancelCurrentFlow,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel'),
            ),
          ],
        ),
      );
    } else if (currentFlow is OAuthProviderDevice) {
      return Card(
        child: Column(
          children: [
            InkWell(
              onTap: () {
                launchUrlString(
                  currentFlow.device.verificationUriComplete ??
                      currentFlow.device.verificationUri,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SelectableText(
                  currentFlow.device.verificationUri,
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            BarcodeWidget(
              barcode: Barcode.qrCode(
                errorCorrectLevel: BarcodeQRCorrectionLevel.high,
              ),
              data: currentFlow.device.verificationUriComplete ??
                  currentFlow.device.verificationUri,
              width: 200,
              height: 200,
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(currentFlow.device.userCode),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                currentFlow.device.message ??
                    'Enter the code in the url to authorize this device.',
              ),
            ),
            ElevatedButton.icon(
              onPressed: state.cancelCurrentFlow,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel'),
            ),
          ],
        ),
      );
    }
    return const AuthProvidersList();
  }
}

class AuthProvidersList extends HookWidget {
  const AuthProvidersList({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GlobalState.of(context).authState;
    final data = useValueListenable(state.providersList);

    if (data == null) return const CircularProgressIndicator();

    return Expanded(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ...data.credentialsProviders.map(CredentialsProviderForm.new).map(
                    (w) => Card(
                      key: Key(w.data.providerId),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 22,
                        ),
                        child: w,
                      ),
                    ),
                  ),
              ...data.providers.map(OAuthProviderSignInButton.new).map(
                    (w) => Card(
                      key: Key(w.data.providerId),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 22,
                        ),
                        child: w,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
