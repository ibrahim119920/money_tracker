/// The largest amount accepted by a PostgreSQL BIGINT column.
const int maxMoneyAmount = 9223372036854775807;

/// Appends one decimal digit without allowing an int or BIGINT overflow.
///
/// A leading zero is normalized by treating zero as the empty input state, so
/// `000` remains `0` and `007` becomes `7`.
int appendMoneyDigit(int current, int digit) {
  if (digit < 0 || digit > 9) {
    throw ArgumentError.value(digit, 'digit', 'Must be between 0 and 9');
  }

  if (current == 0) return digit;
  if (current > (maxMoneyAmount - digit) ~/ 10) return current;
  return current * 10 + digit;
}

/// Removes one decimal digit, returning zero for a one-digit amount.
int removeMoneyDigit(int current) {
  if (current <= 0) return 0;
  return current < 10 ? 0 : current ~/ 10;
}
