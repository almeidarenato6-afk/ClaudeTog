import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/features/categories/domain/entities/audio_category.dart';
import 'package:vai_marcia/features/categories/presentation/providers/category_providers.dart';

class CategoryChipList extends ConsumerWidget {
  const CategoryChipList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AudioCategory>> categoriesAsync = ref.watch(categoriesProvider);
    final String? selectedId = ref.watch(selectedCategoryIdProvider);

    return categoriesAsync.when(
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (Object error, StackTrace stackTrace) => const SizedBox.shrink(),
      data: (List<AudioCategory> categories) {
        return SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (BuildContext context, int index) {
              final AudioCategory category = categories[index];
              final bool isSelected = category.id == selectedId || (selectedId == null && index == 0);
              return ChoiceChip(
                label: Text(category.name),
                selected: isSelected,
                onSelected: (_) => ref.read(selectedCategoryIdProvider.notifier).state = category.id,
              );
            },
          ),
        );
      },
    );
  }
}
