class PredictionResult {
  final String label;
  final double confidence;

  const PredictionResult({
    required this.label,
    required this.confidence,
  });

  @override
  String toString() => 'PredictionResult(label: $label, confidence: $confidence)';
}
