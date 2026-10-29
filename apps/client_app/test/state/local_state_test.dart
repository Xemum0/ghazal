// Compare, the Brief, the wedding profile and the booking draft: the state that lives on the device or in the flow.
import 'package:client_app/app/state/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'state_world.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StateWorld world;
  setUpAll(() async => world = await StateWorld.load());
  setUp(() async => world.fresh());
  tearDown(StateWorld.disposeAll);

  group('compare', () {
    test('adds up to three, says exists and full, replaces, removes, clears', () {
      final c = world.container();
      final n = c.read(compareProvider.notifier);
      expect(n.add('V01'), CompareResult.added);
      expect(n.add('V01'), CompareResult.exists);
      expect(n.add('V02'), CompareResult.added);
      expect(c.read(compareProvider).canCompare, isTrue);
      expect(n.add('V03'), CompareResult.added);
      expect(c.read(compareProvider).isFull, isTrue);
      expect(n.add('V04'), CompareResult.full);
      expect(c.read(compareProvider).venueIds, ['V01', 'V02', 'V03']);

      n.replace('V02', 'V04');
      expect(c.read(compareProvider).venueIds, ['V01', 'V04', 'V03']);
      n.replace('V01', 'V03'); // already in the tray: nothing changes
      expect(c.read(compareProvider).venueIds, ['V01', 'V04', 'V03']);
      n.remove('V04');
      expect(c.read(compareProvider).venueIds, ['V01', 'V03']);
      n.clear();
      expect(c.read(compareProvider).isEmpty, isTrue);
    });

    test('setAll de-duplicates and cuts to three; toggle removes or adds', () {
      final c = world.container();
      final n = c.read(compareProvider.notifier);
      n.setAll(['V01', 'V01', 'V02', 'V03', 'V04']);
      expect(c.read(compareProvider).venueIds, ['V01', 'V02', 'V03']);
      n.toggle('V02');
      expect(c.read(compareProvider).venueIds, ['V01', 'V03']);
      expect(n.toggle('V09'), CompareResult.added);
    });
  });

  group('search brief', () {
    test('edits, persists across an app start, fills only blanks, clears', () async {
      final prefs = await SharedPreferences.getInstance();
      final c = world.container(prefs: prefs);
      expect(c.read(searchBriefProvider).isEmpty, isTrue);
      c
          .read(searchBriefProvider.notifier)
          .update(
            (b) => b.copyWith(
              date: LocalDate.parse('2027-01-14'),
              guests: 350,
              audience: Audience.women,
              governorateIds: const ['hawalli'],
              budget: const MoneyRange(min: MoneyAmount(20000000), max: MoneyAmount(35000000)),
              dateMode: DateMode.exact,
            ),
          );
      final b = c.read(searchBriefProvider);
      expect(b.hasQuoteInputs, isTrue);

      final restarted = world.container(prefs: prefs);
      expect(restarted.read(searchBriefProvider), b);

      restarted.read(searchBriefProvider.notifier).fillBlanks(SearchBrief.empty.copyWith(guests: 10, governorateIds: const ['capital']));
      expect(restarted.read(searchBriefProvider).guests, 350); // never overwritten
      expect(restarted.read(searchBriefProvider).governorateIds, ['hawalli']);
      restarted.read(searchBriefProvider.notifier).update((b) => b.copyWith(clearDate: true));
      expect(restarted.read(searchBriefProvider).date, isNull);
      restarted.read(searchBriefProvider.notifier).clear();
      expect(restarted.read(searchBriefProvider).isEmpty, isTrue);
      expect(world.container(prefs: prefs).read(searchBriefProvider).isEmpty, isTrue);
    });
  });

  group('wedding profile', () {
    test("Reem's profile loads and a patch changes it on the server", () async {
      final c = world.container();
      await c.read(sessionProvider.notifier).loadPersona('reem');
      final p = await c.read(weddingProfileProvider.future);
      expect(p, isNotNull);
      expect(p!.weddingDate, LocalDate.parse('2027-01-14'));
      expect(p.guests.women, 350);

      final saved = await c.read(weddingProfileProvider.notifier).patch(const WeddingProfileInput(guests: GuestSplit(women: 300, men: 120)));
      expect(saved!.guests.women, 300);
      expect(c.read(weddingProfileProvider).value!.guests.men, 120);
      expect((await world.repos('reem').wedding.getWeddingProfile()).guests.women, 300);
    });

    test('sign-in as Reem seeds an empty Brief from her profile on the first GET (14 Jan 2027, Hawalli and Capital, 350, KD 20,000 to 35,000)', () async {
      final c = world.container();
      expect(c.read(searchBriefProvider).isEmpty, isTrue);
      await c.read(sessionProvider.notifier).loadPersona('reem');
      await c.read(weddingProfileProvider.future);
      final b = c.read(searchBriefProvider);
      expect(b.date, LocalDate.parse('2027-01-14'));
      expect(b.guests, 350);
      expect(b.governorateIds, ['hawalli', 'capital']);
      expect(b.budget, const MoneyRange(min: MoneyAmount(20000000), max: MoneyAmount(35000000)));
    });

    test('the seed is once: a Brief the person changed is never overwritten, and Clear does not bring the profile back on a refetch', () async {
      final c = world.container();
      c.read(searchBriefProvider.notifier).update((b) => b.copyWith(guests: 120));
      await c.read(sessionProvider.notifier).loadPersona('reem');
      await c.read(weddingProfileProvider.future);
      expect(c.read(searchBriefProvider).guests, 120, reason: 'the guests the person set stay');
      expect(c.read(searchBriefProvider).date, LocalDate.parse('2027-01-14'), reason: 'a blank is filled');

      c.read(searchBriefProvider.notifier).clear();
      c.invalidate(weddingProfileProvider);
      await c.read(weddingProfileProvider.future);
      expect(c.read(searchBriefProvider).isEmpty, isTrue, reason: 'one seed per account per run');
    });

    test('a new client has none (null: the empty state); the first optional step creates it and fills the blanks of the Brief', () async {
      final c = world.container();
      await c.read(sessionProvider.notifier).loadPersona('new_client');
      expect(await c.read(weddingProfileProvider.future), isNull);
      expect(c.read(searchBriefProvider).isEmpty, isTrue);
      final saved = await c
          .read(weddingProfileProvider.notifier)
          .save(
            WeddingProfileInput(
              role: WeddingRole.bride,
              brideName: 'Nora',
              weddingDate: LocalDate.parse('2027-03-04'),
              dateMode: DateMode.exact,
              guests: const GuestSplit(women: 200, men: 100),
              venueBudget: const MoneyRange(min: MoneyAmount(10000000), max: MoneyAmount(20000000)),
              totalBudget: const MoneyAmount(40000000),
              governorateIds: const <String>['hawalli'],
              searching: const [Audience.women],
            ),
          );
      expect(saved!.brideName, 'Nora');
      expect(c.read(searchBriefProvider).guests, 200);
      expect(c.read(searchBriefProvider).governorateIds, ['hawalli']);
      expect((await world.repos('new_client').wedding.getWeddingProfile()).guests.women, 200);
    });
  });

  group('booking draft', () {
    test('start seeds from the Brief and the signed-in client; the draft knows what is missing and builds the request body', () async {
      final c = world.container();
      await c.read(sessionProvider.notifier).loadPersona('reem');
      c.read(searchBriefProvider.notifier).set(SearchBrief(date: LocalDate.parse('2027-01-14'), guests: 350, audience: Audience.women));
      c.read(bookingDraftProvider.notifier).start(venueId: 'V01', packageId: 'pkg-1');
      final d = c.read(bookingDraftProvider);
      expect(d.eventDate, LocalDate.parse('2027-01-14'));
      expect(d.guests, 350);
      expect(d.personal.name, isNotEmpty);
      expect(d.missing, ['hallId', 'sessionId']);
      expect(() => d.toCreateRequestInput(voucherId: 'v'), throwsStateError);

      c.read(bookingDraftProvider.notifier)
        .patch((x) => x.copyWith(hallId: 'V01-danah', sessionId: 'V01-danah-evening'));
      final ready = c.read(bookingDraftProvider);
      expect(ready.isComplete, isTrue);
      final body = ready.toCreateRequestInput(voucherId: 'voucher-1');
      expect(body.sections!.single.hallId, 'V01-danah');
      expect(body.sections!.single.guests, 350);
      expect(body.extras, anyOf(isNull, isEmpty), reason: 'extras are retired (ADR 0038 D2)');
      expect(body.voucherId, 'voucher-1');
      expect(body.contact.shared, isTrue);
      expect(ready.toCheckoutInput().targetId, 'V01');

      // a stale checkout is dropped when the quote inputs change
      final bound = ready.copyWith(voucherId: 'voucher-1', quoteId: 'q1');
      expect(bound.copyWith(guests: 300, clearVoucher: true).voucherId, isNull);
    });

    test('a service request carries a listing and a quantity', () {
      final c = world.container();
      c
          .read(bookingDraftProvider.notifier)
          .start(providerId: 'P01', listingId: 'L01', packageId: 'pk', eventDate: LocalDate.parse('2027-02-01'), guests: 2);
      final d = c.read(bookingDraftProvider);
      expect(d.isProvider, isTrue);
      final body = d.toCreateRequestInput(voucherId: 'v1');
      expect(body.service!.quantity, 2);
      expect(body.sections, isNull);
      expect(d.toCheckoutInput().targetType, VoucherTargetType.provider);
    });

    test('signing out clears the draft', () async {
      final c = world.container();
      c.read(bookingDraftProvider.notifier).start(venueId: 'V01', packageId: 'p');
      await c.read(sessionProvider.notifier).loadPersona('reem');
      expect(c.read(bookingDraftProvider).venueId, 'V01');
      await c.read(sessionProvider.notifier).signOut();
      expect(c.read(bookingDraftProvider), BookingDraft.empty);
    });
  });
}
