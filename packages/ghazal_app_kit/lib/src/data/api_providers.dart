import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_api/ghazal_api.dart';
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

import '../session/session_notifier.dart';
import 'client_environment.dart';
import 'mock_backend.dart';

/// The provider retry of the apps: none. Riverpod 3 retries a failed provider up to ten times by default (200 ms doubling), which would
/// keep a screen in "loading" while a failure is already known. A transient network error is retried once, below, by the HTTP client
/// (`RetryPolicy`: idempotent GETs only); after that the screen shows its error state and the user's Retry button asks again.
/// Pass it to the root `ProviderScope(retry: gzProviderRetry)` / `ProviderContainer(retry: gzProviderRetry)`.
Duration? gzProviderRetry(int retryCount, Object error) => null;

/// The base URL the in-process mock answers on (the `GzApiConfig` default).
const String kMockBaseUrl = 'http://mock.ghazal.local/v1';

/// Bumped when the world behind the API changes under the app (the demo tools switch persona, reset the story, jump or move the clock):
/// the client and every repository provider rebuild, so each screen's data provider refetches.
final NotifierProvider<BackendEpoch, int> backendEpochProvider = NotifierProvider<BackendEpoch, int>(BackendEpoch.new);

class BackendEpoch extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

/// The one HTTP client: the in-process mock adapter when `USE_MOCK` is on and a backend exists, otherwise the real `API_BASE_URL`.
/// Tokens come from [tokenStoreProvider], language and partner context from [clientEnvironmentProvider]; a revoked session or a failed
/// refresh signs the app out.
/// The retry policy of the API client (ADR 0022 C): idempotent GETs retry with timers. Shots and tests of error and offline states
/// override it with `RetryPolicy.none`, so no retry timer outlives the screen (and the state shows at once).
final Provider<RetryPolicy> gzRetryPolicyProvider = Provider<RetryPolicy>((ref) => const RetryPolicy());

final Provider<GzApiClient> apiClientProvider = Provider<GzApiClient>((ref) {
  ref.watch(backendEpochProvider);
  final env = ref.watch(appEnvProvider);
  final mock = env.useMock ? ref.watch(mockBackendProvider) : null;
  final client = GzApiClient.create(
    config: GzApiConfig(baseUrl: mock != null ? kMockBaseUrl : env.apiBaseUrl, useMock: mock != null),
    environment: ref.watch(clientEnvironmentProvider),
    tokens: ref.watch(tokenStoreProvider),
    adapter: mock?.httpClientAdapter,
    retry: ref.watch(gzRetryPolicyProvider),
    onSessionEnded: () => ref.read(sessionProvider.notifier).endedByServer(),
  );
  ref.onDispose(() => client.dio.close(force: true));
  return client;
});

/// Every REST repository over [apiClientProvider]. Screens read the per-repository providers below, not this.
final Provider<RestRepositories> repositoriesProvider = Provider<RestRepositories>((ref) => RestRepositories(ref.watch(apiClientProvider)));

// One provider per repository, typed as the domain interface, so a test overrides it with a fake.

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>((ref) => ref.watch(repositoriesProvider).auth);
final Provider<HomeRepository> homeRepositoryProvider = Provider<HomeRepository>((ref) => ref.watch(repositoriesProvider).home);
final Provider<VenuesRepository> venuesRepositoryProvider = Provider<VenuesRepository>((ref) => ref.watch(repositoriesProvider).venues);
final Provider<VouchersRepository> vouchersRepositoryProvider = Provider<VouchersRepository>((ref) => ref.watch(repositoriesProvider).vouchers);
final Provider<RequestsRepository> requestsRepositoryProvider = Provider<RequestsRepository>((ref) => ref.watch(repositoriesProvider).requests);
final Provider<VisitsRepository> visitsRepositoryProvider = Provider<VisitsRepository>((ref) => ref.watch(repositoriesProvider).visits);
final Provider<ChatRepository> chatRepositoryProvider = Provider<ChatRepository>((ref) => ref.watch(repositoriesProvider).chat);
final Provider<NotificationsRepository> notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) => ref.watch(repositoriesProvider).notifications);
final Provider<ReviewsRepository> reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) => ref.watch(repositoriesProvider).reviews);
final Provider<WeddingRepository> weddingRepositoryProvider = Provider<WeddingRepository>((ref) => ref.watch(repositoriesProvider).wedding);
final Provider<ServicesRepository> servicesRepositoryProvider = Provider<ServicesRepository>((ref) => ref.watch(repositoriesProvider).services);
final Provider<PlannersRepository> plannersRepositoryProvider = Provider<PlannersRepository>((ref) => ref.watch(repositoriesProvider).planners);
final Provider<ProfileRepository> profileRepositoryProvider = Provider<ProfileRepository>((ref) => ref.watch(repositoriesProvider).profile);
final Provider<SupportRepository> supportRepositoryProvider = Provider<SupportRepository>((ref) => ref.watch(repositoriesProvider).support);
final Provider<PartnerAccountRepository> partnerAccountRepositoryProvider =
    Provider<PartnerAccountRepository>((ref) => ref.watch(repositoriesProvider).partnerAccount);
final Provider<PartnerRequestsRepository> partnerRequestsRepositoryProvider =
    Provider<PartnerRequestsRepository>((ref) => ref.watch(repositoriesProvider).partnerRequests);
final Provider<PartnerBookingsRepository> partnerBookingsRepositoryProvider =
    Provider<PartnerBookingsRepository>((ref) => ref.watch(repositoriesProvider).partnerBookings);
final Provider<PartnerCalendarRepository> partnerCalendarRepositoryProvider =
    Provider<PartnerCalendarRepository>((ref) => ref.watch(repositoriesProvider).partnerCalendar);
final Provider<PartnerVenueRepository> partnerVenueRepositoryProvider =
    Provider<PartnerVenueRepository>((ref) => ref.watch(repositoriesProvider).partnerVenue);
final Provider<PartnerVisitsRepository> partnerVisitsRepositoryProvider =
    Provider<PartnerVisitsRepository>((ref) => ref.watch(repositoriesProvider).partnerVisits);
final Provider<PartnerGrowthRepository> partnerGrowthRepositoryProvider =
    Provider<PartnerGrowthRepository>((ref) => ref.watch(repositoriesProvider).partnerGrowth);
final Provider<PartnerListingsRepository> partnerListingsRepositoryProvider =
    Provider<PartnerListingsRepository>((ref) => ref.watch(repositoriesProvider).partnerListings);
final Provider<PartnerReviewsRepository> partnerReviewsRepositoryProvider =
    Provider<PartnerReviewsRepository>((ref) => ref.watch(repositoriesProvider).partnerReviews);
