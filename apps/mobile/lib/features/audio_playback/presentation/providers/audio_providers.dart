import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/core/di/injection.dart';
import 'package:vai_marcia/features/audio_playback/domain/entities/audio_clip.dart';
import 'package:vai_marcia/features/audio_playback/domain/repositories/audio_repository.dart';
import 'package:vai_marcia/features/audio_playback/domain/usecases/play_audio_usecase.dart';
import 'package:vai_marcia/features/audio_playback/domain/usecases/preload_category_usecase.dart';
import 'package:vai_marcia/features/audio_playback/presentation/providers/playback_controller.dart';

final Provider<AudioRepository> audioRepositoryProvider = Provider<AudioRepository>(
  (Ref ref) => getIt<AudioRepository>(),
);

final Provider<PlayAudioUseCase> playAudioUseCaseProvider = Provider<PlayAudioUseCase>(
  (Ref ref) => getIt<PlayAudioUseCase>(),
);

final Provider<PreloadCategoryUseCase> preloadCategoryUseCaseProvider = Provider<PreloadCategoryUseCase>(
  (Ref ref) => getIt<PreloadCategoryUseCase>(),
);

final StreamProviderFamily<List<AudioClip>, String> clipsByCategoryProvider =
    StreamProvider.family<List<AudioClip>, String>(
  (Ref ref, String categoryId) {
    return ref.watch(audioRepositoryProvider).watchClipsByCategory(categoryId);
  },
);

final NotifierProvider<PlaybackController, PlaybackState> playbackControllerProvider =
    NotifierProvider<PlaybackController, PlaybackState>(PlaybackController.new);
