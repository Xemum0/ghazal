import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show ThreadRole;
import 'package:ghazal_ui/src/client/client_c.dart';

import '../client/client_c_fixtures.dart';
import '../core/core_harness.dart';
import '../shared/shared_harness.dart';

void main() {
  setUpAll(loadUiFonts);

  testWidgets('chat bubble in a visit group (web HL-VIST-03 ar: 350 wide, sender 30, body 76, meta 4, total 118)', (tester) async {
    await pumpCore(
      tester,
      SizedBox(
        width: 350,
        child: GzChatBubble(
          message: message(from: 'client', ar: 'السلام عليكم، نبي نزور القاعة يوم السبت الساعة 6 مساءً مع الوالدة وأخواتي.', en: 'x'),
          side: GzChatSide.hotel,
          sender: const GzChatSender(name: 'راشد العجمي', role: ThreadRole.client),
        ),
      ),
      lang: 'ar',
      size: const Size(390, 800),
    );
    expect(tester.getSize(find.byType(GzChatBubble)).height, 118);
  });

  testWidgets('chat bubble, Arabic text in the English UI (web HL-VIST-03 en: sender 26, body 76, meta 4, total 114)', (tester) async {
    await pumpCore(
      tester,
      SizedBox(
        width: 350,
        child: GzChatBubble(
          message: message(from: 'client', ar: 'السلام عليكم، نبي نزور القاعة يوم السبت الساعة 6 مساءً مع الوالدة وأخواتي.', en: 'x'),
          side: GzChatSide.hotel,
          sender: const GzChatSender(name: 'Rashed Al-Ajmi', role: ThreadRole.client),
        ),
      ),
      lang: 'en',
      size: const Size(390, 800),
    );
    expect(tester.getSize(find.byType(GzChatBubble)).height, 114);
  });
}
