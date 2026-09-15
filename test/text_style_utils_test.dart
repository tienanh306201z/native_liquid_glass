import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_liquid_glass/src/utils/text_style_utils.dart';

void main() {
  group('textStylePayload', () {
    test('returns null for a null style', () {
      expect(textStylePayload(null), isNull);
    });

    test('returns null when style has no applicable properties', () {
      expect(textStylePayload(const TextStyle()), isNull);
    });

    test('includes color as an ARGB32 int when set', () {
      final payload = textStylePayload(const TextStyle(color: Color(0xFFFF6B6B)));

      expect(payload, isNotNull);
      expect(payload!['color'], const Color(0xFFFF6B6B).toARGB32());
    });

    test('omits color when unset', () {
      final payload = textStylePayload(const TextStyle(fontSize: 20));

      expect(payload, isNotNull);
      expect(payload!.containsKey('color'), isFalse);
    });

    test('combines color with other supported properties', () {
      final payload = textStylePayload(
        const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
          letterSpacing: 0.5,
          color: Color(0xFF112233),
        ),
      );

      expect(
        payload,
        <String, Object?>{
          'fontSize': 18.0,
          'fontWeight': 600,
          'fontFamily': 'Inter',
          'letterSpacing': 0.5,
          'color': const Color(0xFF112233).toARGB32(),
        },
      );
    });
  });

  group('textStyleSignature', () {
    test('changes when only color changes', () {
      final a = textStyleSignature(const TextStyle(fontSize: 16, color: Color(0xFFFFFFFF)));
      final b = textStyleSignature(const TextStyle(fontSize: 16, color: Color(0xFF000000)));

      expect(a, isNot(equals(b)));
    });

    test('matches for styles with the same color', () {
      final a = textStyleSignature(const TextStyle(fontSize: 16, color: Color(0xFF123456)));
      final b = textStyleSignature(const TextStyle(fontSize: 16, color: Color(0xFF123456)));

      expect(a, equals(b));
    });

    test('is zero for a null style', () {
      expect(textStyleSignature(null), 0);
    });
  });
}
