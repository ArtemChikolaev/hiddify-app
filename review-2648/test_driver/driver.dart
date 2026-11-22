import 'dart:convert';
import 'dart:io';
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() async {
  await integrationDriver(responseDataCallback: (data) async {
    if (data == null || data.length != 16) throw StateError('Missing editor captures');
    final dir = Directory('captures')..createSync(recursive: true);
    for (final item in data.entries) {
      File('${dir.path}/${item.key}.png').writeAsBytesSync(base64Decode(item.value as String));
    }
  });
}
