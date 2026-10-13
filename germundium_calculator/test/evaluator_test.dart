// Tests for stage 5: the evaluator.
//
// TODO: adjust the package name below if your pubspec uses a different one.
//
// Groups 1-5 use a small fake registry defined in main() (the same idea as
// the stage 2 tests of the registry). That keeps these tests independent
// of builtins.dart: if one fails, the evaluator is to blame, not sqrt.
// Only group 6 uses standardRegistry().
//
// The trees are built with your parser, so the inputs stay readable.
// If a test fails, first print `parse(input)` and check that the tree is
// what you expect. Only then look at the evaluator.
//
// Remove the `skip:` of a group when you start that stage.

import 'dart:math' as math;

import 'package:germundium_calculator/engine/engine.dart';
import 'package:germundium_calculator/engine/evaluator.dart';
import 'package:germundium_calculator/engine/registry.dart';
import 'package:rational/rational.dart';
import 'package:test/test.dart';

////dart test test/evaluator_test.dart

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ExactNumber ex(int n) => ExactNumber.fromInt(n);

ExactNumber frac(int n, int d) =>
    ExactNumber(Rational(BigInt.from(n), BigInt.from(d)));

const rad = EvalContext();
const deg = EvalContext(angleMode: AngleMode.degrees);

/// Checks the numeric value without caring whether it is exact or approximate.
void expectNumber(Value actual, double expected, {double tolerance = 1e-12}) {
  expect(actual, isA<NumberValue>());
  expect((actual as NumberValue).toDouble(), closeTo(expected, tolerance));
}

/// Expects a thrown [T] (any [CalcError] if no type is given).
///
/// [at] checks [CalcError.position], [mentioning] checks that
/// [CalcError.message] contains the text. Both are optional.
Matcher throwsCalcError<T extends CalcError>({int? at, String? mentioning}) {
  var matcher = isA<T>();
  if (at != null) {
    matcher = matcher.having((e) => e.position, 'position', at);
  }
  if (mentioning != null) {
    matcher = matcher.having((e) => e.message, 'message', contains(mentioning));
  }
  return throwsA(matcher);
}

/// Runs [body] and returns the [CalcError] it throws.
/// Fails the test if nothing is thrown.
CalcError errorOf(void Function() body) {
  try {
    body();
  } on CalcError catch (e) {
    return e;
  }
  fail('Expected a CalcError, but nothing was thrown');
}

