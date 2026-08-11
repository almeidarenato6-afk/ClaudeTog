/// Veja docs/DEVICE_DETECTION.md — decidida uma vez por mudança de
/// pareamento, nunca recalculada de forma síncrona no caminho crítico de
/// toque-para-reproduzir.
enum PlaybackStrategy {
  /// Cenário A: o relógio reproduz localmente direto na caixa de som
  /// Bluetooth.
  direct,

  /// Cenário B: o relógio envia um audioId leve para o celular, que
  /// reproduz o clipe já em cache na caixa de som Bluetooth.
  relay,

  /// Nenhum relógio compatível pareado; o celular dispara tudo.
  phoneOnly,
}

extension PlaybackStrategyX on PlaybackStrategy {
  bool get involvesWatch => this != PlaybackStrategy.phoneOnly;
}
