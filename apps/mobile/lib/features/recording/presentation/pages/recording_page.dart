import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/core/constants/app_strings.dart';
import 'package:vai_marcia/core/extensions/context_extensions.dart';
import 'package:vai_marcia/features/categories/domain/entities/audio_category.dart';
import 'package:vai_marcia/features/recording/domain/entities/recording_session.dart';
import 'package:vai_marcia/features/recording/presentation/providers/recording_providers.dart';

class RecordingPage extends ConsumerStatefulWidget {
  const RecordingPage({super.key});

  @override
  ConsumerState<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends ConsumerState<RecordingPage> {
  final TextEditingController _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RecordingSession session = ref.watch(recordingControllerProvider);
    final RecordingController controller = ref.read(recordingControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.recordingTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  if (session.status == RecordingStatus.recording) {
                    controller.stopRecording();
                  } else {
                    controller.startRecording();
                  }
                },
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: session.status == RecordingStatus.recording
                      ? context.colors.error
                      : context.colors.primary,
                  child: Icon(
                    session.status == RecordingStatus.recording ? Icons.stop : Icons.mic,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                session.status == RecordingStatus.recording
                    ? AppStrings.recordingStop
                    : AppStrings.recordingStart,
              ),
              if (session.status == RecordingStatus.stopped) ...<Widget>[
                const SizedBox(height: 32),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.recordingNamePrompt,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.reset,
                        child: const Text(AppStrings.recordingDiscard),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final bool saved = await controller.saveRecording(
                            title: _titleController.text.trim().isEmpty
                                ? 'Áudio personalizado'
                                : _titleController.text.trim(),
                            categoryId: DefaultCategories.seed.last.id,
                          );
                          if (saved && context.mounted) {
                            context.showSnack('Áudio salvo!');
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text(AppStrings.recordingSave),
                      ),
                    ),
                  ],
                ),
              ],
              if (session.status == RecordingStatus.processing) ...<Widget>[
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
