String? validateGrowthMeasurement(
  String? raw, {
  required String label,
  required double min,
  required double max,
}) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return null;

  final value = double.tryParse(text);
  if (value == null || !value.isFinite) return 'Enter a valid number';
  if (value <= 0) return '$label must be above zero';
  if (value < min || value > max) {
    return '$label must be ${_format(min)}–${_format(max)}';
  }
  return null;
}

String _format(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}
