/// Ponto de extensão para futuro processamento de áudio assistido por IA
/// (ARCHITECTURE.md §8 / docs/DEVICE_DETECTION.md são silenciosos sobre
/// isso por design — isso é uma preocupação puramente da feature
/// `recording`).
///
/// HOJE apenas [PassthroughStage] está conectado: um clipe gravado vai
/// direto do microfone para o armazenamento, sem modificação. A
/// interface já existe para que, quando o processamento por IA for
/// lançado, ele se conecte como [stages] adicionais sem tocar em
/// [RecordAudioUseCase], na UI de gravação, ou no caminho de código de
/// armazenamento/upload.
///
/// Estágios futuros documentados (não implementados):
/// - [NoiseReductionStage]: suprime ruído de vento/multidão em gravações
///   feitas à beira da quadra.
/// - [VoiceEnhancementStage]: normaliza volume/EQ para um volume de
///   reprodução consistente entre os clipes gravados pelo usuário.
/// - [PhraseSegmentationStage]: corta silêncio automaticamente e divide
///   uma única gravação em múltiplos clipes curtos.
/// - [AutoCategorizationStage]: sugere uma categoria (Motivação, Humor,
///   etc.) a partir do conteúdo transcrito/analisado.
abstract interface class AudioProcessingStage {
  String get name;

  /// Recebe o caminho de um arquivo de áudio bruto (ou já processado por
  /// um estágio anterior) e retorna o caminho de sua saída —
  /// implementações podem retornar o mesmo caminho sem alteração (como
  /// [PassthroughStage] faz).
  Future<String> process(String inputFilePath);
}

class AudioProcessingPipeline {
  const AudioProcessingPipeline(this.stages);

  final List<AudioProcessingStage> stages;

  Future<String> run(String inputFilePath) async {
    String current = inputFilePath;
    for (final AudioProcessingStage stage in stages) {
      current = await stage.process(current);
    }
    return current;
  }
}

/// O único estágio conectado hoje: o áudio passa sem modificação.
class PassthroughStage implements AudioProcessingStage {
  const PassthroughStage();

  @override
  String get name => 'passthrough';

  @override
  Future<String> process(String inputFilePath) async => inputFilePath;
}

/// NÃO IMPLEMENTADO — apenas um ponto de extensão documentado. Veja a
/// documentação da classe acima.
abstract interface class NoiseReductionStage implements AudioProcessingStage {}

/// NÃO IMPLEMENTADO — apenas um ponto de extensão documentado. Veja a
/// documentação da classe acima.
abstract interface class VoiceEnhancementStage implements AudioProcessingStage {}

/// NÃO IMPLEMENTADO — apenas um ponto de extensão documentado. Veja a
/// documentação da classe acima.
abstract interface class PhraseSegmentationStage implements AudioProcessingStage {}

/// NÃO IMPLEMENTADO — apenas um ponto de extensão documentado. Veja a
/// documentação da classe acima.
abstract interface class AutoCategorizationStage implements AudioProcessingStage {}
