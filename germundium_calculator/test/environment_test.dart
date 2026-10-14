// Tests for stage 6: the environment.
//
// TODO: adjust the package name below if your pubspec uses a different one.
//
// Like the evaluator tests, these use a small fake registry (see main()),
// so a red test points at stage 6 and not at builtins.dart. Only step 7
// uses standardRegistry().
//
// The groups are called "Step N" in English; in the task file they are
// "Stufe N". Remove the `skip:` of a group when you start that step.
//
// If a test fails, first print the tree: `print(parseStatement(input));`
// Only when the tree is what you expect, look at the evaluator.

import 'package:germundium_calculator/engine/engine.dart';
import 'package:germundium_calculator/engine/environment.dart';
import 'package:germundium_calculator/engine/parser.dart';
import 'package:germundium_calculator/engine/statement.dart';
import 'package:rational/rational.dart';
import 'package:test/test.dart';

////dart test test/environment_test.dart

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ExactNumber ex(int n) => ExactNumber.fromInt(n);

ExactNumber frac(int n, int d) =>
    ExactNumber(Rational(BigInt.from(n), BigInt.from(d)));

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

/// A function binding, written the short way: fn(['x'], 'x^2').
///
/// This is the ONLY place in this file that calls the FunctionBinding
/// constructor. If you change the constructor (variant B, task 29),
/// adjust this helper and nothing else.
FunctionBinding fn(List<String> params, String body) =>
    FunctionBinding(params, parse(body));

/// The value of the variable [name] in [environment], or null if [name]
/// is not a variable there.
Value? valueIn(Environment environment, String name) =>
    switch (environment.lookup(name)) {
      VariableBinding(:final value) => value,
      _ => null,
    };

/// The value a line produced. Fails the test for a function definition.
Value valueOf(Outcome outcome) => switch (outcome) {
  Computed(:final value) => value,
  Assigned(:final value) => value,
  FunctionDefined(:final name) => fail(
    'Expected a value, but the function $name was defined',
  ),
};

