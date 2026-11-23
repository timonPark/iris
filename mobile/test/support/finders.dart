import 'package:flutter_test/flutter_test.dart';
import 'package:iris/widgets/form_parts.dart';
import 'package:material_ui/material_ui.dart';

/// 라벨이 [label]인 입력칸.
Finder fieldFor(String label) {
  return find.descendant(
    of: find.widgetWithText(LabeledField, label),
    matching: find.byType(TextField),
  );
}
