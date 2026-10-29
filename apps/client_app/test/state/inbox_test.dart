// Notifications and the tab badges of the client.
import 'package:client_app/app/state/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

import 'state_world.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StateWorld world;
  setUpAll(() async => world = await StateWorld.load());
  setUp(() async => world.fresh());
  tearDown(StateWorld.disposeAll);

  group('notifications', () {
    test('signed out there is nothing to read and nothing is requested', () async {
      final c = world.container();
      world.control.setScenario('error'); // any call would fail
      final s = await c.read(notificationsProvider.future);
      expect(s.items, isEmpty);
      expect(c.read(unreadNotificationsProvider), 0);
    });

    test('Reem reads her list and the unread count; reading one or all is optimistic and written through', () async {
      final c = world.container();
      await c.read(sessionProvider.notifier).loadPersona('reem');
      final s = await c.read(notificationsProvider.future);
      final serverCount = (await world.repos('reem').notifications.getUnreadNotificationCount()).count;
      expect(s.unread, serverCount);
      expect(s.items, isNotEmpty);
      expect(c.read(unreadNotificationsProvider), serverCount);

      final unread = s.items.firstWhere((n) => !n.read);
      final n = c.read(notificationsProvider.notifier);
      final pending = n.markRead(unread.id);
      expect(c.read(unreadNotificationsProvider), serverCount - 1); // before the server answered
      expect((await pending).isSuccess, isTrue);
      expect((await world.repos('reem').notifications.getUnreadNotificationCount()).count, serverCount - 1);

      expect((await n.markAllRead()).isSuccess, isTrue);
      expect(c.read(unreadNotificationsProvider), 0);
      expect((await world.repos('reem').notifications.getUnreadNotificationCount()).count, 0);
      expect(c.read(notificationsProvider).value!.items.every((x) => x.read), isTrue);
    });

    test('a refused read restores the count; a new notification arrives after the refetch', () async {
      final c = world.container();
      await c.read(sessionProvider.notifier).loadPersona('reem');
      final s = await c.read(notificationsProvider.future);
      final unread = s.items.firstWhere((n) => !n.read);
      world.control.setScenario('error');
      final r = await c.read(notificationsProvider.notifier).markRead(unread.id);
      world.control.setScenario('none');
      expect(r.problem, isNotNull);
      expect(c.read(unreadNotificationsProvider), s.unread);

      // the hotel approves; once the undo window closed the client is told
      final hind = world.repos('hotel_manager', venueId: 'V01');
      final hero = await hind.partnerRequests.getPartnerRequest(requestId: heroId);
      await hind.partnerRequests.acceptRequest(requestId: heroId, body: const AcceptRequestInput(), ifMatch: versionTag(hero.booking.version));
      await world.control.flush();
      c.read(notificationsProvider.notifier).refresh();
      final after = await c.read(notificationsProvider.future);
      expect(after.unread, s.unread + 1);
      expect(after.items.any((n) => n.kind == NotificationKind.requestApproved), isTrue);
    });
  });

  group('tab badges', () {
    test('signed out there are no badges', () async {
      final c = world.container(overrides: clientStateOverrides);
      expect(c.read(gzTabBadgesProvider), isEmpty);
    });

    test("Reem's My Wedding gets a dot only while a request waits for her confirmation; Messages counts unread", () async {
      final c = world.container(overrides: clientStateOverrides);
      await c.read(sessionProvider.notifier).loadPersona('reem');
      expect(await c.read(clientActionDueProvider.future), isFalse); // the hero request is pending
      final unreadMessages = await c.read(clientUnreadMessagesProvider.future);
      final expected = (await world.repos('reem').chat.listConversations(unread: true, limit: 50)).items.fold<int>(0, (n, x) => n + x.unread.client);
      expect(unreadMessages, expected);
      expect(c.read(gzTabBadgesProvider).containsKey('my-wedding'), isFalse);

      world.control.jumpToStory('approved');
      c.read(clientDataRevisionProvider.notifier).bump();
      expect(await c.read(clientActionDueProvider.future), isTrue);
      final badges = c.read(gzTabBadgesProvider);
      expect(badges['my-wedding']!.dot, isTrue);
      expect(badges.containsKey('messages'), unreadMessages > 0);
      if (unreadMessages > 0) expect(badges['messages']!.count, unreadMessages);
    });
  });
}
