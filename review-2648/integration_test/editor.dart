import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:hiddify/before.dart' as before;
import 'package:hiddify/features/profile/details/json_editor.dart' as after;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('record tree and text modes on the device', (tester) async {
    final frames = <String, String>{};
    const data = {
      'host': '192.0.2.8',
      'port': 10443,
      'digits': '0123456789',
      'label': 'فارسی ۱۲۳',
    };
    final json = jsonEncode(data);
    for (final lang in ['en', 'fa']) {
      for (final brightness in Brightness.values) {
        for (final version in ['before', 'after']) {
          final captureKey = GlobalKey();
          final editor = version == 'before'
              ? before.JsonEditor(json: json, onChanged: (_) {}, enableHorizontalScroll: true)
              : after.JsonEditor(json: json, onChanged: (_) {}, enableHorizontalScroll: true);
          await tester.pumpWidget(MaterialApp(
            key: UniqueKey(),
            locale: Locale(lang),
            supportedLocales: const [Locale('en'), Locale('fa')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: ThemeData(brightness: brightness, fontFamily: lang == 'fa' ? 'Shabnam' : null),
            home: Scaffold(body: SafeArea(child: Center(child: SizedBox(
              width: Platform.isAndroid ? 480 : 800,
              height: Platform.isAndroid ? 530 : 470,
              child: RepaintBoundary(
                key: captureKey,
                child: Material(child: editor),
              ),
            )))),
          ));
          await tester.pumpAndSettle();
          for (final mode in ['tree', 'text']) {
            if (mode == 'text') {
              await tester.tap(find.byTooltip('Change editor'));
              await tester.pumpAndSettle();
              await tester.tap(find.text('Text'));
              await tester.pumpAndSettle();
              final field = tester.widget<EditableText>(find.byType(EditableText));
              expect(jsonDecode(field.controller.text), data);
              if (version == 'after') expect(field.style.fontFamily, 'monospace');
            } else {
              final value = tester.widget<Text>(find.text('0123456789'));
              if (version == 'after') expect(value.style?.fontFamily, 'monospace');
            }
            final boundary = captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            final result = await boundary.toImage(pixelRatio: 1.25);
            final bytes = await result.toByteData(format: ui.ImageByteFormat.png);
            frames['${brightness.name}-$lang-$mode-$version'] = base64Encode(bytes!.buffer.asUint8List());
            result.dispose();
          }
        }
      }
    }
    binding.reportData = frames;
  });
}