void main() {
  // -------------------------------------------------------------------------
  // Fake registry
  // -------------------------------------------------------------------------

  var calls = 0; // how often `twice` ran

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
  ]);

  setUp(() {
    calls = 0;
  });

  /// Evaluates the EXPRESSION [input] in [environment] (steps 1 and 2).
  Value eval(String input, [Environment environment = Environment.empty]) =>
      Evaluator(
        registry: registry,
        environment: environment,
      ).evaluate(parse(input));

  /// Executes ONE LINE [input] in [environment] (from step 4 on).
  Outcome exec(String input, [Environment environment = Environment.empty]) =>
      Evaluator(
        registry: registry,
        environment: environment,
      ).execute(parseStatement(input));

  /// Executes several lines one after another, like a user pressing `=`
  /// after each of them. Every line gets the environment of the line
  /// before. Returns the outcome of the last line.
  Outcome session(List<String> lines) {
    var environment = Environment.empty;
    late Outcome outcome;
    for (final line in lines) {
      outcome = exec(line, environment);
      environment = outcome.environment;
    }
    return outcome;
  }

  /// x = 3, half = 1/2, f(t) = t^2. Built by hand, no parser statements
  /// and no execute() needed.
  Environment sampleEnvironment() => Environment.empty
      .define('x', VariableBinding(ex(3)))
      .define('half', VariableBinding(frac(1, 2)))
      .define('f', fn(['t'], 't^2'));

  // -------------------------------------------------------------------------
  group('Step 1: the environment', () {
    test('the empty environment knows no names', () {
      expect(Environment.empty.lookup('x'), isNull);
      expect(Environment.empty.names, isEmpty);
    });

    test('define adds a variable', () {
      final env = Environment.empty.define('x', VariableBinding(ex(3)));
      expect(
        env.lookup('x'),
        isA<VariableBinding>().having((b) => b.value, 'value', ex(3)),
      );
    });

    test('define adds a function', () {
      final env = Environment.empty.define('f', fn(['x'], 'x^2'));
      expect(
        env.lookup('f'),
        isA<FunctionBinding>().having((b) => b.params, 'params', ['x']),
      );
    });

    test('define returns a new environment, the old one stays unchanged', () {
      const before = Environment.empty;
      final after = before.define('x', VariableBinding(ex(3)));
      expect(before.lookup('x'), isNull);
      expect(after.lookup('x'), isNotNull);
    });

    test('redefining a name replaces its binding in the new environment', () {
      final first = Environment.empty.define('x', VariableBinding(ex(3)));
      final second = first.define('x', VariableBinding(ex(5)));
      expect(valueIn(second, 'x'), ex(5));
      expect(valueIn(first, 'x'), ex(3), reason: 'first must not change');
    });

    test('one name, one meaning: a function replaces a variable', () {
      final env = Environment.empty
          .define('f', VariableBinding(ex(3)))
          .define('f', fn(['x'], 'x'));
      expect(env.lookup('f'), isA<FunctionBinding>());
    });

    test('names lists the names in the order of definition', () {
      final env = Environment.empty
          .define('x', VariableBinding(ex(1)))
          .define('f', fn(['t'], 't'))
          .define('y', VariableBinding(ex(2)));
      expect(env.names, orderedEquals(['x', 'f', 'y']));
    });

    test('a redefined name is listed only once', () {
      final env = Environment.empty
          .define('x', VariableBinding(ex(1)))
          .define('y', VariableBinding(ex(2)))
          .define('x', VariableBinding(ex(3)));
      expect(env.names, unorderedEquals(['x', 'y']));
    });
  });

  // -------------------------------------------------------------------------
  group('Step 2: the evaluator reads the environment', () {
    test('a user variable is replaced by its value', () {
      expect(eval('x', sampleEnvironment()), ex(3));
    });

    test('user variables work inside expressions', () {
      final env = sampleEnvironment();
      expect(eval('2x + 1', env), ex(7));
      expect(eval('x^2 - x', env), ex(6));
      expect(eval('half * 4', env), ex(2));
    });

    test('user variables and registry names work together', () {
      final env = sampleEnvironment();
      expect(eval('answer + x', env), ex(45));
      expect(eval('twice(x)', env), ex(6));
    });

    test('an unknown name is still an error', () {
      expect(
        () => eval('y', sampleEnvironment()),
        throwsCalcError(at: 0, mentioning: 'y'),
      );
    });

    test('without an environment there are no user variables', () {
      // Evaluator(registry: ...) without `environment:` uses the empty one.
      expect(() => eval('x'), throwsCalcError(at: 0, mentioning: 'x'));
    });

    test('a user function without parentheses is an error', () {
      expect(
        () => eval('2 + f', sampleEnvironment()),
        throwsCalcError<EvaluationError>(at: 4, mentioning: 'f'),
      );
    });

    test('a variable followed by parentheses multiplies, like answer(2)', () {
      final env = sampleEnvironment();
      expect(eval('x(2)', env), ex(6));
      expect(eval('x(1 + 1)', env), ex(6));
      expect(eval('half(x)', env), frac(3, 2));
    });

    test('a variable with empty or several arguments is an error', () {
      final env = sampleEnvironment();
      expect(() => eval('x()', env), throwsCalcError(at: 0, mentioning: 'x'));
      expect(
        () => eval('1 + x(1, 2)', env),
        throwsCalcError(at: 4, mentioning: 'x'),
      );
    });

    test('constants with parentheses still work after the refactoring', () {
      expect(eval('answer(2)', sampleEnvironment()), ex(84));
      expect(
        () => eval('answer()'),
        throwsCalcError(at: 0, mentioning: 'answer'),
      );
    });
  }, skip: 'Step 2');

  // -------------------------------------------------------------------------
  group('Step 3: the parser reads statements', () {
    test('a plain expression becomes an ExpressionStatement', () {
      expect(
        parseStatement('1 + 2'),
        isA<ExpressionStatement>().having(
          (s) => s.expr,
          'expr',
          isA<BinaryOp>(),
        ),
      );
    });

    test('name = expression becomes an Assignment', () {
      expect(
        parseStatement('x = 3'),
        isA<Assignment>()
            .having((s) => s.name, 'name', 'x')
            .having((s) => s.position, 'position', 0)
            .having((s) => s.expr, 'expr', isA<NumberLiteral>()),
      );
    });

    test('the right side is a complete expression', () {
      // The BinaryOp has the position of its operator (stage 2).
      expect(
        parseStatement('x = 1 + 2'),
        isA<Assignment>().having(
          (s) => s.expr,
          'expr',
          isA<BinaryOp>().having((e) => e.position, 'position', 6),
        ),
      );
    });

    test('the position of an assignment is where its name starts', () {
      expect(
        parseStatement('  y=2'),
        isA<Assignment>().having((s) => s.position, 'position', 2),
      );
    });

    test('f(x) = body becomes a FunctionDefinition', () {
      expect(
        parseStatement('f(x) = x^2'),
        isA<FunctionDefinition>()
            .having((s) => s.name, 'name', 'f')
            .having((s) => s.position, 'position', 0)
            .having(
              (s) => [for (final p in s.params) p.name],
              'parameter names',
              ['x'],
            )
            .having(
              (s) => [for (final p in s.params) p.position],
              'parameter positions',
              [2],
            )
            .having(
              (s) => s.body,
              'body',
              isA<BinaryOp>().having((e) => e.position, 'position', 8),
            ),
      );
    });

    test('several parameters keep their order', () {
      expect(
        parseStatement('g(a, b) = a - b'),
        isA<FunctionDefinition>()
            .having(
              (s) => [for (final p in s.params) p.name],
              'parameter names',
              ['a', 'b'],
            )
            .having(
              (s) => [for (final p in s.params) p.position],
              'parameter positions',
              [2, 5],
            ),
      );
    });

    test('parse() still accepts only expressions', () {
      expect(() => parse('x = 3'), throwsCalcError<SyntaxError>(at: 2));
    });

    test('left of = there must be a name or f(names), else the = is wrong', () {
      expect(
        () => parseStatement('1 = 2'),
        throwsCalcError<SyntaxError>(at: 2),
      );
      expect(
        () => parseStatement('2x = 3'),
        throwsCalcError<SyntaxError>(at: 3),
      );
      expect(
        () => parseStatement('x + 1 = 3'),
        throwsCalcError<SyntaxError>(at: 6),
      );
    });

    test('a parameter must be a name', () {
      expect(
        () => parseStatement('f(2) = 3'),
        throwsCalcError<SyntaxError>(at: 2),
      );
      expect(
        () => parseStatement('f(x, 1) = 3'),
        throwsCalcError<SyntaxError>(at: 5),
      );
    });

    test('there is at most one =', () {
      expect(
        () => parseStatement('x = 3 = 4'),
        throwsCalcError<SyntaxError>(at: 6),
      );
    });

    test('both sides of = are needed', () {
      expect(() => parseStatement('= 3'), throwsCalcError<SyntaxError>(at: 0));
      expect(() => parseStatement('x ='), throwsCalcError<SyntaxError>());
    });

    test('an assignment cannot be part of an expression', () {
      expect(
        () => parseStatement('2 + (x = 3)'),
        throwsCalcError<SyntaxError>(),
      );
    });
  }, skip: 'Step 3');

  // -------------------------------------------------------------------------
  group('Step 4: executing expressions and assignments', () {
    test('an expression is computed', () {
      final outcome = exec('1 + 2');
      expect(outcome, isA<Computed>());
      expect(valueOf(outcome), ex(3));
    });

    test('the result becomes ans', () {
      expect(valueIn(exec('1 + 2').environment, ansName), ex(3));
    });

    test('ans can be used in the next line', () {
      expect(valueOf(session(['2 + 3', 'ans * 2'])), ex(10));
      expect(valueOf(session(['2 + 3', 'ans * 2', 'ans * 2'])), ex(20));
    });

    test('ans before the first result is an error', () {
      expect(
        () => exec('ans'),
        throwsCalcError<EvaluationError>(at: 0, mentioning: 'ans'),
      );
    });

    test('an assignment stores the value', () {
      final outcome = exec('x = 3');
      expect(outcome, isA<Assigned>().having((o) => o.name, 'name', 'x'));
      expect(valueOf(outcome), ex(3));
      expect(valueIn(outcome.environment, 'x'), ex(3));
    });

    test('a stored variable can be used in a later line', () {
      expect(valueOf(session(['x = 3', '2x'])), ex(6));
    });

    test('an assignment also sets ans', () {
      expect(valueOf(session(['x = 3', 'ans'])), ex(3));
    });

    test('a variable can be reassigned', () {
      expect(valueOf(session(['x = 3', 'x = 5', 'x'])), ex(5));
    });

    test('the right side is evaluated before the name is stored', () {
      expect(valueOf(session(['x = 3', 'x = x + 1', 'x'])), ex(4));
      expect(() => exec('y = y + 1'), throwsCalcError(at: 4, mentioning: 'y'));
    });

    test('a variable stores a value, not a formula', () {
      expect(valueOf(session(['a = 2', 'b = a + 1', 'a = 10', 'b'])), ex(3));
    });

    test('built-in names cannot be assigned', () {
      expect(
        () => exec('answer = 1'),
        throwsCalcError<EvaluationError>(at: 0, mentioning: 'answer'),
      );
      expect(
        () => exec('twice = 1'),
        throwsCalcError<EvaluationError>(at: 0, mentioning: 'twice'),
      );
      expect(
        () => exec('  answer = 1'),
        throwsCalcError<EvaluationError>(at: 2),
      );
    });

    test('ans cannot be assigned', () {
      expect(
        () => exec('ans = 1'),
        throwsCalcError<EvaluationError>(at: 0, mentioning: 'ans'),
      );
    });

    test('the name is checked before the right side is evaluated', () {
      // Like nope(1/0) in stage 5: the user learns about the name first.
      expect(
        () => exec('answer = 1/0'),
        throwsCalcError<EvaluationError>(at: 0, mentioning: 'answer'),
      );
    });

    test('an error on the right side keeps its own position', () {
      expect(() => exec('x = 1/0'), throwsCalcError<MathError>(at: 5));
    });

    test('executing a line leaves the old environment unchanged', () {
      final first = exec('x = 3').environment;
      exec('x = 5', first);
      expect(valueIn(first, 'x'), ex(3));
      expect(valueIn(first, ansName), ex(3));
    });

    test('a failed line changes nothing', () {
      final before = exec('x = 3').environment;
      expect(() => exec('x = 1/0', before), throwsCalcError<MathError>());
      expect(valueIn(before, 'x'), ex(3));
      expect(valueIn(before, ansName), ex(3));
    });
  }, skip: 'Step 4');

  // -------------------------------------------------------------------------
  group('Step 5: defining and calling functions', () {
    test('a function definition is stored', () {
      final outcome = exec('f(x) = x^2');
      expect(
        outcome,
        isA<FunctionDefined>().having((o) => o.name, 'name', 'f'),
      );
      expect(
        outcome.environment.lookup('f'),
        isA<FunctionBinding>().having((b) => b.params, 'params', ['x']),
      );
    });

    test('a function definition does not change ans', () {
      expect(valueOf(session(['2 + 3', 'f(x) = x^2', 'ans'])), ex(5));
    });

    test('a user function can be called', () {
      expect(valueOf(session(['f(x) = x^2', 'f(3)'])), ex(9));
    });

    test('calls work inside expressions and stay exact', () {
      expect(valueOf(session(['f(x) = x^2', '2f(3) + 1'])), ex(19));
      expect(valueOf(session(['f(x) = x^2', 'f(1/2)'])), frac(1, 4));
    });

    test('arguments are bound to the parameters in order', () {
      expect(valueOf(session(['g(a, b) = a - b', 'g(5, 3)'])), ex(2));
    });

    test('a body can use built-ins and other user functions', () {
      expect(valueOf(session(['f(x) = twice(x) + answer', 'f(1)'])), ex(44));
      expect(valueOf(session(['f(x) = x + 1', 'g(x) = 2f(x)', 'g(3)'])), ex(8));
    });

    test('nested calls', () {
      expect(valueOf(session(['f(x) = x + 1', 'f(f(1))'])), ex(3));
    });

    test('every argument is evaluated exactly once', () {
      // x appears twice in the body, but twice(1) must run only once.
      expect(valueOf(session(['f(x) = x + x', 'f(twice(1))'])), ex(4));
      expect(calls, 1);
    });

    test('a parameter hides a variable with the same name', () {
      expect(valueOf(session(['x = 5', 'f(x) = x^2', 'f(2)'])), ex(4));
      expect(valueOf(session(['x = 5', 'f(x) = x^2', 'f(2)', 'x'])), ex(5));
    });

    test('parameters exist only inside the function', () {
      expect(
        () => session(['f(y) = y', 'f(1)', 'y']),
        throwsCalcError(at: 0, mentioning: 'y'),
      );
    });

    test('a user function without parentheses is an error', () {
      expect(
        () => session(['f(x) = x', 'f']),
        throwsCalcError(at: 0, mentioning: 'f'),
      );
    });

    test('a wrong number of arguments is an error at the call', () {
      expect(
        () => session(['f(x) = x', 'f(1, 2)']),
        throwsCalcError(at: 0, mentioning: 'f'),
      );
      expect(
        () => session(['f(x) = x', '1 + f()']),
        throwsCalcError(at: 4, mentioning: 'f'),
      );
    });

    test('a function can be redefined', () {
      expect(valueOf(session(['f(x) = x', 'f(x) = 2x', 'f(5)'])), ex(10));
    });

    test(
      'one name, one meaning: variables and functions replace each other',
      () {
        expect(valueOf(session(['f(x) = x', 'f = 3', 'f(2)'])), ex(6));
        expect(valueOf(session(['f = 3', 'f(x) = x^2', 'f(2)'])), ex(4));
      },
    );

    test('built-in names cannot become functions', () {
      expect(
        () => exec('twice(x) = x'),
        throwsCalcError<EvaluationError>(at: 0, mentioning: 'twice'),
      );
      expect(
        () => exec('answer(x) = x'),
        throwsCalcError<EvaluationError>(at: 0, mentioning: 'answer'),
      );
      expect(
        () => exec('ans(x) = x'),
        throwsCalcError<EvaluationError>(at: 0, mentioning: 'ans'),
      );
    });

    test('built-in names cannot be parameters', () {
      expect(
        () => exec('f(answer) = 1'),
        throwsCalcError<EvaluationError>(at: 2, mentioning: 'answer'),
      );
      expect(
        () => exec('f(x, ans) = 1'),
        throwsCalcError<EvaluationError>(at: 5, mentioning: 'ans'),
      );
    });

    test('a parameter name may appear only once', () {
      // Parser or evaluator? Your decision (task 30), so no error type here.
      expect(
        () => exec('f(x, x) = 1'),
        throwsCalcError(at: 5, mentioning: 'x'),
      );
    });
  }, skip: 'Step 5');

  // -------------------------------------------------------------------------
  group('Step 6: errors inside functions', () {
    test('an error inside a function points at the call', () {
      expect(
        () => session(['f(x) = 1/x', '2 + f(0)']),
        throwsCalcError<MathError>(at: 4),
      );
    });

    test('it keeps its type and message', () {
      final direct = errorOf(() => exec('1/0'));
      final viaFunction = errorOf(() => session(['f(x) = 1/x', 'f(0)']));
      expect(viaFunction, isA<MathError>());
      expect(viaFunction.message, contains(direct.message));
    });

    test('the call in the current line wins, not one inside another body', () {
      expect(
        () => session(['f(x) = 1/x', 'g(x) = f(x) + 1', '3 * g(0)']),
        throwsCalcError<MathError>(at: 4),
      );
    });

    test('an error in an argument keeps its own position', () {
      expect(
        () => session(['f(x) = x', 'f(1/0)']),
        throwsCalcError<MathError>(at: 3),
      );
    });

    test('a function that calls itself is a CalcError, not a crash', () {
      expect(
        () => session(['f(x) = f(x) + 1', 'f(1)']),
        throwsA(isA<CalcError>()),
      );
    });
  }, skip: 'Step 6');

  // -------------------------------------------------------------------------
  // Your decision (task 29). Keep the group of the variant you chose:
  // remove its `skip:` and delete the other group completely.
  // -------------------------------------------------------------------------
  group('Variant A: late binding', () {
    test('the body sees the current value of a variable', () {
      expect(
        valueOf(session(['a = 2', 'f(x) = a * x', 'a = 3', 'f(1)'])),
        ex(3),
      );
    });

    test('a name in the body may be defined after the function', () {
      expect(valueOf(session(['f(x) = a * x', 'a = 3', 'f(2)'])), ex(6));
    });

    test('an indirect cycle is a CalcError, not a crash', () {
      expect(
        () => session(['f(x) = x', 'g(x) = f(x)', 'f(x) = g(x)', 'f(1)']),
        throwsA(isA<CalcError>()),
      );
    });
  }, skip: 'Variant A');

  group('Variant B: early binding (snapshot)', () {
    test('the body keeps the values from the moment of definition', () {
      expect(
        valueOf(session(['a = 2', 'f(x) = a * x', 'a = 3', 'f(1)'])),
        ex(2),
      );
    });

    test('redefining f does not change functions that used the old f', () {
      expect(
        valueOf(session(['f(x) = x', 'g(x) = f(x)', 'f(x) = g(x)', 'f(1)'])),
        ex(1),
      );
    });
  }, skip: 'Variant B');

  // -------------------------------------------------------------------------
  group('Step 7: run() with the built-in registry', () {
    test('run parses and executes one line', () {
      expect(valueOf(run('1 + 2')), ex(3));
    });

    test('run takes an environment and returns the new one', () {
      final first = run('x = 2');
      expect(valueOf(run('3x', environment: first.environment)), ex(6));
    });

    test('built-in constants cannot be redefined', () {
      expect(
        () => run('pi = 3'),
        throwsCalcError<EvaluationError>(at: 0, mentioning: 'pi'),
      );
      // The open question from stage 4, task 15.
      expect(() => run('e = 3'), throwsCalcError<EvaluationError>(at: 0));
    });

    test('built-in functions cannot be redefined', () {
      expect(
        () => run('sin(x) = x'),
        throwsCalcError<EvaluationError>(at: 0, mentioning: 'sin'),
      );
    });

    test('the context reaches built-ins inside user functions', () {
      final defined = run('f(x) = 2sin(x)', context: deg);
      final outcome = run(
        'f(30)',
        environment: defined.environment,
        context: deg,
      );
      expectNumber(valueOf(outcome), 1);
    });

    test('syntax errors from the parser pass through', () {
      expect(() => run('x ='), throwsCalcError<SyntaxError>());
    });

    test('a custom registry can be passed in', () {
      expect(valueOf(run('answer(2)', registry: registry)), ex(84));
    });
  }, skip: 'Step 7');

  // -------------------------------------------------------------------------
  // Variant B only (task 44). With variant A, delete this group (task 39).
  group('Bonus: names in the body are checked at definition', () {
    test('an unknown name is reported where the function is defined', () {
      expect(
        () => exec('f(x) = x + y'),
        throwsCalcError<EvaluationError>(at: 11, mentioning: 'y'),
      );
      expect(
        () => exec('f(x) = nope(x)'),
        throwsCalcError<EvaluationError>(at: 7, mentioning: 'nope'),
      );
    });

    test('parameters, variables and built-ins are known', () {
      expect(
        valueOf(session(['a = 1', 'f(x) = a + x + answer + twice(x)', 'f(1)'])),
        ex(46),
      );
    });
  }, skip: 'Bonus');

  // -------------------------------------------------------------------------
  group('Your own tests', () {
    // At least three tests of your own (see the task file, task 45).
  });
}
