import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashUtil {
  HashUtil._();

  static String sha256Of(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
