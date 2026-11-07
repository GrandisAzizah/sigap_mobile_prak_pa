import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:MyApp/screens/login_screen.dart';

void main() {
  testWidgets('LoginPage menampilkan field NIM dan Password', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: LoginPage()));

    expect(find.text('NIM'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
s