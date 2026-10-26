import 'package:calculator_core/calculator_core.dart';
import 'package:test/test.dart';

final _characters = <String, CalculatorKey>{
  '0': CalculatorKey.digit0,
  '1': CalculatorKey.digit1,
  '2': CalculatorKey.digit2,
  '3': CalculatorKey.digit3,
  '4': CalculatorKey.digit4,
  '5': CalculatorKey.digit5,
  '6': CalculatorKey.digit6,
  '7': CalculatorKey.digit7,
  '8': CalculatorKey.digit8,
  '9': CalculatorKey.digit9,
  '+': CalculatorKey.add,
  '-': CalculatorKey.subtract,
  '*': CalculatorKey.multiply,
  '/': CalculatorKey.divide,
  '^': CalculatorKey.power,
  ',': CalculatorKey.decimal,
  '(': CalculatorKey.leftParenthesis,
  ')': CalculatorKey.rightParenthesis,
};

void enter(CalculatorSession session, String source) {
  for (final character in source.split('')) {
    session.press(_characters[character]!);
  }
}

void main() {
  group('initial and immutable snapshots', () {
    test('starts editing with an empty editor and zero answer', () {
      final session = CalculatorSession();
      final state = session.snapshot;
      expect(state.phase, CalculatorPhase.editing);
      expect(state.expression, '');
      expect(state.tokens, isEmpty);
      expect(state.cursor, 0);
      expect(state.cursorOffset, 0);
      expect(state.answer, Rational.fromInt(0));
      expect(state.result, isNull);
      expect(state.error, isNull);
    });

    test(
      'press returns the new current state without mutating older snapshots',
      () {
        final session = CalculatorSession();
        final empty = session.snapshot;
        final one = session.press(CalculatorKey.digit1);
        final two = session.press(CalculatorKey.digit2);
        expect(one.expression, '1');
        expect(one.tokens, ['1']);
        expect(one.cursor, 1);
        expect(two.expression, '12');
        expect(session.snapshot.expression, two.expression);
        expect(empty.expression, '');
        expect(empty.tokens, isEmpty);
        expect(empty.cursor, 0);
        expect(one.expression, '1');
        expect(one.tokens, ['1']);
      },
    );

    test('snapshot token lists cannot be added to or overwritten', () {
      final session = CalculatorSession();
      final state = session.press(CalculatorKey.digit1);
      expect(() => state.tokens.add('9'), throwsUnsupportedError);
      expect(() => state.tokens[0] = '9', throwsUnsupportedError);
      expect(() => state.tokens.clear(), throwsUnsupportedError);
      expect(session.snapshot.expression, '1');
    });

    test(
      'old successful snapshots retain their answer after a later calculation',
      () {
        final session = CalculatorSession();
        enter(session, '2+3');
        final five = session.press(CalculatorKey.equals);
        enter(session, '8');
        session.press(CalculatorKey.equals);
        expect(five.phase, CalculatorPhase.result);
        expect(five.expression, '2+3');
        expect(five.answer, Rational.fromInt(5));
        expect(five.result, Rational.fromInt(5));
        expect(session.snapshot.answer, Rational.fromInt(8));
      },
    );
  });

  group('stable IDs for the implemented key subset', () {
    final ids = <CalculatorKey, String>{
      CalculatorKey.digit0: 'KEY_0',
      CalculatorKey.digit1: 'KEY_1',
      CalculatorKey.digit2: 'KEY_2',
      CalculatorKey.digit3: 'KEY_3',
      CalculatorKey.digit4: 'KEY_4',
      CalculatorKey.digit5: 'KEY_5',
      CalculatorKey.digit6: 'KEY_6',
      CalculatorKey.digit7: 'KEY_7',
      CalculatorKey.digit8: 'KEY_8',
      CalculatorKey.digit9: 'KEY_9',
      CalculatorKey.add: 'KEY_ADD',
      CalculatorKey.subtract: 'KEY_SUBTRACT',
      CalculatorKey.multiply: 'KEY_MULTIPLY',
      CalculatorKey.divide: 'KEY_DIVIDE',
      CalculatorKey.power: 'KEY_POWER',
      CalculatorKey.negate: 'KEY_NEGATE',
      CalculatorKey.decimal: 'KEY_DECIMAL',
      CalculatorKey.leftParenthesis: 'KEY_LPAREN',
      CalculatorKey.rightParenthesis: 'KEY_RPAREN',
      CalculatorKey.left: 'KEY_LEFT',
      CalculatorKey.right: 'KEY_RIGHT',
      CalculatorKey.delete: 'KEY_DEL',
      CalculatorKey.clear: 'KEY_AC',
      CalculatorKey.equals: 'KEY_EQUALS',
      CalculatorKey.answer: 'KEY_ANS',
    };
    test('all supported enum values have unique inventory IDs', () {
      expect(ids.keys.toSet(), CalculatorKey.values.toSet());
      expect(ids.values.toSet().length, ids.length);
      for (final entry in ids.entries) {
        expect(entry.key.id, entry.value);
      }
    });

    for (final digit in List.generate(10, (index) => index)) {
      test('digit $digit dispatches through pressId', () {
        final session = CalculatorSession();
        final state = session.pressId('KEY_$digit');
        expect(state.expression, '$digit');
        expect(state.tokens, ['$digit']);
        expect(state.cursor, 1);
      });
    }

    test('pressId follows the same calculation path as enum presses', () {
      final session = CalculatorSession();
      for (final id in ['KEY_6', 'KEY_DIVIDE', 'KEY_4']) {
        session.pressId(id);
      }
      final state = session.pressId('KEY_EQUALS');
      expect(state.phase, CalculatorPhase.result);
      expect(state.result.toString(), '3/2');
    });

    for (final id in ['KEY_SHIFT', 'KEY_SIN', 'not_a_key', '']) {
      test('unsupported ID "$id" throws without changing state', () {
        final session = CalculatorSession();
        enter(session, '12');
        session.press(CalculatorKey.left);
        final before = session.snapshot;
        expect(
          () => session.pressId(id),
          throwsA(
            isA<CalculatorException>().having(
              (error) => error.code,
              'code',
              CalculatorErrorCode.unsupported,
            ),
          ),
        );
        final after = session.snapshot;
        expect(after.phase, before.phase);
        expect(after.expression, before.expression);
        expect(after.tokens, before.tokens);
        expect(after.cursor, before.cursor);
        expect(after.cursorOffset, before.cursorOffset);
        expect(after.answer, before.answer);
        expect(after.result, before.result);
        expect(after.error, before.error);
      });
    }
  });

  group('linear input and exact arithmetic', () {
    final cases = <String, String>{
      '2+3*4': '14',
      '(2+3)*4': '20',
      '8-3-2': '3',
      '8/2/2': '2',
      '1/3+1/6': '1/2',
      '0,1+0,2': '3/10',
      '2(3+4)': '14',
      '2^0': '1',
      '2^3^2': '512',
      '2^-3': '1/8',
      '(-2)^2': '4',
    };
    for (final entry in cases.entries) {
      test('key sequence ${entry.key}', () {
        final session = CalculatorSession();
        enter(session, entry.key);
        final state = session.press(CalculatorKey.equals);
        expect(state.phase, CalculatorPhase.result);
        expect(state.error, isNull);
        expect(state.result.toString(), entry.value);
        expect(state.answer, state.result);
      });
    }

    test('negative sign key has lower precedence than power', () {
      final session = CalculatorSession();
      session.press(CalculatorKey.negate);
      enter(session, '2^2');
      expect(session.press(CalculatorKey.equals).result, Rational.fromInt(-4));
    });

    test('equals on empty input is a no-op in this prototype', () {
      final session = CalculatorSession();
      final state = session.press(CalculatorKey.equals);
      expect(state.phase, CalculatorPhase.editing);
      expect(state.expression, '');
      expect(state.error, isNull);
      expect(state.result, isNull);
      expect(state.answer, Rational.fromInt(0));
    });

    test('integer exponent at 1000 works and 1001 gives a limit error', () {
      final session = CalculatorSession();
      enter(session, '2^1000');
      final success = session.press(CalculatorKey.equals);
      expect(success.result, Rational(BigInt.two.pow(1000)));
      session.press(CalculatorKey.clear);
      enter(session, '2^1001');
      final failure = session.press(CalculatorKey.equals);
      expect(failure.phase, CalculatorPhase.error);
      expect(failure.error?.code, CalculatorErrorCode.limit);
      expect(failure.answer, success.answer);
    });
  });

  group('cursor editing and atomic Ans tokens', () {
    test('inserts and deletes at a middle cursor position', () {
      final session = CalculatorSession();
      enter(session, '123');
      session.press(CalculatorKey.left);
      session.press(CalculatorKey.left);
      expect(session.snapshot.cursor, 1);
      final inserted = session.press(CalculatorKey.digit4);
      expect(inserted.expression, '1423');
      expect(inserted.cursor, 2);
      expect(inserted.cursorOffset, 2);
      final deleted = session.press(CalculatorKey.delete);
      expect(deleted.expression, '123');
      expect(deleted.cursor, 1);
      expect(deleted.cursorOffset, 1);
    });

    test('navigation and deletion clamp at both editor boundaries', () {
      final session = CalculatorSession();
      session.press(CalculatorKey.left);
      session.press(CalculatorKey.delete);
      expect(session.snapshot.expression, '');
      expect(session.snapshot.cursor, 0);
      enter(session, '12');
      for (var i = 0; i < 5; i++) {
        session.press(CalculatorKey.right);
      }
      expect(session.snapshot.cursor, 2);
      for (var i = 0; i < 5; i++) {
        session.press(CalculatorKey.left);
      }
      final state = session.press(CalculatorKey.delete);
      expect(state.cursor, 0);
      expect(state.expression, '12');
    });

    test('Ans is one token although its display text has three characters', () {
      final session = CalculatorSession();
      final answer = session.press(CalculatorKey.answer);
      expect(answer.expression, 'Ans');
      expect(answer.tokens, ['Ans']);
      expect(answer.cursor, 1);
      expect(answer.cursorOffset, 3);
      final left = session.press(CalculatorKey.left);
      expect(left.cursor, 0);
      expect(left.cursorOffset, 0);
      final right = session.press(CalculatorKey.right);
      expect(right.cursor, 1);
      expect(right.cursorOffset, 3);
      final deleted = session.press(CalculatorKey.delete);
      expect(deleted.expression, '');
      expect(deleted.tokens, isEmpty);
      expect(deleted.cursor, 0);
      expect(answer.tokens, ['Ans']);
    });

    test('inserting before Ans preserves token-to-string cursor mapping', () {
      final session = CalculatorSession();
      session.press(CalculatorKey.answer);
      session.press(CalculatorKey.left);
      session.press(CalculatorKey.leftParenthesis);
      expect(session.snapshot.tokens, ['(', 'Ans']);
      expect(session.snapshot.cursor, 1);
      expect(session.snapshot.cursorOffset, 1);
      session.press(CalculatorKey.right);
      expect(session.snapshot.cursor, 2);
      expect(session.snapshot.cursorOffset, 4);
      session.press(CalculatorKey.delete);
      expect(session.snapshot.expression, '(');
      expect(session.snapshot.cursorOffset, 1);
    });

    test('editing is independent between sessions', () {
      final first = CalculatorSession();
      final second = CalculatorSession();
      enter(first, '2+3');
      first.press(CalculatorKey.equals);
      expect(second.snapshot.expression, '');
      expect(second.snapshot.answer, Rational.fromInt(0));
      second.press(CalculatorKey.answer);
      expect(second.press(CalculatorKey.equals).result, Rational.fromInt(0));
    });
  });

  group('result transitions and exact Ans continuation', () {
    for (final key in [
      CalculatorKey.digit7,
      CalculatorKey.decimal,
      CalculatorKey.leftParenthesis,
      CalculatorKey.rightParenthesis,
      CalculatorKey.negate,
      CalculatorKey.answer,
    ]) {
      test('${key.name} after result starts a fresh one-token expression', () {
        final session = CalculatorSession();
        enter(session, '2+3');
        session.press(CalculatorKey.equals);
        final state = session.press(key);
        expect(state.phase, CalculatorPhase.editing);
        expect(state.tokens, hasLength(1));
        expect(state.cursor, 1);
        expect(state.answer, Rational.fromInt(5));
        expect(state.result, isNull);
        expect(state.error, isNull);
      });
    }

    final continuations = <CalculatorKey, String>{
      CalculatorKey.add: '7/3',
      CalculatorKey.subtract: '-5/3',
      CalculatorKey.multiply: '2/3',
      CalculatorKey.divide: '1/6',
      CalculatorKey.power: '1/9',
    };
    for (final entry in continuations.entries) {
      test('operator ${entry.key.name} continues from exact Ans', () {
        final session = CalculatorSession();
        enter(session, '1/3');
        session.press(CalculatorKey.equals);
        final pending = session.press(entry.key);
        expect(pending.phase, CalculatorPhase.editing);
        expect(pending.tokens, hasLength(2));
        expect(pending.tokens.first, 'Ans');
        expect(pending.cursor, 2);
        expect(pending.cursorOffset, pending.expression.length);
        session.press(CalculatorKey.digit2);
        expect(
          session.press(CalculatorKey.equals).result.toString(),
          entry.value,
        );
      });
    }

    test('a negative fractional answer keeps its grouping when squared', () {
      final session = CalculatorSession();
      enter(session, '-1/2');
      session.press(CalculatorKey.equals);
      session.press(CalculatorKey.power);
      session.press(CalculatorKey.digit2);
      expect(session.press(CalculatorKey.equals).result.toString(), '1/4');
    });

    test('equals in result phase is idempotent, not a repeated operation', () {
      final session = CalculatorSession();
      enter(session, '2+3');
      final before = session.press(CalculatorKey.equals);
      final after = session.press(CalculatorKey.equals);
      expect(after.phase, CalculatorPhase.result);
      expect(after.expression, before.expression);
      expect(after.tokens, before.tokens);
      expect(after.cursor, before.cursor);
      expect(after.answer, Rational.fromInt(5));
      expect(after.result, Rational.fromInt(5));
      expect(after.error, isNull);
    });

    for (final arrow in [CalculatorKey.left, CalculatorKey.right]) {
      test(
        'first ${arrow.name} from result reopens the expression at its end',
        () {
          final session = CalculatorSession();
          enter(session, '12+3');
          session.press(CalculatorKey.equals);
          final reopened = session.press(arrow);
          expect(reopened.phase, CalculatorPhase.editing);
          expect(reopened.expression, '12+3');
          expect(reopened.cursor, reopened.tokens.length);
          expect(reopened.cursorOffset, reopened.expression.length);
          expect(reopened.result, isNull);
          expect(reopened.answer, Rational.fromInt(15));
          session.press(CalculatorKey.left);
          expect(session.snapshot.cursor, reopened.tokens.length - 1);
        },
      );
    }

    test(
      'DEL from result reopens and removes the last token (prototype rule)',
      () {
        final session = CalculatorSession();
        enter(session, '12+3');
        session.press(CalculatorKey.equals);
        final state = session.press(CalculatorKey.delete);
        expect(state.phase, CalculatorPhase.editing);
        expect(state.expression, '12+');
        expect(state.cursor, 3);
        expect(state.answer, Rational.fromInt(15));
        expect(state.result, isNull);
      },
    );

    test('AC clears the editor and result while preserving exact Ans', () {
      final session = CalculatorSession();
      enter(session, '1/3');
      session.press(CalculatorKey.equals);
      final cleared = session.press(CalculatorKey.clear);
      expect(cleared.phase, CalculatorPhase.editing);
      expect(cleared.expression, '');
      expect(cleared.tokens, isEmpty);
      expect(cleared.cursor, 0);
      expect(cleared.cursorOffset, 0);
      expect(cleared.result, isNull);
      expect(cleared.error, isNull);
      expect(cleared.answer.toString(), '1/3');
      session.press(CalculatorKey.answer);
      expect(session.press(CalculatorKey.equals).result.toString(), '1/3');
    });
  });

  group('error transitions and answer persistence', () {
    test('unsupported fractional power is exposed as a session error', () {
      final session = CalculatorSession();
      enter(session, '2^(1/2)');
      final state = session.press(CalculatorKey.equals);
      expect(state.phase, CalculatorPhase.error);
      expect(state.error?.code, CalculatorErrorCode.unsupported);
      expect(state.answer, Rational.fromInt(0));
      expect(state.result, isNull);
    });

    test('math failure does not replace a previous successful answer', () {
      final session = CalculatorSession();
      enter(session, '7');
      session.press(CalculatorKey.equals);
      enter(session, '1/0');
      final error = session.press(CalculatorKey.equals);
      expect(error.phase, CalculatorPhase.error);
      expect(error.expression, '1/0');
      expect(error.error?.code, CalculatorErrorCode.math);
      expect(error.error?.position, 1);
      expect(error.result, isNull);
      expect(error.answer, Rational.fromInt(7));
      final cleared = session.press(CalculatorKey.clear);
      expect(cleared.phase, CalculatorPhase.editing);
      expect(cleared.expression, '');
      expect(cleared.error, isNull);
      expect(cleared.answer, Rational.fromInt(7));
    });

    for (final arrow in [CalculatorKey.left, CalculatorKey.right]) {
      test(
        '${arrow.name} from syntax error restores expression at error offset',
        () {
          final session = CalculatorSession();
          enter(session, '1+*2');
          final failure = session.press(CalculatorKey.equals);
          expect(failure.error?.code, CalculatorErrorCode.syntax);
          expect(failure.error?.position, 2);
          final edit = session.press(arrow);
          expect(edit.phase, CalculatorPhase.editing);
          expect(edit.expression, '1+*2');
          expect(edit.cursor, 2);
          expect(edit.cursorOffset, 2);
          expect(edit.error, isNull);
          session.press(CalculatorKey.right);
          session.press(CalculatorKey.delete);
          expect(session.snapshot.expression, '1+2');
          expect(
            session.press(CalculatorKey.equals).result,
            Rational.fromInt(3),
          );
          expect(failure.phase, CalculatorPhase.error);
          expect(failure.error?.code, CalculatorErrorCode.syntax);
        },
      );
    }

    test('error offset maps across an atomic Ans token', () {
      final session = CalculatorSession();
      session.press(CalculatorKey.answer);
      enter(session, '+*2');
      final error = session.press(CalculatorKey.equals);
      expect(error.error?.code, CalculatorErrorCode.syntax);
      // The displayed source is Ans+*2, so the star begins at offset 4.
      expect(error.error?.position, 4);
      final edit = session.press(CalculatorKey.left);
      expect(edit.expression, 'Ans+*2');
      expect(edit.cursor, 2);
      expect(edit.cursorOffset, 4);
    });

    test('incomplete expression reopens at the end without overshooting', () {
      final session = CalculatorSession();
      enter(session, '1+');
      session.press(CalculatorKey.equals);
      final edit = session.press(CalculatorKey.right);
      expect(edit.phase, CalculatorPhase.editing);
      expect(edit.cursor, 2);
      expect(edit.cursorOffset, 2);
      session.press(CalculatorKey.digit2);
      expect(session.press(CalculatorKey.equals).result, Rational.fromInt(3));
    });

    test('all other supported keys leave the error state unchanged', () {
      final session = CalculatorSession();
      enter(session, '1/0');
      final failed = session.press(CalculatorKey.equals);
      for (final key in CalculatorKey.values.where(
        (key) =>
            key != CalculatorKey.left &&
            key != CalculatorKey.right &&
            key != CalculatorKey.clear,
      )) {
        final state = session.press(key);
        expect(state.phase, CalculatorPhase.error, reason: key.name);
        expect(state.expression, failed.expression, reason: key.name);
        expect(state.cursor, failed.cursor, reason: key.name);
        expect(state.answer, failed.answer, reason: key.name);
        expect(state.result, isNull, reason: key.name);
        expect(state.error?.code, failed.error?.code, reason: key.name);
        expect(state.error?.position, failed.error?.position, reason: key.name);
      }
    });

    test('unknown key IDs cannot bypass result or error state handling', () {
      final session = CalculatorSession();
      enter(session, '7');
      session.press(CalculatorKey.equals);
      for (final source in ['', '1/0']) {
        if (source.isNotEmpty) {
          enter(session, source);
          session.press(CalculatorKey.equals);
        }
        final before = session.snapshot;
        expect(
          () => session.pressId('KEY_SHIFT'),
          throwsA(
            isA<CalculatorException>().having(
              (error) => error.code,
              'code',
              CalculatorErrorCode.unsupported,
            ),
          ),
        );
        final after = session.snapshot;
        expect(after.phase, before.phase);
        expect(after.tokens, before.tokens);
        expect(after.cursor, before.cursor);
        expect(after.answer, before.answer);
        expect(after.result, before.result);
        expect(after.error, before.error);
      }
    });
  });

  group('editor and evaluation resource limits', () {
    test('accepts exactly 2048 characters and rejects the next character', () {
      final session = CalculatorSession();
      enter(session, '7');
      session.press(CalculatorKey.equals);
      session.press(CalculatorKey.clear);
      for (var i = 0; i < 2048; i++) {
        session.press(CalculatorKey.digit1);
      }
      final maximum = session.snapshot;
      expect(maximum.phase, CalculatorPhase.editing);
      expect(maximum.expression.length, 2048);
      expect(maximum.cursor, 2048);
      expect(maximum.cursorOffset, 2048);
      final rejected = session.press(CalculatorKey.digit2);
      expect(rejected.phase, CalculatorPhase.error);
      expect(rejected.error?.code, CalculatorErrorCode.limit);
      expect(rejected.expression, maximum.expression);
      expect(rejected.tokens, maximum.tokens);
      expect(rejected.cursor, maximum.cursor);
      expect(rejected.answer, Rational.fromInt(7));
      expect(rejected.result, isNull);
      final reopened = session.press(CalculatorKey.right);
      expect(reopened.phase, CalculatorPhase.editing);
      expect(reopened.cursor, 2048);
      session.press(CalculatorKey.delete);
      final allowed = session.press(CalculatorKey.digit2);
      expect(allowed.phase, CalculatorPhase.editing);
      expect(allowed.expression.length, 2048);
      expect(allowed.expression.endsWith('12'), isTrue);
      expect(maximum.expression.endsWith('11'), isTrue);
    });

    test('the input budget counts Ans characters, not only logical tokens', () {
      final session = CalculatorSession();
      for (var i = 0; i < 2045; i++) {
        session.press(CalculatorKey.digit1);
      }
      final maximum = session.press(CalculatorKey.answer);
      expect(maximum.phase, CalculatorPhase.editing);
      expect(maximum.tokens.length, 2046);
      expect(maximum.expression.length, 2048);
      expect(maximum.cursor, 2046);
      expect(maximum.cursorOffset, 2048);
      final rejected = session.press(CalculatorKey.digit1);
      expect(rejected.phase, CalculatorPhase.error);
      expect(rejected.error?.code, CalculatorErrorCode.limit);
      expect(rejected.tokens, maximum.tokens);
      final reopened = session.press(CalculatorKey.left);
      expect(reopened.cursor, 2046);
      expect(reopened.cursorOffset, 2048);
      final deleted = session.press(CalculatorKey.delete);
      expect(deleted.expression.length, 2045);
      expect(deleted.cursor, 2045);
      expect(deleted.tokens.contains('Ans'), isFalse);
    });

    test('a literal over the evaluation budget fails only when evaluated', () {
      final session = CalculatorSession();
      for (var i = 0; i < 1001; i++) {
        session.press(CalculatorKey.digit1);
      }
      expect(session.snapshot.phase, CalculatorPhase.editing);
      final error = session.press(CalculatorKey.equals);
      expect(error.phase, CalculatorPhase.error);
      expect(error.error?.code, CalculatorErrorCode.limit);
      expect(error.expression.length, 1001);
      expect(error.answer, Rational.fromInt(0));
      final cleared = session.press(CalculatorKey.clear);
      expect(cleared.phase, CalculatorPhase.editing);
      expect(cleared.expression, '');
      expect(cleared.error, isNull);
    });
  });
}
