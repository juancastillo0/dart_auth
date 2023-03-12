import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:oauth/endpoint_models.dart';
import 'package:oauth/oauth.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'credentials_form.dart';
import 'main.dart';

class OAuthProviderSignInButton extends StatelessWidget {
  final OAuthProviderData data;

  const OAuthProviderSignInButton(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        Theme.of(context).colorScheme.brightness == Brightness.dark;

    final ButtonStyle buttonStyle;
    final String logo;
    final oauthStyles = data.buttonStyles;
    if (isDarkMode) {
      logo = oauthStyles.logoDark;
      buttonStyle = ElevatedButton.styleFrom(
        backgroundColor:
            Color(OAuthButtonStyles.parseHexColor(oauthStyles.bgDark)),
        foregroundColor:
            Color(OAuthButtonStyles.parseHexColor(oauthStyles.textDark)),
      );
    } else {
      logo = oauthStyles.logo;
      buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: Color(OAuthButtonStyles.parseHexColor(oauthStyles.bg)),
        foregroundColor:
            Color(OAuthButtonStyles.parseHexColor(oauthStyles.text)),
      );
    }

    final Widget image;
    // TODO: extract logic and support 'data:' uris
    if (logo.endsWith('.svg')) {
      image = SvgPicture.network(logo, width: 20);
    } else {
      image = Image.network(logo, width: 20);
    }

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
            style: buttonStyle,
            onPressed: () async {
              final authState = GlobalState.of(context).authState;
              await authState.getProviderDeviceCode(data.providerId);
            },
            child: Row(
              children: [
                image,
                const Text('Sign Up with Device'),
              ],
            ),
          ),
        ElevatedButton(
          style: buttonStyle,
          onPressed: () async {
            final authState = GlobalState.of(context).authState;
            final url = await authState.getProviderUrl(data.providerId);
            if (url != null) {
              // TODO:
              final success = await launchUrlString(url);
            }
          },
          child: Row(
            children: [
              image,
              const Text('Sign Up'),
            ],
          ),
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
    final leftMfaItems = useValueListenable(state.leftMfaItems);
    final isAddingMFAProvider = useValueListenable(state.isAddingMFAProvider);

    if (data == null) return const CircularProgressIndicator();

    bool inMFA(AuthProviderData s) {
      return leftMfaItems == null ||
          leftMfaItems.any((e) => e.mfa.providerId == s.providerId);
    }

    Widget list = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...data.credentialsProviders
              .where(inMFA)
              .map(CredentialsProviderForm.new)
              .map(
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
          ...data.providers.where(inMFA).map(OAuthProviderSignInButton.new).map(
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
    );
    if (leftMfaItems != null || isAddingMFAProvider) {
      list = Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // TODO: Leave it for both flows?
                if (isAddingMFAProvider)
                  BackButton(
                    onPressed: state.cancelCurrentFlow,
                  ),
                Expanded(
                  child: Text(
                    '${isAddingMFAProvider ? 'Add ' : ''}'
                    'Multi-Factor Authentication (MFA)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: list,
          ),
        ],
      );
    }

    return Expanded(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: list,
      ),
    );
  }
}
