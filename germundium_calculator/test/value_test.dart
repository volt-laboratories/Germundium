// Tests for lib/engine/value.dart (Phase 1, step 3: value types).
//
// Workflow: remove the `skip:` of a stage when you start working on it,
// then run `dart test` after every task.
//
// Assumed API (see Stage 2.md):
//   sealed class Value
//   sealed class NumberValue extends Value
//     double toDouble(); bool get isInteger; int? toIntOrNull();
//   final class ExactNumber extends NumberValue   (field: Rational value)
//     ExactNumber(Rational), ExactNumber.fromInt(int), ExactNumber.parse(String)
//   final class ApproxNumber extends NumberValue  (field: double value)
//   class MathError implements Exception          (field: String message)
//   Top-level functions: add, subtract, multiply, divide, power,
//                        negate, factorial
//
// If you decide on methods instead of top-level functions (task 8),
// adjust the calls below accordingly.

import 'package:germundium_calculator/engine/errors.dart';
import 'package:germundium_calculator/engine/value.dart';
import 'package:rational/rational.dart';
import 'package:test/test.dart';

////dart test test/value_test.dart

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Exact number n/d.
ExactNumber frac(int n, int d) => ExactNumber(Rational.fromInt(n, d));

/// Exact integer.
ExactNumber exact(int n) => ExactNumber.fromInt(n);

/// Matches an ApproxNumber whose value is close to [expected].
Matcher isApprox(double expected) => isA<ApproxNumber>().having(
  (n) => n.value,
  'value',
  closeTo(expected, 1e-12),
);

/// Matches a function call that throws a MathError.
final throwsMathError = throwsA(isA<MathError>());

