import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathplayer/services/subsonic_auth.dart';

void main() {
  group('SubsonicAuth', () {
    test('generateSalt returns a 16 character hex string', () {
      final salt = SubsonicAuth.generateSalt();
      expect(salt.length, 16);
      expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(salt), isTrue);
    });

    test('token computes md5(password + salt)', () {
      const password = 'YOUR_PASSWORD';
      const salt = 'abcd1234';
      final expected = md5.convert('$password$salt'.codeUnits).toString();
      expect(SubsonicAuth.token(password, salt), expected);
    });
  });
}
