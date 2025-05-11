import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skylist/main.dart';
import 'package:skylist/pages/home_page.dart';

void main() {
  testWidgets('Navigates to HomePage when Get Started is tapped',
      (WidgetTester tester) async {
    // Siapkan mock SharedPreferences agar tidak error
    SharedPreferences.setMockInitialValues({});

    // Bangun aplikasi
    await tester.pumpWidget(TodoApp());

    // Verifikasi WelcomePage tampil
    expect(find.text('Skylist'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // Tap tombol 'Get Started'
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle(); // Tunggu navigasi selesai

    // Verifikasi HomePage muncul
    expect(find.byType(HomePage), findsOneWidget);
  });
}