void main() {
  // -------------------------------------------------------------------------
  group('Stage 1: types and equality', () {
    test('ExactNumber is a NumberValue and a Value', () {
      final n = exact(1);
      expect(n, isA<NumberValue>());
      expect(n, isA<Value>());
    });

    test('ApproxNumber is a NumberValue and a Value', () {
      final n = ApproxNumber(1.5);
      expect(n, isA<NumberValue>());
      expect(n, isA<Value>());
    });

    test('equal exact numbers are ==', () {
      expect(exact(3), equals(exact(3)));
    });

    test('different exact numbers are not ==', () {
      expect(exact(3), isNot(equals(exact(4))));
    });

    test('fractions are compared by value, not by notation', () {
      expect(frac(2, 4), equals(frac(1, 2)));
    });

    test('parse reads decimal strings exactly', () {
      expect(ExactNumber.parse('0.5'), equals(frac(1, 2)));
      expect(ExactNumber.parse('0.1'), equals(frac(1, 10)));
    });

    test('equal approx numbers are ==', () {
      expect(ApproxNumber(0.5), equals(ApproxNumber(0.5)));
    });

    test('exact and approx are never ==, even with the same value', () {
      expect(frac(1, 2), isNot(equals(ApproxNumber(0.5))));
    });

    test('equal values have equal hashCodes', () {
      expect(frac(2, 4).hashCode, equals(frac(1, 2).hashCode));
      expect(ApproxNumber(0.5).hashCode, equals(ApproxNumber(0.5).hashCode));
    });

    test('toString is overridden', () {
      expect(exact(3).toString(), isNot(contains('Instance of')));
      expect(ApproxNumber(3.0).toString(), isNot(contains('Instance of')));
    });
  });

  // -------------------------------------------------------------------------
  group('Stage 2: basic arithmetic', () {
    test('add exact', () {
      expect(add(exact(2), exact(3)), equals(exact(5)));
    });

    test('0.1 + 0.2 == 0.3 exactly', () {
      final result = add(ExactNumber.parse('0.1'), ExactNumber.parse('0.2'));
      expect(result, equals(ExactNumber.parse('0.3')));
    });

    test('subtract exact', () {
      expect(subtract(exact(2), exact(5)), equals(exact(-3)));
    });

    test('multiply exact', () {
      expect(multiply(frac(2, 3), frac(3, 4)), equals(frac(1, 2)));
    });

    test('divide exact stays exact', () {
      expect(divide(exact(1), exact(3)), equals(frac(1, 3)));
    });

    test('1/3 * 3 == 1 exactly', () {
      final third = divide(exact(1), exact(3));
      expect(multiply(third, exact(3)), equals(exact(1)));
    });

    test('negate exact', () {
      expect(negate(frac(1, 2)), equals(frac(-1, 2)));
    });

    test('negate approx', () {
      expect(negate(ApproxNumber(1.5)), isApprox(-1.5));
    });

    test('approx + approx is approx', () {
      expect(add(ApproxNumber(1.5), ApproxNumber(2.0)), isApprox(3.5));
    });

    test('exact + approx is approx', () {
      expect(add(exact(1), ApproxNumber(0.5)), isApprox(1.5));
    });

    test('approx + exact is approx (order does not matter)', () {
      expect(add(ApproxNumber(0.5), exact(1)), isApprox(1.5));
    });

    test('mixed multiply and divide are approx', () {
      expect(multiply(frac(1, 2), ApproxNumber(3.0)), isApprox(1.5));
      expect(divide(ApproxNumber(3.0), exact(2)), isApprox(1.5));
    });

    test('division by exact zero throws', () {
      expect(() => divide(exact(1), exact(0)), throwsMathError);
    });

    test('division by approx zero throws (no Infinity)', () {
      expect(
        () => divide(ApproxNumber(1.0), ApproxNumber(0.0)),
        throwsMathError,
      );
    });

    test('division by zero has an English message', () {
      expect(
        () => divide(exact(1), exact(0)),
        throwsA(
          isA<MathError>().having(
            (e) => e.message,
            'message',
            'Division by zero',
          ),
        ),
      );
    });
  }, skip: 'Remove when starting stage 2');

  // -------------------------------------------------------------------------
  group('Stage 3: power and factorial', () {
    group('power', () {
      test('integer exponent stays exact', () {
        expect(power(exact(2), exact(10)), equals(exact(1024)));
      });

      test('fraction base with integer exponent stays exact', () {
        expect(power(frac(2, 3), exact(2)), equals(frac(4, 9)));
      });

      test('large but allowed exponent stays exact (BigInt)', () {
        final expected = ExactNumber(Rational(BigInt.two.pow(100)));
        expect(power(exact(2), exact(100)), equals(expected));
      });

      test('negative integer exponent gives the reciprocal', () {
        expect(power(exact(2), exact(-2)), equals(frac(1, 4)));
      });

      test('0 to a negative power throws', () {
        expect(() => power(exact(0), exact(-1)), throwsMathError);
      });

      test('non-integer exponent gives approx', () {
        expect(
          power(exact(2), ExactNumber.parse('0.5')),
          isApprox(1.4142135623730951),
        );
      });

      test('approx base gives approx', () {
        expect(power(ApproxNumber(2.0), exact(3)), isApprox(8.0));
      });

      test('negative base with non-integer exponent throws (not real)', () {
        expect(
          () => power(exact(-8), ExactNumber.parse('0.5')),
          throwsMathError,
        );
      });

      test('absurdly large exponent throws instead of hanging', () {
        expect(() => power(exact(2), exact(10000000)), throwsMathError);
      });
    });

    group('factorial', () {
      test('5! == 120', () {
        expect(factorial(exact(5)), equals(exact(120)));
      });

      test('25! is exact (beyond int range)', () {
        final expected = ExactNumber(
          Rational(BigInt.parse('15511210043330985984000000')),
        );
        expect(factorial(exact(25)), equals(expected));
      });

      test('negative number throws', () {
        expect(() => factorial(exact(-1)), throwsMathError);
      });

      test('non-integer throws', () {
        expect(() => factorial(frac(5, 2)), throwsMathError);
      });

      test('absurdly large input throws instead of hanging', () {
        expect(() => factorial(exact(1000000)), throwsMathError);
      });
    });

    group('NaN and Infinity never escape', () {
      test('approx overflow in multiply throws', () {
        expect(
          () => multiply(ApproxNumber(1e308), ApproxNumber(10.0)),
          throwsMathError,
        );
      });

      test('approx overflow in power throws', () {
        expect(() => power(ApproxNumber(10.0), exact(400)), throwsMathError);
      });
    });
  }, skip: 'Remove when starting stage 3');

  // -------------------------------------------------------------------------
  group('Stage 4: helpers', () {
    test('toDouble', () {
      expect(frac(1, 4).toDouble(), equals(0.25));
      expect(ApproxNumber(0.25).toDouble(), equals(0.25));
    });

    test('isInteger on exact numbers', () {
      expect(frac(4, 2).isInteger, isTrue);
      expect(frac(1, 2).isInteger, isFalse);
    });

    test('isInteger on approx numbers', () {
      expect(ApproxNumber(2.5).isInteger, isFalse);
    });

    test('toIntOrNull', () {
      expect(exact(7).toIntOrNull(), equals(7));
      expect(frac(1, 2).toIntOrNull(), isNull);
    });
  }, skip: 'Remove when starting stage 4');

  // -------------------------------------------------------------------------
  group('Own tests (task 18)', () {
    // Ideas: 0^0, (-2)^3, 0!, ApproxNumber(2.0).isInteger,
    //        factorial(ApproxNumber(5.0)) – decide what SHOULD happen first!
  });
}
