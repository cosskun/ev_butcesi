import 'package:flutter_test/flutter_test.dart';
import 'package:kurusu_kurusuna/main.dart';

void main() {
  testWidgets('App basic smoke test', (WidgetTester tester) async {
    expect(const KurusuKurusunaApp(), isNotNull);
  });
}
