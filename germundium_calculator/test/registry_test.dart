// Tests for stage 4: function registry.
//
// TODO: adjust the package name below if your pubspec uses a different one.
// The helper `throwsCalcErrorMentioning` reads `CalcError.message`; if your
// field is named differently, change it there (one place only).
//
// Remove the `skip:` of a group when you start that stage.

import 'dart:math' as math;

import 'package:germundium_calculator/engine/builtins.dart';
import 'package:germundium_calculator/engine/engine.dart';
import 'package:germundium_calculator/engine/registry.dart';
import 'package:rational/rational.dart';
import 'package:test/test.dart';

////dart test test/registry_test.dart

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ExactNumber ex(int n) => ExactNumber.fromInt(n);

ExactNumber frac(int n, int d) =>
    ExactNumber(Rational(BigInt.from(n), BigInt.from(d)));

ApproxNumber ap(double x) => ApproxNumber(x);

const rad = EvalContext();
const deg = EvalContext(angleMode: AngleMode.degrees);

/// Checks the numeric value without caring whether it is exact or approximate.
void expectNumber(Value actual, double expected, {double tolerance = 1e-12}) {
  expect(actual, isA<NumberValue>());
  expect((actual as NumberValue).toDouble(), closeTo(expected, tolerance));
}

/// Any CalcError subclass whose message contains [text].
/// Which subclass you use for "unknown name" / "wrong argument count"
/// is your decision (task 13).
Matcher throwsCalcErrorMentioning(String text) => throwsA(
  isA<CalcError>().having((e) => e.message, 'message', contains(text)),
);

final Matcher throwsMathError = throwsA(isA<MathError>());

