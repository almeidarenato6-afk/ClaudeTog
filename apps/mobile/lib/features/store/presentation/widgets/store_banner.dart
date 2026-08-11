import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/core/constants/app_strings.dart';
import 'package:vai_marcia/core/extensions/context_extensions.dart';
import 'package:vai_marcia/core/theme/app_colors.dart';
import 'package:vai_marcia/features/store/presentation/providers/store_providers.dart';

/// Persistente, mas discreto: um banner fino de uma única linha, nunca
/// um modal ou interstitial, para que nunca fique entre o usuário e os
/// botões grandes.
class StoreBanner extends ConsumerWidget {
  const StoreBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.sandBeige,
      child: InkWell(
        onTap: () => ref.read(storeRepositoryProvider).openStore(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: <Widget>[
              const Icon(Icons.storefront, size: 18, color: AppColors.navySecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.storeBannerText,
                  style: context.textStyles.bodyLarge?.copyWith(
                    color: AppColors.navySecondary,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.navySecondary),
            ],
          ),
        ),
      ),
    );
  }
}
