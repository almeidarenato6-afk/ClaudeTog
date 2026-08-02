import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/core/constants/app_strings.dart';
import 'package:vai_marcia/core/extensions/context_extensions.dart';
import 'package:vai_marcia/features/store/presentation/providers/store_providers.dart';

class StorePage extends ConsumerWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.storeTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.storefront, size: 72, color: context.colors.primary),
              const SizedBox(height: 16),
              Text(
                AppStrings.storeBannerText,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final result = await ref.read(storeRepositoryProvider).openStore();
                  if (result.isErr && context.mounted) {
                    context.showSnack(AppStrings.storeOpenError);
                  }
                },
                child: const Text(AppStrings.storeOpenButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
