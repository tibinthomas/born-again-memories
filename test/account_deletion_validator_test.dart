import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/utils/account_deletion_validator.dart';

void main() {
  test('accepts only the exact account deletion confirmation text', () {
    expect(isAccountDeletionConfirmationValid('delete'), isTrue);

    expect(isAccountDeletionConfirmationValid('Delete'), isFalse);
    expect(isAccountDeletionConfirmationValid('DELETE'), isFalse);
    expect(isAccountDeletionConfirmationValid(' delete'), isFalse);
    expect(isAccountDeletionConfirmationValid('delete '), isFalse);
    expect(isAccountDeletionConfirmationValid('deleted'), isFalse);
    expect(isAccountDeletionConfirmationValid(''), isFalse);
  });
}