void main() {
  // -------------------------------------------------------------------------
  // Fake registry
  // -------------------------------------------------------------------------

  var calls = 0; // how often `twice` ran
  EvalContext? seenContext; // the context `probe` received last

  final registry = FunctionRegistry([
    // A constant: answer = 42.
    ConstantEntry(name: 'answer', symbol: '42', value: ex(42)),

    // One argument, counts its calls.
    FunctionEntry(
      name: 'twice',
      symbol: '2×',
      category: FunctionCategory.basic,
      arity: const Arity.exactly(1),
      evaluate: (args, context) {
        calls++;
        return multiply(args[0], ex(2));
      },
    ),

    // Any number of arguments (at least one).
    FunctionEntry(
      name: 'sum',
      symbol: 'Σ',
      category: FunctionCategory.basic,
      arity: const Arity.atLeast(1),
      evaluate: (args, context) => args.reduce(add),
    ),

    // Throws a MathError (without position) for 0, like a real built-in.
    FunctionEntry(
      name: 'inv',
      symbol: '1/x',
      category: FunctionCategory.basic,
      arity: const Arity.exactly(1),
      evaluate: (args, context) => divide(ex(1), args[0]),
    ),

    // No arguments, remembers the context it was called with.
    FunctionEntry(
      name: 'probe',
      symbol: '?',
      category: FunctionCategory.basic,
      arity: const Arity.exactly(0),
      evaluate: (args, context) {
        seenContext = context;
        return ex(0);
      },
    ),

    // Simulates a bug: throws something that is NOT a CalcError.
    FunctionEntry(
      name: 'broken',
      symbol: '☠',
      category: FunctionCategory.basic,
      arity: const Arity.exactly(0),
      evaluate: (args, context) => throw StateError('a bug, not user input'),
    ),
  ]);

  setUp(() {
    calls = 0;
    seenContext = null;
  });

  /// Parses [input] and evaluates the tree with the fake registry.
  Value eval(String input, {EvalContext context = rad}) =>
      Evaluator(registry: registry, context: context).evaluate(parse(input));

  // -------------------------------------------------------------------------
  group('Stage 1: numbers and operators', () {
    test('an integer literal becomes an exact number', () {
      final result = eval('42');
      expect(result, isA<ExactNumber>());
      expect(result, ex(42));
    });

    test('a decimal literal stays exact', () {
      final result = eval('0.1');
      expect(result, isA<ExactNumber>());
      expect(result, ExactNumber.parse('0.1'));
    });

    test('0.1 + 0.2 is exactly 0.3', () {
      expect(eval('0.1 + 0.2'), ExactNumber.parse('0.3'));
    });

    test('subtraction, multiplication, division', () {
      expect(eval('7 - 10'), ex(-3));
      expect(eval('6 * 7'), ex(42));
      expect(eval('1 / 3'), frac(1, 3));
    });

    test('1/3 * 3 is exactly 1', () {
      expect(eval('1/3 * 3'), ex(1));
    });

    test('power with an integer exponent stays exact', () {
      expect(eval('2 ^ 10'), ex(1024));
      expect(eval('2 ^ -2'), frac(1, 4));
    });

    test('a non-integer exponent gives an approximate result', () {
      final result = eval('2 ^ 0.5');
      expect(result, isA<ApproxNumber>());
      expectNumber(result, math.sqrt2);
    });

    test('negation', () {
      expect(eval('-5'), ex(-5));
      expect(eval('--5'), ex(5));
      expect(eval('-(2 - 7)'), ex(5));
    });

    test('factorial', () {
      expect(eval('0!'), ex(1));
      expect(eval('3!'), ex(6));
      expect(eval('3!!'), ex(720));
    });

    test('implicit multiplication: 2(3 + 4) = 14', () {
      expect(eval('2(3 + 4)'), ex(14));
    });

    // --- order of operations ---
    // The next three need nothing special in the evaluator.

    test('subtraction is left-associative: 1 - 2 - 3 = -4', () {
      expect(eval('1 - 2 - 3'), ex(-4));
    });

    test('power is right-associative: 2^3^2 = 512', () {
      expect(eval('2^3^2'), ex(512));
    });

    test('power binds tighter than the sign: -2^2 = -4', () {
      expect(eval('-2^2'), ex(-4));
    });

    test('evaluating the same tree twice gives the same result', () {
      final evaluator = Evaluator(registry: registry);
      final tree = parse('1/3 + 1/6');
      expect(evaluator.evaluate(tree), frac(1, 2));
      expect(evaluator.evaluate(tree), frac(1, 2));
    });
  });

  // -------------------------------------------------------------------------
  group('Stage 2: error positions', () {
    test('division by zero points at the operator', () {
      expect(() => eval('1/0'), throwsCalcError<MathError>(at: 1));
    });

    test('the error keeps its type and message, only the position is new', () {
      final original = errorOf(() => divide(ex(1), ex(0)));
      expect(
        original.position,
        isNull,
        reason: 'value types know no positions',
      );

      final positioned = errorOf(() => eval('1/0'));
      expect(positioned, isA<MathError>());
      expect(positioned.message, original.message);
    });

    test('the position is counted in the whole input', () {
      expect(() => eval('1 + 1/0'), throwsCalcError<MathError>(at: 5));
    });

    test('the error belongs to the operation, not to the operand', () {
      // The zero comes from (2 - 2), but dividing is what fails.
      expect(() => eval('1/(2 - 2)'), throwsCalcError<MathError>(at: 1));
    });

    test('the innermost node wins', () {
      // The outer operators must not overwrite the position of the inner /.
      expect(() => eval('(1/0) + 2'), throwsCalcError<MathError>(at: 2));
      expect(() => eval('2 * (1 + 1/0)'), throwsCalcError<MathError>(at: 10));
    });

    test('zero to a negative power points at the operator', () {
      expect(() => eval('0^-1'), throwsCalcError<MathError>(at: 1));
    });

    test('factorial of a negative number points at the factorial node', () {
      // Which position a Factorial node has (the `!` or its operand) was
      // decided by your parser in stage 2, so the test reads it from there.
      final tree = parse('(-1)!');
      expect(
        () => Evaluator(registry: registry).evaluate(tree),
        throwsCalcError<MathError>(at: tree.position),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('Stage 3: names', () {
    test('a constant is replaced by its value', () {
      expect(eval('answer'), ex(42));
    });

    test('constants work with signs and implicit multiplication', () {
      expect(eval('-answer'), ex(-42));
      expect(eval('2answer'), ex(84));
      expect(eval('answer/answer'), ex(1));
    });

    test('an unknown name throws a CalcError naming it', () {
      expect(() => eval('foo'), throwsCalcError(at: 0, mentioning: 'foo'));
    });

    test('an unknown name points at where the name starts', () {
      expect(() => eval('1 + foo'), throwsCalcError(at: 4, mentioning: 'foo'));
    });

    test('a function name without parentheses is an error', () {
      expect(() => eval('twice'), throwsCalcError(at: 0, mentioning: 'twice'));
      expect(() => eval('3twice'), throwsCalcError(at: 1, mentioning: 'twice'));
    });
  });

  // -------------------------------------------------------------------------
  group('Stage 4: function calls', () {
    test('a call evaluates its argument and invokes the function', () {
      expect(eval('twice(21)'), ex(42));
      expect(eval('twice(1 + 2)'), ex(6));
    });

    test('a call with several arguments', () {
      expect(eval('sum(1, 2, 3)'), ex(6));
      expect(eval('sum(answer, 1/2)'), frac(85, 2));
    });

    test('a call with no arguments', () {
      expect(eval('probe()'), ex(0));
    });

    test('nested calls and implicit multiplication', () {
      expect(eval('twice(twice(2))'), ex(8));
      expect(eval('3twice(2)'), ex(12));
    });

    test('every call runs exactly once', () {
      eval('twice(twice(1))');
      expect(calls, 2);
    });

    test('the evaluator passes its own context to the function', () {
      eval('probe()', context: deg);
      expect(seenContext, same(deg));
      eval('probe()', context: rad);
      expect(seenContext, same(rad));
    });

    test('wrong argument count points at the call', () {
      expect(
        () => eval('twice(1, 2)'),
        throwsCalcError(at: 0, mentioning: 'twice'),
      );
      expect(
        () => eval('1 + twice()'),
        throwsCalcError(at: 4, mentioning: 'twice'),
      );
      expect(calls, 0);
    });

    test('an unknown function throws a CalcError naming it', () {
      expect(() => eval('nope(1)'), throwsCalcError(at: 0, mentioning: 'nope'));
    });

    test(
      'an unknown function is reported before its arguments are evaluated',
      () {
        // The user should learn about the typo first, not about 1/0.
        expect(
          () => eval('nope(1/0)'),
          throwsCalcError(at: 0, mentioning: 'nope'),
        );
      },
    );

    test('a MathError from inside a function points at the call', () {
      expect(() => eval('inv(0)'), throwsCalcError<MathError>(at: 0));
      expect(() => eval('2 * inv(0)'), throwsCalcError<MathError>(at: 4));
    });

    test('a MathError in an argument points at the argument', () {
      expect(() => eval('twice(1/0)'), throwsCalcError<MathError>(at: 7));
      expect(calls, 0, reason: 'twice must not run with a broken argument');
    });

    test('arguments are evaluated from left to right', () {
      // Both arguments fail. The first one must be reported.
      expect(() => eval('sum(1/0, foo)'), throwsCalcError<MathError>(at: 5));
    });

    test('errors that are not CalcErrors pass through untouched', () {
      // A StateError is a bug in our code, not a mistake of the user.
      expect(() => eval('broken()'), throwsStateError);
    });
  }, skip: 'Stage 4');

  // -------------------------------------------------------------------------
  group('Stage 5: constants with parentheses', () {
    test('a constant followed by one argument multiplies', () {
      expect(eval('answer(2)'), ex(84));
    });

    test('answer(2) means the same as answer * 2 and 2answer', () {
      expect(eval('answer(2)'), eval('answer * 2'));
      expect(eval('answer(2)'), eval('2answer'));
    });

    test('the argument is a complete expression', () {
      expect(eval('answer(1 + 1)'), ex(84));
    });

    test('a call binds tighter than division: 1/answer(2) = 1/84', () {
      // The parser builds a Call node, and a Call is a primary.
      // Compare this with 1/2answer (see the task file).
      expect(eval('1/answer(2)'), frac(1, 84));
    });

    test('empty parentheses are an error', () {
      expect(
        () => eval('answer()'),
        throwsCalcError(at: 0, mentioning: 'answer'),
      );
    });

    test('more than one argument is an error', () {
      expect(
        () => eval('answer(1, 2)'),
        throwsCalcError(at: 0, mentioning: 'answer'),
      );
    });

    test('an error inside the parentheses keeps its own position', () {
      expect(() => eval('answer(1/0)'), throwsCalcError<MathError>(at: 8));
    });
  }, skip: 'Stage 5');

  // -------------------------------------------------------------------------
  group(
    'Stage 6: calculate() with the built-in registry',
    () {
      test('calculate parses and evaluates in one step', () {
        expect(calculate('1 + 2'), ex(3));
        expect(calculate('0.1 + 0.2'), ExactNumber.parse('0.3'));
      });

      test('syntax errors from the parser pass through unchanged', () {
        final direct = errorOf(() => parse('1 +'));
        final viaCalculate = errorOf(() => calculate('1 +'));
        expect(viaCalculate, isA<SyntaxError>());
        expect(viaCalculate.message, direct.message);
        expect(viaCalculate.position, direct.position);
      });

      test('a custom registry can be passed in', () {
        expect(calculate('answer(2)', registry: registry), ex(84));
      });

      test('the default registry knows pi and sqrt', () {
        expectNumber(calculate('2pi'), 2 * math.pi);
        expect(calculate('sqrt(16)'), ex(4));
      });

      test('pi(2) is the same as 2pi', () {
        expect(calculate('pi(2)'), calculate('2pi'));
      });

      test('the default context is radians', () {
        expectNumber(calculate('cos(pi)'), -1);
      });

      test('the context reaches the built-ins', () {
        expectNumber(calculate('sin(30)', context: deg), 0.5);
      });

      test('a MathError from a built-in points at the call', () {
        expect(
          () => calculate('1 + sqrt(-1)'),
          throwsCalcError<MathError>(at: 4),
        );
      });

      test('a built-in function without parentheses', () {
        expect(
          () => calculate('sin'),
          throwsCalcError(at: 0, mentioning: 'sin'),
        );
      });
    },
    skip: 'Stage 6 (needs stage 4 to be finished)',
  );

  // -------------------------------------------------------------------------
  group('Your own tests', () {
    // At least three tests of your own (see the task file), for example
    // the one that records your decision for twice(1/0, 2).
  });
}
