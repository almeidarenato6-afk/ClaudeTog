import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vai_marcia/core/constants/app_constants.dart';
import 'package:vai_marcia/core/constants/app_strings.dart';
import 'package:vai_marcia/core/router/app_router.dart';
import 'package:vai_marcia/features/audio_playback/presentation/widgets/big_button_grid.dart';
import 'package:vai_marcia/features/categories/domain/entities/audio_category.dart';
import 'package:vai_marcia/features/categories/presentation/providers/category_providers.dart';
import 'package:vai_marcia/features/categories/presentation/widgets/category_chip_list.dart';
import 'package:vai_marcia/features/favorites/presentation/widgets/favorites_list.dart';
import 'package:vai_marcia/features/store/presentation/widgets/store_banner.dart';
import 'package:vai_marcia/features/watch_companion/presentation/providers/watch_companion_providers.dart';

/// Top-level scaffold: category chips + big button grid on the Home tab,
/// Favorites on the second tab, bottom nav, persistent store banner, plus
/// the always-on watch-command relay subscription (Cenário B).
class HomeShellPage extends ConsumerStatefulWidget {
  const HomeShellPage({super.key});

  @override
  ConsumerState<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends ConsumerState<HomeShellPage> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowSetupWizard());
  }

  Future<void> _maybeShowSetupWizard() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool onboardingComplete = prefs.getBool(AppConstants.prefsKeyOnboardingComplete) ?? false;
    if (!onboardingComplete && mounted) {
      await context.push(AppRoutes.setupWizard);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(watchCommandRelayProvider);

    final String? selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final List<AudioCategory> categories = ref.watch(categoriesProvider).valueOrNull ?? const <AudioCategory>[];
    final String effectiveCategoryId =
        selectedCategoryId ?? (categories.isNotEmpty ? categories.first.id : 'motivacao');

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.homeTitle),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () => context.push(AppRoutes.recording),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (_tabIndex == 0) ...<Widget>[
            const SizedBox(height: 8),
            const CategoryChipList(),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: _tabIndex == 0 ? BigButtonGrid(categoryId: effectiveCategoryId) : const FavoritesList(),
          ),
          const StoreBanner(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (int index) => setState(() => _tabIndex = index),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: AppStrings.categoriesTitle),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: AppStrings.favoritesTitle),
        ],
      ),
    );
  }
}
