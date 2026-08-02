import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vai_marcia/core/constants/app_constants.dart';
import 'package:vai_marcia/core/constants/app_strings.dart';
import 'package:vai_marcia/core/extensions/context_extensions.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/playback_strategy.dart';
import 'package:vai_marcia/features/device_pairing/domain/usecases/run_capability_probe_usecase.dart';
import 'package:vai_marcia/features/device_pairing/presentation/providers/device_pairing_providers.dart';

/// First-run "Vamos configurar seu equipamento" wizard, per
/// docs/DEVICE_DETECTION.md. Every step is detection-driven — the only
/// user action is "open Bluetooth settings" or "install the watch app"
/// when detection can't complete on its own.
class SetupWizardPage extends ConsumerStatefulWidget {
  const SetupWizardPage({super.key});

  @override
  ConsumerState<SetupWizardPage> createState() => _SetupWizardPageState();
}

class _SetupWizardPageState extends ConsumerState<SetupWizardPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(capabilityProbeControllerProvider.notifier).runProbe());
  }

  Future<void> _finish() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefsKeyOnboardingComplete, true);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<CapabilityProbeOutcome?> probeState = ref.watch(capabilityProbeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.setupWizardTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(AppStrings.setupWizardIntro, style: context.textStyles.bodyLarge),
              const SizedBox(height: 32),
              Expanded(
                child: probeState.when(
                  loading: () => const _ProbingList(),
                  error: (Object error, StackTrace stackTrace) => _ErrorState(
                    onRetry: () => ref.read(capabilityProbeControllerProvider.notifier).runProbe(),
                  ),
                  data: (CapabilityProbeOutcome? outcome) => outcome == null
                      ? const _ProbingList()
                      : _SummaryView(outcome: outcome),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: probeState.hasValue && probeState.value != null ? _finish : null,
                  child: const Text(AppStrings.setupFinishButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProbingList extends StatelessWidget {
  const _ProbingList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ProbeStep(label: AppStrings.setupDetectingWatch),
        SizedBox(height: 16),
        _ProbeStep(label: AppStrings.setupProbingCapabilities),
        SizedBox(height: 16),
        _ProbeStep(label: AppStrings.setupDetectingSpeaker),
      ],
    );
  }
}

class _ProbeStep extends StatelessWidget {
  const _ProbeStep({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(label)),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(AppStrings.genericError),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
        ],
      ),
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.outcome});

  final CapabilityProbeOutcome outcome;

  String get _summaryText {
    final String watchModel = outcome.watchProfile?.model ?? '';
    final String speakerName = outcome.pairedSpeakers.isNotEmpty ? outcome.pairedSpeakers.first.name : '';

    switch (outcome.strategy) {
      case PlaybackStrategy.direct:
        return AppStrings.setupSummaryDirect
            .replaceAll('%watch%', watchModel)
            .replaceAll('%speaker%', speakerName);
      case PlaybackStrategy.relay:
        return AppStrings.setupSummaryRelay
            .replaceAll('%watch%', watchModel)
            .replaceAll('%speaker%', speakerName);
      case PlaybackStrategy.phoneOnly:
        return AppStrings.setupSummaryPhoneOnly;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.check_circle, color: context.colors.primary, size: 48),
        const SizedBox(height: 16),
        Text(_summaryText, style: context.textStyles.titleMedium),
        const SizedBox(height: 24),
        if (outcome.pairedSpeakers.isEmpty) ...<Widget>[
          const Text(AppStrings.bluetoothNotConnected),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {},
            child: const Text(AppStrings.setupOpenBluetoothSettings),
          ),
        ],
      ],
    );
  }
}