void main() {
  // -------------------------------------------------------------------------
  group('Stage 1: Arity and entries', () {
    test('exactly(1) accepts only one argument', () {
      const arity = Arity.exactly(1);
      expect(arity.accepts(1), isTrue);
      expect(arity.accepts(0), isFalse);
      expect(arity.accepts(2), isFalse);
    });

    test('exactly(0) accepts no arguments (e.g. a future rand())', () {
      const arity = Arity.exactly(0);
      expect(arity.accepts(0), isTrue);
      expect(arity.accepts(1), isFalse);
    });

    test('range(1, 2) accepts one or two arguments', () {
      const arity = Arity.range(1, 2);
      expect(arity.accepts(0), isFalse);
      expect(arity.accepts(1), isTrue);
      expect(arity.accepts(2), isTrue);
      expect(arity.accepts(3), isFalse);
    });

    test('atLeast(1) has no upper limit', () {
      const arity = Arity.atLeast(1);
      expect(arity.accepts(0), isFalse);
      expect(arity.accepts(1), isTrue);
      expect(arity.accepts(1000), isTrue);
    });

    test('toString describes the arity for error messages', () {
      expect(const Arity.exactly(1).toString(), '1');
      expect(const Arity.range(1, 2).toString(), '1 to 2');
      expect(const Arity.atLeast(1).toString(), 'at least 1');
    });

    test('range(2, 2) reads like exactly(2)', () {
      expect(const Arity.range(2, 2).toString(), '2');
    });

    test('ConstantEntry always has the category constant', () {
      final pi = ConstantEntry(name: 'pi', symbol: 'π', value: ap(math.pi));
      expect(pi.category, FunctionCategory.constant);
    });

    test('default context uses radians', () {
      expect(const EvalContext().angleMode, AngleMode.radians);
    });
  });

  // -------------------------------------------------------------------------
  group('Stage 2: FunctionRegistry', () {
    // Fake entries: these tests check the registry mechanics,
    // independent of any real math function.
    var calls = 0;
    EvalContext? seenContext;

    final twice = FunctionEntry(
      name: 'twice',
      symbol: '2×',
      category: FunctionCategory.basic,
      arity: const Arity.exactly(1),
      evaluate: (args, context) {
        calls++;
        seenContext = context;
        return multiply(args[0], ex(2));
      },
    );

    final sum = FunctionEntry(
      name: 'sum',
      symbol: 'Σ',
      category: FunctionCategory.basic,
      arity: const Arity.atLeast(1),
      evaluate: (args, _) => args.reduce(add),
    );

    final answer = ConstantEntry(name: 'answer', symbol: '42', value: ex(42));

    late FunctionRegistry registry;

    setUp(() {
      calls = 0;
      seenContext = null;
      registry = FunctionRegistry([twice, sum, answer]);
    });

    test('lookup finds an entry by name', () {
      expect(registry.lookup('twice'), same(twice));
      expect(registry.lookup('answer'), same(answer));
    });

    test('lookup returns null for unknown names', () {
      expect(registry.lookup('nope'), isNull);
    });

    test('lookup is case-sensitive', () {
      expect(registry.lookup('Twice'), isNull);
    });

    test('entries contains everything in registration order', () {
      expect(registry.entries, orderedEquals([twice, sum, answer]));
    });

    test('inCategory filters by category', () {
      expect(registry.inCategory(FunctionCategory.constant), [answer]);
      expect(registry.inCategory(FunctionCategory.basic), [twice, sum]);
      expect(registry.inCategory(FunctionCategory.trigonometry), isEmpty);
    });

    test('duplicate names are a programmer error, not a CalcError', () {
      expect(() => FunctionRegistry([twice, twice]), throwsArgumentError);
    });

    test('invoke calls the implementation', () {
      expect(registry.invoke('twice', [ex(21)], rad), ex(42));
      expect(calls, 1);
    });

    test('invoke passes the context through unchanged', () {
      registry.invoke('twice', [ex(1)], deg);
      expect(seenContext, same(deg));
    });

    test('invoke supports variadic functions', () {
      expect(registry.invoke('sum', [ex(1), ex(2), ex(3)], rad), ex(6));
    });

    test(
      'wrong argument count throws and never reaches the implementation',
      () {
        expect(
          () => registry.invoke('twice', [ex(1), ex(2)], rad),
          throwsCalcErrorMentioning('twice'),
        );
        expect(
          () => registry.invoke('twice', [], rad),
          throwsCalcErrorMentioning('twice'),
        );
        expect(calls, 0);
      },
    );

    test('atLeast(1) rejects zero arguments', () {
      expect(
        () => registry.invoke('sum', [], rad),
        throwsCalcErrorMentioning('sum'),
      );
    });

    test('unknown function throws a CalcError naming it', () {
      expect(
        () => registry.invoke('nope', [ex(1)], rad),
        throwsCalcErrorMentioning('nope'),
      );
    });

    test('a constant cannot be called like a function', () {
      expect(
        () => registry.invoke('answer', [], rad),
        throwsCalcErrorMentioning('answer'),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('Stage 3: constants, sqrt, abs, ln, log', () {
    late FunctionRegistry reg;
    setUp(() => reg = standardRegistry());

    Value call(String name, List<Value> args) => reg.invoke(name, args, rad);

    test('all stage 3 names are registered', () {
      for (final name in ['pi', 'e', 'sqrt', 'abs', 'ln', 'log']) {
        expect(reg.lookup(name), isNotNull, reason: name);
      }
    });

    test('every entry has a non-empty symbol', () {
      for (final entry in reg.entries) {
        expect(entry.symbol, isNotEmpty, reason: entry.name);
      }
    });

    test('pi and e are constants with approximate values', () {
      final pi = reg.lookup('pi');
      final e = reg.lookup('e');
      expect(pi, isA<ConstantEntry>());
      expect(e, isA<ConstantEntry>());
      expectNumber((pi as ConstantEntry).value, math.pi);
      expectNumber((e as ConstantEntry).value, math.e);
      expect(pi.symbol, 'π');
    });

    test('categories are set', () {
      expect(reg.lookup('sqrt')!.category, FunctionCategory.basic);
      expect(reg.lookup('abs')!.category, FunctionCategory.basic);
      expect(reg.lookup('ln')!.category, FunctionCategory.logarithm);
      expect(reg.lookup('log')!.category, FunctionCategory.logarithm);
    });

    // --- abs ---
    test('abs keeps exact values exact', () {
      expect(call('abs', [ex(-3)]), ex(3));
      expect(call('abs', [frac(-1, 2)]), frac(1, 2));
      expect(call('abs', [ex(0)]), ex(0));
    });

    test('abs of an approximate value stays approximate', () {
      expect(call('abs', [ap(-2.5)]), ap(2.5));
    });

    // --- sqrt ---
    test('sqrt of a perfect square is exact', () {
      expect(call('sqrt', [ex(4)]), ex(2));
      expect(call('sqrt', [ex(0)]), ex(0));
      expect(call('sqrt', [frac(9, 4)]), frac(3, 2));
    });

    test('sqrt of a non-square is approximate', () {
      final result = call('sqrt', [ex(2)]);
      expect(result, isA<ApproxNumber>());
      expectNumber(result, math.sqrt2);
    });

    test('sqrt of an approximate value is approximate', () {
      expect(call('sqrt', [ap(2.25)]), ap(1.5));
    });

    test('sqrt of a negative number is a MathError', () {
      expect(() => call('sqrt', [ex(-1)]), throwsMathError);
      expect(() => call('sqrt', [ap(-4.0)]), throwsMathError);
    });

    test('sqrt with two arguments is rejected by the registry', () {
      expect(
        () => call('sqrt', [ex(4), ex(9)]),
        throwsCalcErrorMentioning('sqrt'),
      );
    });

    // --- ln ---
    test('ln basics', () {
      expectNumber(call('ln', [ex(1)]), 0);
      expectNumber(call('ln', [ap(math.e)]), 1);
    });

    test('ln outside its domain is a MathError', () {
      expect(() => call('ln', [ex(0)]), throwsMathError);
      expect(() => call('ln', [ex(-1)]), throwsMathError);
    });

    // --- log ---
    test('log with one argument uses base 10', () {
      expectNumber(call('log', [ex(100)]), 2);
      expectNumber(call('log', [frac(1, 10)]), -1);
    });

    // Convention used here: log(x, base). If you choose log(base, x)
    // in task 20, swap the arguments in the next two tests.
    test('log with two arguments uses the second as base', () {
      expectNumber(call('log', [ex(8), ex(2)]), 3);
      expectNumber(call('log', [ex(81), ex(3)]), 4);
    });

    test('log with an invalid base is a MathError', () {
      expect(() => call('log', [ex(8), ex(1)]), throwsMathError);
      expect(() => call('log', [ex(8), ex(0)]), throwsMathError);
      expect(() => call('log', [ex(8), ex(-2)]), throwsMathError);
    });

    test('log outside its domain is a MathError', () {
      expect(() => call('log', [ex(0)]), throwsMathError);
    });

    test('log accepts only 1 or 2 arguments', () {
      expect(() => call('log', []), throwsCalcErrorMentioning('log'));
      expect(
        () => call('log', [ex(1), ex(2), ex(3)]),
        throwsCalcErrorMentioning('log'),
      );
    });
  });

  group('Stage 3: results outside the double range', () {
    final registry = standardRegistry();
    final context = EvalContext();

    // 2^1100 is far beyond the double range (~2^1024) but well below
    // maxExactBits (100000), so it is a valid ExactNumber.
    final huge = BigInt.two.pow(1100);

    ExactNumber exact(BigInt numerator, [BigInt? denominator]) =>
        ExactNumber(Rational(numerator, denominator ?? BigInt.one));

    test('ln of a number beyond the double range is a MathError', () {
      // toDouble() overflows to Infinity, ln(Infinity) = Infinity
      expect(
        () => registry.invoke('ln', [exact(huge)], context),
        throwsA(isA<MathError>()),
      );
    });

    test('ln of a positive number below the double range is a MathError', () {
      // 1 / 2^1100 is positive, so the domain check passes,
      // but toDouble() underflows to 0.0 and ln(0.0) = -Infinity
      expect(
        () => registry.invoke('ln', [exact(BigInt.one, huge)], context),
        throwsA(isA<MathError>()),
      );
    });

    test('sqrt of a non-square beyond the double range is a MathError', () {
      expect(
        () => registry.invoke('sqrt', [exact(huge + BigInt.one)], context),
        throwsA(isA<MathError>()),
      );
    });

    test('ApproxNumber rejects NaN and both infinities', () {
      expect(() => ApproxNumber(double.nan), throwsA(isA<MathError>()));
      expect(() => ApproxNumber(double.infinity), throwsA(isA<MathError>()));
      expect(
        () => ApproxNumber(double.negativeInfinity),
        throwsA(isA<MathError>()),
      );
    });

    test(
      'log with a base beyond the double range is wrong but finite',
      () {
        // ln(base) overflows to Infinity, ln(8) / Infinity = 0.0.
        // The real result is 3 / 1100 ≈ 0.0027. A NaN/Infinity check
        // cannot detect wrong finite results.
        final result = registry.invoke('log', [
          exact(BigInt.from(8)),
          exact(huge),
        ], context);
        expect((result as ApproxNumber).value, closeTo(3 / 1100, 1e-12));
      },
      skip: 'Known limitation: base is converted to double before ln',
    );
  });

  // -------------------------------------------------------------------------
  group('Stage 4: trigonometry and DEG / RAD', () {
    late FunctionRegistry reg;
    setUp(() => reg = standardRegistry());

    test('all trig names are registered in the right category', () {
      for (final name in ['sin', 'cos', 'tan']) {
        expect(
          reg.lookup(name)?.category,
          FunctionCategory.trigonometry,
          reason: name,
        );
      }
    });

    test('radians', () {
      expectNumber(reg.invoke('sin', [ex(0)], rad), 0);
      expectNumber(reg.invoke('sin', [ap(math.pi / 2)], rad), 1);
      expectNumber(reg.invoke('cos', [ex(0)], rad), 1);
      expectNumber(reg.invoke('tan', [ap(math.pi / 4)], rad), 1);
    });

    test('degrees', () {
      expectNumber(reg.invoke('sin', [ex(90)], deg), 1);
      expectNumber(reg.invoke('sin', [ex(30)], deg), 0.5);
      expectNumber(reg.invoke('cos', [ex(60)], deg), 0.5);
      expectNumber(reg.invoke('tan', [ex(45)], deg), 1);
      expectNumber(reg.invoke('cos', [ex(-60)], deg), 0.5);
    });

    test('the same input gives different results in DEG and RAD', () {
      expectNumber(reg.invoke('sin', [ex(90)], rad), 0.8939966636005579);
      expectNumber(reg.invoke('sin', [ex(90)], deg), 1);
    });

    test('sin(180°) is (close to) zero', () {
      expectNumber(reg.invoke('sin', [ex(180)], deg), 0);
    });

    test('sin(1) is approximate', () {
      expect(reg.invoke('sin', [ex(1)], rad), isA<ApproxNumber>());
    });

    // double does NOT produce NaN or Infinity here, but about 1.6e16.
    // Your central NaN/Infinity check will not catch this.
    test('tan at its poles in DEG is a MathError', () {
      expect(() => reg.invoke('tan', [ex(90)], deg), throwsMathError);
      expect(() => reg.invoke('tan', [ex(270)], deg), throwsMathError);
      expect(() => reg.invoke('tan', [ex(-90)], deg), throwsMathError);
    });

    test('tan(180°) is fine', () {
      expectNumber(reg.invoke('tan', [ex(180)], deg), 0);
    });
  }, skip: 'Stage 4');

  // -------------------------------------------------------------------------
  group('Stage 5 (bonus): exact special values', () {
    late FunctionRegistry reg;
    setUp(() => reg = standardRegistry());

    test('rational trig values in DEG are exact', () {
      expect(reg.invoke('sin', [ex(30)], deg), frac(1, 2));
      expect(reg.invoke('sin', [ex(180)], deg), ex(0));
      expect(reg.invoke('cos', [ex(90)], deg), ex(0));
      expect(reg.invoke('cos', [ex(120)], deg), frac(-1, 2));
      expect(reg.invoke('tan', [ex(45)], deg), ex(1));
      expect(reg.invoke('sin', [ex(390)], deg), frac(1, 2));
    });

    test('irrational trig values stay approximate', () {
      // sin(45°) = √2 / 2 is not rational.
      expect(reg.invoke('sin', [ex(45)], deg), isA<ApproxNumber>());
    });

    test('approximate input stays approximate', () {
      expect(reg.invoke('sin', [ap(30.0)], deg), isA<ApproxNumber>());
    });

    test('sin(0) and cos(0) are exact in both modes', () {
      expect(reg.invoke('sin', [ex(0)], rad), ex(0));
      expect(reg.invoke('cos', [ex(0)], rad), ex(1));
    });

    test('ln(1) and log of powers of ten are exact', () {
      expect(reg.invoke('ln', [ex(1)], rad), ex(0));
      expect(reg.invoke('log', [ex(1000)], rad), ex(3));
      expect(reg.invoke('log', [frac(1, 100)], rad), ex(-2));
    });

    test('sqrt of a huge perfect square is exact', () {
      // (10^20 + 1)^2: a double cannot represent the root exactly.
      final root = BigInt.from(10).pow(20) + BigInt.one;
      final square = ExactNumber(Rational(root * root));
      expect(reg.invoke('sqrt', [square], rad), ExactNumber(Rational(root)));
    });
  }, skip: 'Stage 5 (bonus)');
}
