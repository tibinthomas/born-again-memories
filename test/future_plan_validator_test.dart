import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/utils/future_plan_validator.dart';

void main() {
  test('future plan title is required', () {
    expect(validateFuturePlanTitle('  '), 'Title is required');
    expect(validateFuturePlanTitle('College fund'), isNull);
  });

  test('target cannot be lower than the current amount', () {
    expect(
      validateFuturePlanTarget('500', '600'),
      'Target must be equal to or greater than current',
    );
    expect(validateFuturePlanTarget('600', '600'), isNull);
    expect(validateFuturePlanTarget('700', '600'), isNull);
  });

  test('amounts must be valid and non-negative', () {
    expect(
      validateFuturePlanAmount('invalid', label: 'current amount'),
      'Enter a valid current amount',
    );
    expect(
      validateFuturePlanAmount('-1', label: 'current amount'),
      'Current amount cannot be negative',
    );
  });
}
