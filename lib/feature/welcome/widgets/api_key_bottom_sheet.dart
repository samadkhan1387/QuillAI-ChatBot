import 'package:quill_ai/core/config/assets_constants.dart'; // Ensure this import is correct
import 'package:quill_ai/core/extension/context.dart';
import 'package:quill_ai/core/navigation/route.dart';
import 'package:quill_ai/core/util/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class APIKeyBottomSheet extends StatefulWidget {
  const APIKeyBottomSheet({
    required this.apiKeyController,
    required this.isCalledFromHomePage,
    super.key,
  });

  final TextEditingController apiKeyController;
  final bool isCalledFromHomePage;

  @override
  State<APIKeyBottomSheet> createState() => _APIKeyBottomSheetState();
}

class _APIKeyBottomSheetState extends State<APIKeyBottomSheet> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 50,
                decoration: BoxDecoration(
                  color: context.colorScheme.onSurface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.only(bottom: 8),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  const apiKey = AssetConstants.hardcodedApiKey; // Use the hardcoded API key
                  context.closeKeyboard();

                  setState(() {
                    _isLoading = true;
                  });
                  await SecureStorage().storeApiKey(apiKey);
                  setState(() {
                    _isLoading = false;
                  });

                  if (widget.isCalledFromHomePage) {
                    context.pop(); // Go back if called from home page
                  } else {
                    AppRoute.home.go(context); // Navigate to home page if not called from there
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colorScheme.onSurface,
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(
                  color: context.colorScheme.surface,
                )
                    : Text(
                  'Continue',
                  style: context.textTheme.labelLarge!.copyWith(
                    color: context.colorScheme.surface,
                  ),
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
