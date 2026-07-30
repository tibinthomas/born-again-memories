String? validateFuturePlanTitle(String? value) {
  if ((value ?? '').trim().isEmpty) return 'Title is required';
  return null;
}

String? validateFuturePlanAmount(String? value, {required String label}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final amount = double.tryParse(text);
  if (amount == null || !amount.isFinite) return 'Enter a valid $label';
  if (amount < 0) {
    final displayLabel = '${label[0].toUpperCase()}${label.substring(1)}';
    return '$displayLabel cannot be negative';
  }
  return null;
}

String? validateFuturePlanTarget(String? targetValue, String? currentValue) {
  final basicError = validateFuturePlanAmount(
    targetValue,
    label: 'target amount',
  );
  if (basicError != null) return basicError;

  final targetText = targetValue?.trim() ?? '';
  final currentText = currentValue?.trim() ?? '';
  if (targetText.isEmpty || currentText.isEmpty) return null;

  final target = double.tryParse(targetText);
  final current = double.tryParse(currentText);
  if (target != null && current != null && target < current) {
    return 'Target must be equal to or greater than current';
  }
  return null;
}
