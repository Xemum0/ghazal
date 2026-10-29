import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar'), Locale('en')];

  /// No description provided for @commonActionAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get commonActionAccept;

  /// No description provided for @commonActionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonActionAdd;

  /// No description provided for @commonActionApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonActionApply;

  /// No description provided for @commonActionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonActionBack;

  /// No description provided for @commonActionCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get commonActionCall;

  /// No description provided for @commonActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonActionCancel;

  /// No description provided for @commonActionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonActionClear;

  /// No description provided for @commonActionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonActionClose;

  /// No description provided for @commonActionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonActionConfirm;

  /// No description provided for @commonActionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonActionContinue;

  /// No description provided for @commonActionDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get commonActionDecline;

  /// No description provided for @commonActionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonActionDone;

  /// No description provided for @commonActionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonActionEdit;

  /// No description provided for @commonActionMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get commonActionMessage;

  /// No description provided for @commonActionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonActionNext;

  /// No description provided for @commonActionOpenWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Open WhatsApp'**
  String get commonActionOpenWhatsapp;

  /// No description provided for @commonActionPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get commonActionPrevious;

  /// No description provided for @commonActionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonActionRemove;

  /// No description provided for @commonActionReschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get commonActionReschedule;

  /// No description provided for @commonActionReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonActionReset;

  /// No description provided for @commonActionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonActionRetry;

  /// No description provided for @commonActionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonActionSave;

  /// No description provided for @commonActionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonActionSearch;

  /// No description provided for @commonActionSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get commonActionSeeAll;

  /// No description provided for @commonActionSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get commonActionSend;

  /// No description provided for @commonActionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonActionShare;

  /// No description provided for @commonActionShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get commonActionShowLess;

  /// No description provided for @commonActionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonActionSkip;

  /// No description provided for @commonActionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonActionUndo;

  /// No description provided for @commonActionWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get commonActionWhatsapp;

  /// No description provided for @commonAvailabilityAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get commonAvailabilityAvailable;

  /// No description provided for @commonAvailabilityBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get commonAvailabilityBlocked;

  /// No description provided for @commonAvailabilityBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get commonAvailabilityBooked;

  /// No description provided for @commonAvailabilityFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get commonAvailabilityFree;

  /// No description provided for @commonAvailabilityHeld.
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get commonAvailabilityHeld;

  /// No description provided for @commonAvailabilityPast.
  ///
  /// In en, this message translates to:
  /// **'Past date'**
  String get commonAvailabilityPast;

  /// No description provided for @commonAvailabilityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get commonAvailabilityUnavailable;

  /// No description provided for @commonAvailabilityLineFree.
  ///
  /// In en, this message translates to:
  /// **'{date} · Free'**
  String commonAvailabilityLineFree(String date);

  /// No description provided for @commonAvailabilityLineBooked.
  ///
  /// In en, this message translates to:
  /// **'{date} · Booked'**
  String commonAvailabilityLineBooked(String date);

  /// No description provided for @commonCalendarAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get commonCalendarAvailability;

  /// No description provided for @commonCalendarPrices.
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get commonCalendarPrices;

  /// No description provided for @commonCalendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonCalendarToday;

  /// No description provided for @commonCalendarSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get commonCalendarSelected;

  /// No description provided for @commonCalendarPeak.
  ///
  /// In en, this message translates to:
  /// **'Peak days'**
  String get commonCalendarPeak;

  /// No description provided for @commonCalendarPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get commonCalendarPreviousMonth;

  /// No description provided for @commonCalendarNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get commonCalendarNextMonth;

  /// No description provided for @commonCalendarOccasionApproximate.
  ///
  /// In en, this message translates to:
  /// **'{occasion} (approx.)'**
  String commonCalendarOccasionApproximate(String occasion);

  /// No description provided for @commonStatusRequested.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get commonStatusRequested;

  /// No description provided for @commonStatusAwaitingDeposit.
  ///
  /// In en, this message translates to:
  /// **'Approved · deposit due'**
  String get commonStatusAwaitingDeposit;

  /// No description provided for @commonStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get commonStatusConfirmed;

  /// No description provided for @commonStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Not accepted'**
  String get commonStatusRejected;

  /// No description provided for @commonStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get commonStatusExpired;

  /// No description provided for @commonStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get commonStatusCancelled;

  /// No description provided for @commonStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get commonStatusCompleted;

  /// No description provided for @commonStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get commonStatusRefunded;

  /// No description provided for @commonStatusNoShow.
  ///
  /// In en, this message translates to:
  /// **'No-show'**
  String get commonStatusNoShow;

  /// No description provided for @commonStatusHeadlineConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed booking'**
  String get commonStatusHeadlineConfirmed;

  /// No description provided for @commonStatusCancelledByYou.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by you'**
  String get commonStatusCancelledByYou;

  /// No description provided for @commonStatusCancelledByVenue.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by the venue'**
  String get commonStatusCancelledByVenue;

  /// No description provided for @commonStatusHotelMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get commonStatusHotelMissed;

  /// No description provided for @commonStatusUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get commonStatusUrgent;

  /// No description provided for @commonStatusTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} remaining'**
  String commonStatusTimeLeft(String time);

  /// No description provided for @commonFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonFilterAll;

  /// No description provided for @commonTierWeekday.
  ///
  /// In en, this message translates to:
  /// **'Weekday'**
  String get commonTierWeekday;

  /// No description provided for @commonTierWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get commonTierWeekend;

  /// No description provided for @commonTierHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get commonTierHoliday;

  /// No description provided for @commonTierSeason.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get commonTierSeason;

  /// No description provided for @commonTierSpecialDate.
  ///
  /// In en, this message translates to:
  /// **'Special date'**
  String get commonTierSpecialDate;

  /// No description provided for @commonUnitPerGuest.
  ///
  /// In en, this message translates to:
  /// **'per guest'**
  String get commonUnitPerGuest;

  /// No description provided for @commonUnitPerNight.
  ///
  /// In en, this message translates to:
  /// **'per night'**
  String get commonUnitPerNight;

  /// No description provided for @commonUnitPerDay.
  ///
  /// In en, this message translates to:
  /// **'per day'**
  String get commonUnitPerDay;

  /// No description provided for @commonUnitPerHour.
  ///
  /// In en, this message translates to:
  /// **'per hour'**
  String get commonUnitPerHour;

  /// No description provided for @commonUnitMinGuests.
  ///
  /// In en, this message translates to:
  /// **'Minimum {count, plural, one{{count} guest} other{{count} guests}}'**
  String commonUnitMinGuests(int count);

  /// No description provided for @commonUnitUpToGuests.
  ///
  /// In en, this message translates to:
  /// **'Up to {count, plural, one{{count} guest} other{{count} guests}}'**
  String commonUnitUpToGuests(int count);

  /// No description provided for @commonCountGuests.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No guests} one{{count} guest} other{{count} guests}}'**
  String commonCountGuests(int count);

  /// No description provided for @commonCountDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No days} one{{count} day} other{{count} days}}'**
  String commonCountDays(int count);

  /// No description provided for @commonCountHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No hours} one{{count} hour} other{{count} hours}}'**
  String commonCountHours(int count);

  /// No description provided for @commonCountMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No minutes} one{{count} minute} other{{count} minutes}}'**
  String commonCountMinutes(int count);

  /// No description provided for @commonCountHalls.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No halls} one{{count} hall} other{{count} halls}}'**
  String commonCountHalls(int count);

  /// No description provided for @commonCountPackages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No packages} one{{count} package} other{{count} packages}}'**
  String commonCountPackages(int count);

  /// No description provided for @commonCountMessages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No messages} one{{count} message} other{{count} messages}}'**
  String commonCountMessages(int count);

  /// No description provided for @commonCountBookings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No bookings} one{{count} booking} other{{count} bookings}}'**
  String commonCountBookings(int count);

  /// No description provided for @commonCountSessions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sessions} one{{count} session} other{{count} sessions}}'**
  String commonCountSessions(int count);

  /// No description provided for @commonCountMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No months} one{{count} month} other{{count} months}}'**
  String commonCountMonths(int count);

  /// No description provided for @commonCountDates.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No dates} one{{count} date} other{{count} dates}}'**
  String commonCountDates(int count);

  /// No description provided for @commonCountRequests.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No requests} one{{count} request} other{{count} requests}}'**
  String commonCountRequests(int count);

  /// No description provided for @commonCountReviews.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No reviews} one{{count} review} other{{count} reviews}}'**
  String commonCountReviews(int count);

  /// No description provided for @commonCountPhotos.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No photos} one{{count} photo} other{{count} photos}}'**
  String commonCountPhotos(int count);

  /// No description provided for @commonCountdownDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Today} one{{count} day to go} other{{count} days to go}}'**
  String commonCountdownDays(int count);

  /// No description provided for @commonCounter.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String commonCounter(num current, num total);

  /// No description provided for @commonStateLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get commonStateLoading;

  /// No description provided for @commonStateTitleGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonStateTitleGeneric;

  /// No description provided for @commonStateTitleLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load'**
  String get commonStateTitleLoad;

  /// No description provided for @commonStateTitleNetwork.
  ///
  /// In en, this message translates to:
  /// **'You’re offline'**
  String get commonStateTitleNetwork;

  /// No description provided for @commonStateTitlePayment.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get commonStateTitlePayment;

  /// No description provided for @commonStateTitleNoAccess.
  ///
  /// In en, this message translates to:
  /// **'No access'**
  String get commonStateTitleNoAccess;

  /// No description provided for @commonStateTitleNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get commonStateTitleNotFound;

  /// No description provided for @commonStateTitleEmptySearch.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get commonStateTitleEmptySearch;

  /// No description provided for @commonStateTitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get commonStateTitleEmpty;

  /// No description provided for @commonStateOffline.
  ///
  /// In en, this message translates to:
  /// **'You’re offline'**
  String get commonStateOffline;

  /// No description provided for @commonStateErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Nothing was changed. Please try again.'**
  String get commonStateErrorGeneric;

  /// No description provided for @commonStateErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load this. Please try again.'**
  String get commonStateErrorLoad;

  /// No description provided for @commonStateErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t connect. Check your connection and try again.'**
  String get commonStateErrorNetwork;

  /// No description provided for @commonStateErrorPayment.
  ///
  /// In en, this message translates to:
  /// **'The payment could not be completed. No amount was charged.'**
  String get commonStateErrorPayment;

  /// No description provided for @commonStateErrorNoAccess.
  ///
  /// In en, this message translates to:
  /// **'You do not have access. Ask your manager.'**
  String get commonStateErrorNoAccess;

  /// No description provided for @commonStateErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'This page is no longer available.'**
  String get commonStateErrorNotFound;

  /// No description provided for @commonStateSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get commonStateSaved;

  /// No description provided for @commonStateCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get commonStateCopied;

  /// No description provided for @commonStateSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get commonStateSent;

  /// No description provided for @commonNoPaymentNowFull.
  ///
  /// In en, this message translates to:
  /// **'No payment now. Nothing is charged until the hotel approves.'**
  String get commonNoPaymentNowFull;

  /// No description provided for @commonMoneyDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get commonMoneyDeposit;

  /// No description provided for @commonMoneyBalance.
  ///
  /// In en, this message translates to:
  /// **'Remaining balance'**
  String get commonMoneyBalance;

  /// No description provided for @commonMoneyTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get commonMoneyTotal;

  /// No description provided for @commonMoneyServiceCharge.
  ///
  /// In en, this message translates to:
  /// **'Service charge'**
  String get commonMoneyServiceCharge;

  /// No description provided for @commonMoneyRentalFee.
  ///
  /// In en, this message translates to:
  /// **'Rental fee'**
  String get commonMoneyRentalFee;

  /// No description provided for @commonLabelOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get commonLabelOptional;

  /// No description provided for @commonLabelRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonLabelRequired;

  /// No description provided for @commonLabelNotDecided.
  ///
  /// In en, this message translates to:
  /// **'Not decided'**
  String get commonLabelNotDecided;

  /// No description provided for @commonLabelToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonLabelToday;

  /// No description provided for @commonLabelTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get commonLabelTomorrow;

  /// No description provided for @commonLabelKuwaitTime.
  ///
  /// In en, this message translates to:
  /// **'Kuwait time'**
  String get commonLabelKuwaitTime;

  /// No description provided for @commonLabelSponsored.
  ///
  /// In en, this message translates to:
  /// **'Sponsored'**
  String get commonLabelSponsored;

  /// No description provided for @commonLabelNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get commonLabelNew;

  /// No description provided for @commonLabelOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get commonLabelOr;

  /// No description provided for @commonLabelLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get commonLabelLanguage;

  /// No description provided for @commonLabelSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get commonLabelSettings;

  /// No description provided for @commonLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get commonLanguageEnglish;

  /// No description provided for @commonLanguageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get commonLanguageArabic;

  /// No description provided for @commonFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get commonFieldRequired;

  /// No description provided for @commonFieldInvalid.
  ///
  /// In en, this message translates to:
  /// **'This value isn’t valid.'**
  String get commonFieldInvalid;

  /// No description provided for @commonFieldPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'This phone number isn’t valid.'**
  String get commonFieldPhoneInvalid;

  /// No description provided for @commonA11yFavouriteAdd.
  ///
  /// In en, this message translates to:
  /// **'Save to favourites'**
  String get commonA11yFavouriteAdd;

  /// No description provided for @commonA11yFavouriteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get commonA11yFavouriteRemove;

  /// No description provided for @commonA11yCompareAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to compare'**
  String get commonA11yCompareAdd;

  /// No description provided for @commonA11yCompareRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from compare'**
  String get commonA11yCompareRemove;

  /// No description provided for @commonA11yPhotoCounter.
  ///
  /// In en, this message translates to:
  /// **'Photo {current} of {total}'**
  String commonA11yPhotoCounter(num current, num total);

  /// No description provided for @commonA11yRating.
  ///
  /// In en, this message translates to:
  /// **'Rated {rating} out of {max}'**
  String commonA11yRating(num rating, num max);

  /// No description provided for @commonA11ySelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get commonA11ySelected;

  /// No description provided for @commonStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get commonStatusPending;

  /// No description provided for @commonStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get commonStatusApproved;

  /// No description provided for @commonStatusRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Redeemed'**
  String get commonStatusRedeemed;

  /// No description provided for @commonStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get commonStatusDeclined;

  /// No description provided for @commonStatusHotelPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get commonStatusHotelPending;

  /// No description provided for @commonStatusHotelApproved.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get commonStatusHotelApproved;

  /// No description provided for @commonStatusHotelRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Redeemed'**
  String get commonStatusHotelRedeemed;

  /// No description provided for @commonStatusHotelDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get commonStatusHotelDeclined;

  /// No description provided for @commonStatusHotelLapsed.
  ///
  /// In en, this message translates to:
  /// **'Lapsed'**
  String get commonStatusHotelLapsed;

  /// No description provided for @commonStatusDateProposed.
  ///
  /// In en, this message translates to:
  /// **'New date'**
  String get commonStatusDateProposed;

  /// No description provided for @commonVoucherStatusUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Paying'**
  String get commonVoucherStatusUnpaid;

  /// No description provided for @commonVoucherStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get commonVoucherStatusActive;

  /// No description provided for @commonVoucherStatusBound.
  ///
  /// In en, this message translates to:
  /// **'In request'**
  String get commonVoucherStatusBound;

  /// No description provided for @commonVoucherStatusUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get commonVoucherStatusUsed;

  /// No description provided for @commonVoucherStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get commonVoucherStatusExpired;

  /// No description provided for @commonVisitStatusRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get commonVisitStatusRequested;

  /// No description provided for @commonVisitStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get commonVisitStatusConfirmed;

  /// No description provided for @commonVisitStatusReschedule.
  ///
  /// In en, this message translates to:
  /// **'New time'**
  String get commonVisitStatusReschedule;

  /// No description provided for @commonVisitStatusArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get commonVisitStatusArrived;

  /// No description provided for @commonVisitStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonVisitStatusCompleted;

  /// No description provided for @commonVisitStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get commonVisitStatusDeclined;

  /// No description provided for @commonVisitStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get commonVisitStatusCancelled;

  /// No description provided for @commonVisitStatusMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get commonVisitStatusMissed;

  /// No description provided for @commonListingStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get commonListingStatusDraft;

  /// No description provided for @commonListingStatusPayment.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get commonListingStatusPayment;

  /// No description provided for @commonListingStatusReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get commonListingStatusReview;

  /// No description provided for @commonListingStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get commonListingStatusApproved;

  /// No description provided for @commonListingStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get commonListingStatusRejected;

  /// No description provided for @commonListingStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get commonListingStatusActive;

  /// No description provided for @commonListingStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get commonListingStatusExpired;

  /// No description provided for @commonListingStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get commonListingStatusPaused;

  /// No description provided for @commonVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get commonVoucher;

  /// No description provided for @commonVoucherPrice.
  ///
  /// In en, this message translates to:
  /// **'Voucher price'**
  String get commonVoucherPrice;

  /// No description provided for @commonStandardPrice.
  ///
  /// In en, this message translates to:
  /// **'Standard price'**
  String get commonStandardPrice;

  /// No description provided for @commonYouSave.
  ///
  /// In en, this message translates to:
  /// **'You save {amount}'**
  String commonYouSave(String amount);

  /// No description provided for @commonSaveAmount.
  ///
  /// In en, this message translates to:
  /// **'Save {amount}'**
  String commonSaveAmount(String amount);

  /// No description provided for @commonConfirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get commonConfirmBooking;

  /// No description provided for @commonRedeemVoucher.
  ///
  /// In en, this message translates to:
  /// **'Redeem voucher'**
  String get commonRedeemVoucher;

  /// No description provided for @commonVoucherCode.
  ///
  /// In en, this message translates to:
  /// **'Voucher code'**
  String get commonVoucherCode;

  /// No description provided for @commonValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String commonValidUntil(String date);

  /// No description provided for @commonRoleClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get commonRoleClient;

  /// No description provided for @commonRoleYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get commonRoleYou;

  /// No description provided for @commonRoleHotelRep.
  ///
  /// In en, this message translates to:
  /// **'Hotel representative'**
  String get commonRoleHotelRep;

  /// No description provided for @commonRoleSupport.
  ///
  /// In en, this message translates to:
  /// **'Ghazal support'**
  String get commonRoleSupport;

  /// No description provided for @commonVenueTypePrivateHall.
  ///
  /// In en, this message translates to:
  /// **'Private hall'**
  String get commonVenueTypePrivateHall;

  /// No description provided for @commonVenueTypeGovernmental.
  ///
  /// In en, this message translates to:
  /// **'Governmental facility'**
  String get commonVenueTypeGovernmental;

  /// No description provided for @commonVenueTypeHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get commonVenueTypeHotel;

  /// No description provided for @commonPricingPerPerson.
  ///
  /// In en, this message translates to:
  /// **'Per person'**
  String get commonPricingPerPerson;

  /// No description provided for @commonPricingPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get commonPricingPackages;

  /// No description provided for @commonPricingPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get commonPricingPackage;

  /// No description provided for @commonPricingStructure.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get commonPricingStructure;

  /// No description provided for @commonFilterGovernorate.
  ///
  /// In en, this message translates to:
  /// **'Governorate'**
  String get commonFilterGovernorate;

  /// No description provided for @commonFilterVenueType.
  ///
  /// In en, this message translates to:
  /// **'Venue type'**
  String get commonFilterVenueType;

  /// No description provided for @commonFilterCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get commonFilterCapacity;

  /// No description provided for @commonPlanWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get commonPlanWeekly;

  /// No description provided for @commonPlanMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get commonPlanMonthly;

  /// No description provided for @commonPlanAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get commonPlanAnnual;

  /// No description provided for @commonRatesSoon.
  ///
  /// In en, this message translates to:
  /// **'Rates announced soon'**
  String get commonRatesSoon;

  /// No description provided for @commonExempt.
  ///
  /// In en, this message translates to:
  /// **'Exempt'**
  String get commonExempt;

  /// No description provided for @commonMajorHotel.
  ///
  /// In en, this message translates to:
  /// **'Major hotel'**
  String get commonMajorHotel;

  /// No description provided for @commonA11yInfo.
  ///
  /// In en, this message translates to:
  /// **'More info'**
  String get commonA11yInfo;

  /// No description provided for @commonLabelDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get commonLabelDetails;

  /// No description provided for @commonVoucherStatusForfeited.
  ///
  /// In en, this message translates to:
  /// **'Not valid'**
  String get commonVoucherStatusForfeited;

  /// No description provided for @commonVoucherStatusCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get commonVoucherStatusCredit;

  /// No description provided for @commonVoucherStatusCreditIssued.
  ///
  /// In en, this message translates to:
  /// **'Credit issued'**
  String get commonVoucherStatusCreditIssued;

  /// No description provided for @commonVoucherCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit voucher'**
  String get commonVoucherCredit;

  /// No description provided for @commonVoucherAnyVenue.
  ///
  /// In en, this message translates to:
  /// **'Any hall, hotel or service'**
  String get commonVoucherAnyVenue;

  /// No description provided for @commonVoucherNotValidNote.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed within {hours, plural, one{{hours} hour} other{{hours} hours}}'**
  String commonVoucherNotValidNote(int hours);

  /// No description provided for @commonVoucherConfirmIn24h.
  ///
  /// In en, this message translates to:
  /// **'Confirm at the hotel or service within {hours, plural, one{{hours} hour} other{{hours} hours}}, or the voucher is not valid'**
  String commonVoucherConfirmIn24h(int hours);

  /// No description provided for @commonAskSupport.
  ///
  /// In en, this message translates to:
  /// **'Ask support'**
  String get commonAskSupport;

  /// No description provided for @commonCreditRequested.
  ///
  /// In en, this message translates to:
  /// **'Request sent to support'**
  String get commonCreditRequested;

  /// No description provided for @commonBillingContract.
  ///
  /// In en, this message translates to:
  /// **'Business contract'**
  String get commonBillingContract;

  /// No description provided for @commonBillingPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get commonBillingPlan;

  /// No description provided for @commonBillingContractTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms as contracted'**
  String get commonBillingContractTerms;

  /// No description provided for @commonStaffInvitedByEmail.
  ///
  /// In en, this message translates to:
  /// **'Invited by email'**
  String get commonStaffInvitedByEmail;

  /// No description provided for @commonCalendarByEmail.
  ///
  /// In en, this message translates to:
  /// **'Calendar by email'**
  String get commonCalendarByEmail;

  /// No description provided for @commonReviewAskSupportHide.
  ///
  /// In en, this message translates to:
  /// **'Ask support to hide or delete'**
  String get commonReviewAskSupportHide;

  /// No description provided for @commonVideoLimit.
  ///
  /// In en, this message translates to:
  /// **'Up to {size} MB per video'**
  String commonVideoLimit(String size);

  /// No description provided for @hotelAccessLanguageSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch language'**
  String get hotelAccessLanguageSwitch;

  /// No description provided for @hotelAccessPasswordShow.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get hotelAccessPasswordShow;

  /// No description provided for @hotelAccessPasswordHide.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hotelAccessPasswordHide;

  /// No description provided for @hotelAccessPhotoAlt.
  ///
  /// In en, this message translates to:
  /// **'Light-filled vaulted hall with skylights and arched windows, long banquet tables set with white linen and gold chairs on herringbone parquet'**
  String get hotelAccessPhotoAlt;

  /// No description provided for @hotelAccessSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Ghazal Support'**
  String get hotelAccessSupportTitle;

  /// No description provided for @hotelAccessSupportAction.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get hotelAccessSupportAction;

  /// No description provided for @hotelAccessSupportShort.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get hotelAccessSupportShort;

  /// No description provided for @hotelAccessAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Account admin'**
  String get hotelAccessAdminTitle;

  /// No description provided for @hotelAccessAdminAction.
  ///
  /// In en, this message translates to:
  /// **'Contact admin'**
  String get hotelAccessAdminAction;

  /// No description provided for @hotelAccessSigninTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get hotelAccessSigninTitle;

  /// No description provided for @hotelAccessSigninEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get hotelAccessSigninEmailLabel;

  /// No description provided for @hotelAccessSigninPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get hotelAccessSigninPasswordLabel;

  /// No description provided for @hotelAccessSigninForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot?'**
  String get hotelAccessSigninForgot;

  /// No description provided for @hotelAccessSigninForgotLabel.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get hotelAccessSigninForgotLabel;

  /// No description provided for @hotelAccessSigninInvite.
  ///
  /// In en, this message translates to:
  /// **'Invitation'**
  String get hotelAccessSigninInvite;

  /// No description provided for @hotelAccessSigninApplyLine.
  ///
  /// In en, this message translates to:
  /// **'New service provider or private hall?'**
  String get hotelAccessSigninApplyLine;

  /// No description provided for @hotelAccessSigninApply.
  ///
  /// In en, this message translates to:
  /// **'Apply to join'**
  String get hotelAccessSigninApply;

  /// No description provided for @hotelAccessSigninSubmit.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get hotelAccessSigninSubmit;

  /// No description provided for @hotelAccessSigninInvalid.
  ///
  /// In en, this message translates to:
  /// **'Incorrect details'**
  String get hotelAccessSigninInvalid;

  /// No description provided for @hotelAccessSigninInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get hotelAccessSigninInvalidTitle;

  /// No description provided for @hotelAccessSigninInvalidDetail.
  ///
  /// In en, this message translates to:
  /// **'The email or password is not correct. You are not signed in.'**
  String get hotelAccessSigninInvalidDetail;

  /// No description provided for @hotelAccessSigninPaused.
  ///
  /// In en, this message translates to:
  /// **'Attempts paused'**
  String get hotelAccessSigninPaused;

  /// No description provided for @hotelAccessSigninPausedDetail.
  ///
  /// In en, this message translates to:
  /// **'Attempts are paused. Try again after {time} Kuwait time.'**
  String hotelAccessSigninPausedDetail(String time);

  /// No description provided for @hotelAccessSigninPausedUntil.
  ///
  /// In en, this message translates to:
  /// **'Paused until {time}'**
  String hotelAccessSigninPausedUntil(String time);

  /// No description provided for @hotelAccessInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation only'**
  String get hotelAccessInviteTitle;

  /// No description provided for @hotelAccessInviteStepLink.
  ///
  /// In en, this message translates to:
  /// **'Email link'**
  String get hotelAccessInviteStepLink;

  /// No description provided for @hotelAccessInviteStepCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get hotelAccessInviteStepCode;

  /// No description provided for @hotelAccessInviteSteps.
  ///
  /// In en, this message translates to:
  /// **'How an invitation works'**
  String get hotelAccessInviteSteps;

  /// No description provided for @hotelAccessInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get hotelAccessInviteLink;

  /// No description provided for @hotelAccessInviteFrom.
  ///
  /// In en, this message translates to:
  /// **'Invited by {name}'**
  String hotelAccessInviteFrom(String name);

  /// No description provided for @hotelAccessVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get hotelAccessVerifyTitle;

  /// No description provided for @hotelAccessVerifyApplicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get hotelAccessVerifyApplicationTitle;

  /// No description provided for @hotelAccessVerifyLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get hotelAccessVerifyLabel;

  /// No description provided for @hotelAccessVerifyStepEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get hotelAccessVerifyStepEmail;

  /// No description provided for @hotelAccessVerifySentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent by email to {email}'**
  String hotelAccessVerifySentTo(String email);

  /// No description provided for @hotelAccessVerifySubmit.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get hotelAccessVerifySubmit;

  /// No description provided for @hotelAccessVerifyWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong code'**
  String get hotelAccessVerifyWrong;

  /// No description provided for @hotelAccessVerifyAttemptsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No attempts remaining} one{{count} attempt remaining} other{{count} attempts remaining}}'**
  String hotelAccessVerifyAttemptsLeft(int count);

  /// No description provided for @hotelAccessVerifyExpired.
  ///
  /// In en, this message translates to:
  /// **'Code expired'**
  String get hotelAccessVerifyExpired;

  /// No description provided for @hotelAccessVerifyTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts'**
  String get hotelAccessVerifyTooMany;

  /// No description provided for @hotelAccessVerifyResent.
  ///
  /// In en, this message translates to:
  /// **'Code sent'**
  String get hotelAccessVerifyResent;

  /// No description provided for @hotelAccessVerifyTimer.
  ///
  /// In en, this message translates to:
  /// **'{count}s'**
  String hotelAccessVerifyTimer(String count);

  /// No description provided for @hotelAccessVerifyResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {count, plural, one{{count} second} other{{count} seconds}}'**
  String hotelAccessVerifyResendIn(int count);

  /// No description provided for @hotelAccessVerifyResend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get hotelAccessVerifyResend;

  /// No description provided for @hotelAccessVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Not delivered'**
  String get hotelAccessVerifyFailed;

  /// No description provided for @hotelAccessVerifyFailedDetail.
  ///
  /// In en, this message translates to:
  /// **'The code could not be sent by email. Send it again, or contact Support.'**
  String get hotelAccessVerifyFailedDetail;

  /// No description provided for @hotelAccessVerifySuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Device trusted'**
  String get hotelAccessVerifySuccessTitle;

  /// No description provided for @hotelAccessVerifyApplicationDone.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get hotelAccessVerifyApplicationDone;

  /// No description provided for @hotelAccessVerifyTrustDays.
  ///
  /// In en, this message translates to:
  /// **'Trusted for {count, plural, one{{count} day} other{{count} days}}'**
  String hotelAccessVerifyTrustDays(int count);

  /// No description provided for @hotelAccessVerifyTrustFact.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String hotelAccessVerifyTrustFact(String count);

  /// No description provided for @hotelAccessVerifySteps.
  ///
  /// In en, this message translates to:
  /// **'Verification steps'**
  String get hotelAccessVerifySteps;

  /// No description provided for @hotelAccessVerifyStepCounter.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String hotelAccessVerifyStepCounter(num current, num total);

  /// No description provided for @hotelAccessAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'Authenticator code'**
  String get hotelAccessAuthTitle;

  /// No description provided for @hotelAccessStepupTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm identity'**
  String get hotelAccessStepupTitle;

  /// No description provided for @hotelAccessStepupActionInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite staff'**
  String get hotelAccessStepupActionInvite;

  /// No description provided for @hotelAccessStepupActionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove staff'**
  String get hotelAccessStepupActionRemove;

  /// No description provided for @hotelAccessStepupActionBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing details'**
  String get hotelAccessStepupActionBilling;

  /// No description provided for @hotelAccessStepupDone.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get hotelAccessStepupDone;

  /// No description provided for @hotelAccessSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get hotelAccessSetupTitle;

  /// No description provided for @hotelAccessSetupCardLabel.
  ///
  /// In en, this message translates to:
  /// **'Invitation'**
  String get hotelAccessSetupCardLabel;

  /// No description provided for @hotelAccessSetupInvitedEmail.
  ///
  /// In en, this message translates to:
  /// **'Invited email'**
  String get hotelAccessSetupInvitedEmail;

  /// No description provided for @hotelAccessSetupValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String hotelAccessSetupValidUntil(String date);

  /// No description provided for @hotelAccessSetupRoleInfo.
  ///
  /// In en, this message translates to:
  /// **'What this role can do'**
  String get hotelAccessSetupRoleInfo;

  /// No description provided for @hotelAccessSetupPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get hotelAccessSetupPasswordLabel;

  /// No description provided for @hotelAccessSetupConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get hotelAccessSetupConfirmLabel;

  /// No description provided for @hotelAccessSetupMismatch.
  ///
  /// In en, this message translates to:
  /// **'Doesn’t match'**
  String get hotelAccessSetupMismatch;

  /// No description provided for @hotelAccessSetupStrength.
  ///
  /// In en, this message translates to:
  /// **'Password strength: {level}'**
  String hotelAccessSetupStrength(String level);

  /// No description provided for @hotelAccessSetupStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get hotelAccessSetupStrengthWeak;

  /// No description provided for @hotelAccessSetupStrengthFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get hotelAccessSetupStrengthFair;

  /// No description provided for @hotelAccessSetupStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get hotelAccessSetupStrengthStrong;

  /// No description provided for @hotelAccessSetupRuleLength.
  ///
  /// In en, this message translates to:
  /// **'At least {count, plural, one{{count} character} other{{count} characters}}'**
  String hotelAccessSetupRuleLength(int count);

  /// No description provided for @hotelAccessSetupRuleMix.
  ///
  /// In en, this message translates to:
  /// **'A letter and a number'**
  String get hotelAccessSetupRuleMix;

  /// No description provided for @hotelAccessSetupRuleMet.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get hotelAccessSetupRuleMet;

  /// No description provided for @hotelAccessSetupRuleOpen.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get hotelAccessSetupRuleOpen;

  /// No description provided for @hotelAccessSetupError.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get hotelAccessSetupError;

  /// No description provided for @hotelAccessSetupErrorDetail.
  ///
  /// In en, this message translates to:
  /// **'We could not save your password. Nothing was changed. Please try again.'**
  String get hotelAccessSetupErrorDetail;

  /// No description provided for @hotelAccessSetupSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Password saved'**
  String get hotelAccessSetupSuccessTitle;

  /// No description provided for @hotelAccessSetupExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation expired'**
  String get hotelAccessSetupExpiredTitle;

  /// No description provided for @hotelAccessSetupExpiredDetail.
  ///
  /// In en, this message translates to:
  /// **'Invitations stop working after a few days. Your account admin or Ghazal Support can send a new one.'**
  String get hotelAccessSetupExpiredDetail;

  /// No description provided for @hotelAccessSetupUsedTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation used'**
  String get hotelAccessSetupUsedTitle;

  /// No description provided for @hotelAccessSetupUsedDetail.
  ///
  /// In en, this message translates to:
  /// **'Your password is already set. Sign in with your email and password.'**
  String get hotelAccessSetupUsedDetail;

  /// No description provided for @hotelAccessStatusUnderReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get hotelAccessStatusUnderReviewTitle;

  /// No description provided for @hotelAccessStatusUnderReviewBody.
  ///
  /// In en, this message translates to:
  /// **'Your account is under review. We will email you when it is active.'**
  String get hotelAccessStatusUnderReviewBody;

  /// No description provided for @hotelAccessStatusApplicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Application in review'**
  String get hotelAccessStatusApplicationTitle;

  /// No description provided for @hotelAccessStatusApplicationBody.
  ///
  /// In en, this message translates to:
  /// **'Ghazal reviews every application and emails you the decision. You can add listings once it is approved.'**
  String get hotelAccessStatusApplicationBody;

  /// No description provided for @hotelAccessStatusRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Application not approved'**
  String get hotelAccessStatusRejectedTitle;

  /// No description provided for @hotelAccessStatusEditResubmit.
  ///
  /// In en, this message translates to:
  /// **'Edit and resubmit'**
  String get hotelAccessStatusEditResubmit;

  /// No description provided for @hotelAccessStatusApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Application approved'**
  String get hotelAccessStatusApprovedTitle;

  /// No description provided for @hotelAccessStatusReasonsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get hotelAccessStatusReasonsLabel;

  /// No description provided for @hotelAccessStatusProtoTitle.
  ///
  /// In en, this message translates to:
  /// **'Ghazal staff'**
  String get hotelAccessStatusProtoTitle;

  /// No description provided for @hotelAccessStatusProtoApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get hotelAccessStatusProtoApprove;

  /// No description provided for @hotelAccessStatusProtoReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get hotelAccessStatusProtoReject;

  /// No description provided for @hotelAccessStatusSuspendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get hotelAccessStatusSuspendedTitle;

  /// No description provided for @hotelAccessStatusSuspendedBody.
  ///
  /// In en, this message translates to:
  /// **'This account is suspended. Contact Ghazal Support.'**
  String get hotelAccessStatusSuspendedBody;

  /// No description provided for @hotelAccessStatusDeactivatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Access off'**
  String get hotelAccessStatusDeactivatedTitle;

  /// No description provided for @hotelAccessStatusDeactivatedBody.
  ///
  /// In en, this message translates to:
  /// **'Your access to this account has been turned off. Contact your account admin.'**
  String get hotelAccessStatusDeactivatedBody;

  /// No description provided for @hotelAccessStatusRevokedTitle.
  ///
  /// In en, this message translates to:
  /// **'Session ended'**
  String get hotelAccessStatusRevokedTitle;

  /// No description provided for @hotelAccessStatusRevokedBody.
  ///
  /// In en, this message translates to:
  /// **'An account admin ended this session. Sign in again.'**
  String get hotelAccessStatusRevokedBody;

  /// No description provided for @hotelAccessStatusNoAccessBody.
  ///
  /// In en, this message translates to:
  /// **'You do not have access. Ask your manager.'**
  String get hotelAccessStatusNoAccessBody;

  /// No description provided for @hotelAccessStatusSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get hotelAccessStatusSignOut;

  /// No description provided for @hotelAccessStatusSwitchVenue.
  ///
  /// In en, this message translates to:
  /// **'Switch venue'**
  String get hotelAccessStatusSwitchVenue;

  /// No description provided for @hotelAccessStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get hotelAccessStatusActive;

  /// No description provided for @hotelBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get hotelBookingsTitle;

  /// No description provided for @hotelBookingsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search bookings'**
  String get hotelBookingsSearch;

  /// No description provided for @hotelBookingsSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Name, reference, date'**
  String get hotelBookingsSearchPlaceholder;

  /// No description provided for @hotelBookingsFilterByDate.
  ///
  /// In en, this message translates to:
  /// **'Filter by date'**
  String get hotelBookingsFilterByDate;

  /// No description provided for @hotelBookingsSegments.
  ///
  /// In en, this message translates to:
  /// **'Booking views'**
  String get hotelBookingsSegments;

  /// No description provided for @hotelBookingsSegPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get hotelBookingsSegPending;

  /// No description provided for @hotelBookingsSegUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get hotelBookingsSegUpcoming;

  /// No description provided for @hotelBookingsSegPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get hotelBookingsSegPast;

  /// No description provided for @hotelBookingsWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Awaiting couple'**
  String get hotelBookingsWaitingTitle;

  /// No description provided for @hotelBookingsOpenRequest.
  ///
  /// In en, this message translates to:
  /// **'Open request: {date}'**
  String hotelBookingsOpenRequest(String date);

  /// No description provided for @hotelBookingsTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} remaining'**
  String hotelBookingsTimeLeft(String time);

  /// No description provided for @hotelBookingsAudienceWomen.
  ///
  /// In en, this message translates to:
  /// **'Ladies'**
  String get hotelBookingsAudienceWomen;

  /// No description provided for @hotelBookingsAudienceMen.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get hotelBookingsAudienceMen;

  /// No description provided for @hotelBookingsAudienceMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get hotelBookingsAudienceMixed;

  /// No description provided for @hotelBookingsVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified phone'**
  String get hotelBookingsVerified;

  /// No description provided for @hotelBookingsFirstBooking.
  ///
  /// In en, this message translates to:
  /// **'First booking'**
  String get hotelBookingsFirstBooking;

  /// No description provided for @hotelBookingsMessageName.
  ///
  /// In en, this message translates to:
  /// **'Message {name}'**
  String hotelBookingsMessageName(String name);

  /// No description provided for @hotelBookingsCallName.
  ///
  /// In en, this message translates to:
  /// **'Call {name}'**
  String hotelBookingsCallName(String name);

  /// No description provided for @hotelBookingsSpecialRequests.
  ///
  /// In en, this message translates to:
  /// **'Special requests'**
  String get hotelBookingsSpecialRequests;

  /// No description provided for @hotelBookingsHeldLine.
  ///
  /// In en, this message translates to:
  /// **'Date held'**
  String get hotelBookingsHeldLine;

  /// No description provided for @hotelBookingsOthersSameDate.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{+{count} other request for this date} other{+{count} other requests for this date}}'**
  String hotelBookingsOthersSameDate(int count);

  /// No description provided for @hotelBookingsCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get hotelBookingsCompare;

  /// No description provided for @hotelBookingsViewOnly.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get hotelBookingsViewOnly;

  /// No description provided for @hotelBookingsOfflineShort.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get hotelBookingsOfflineShort;

  /// No description provided for @hotelBookingsOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline · updated {time}'**
  String hotelBookingsOfflineBanner(String time);

  /// No description provided for @hotelBookingsProposeDate.
  ///
  /// In en, this message translates to:
  /// **'Propose another date'**
  String get hotelBookingsProposeDate;

  /// No description provided for @hotelBookingsEmptyPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get hotelBookingsEmptyPendingTitle;

  /// No description provided for @hotelBookingsSeeUpcoming.
  ///
  /// In en, this message translates to:
  /// **'View upcoming'**
  String get hotelBookingsSeeUpcoming;

  /// No description provided for @hotelBookingsNextEvent.
  ///
  /// In en, this message translates to:
  /// **'Next event'**
  String get hotelBookingsNextEvent;

  /// No description provided for @hotelBookingsEmptyUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookings'**
  String get hotelBookingsEmptyUpcomingTitle;

  /// No description provided for @hotelBookingsPastFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter past bookings'**
  String get hotelBookingsPastFilter;

  /// No description provided for @hotelBookingsNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No match for {query}'**
  String hotelBookingsNoResultsTitle(String query);

  /// No description provided for @hotelBookingsRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get hotelBookingsRecentTitle;

  /// No description provided for @hotelBookingsAcceptedToast.
  ///
  /// In en, this message translates to:
  /// **'Approved · {name}'**
  String hotelBookingsAcceptedToast(String name);

  /// No description provided for @hotelBookingsAwaitingCouple.
  ///
  /// In en, this message translates to:
  /// **'Awaiting the couple'**
  String get hotelBookingsAwaitingCouple;

  /// No description provided for @hotelBookingsConfirmLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} to confirm'**
  String hotelBookingsConfirmLeft(String time);

  /// No description provided for @hotelBookingsNotRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Voucher not redeemed'**
  String get hotelBookingsNotRedeemed;

  /// No description provided for @hotelBookingsRedeemedBy.
  ///
  /// In en, this message translates to:
  /// **'Redeemed by {name}, {date}'**
  String hotelBookingsRedeemedBy(String name, String date);

  /// No description provided for @hotelBookingsRedeemedPlain.
  ///
  /// In en, this message translates to:
  /// **'Redeemed'**
  String get hotelBookingsRedeemedPlain;

  /// No description provided for @hotelBookingsActorVenue.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get hotelBookingsActorVenue;

  /// No description provided for @hotelBookingsActorGhazal.
  ///
  /// In en, this message translates to:
  /// **'Ghazal'**
  String get hotelBookingsActorGhazal;

  /// No description provided for @hotelBookingsActorSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get hotelBookingsActorSystem;

  /// No description provided for @hotelBookingsActorClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get hotelBookingsActorClient;

  /// No description provided for @hotelBookingsByVenue.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by the hotel'**
  String get hotelBookingsByVenue;

  /// No description provided for @hotelBookingsByClient.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by the client'**
  String get hotelBookingsByClient;

  /// No description provided for @hotelBookingsDeclineDate.
  ///
  /// In en, this message translates to:
  /// **'Date unavailable'**
  String get hotelBookingsDeclineDate;

  /// No description provided for @hotelBookingsDeclineCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get hotelBookingsDeclineCapacity;

  /// No description provided for @hotelBookingsDeclinePackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get hotelBookingsDeclinePackage;

  /// No description provided for @hotelBookingsDeclineOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get hotelBookingsDeclineOther;

  /// No description provided for @hotelBookingsDeclineReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get hotelBookingsDeclineReason;

  /// No description provided for @hotelBookingsSilence.
  ///
  /// In en, this message translates to:
  /// **'No reply for {time}'**
  String hotelBookingsSilence(String time);

  /// No description provided for @hotelBookingsFactsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get hotelBookingsFactsLabel;

  /// No description provided for @hotelBookingsFactDate.
  ///
  /// In en, this message translates to:
  /// **'Event date'**
  String get hotelBookingsFactDate;

  /// No description provided for @hotelBookingsFactGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get hotelBookingsFactGuests;

  /// No description provided for @hotelBookingsFactHall.
  ///
  /// In en, this message translates to:
  /// **'Hall'**
  String get hotelBookingsFactHall;

  /// No description provided for @hotelBookingsFactTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get hotelBookingsFactTime;

  /// No description provided for @hotelBookingsSessionDay.
  ///
  /// In en, this message translates to:
  /// **'Day session'**
  String get hotelBookingsSessionDay;

  /// No description provided for @hotelBookingsSessionAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon session'**
  String get hotelBookingsSessionAfternoon;

  /// No description provided for @hotelBookingsSessionEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening session'**
  String get hotelBookingsSessionEvening;

  /// No description provided for @hotelBookingsBillable.
  ///
  /// In en, this message translates to:
  /// **'Billed for {count, plural, one{{count} guest} other{{count} guests}}'**
  String hotelBookingsBillable(int count);

  /// No description provided for @hotelBookingsFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get hotelBookingsFilterTitle;

  /// No description provided for @hotelBookingsFilterBy.
  ///
  /// In en, this message translates to:
  /// **'Filter by'**
  String get hotelBookingsFilterBy;

  /// No description provided for @hotelBookingsFilterEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get hotelBookingsFilterEvent;

  /// No description provided for @hotelBookingsFilterRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get hotelBookingsFilterRequest;

  /// No description provided for @hotelBookingsRangeLine.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String hotelBookingsRangeLine(String from, String to);

  /// No description provided for @hotelBookingsRangeApplied.
  ///
  /// In en, this message translates to:
  /// **'Date filter applied'**
  String get hotelBookingsRangeApplied;

  /// No description provided for @hotelBookingsDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get hotelBookingsDetailTitle;

  /// No description provided for @hotelBookingsReplyLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} to reply'**
  String hotelBookingsReplyLeft(String time);

  /// No description provided for @hotelBookingsDaysToGo.
  ///
  /// In en, this message translates to:
  /// **'Days to go'**
  String get hotelBookingsDaysToGo;

  /// No description provided for @hotelBookingsEventToday.
  ///
  /// In en, this message translates to:
  /// **'Event today'**
  String get hotelBookingsEventToday;

  /// No description provided for @hotelBookingsKnotVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get hotelBookingsKnotVoucher;

  /// No description provided for @hotelBookingsKnotRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get hotelBookingsKnotRequest;

  /// No description provided for @hotelBookingsKnotApproval.
  ///
  /// In en, this message translates to:
  /// **'Approval'**
  String get hotelBookingsKnotApproval;

  /// No description provided for @hotelBookingsKnotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get hotelBookingsKnotConfirmed;

  /// No description provided for @hotelBookingsKnotRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Redeemed'**
  String get hotelBookingsKnotRedeemed;

  /// No description provided for @hotelBookingsProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking progress'**
  String get hotelBookingsProgressLabel;

  /// No description provided for @hotelBookingsStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {n} of {total}'**
  String hotelBookingsStepOf(String n, String total);

  /// No description provided for @hotelBookingsIssueReported.
  ///
  /// In en, this message translates to:
  /// **'Client reported an issue'**
  String get hotelBookingsIssueReported;

  /// No description provided for @hotelBookingsIssueLink.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get hotelBookingsIssueLink;

  /// No description provided for @hotelBookingsCreateWindow.
  ///
  /// In en, this message translates to:
  /// **'Set price'**
  String get hotelBookingsCreateWindow;

  /// No description provided for @hotelBookingsDateFreeAgain.
  ///
  /// In en, this message translates to:
  /// **'Date free'**
  String get hotelBookingsDateFreeAgain;

  /// No description provided for @hotelBookingsShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get hotelBookingsShowMore;

  /// No description provided for @hotelBookingsShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get hotelBookingsShowLess;

  /// No description provided for @hotelBookingsRowServiceDate.
  ///
  /// In en, this message translates to:
  /// **'Service date'**
  String get hotelBookingsRowServiceDate;

  /// No description provided for @hotelBookingsEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get hotelBookingsEventTitle;

  /// No description provided for @hotelBookingsRowPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get hotelBookingsRowPackage;

  /// No description provided for @hotelBookingsRowHall.
  ///
  /// In en, this message translates to:
  /// **'Hall'**
  String get hotelBookingsRowHall;

  /// No description provided for @hotelBookingsRowDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get hotelBookingsRowDate;

  /// No description provided for @hotelBookingsRowTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get hotelBookingsRowTime;

  /// No description provided for @hotelBookingsRowRedeemedBy.
  ///
  /// In en, this message translates to:
  /// **'Redeemed by'**
  String get hotelBookingsRowRedeemedBy;

  /// No description provided for @hotelBookingsPriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get hotelBookingsPriceTitle;

  /// No description provided for @hotelBookingsClientSaves.
  ///
  /// In en, this message translates to:
  /// **'Client saves'**
  String get hotelBookingsClientSaves;

  /// No description provided for @hotelBookingsInfoPriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher price'**
  String get hotelBookingsInfoPriceTitle;

  /// No description provided for @hotelBookingsDirectNote.
  ///
  /// In en, this message translates to:
  /// **'You collect this directly from the client. Ghazal never shows a payment status.'**
  String get hotelBookingsDirectNote;

  /// No description provided for @hotelBookingsVoucherBound.
  ///
  /// In en, this message translates to:
  /// **'In request'**
  String get hotelBookingsVoucherBound;

  /// No description provided for @hotelBookingsVoucherRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Redeemed'**
  String get hotelBookingsVoucherRedeemed;

  /// No description provided for @hotelBookingsVoucherReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get hotelBookingsVoucherReturned;

  /// No description provided for @hotelBookingsVoucherExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get hotelBookingsVoucherExpired;

  /// No description provided for @hotelBookingsVoucherNotValid.
  ///
  /// In en, this message translates to:
  /// **'Not valid'**
  String get hotelBookingsVoucherNotValid;

  /// No description provided for @hotelBookingsProposalTitle.
  ///
  /// In en, this message translates to:
  /// **'New dates'**
  String get hotelBookingsProposalTitle;

  /// No description provided for @hotelBookingsProposalWindow.
  ///
  /// In en, this message translates to:
  /// **'Couple answers by'**
  String get hotelBookingsProposalWindow;

  /// No description provided for @hotelBookingsPriceChanged.
  ///
  /// In en, this message translates to:
  /// **'Price changes'**
  String get hotelBookingsPriceChanged;

  /// No description provided for @hotelBookingsInfoReturned.
  ///
  /// In en, this message translates to:
  /// **'The client’s voucher went back to them. The date is free again.'**
  String get hotelBookingsInfoReturned;

  /// No description provided for @hotelBookingsInfoClientUsed.
  ///
  /// In en, this message translates to:
  /// **'The client cancelled after confirming, so their voucher is used up. The date is free again.'**
  String get hotelBookingsInfoClientUsed;

  /// No description provided for @hotelBookingsInfoVenue.
  ///
  /// In en, this message translates to:
  /// **'The client’s voucher was returned. They can ask support for credit. A reliability strike was recorded.'**
  String get hotelBookingsInfoVenue;

  /// No description provided for @hotelBookingsMarkCompleted.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get hotelBookingsMarkCompleted;

  /// No description provided for @hotelBookingsCancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get hotelBookingsCancelBooking;

  /// No description provided for @hotelBookingsCancelInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancellation'**
  String get hotelBookingsCancelInfoTitle;

  /// No description provided for @hotelBookingsCancelNote.
  ///
  /// In en, this message translates to:
  /// **'The client’s voucher goes back to them. They can ask support for credit. A reliability strike is recorded.'**
  String get hotelBookingsCancelNote;

  /// No description provided for @hotelBookingsRevokeApproval.
  ///
  /// In en, this message translates to:
  /// **'Revoke approval'**
  String get hotelBookingsRevokeApproval;

  /// No description provided for @hotelBookingsReplyToReview.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get hotelBookingsReplyToReview;

  /// No description provided for @hotelBookingsCompletedToast.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get hotelBookingsCompletedToast;

  /// No description provided for @hotelBookingsAuditTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get hotelBookingsAuditTitle;

  /// No description provided for @hotelBookingsAuditRequested.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get hotelBookingsAuditRequested;

  /// No description provided for @hotelBookingsAuditApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get hotelBookingsAuditApproved;

  /// No description provided for @hotelBookingsAuditConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get hotelBookingsAuditConfirmed;

  /// No description provided for @hotelBookingsAuditRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Redeemed'**
  String get hotelBookingsAuditRedeemed;

  /// No description provided for @hotelBookingsAuditDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get hotelBookingsAuditDeclined;

  /// No description provided for @hotelBookingsAuditExpired.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get hotelBookingsAuditExpired;

  /// No description provided for @hotelBookingsAuditLapsed.
  ///
  /// In en, this message translates to:
  /// **'Lapsed'**
  String get hotelBookingsAuditLapsed;

  /// No description provided for @hotelBookingsAuditRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get hotelBookingsAuditRevoked;

  /// No description provided for @hotelBookingsAuditCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get hotelBookingsAuditCancelled;

  /// No description provided for @hotelBookingsAuditCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get hotelBookingsAuditCompleted;

  /// No description provided for @hotelBookingsAuditProposal.
  ///
  /// In en, this message translates to:
  /// **'New date'**
  String get hotelBookingsAuditProposal;

  /// No description provided for @hotelBookingsAuditUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get hotelBookingsAuditUpdated;

  /// No description provided for @hotelBookingsChatRow.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get hotelBookingsChatRow;

  /// No description provided for @hotelBookingsNotShared.
  ///
  /// In en, this message translates to:
  /// **'Number not shared'**
  String get hotelBookingsNotShared;

  /// No description provided for @hotelBookingsContactPrivacy.
  ///
  /// In en, this message translates to:
  /// **'This number is shown for this booking only. The client’s voucher code appears only when you redeem it.'**
  String get hotelBookingsContactPrivacy;

  /// No description provided for @hotelBookingsContactOffline.
  ///
  /// In en, this message translates to:
  /// **'You’re offline. Calls still work; messages send when you reconnect.'**
  String get hotelBookingsContactOffline;

  /// No description provided for @hotelBookingsRoleNoContact.
  ///
  /// In en, this message translates to:
  /// **'Your role cannot contact clients. Ask your manager.'**
  String get hotelBookingsRoleNoContact;

  /// No description provided for @hotelBookingsCallToast.
  ///
  /// In en, this message translates to:
  /// **'Calling {name}'**
  String hotelBookingsCallToast(String name);

  /// No description provided for @hotelBookingsWhatsappToast.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp {name}'**
  String hotelBookingsWhatsappToast(String name);

  /// No description provided for @hotelBookingsRedeemMode.
  ///
  /// In en, this message translates to:
  /// **'Entry method'**
  String get hotelBookingsRedeemMode;

  /// No description provided for @hotelBookingsModeScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get hotelBookingsModeScan;

  /// No description provided for @hotelBookingsModeType.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get hotelBookingsModeType;

  /// No description provided for @hotelBookingsTypeCode.
  ///
  /// In en, this message translates to:
  /// **'Type code'**
  String get hotelBookingsTypeCode;

  /// No description provided for @hotelBookingsScanDemo.
  ///
  /// In en, this message translates to:
  /// **'Simulate'**
  String get hotelBookingsScanDemo;

  /// No description provided for @hotelBookingsTorchOn.
  ///
  /// In en, this message translates to:
  /// **'Torch on'**
  String get hotelBookingsTorchOn;

  /// No description provided for @hotelBookingsTorchOff.
  ///
  /// In en, this message translates to:
  /// **'Torch off'**
  String get hotelBookingsTorchOff;

  /// No description provided for @hotelBookingsCameraDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera is off'**
  String get hotelBookingsCameraDeniedTitle;

  /// No description provided for @hotelBookingsCameraDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Allow the camera in your phone settings to scan, or type the code instead.'**
  String get hotelBookingsCameraDeniedBody;

  /// No description provided for @hotelBookingsCheckCode.
  ///
  /// In en, this message translates to:
  /// **'Check code'**
  String get hotelBookingsCheckCode;

  /// No description provided for @hotelBookingsChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get hotelBookingsChecking;

  /// No description provided for @hotelBookingsTryAnother.
  ///
  /// In en, this message translates to:
  /// **'Try another'**
  String get hotelBookingsTryAnother;

  /// No description provided for @hotelBookingsErrUnknownField.
  ///
  /// In en, this message translates to:
  /// **'Code not found'**
  String get hotelBookingsErrUnknownField;

  /// No description provided for @hotelBookingsErrUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Code not found'**
  String get hotelBookingsErrUnknownTitle;

  /// No description provided for @hotelBookingsErrUnknownBody.
  ///
  /// In en, this message translates to:
  /// **'Check it and try again.'**
  String get hotelBookingsErrUnknownBody;

  /// No description provided for @hotelBookingsErrOtherTitle.
  ///
  /// In en, this message translates to:
  /// **'Another venue’s voucher'**
  String get hotelBookingsErrOtherTitle;

  /// No description provided for @hotelBookingsErrOtherBody.
  ///
  /// In en, this message translates to:
  /// **'It can only be redeemed by the venue it was issued for. No other details are shown.'**
  String get hotelBookingsErrOtherBody;

  /// No description provided for @hotelBookingsErrNotConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed yet'**
  String get hotelBookingsErrNotConfirmedTitle;

  /// No description provided for @hotelBookingsErrNotConfirmedBody.
  ///
  /// In en, this message translates to:
  /// **'The client has to confirm the booking before the voucher can be redeemed.'**
  String get hotelBookingsErrNotConfirmedBody;

  /// No description provided for @hotelBookingsErrUsedPlain.
  ///
  /// In en, this message translates to:
  /// **'Already used'**
  String get hotelBookingsErrUsedPlain;

  /// No description provided for @hotelBookingsErrUsedBody.
  ///
  /// In en, this message translates to:
  /// **'A voucher works once. Contact support if this looks wrong.'**
  String get hotelBookingsErrUsedBody;

  /// No description provided for @hotelBookingsErrExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Not valid'**
  String get hotelBookingsErrExpiredTitle;

  /// No description provided for @hotelBookingsErrExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'It can no longer be redeemed.'**
  String get hotelBookingsErrExpiredBody;

  /// No description provided for @hotelBookingsRedeemErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing was changed. Please try again.'**
  String get hotelBookingsRedeemErrorBody;

  /// No description provided for @hotelBookingsRoleHiddenBody.
  ///
  /// In en, this message translates to:
  /// **'Ask an Admin, a Manager or Reception to redeem it.'**
  String get hotelBookingsRoleHiddenBody;

  /// No description provided for @hotelBookingsRedeemFine.
  ///
  /// In en, this message translates to:
  /// **'Redeeming cannot be undone. Support can adjust it if a mistake is made.'**
  String get hotelBookingsRedeemFine;

  /// No description provided for @hotelBookingsRedeemedFine.
  ///
  /// In en, this message translates to:
  /// **'The client pays you directly. Ghazal shows no amount due.'**
  String get hotelBookingsRedeemedFine;

  /// No description provided for @hotelBookingsRedeemedCached.
  ///
  /// In en, this message translates to:
  /// **'Offline · saved {time}'**
  String hotelBookingsRedeemedCached(String time);

  /// No description provided for @hotelBookingsViewBooking.
  ///
  /// In en, this message translates to:
  /// **'View booking'**
  String get hotelBookingsViewBooking;

  /// No description provided for @hotelBookingsProtoTag.
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get hotelBookingsProtoTag;

  /// No description provided for @hotelBookingsProtoTitle.
  ///
  /// In en, this message translates to:
  /// **'Prototype shortcuts'**
  String get hotelBookingsProtoTitle;

  /// No description provided for @hotelBookingsProtoReady.
  ///
  /// In en, this message translates to:
  /// **'Ready voucher'**
  String get hotelBookingsProtoReady;

  /// No description provided for @hotelBookingsProtoNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed'**
  String get hotelBookingsProtoNotConfirmed;

  /// No description provided for @hotelBookingsProtoUsed.
  ///
  /// In en, this message translates to:
  /// **'Already used'**
  String get hotelBookingsProtoUsed;

  /// No description provided for @hotelBookingsProtoOther.
  ///
  /// In en, this message translates to:
  /// **'Other venue'**
  String get hotelBookingsProtoOther;

  /// No description provided for @hotelBookingsBackToList.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get hotelBookingsBackToList;

  /// No description provided for @hotelBookingsDurJoin.
  ///
  /// In en, this message translates to:
  /// **'{first} {second}'**
  String hotelBookingsDurJoin(String first, String second);

  /// No description provided for @hotelCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get hotelCalendarTitle;

  /// No description provided for @hotelCalendarViewLabel.
  ///
  /// In en, this message translates to:
  /// **'Calendar view'**
  String get hotelCalendarViewLabel;

  /// No description provided for @hotelCalendarViewMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get hotelCalendarViewMonth;

  /// No description provided for @hotelCalendarViewWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get hotelCalendarViewWeek;

  /// No description provided for @hotelCalendarViewDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get hotelCalendarViewDay;

  /// No description provided for @hotelCalendarHallsLabel.
  ///
  /// In en, this message translates to:
  /// **'Halls'**
  String get hotelCalendarHallsLabel;

  /// No description provided for @hotelCalendarHallsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get hotelCalendarHallsAll;

  /// No description provided for @hotelCalendarGridLabel.
  ///
  /// In en, this message translates to:
  /// **'Calendar, {month}'**
  String hotelCalendarGridLabel(String month);

  /// No description provided for @hotelCalendarPrevWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get hotelCalendarPrevWeek;

  /// No description provided for @hotelCalendarNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get hotelCalendarNextWeek;

  /// No description provided for @hotelCalendarPrevDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get hotelCalendarPrevDay;

  /// No description provided for @hotelCalendarNextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get hotelCalendarNextDay;

  /// No description provided for @hotelCalendarWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get hotelCalendarWeekLabel;

  /// No description provided for @hotelCalendarActionBlock.
  ///
  /// In en, this message translates to:
  /// **'Block dates'**
  String get hotelCalendarActionBlock;

  /// No description provided for @hotelCalendarActionSelect.
  ///
  /// In en, this message translates to:
  /// **'Select dates'**
  String get hotelCalendarActionSelect;

  /// No description provided for @hotelCalendarReadOnly.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get hotelCalendarReadOnly;

  /// No description provided for @hotelCalendarOfflineStamp.
  ///
  /// In en, this message translates to:
  /// **'Offline · {time}'**
  String hotelCalendarOfflineStamp(String time);

  /// No description provided for @hotelCalendarOfflineNeed.
  ///
  /// In en, this message translates to:
  /// **'Needs a connection'**
  String get hotelCalendarOfflineNeed;

  /// No description provided for @hotelCalendarNudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar up to date?'**
  String get hotelCalendarNudgeTitle;

  /// No description provided for @hotelCalendarNudgeDone.
  ///
  /// In en, this message translates to:
  /// **'Calendar confirmed'**
  String get hotelCalendarNudgeDone;

  /// No description provided for @hotelCalendarEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing booked'**
  String get hotelCalendarEmptyTitle;

  /// No description provided for @hotelCalendarAgendaTitle.
  ///
  /// In en, this message translates to:
  /// **'Agenda, {date}'**
  String hotelCalendarAgendaTitle(String date);

  /// No description provided for @hotelCalendarOpenDay.
  ///
  /// In en, this message translates to:
  /// **'Open day'**
  String get hotelCalendarOpenDay;

  /// No description provided for @hotelCalendarOpenLabel.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get hotelCalendarOpenLabel;

  /// No description provided for @hotelCalendarRequestedLabel.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get hotelCalendarRequestedLabel;

  /// No description provided for @hotelCalendarBlockedBy.
  ///
  /// In en, this message translates to:
  /// **'Blocked by {name}'**
  String hotelCalendarBlockedBy(String name);

  /// No description provided for @hotelCalendarBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get hotelCalendarBlock;

  /// No description provided for @hotelCalendarOffer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get hotelCalendarOffer;

  /// No description provided for @hotelCalendarCreateOffer.
  ///
  /// In en, this message translates to:
  /// **'Create offer'**
  String get hotelCalendarCreateOffer;

  /// No description provided for @hotelCalendarOpenThisDate.
  ///
  /// In en, this message translates to:
  /// **'Open date'**
  String get hotelCalendarOpenThisDate;

  /// No description provided for @hotelCalendarWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Can’t block'**
  String get hotelCalendarWhyTitle;

  /// No description provided for @hotelCalendarSoldOutReason.
  ///
  /// In en, this message translates to:
  /// **'A confirmed booking can’t be blocked. Cancel it first.'**
  String get hotelCalendarSoldOutReason;

  /// No description provided for @hotelCalendarSoftTitle.
  ///
  /// In en, this message translates to:
  /// **'Open weekends'**
  String get hotelCalendarSoftTitle;

  /// No description provided for @hotelCalendarSoftRow.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No open weekend dates in the next {days} days} one{{count} open weekend date in the next {days} days} other{{count} open weekend dates in the next {days} days}}'**
  String hotelCalendarSoftRow(int count, String days);

  /// No description provided for @hotelCalendarLegendSoft.
  ///
  /// In en, this message translates to:
  /// **'Open weekend'**
  String get hotelCalendarLegendSoft;

  /// No description provided for @hotelCalendarHallFact.
  ///
  /// In en, this message translates to:
  /// **'Hall'**
  String get hotelCalendarHallFact;

  /// No description provided for @hotelCalendarGuestsFact.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get hotelCalendarGuestsFact;

  /// No description provided for @hotelCalendarCapacityFact.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get hotelCalendarCapacityFact;

  /// No description provided for @hotelCalendarSessionFact.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get hotelCalendarSessionFact;

  /// No description provided for @hotelCalendarHoldLeft.
  ///
  /// In en, this message translates to:
  /// **'Time remaining'**
  String get hotelCalendarHoldLeft;

  /// No description provided for @hotelCalendarStartsFact.
  ///
  /// In en, this message translates to:
  /// **'Starts in'**
  String get hotelCalendarStartsFact;

  /// No description provided for @hotelCalendarBlockedByFact.
  ///
  /// In en, this message translates to:
  /// **'Blocked by'**
  String get hotelCalendarBlockedByFact;

  /// No description provided for @hotelCalendarAudienceWomen.
  ///
  /// In en, this message translates to:
  /// **'Ladies'**
  String get hotelCalendarAudienceWomen;

  /// No description provided for @hotelCalendarAudienceMen.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get hotelCalendarAudienceMen;

  /// No description provided for @hotelCalendarAudienceMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get hotelCalendarAudienceMixed;

  /// No description provided for @hotelCalendarKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get hotelCalendarKeyTitle;

  /// No description provided for @hotelCalendarRequestNote.
  ///
  /// In en, this message translates to:
  /// **'A request does not hold the date.'**
  String get hotelCalendarRequestNote;

  /// No description provided for @hotelCalendarTimes.
  ///
  /// In en, this message translates to:
  /// **'Times'**
  String get hotelCalendarTimes;

  /// No description provided for @hotelCalendarSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get hotelCalendarSetup;

  /// No description provided for @hotelCalendarEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get hotelCalendarEvent;

  /// No description provided for @hotelCalendarTeardown.
  ///
  /// In en, this message translates to:
  /// **'Teardown'**
  String get hotelCalendarTeardown;

  /// No description provided for @hotelCalendarTimelineLabel.
  ///
  /// In en, this message translates to:
  /// **'{hall}, timeline'**
  String hotelCalendarTimelineLabel(String hall);

  /// No description provided for @hotelCalendarOpenBooking.
  ///
  /// In en, this message translates to:
  /// **'Open booking'**
  String get hotelCalendarOpenBooking;

  /// No description provided for @hotelCalendarCall.
  ///
  /// In en, this message translates to:
  /// **'Call {name}'**
  String hotelCalendarCall(String name);

  /// No description provided for @hotelCalendarMessage.
  ///
  /// In en, this message translates to:
  /// **'Message {name}'**
  String hotelCalendarMessage(String name);

  /// No description provided for @hotelCalendarHintDrag.
  ///
  /// In en, this message translates to:
  /// **'Press and hold a date, then drag to the last one.'**
  String get hotelCalendarHintDrag;

  /// No description provided for @hotelCalendarHintTap.
  ///
  /// In en, this message translates to:
  /// **'Or tap the first date, then the last.'**
  String get hotelCalendarHintTap;

  /// No description provided for @hotelCalendarRangeNone.
  ///
  /// In en, this message translates to:
  /// **'Choose dates'**
  String get hotelCalendarRangeNone;

  /// No description provided for @hotelCalendarRangeSummary.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get hotelCalendarRangeSummary;

  /// No description provided for @hotelCalendarRangeBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get hotelCalendarRangeBlock;

  /// No description provided for @hotelCalendarRangeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get hotelCalendarRangeOpen;

  /// No description provided for @hotelCalendarRangeOffer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get hotelCalendarRangeOffer;

  /// No description provided for @hotelCalendarSheetBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block dates'**
  String get hotelCalendarSheetBlockTitle;

  /// No description provided for @hotelCalendarSheetOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Open dates'**
  String get hotelCalendarSheetOpenTitle;

  /// No description provided for @hotelCalendarModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Block or open'**
  String get hotelCalendarModeLabel;

  /// No description provided for @hotelCalendarModeBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get hotelCalendarModeBlock;

  /// No description provided for @hotelCalendarModeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get hotelCalendarModeOpen;

  /// No description provided for @hotelCalendarSumEdit.
  ///
  /// In en, this message translates to:
  /// **'Change dates'**
  String get hotelCalendarSumEdit;

  /// No description provided for @hotelCalendarShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get hotelCalendarShortcuts;

  /// No description provided for @hotelCalendarSession.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get hotelCalendarSession;

  /// No description provided for @hotelCalendarReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get hotelCalendarReason;

  /// No description provided for @hotelCalendarNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get hotelCalendarNote;

  /// No description provided for @hotelCalendarReasonOffline.
  ///
  /// In en, this message translates to:
  /// **'Booked offline'**
  String get hotelCalendarReasonOffline;

  /// No description provided for @hotelCalendarReasonMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get hotelCalendarReasonMaintenance;

  /// No description provided for @hotelCalendarReasonPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private event'**
  String get hotelCalendarReasonPrivate;

  /// No description provided for @hotelCalendarReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get hotelCalendarReasonOther;

  /// No description provided for @hotelCalendarVisibilityHint.
  ///
  /// In en, this message translates to:
  /// **'Couples stop seeing blocked dates within seconds.'**
  String get hotelCalendarVisibilityHint;

  /// No description provided for @hotelCalendarOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Opened dates go back on sale for couples.'**
  String get hotelCalendarOpenHint;

  /// No description provided for @hotelCalendarPendingWarn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No pending requests on {date}} one{{date} has {count} pending request. It will be marked unavailable.} other{{date} has {count} pending requests. They will be marked unavailable.}}'**
  String hotelCalendarPendingWarn(int count, String date);

  /// No description provided for @hotelCalendarConflictBody.
  ///
  /// In en, this message translates to:
  /// **'A date with a confirmed booking can’t be blocked. Cancel the booking first.'**
  String get hotelCalendarConflictBody;

  /// No description provided for @hotelCalendarConflictTip.
  ///
  /// In en, this message translates to:
  /// **'Or choose only the hall that is free.'**
  String get hotelCalendarConflictTip;

  /// No description provided for @hotelCalendarConflictCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get hotelCalendarConflictCancel;

  /// No description provided for @hotelCalendarReasonConflict.
  ///
  /// In en, this message translates to:
  /// **'Free dates only'**
  String get hotelCalendarReasonConflict;

  /// No description provided for @hotelCalendarReasonChoose.
  ///
  /// In en, this message translates to:
  /// **'Pick dates first'**
  String get hotelCalendarReasonChoose;

  /// No description provided for @hotelCalendarAlreadyBlocked.
  ///
  /// In en, this message translates to:
  /// **'Already blocked'**
  String get hotelCalendarAlreadyBlocked;

  /// No description provided for @hotelCalendarCtaBlock.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Block} one{Block {count} date} other{Block {count} dates}}'**
  String hotelCalendarCtaBlock(int count);

  /// No description provided for @hotelCalendarCtaOpen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Open} one{Open {count} date} other{Open {count} dates}}'**
  String hotelCalendarCtaOpen(int count);

  /// No description provided for @hotelCalendarOpenListTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked dates'**
  String get hotelCalendarOpenListTitle;

  /// No description provided for @hotelCalendarOpenEmpty.
  ///
  /// In en, this message translates to:
  /// **'No blocked dates'**
  String get hotelCalendarOpenEmpty;

  /// No description provided for @hotelCalendarToastBlocked.
  ///
  /// In en, this message translates to:
  /// **'Hidden from couples'**
  String get hotelCalendarToastBlocked;

  /// No description provided for @hotelCalendarToastOpened.
  ///
  /// In en, this message translates to:
  /// **'Open for booking'**
  String get hotelCalendarToastOpened;

  /// No description provided for @hotelCalendarPartialTitle.
  ///
  /// In en, this message translates to:
  /// **'Some dates skipped'**
  String get hotelCalendarPartialTitle;

  /// No description provided for @hotelCalendarSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save'**
  String get hotelCalendarSaveFailed;

  /// No description provided for @hotelCalendarEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar by email'**
  String get hotelCalendarEmailTitle;

  /// No description provided for @hotelCalendarEmailSwitch.
  ///
  /// In en, this message translates to:
  /// **'Invite me by email'**
  String get hotelCalendarEmailSwitch;

  /// No description provided for @hotelCalendarEmailAdd.
  ///
  /// In en, this message translates to:
  /// **'Another address'**
  String get hotelCalendarEmailAdd;

  /// No description provided for @hotelCalendarEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the address'**
  String get hotelCalendarEmailInvalid;

  /// No description provided for @hotelCalendarEmailTest.
  ///
  /// In en, this message translates to:
  /// **'Send a test'**
  String get hotelCalendarEmailTest;

  /// No description provided for @hotelCalendarEmailTestSent.
  ///
  /// In en, this message translates to:
  /// **'Test sent'**
  String get hotelCalendarEmailTestSent;

  /// No description provided for @hotelDecisionsFactsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get hotelDecisionsFactsLabel;

  /// No description provided for @hotelDecisionsFactDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get hotelDecisionsFactDate;

  /// No description provided for @hotelDecisionsFactGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get hotelDecisionsFactGuests;

  /// No description provided for @hotelDecisionsFactSession.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get hotelDecisionsFactSession;

  /// No description provided for @hotelDecisionsFactLadies.
  ///
  /// In en, this message translates to:
  /// **'Ladies'**
  String get hotelDecisionsFactLadies;

  /// No description provided for @hotelDecisionsFactMen.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get hotelDecisionsFactMen;

  /// No description provided for @hotelDecisionsFactMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get hotelDecisionsFactMixed;

  /// No description provided for @hotelDecisionsOfflineInfo.
  ///
  /// In en, this message translates to:
  /// **'Decisions are never queued, so nothing is half-sent.'**
  String get hotelDecisionsOfflineInfo;

  /// No description provided for @hotelDecisionsTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get hotelDecisionsTermsTitle;

  /// No description provided for @hotelDecisionsReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get hotelDecisionsReason;

  /// No description provided for @hotelDecisionsPickReason.
  ///
  /// In en, this message translates to:
  /// **'Pick a reason'**
  String get hotelDecisionsPickReason;

  /// No description provided for @hotelDecisionsNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get hotelDecisionsNote;

  /// No description provided for @hotelDecisionsNoteHelper.
  ///
  /// In en, this message translates to:
  /// **'Client sees this'**
  String get hotelDecisionsNoteHelper;

  /// No description provided for @hotelDecisionsNoteRequired.
  ///
  /// In en, this message translates to:
  /// **'Note required'**
  String get hotelDecisionsNoteRequired;

  /// No description provided for @hotelDecisionsViewBooking.
  ///
  /// In en, this message translates to:
  /// **'View request'**
  String get hotelDecisionsViewBooking;

  /// No description provided for @hotelDecisionsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get hotelDecisionsRefresh;

  /// No description provided for @hotelDecisionsAcceptTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept request'**
  String get hotelDecisionsAcceptTitle;

  /// No description provided for @hotelDecisionsAcceptCta.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get hotelDecisionsAcceptCta;

  /// No description provided for @hotelDecisionsAcceptConsequence.
  ///
  /// In en, this message translates to:
  /// **'This holds <f>{date}</f> for <n>{name}</n> for <f>{duration}</f>.'**
  String hotelDecisionsAcceptConsequence(String date, String name, String duration);

  /// No description provided for @hotelDecisionsAcceptConfirmRule.
  ///
  /// In en, this message translates to:
  /// **'If the client does not confirm, the date is released and their voucher goes back to them.'**
  String get hotelDecisionsAcceptConfirmRule;

  /// No description provided for @hotelDecisionsAcceptPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Paid to you directly, outside the app, after the client confirms.'**
  String get hotelDecisionsAcceptPriceHint;

  /// No description provided for @hotelDecisionsAcceptLowerHint.
  ///
  /// In en, this message translates to:
  /// **'A lower voucher price is optional and never higher than the quote. The client sees the new saving.'**
  String get hotelDecisionsAcceptLowerHint;

  /// No description provided for @hotelDecisionsAcceptHoldLabel.
  ///
  /// In en, this message translates to:
  /// **'Date held for {duration}'**
  String hotelDecisionsAcceptHoldLabel(String duration);

  /// No description provided for @hotelDecisionsAcceptDeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Client confirms by'**
  String get hotelDecisionsAcceptDeadlineLabel;

  /// No description provided for @hotelDecisionsAcceptOffApp.
  ///
  /// In en, this message translates to:
  /// **'Off-app'**
  String get hotelDecisionsAcceptOffApp;

  /// No description provided for @hotelDecisionsAcceptOthersLine.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} other request for this date} other{{count} other requests for this date}}'**
  String hotelDecisionsAcceptOthersLine(int count);

  /// No description provided for @hotelDecisionsAcceptCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get hotelDecisionsAcceptCompare;

  /// No description provided for @hotelDecisionsAcceptCompareThis.
  ///
  /// In en, this message translates to:
  /// **'This'**
  String get hotelDecisionsAcceptCompareThis;

  /// No description provided for @hotelDecisionsAcceptCompareOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get hotelDecisionsAcceptCompareOther;

  /// No description provided for @hotelDecisionsAcceptCompareReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get hotelDecisionsAcceptCompareReceived;

  /// No description provided for @hotelDecisionsAcceptLower.
  ///
  /// In en, this message translates to:
  /// **'Lower price'**
  String get hotelDecisionsAcceptLower;

  /// No description provided for @hotelDecisionsAcceptLowerLabel.
  ///
  /// In en, this message translates to:
  /// **'Reduce by'**
  String get hotelDecisionsAcceptLowerLabel;

  /// No description provided for @hotelDecisionsAcceptLowerTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Below the voucher price'**
  String get hotelDecisionsAcceptLowerTooHigh;

  /// No description provided for @hotelDecisionsAcceptedTitle.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get hotelDecisionsAcceptedTitle;

  /// No description provided for @hotelDecisionsAcceptedBody.
  ///
  /// In en, this message translates to:
  /// **'The date is held for <n>{name}</n>, who has until <f>{deadline}</f> to confirm.'**
  String hotelDecisionsAcceptedBody(String name, String deadline);

  /// No description provided for @hotelDecisionsAcceptedUndoHint.
  ///
  /// In en, this message translates to:
  /// **'The client is told in a few seconds. Undo until then.'**
  String get hotelDecisionsAcceptedUndoHint;

  /// No description provided for @hotelDecisionsNotifying.
  ///
  /// In en, this message translates to:
  /// **'Notifying client'**
  String get hotelDecisionsNotifying;

  /// No description provided for @hotelDecisionsUndoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Back to pending'**
  String get hotelDecisionsUndoneTitle;

  /// No description provided for @hotelDecisionsUndoneBody.
  ///
  /// In en, this message translates to:
  /// **'The date is released and the client was not told.'**
  String get hotelDecisionsUndoneBody;

  /// No description provided for @hotelDecisionsConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Date on hold'**
  String get hotelDecisionsConflictTitle;

  /// No description provided for @hotelDecisionsConflictBody.
  ///
  /// In en, this message translates to:
  /// **'Another client’s approved request holds <f>{date}</f> while they confirm. You can still offer a different date.'**
  String hotelDecisionsConflictBody(String date);

  /// No description provided for @hotelDecisionsAlreadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Already updated'**
  String get hotelDecisionsAlreadyTitle;

  /// No description provided for @hotelDecisionsAlreadyBody.
  ///
  /// In en, this message translates to:
  /// **'Someone on your team or the client changed it a moment ago. This is where it stands now.'**
  String get hotelDecisionsAlreadyBody;

  /// No description provided for @hotelDecisionsReleasedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request withdrawn'**
  String get hotelDecisionsReleasedTitle;

  /// No description provided for @hotelDecisionsReleasedBody.
  ///
  /// In en, this message translates to:
  /// **'The client’s voucher is no longer attached to your venue, so there is nothing to approve. The request leaves your list.'**
  String get hotelDecisionsReleasedBody;

  /// No description provided for @hotelDecisionsDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline request'**
  String get hotelDecisionsDeclineTitle;

  /// No description provided for @hotelDecisionsDeclineReasonDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get hotelDecisionsDeclineReasonDate;

  /// No description provided for @hotelDecisionsDeclineReasonCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get hotelDecisionsDeclineReasonCapacity;

  /// No description provided for @hotelDecisionsDeclineReasonPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get hotelDecisionsDeclineReasonPackage;

  /// No description provided for @hotelDecisionsDeclineReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get hotelDecisionsDeclineReasonOther;

  /// No description provided for @hotelDecisionsDeclineSuggestTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggest dates'**
  String get hotelDecisionsDeclineSuggestTitle;

  /// No description provided for @hotelDecisionsDeclineSuggestBody.
  ///
  /// In en, this message translates to:
  /// **'The client will see a gentle message and venues that are free on the same date.'**
  String get hotelDecisionsDeclineSuggestBody;

  /// No description provided for @hotelDecisionsDeclineVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher returns'**
  String get hotelDecisionsDeclineVoucher;

  /// No description provided for @hotelDecisionsDeclineVoucherInfo.
  ///
  /// In en, this message translates to:
  /// **'The client’s voucher goes back to them. Declining has no payment consequence.'**
  String get hotelDecisionsDeclineVoucherInfo;

  /// No description provided for @hotelDecisionsDeclineNoUndo.
  ///
  /// In en, this message translates to:
  /// **'A decline cannot be undone.'**
  String get hotelDecisionsDeclineNoUndo;

  /// No description provided for @hotelDecisionsDeclineNoUndoShort.
  ///
  /// In en, this message translates to:
  /// **'Can’t undo'**
  String get hotelDecisionsDeclineNoUndoShort;

  /// No description provided for @hotelDecisionsDeclineCtaNext.
  ///
  /// In en, this message translates to:
  /// **'Choose dates'**
  String get hotelDecisionsDeclineCtaNext;

  /// No description provided for @hotelDecisionsDeclineCta.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get hotelDecisionsDeclineCta;

  /// No description provided for @hotelDecisionsDeclinedTitle.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get hotelDecisionsDeclinedTitle;

  /// No description provided for @hotelDecisionsDeclinedBody.
  ///
  /// In en, this message translates to:
  /// **'The client has been told and their voucher is back with them.'**
  String get hotelDecisionsDeclinedBody;

  /// No description provided for @hotelDecisionsProposeTitle.
  ///
  /// In en, this message translates to:
  /// **'Propose date'**
  String get hotelDecisionsProposeTitle;

  /// No description provided for @hotelDecisionsProposeIntro.
  ///
  /// In en, this message translates to:
  /// **'Pick one to three free dates for the same hall and session. The client has {window} to reply.'**
  String hotelDecisionsProposeIntro(String window);

  /// No description provided for @hotelDecisionsProposeHold.
  ///
  /// In en, this message translates to:
  /// **'Every date keeps the quoted voucher price of {amount}. If a date normally costs more, you cover the difference.'**
  String hotelDecisionsProposeHold(String amount);

  /// No description provided for @hotelDecisionsProposeHallLabel.
  ///
  /// In en, this message translates to:
  /// **'Hall'**
  String get hotelDecisionsProposeHallLabel;

  /// No description provided for @hotelDecisionsProposeCalendarLabel.
  ///
  /// In en, this message translates to:
  /// **'Free dates for {hall}'**
  String hotelDecisionsProposeCalendarLabel(String hall);

  /// No description provided for @hotelDecisionsProposeOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original date'**
  String get hotelDecisionsProposeOriginal;

  /// No description provided for @hotelDecisionsProposeChosen.
  ///
  /// In en, this message translates to:
  /// **'Your proposal'**
  String get hotelDecisionsProposeChosen;

  /// No description provided for @hotelDecisionsProposeRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {date}'**
  String hotelDecisionsProposeRemove(String date);

  /// No description provided for @hotelDecisionsProposeTakenBadge.
  ///
  /// In en, this message translates to:
  /// **'Date taken'**
  String get hotelDecisionsProposeTakenBadge;

  /// No description provided for @hotelDecisionsProposeHeldLabel.
  ///
  /// In en, this message translates to:
  /// **'Voucher price held'**
  String get hotelDecisionsProposeHeldLabel;

  /// No description provided for @hotelDecisionsProposeLowerLabel.
  ///
  /// In en, this message translates to:
  /// **'Lower by'**
  String get hotelDecisionsProposeLowerLabel;

  /// No description provided for @hotelDecisionsProposeReplyLabel.
  ///
  /// In en, this message translates to:
  /// **'Client reply window'**
  String get hotelDecisionsProposeReplyLabel;

  /// No description provided for @hotelDecisionsProposeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No dates chosen} one{{count} date chosen} other{{count} dates chosen}}'**
  String hotelDecisionsProposeCount(int count);

  /// No description provided for @hotelDecisionsProposeCta.
  ///
  /// In en, this message translates to:
  /// **'Send proposal'**
  String get hotelDecisionsProposeCta;

  /// No description provided for @hotelDecisionsProposePick.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get hotelDecisionsProposePick;

  /// No description provided for @hotelDecisionsProposeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No free dates'**
  String get hotelDecisionsProposeEmptyTitle;

  /// No description provided for @hotelDecisionsProposeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No free dates in the next {days} for this hall.'**
  String hotelDecisionsProposeEmpty(String days);

  /// No description provided for @hotelDecisionsProposeEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Open calendar'**
  String get hotelDecisionsProposeEmptyAction;

  /// No description provided for @hotelDecisionsProposeNoHallTitle.
  ///
  /// In en, this message translates to:
  /// **'Agree in chat'**
  String get hotelDecisionsProposeNoHallTitle;

  /// No description provided for @hotelDecisionsProposeNoHallBody.
  ///
  /// In en, this message translates to:
  /// **'A service request has no hall calendar. Reply to the client in the chat to agree another day.'**
  String get hotelDecisionsProposeNoHallBody;

  /// No description provided for @hotelDecisionsProposeSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Proposal sent'**
  String get hotelDecisionsProposeSentTitle;

  /// No description provided for @hotelDecisionsProposeSentBody.
  ///
  /// In en, this message translates to:
  /// **'The request stays pending with your dates attached. If the client accepts one, a new {duration} confirm window starts.'**
  String hotelDecisionsProposeSentBody(String duration);

  /// No description provided for @hotelDecisionsProposeAwaiting.
  ///
  /// In en, this message translates to:
  /// **'Awaiting <n>{name}</n> · answer due <f>{deadline}</f>'**
  String hotelDecisionsProposeAwaiting(String name, String deadline);

  /// No description provided for @hotelDecisionsToastProposed.
  ///
  /// In en, this message translates to:
  /// **'Proposal sent · {window}'**
  String hotelDecisionsToastProposed(String window);

  /// No description provided for @hotelDecisionsCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get hotelDecisionsCancelTitle;

  /// No description provided for @hotelDecisionsCancelTitleApproved.
  ///
  /// In en, this message translates to:
  /// **'Withdraw approval'**
  String get hotelDecisionsCancelTitleApproved;

  /// No description provided for @hotelDecisionsCancelTalkTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat first'**
  String get hotelDecisionsCancelTalkTitle;

  /// No description provided for @hotelDecisionsCancelTalkBody.
  ///
  /// In en, this message translates to:
  /// **'A new date is agreed with the client in the chat. If the date moves, the client may need a new request.'**
  String get hotelDecisionsCancelTalkBody;

  /// No description provided for @hotelDecisionsCancelReasonHall.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get hotelDecisionsCancelReasonHall;

  /// No description provided for @hotelDecisionsCancelReasonSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety work'**
  String get hotelDecisionsCancelReasonSafety;

  /// No description provided for @hotelDecisionsCancelReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get hotelDecisionsCancelReasonOther;

  /// No description provided for @hotelDecisionsCancelConsequence.
  ///
  /// In en, this message translates to:
  /// **'What happens'**
  String get hotelDecisionsCancelConsequence;

  /// No description provided for @hotelDecisionsCancelVoucherInfo.
  ///
  /// In en, this message translates to:
  /// **'The client’s voucher goes back to them to use again.'**
  String get hotelDecisionsCancelVoucherInfo;

  /// No description provided for @hotelDecisionsCancelStrikeInfo.
  ///
  /// In en, this message translates to:
  /// **'A reliability strike is recorded and the date opens again.'**
  String get hotelDecisionsCancelStrikeInfo;

  /// No description provided for @hotelDecisionsCancelNoMoney.
  ///
  /// In en, this message translates to:
  /// **'No money moves in the app. Anything the client has already paid you is settled between the two of you.'**
  String get hotelDecisionsCancelNoMoney;

  /// No description provided for @hotelDecisionsConsReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get hotelDecisionsConsReturned;

  /// No description provided for @hotelDecisionsConsStrike.
  ///
  /// In en, this message translates to:
  /// **'Strike'**
  String get hotelDecisionsConsStrike;

  /// No description provided for @hotelDecisionsConsReopens.
  ///
  /// In en, this message translates to:
  /// **'Reopens'**
  String get hotelDecisionsConsReopens;

  /// No description provided for @hotelDecisionsCancelCta.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get hotelDecisionsCancelCta;

  /// No description provided for @hotelDecisionsCancelCtaApproved.
  ///
  /// In en, this message translates to:
  /// **'Withdraw approval'**
  String get hotelDecisionsCancelCtaApproved;

  /// No description provided for @hotelDecisionsCancelKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep booking'**
  String get hotelDecisionsCancelKeep;

  /// No description provided for @hotelDecisionsCancelKeepApproved.
  ///
  /// In en, this message translates to:
  /// **'Keep approval'**
  String get hotelDecisionsCancelKeepApproved;

  /// No description provided for @hotelDecisionsCancelDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking?'**
  String get hotelDecisionsCancelDialogTitle;

  /// No description provided for @hotelDecisionsCancelDialogTitleApproved.
  ///
  /// In en, this message translates to:
  /// **'Withdraw approval?'**
  String get hotelDecisionsCancelDialogTitleApproved;

  /// No description provided for @hotelDecisionsCancelDialogBody.
  ///
  /// In en, this message translates to:
  /// **'<n>{name}</n> · <f>{date}</f>'**
  String hotelDecisionsCancelDialogBody(String name, String date);

  /// No description provided for @hotelDecisionsCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get hotelDecisionsCancelledTitle;

  /// No description provided for @hotelDecisionsCancelledTitleApproved.
  ///
  /// In en, this message translates to:
  /// **'Approval withdrawn'**
  String get hotelDecisionsCancelledTitleApproved;

  /// No description provided for @hotelDecisionsCancelledWindow.
  ///
  /// In en, this message translates to:
  /// **'New offer'**
  String get hotelDecisionsCancelledWindow;

  /// No description provided for @hotelDecisionsCancelHiddenTitle.
  ///
  /// In en, this message translates to:
  /// **'Managers only'**
  String get hotelDecisionsCancelHiddenTitle;

  /// No description provided for @hotelDecisionsCancelHiddenBody.
  ///
  /// In en, this message translates to:
  /// **'Only an Admin or Manager can cancel a confirmed booking.'**
  String get hotelDecisionsCancelHiddenBody;

  /// No description provided for @hotelGrowOfflineStamp.
  ///
  /// In en, this message translates to:
  /// **'Offline · updated {time}'**
  String hotelGrowOfflineStamp(String time);

  /// No description provided for @hotelGrowErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing was changed. Check your connection and try again.'**
  String get hotelGrowErrorBody;

  /// No description provided for @hotelGrowTabsLabel.
  ///
  /// In en, this message translates to:
  /// **'Voucher prices by state'**
  String get hotelGrowTabsLabel;

  /// No description provided for @hotelGrowTabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get hotelGrowTabActive;

  /// No description provided for @hotelGrowTabScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get hotelGrowTabScheduled;

  /// No description provided for @hotelGrowTabEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get hotelGrowTabEnded;

  /// No description provided for @hotelGrowPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get hotelGrowPaused;

  /// No description provided for @hotelGrowAppliesAll.
  ///
  /// In en, this message translates to:
  /// **'All packages'**
  String get hotelGrowAppliesAll;

  /// No description provided for @hotelGrowSoftInsight.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No open weekend dates in the next {days} days} one{{count} open weekend date in the next {days} days} other{{count} open weekend dates in the next {days} days}}'**
  String hotelGrowSoftInsight(int count, num days);

  /// No description provided for @hotelGrowEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No time-boxed windows'**
  String get hotelGrowEmptyTitle;

  /// No description provided for @hotelGrowNoScheduledTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled'**
  String get hotelGrowNoScheduledTitle;

  /// No description provided for @hotelGrowNoEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'No ended windows'**
  String get hotelGrowNoEndedTitle;

  /// No description provided for @hotelGrowShowActive.
  ///
  /// In en, this message translates to:
  /// **'Show active prices'**
  String get hotelGrowShowActive;

  /// No description provided for @hotelGrowActionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Voucher price actions'**
  String get hotelGrowActionsLabel;

  /// No description provided for @hotelGrowStatStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get hotelGrowStatStarts;

  /// No description provided for @hotelGrowPreviewWaiting.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid voucher price to see the card as couples will see it.'**
  String get hotelGrowPreviewWaiting;

  /// No description provided for @hotelGrowPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'How couples see it'**
  String get hotelGrowPreviewLabel;

  /// No description provided for @hotelGrowEffectNote.
  ///
  /// In en, this message translates to:
  /// **'Pause and End take effect for couples at once.'**
  String get hotelGrowEffectNote;

  /// No description provided for @hotelGrowPause.
  ///
  /// In en, this message translates to:
  /// **'Pause window'**
  String get hotelGrowPause;

  /// No description provided for @hotelGrowResume.
  ///
  /// In en, this message translates to:
  /// **'Resume window'**
  String get hotelGrowResume;

  /// No description provided for @hotelGrowDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get hotelGrowDuplicate;

  /// No description provided for @hotelGrowEndNow.
  ///
  /// In en, this message translates to:
  /// **'End now'**
  String get hotelGrowEndNow;

  /// No description provided for @hotelGrowToastPaused.
  ///
  /// In en, this message translates to:
  /// **'{title} is paused. Couples see the standing voucher price.'**
  String hotelGrowToastPaused(String title);

  /// No description provided for @hotelGrowToastResumed.
  ///
  /// In en, this message translates to:
  /// **'{title} is live again.'**
  String hotelGrowToastResumed(String title);

  /// No description provided for @hotelGrowToastEnded.
  ///
  /// In en, this message translates to:
  /// **'{title} has ended.'**
  String hotelGrowToastEnded(String title);

  /// No description provided for @hotelGrowEndTitle.
  ///
  /// In en, this message translates to:
  /// **'End {title} now?'**
  String hotelGrowEndTitle(String title);

  /// No description provided for @hotelGrowEndBody.
  ///
  /// In en, this message translates to:
  /// **'Couples go back to the standing voucher price at once. Requests already sent keep their price. This cannot be undone.'**
  String get hotelGrowEndBody;

  /// No description provided for @hotelGrowEndConfirm.
  ///
  /// In en, this message translates to:
  /// **'End window'**
  String get hotelGrowEndConfirm;

  /// No description provided for @hotelGrowEndKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep window'**
  String get hotelGrowEndKeep;

  /// No description provided for @hotelGrowStepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Voucher price window steps'**
  String get hotelGrowStepsLabel;

  /// No description provided for @hotelGrowValueTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher price'**
  String get hotelGrowValueTitle;

  /// No description provided for @hotelGrowOverError.
  ///
  /// In en, this message translates to:
  /// **'The voucher price cannot be above the standard price, {max}.'**
  String hotelGrowOverError(String max);

  /// No description provided for @hotelGrowEmptyValueError.
  ///
  /// In en, this message translates to:
  /// **'Enter the voucher price in dinars, up to three decimals.'**
  String get hotelGrowEmptyValueError;

  /// No description provided for @hotelGrowBestOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the best voucher price applies to a request. Prices do not stack.'**
  String get hotelGrowBestOnly;

  /// No description provided for @hotelGrowScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Applies to'**
  String get hotelGrowScopeTitle;

  /// No description provided for @hotelGrowPackagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get hotelGrowPackagesLabel;

  /// No description provided for @hotelGrowHallsLabel.
  ///
  /// In en, this message translates to:
  /// **'Halls'**
  String get hotelGrowHallsLabel;

  /// No description provided for @hotelGrowAllHalls.
  ///
  /// In en, this message translates to:
  /// **'All halls'**
  String get hotelGrowAllHalls;

  /// No description provided for @hotelGrowTitleTitle.
  ///
  /// In en, this message translates to:
  /// **'Window title'**
  String get hotelGrowTitleTitle;

  /// No description provided for @hotelGrowTitleEn.
  ///
  /// In en, this message translates to:
  /// **'Title in English'**
  String get hotelGrowTitleEn;

  /// No description provided for @hotelGrowTitleAr.
  ///
  /// In en, this message translates to:
  /// **'Title in Arabic'**
  String get hotelGrowTitleAr;

  /// No description provided for @hotelGrowTitleComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get hotelGrowTitleComplete;

  /// No description provided for @hotelGrowCouplesSee.
  ///
  /// In en, this message translates to:
  /// **'Couples see'**
  String get hotelGrowCouplesSee;

  /// No description provided for @hotelGrowNextReasonTitles.
  ///
  /// In en, this message translates to:
  /// **'Add the title in both languages to continue.'**
  String get hotelGrowNextReasonTitles;

  /// No description provided for @hotelGrowNextReasonValue.
  ///
  /// In en, this message translates to:
  /// **'Correct the voucher price to continue.'**
  String get hotelGrowNextReasonValue;

  /// No description provided for @hotelGrowPrefilledTitle.
  ///
  /// In en, this message translates to:
  /// **'For these dates'**
  String get hotelGrowPrefilledTitle;

  /// No description provided for @hotelGrowOfflineEdit.
  ///
  /// In en, this message translates to:
  /// **'Offline. You can keep editing; publishing needs a connection.'**
  String get hotelGrowOfflineEdit;

  /// No description provided for @hotelGrowGuardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this window?'**
  String get hotelGrowGuardTitle;

  /// No description provided for @hotelGrowGuardDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get hotelGrowGuardDiscard;

  /// No description provided for @hotelGrowGuardKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get hotelGrowGuardKeep;

  /// No description provided for @hotelGrowEditorErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing was saved. Check your connection and try again.'**
  String get hotelGrowEditorErrorBody;

  /// No description provided for @hotelGrowDatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Event dates'**
  String get hotelGrowDatesTitle;

  /// No description provided for @hotelGrowShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get hotelGrowShortcuts;

  /// No description provided for @hotelGrowChooseDates.
  ///
  /// In en, this message translates to:
  /// **'Choose dates myself'**
  String get hotelGrowChooseDates;

  /// No description provided for @hotelGrowNoDatesError.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one event date.'**
  String get hotelGrowNoDatesError;

  /// No description provided for @hotelGrowDatesChosen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No dates chosen} one{{count} date chosen} other{{count} dates chosen}}'**
  String hotelGrowDatesChosen(int count);

  /// No description provided for @hotelGrowClearDates.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get hotelGrowClearDates;

  /// No description provided for @hotelGrowUseOpenDates.
  ///
  /// In en, this message translates to:
  /// **'Use open weekend dates'**
  String get hotelGrowUseOpenDates;

  /// No description provided for @hotelGrowOpenWeekend.
  ///
  /// In en, this message translates to:
  /// **'Open weekend date'**
  String get hotelGrowOpenWeekend;

  /// No description provided for @hotelGrowOverlap.
  ///
  /// In en, this message translates to:
  /// **'{title} at {value} already covers {dates}. The better voucher price applies.'**
  String hotelGrowOverlap(String title, String value, String dates);

  /// No description provided for @hotelGrowRunsTitle.
  ///
  /// In en, this message translates to:
  /// **'When it runs'**
  String get hotelGrowRunsTitle;

  /// No description provided for @hotelGrowScheduledPill.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get hotelGrowScheduledPill;

  /// No description provided for @hotelGrowStartsLabel.
  ///
  /// In en, this message translates to:
  /// **'Starts on'**
  String get hotelGrowStartsLabel;

  /// No description provided for @hotelGrowEndsLabel.
  ///
  /// In en, this message translates to:
  /// **'Ends on'**
  String get hotelGrowEndsLabel;

  /// No description provided for @hotelGrowEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'The end date is before the start date.'**
  String get hotelGrowEndBeforeStart;

  /// No description provided for @hotelGrowPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish window'**
  String get hotelGrowPublish;

  /// No description provided for @hotelGrowSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule window'**
  String get hotelGrowSchedule;

  /// No description provided for @hotelGrowOfflinePublish.
  ///
  /// In en, this message translates to:
  /// **'Reconnect to publish.'**
  String get hotelGrowOfflinePublish;

  /// No description provided for @hotelGrowReasonDates.
  ///
  /// In en, this message translates to:
  /// **'Choose the event dates first.'**
  String get hotelGrowReasonDates;

  /// No description provided for @hotelGrowReasonEnd.
  ///
  /// In en, this message translates to:
  /// **'Set a valid end date first.'**
  String get hotelGrowReasonEnd;

  /// No description provided for @hotelGrowPublishFailed.
  ///
  /// In en, this message translates to:
  /// **'The window was not published. Nothing changed; try again.'**
  String get hotelGrowPublishFailed;

  /// No description provided for @hotelGrowToastPublished.
  ///
  /// In en, this message translates to:
  /// **'{title} is live.'**
  String hotelGrowToastPublished(String title);

  /// No description provided for @hotelGrowToastScheduled.
  ///
  /// In en, this message translates to:
  /// **'{title} is scheduled.'**
  String hotelGrowToastScheduled(String title);

  /// No description provided for @hotelGrowView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get hotelGrowView;

  /// No description provided for @hotelGrowAnTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get hotelGrowAnTitle;

  /// No description provided for @hotelGrowAnRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get hotelGrowAnRangeLabel;

  /// No description provided for @hotelGrowAnRangeMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get hotelGrowAnRangeMonth;

  /// No description provided for @hotelGrowAnRangeDays.
  ///
  /// In en, this message translates to:
  /// **'Last {days} days'**
  String hotelGrowAnRangeDays(num days);

  /// No description provided for @hotelGrowAnRangeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get hotelGrowAnRangeCustom;

  /// No description provided for @hotelGrowAnRangeNote.
  ///
  /// In en, this message translates to:
  /// **'Data is available from {date}.'**
  String hotelGrowAnRangeNote(String date);

  /// No description provided for @hotelGrowAnKpiViews.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get hotelGrowAnKpiViews;

  /// No description provided for @hotelGrowAnKpiClicks.
  ///
  /// In en, this message translates to:
  /// **'Clicks'**
  String get hotelGrowAnKpiClicks;

  /// No description provided for @hotelGrowAnKpiConversion.
  ///
  /// In en, this message translates to:
  /// **'Conversion'**
  String get hotelGrowAnKpiConversion;

  /// No description provided for @hotelGrowAnVsPrevious.
  ///
  /// In en, this message translates to:
  /// **'vs previous period'**
  String get hotelGrowAnVsPrevious;

  /// No description provided for @hotelGrowAnChartDesc.
  ///
  /// In en, this message translates to:
  /// **'{metric}, from {from} to {to}.'**
  String hotelGrowAnChartDesc(String metric, String from, String to);

  /// No description provided for @hotelGrowAnAsTable.
  ///
  /// In en, this message translates to:
  /// **'View as table'**
  String get hotelGrowAnAsTable;

  /// No description provided for @hotelGrowAnAsChart.
  ///
  /// In en, this message translates to:
  /// **'View as chart'**
  String get hotelGrowAnAsChart;

  /// No description provided for @hotelGrowAnFunnelTitle.
  ///
  /// In en, this message translates to:
  /// **'From view to voucher'**
  String get hotelGrowAnFunnelTitle;

  /// No description provided for @hotelGrowAnFunnelDesc.
  ///
  /// In en, this message translates to:
  /// **'Views, clicks, vouchers purchased, requests, confirmed bookings and redeemed vouchers in the period.'**
  String get hotelGrowAnFunnelDesc;

  /// No description provided for @hotelGrowAnStageConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get hotelGrowAnStageConfirmed;

  /// No description provided for @hotelGrowAnValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get hotelGrowAnValueLabel;

  /// No description provided for @hotelGrowAnTopTitle.
  ///
  /// In en, this message translates to:
  /// **'Top packages'**
  String get hotelGrowAnTopTitle;

  /// No description provided for @hotelGrowAnTopDesc.
  ///
  /// In en, this message translates to:
  /// **'Confirmed bookings per package in the period.'**
  String get hotelGrowAnTopDesc;

  /// No description provided for @hotelGrowAnTopOpen.
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String hotelGrowAnTopOpen(String name);

  /// No description provided for @hotelGrowAnDefsTitle.
  ///
  /// In en, this message translates to:
  /// **'How we count'**
  String get hotelGrowAnDefsTitle;

  /// No description provided for @hotelGrowAnDefViews.
  ///
  /// In en, this message translates to:
  /// **'Each person counts once per {minutes} minutes, however many times they open your listing.'**
  String hotelGrowAnDefViews(num minutes);

  /// No description provided for @hotelGrowAnDefClicks.
  ///
  /// In en, this message translates to:
  /// **'Taps on Message, Call, Directions or Share after viewing your listing.'**
  String get hotelGrowAnDefClicks;

  /// No description provided for @hotelGrowAnDefConversion.
  ///
  /// In en, this message translates to:
  /// **'Confirmed bookings divided by views in the same period, credited to the last view within {days} days.'**
  String hotelGrowAnDefConversion(num days);

  /// No description provided for @hotelGrowAnCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom period'**
  String get hotelGrowAnCustomTitle;

  /// No description provided for @hotelGrowAnCustomOutside.
  ///
  /// In en, this message translates to:
  /// **'Days before {date} have no data.'**
  String hotelGrowAnCustomOutside(String date);

  /// No description provided for @hotelGrowAnEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get hotelGrowAnEmptyTitle;

  /// No description provided for @hotelGrowAnInsufBody.
  ///
  /// In en, this message translates to:
  /// **'Trends need at least {days} days of views. The totals so far are below.'**
  String hotelGrowAnInsufBody(num days);

  /// No description provided for @hotelGrowAnRoleAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Your role sees listing performance only.'**
  String get hotelGrowAnRoleAnalytics;

  /// No description provided for @hotelGrowRwTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get hotelGrowRwTitle;

  /// No description provided for @hotelGrowRwCatVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get hotelGrowRwCatVenue;

  /// No description provided for @hotelGrowRwCatFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get hotelGrowRwCatFood;

  /// No description provided for @hotelGrowRwCatService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get hotelGrowRwCatService;

  /// No description provided for @hotelGrowRwCatValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get hotelGrowRwCatValue;

  /// No description provided for @hotelGrowRwFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Show reviews'**
  String get hotelGrowRwFilterLabel;

  /// No description provided for @hotelGrowRwFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get hotelGrowRwFilterAll;

  /// No description provided for @hotelGrowRwFilterNeeds.
  ///
  /// In en, this message translates to:
  /// **'Needs reply'**
  String get hotelGrowRwFilterNeeds;

  /// No description provided for @hotelGrowRwFilterReplied.
  ///
  /// In en, this message translates to:
  /// **'Replied'**
  String get hotelGrowRwFilterReplied;

  /// No description provided for @hotelGrowRwFilterReported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get hotelGrowRwFilterReported;

  /// No description provided for @hotelGrowRwModerated.
  ///
  /// In en, this message translates to:
  /// **'Ghazal moderates reviews. Reply once or report abuse. To hide or delete a review, ask support.'**
  String get hotelGrowRwModerated;

  /// No description provided for @hotelGrowRwAskSupport.
  ///
  /// In en, this message translates to:
  /// **'Ask support to hide or delete'**
  String get hotelGrowRwAskSupport;

  /// No description provided for @hotelGrowRwReplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Reply to {name}'**
  String hotelGrowRwReplyTitle(String name);

  /// No description provided for @hotelGrowRwReplyHelp.
  ///
  /// In en, this message translates to:
  /// **'Public, signed with the venue name, and sent once.'**
  String get hotelGrowRwReplyHelp;

  /// No description provided for @hotelGrowRwReplySend.
  ///
  /// In en, this message translates to:
  /// **'Send reply'**
  String get hotelGrowRwReplySend;

  /// No description provided for @hotelGrowRwReplySent.
  ///
  /// In en, this message translates to:
  /// **'Your reply is published.'**
  String get hotelGrowRwReplySent;

  /// No description provided for @hotelGrowRwReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report this review'**
  String get hotelGrowRwReportTitle;

  /// No description provided for @hotelGrowRwReportBody.
  ///
  /// In en, this message translates to:
  /// **'Choose the reason. Ghazal reviews it and the review stays visible until then.'**
  String get hotelGrowRwReportBody;

  /// No description provided for @hotelGrowRwReasonAbuse.
  ///
  /// In en, this message translates to:
  /// **'Abusive language'**
  String get hotelGrowRwReasonAbuse;

  /// No description provided for @hotelGrowRwReasonOff.
  ///
  /// In en, this message translates to:
  /// **'Not about this venue'**
  String get hotelGrowRwReasonOff;

  /// No description provided for @hotelGrowRwReasonPersonal.
  ///
  /// In en, this message translates to:
  /// **'Shares personal data'**
  String get hotelGrowRwReasonPersonal;

  /// No description provided for @hotelGrowRwReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get hotelGrowRwReasonOther;

  /// No description provided for @hotelGrowRwReportSend.
  ///
  /// In en, this message translates to:
  /// **'Report review'**
  String get hotelGrowRwReportSend;

  /// No description provided for @hotelGrowRwReported.
  ///
  /// In en, this message translates to:
  /// **'Reported. Ghazal will review it.'**
  String get hotelGrowRwReported;

  /// No description provided for @hotelGrowRwEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get hotelGrowRwEmptyTitle;

  /// No description provided for @hotelGrowRwNoNeedsTitle.
  ///
  /// In en, this message translates to:
  /// **'Every review has a reply'**
  String get hotelGrowRwNoNeedsTitle;

  /// No description provided for @hotelGrowRwNoFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get hotelGrowRwNoFilterTitle;

  /// No description provided for @hotelGrowRwShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all reviews'**
  String get hotelGrowRwShowAll;

  /// No description provided for @hotelGrowRwAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get hotelGrowRwAnonymous;

  /// No description provided for @hotelGrowRwSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Overall rating'**
  String get hotelGrowRwSummaryLabel;

  /// No description provided for @hotelGrowListTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher prices'**
  String get hotelGrowListTitle;

  /// No description provided for @hotelGrowNewWindow.
  ///
  /// In en, this message translates to:
  /// **'New voucher price window'**
  String get hotelGrowNewWindow;

  /// No description provided for @hotelGrowEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher price window'**
  String get hotelGrowEditorTitle;

  /// No description provided for @hotelGrowAlwaysOn.
  ///
  /// In en, this message translates to:
  /// **'Always on'**
  String get hotelGrowAlwaysOn;

  /// No description provided for @hotelGrowStandingTitle.
  ///
  /// In en, this message translates to:
  /// **'Standing voucher prices'**
  String get hotelGrowStandingTitle;

  /// No description provided for @hotelGrowStandingEditCta.
  ///
  /// In en, this message translates to:
  /// **'Edit package prices'**
  String get hotelGrowStandingEditCta;

  /// No description provided for @hotelGrowStandingExplain.
  ///
  /// In en, this message translates to:
  /// **'Every package with a voucher price shows it beside the standard price all the time. A window lowers it for chosen event dates.'**
  String get hotelGrowStandingExplain;

  /// No description provided for @hotelGrowStandingNote.
  ///
  /// In en, this message translates to:
  /// **'Standing prices change in the package editor, not here.'**
  String get hotelGrowStandingNote;

  /// No description provided for @hotelGrowStatRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get hotelGrowStatRequests;

  /// No description provided for @hotelGrowStatConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get hotelGrowStatConfirmed;

  /// No description provided for @hotelGrowStatVouchers.
  ///
  /// In en, this message translates to:
  /// **'Vouchers bought'**
  String get hotelGrowStatVouchers;

  /// No description provided for @hotelGrowStatEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get hotelGrowStatEnds;

  /// No description provided for @hotelGrowUnitPackage.
  ///
  /// In en, this message translates to:
  /// **'per package'**
  String get hotelGrowUnitPackage;

  /// No description provided for @hotelGrowTitleSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Lower voucher price'**
  String get hotelGrowTitleSuggestion;

  /// No description provided for @hotelGrowPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Voucher price per guest'**
  String get hotelGrowPriceLabel;

  /// No description provided for @hotelGrowPriceLabelFlat.
  ///
  /// In en, this message translates to:
  /// **'Voucher price per package'**
  String get hotelGrowPriceLabelFlat;

  /// No description provided for @hotelGrowNoEffect.
  ///
  /// In en, this message translates to:
  /// **'This is not below the standing voucher price of {standing}, so it will not change what couples pay.'**
  String hotelGrowNoEffect(String standing);

  /// No description provided for @hotelGrowBelowFee.
  ///
  /// In en, this message translates to:
  /// **'The saving would not be more than the {fee} voucher fee, so couples are not offered a voucher at this price.'**
  String hotelGrowBelowFee(String fee);

  /// No description provided for @hotelGrowRequestPrice.
  ///
  /// In en, this message translates to:
  /// **'Request price'**
  String get hotelGrowRequestPrice;

  /// No description provided for @hotelGrowStandardPrice.
  ///
  /// In en, this message translates to:
  /// **'Standard price'**
  String get hotelGrowStandardPrice;

  /// No description provided for @hotelGrowYouSave.
  ///
  /// In en, this message translates to:
  /// **'Couples save'**
  String get hotelGrowYouSave;

  /// No description provided for @hotelGrowFeeNote.
  ///
  /// In en, this message translates to:
  /// **'Couples also pay Ghazal a {fee} voucher fee. It is not part of your price and you do not collect it.'**
  String hotelGrowFeeNote(String fee);

  /// No description provided for @hotelGrowOpenWeekends.
  ///
  /// In en, this message translates to:
  /// **'Open weekend dates'**
  String get hotelGrowOpenWeekends;

  /// No description provided for @hotelGrowWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get hotelGrowWeekdays;

  /// No description provided for @hotelGrowOpenWeekendsBody.
  ///
  /// In en, this message translates to:
  /// **'Open Thursday to Saturday dates in the next {days} days'**
  String hotelGrowOpenWeekendsBody(num days);

  /// No description provided for @hotelGrowWeekdaysBody.
  ///
  /// In en, this message translates to:
  /// **'Open Sunday to Wednesday dates in the next {days} days'**
  String hotelGrowWeekdaysBody(num days);

  /// No description provided for @hotelGrowUntilEnd.
  ///
  /// In en, this message translates to:
  /// **'Until I end it'**
  String get hotelGrowUntilEnd;

  /// No description provided for @hotelGrowEndRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose an end date, or turn on Until I end it.'**
  String get hotelGrowEndRequired;

  /// No description provided for @hotelGrowAnKpiVouchers.
  ///
  /// In en, this message translates to:
  /// **'Vouchers purchased'**
  String get hotelGrowAnKpiVouchers;

  /// No description provided for @hotelGrowAnKpiRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get hotelGrowAnKpiRequests;

  /// No description provided for @hotelGrowAnKpiRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Vouchers redeemed'**
  String get hotelGrowAnKpiRedeemed;

  /// No description provided for @hotelGrowAnDefVouchers.
  ///
  /// In en, this message translates to:
  /// **'Vouchers bought for your venue in the period, counted at payment, not at use.'**
  String get hotelGrowAnDefVouchers;

  /// No description provided for @hotelGrowFactDates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get hotelGrowFactDates;

  /// No description provided for @hotelGrowStatEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get hotelGrowStatEnded;

  /// No description provided for @hotelGrowUnitGuest.
  ///
  /// In en, this message translates to:
  /// **'Per guest'**
  String get hotelGrowUnitGuest;

  /// No description provided for @hotelGrowFactsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get hotelGrowFactsLabel;

  /// No description provided for @hotelGrowStandingCount.
  ///
  /// In en, this message translates to:
  /// **'Standing offers'**
  String get hotelGrowStandingCount;

  /// No description provided for @hotelGrowFeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher fee'**
  String get hotelGrowFeeTitle;

  /// No description provided for @hotelGrowExampleLabel.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get hotelGrowExampleLabel;

  /// No description provided for @hotelGrowFactGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get hotelGrowFactGuests;

  /// No description provided for @hotelGrowFactDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get hotelGrowFactDate;

  /// No description provided for @hotelGrowSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get hotelGrowSaving;

  /// No description provided for @hotelGrowCouplesPay.
  ///
  /// In en, this message translates to:
  /// **'Couples pay'**
  String get hotelGrowCouplesPay;

  /// No description provided for @hotelGrowOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get hotelGrowOffline;

  /// No description provided for @hotelGrowRwReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get hotelGrowRwReply;

  /// No description provided for @hotelGrowAnRangeFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get hotelGrowAnRangeFrom;

  /// No description provided for @hotelGrowAnRangeTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get hotelGrowAnRangeTo;

  /// No description provided for @hotelGrowEffectTitle.
  ///
  /// In en, this message translates to:
  /// **'Effect'**
  String get hotelGrowEffectTitle;

  /// No description provided for @hotelGrowFactPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get hotelGrowFactPackages;

  /// No description provided for @hotelGrowStandingInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Standing offers'**
  String get hotelGrowStandingInfoTitle;

  /// No description provided for @hotelGrowRwVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get hotelGrowRwVerified;

  /// No description provided for @hotelGrowRwPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get hotelGrowRwPosted;

  /// No description provided for @hotelGrowFactMen.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get hotelGrowFactMen;

  /// No description provided for @hotelGrowFactLadies.
  ///
  /// In en, this message translates to:
  /// **'Ladies'**
  String get hotelGrowFactLadies;

  /// No description provided for @hotelGrowRwYourReply.
  ///
  /// In en, this message translates to:
  /// **'Your reply'**
  String get hotelGrowRwYourReply;

  /// No description provided for @hotelGrowRwDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get hotelGrowRwDraft;

  /// No description provided for @hotelGrowRwReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get hotelGrowRwReport;

  /// No description provided for @hotelGrowStepPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get hotelGrowStepPrice;

  /// No description provided for @hotelGrowStepDates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get hotelGrowStepDates;

  /// No description provided for @hotelGrowBoundsLabel.
  ///
  /// In en, this message translates to:
  /// **'Price range'**
  String get hotelGrowBoundsLabel;

  /// No description provided for @hotelGrowStandingPrice.
  ///
  /// In en, this message translates to:
  /// **'Standing price'**
  String get hotelGrowStandingPrice;

  /// No description provided for @hotelGrowNoEffectTitle.
  ///
  /// In en, this message translates to:
  /// **'No change'**
  String get hotelGrowNoEffectTitle;

  /// No description provided for @hotelGrowNoEffectShort.
  ///
  /// In en, this message translates to:
  /// **'No change'**
  String get hotelGrowNoEffectShort;

  /// No description provided for @hotelGrowBelowFeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Below fee'**
  String get hotelGrowBelowFeeTitle;

  /// No description provided for @hotelGrowBelowFeeShort.
  ///
  /// In en, this message translates to:
  /// **'Under {fee} fee'**
  String hotelGrowBelowFeeShort(String fee);

  /// No description provided for @hotelGrowPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get hotelGrowPreviewTitle;

  /// No description provided for @hotelGrowRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get hotelGrowRulesTitle;

  /// No description provided for @hotelGrowPublishFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not published'**
  String get hotelGrowPublishFailedTitle;

  /// No description provided for @hotelGrowOverlapTitle.
  ///
  /// In en, this message translates to:
  /// **'Overlap'**
  String get hotelGrowOverlapTitle;

  /// No description provided for @hotelGrowLowerPrice.
  ///
  /// In en, this message translates to:
  /// **'Lower price'**
  String get hotelGrowLowerPrice;

  /// No description provided for @hotelGrowOpenDates.
  ///
  /// In en, this message translates to:
  /// **'Open dates'**
  String get hotelGrowOpenDates;

  /// No description provided for @hotelGrowAnApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get hotelGrowAnApproved;

  /// No description provided for @hotelGrowAnInsufTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough data'**
  String get hotelGrowAnInsufTitle;

  /// No description provided for @hotelGrowAnInsufShort.
  ///
  /// In en, this message translates to:
  /// **'{days} days needed'**
  String hotelGrowAnInsufShort(String days);

  /// No description provided for @hotelGrowRwReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get hotelGrowRwReviews;

  /// No description provided for @hotelGrowRwCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get hotelGrowRwCategories;

  /// No description provided for @hotelGrowRwMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get hotelGrowRwMore;

  /// No description provided for @hotelGrowRwRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get hotelGrowRwRulesTitle;

  /// No description provided for @hotelProviderOfflineStrip.
  ///
  /// In en, this message translates to:
  /// **'Offline · saved {time}'**
  String hotelProviderOfflineStrip(String time);

  /// No description provided for @hotelProviderNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get hotelProviderNeedsConnection;

  /// No description provided for @hotelProviderLangArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get hotelProviderLangArabic;

  /// No description provided for @hotelProviderLangEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get hotelProviderLangEnglish;

  /// No description provided for @hotelProviderFieldInArabic.
  ///
  /// In en, this message translates to:
  /// **'{field} · AR'**
  String hotelProviderFieldInArabic(String field);

  /// No description provided for @hotelProviderFieldInEnglish.
  ///
  /// In en, this message translates to:
  /// **'{field} · EN'**
  String hotelProviderFieldInEnglish(String field);

  /// No description provided for @hotelProviderPriceError.
  ///
  /// In en, this message translates to:
  /// **'Amount in dinars'**
  String get hotelProviderPriceError;

  /// No description provided for @hotelProviderListTitle.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get hotelProviderListTitle;

  /// No description provided for @hotelProviderListNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get hotelProviderListNew;

  /// No description provided for @hotelProviderListRoleReason.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get hotelProviderListRoleReason;

  /// No description provided for @hotelProviderListGroupAttention.
  ///
  /// In en, this message translates to:
  /// **'Action · {count}'**
  String hotelProviderListGroupAttention(num count);

  /// No description provided for @hotelProviderListGroupRunning.
  ///
  /// In en, this message translates to:
  /// **'Live · {count}'**
  String hotelProviderListGroupRunning(num count);

  /// No description provided for @hotelProviderListGroupEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended · {count}'**
  String hotelProviderListGroupEnded(num count);

  /// No description provided for @hotelProviderListRejectedBanner.
  ///
  /// In en, this message translates to:
  /// **'{count} not approved'**
  String hotelProviderListRejectedBanner(num count);

  /// No description provided for @hotelProviderListExpiryBanner.
  ///
  /// In en, this message translates to:
  /// **'Ends {date}'**
  String hotelProviderListExpiryBanner(String date);

  /// No description provided for @hotelProviderListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No listings yet'**
  String get hotelProviderListEmptyTitle;

  /// No description provided for @hotelProviderListErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Not loaded'**
  String get hotelProviderListErrorTitle;

  /// No description provided for @hotelProviderListErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed. Try again.'**
  String get hotelProviderListErrorBody;

  /// No description provided for @hotelProviderStepFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get hotelProviderStepFinish;

  /// No description provided for @hotelProviderStepChoosePlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get hotelProviderStepChoosePlan;

  /// No description provided for @hotelProviderStepFix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get hotelProviderStepFix;

  /// No description provided for @hotelProviderStepRenew.
  ///
  /// In en, this message translates to:
  /// **'Renew'**
  String get hotelProviderStepRenew;

  /// No description provided for @hotelProviderStepSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get hotelProviderStepSubmit;

  /// No description provided for @hotelProviderPlanContractTitle.
  ///
  /// In en, this message translates to:
  /// **'Business contract'**
  String get hotelProviderPlanContractTitle;

  /// No description provided for @hotelProviderPlanContractBody.
  ///
  /// In en, this message translates to:
  /// **'Terms as contracted'**
  String get hotelProviderPlanContractBody;

  /// No description provided for @hotelProviderPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get hotelProviderPlanTitle;

  /// No description provided for @hotelProviderPlanTitleRenew.
  ///
  /// In en, this message translates to:
  /// **'Renew'**
  String get hotelProviderPlanTitleRenew;

  /// No description provided for @hotelProviderPlanEditListing.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get hotelProviderPlanEditListing;

  /// No description provided for @hotelProviderPlanGroup.
  ///
  /// In en, this message translates to:
  /// **'Plan period'**
  String get hotelProviderPlanGroup;

  /// No description provided for @hotelProviderPlanInclTitle.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get hotelProviderPlanInclTitle;

  /// No description provided for @hotelProviderPlanIncl1.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get hotelProviderPlanIncl1;

  /// No description provided for @hotelProviderPlanIncl2.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get hotelProviderPlanIncl2;

  /// No description provided for @hotelProviderPlanIncl3.
  ///
  /// In en, this message translates to:
  /// **'Figures'**
  String get hotelProviderPlanIncl3;

  /// No description provided for @hotelProviderPlanContinue.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get hotelProviderPlanContinue;

  /// No description provided for @hotelProviderPlanReasonRates.
  ///
  /// In en, this message translates to:
  /// **'Rates soon'**
  String get hotelProviderPlanReasonRates;

  /// No description provided for @hotelProviderPlanReasonChoose.
  ///
  /// In en, this message translates to:
  /// **'Pick a plan'**
  String get hotelProviderPlanReasonChoose;

  /// No description provided for @hotelProviderPlanSubmittedToast.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get hotelProviderPlanSubmittedToast;

  /// No description provided for @hotelProviderPlanSampleNote.
  ///
  /// In en, this message translates to:
  /// **'Sample amounts'**
  String get hotelProviderPlanSampleNote;

  /// No description provided for @hotelProviderPlanPreviewSample.
  ///
  /// In en, this message translates to:
  /// **'Sample rates'**
  String get hotelProviderPlanPreviewSample;

  /// No description provided for @hotelProviderPlanRenewLive.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String hotelProviderPlanRenewLive(String date);

  /// No description provided for @hotelProviderPlanRenewExpired.
  ///
  /// In en, this message translates to:
  /// **'Ended {date}'**
  String hotelProviderPlanRenewExpired(String date);

  /// No description provided for @hotelProviderPlanErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Not loaded'**
  String get hotelProviderPlanErrorTitle;

  /// No description provided for @hotelProviderPlanErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed. Try again.'**
  String get hotelProviderPlanErrorBody;

  /// No description provided for @hotelProviderPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get hotelProviderPayTitle;

  /// No description provided for @hotelProviderPayTotal.
  ///
  /// In en, this message translates to:
  /// **'Plan total'**
  String get hotelProviderPayTotal;

  /// No description provided for @hotelProviderPayAction.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String hotelProviderPayAction(String amount);

  /// No description provided for @hotelProviderPayWith.
  ///
  /// In en, this message translates to:
  /// **'Pay with'**
  String get hotelProviderPayWith;

  /// No description provided for @hotelProviderChangeMethod.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get hotelProviderChangeMethod;

  /// No description provided for @hotelProviderMethodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get hotelProviderMethodsTitle;

  /// No description provided for @hotelProviderMethodKnet.
  ///
  /// In en, this message translates to:
  /// **'KNET'**
  String get hotelProviderMethodKnet;

  /// No description provided for @hotelProviderMethodVisa.
  ///
  /// In en, this message translates to:
  /// **'Visa'**
  String get hotelProviderMethodVisa;

  /// No description provided for @hotelProviderMethodMastercard.
  ///
  /// In en, this message translates to:
  /// **'Mastercard'**
  String get hotelProviderMethodMastercard;

  /// No description provided for @hotelProviderMethodApplePay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get hotelProviderMethodApplePay;

  /// No description provided for @hotelProviderMethodGooglePay.
  ///
  /// In en, this message translates to:
  /// **'Google Pay'**
  String get hotelProviderMethodGooglePay;

  /// No description provided for @hotelProviderSampleBadge.
  ///
  /// In en, this message translates to:
  /// **'Sample'**
  String get hotelProviderSampleBadge;

  /// No description provided for @hotelProviderRefundNote.
  ///
  /// In en, this message translates to:
  /// **'Fee refunds are handled by support, on request.'**
  String get hotelProviderRefundNote;

  /// No description provided for @hotelProviderSumListing.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get hotelProviderSumListing;

  /// No description provided for @hotelProviderSumPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get hotelProviderSumPlan;

  /// No description provided for @hotelProviderSumAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get hotelProviderSumAmount;

  /// No description provided for @hotelProviderSumPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get hotelProviderSumPaid;

  /// No description provided for @hotelProviderGatewayTitle.
  ///
  /// In en, this message translates to:
  /// **'{method}'**
  String hotelProviderGatewayTitle(String method);

  /// No description provided for @hotelProviderRedirectTitle.
  ///
  /// In en, this message translates to:
  /// **'To {method}'**
  String hotelProviderRedirectTitle(String method);

  /// No description provided for @hotelProviderRedirectBody.
  ///
  /// In en, this message translates to:
  /// **'Keep the app open.'**
  String get hotelProviderRedirectBody;

  /// No description provided for @hotelProviderConfirmingTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirming'**
  String get hotelProviderConfirmingTitle;

  /// No description provided for @hotelProviderConfirmingBody.
  ///
  /// In en, this message translates to:
  /// **'Please do not pay again.'**
  String get hotelProviderConfirmingBody;

  /// No description provided for @hotelProviderBankMerchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get hotelProviderBankMerchant;

  /// No description provided for @hotelProviderBankMerchantName.
  ///
  /// In en, this message translates to:
  /// **'Ghazal'**
  String get hotelProviderBankMerchantName;

  /// No description provided for @hotelProviderBankAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get hotelProviderBankAmount;

  /// No description provided for @hotelProviderBankCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get hotelProviderBankCard;

  /// No description provided for @hotelProviderBankExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get hotelProviderBankExpiry;

  /// No description provided for @hotelProviderBankPin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get hotelProviderBankPin;

  /// No description provided for @hotelProviderBankSubmit.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get hotelProviderBankSubmit;

  /// No description provided for @hotelProviderProtoLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank answer'**
  String get hotelProviderProtoLabel;

  /// No description provided for @hotelProviderProtoApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get hotelProviderProtoApproved;

  /// No description provided for @hotelProviderProtoDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get hotelProviderProtoDeclined;

  /// No description provided for @hotelProviderLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave payment?'**
  String get hotelProviderLeaveTitle;

  /// No description provided for @hotelProviderLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing was charged.'**
  String get hotelProviderLeaveBody;

  /// No description provided for @hotelProviderLeaveStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get hotelProviderLeaveStay;

  /// No description provided for @hotelProviderLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get hotelProviderLeaveConfirm;

  /// No description provided for @hotelProviderPaidTitle.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get hotelProviderPaidTitle;

  /// No description provided for @hotelProviderPaidBody.
  ///
  /// In en, this message translates to:
  /// **'Your listing is in review.'**
  String get hotelProviderPaidBody;

  /// No description provided for @hotelProviderRenewedTitle.
  ///
  /// In en, this message translates to:
  /// **'Renewed'**
  String get hotelProviderRenewedTitle;

  /// No description provided for @hotelProviderRenewedBody.
  ///
  /// In en, this message translates to:
  /// **'Your listing stays live.'**
  String get hotelProviderRenewedBody;

  /// No description provided for @hotelProviderRenewedNote.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String hotelProviderRenewedNote(String date);

  /// No description provided for @hotelProviderReceiptLink.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get hotelProviderReceiptLink;

  /// No description provided for @hotelProviderViewStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get hotelProviderViewStatus;

  /// No description provided for @hotelProviderBackToListings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get hotelProviderBackToListings;

  /// No description provided for @hotelProviderFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get hotelProviderFailedTitle;

  /// No description provided for @hotelProviderFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing was charged.'**
  String get hotelProviderFailedBody;

  /// No description provided for @hotelProviderRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get hotelProviderRetry;

  /// No description provided for @hotelProviderSwitchMethod.
  ///
  /// In en, this message translates to:
  /// **'Other method'**
  String get hotelProviderSwitchMethod;

  /// No description provided for @hotelProviderCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get hotelProviderCancelledTitle;

  /// No description provided for @hotelProviderCancelledBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing was charged. Your plan is saved.'**
  String get hotelProviderCancelledBody;

  /// No description provided for @hotelProviderBackToPay.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get hotelProviderBackToPay;

  /// No description provided for @hotelProviderBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Rates soon'**
  String get hotelProviderBlockedTitle;

  /// No description provided for @hotelProviderBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'Rates are not announced yet, so there is nothing to pay. Your listing and plan choice are kept.'**
  String get hotelProviderBlockedBody;

  /// No description provided for @hotelProviderBackToPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get hotelProviderBackToPlans;

  /// No description provided for @hotelProviderOfflinePay.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get hotelProviderOfflinePay;

  /// No description provided for @hotelProviderPayErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get hotelProviderPayErrorTitle;

  /// No description provided for @hotelProviderPayErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing was charged. Try again.'**
  String get hotelProviderPayErrorBody;

  /// No description provided for @hotelProviderReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get hotelProviderReceiptTitle;

  /// No description provided for @hotelProviderReceiptIssuer.
  ///
  /// In en, this message translates to:
  /// **'Ghazal'**
  String get hotelProviderReceiptIssuer;

  /// No description provided for @hotelProviderReceiptNumber.
  ///
  /// In en, this message translates to:
  /// **'No.'**
  String get hotelProviderReceiptNumber;

  /// No description provided for @hotelProviderReceiptDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get hotelProviderReceiptDate;

  /// No description provided for @hotelProviderReceiptListing.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get hotelProviderReceiptListing;

  /// No description provided for @hotelProviderReceiptPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get hotelProviderReceiptPlan;

  /// No description provided for @hotelProviderReceiptVia.
  ///
  /// In en, this message translates to:
  /// **'Via'**
  String get hotelProviderReceiptVia;

  /// No description provided for @hotelProviderReceiptFoot.
  ///
  /// In en, this message translates to:
  /// **'KWD'**
  String get hotelProviderReceiptFoot;

  /// No description provided for @hotelProviderReceiptSample.
  ///
  /// In en, this message translates to:
  /// **'Sample'**
  String get hotelProviderReceiptSample;

  /// No description provided for @hotelProviderRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get hotelProviderRequired;

  /// No description provided for @hotelProviderRetryShort.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get hotelProviderRetryShort;

  /// No description provided for @hotelProviderEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get hotelProviderEditorTitle;

  /// No description provided for @hotelProviderEditorTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New listing'**
  String get hotelProviderEditorTitleNew;

  /// No description provided for @hotelProviderEditorCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get hotelProviderEditorCategory;

  /// No description provided for @hotelProviderEditorCategoryPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get hotelProviderEditorCategoryPlaceholder;

  /// No description provided for @hotelProviderEditorTexts.
  ///
  /// In en, this message translates to:
  /// **'Texts'**
  String get hotelProviderEditorTexts;

  /// No description provided for @hotelProviderEditorTitleField.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get hotelProviderEditorTitleField;

  /// No description provided for @hotelProviderEditorDescField.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get hotelProviderEditorDescField;

  /// No description provided for @hotelProviderEditorPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get hotelProviderEditorPhotos;

  /// No description provided for @hotelProviderEditorPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get hotelProviderEditorPackages;

  /// No description provided for @hotelProviderEditorContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get hotelProviderEditorContact;

  /// No description provided for @hotelProviderEditorChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get hotelProviderEditorChat;

  /// No description provided for @hotelProviderEditorPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get hotelProviderEditorPhone;

  /// No description provided for @hotelProviderEditorContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get hotelProviderEditorContinue;

  /// No description provided for @hotelProviderEditorSubmitChanges.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get hotelProviderEditorSubmitChanges;

  /// No description provided for @hotelProviderEditorResubmit.
  ///
  /// In en, this message translates to:
  /// **'Resubmit'**
  String get hotelProviderEditorResubmit;

  /// No description provided for @hotelProviderEditorSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get hotelProviderEditorSaveDraft;

  /// No description provided for @hotelProviderEditorSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get hotelProviderEditorSaved;

  /// No description provided for @hotelProviderEditorSavedBanner.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get hotelProviderEditorSavedBanner;

  /// No description provided for @hotelProviderEditorDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get hotelProviderEditorDraftSaved;

  /// No description provided for @hotelProviderEditorDraftNeedsTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a title'**
  String get hotelProviderEditorDraftNeedsTitle;

  /// No description provided for @hotelProviderEditorFixFields.
  ///
  /// In en, this message translates to:
  /// **'Complete the marked fields'**
  String get hotelProviderEditorFixFields;

  /// No description provided for @hotelProviderEditorValidationNote.
  ///
  /// In en, this message translates to:
  /// **'Complete the marked fields'**
  String get hotelProviderEditorValidationNote;

  /// No description provided for @hotelProviderEditorError.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get hotelProviderEditorError;

  /// No description provided for @hotelProviderEditorLiveNote.
  ///
  /// In en, this message translates to:
  /// **'Live version stays'**
  String get hotelProviderEditorLiveNote;

  /// No description provided for @hotelProviderEditorRejectedNote.
  ///
  /// In en, this message translates to:
  /// **'{note}'**
  String hotelProviderEditorRejectedNote(String note);

  /// No description provided for @hotelProviderGuardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get hotelProviderGuardTitle;

  /// No description provided for @hotelProviderGuardBody.
  ///
  /// In en, this message translates to:
  /// **'Unsaved edits will be lost.'**
  String get hotelProviderGuardBody;

  /// No description provided for @hotelProviderGuardDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get hotelProviderGuardDiscard;

  /// No description provided for @hotelProviderGuardKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get hotelProviderGuardKeep;

  /// No description provided for @hotelProviderPhotoAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get hotelProviderPhotoAdd;

  /// No description provided for @hotelProviderPhotoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get hotelProviderPhotoRemove;

  /// No description provided for @hotelProviderPhotoCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get hotelProviderPhotoCover;

  /// No description provided for @hotelProviderCatsPrimary.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get hotelProviderCatsPrimary;

  /// No description provided for @hotelProviderCatsMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get hotelProviderCatsMore;

  /// No description provided for @hotelProviderCatsLimit.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max}'**
  String hotelProviderCatsLimit(num count, num max);

  /// No description provided for @hotelProviderPkgUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Unnamed'**
  String get hotelProviderPkgUnnamed;

  /// No description provided for @hotelProviderPkgAdd.
  ///
  /// In en, this message translates to:
  /// **'Add package'**
  String get hotelProviderPkgAdd;

  /// No description provided for @hotelProviderPkgNeeded.
  ///
  /// In en, this message translates to:
  /// **'Add a package'**
  String get hotelProviderPkgNeeded;

  /// No description provided for @hotelProviderPkgNoVoucher.
  ///
  /// In en, this message translates to:
  /// **'No voucher'**
  String get hotelProviderPkgNoVoucher;

  /// No description provided for @hotelProviderPkgNoVoucherFull.
  ///
  /// In en, this message translates to:
  /// **'No voucher. Saving must exceed {fee}.'**
  String hotelProviderPkgNoVoucherFull(String fee);

  /// No description provided for @hotelProviderPkgSaving.
  ///
  /// In en, this message translates to:
  /// **'Saves {amount}'**
  String hotelProviderPkgSaving(String amount);

  /// No description provided for @hotelProviderPkgSheetNew.
  ///
  /// In en, this message translates to:
  /// **'New package'**
  String get hotelProviderPkgSheetNew;

  /// No description provided for @hotelProviderPkgSheetEdit.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get hotelProviderPkgSheetEdit;

  /// No description provided for @hotelProviderPkgSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get hotelProviderPkgSave;

  /// No description provided for @hotelProviderPkgDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get hotelProviderPkgDelete;

  /// No description provided for @hotelProviderPkgName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get hotelProviderPkgName;

  /// No description provided for @hotelProviderPkgPerPackage.
  ///
  /// In en, this message translates to:
  /// **'package'**
  String get hotelProviderPkgPerPackage;

  /// No description provided for @hotelProviderPkgVoucherOver.
  ///
  /// In en, this message translates to:
  /// **'At or below standard'**
  String get hotelProviderPkgVoucherOver;

  /// No description provided for @hotelProviderPkgIncludes.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get hotelProviderPkgIncludes;

  /// No description provided for @hotelProviderPkgInclPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get hotelProviderPkgInclPlaceholder;

  /// No description provided for @hotelProviderPkgRemoveIncl.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String hotelProviderPkgRemoveIncl(String name);

  /// No description provided for @hotelProviderPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get hotelProviderPreviewTitle;

  /// No description provided for @hotelProviderPreviewNoTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get hotelProviderPreviewNoTitle;

  /// No description provided for @hotelProviderPreviewNoPackage.
  ///
  /// In en, this message translates to:
  /// **'Add a package'**
  String get hotelProviderPreviewNoPackage;

  /// No description provided for @hotelProviderReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get hotelProviderReviewTitle;

  /// No description provided for @hotelProviderReviewErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Not loaded'**
  String get hotelProviderReviewErrorTitle;

  /// No description provided for @hotelProviderReviewErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed. Try again.'**
  String get hotelProviderReviewErrorBody;

  /// No description provided for @hotelProviderHeadPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get hotelProviderHeadPendingTitle;

  /// No description provided for @hotelProviderHeadApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get hotelProviderHeadApprovedTitle;

  /// No description provided for @hotelProviderHeadLiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get hotelProviderHeadLiveTitle;

  /// No description provided for @hotelProviderHeadRevisionTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes in review'**
  String get hotelProviderHeadRevisionTitle;

  /// No description provided for @hotelProviderHeadRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get hotelProviderHeadRejectedTitle;

  /// No description provided for @hotelProviderLongWait.
  ///
  /// In en, this message translates to:
  /// **'{hours} h in review'**
  String hotelProviderLongWait(num hours);

  /// No description provided for @hotelProviderContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get hotelProviderContactSupport;

  /// No description provided for @hotelProviderReasons.
  ///
  /// In en, this message translates to:
  /// **'Team notes'**
  String get hotelProviderReasons;

  /// No description provided for @hotelProviderReasonContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get hotelProviderReasonContent;

  /// No description provided for @hotelProviderReasonCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get hotelProviderReasonCategory;

  /// No description provided for @hotelProviderReasonMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing details'**
  String get hotelProviderReasonMissing;

  /// No description provided for @hotelProviderReasonPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get hotelProviderReasonPricing;

  /// No description provided for @hotelProviderReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get hotelProviderReasonOther;

  /// No description provided for @hotelProviderAppReasonVerify.
  ///
  /// In en, this message translates to:
  /// **'Cannot verify'**
  String get hotelProviderAppReasonVerify;

  /// No description provided for @hotelProviderAppDemoNote.
  ///
  /// In en, this message translates to:
  /// **'Add your licence number and a clearer description.'**
  String get hotelProviderAppDemoNote;

  /// No description provided for @hotelProviderApprovalGuardTitle.
  ///
  /// In en, this message translates to:
  /// **'Listings open after approval'**
  String get hotelProviderApprovalGuardTitle;

  /// No description provided for @hotelProviderPlanRetained.
  ///
  /// In en, this message translates to:
  /// **'Fee refund: ask support'**
  String get hotelProviderPlanRetained;

  /// No description provided for @hotelProviderPlanRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refund recorded'**
  String get hotelProviderPlanRefunded;

  /// No description provided for @hotelProviderChoosePlanAgain.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get hotelProviderChoosePlanAgain;

  /// No description provided for @hotelProviderListingLabel.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get hotelProviderListingLabel;

  /// No description provided for @hotelProviderTimeline.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get hotelProviderTimeline;

  /// No description provided for @hotelProviderFacts.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get hotelProviderFacts;

  /// No description provided for @hotelProviderFactSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get hotelProviderFactSubmitted;

  /// No description provided for @hotelProviderFactFees.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get hotelProviderFactFees;

  /// No description provided for @hotelProviderFactNoFees.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get hotelProviderFactNoFees;

  /// No description provided for @hotelProviderFactPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get hotelProviderFactPaid;

  /// No description provided for @hotelProviderFactRatesSoon.
  ///
  /// In en, this message translates to:
  /// **'Rates soon'**
  String get hotelProviderFactRatesSoon;

  /// No description provided for @hotelProviderFactPlanEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get hotelProviderFactPlanEnds;

  /// No description provided for @hotelProviderDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} d'**
  String hotelProviderDaysLeft(num days);

  /// No description provided for @hotelProviderEditResubmit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get hotelProviderEditResubmit;

  /// No description provided for @hotelProviderViewPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get hotelProviderViewPerformance;

  /// No description provided for @hotelProviderProtoTitle.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get hotelProviderProtoTitle;

  /// No description provided for @hotelProviderProtoApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get hotelProviderProtoApprove;

  /// No description provided for @hotelProviderProtoReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get hotelProviderProtoReject;

  /// No description provided for @hotelProviderProtoNote.
  ///
  /// In en, this message translates to:
  /// **'Wrong category, unclear price.'**
  String get hotelProviderProtoNote;

  /// No description provided for @hotelProviderPerfTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get hotelProviderPerfTitle;

  /// No description provided for @hotelProviderPerfEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get hotelProviderPerfEdit;

  /// No description provided for @hotelProviderPerfErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Not loaded'**
  String get hotelProviderPerfErrorTitle;

  /// No description provided for @hotelProviderPerfErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed. Try again.'**
  String get hotelProviderPerfErrorBody;

  /// No description provided for @hotelProviderPerfEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No figures yet'**
  String get hotelProviderPerfEmptyTitle;

  /// No description provided for @hotelProviderPerfEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended {date}'**
  String hotelProviderPerfEnded(String date);

  /// No description provided for @hotelProviderPerfRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get hotelProviderPerfRangeLabel;

  /// No description provided for @hotelProviderPerfRangeMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get hotelProviderPerfRangeMonth;

  /// No description provided for @hotelProviderPerfRange30.
  ///
  /// In en, this message translates to:
  /// **'{days} d'**
  String hotelProviderPerfRange30(num days);

  /// No description provided for @hotelProviderPerfRange90.
  ///
  /// In en, this message translates to:
  /// **'{days} d'**
  String hotelProviderPerfRange90(num days);

  /// No description provided for @hotelProviderPerfRangeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get hotelProviderPerfRangeCustom;

  /// No description provided for @hotelProviderPerfViews.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get hotelProviderPerfViews;

  /// No description provided for @hotelProviderPerfSaves.
  ///
  /// In en, this message translates to:
  /// **'Saves'**
  String get hotelProviderPerfSaves;

  /// No description provided for @hotelProviderPerfVouchers.
  ///
  /// In en, this message translates to:
  /// **'Vouchers'**
  String get hotelProviderPerfVouchers;

  /// No description provided for @hotelProviderPerfRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get hotelProviderPerfRequests;

  /// No description provided for @hotelProviderPerfRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Redeemed'**
  String get hotelProviderPerfRedeemed;

  /// No description provided for @hotelProviderPerfVsPrevious.
  ///
  /// In en, this message translates to:
  /// **'vs before'**
  String get hotelProviderPerfVsPrevious;

  /// No description provided for @hotelProviderPerfFunnel.
  ///
  /// In en, this message translates to:
  /// **'Funnel'**
  String get hotelProviderPerfFunnel;

  /// No description provided for @hotelProviderPerfFunnelDesc.
  ///
  /// In en, this message translates to:
  /// **'Views to redeemed'**
  String get hotelProviderPerfFunnelDesc;

  /// No description provided for @hotelProviderPerfCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get hotelProviderPerfCount;

  /// No description provided for @hotelProviderPerfStep.
  ///
  /// In en, this message translates to:
  /// **'{percent}'**
  String hotelProviderPerfStep(String percent);

  /// No description provided for @hotelProviderPerfInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Pick {days}+ days'**
  String hotelProviderPerfInsufficient(num days);

  /// No description provided for @hotelProviderPerfTop.
  ///
  /// In en, this message translates to:
  /// **'Top packages'**
  String get hotelProviderPerfTop;

  /// No description provided for @hotelProviderPerfTopDesc.
  ///
  /// In en, this message translates to:
  /// **'By requests'**
  String get hotelProviderPerfTopDesc;

  /// No description provided for @hotelProviderPerfAsTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get hotelProviderPerfAsTable;

  /// No description provided for @hotelProviderPerfAsChart.
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get hotelProviderPerfAsChart;

  /// No description provided for @hotelProviderPerfVenueAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Venue analytics'**
  String get hotelProviderPerfVenueAnalytics;

  /// No description provided for @hotelProviderPerfAllListings.
  ///
  /// In en, this message translates to:
  /// **'All listings'**
  String get hotelProviderPerfAllListings;

  /// No description provided for @hotelProviderRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get hotelProviderRangeTitle;

  /// No description provided for @hotelProviderRangeHint.
  ///
  /// In en, this message translates to:
  /// **'Pick dates'**
  String get hotelProviderRangeHint;

  /// No description provided for @hotelProviderRangeApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get hotelProviderRangeApply;

  /// No description provided for @hotelProviderContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get hotelProviderContinue;

  /// No description provided for @hotelProviderChooseTitle.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get hotelProviderChooseTitle;

  /// No description provided for @hotelProviderChooseReason.
  ///
  /// In en, this message translates to:
  /// **'Pick one'**
  String get hotelProviderChooseReason;

  /// No description provided for @hotelProviderChooseChains.
  ///
  /// In en, this message translates to:
  /// **'Hotels and chains join through Ghazal.'**
  String get hotelProviderChooseChains;

  /// No description provided for @hotelProviderTypeProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Service provider'**
  String get hotelProviderTypeProviderTitle;

  /// No description provided for @hotelProviderTypeHallTitle.
  ///
  /// In en, this message translates to:
  /// **'Private hall'**
  String get hotelProviderTypeHallTitle;

  /// No description provided for @hotelProviderProfileName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get hotelProviderProfileName;

  /// No description provided for @hotelProviderFormBarEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit application'**
  String get hotelProviderFormBarEdit;

  /// No description provided for @hotelProviderProfileGovernorate.
  ///
  /// In en, this message translates to:
  /// **'Governorate'**
  String get hotelProviderProfileGovernorate;

  /// No description provided for @hotelProviderProfileCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get hotelProviderProfileCategories;

  /// No description provided for @hotelProviderFormOther.
  ///
  /// In en, this message translates to:
  /// **'Other category'**
  String get hotelProviderFormOther;

  /// No description provided for @hotelProviderFormOtherHelper.
  ///
  /// In en, this message translates to:
  /// **'Not in the list? Tell us.'**
  String get hotelProviderFormOtherHelper;

  /// No description provided for @hotelProviderCatsChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get hotelProviderCatsChoose;

  /// No description provided for @hotelProviderCatsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get hotelProviderCatsEdit;

  /// No description provided for @hotelProviderProfilePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get hotelProviderProfilePhone;

  /// No description provided for @hotelProviderFormContact.
  ///
  /// In en, this message translates to:
  /// **'Contact person'**
  String get hotelProviderFormContact;

  /// No description provided for @hotelProviderFormEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get hotelProviderFormEmail;

  /// No description provided for @hotelProviderFormEmailError.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get hotelProviderFormEmailError;

  /// No description provided for @hotelProviderFormAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get hotelProviderFormAccountTitle;

  /// No description provided for @hotelProviderFormBusinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Your business'**
  String get hotelProviderFormBusinessTitle;

  /// No description provided for @hotelProviderAccountRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get hotelProviderAccountRepeat;

  /// No description provided for @hotelProviderAccountEmailUsed.
  ///
  /// In en, this message translates to:
  /// **'Email already registered'**
  String get hotelProviderAccountEmailUsed;

  /// No description provided for @hotelProviderAccountPasswordWeak.
  ///
  /// In en, this message translates to:
  /// **'Password too weak'**
  String get hotelProviderAccountPasswordWeak;

  /// No description provided for @hotelProviderFormAbout.
  ///
  /// In en, this message translates to:
  /// **'Short description'**
  String get hotelProviderFormAbout;

  /// No description provided for @hotelProviderFormLicence.
  ///
  /// In en, this message translates to:
  /// **'Commercial licence'**
  String get hotelProviderFormLicence;

  /// No description provided for @hotelProviderFormFix.
  ///
  /// In en, this message translates to:
  /// **'Complete the marked fields.'**
  String get hotelProviderFormFix;

  /// No description provided for @hotelProviderFormResubmitNote.
  ///
  /// In en, this message translates to:
  /// **'Not approved: {note}'**
  String hotelProviderFormResubmitNote(String note);

  /// No description provided for @hotelProviderPhoneError.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get hotelProviderPhoneError;

  /// No description provided for @hotelProviderSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send application'**
  String get hotelProviderSubmit;

  /// No description provided for @hotelProviderSubmitErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Not submitted'**
  String get hotelProviderSubmitErrorTitle;

  /// No description provided for @hotelProviderSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. Try again.'**
  String get hotelProviderSubmitError;

  /// No description provided for @hotelProviderSubmittedBar.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get hotelProviderSubmittedBar;

  /// No description provided for @hotelProviderSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Application received'**
  String get hotelProviderSubmittedTitle;

  /// No description provided for @hotelProviderSubmittedLine.
  ///
  /// In en, this message translates to:
  /// **'Your account stays under review.'**
  String get hotelProviderSubmittedLine;

  /// No description provided for @hotelProviderSubmittedNext.
  ///
  /// In en, this message translates to:
  /// **'What next'**
  String get hotelProviderSubmittedNext;

  /// No description provided for @hotelProviderNextReview.
  ///
  /// In en, this message translates to:
  /// **'Ghazal reviews'**
  String get hotelProviderNextReview;

  /// No description provided for @hotelProviderNextEmail.
  ///
  /// In en, this message translates to:
  /// **'We email you'**
  String get hotelProviderNextEmail;

  /// No description provided for @hotelProviderNextListings.
  ///
  /// In en, this message translates to:
  /// **'Then add listings'**
  String get hotelProviderNextListings;

  /// No description provided for @hotelProviderSubmittedStatus.
  ///
  /// In en, this message translates to:
  /// **'Application status'**
  String get hotelProviderSubmittedStatus;

  /// No description provided for @hotelProviderRejectContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get hotelProviderRejectContent;

  /// No description provided for @hotelProviderRejectCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get hotelProviderRejectCategory;

  /// No description provided for @hotelProviderRejectDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get hotelProviderRejectDetails;

  /// No description provided for @hotelProviderRejectPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get hotelProviderRejectPricing;

  /// No description provided for @hotelProviderRejectOther.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get hotelProviderRejectOther;

  /// No description provided for @hotelProviderPlanSampleCta.
  ///
  /// In en, this message translates to:
  /// **'Sample amounts, prototype only. Not a real rate.'**
  String get hotelProviderPlanSampleCta;

  /// No description provided for @hotelProviderRefundTitle.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get hotelProviderRefundTitle;

  /// No description provided for @hotelProviderDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get hotelProviderDetails;

  /// No description provided for @hotelSettingsRoleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get hotelSettingsRoleManager;

  /// No description provided for @hotelSettingsRoleReception.
  ///
  /// In en, this message translates to:
  /// **'Reception'**
  String get hotelSettingsRoleReception;

  /// No description provided for @hotelSettingsRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get hotelSettingsRoleOwner;

  /// No description provided for @hotelSettingsStepUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm it’s you'**
  String get hotelSettingsStepUpTitle;

  /// No description provided for @hotelSettingsStepUpBodyStaff.
  ///
  /// In en, this message translates to:
  /// **'We send a code to your email.'**
  String get hotelSettingsStepUpBodyStaff;

  /// No description provided for @hotelSettingsStepUpSend.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get hotelSettingsStepUpSend;

  /// No description provided for @hotelSettingsMoreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get hotelSettingsMoreTitle;

  /// No description provided for @hotelSettingsMoreListing.
  ///
  /// In en, this message translates to:
  /// **'Your listing'**
  String get hotelSettingsMoreListing;

  /// No description provided for @hotelSettingsMoreCompleteness.
  ///
  /// In en, this message translates to:
  /// **'Language completeness'**
  String get hotelSettingsMoreCompleteness;

  /// No description provided for @hotelSettingsMoreLangAr.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get hotelSettingsMoreLangAr;

  /// No description provided for @hotelSettingsMoreLangEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get hotelSettingsMoreLangEn;

  /// No description provided for @hotelSettingsMorePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get hotelSettingsMorePreview;

  /// No description provided for @hotelSettingsMorePreviewHeld.
  ///
  /// In en, this message translates to:
  /// **'Preview opens once your listing is approved.'**
  String get hotelSettingsMorePreviewHeld;

  /// No description provided for @hotelSettingsMoreGroupVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get hotelSettingsMoreGroupVenue;

  /// No description provided for @hotelSettingsMoreGroupVisits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get hotelSettingsMoreGroupVisits;

  /// No description provided for @hotelSettingsMoreGroupGrow.
  ///
  /// In en, this message translates to:
  /// **'Grow'**
  String get hotelSettingsMoreGroupGrow;

  /// No description provided for @hotelSettingsMoreGroupBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get hotelSettingsMoreGroupBusiness;

  /// No description provided for @hotelSettingsMoreGroupAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get hotelSettingsMoreGroupAccount;

  /// No description provided for @hotelSettingsMoreMedia.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get hotelSettingsMoreMedia;

  /// No description provided for @hotelSettingsMorePackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get hotelSettingsMorePackages;

  /// No description provided for @hotelSettingsMoreHalls.
  ///
  /// In en, this message translates to:
  /// **'Halls'**
  String get hotelSettingsMoreHalls;

  /// No description provided for @hotelSettingsMorePolicies.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get hotelSettingsMorePolicies;

  /// No description provided for @hotelSettingsMoreRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get hotelSettingsMoreRules;

  /// No description provided for @hotelSettingsMoreAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get hotelSettingsMoreAvailability;

  /// No description provided for @hotelSettingsMoreVisitRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get hotelSettingsMoreVisitRequests;

  /// No description provided for @hotelSettingsMoreVisitAvailability.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get hotelSettingsMoreVisitAvailability;

  /// No description provided for @hotelSettingsMoreVoucherPrices.
  ///
  /// In en, this message translates to:
  /// **'Voucher prices'**
  String get hotelSettingsMoreVoucherPrices;

  /// No description provided for @hotelSettingsMoreAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get hotelSettingsMoreAnalytics;

  /// No description provided for @hotelSettingsMoreReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get hotelSettingsMoreReviews;

  /// No description provided for @hotelSettingsMoreListings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get hotelSettingsMoreListings;

  /// No description provided for @hotelSettingsMorePerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get hotelSettingsMorePerformance;

  /// No description provided for @hotelSettingsMoreNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get hotelSettingsMoreNotifications;

  /// No description provided for @hotelSettingsMoreStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get hotelSettingsMoreStaff;

  /// No description provided for @hotelSettingsMoreHours.
  ///
  /// In en, this message translates to:
  /// **'Business hours'**
  String get hotelSettingsMoreHours;

  /// No description provided for @hotelSettingsMoreLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get hotelSettingsMoreLanguage;

  /// No description provided for @hotelSettingsMoreBiometric.
  ///
  /// In en, this message translates to:
  /// **'Biometric lock'**
  String get hotelSettingsMoreBiometric;

  /// No description provided for @hotelSettingsMoreSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get hotelSettingsMoreSupport;

  /// No description provided for @hotelSettingsMoreSupportToast.
  ///
  /// In en, this message translates to:
  /// **'Support chat'**
  String get hotelSettingsMoreSupportToast;

  /// No description provided for @hotelSettingsMoreSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch venue'**
  String get hotelSettingsMoreSwitch;

  /// No description provided for @hotelSettingsMoreLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get hotelSettingsMoreLogout;

  /// No description provided for @hotelSettingsMoreVersion.
  ///
  /// In en, this message translates to:
  /// **'{version}'**
  String hotelSettingsMoreVersion(String version);

  /// No description provided for @hotelSettingsMoreTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get hotelSettingsMoreTerms;

  /// No description provided for @hotelSettingsMorePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get hotelSettingsMorePrivacy;

  /// No description provided for @hotelSettingsMoreLegalToast.
  ///
  /// In en, this message translates to:
  /// **'Texts managed by Ghazal'**
  String get hotelSettingsMoreLegalToast;

  /// No description provided for @hotelSettingsMoreAccountType.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get hotelSettingsMoreAccountType;

  /// No description provided for @hotelSettingsMoreBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get hotelSettingsMoreBilling;

  /// No description provided for @hotelSettingsMoreBillingAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get hotelSettingsMoreBillingAttention;

  /// No description provided for @hotelSettingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get hotelSettingsLanguageTitle;

  /// No description provided for @hotelSettingsLanguageSaved.
  ///
  /// In en, this message translates to:
  /// **'Language saved'**
  String get hotelSettingsLanguageSaved;

  /// No description provided for @hotelSettingsSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch venue'**
  String get hotelSettingsSwitchTitle;

  /// No description provided for @hotelSettingsSwitchCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current venue'**
  String get hotelSettingsSwitchCurrent;

  /// No description provided for @hotelSettingsLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get hotelSettingsLogoutTitle;

  /// No description provided for @hotelSettingsBiometricOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on biometric lock?'**
  String get hotelSettingsBiometricOnTitle;

  /// No description provided for @hotelSettingsBiometricOnConfirm.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get hotelSettingsBiometricOnConfirm;

  /// No description provided for @hotelSettingsBiometricOn.
  ///
  /// In en, this message translates to:
  /// **'Lock on'**
  String get hotelSettingsBiometricOn;

  /// No description provided for @hotelSettingsBiometricOff.
  ///
  /// In en, this message translates to:
  /// **'Lock off'**
  String get hotelSettingsBiometricOff;

  /// No description provided for @hotelSettingsPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get hotelSettingsPreviewTitle;

  /// No description provided for @hotelSettingsAcctTitle.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get hotelSettingsAcctTitle;

  /// No description provided for @hotelSettingsAcctVenue.
  ///
  /// In en, this message translates to:
  /// **'Hotel or hall'**
  String get hotelSettingsAcctVenue;

  /// No description provided for @hotelSettingsAcctProvider.
  ///
  /// In en, this message translates to:
  /// **'Service provider'**
  String get hotelSettingsAcctProvider;

  /// No description provided for @hotelSettingsAcctSetup.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get hotelSettingsAcctSetup;

  /// No description provided for @hotelSettingsAcctSwitchedVenue.
  ///
  /// In en, this message translates to:
  /// **'Hotel or hall'**
  String get hotelSettingsAcctSwitchedVenue;

  /// No description provided for @hotelSettingsAcctSwitchedProvider.
  ///
  /// In en, this message translates to:
  /// **'Service provider'**
  String get hotelSettingsAcctSwitchedProvider;

  /// No description provided for @hotelSettingsNotifAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About alerts'**
  String get hotelSettingsNotifAboutTitle;

  /// No description provided for @hotelSettingsNotifAboutLock.
  ///
  /// In en, this message translates to:
  /// **'New request alerts are always on for your role, with a sound of their own.'**
  String get hotelSettingsNotifAboutLock;

  /// No description provided for @hotelSettingsNotifAboutQuiet.
  ///
  /// In en, this message translates to:
  /// **'Outside business hours the alert is silent and still appears in your list.'**
  String get hotelSettingsNotifAboutQuiet;

  /// No description provided for @hotelSettingsNotifAboutChannel.
  ///
  /// In en, this message translates to:
  /// **'Alerts arrive as push notifications. Urgent escalations also come by email, and there is no marketing push.'**
  String get hotelSettingsNotifAboutChannel;

  /// No description provided for @hotelSettingsNotifPushOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications off'**
  String get hotelSettingsNotifPushOffTitle;

  /// No description provided for @hotelSettingsNotifPushOffBody.
  ///
  /// In en, this message translates to:
  /// **'You will not hear about new requests until you turn them on, and the reply clock keeps running. Nothing else here is affected.'**
  String get hotelSettingsNotifPushOffBody;

  /// No description provided for @hotelSettingsNotifPushOffAction.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get hotelSettingsNotifPushOffAction;

  /// No description provided for @hotelSettingsNotifPushOffToast.
  ///
  /// In en, this message translates to:
  /// **'Opens phone settings'**
  String get hotelSettingsNotifPushOffToast;

  /// No description provided for @hotelSettingsNotifNewRequest.
  ///
  /// In en, this message translates to:
  /// **'New requests'**
  String get hotelSettingsNotifNewRequest;

  /// No description provided for @hotelSettingsNotifAlwaysOn.
  ///
  /// In en, this message translates to:
  /// **'Always on'**
  String get hotelSettingsNotifAlwaysOn;

  /// No description provided for @hotelSettingsNotifPlaySound.
  ///
  /// In en, this message translates to:
  /// **'Play sound'**
  String get hotelSettingsNotifPlaySound;

  /// No description provided for @hotelSettingsNotifPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get hotelSettingsNotifPlaying;

  /// No description provided for @hotelSettingsNotifConfirmations.
  ///
  /// In en, this message translates to:
  /// **'Confirmations'**
  String get hotelSettingsNotifConfirmations;

  /// No description provided for @hotelSettingsNotifCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancellations'**
  String get hotelSettingsNotifCancelled;

  /// No description provided for @hotelSettingsNotifRedemptions.
  ///
  /// In en, this message translates to:
  /// **'Vouchers'**
  String get hotelSettingsNotifRedemptions;

  /// No description provided for @hotelSettingsNotifVisits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get hotelSettingsNotifVisits;

  /// No description provided for @hotelSettingsNotifMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get hotelSettingsNotifMessages;

  /// No description provided for @hotelSettingsNotifReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get hotelSettingsNotifReviews;

  /// No description provided for @hotelSettingsNotifListing.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get hotelSettingsNotifListing;

  /// No description provided for @hotelSettingsNotifPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get hotelSettingsNotifPlan;

  /// No description provided for @hotelSettingsStaffInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite staff'**
  String get hotelSettingsStaffInvite;

  /// No description provided for @hotelSettingsStaffYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get hotelSettingsStaffYou;

  /// No description provided for @hotelSettingsStaffSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get hotelSettingsStaffSupport;

  /// No description provided for @hotelSettingsStaffEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Only you'**
  String get hotelSettingsStaffEmptyTitle;

  /// No description provided for @hotelSettingsStaffName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get hotelSettingsStaffName;

  /// No description provided for @hotelSettingsStaffNameError.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get hotelSettingsStaffNameError;

  /// No description provided for @hotelSettingsStaffRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get hotelSettingsStaffRole;

  /// No description provided for @hotelSettingsStaffAccept.
  ///
  /// In en, this message translates to:
  /// **'Reply to requests'**
  String get hotelSettingsStaffAccept;

  /// No description provided for @hotelSettingsStaffSend.
  ///
  /// In en, this message translates to:
  /// **'Send invite'**
  String get hotelSettingsStaffSend;

  /// No description provided for @hotelSettingsStaffSent.
  ///
  /// In en, this message translates to:
  /// **'Invite sent'**
  String get hotelSettingsStaffSent;

  /// No description provided for @hotelSettingsStaffSaveRole.
  ///
  /// In en, this message translates to:
  /// **'Save role'**
  String get hotelSettingsStaffSaveRole;

  /// No description provided for @hotelSettingsStaffSessions.
  ///
  /// In en, this message translates to:
  /// **'End sessions'**
  String get hotelSettingsStaffSessions;

  /// No description provided for @hotelSettingsStaffSessionsDone.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get hotelSettingsStaffSessionsDone;

  /// No description provided for @hotelSettingsStaffDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get hotelSettingsStaffDeactivate;

  /// No description provided for @hotelSettingsStaffDeactivated.
  ///
  /// In en, this message translates to:
  /// **'{name} deactivated'**
  String hotelSettingsStaffDeactivated(String name);

  /// No description provided for @hotelSettingsStaffReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get hotelSettingsStaffReactivate;

  /// No description provided for @hotelSettingsStaffReactivated.
  ///
  /// In en, this message translates to:
  /// **'{name} active'**
  String hotelSettingsStaffReactivated(String name);

  /// No description provided for @hotelSettingsStaffRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get hotelSettingsStaffRemove;

  /// No description provided for @hotelSettingsStaffRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String hotelSettingsStaffRemoveTitle(String name);

  /// No description provided for @hotelSettingsStaffRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get hotelSettingsStaffRemoveConfirm;

  /// No description provided for @hotelSettingsStaffRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed'**
  String hotelSettingsStaffRemoved(String name);

  /// No description provided for @hotelSettingsStaffResend.
  ///
  /// In en, this message translates to:
  /// **'Resend invite'**
  String get hotelSettingsStaffResend;

  /// No description provided for @hotelSettingsStaffResent.
  ///
  /// In en, this message translates to:
  /// **'Invite resent'**
  String get hotelSettingsStaffResent;

  /// No description provided for @hotelSettingsStaffOpen.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String hotelSettingsStaffOpen(String name);

  /// No description provided for @hotelSettingsStaffLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen'**
  String get hotelSettingsStaffLastSeen;

  /// No description provided for @hotelSettingsStaffExpires.
  ///
  /// In en, this message translates to:
  /// **'Invite expires'**
  String get hotelSettingsStaffExpires;

  /// No description provided for @hotelSettingsStaffStateDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get hotelSettingsStaffStateDeactivated;

  /// No description provided for @hotelSettingsStaffAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About roles'**
  String get hotelSettingsStaffAboutTitle;

  /// No description provided for @hotelSettingsStaffVisitNote.
  ///
  /// In en, this message translates to:
  /// **'Whoever manages visits can read the visit group chats, which also include Ghazal Support.'**
  String get hotelSettingsStaffVisitNote;

  /// No description provided for @hotelSettingsStaffFoot.
  ///
  /// In en, this message translates to:
  /// **'Admin can’t be assigned from the app. Ghazal support handles ownership transfers.'**
  String get hotelSettingsStaffFoot;

  /// No description provided for @hotelSettingsRoleLineManager.
  ///
  /// In en, this message translates to:
  /// **'Everything, including redeeming vouchers, visits, listings and billing; not staff'**
  String get hotelSettingsRoleLineManager;

  /// No description provided for @hotelSettingsRoleLineReception.
  ///
  /// In en, this message translates to:
  /// **'Requests, redeeming vouchers, visits and chat'**
  String get hotelSettingsRoleLineReception;

  /// No description provided for @hotelSettingsRoleLineAccountant.
  ///
  /// In en, this message translates to:
  /// **'Billing and receipts; requests to read only'**
  String get hotelSettingsRoleLineAccountant;

  /// No description provided for @hotelSettingsRoleLineMarketing.
  ///
  /// In en, this message translates to:
  /// **'Voucher prices, listings, analytics and photos'**
  String get hotelSettingsRoleLineMarketing;

  /// No description provided for @hotelSettingsHoursAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About hours'**
  String get hotelSettingsHoursAboutTitle;

  /// No description provided for @hotelSettingsHoursAbout.
  ///
  /// In en, this message translates to:
  /// **'Couples see these as working hours, and they decide when new-request alerts make a sound.'**
  String get hotelSettingsHoursAbout;

  /// No description provided for @hotelSettingsHoursApproxNote.
  ///
  /// In en, this message translates to:
  /// **'Ramadan and the Eids are estimates until announced. Adjust them when they are.'**
  String get hotelSettingsHoursApproxNote;

  /// No description provided for @hotelSettingsHoursPreview.
  ///
  /// In en, this message translates to:
  /// **'Shown to couples as'**
  String get hotelSettingsHoursPreview;

  /// No description provided for @hotelSettingsHoursLine.
  ///
  /// In en, this message translates to:
  /// **'{days} {from}–{to}'**
  String hotelSettingsHoursLine(String days, String from, String to);

  /// No description provided for @hotelSettingsHoursLineClosed.
  ///
  /// In en, this message translates to:
  /// **'{days} closed'**
  String hotelSettingsHoursLineClosed(String days);

  /// No description provided for @hotelSettingsHoursDaysRange.
  ///
  /// In en, this message translates to:
  /// **'{first}–{last}'**
  String hotelSettingsHoursDaysRange(String first, String last);

  /// No description provided for @hotelSettingsHoursDaysPair.
  ///
  /// In en, this message translates to:
  /// **'{first}, {last}'**
  String hotelSettingsHoursDaysPair(String first, String last);

  /// No description provided for @hotelSettingsHoursEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get hotelSettingsHoursEveryDay;

  /// No description provided for @hotelSettingsHoursAllClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get hotelSettingsHoursAllClosed;

  /// No description provided for @hotelSettingsHoursWeek.
  ///
  /// In en, this message translates to:
  /// **'Weekly hours'**
  String get hotelSettingsHoursWeek;

  /// No description provided for @hotelSettingsHoursTimeFrom.
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get hotelSettingsHoursTimeFrom;

  /// No description provided for @hotelSettingsHoursTimeTo.
  ///
  /// In en, this message translates to:
  /// **'Closing'**
  String get hotelSettingsHoursTimeTo;

  /// No description provided for @hotelSettingsHoursHour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get hotelSettingsHoursHour;

  /// No description provided for @hotelSettingsHoursMinute.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get hotelSettingsHoursMinute;

  /// No description provided for @hotelSettingsHoursAm.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get hotelSettingsHoursAm;

  /// No description provided for @hotelSettingsHoursPm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get hotelSettingsHoursPm;

  /// No description provided for @hotelSettingsHoursSetTime.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get hotelSettingsHoursSetTime;

  /// No description provided for @hotelSettingsHoursClosures.
  ///
  /// In en, this message translates to:
  /// **'Closures'**
  String get hotelSettingsHoursClosures;

  /// No description provided for @hotelSettingsHoursClosure.
  ///
  /// In en, this message translates to:
  /// **'Closure'**
  String get hotelSettingsHoursClosure;

  /// No description provided for @hotelSettingsHoursClosureRange.
  ///
  /// In en, this message translates to:
  /// **'{from}–{to}'**
  String hotelSettingsHoursClosureRange(String from, String to);

  /// No description provided for @hotelSettingsHoursApprox.
  ///
  /// In en, this message translates to:
  /// **'Approx.'**
  String get hotelSettingsHoursApprox;

  /// No description provided for @hotelSettingsHoursSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get hotelSettingsHoursSuggested;

  /// No description provided for @hotelSettingsHoursAddClosure.
  ///
  /// In en, this message translates to:
  /// **'Add closure'**
  String get hotelSettingsHoursAddClosure;

  /// No description provided for @hotelSettingsHoursAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add closure'**
  String get hotelSettingsHoursAddTitle;

  /// No description provided for @hotelSettingsHoursAddLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get hotelSettingsHoursAddLabel;

  /// No description provided for @hotelSettingsHoursAddConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get hotelSettingsHoursAddConfirm;

  /// No description provided for @hotelSettingsHoursRemoveClosure.
  ///
  /// In en, this message translates to:
  /// **'Remove closure {label}'**
  String hotelSettingsHoursRemoveClosure(String label);

  /// No description provided for @hotelSettingsHoursSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get hotelSettingsHoursSave;

  /// No description provided for @hotelSettingsHoursGuardTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get hotelSettingsHoursGuardTitle;

  /// No description provided for @hotelSettingsHoursGuardLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get hotelSettingsHoursGuardLeave;

  /// No description provided for @hotelSettingsHoursGuardStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get hotelSettingsHoursGuardStay;

  /// No description provided for @hotelSettingsHoursViewOnly.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get hotelSettingsHoursViewOnly;

  /// No description provided for @hotelSettingsHoursInvalid.
  ///
  /// In en, this message translates to:
  /// **'Times can’t match'**
  String get hotelSettingsHoursInvalid;

  /// No description provided for @hotelSettingsHoursCopy.
  ///
  /// In en, this message translates to:
  /// **'All days'**
  String get hotelSettingsHoursCopy;

  /// No description provided for @hotelSettingsHoursNextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get hotelSettingsHoursNextDay;

  /// No description provided for @hotelSettingsHoursOpenOn.
  ///
  /// In en, this message translates to:
  /// **'Open on {day}'**
  String hotelSettingsHoursOpenOn(String day);

  /// No description provided for @hotelSettingsHoursClosedWord.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get hotelSettingsHoursClosedWord;

  /// No description provided for @hotelSettingsBillExempt.
  ///
  /// In en, this message translates to:
  /// **'Major hotel · no listing fees'**
  String get hotelSettingsBillExempt;

  /// No description provided for @hotelSettingsBillExemptBody.
  ///
  /// In en, this message translates to:
  /// **'Your listings are still reviewed before they go live.'**
  String get hotelSettingsBillExemptBody;

  /// No description provided for @hotelSettingsBillEnds.
  ///
  /// In en, this message translates to:
  /// **'Plan ends'**
  String get hotelSettingsBillEnds;

  /// No description provided for @hotelSettingsBillEnded.
  ///
  /// In en, this message translates to:
  /// **'Plan ended'**
  String get hotelSettingsBillEnded;

  /// No description provided for @hotelSettingsBillDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'Days remaining'**
  String get hotelSettingsBillDaysLeft;

  /// No description provided for @hotelSettingsBillDaysUnit.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get hotelSettingsBillDaysUnit;

  /// No description provided for @hotelSettingsBillHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hotelSettingsBillHidden;

  /// No description provided for @hotelSettingsBillNone.
  ///
  /// In en, this message translates to:
  /// **'No plan'**
  String get hotelSettingsBillNone;

  /// No description provided for @hotelSettingsBillNoneBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a weekly, monthly or annual plan to advertise. Nothing goes live until Ghazal has reviewed it.'**
  String get hotelSettingsBillNoneBody;

  /// No description provided for @hotelSettingsBillRatesBody.
  ///
  /// In en, this message translates to:
  /// **'You can choose a plan now. Payment opens when rates are announced.'**
  String get hotelSettingsBillRatesBody;

  /// No description provided for @hotelSettingsBillStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan status'**
  String get hotelSettingsBillStatusLabel;

  /// No description provided for @hotelSettingsBillPillActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get hotelSettingsBillPillActive;

  /// No description provided for @hotelSettingsBillPillExpiring.
  ///
  /// In en, this message translates to:
  /// **'Ending'**
  String get hotelSettingsBillPillExpiring;

  /// No description provided for @hotelSettingsBillExpiringNote.
  ///
  /// In en, this message translates to:
  /// **'We remind you a week before and again the day before. Renew to keep your listing live.'**
  String get hotelSettingsBillExpiringNote;

  /// No description provided for @hotelSettingsBillExpiredNote.
  ///
  /// In en, this message translates to:
  /// **'Your listing is hidden. Renew to bring it back; it returns to review before it goes live again.'**
  String get hotelSettingsBillExpiredNote;

  /// No description provided for @hotelSettingsBillPlanRow.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get hotelSettingsBillPlanRow;

  /// No description provided for @hotelSettingsBillRenew.
  ///
  /// In en, this message translates to:
  /// **'Renew'**
  String get hotelSettingsBillRenew;

  /// No description provided for @hotelSettingsBillChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose plan'**
  String get hotelSettingsBillChoose;

  /// No description provided for @hotelSettingsBillSeePlans.
  ///
  /// In en, this message translates to:
  /// **'See plans'**
  String get hotelSettingsBillSeePlans;

  /// No description provided for @hotelSettingsBillReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get hotelSettingsBillReceipts;

  /// No description provided for @hotelSettingsBillDirectNote.
  ///
  /// In en, this message translates to:
  /// **'Couples pay you directly for the event. Ghazal holds, takes and pays out no event money, so this is the only place billing appears.'**
  String get hotelSettingsBillDirectNote;

  /// No description provided for @hotelSettingsBillViewOnly.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get hotelSettingsBillViewOnly;

  /// No description provided for @hotelSettingsBillDownload.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get hotelSettingsBillDownload;

  /// No description provided for @hotelSettingsBillDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Receipt saved'**
  String get hotelSettingsBillDownloaded;

  /// No description provided for @hotelSettingsBillMethodKnet.
  ///
  /// In en, this message translates to:
  /// **'KNET'**
  String get hotelSettingsBillMethodKnet;

  /// No description provided for @hotelSettingsBillMethodCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get hotelSettingsBillMethodCard;

  /// No description provided for @hotelSettingsBillMethodApplePay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get hotelSettingsBillMethodApplePay;

  /// No description provided for @hotelSettingsBillMethodGooglePay.
  ///
  /// In en, this message translates to:
  /// **'Google Pay'**
  String get hotelSettingsBillMethodGooglePay;

  /// No description provided for @hotelSettingsStaffEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get hotelSettingsStaffEmail;

  /// No description provided for @hotelSettingsStaffEmailError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get hotelSettingsStaffEmailError;

  /// No description provided for @hotelSettingsBillContractBody.
  ///
  /// In en, this message translates to:
  /// **'Your terms are as contracted with Ghazal. There is no public plan.'**
  String get hotelSettingsBillContractBody;

  /// No description provided for @hotelShellTabBarLabel.
  ///
  /// In en, this message translates to:
  /// **'Main navigation'**
  String get hotelShellTabBarLabel;

  /// No description provided for @hotelShellTabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get hotelShellTabToday;

  /// No description provided for @hotelShellTabBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get hotelShellTabBookings;

  /// No description provided for @hotelShellTabCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get hotelShellTabCalendar;

  /// No description provided for @hotelShellTabMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get hotelShellTabMessages;

  /// No description provided for @hotelShellTabMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get hotelShellTabMore;

  /// No description provided for @hotelShellBadgePending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} request needs your reply} other{{count} requests need your reply}}'**
  String hotelShellBadgePending(int count);

  /// No description provided for @hotelShellBadgeOverflow.
  ///
  /// In en, this message translates to:
  /// **'{max}+'**
  String hotelShellBadgeOverflow(num max);

  /// No description provided for @hotelShellBannerNewRequest.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get hotelShellBannerNewRequest;

  /// No description provided for @hotelShellGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String hotelShellGreeting(String name);

  /// No description provided for @hotelShellTodayNeedsReply.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} request needs your reply} other{{count} requests need your reply}}'**
  String hotelShellTodayNeedsReply(int count);

  /// No description provided for @hotelShellTodayFirstIn.
  ///
  /// In en, this message translates to:
  /// **'first in {time}'**
  String hotelShellTodayFirstIn(String time);

  /// No description provided for @hotelShellTodayAllClear.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get hotelShellTodayAllClear;

  /// No description provided for @hotelShellNeedsYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs your attention'**
  String get hotelShellNeedsYouTitle;

  /// No description provided for @hotelShellOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'You’re offline. Showing what was last loaded.'**
  String get hotelShellOfflineBanner;

  /// No description provided for @hotelTodayBell.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get hotelTodayBell;

  /// No description provided for @hotelTodayBellUnread.
  ///
  /// In en, this message translates to:
  /// **'Notifications, {count, plural, one{{count} unread} other{{count} unread}}'**
  String hotelTodayBellUnread(int count);

  /// No description provided for @hotelTodaySwitchVenue.
  ///
  /// In en, this message translates to:
  /// **'Switch venue, now {venue}'**
  String hotelTodaySwitchVenue(String venue);

  /// No description provided for @hotelTodayStatusFirst.
  ///
  /// In en, this message translates to:
  /// **'First due in {time}'**
  String hotelTodayStatusFirst(String time);

  /// No description provided for @hotelTodayStatusNeeds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} request needs your reply} other{{count} requests need your reply}}'**
  String hotelTodayStatusNeeds(int count);

  /// No description provided for @hotelTodayAllClear.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get hotelTodayAllClear;

  /// No description provided for @hotelTodayStatusMarketing.
  ///
  /// In en, this message translates to:
  /// **'{windows, plural, one{{windows} voucher price running} other{{windows} voucher prices running}} · {views} views this week'**
  String hotelTodayStatusMarketing(int windows, String views);

  /// No description provided for @hotelTodayNeedsYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs you'**
  String get hotelTodayNeedsYouTitle;

  /// No description provided for @hotelTodaySeeAllCount.
  ///
  /// In en, this message translates to:
  /// **'See all {count}'**
  String hotelTodaySeeAllCount(String count);

  /// No description provided for @hotelTodayWindowEnds.
  ///
  /// In en, this message translates to:
  /// **'Reply window ends in {time}'**
  String hotelTodayWindowEnds(String time);

  /// No description provided for @hotelTodayWaitingLong.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a reply for {time}'**
  String hotelTodayWaitingLong(String time);

  /// No description provided for @hotelTodayBlockDate.
  ///
  /// In en, this message translates to:
  /// **'Block date'**
  String get hotelTodayBlockDate;

  /// No description provided for @hotelTodayEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get hotelTodayEventsTitle;

  /// No description provided for @hotelTodayDayView.
  ///
  /// In en, this message translates to:
  /// **'Day view'**
  String get hotelTodayDayView;

  /// No description provided for @hotelTodayAudienceWomen.
  ///
  /// In en, this message translates to:
  /// **'Ladies’ reception'**
  String get hotelTodayAudienceWomen;

  /// No description provided for @hotelTodayAudienceMen.
  ///
  /// In en, this message translates to:
  /// **'Men’s reception'**
  String get hotelTodayAudienceMen;

  /// No description provided for @hotelTodayAudienceMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed reception'**
  String get hotelTodayAudienceMixed;

  /// No description provided for @hotelTodayStartsIn.
  ///
  /// In en, this message translates to:
  /// **'Starts in {time}'**
  String hotelTodayStartsIn(String time);

  /// No description provided for @hotelTodayStripLabel.
  ///
  /// In en, this message translates to:
  /// **'Availability over the next seven days'**
  String get hotelTodayStripLabel;

  /// No description provided for @hotelTodayCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get hotelTodayCalendar;

  /// No description provided for @hotelTodaySoftDates.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} open weekend date in {days} days} other{{count} open weekend dates in {days} days}}'**
  String hotelTodaySoftDates(int count, String days);

  /// No description provided for @hotelTodayOpenDates.
  ///
  /// In en, this message translates to:
  /// **'Open dates in the next thirty days'**
  String get hotelTodayOpenDates;

  /// No description provided for @hotelTodayGlanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get hotelTodayGlanceTitle;

  /// No description provided for @hotelTodayAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get hotelTodayAnalytics;

  /// No description provided for @hotelTodayViews7.
  ///
  /// In en, this message translates to:
  /// **'Views over the last seven days'**
  String get hotelTodayViews7;

  /// No description provided for @hotelTodayVsPrevious.
  ///
  /// In en, this message translates to:
  /// **'vs the seven days before'**
  String get hotelTodayVsPrevious;

  /// No description provided for @hotelTodayViewsTrend.
  ///
  /// In en, this message translates to:
  /// **'Views per day, last seven days'**
  String get hotelTodayViewsTrend;

  /// No description provided for @hotelTodayMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get hotelTodayMessagesTitle;

  /// No description provided for @hotelTodayUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get hotelTodayUnread;

  /// No description provided for @hotelTodayUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} unread message} other{{count} unread messages}}'**
  String hotelTodayUnreadCount(int count);

  /// No description provided for @hotelTodayYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get hotelTodayYou;

  /// No description provided for @hotelTodayPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get hotelTodayPinned;

  /// No description provided for @hotelTodayEnquiry.
  ///
  /// In en, this message translates to:
  /// **'Enquiry'**
  String get hotelTodayEnquiry;

  /// No description provided for @hotelTodayPreviewVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get hotelTodayPreviewVoice;

  /// No description provided for @hotelTodayPreviewPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get hotelTodayPreviewPhoto;

  /// No description provided for @hotelTodayPreviewDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get hotelTodayPreviewDocument;

  /// No description provided for @hotelTodayOfflineStamp.
  ///
  /// In en, this message translates to:
  /// **'Offline · updated {time}'**
  String hotelTodayOfflineStamp(String time);

  /// No description provided for @hotelTodayOfflineReason.
  ///
  /// In en, this message translates to:
  /// **'Offline. Reconnect to accept.'**
  String get hotelTodayOfflineReason;

  /// No description provided for @hotelTodaySwitchSister.
  ///
  /// In en, this message translates to:
  /// **'Lumi Marina Hotel'**
  String get hotelTodaySwitchSister;

  /// No description provided for @hotelTodayAcceptedToast.
  ///
  /// In en, this message translates to:
  /// **'Request approved'**
  String get hotelTodayAcceptedToast;

  /// No description provided for @hotelTodayFirstRunNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get hotelTodayFirstRunNotifTitle;

  /// No description provided for @hotelTodayFirstRunNotifBody.
  ///
  /// In en, this message translates to:
  /// **'New requests have a limited reply window. With notifications on, you hear about them straight away, even when the app is closed.'**
  String get hotelTodayFirstRunNotifBody;

  /// No description provided for @hotelTodayFirstRunNotifPointTime.
  ///
  /// In en, this message translates to:
  /// **'Urgent alerts'**
  String get hotelTodayFirstRunNotifPointTime;

  /// No description provided for @hotelTodayFirstRunNotifPointSound.
  ///
  /// In en, this message translates to:
  /// **'Own sound'**
  String get hotelTodayFirstRunNotifPointSound;

  /// No description provided for @hotelTodayFirstRunNotifAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get hotelTodayFirstRunNotifAllow;

  /// No description provided for @hotelTodayFirstRunNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get hotelTodayFirstRunNotNow;

  /// No description provided for @hotelTodayFirstRunLockTitle.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get hotelTodayFirstRunLockTitle;

  /// No description provided for @hotelTodayFirstRunLockBody.
  ///
  /// In en, this message translates to:
  /// **'Protects requests, vouchers and visits if the phone is lost or shared. You can turn this on later in More.'**
  String get hotelTodayFirstRunLockBody;

  /// No description provided for @hotelTodayFirstRunLockOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get hotelTodayFirstRunLockOn;

  /// No description provided for @hotelTodaySwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch venue'**
  String get hotelTodaySwitchTitle;

  /// No description provided for @hotelTodaySwitchPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} request waiting} other{{count} requests waiting}}'**
  String hotelTodaySwitchPending(int count);

  /// No description provided for @hotelTodaySwitchCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current venue'**
  String get hotelTodaySwitchCurrent;

  /// No description provided for @hotelTodayRoleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get hotelTodayRoleManager;

  /// No description provided for @hotelTodayRoleReception.
  ///
  /// In en, this message translates to:
  /// **'Reception'**
  String get hotelTodayRoleReception;

  /// No description provided for @hotelTodayDurDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day} other{{count} days}}'**
  String hotelTodayDurDays(int count);

  /// No description provided for @hotelTodayDurHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} hour} other{{count} hours}}'**
  String hotelTodayDurHours(int count);

  /// No description provided for @hotelTodayDurMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} minute} other{{count} minutes}}'**
  String hotelTodayDurMinutes(int count);

  /// No description provided for @hotelTodayDurJoin.
  ///
  /// In en, this message translates to:
  /// **'{first} {second}'**
  String hotelTodayDurJoin(String first, String second);

  /// No description provided for @hotelTodayNeedsTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs you'**
  String get hotelTodayNeedsTitle;

  /// No description provided for @hotelTodayFiltersLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter the queue'**
  String get hotelTodayFiltersLabel;

  /// No description provided for @hotelTodayFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get hotelTodayFilterAll;

  /// No description provided for @hotelTodayFilterRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get hotelTodayFilterRequests;

  /// No description provided for @hotelTodayFilterMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get hotelTodayFilterMessages;

  /// No description provided for @hotelTodayFilterReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get hotelTodayFilterReviews;

  /// No description provided for @hotelTodayFilterCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get hotelTodayFilterCalendar;

  /// No description provided for @hotelTodayNotifFilter.
  ///
  /// In en, this message translates to:
  /// **'Show notifications'**
  String get hotelTodayNotifFilter;

  /// No description provided for @hotelTodayMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get hotelTodayMarkAllRead;

  /// No description provided for @hotelTodayPrefs.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get hotelTodayPrefs;

  /// No description provided for @hotelTodayNotifEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get hotelTodayNotifEmptyTitle;

  /// No description provided for @hotelTodayNotifUnreadEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'All read'**
  String get hotelTodayNotifUnreadEmptyTitle;

  /// No description provided for @hotelTodayNotifShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get hotelTodayNotifShowAll;

  /// No description provided for @hotelTodayPushDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications off'**
  String get hotelTodayPushDeniedTitle;

  /// No description provided for @hotelTodayOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get hotelTodayOpenSettings;

  /// No description provided for @hotelTodayPushDeniedToast.
  ///
  /// In en, this message translates to:
  /// **'Turn on in Settings'**
  String get hotelTodayPushDeniedToast;

  /// No description provided for @hotelTodayAllRead.
  ///
  /// In en, this message translates to:
  /// **'All read'**
  String get hotelTodayAllRead;

  /// No description provided for @hotelTodayInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get hotelTodayInboxTitle;

  /// No description provided for @hotelTodayInboxSearch.
  ///
  /// In en, this message translates to:
  /// **'Name or reference'**
  String get hotelTodayInboxSearch;

  /// No description provided for @hotelTodayInboxSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search conversations'**
  String get hotelTodayInboxSearchLabel;

  /// No description provided for @hotelTodayInboxFilters.
  ///
  /// In en, this message translates to:
  /// **'Filter conversations'**
  String get hotelTodayInboxFilters;

  /// No description provided for @hotelTodayInboxUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get hotelTodayInboxUnread;

  /// No description provided for @hotelTodayInboxNeedsReply.
  ///
  /// In en, this message translates to:
  /// **'Needs reply'**
  String get hotelTodayInboxNeedsReply;

  /// No description provided for @hotelTodayInboxLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get hotelTodayInboxLinked;

  /// No description provided for @hotelTodayInboxEnquiries.
  ///
  /// In en, this message translates to:
  /// **'Enquiries'**
  String get hotelTodayInboxEnquiries;

  /// No description provided for @hotelTodayInboxEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get hotelTodayInboxEmptyTitle;

  /// No description provided for @hotelTodayInboxNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No match'**
  String get hotelTodayInboxNoResultsTitle;

  /// No description provided for @hotelTodayClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get hotelTodayClearSearch;

  /// No description provided for @hotelTodayInboxSupportOnly.
  ///
  /// In en, this message translates to:
  /// **'Reception handles clients'**
  String get hotelTodayInboxSupportOnly;

  /// No description provided for @hotelTodayMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark read'**
  String get hotelTodayMarkRead;

  /// No description provided for @hotelTodayMarkUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark unread'**
  String get hotelTodayMarkUnread;

  /// No description provided for @hotelTodayConversationMenu.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get hotelTodayConversationMenu;

  /// No description provided for @hotelTodayHandledBy.
  ///
  /// In en, this message translates to:
  /// **'Handled by {name}'**
  String hotelTodayHandledBy(String name);

  /// No description provided for @hotelTodayCallClient.
  ///
  /// In en, this message translates to:
  /// **'Call {name}'**
  String hotelTodayCallClient(String name);

  /// No description provided for @hotelTodayReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get hotelTodayReport;

  /// No description provided for @hotelTodayReportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get hotelTodayReportSent;

  /// No description provided for @hotelTodayContextLine.
  ///
  /// In en, this message translates to:
  /// **'{audience} · {date} · {guests}'**
  String hotelTodayContextLine(String audience, String date, String guests);

  /// No description provided for @hotelTodayOpenBooking.
  ///
  /// In en, this message translates to:
  /// **'Open request, {summary}'**
  String hotelTodayOpenBooking(String summary);

  /// No description provided for @hotelTodayComposerLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get hotelTodayComposerLabel;

  /// No description provided for @hotelTodayComposerPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get hotelTodayComposerPlaceholder;

  /// No description provided for @hotelTodayAttach.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get hotelTodayAttach;

  /// No description provided for @hotelTodayAttachTitle.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get hotelTodayAttachTitle;

  /// No description provided for @hotelTodayAttachCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get hotelTodayAttachCamera;

  /// No description provided for @hotelTodayAttachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get hotelTodayAttachPhoto;

  /// No description provided for @hotelTodayAttachDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get hotelTodayAttachDocument;

  /// No description provided for @hotelTodayRecordHold.
  ///
  /// In en, this message translates to:
  /// **'Hold to record'**
  String get hotelTodayRecordHold;

  /// No description provided for @hotelTodayRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get hotelTodayRecording;

  /// No description provided for @hotelTodaySlideCancel.
  ///
  /// In en, this message translates to:
  /// **'Slide to cancel'**
  String get hotelTodaySlideCancel;

  /// No description provided for @hotelTodaySlideLock.
  ///
  /// In en, this message translates to:
  /// **'Slide up to lock'**
  String get hotelTodaySlideLock;

  /// No description provided for @hotelTodayRecordingLocked.
  ///
  /// In en, this message translates to:
  /// **'Recording locked'**
  String get hotelTodayRecordingLocked;

  /// No description provided for @hotelTodayRecordDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete recording'**
  String get hotelTodayRecordDelete;

  /// No description provided for @hotelTodayRecordSend.
  ///
  /// In en, this message translates to:
  /// **'Send recording'**
  String get hotelTodayRecordSend;

  /// No description provided for @hotelTodayQuickLabel.
  ///
  /// In en, this message translates to:
  /// **'Quick replies'**
  String get hotelTodayQuickLabel;

  /// No description provided for @hotelTodayQrAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get hotelTodayQrAvailability;

  /// No description provided for @hotelTodayQrPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get hotelTodayQrPrice;

  /// No description provided for @hotelTodayQrVisit.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get hotelTodayQrVisit;

  /// No description provided for @hotelTodayQrAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get hotelTodayQrAddress;

  /// No description provided for @hotelTodayQrAvailabilityText.
  ///
  /// In en, this message translates to:
  /// **'Welcome. {date} is available and we would be glad to host you.'**
  String hotelTodayQrAvailabilityText(String date);

  /// No description provided for @hotelTodayQrPriceText.
  ///
  /// In en, this message translates to:
  /// **'With a Ghazal voucher, the total for {guests} is {total} instead of {standard}. You settle it with us directly after you confirm.'**
  String hotelTodayQrPriceText(String guests, String total, String standard);

  /// No description provided for @hotelTodayQrVisitText.
  ///
  /// In en, this message translates to:
  /// **'You are welcome to visit the hall. You can book a visit from our page in the Ghazal app and choose the day that suits you.'**
  String get hotelTodayQrVisitText;

  /// No description provided for @hotelTodayQrAddressText.
  ///
  /// In en, this message translates to:
  /// **'You will find us at {venue}, {area}.'**
  String hotelTodayQrAddressText(String venue, String area);

  /// No description provided for @hotelTodayMsgSending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get hotelTodayMsgSending;

  /// No description provided for @hotelTodayMsgQueued.
  ///
  /// In en, this message translates to:
  /// **'Waiting for connection'**
  String get hotelTodayMsgQueued;

  /// No description provided for @hotelTodayMsgFailed.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get hotelTodayMsgFailed;

  /// No description provided for @hotelTodayDraftTag.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get hotelTodayDraftTag;

  /// No description provided for @hotelTodayThreadEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get hotelTodayThreadEmptyTitle;

  /// No description provided for @hotelTodayAllPrices.
  ///
  /// In en, this message translates to:
  /// **'All voucher prices'**
  String get hotelTodayAllPrices;

  /// No description provided for @hotelTodayAwaitingClient.
  ///
  /// In en, this message translates to:
  /// **'Awaiting client confirmation'**
  String get hotelTodayAwaitingClient;

  /// No description provided for @hotelTodayBillingTitle.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get hotelTodayBillingTitle;

  /// No description provided for @hotelTodayConfirmWindowEnds.
  ///
  /// In en, this message translates to:
  /// **'Client confirmation window ends in {time}'**
  String hotelTodayConfirmWindowEnds(String time);

  /// No description provided for @hotelTodayFilterListing.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get hotelTodayFilterListing;

  /// No description provided for @hotelTodayFilterVisits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get hotelTodayFilterVisits;

  /// No description provided for @hotelTodayInboxVisits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get hotelTodayInboxVisits;

  /// No description provided for @hotelTodayNewPrice.
  ///
  /// In en, this message translates to:
  /// **'New price'**
  String get hotelTodayNewPrice;

  /// No description provided for @hotelTodayNtfListingApproved.
  ///
  /// In en, this message translates to:
  /// **'Listing approved'**
  String get hotelTodayNtfListingApproved;

  /// No description provided for @hotelTodayNtfListingRejected.
  ///
  /// In en, this message translates to:
  /// **'Listing not approved'**
  String get hotelTodayNtfListingRejected;

  /// No description provided for @hotelTodayNtfListingSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Listing sent for review'**
  String get hotelTodayNtfListingSubmitted;

  /// No description provided for @hotelTodayNtfNewRequest.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get hotelTodayNtfNewRequest;

  /// No description provided for @hotelTodayNtfRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Voucher redeemed by you'**
  String get hotelTodayNtfRedeemed;

  /// No description provided for @hotelTodayPricesTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher prices'**
  String get hotelTodayPricesTitle;

  /// No description provided for @hotelTodayRedeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get hotelTodayRedeem;

  /// No description provided for @hotelTodayRequestsMonth.
  ///
  /// In en, this message translates to:
  /// **'Requests this month'**
  String get hotelTodayRequestsMonth;

  /// No description provided for @hotelTodayStatusExempt.
  ///
  /// In en, this message translates to:
  /// **'Major hotel · no listing fees'**
  String get hotelTodayStatusExempt;

  /// No description provided for @hotelTodayStatusListing.
  ///
  /// In en, this message translates to:
  /// **'A listing needs your attention'**
  String get hotelTodayStatusListing;

  /// No description provided for @hotelTodayStatusNoPlan.
  ///
  /// In en, this message translates to:
  /// **'No active listing plan'**
  String get hotelTodayStatusNoPlan;

  /// No description provided for @hotelTodayStatusPlan.
  ///
  /// In en, this message translates to:
  /// **'Listing plan ends {date}'**
  String hotelTodayStatusPlan(String date);

  /// No description provided for @hotelTodayStatusVisits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} visit request needs your reply} other{{count} visit requests need your reply}}'**
  String hotelTodayStatusVisits(int count);

  /// No description provided for @hotelTodayTilesTitle.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get hotelTodayTilesTitle;

  /// No description provided for @hotelTodayVisitMembers.
  ///
  /// In en, this message translates to:
  /// **'Chat members: client, hotel representative, Ghazal support'**
  String get hotelTodayVisitMembers;

  /// No description provided for @hotelTodayVoucherMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'Vouchers'**
  String get hotelTodayVoucherMonthTitle;

  /// No description provided for @hotelTodayVouchersRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Vouchers redeemed'**
  String get hotelTodayVouchersRedeemed;

  /// No description provided for @hotelTodayFirstRunFaceId.
  ///
  /// In en, this message translates to:
  /// **'Face ID'**
  String get hotelTodayFirstRunFaceId;

  /// No description provided for @hotelTodayFirstRunFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get hotelTodayFirstRunFingerprint;

  /// No description provided for @hotelTodayRoleAccountant.
  ///
  /// In en, this message translates to:
  /// **'Accountant'**
  String get hotelTodayRoleAccountant;

  /// No description provided for @hotelTodayRoleMarketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get hotelTodayRoleMarketing;

  /// No description provided for @hotelTodayReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get hotelTodayReadOnly;

  /// No description provided for @hotelTodayRedeemName.
  ///
  /// In en, this message translates to:
  /// **'Redeem voucher'**
  String get hotelTodayRedeemName;

  /// No description provided for @hotelTodayBlockName.
  ///
  /// In en, this message translates to:
  /// **'Block a date'**
  String get hotelTodayBlockName;

  /// No description provided for @hotelTodayNewPriceName.
  ///
  /// In en, this message translates to:
  /// **'New voucher price'**
  String get hotelTodayNewPriceName;

  /// No description provided for @hotelTodayRedeemedName.
  ///
  /// In en, this message translates to:
  /// **'Vouchers redeemed'**
  String get hotelTodayRedeemedName;

  /// No description provided for @hotelTodayReviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Listing in review'**
  String get hotelTodayReviewLabel;

  /// No description provided for @hotelTodayNoPlan.
  ///
  /// In en, this message translates to:
  /// **'No plan'**
  String get hotelTodayNoPlan;

  /// No description provided for @hotelTodayFactDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get hotelTodayFactDate;

  /// No description provided for @hotelTodayFactGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get hotelTodayFactGuests;

  /// No description provided for @hotelTodayFactHall.
  ///
  /// In en, this message translates to:
  /// **'Hall'**
  String get hotelTodayFactHall;

  /// No description provided for @hotelTodayFactTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get hotelTodayFactTime;

  /// No description provided for @hotelTodayFactRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get hotelTodayFactRating;

  /// No description provided for @hotelTodayFactVisitors.
  ///
  /// In en, this message translates to:
  /// **'Visitors'**
  String get hotelTodayFactVisitors;

  /// No description provided for @hotelTodayFactVoucherPrice.
  ///
  /// In en, this message translates to:
  /// **'Voucher price'**
  String get hotelTodayFactVoucherPrice;

  /// No description provided for @hotelTodayFactReplyBy.
  ///
  /// In en, this message translates to:
  /// **'Reply by'**
  String get hotelTodayFactReplyBy;

  /// No description provided for @hotelTodayFactEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get hotelTodayFactEnds;

  /// No description provided for @hotelTodayKindRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get hotelTodayKindRequest;

  /// No description provided for @hotelTodayKindAwaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for client'**
  String get hotelTodayKindAwaiting;

  /// No description provided for @hotelTodayKindVisit.
  ///
  /// In en, this message translates to:
  /// **'Visit request'**
  String get hotelTodayKindVisit;

  /// No description provided for @hotelTodayKindMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get hotelTodayKindMessage;

  /// No description provided for @hotelTodayKindReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get hotelTodayKindReview;

  /// No description provided for @hotelTodayKindCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar check'**
  String get hotelTodayKindCalendar;

  /// No description provided for @hotelTodayKindListing.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get hotelTodayKindListing;

  /// No description provided for @hotelTodayKindPrice.
  ///
  /// In en, this message translates to:
  /// **'Voucher price ending'**
  String get hotelTodayKindPrice;

  /// No description provided for @hotelTodayCalendarCheck.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get hotelTodayCalendarCheck;

  /// No description provided for @hotelTodayListingEndsIn.
  ///
  /// In en, this message translates to:
  /// **'Plan ends in {time}'**
  String hotelTodayListingEndsIn(String time);

  /// No description provided for @hotelTodayWindowEndsIn.
  ///
  /// In en, this message translates to:
  /// **'Voucher price ends in {time}'**
  String hotelTodayWindowEndsIn(String time);

  /// No description provided for @hotelTodayListings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get hotelTodayListings;

  /// No description provided for @hotelTodayNextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next event'**
  String get hotelTodayNextLabel;

  /// No description provided for @hotelTodayVouchersBought.
  ///
  /// In en, this message translates to:
  /// **'Vouchers bought'**
  String get hotelTodayVouchersBought;

  /// No description provided for @hotelTodayVouchersTrend.
  ///
  /// In en, this message translates to:
  /// **'Vouchers bought per day'**
  String get hotelTodayVouchersTrend;

  /// No description provided for @hotelVenueLangBoth.
  ///
  /// In en, this message translates to:
  /// **'AR · EN'**
  String get hotelVenueLangBoth;

  /// No description provided for @hotelVenueLangArMissing.
  ///
  /// In en, this message translates to:
  /// **'AR {count}'**
  String hotelVenueLangArMissing(num count);

  /// No description provided for @hotelVenueLangEnMissing.
  ///
  /// In en, this message translates to:
  /// **'EN {count}'**
  String hotelVenueLangEnMissing(num count);

  /// No description provided for @hotelVenueDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get hotelVenueDashboardTitle;

  /// No description provided for @hotelVenueDashboardCta.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get hotelVenueDashboardCta;

  /// No description provided for @hotelVenueDashboardLead.
  ///
  /// In en, this message translates to:
  /// **'Edited on the dashboard. Existing bookings keep their terms.'**
  String get hotelVenueDashboardLead;

  /// No description provided for @hotelVenueDashboardItemSeason.
  ///
  /// In en, this message translates to:
  /// **'Seasonal price grids'**
  String get hotelVenueDashboardItemSeason;

  /// No description provided for @hotelVenueDashboardItemHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holiday and occasion prices'**
  String get hotelVenueDashboardItemHoliday;

  /// No description provided for @hotelVenueDashboardItemSpecial.
  ///
  /// In en, this message translates to:
  /// **'Prices for a single date'**
  String get hotelVenueDashboardItemSpecial;

  /// No description provided for @hotelVenueDashboardItemMenus.
  ///
  /// In en, this message translates to:
  /// **'Menus and menu tiers'**
  String get hotelVenueDashboardItemMenus;

  /// No description provided for @hotelVenueDashboardItemService.
  ///
  /// In en, this message translates to:
  /// **'Service charge'**
  String get hotelVenueDashboardItemService;

  /// No description provided for @hotelVenueGuardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get hotelVenueGuardTitle;

  /// No description provided for @hotelVenueGuardBody.
  ///
  /// In en, this message translates to:
  /// **'You have edits that are not saved. If you leave now, they are lost.'**
  String get hotelVenueGuardBody;

  /// No description provided for @hotelVenueGuardDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get hotelVenueGuardDiscard;

  /// No description provided for @hotelVenueGuardKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get hotelVenueGuardKeep;

  /// No description provided for @hotelVenueOfflineStrip.
  ///
  /// In en, this message translates to:
  /// **'Offline · {time}'**
  String hotelVenueOfflineStrip(String time);

  /// No description provided for @hotelVenueNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Needs a connection.'**
  String get hotelVenueNeedsConnection;

  /// No description provided for @hotelVenueRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get hotelVenueRequired;

  /// No description provided for @hotelVenueErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load'**
  String get hotelVenueErrorTitle;

  /// No description provided for @hotelVenueErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed. Check your connection and try again.'**
  String get hotelVenueErrorBody;

  /// No description provided for @hotelVenueFieldInArabic.
  ///
  /// In en, this message translates to:
  /// **'{field} (AR)'**
  String hotelVenueFieldInArabic(String field);

  /// No description provided for @hotelVenueFieldInEnglish.
  ///
  /// In en, this message translates to:
  /// **'{field} (EN)'**
  String hotelVenueFieldInEnglish(String field);

  /// No description provided for @hotelVenuePriceError.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get hotelVenuePriceError;

  /// No description provided for @hotelVenueZoneHall.
  ///
  /// In en, this message translates to:
  /// **'Hall'**
  String get hotelVenueZoneHall;

  /// No description provided for @hotelVenueZoneStage.
  ///
  /// In en, this message translates to:
  /// **'Stage and Kosha'**
  String get hotelVenueZoneStage;

  /// No description provided for @hotelVenueZoneBridal.
  ///
  /// In en, this message translates to:
  /// **'Bridal suite'**
  String get hotelVenueZoneBridal;

  /// No description provided for @hotelVenueZoneBuffet.
  ///
  /// In en, this message translates to:
  /// **'Buffet'**
  String get hotelVenueZoneBuffet;

  /// No description provided for @hotelVenueZoneOutdoors.
  ///
  /// In en, this message translates to:
  /// **'Outdoors'**
  String get hotelVenueZoneOutdoors;

  /// No description provided for @hotelVenueZoneEntrance.
  ///
  /// In en, this message translates to:
  /// **'Entrance and valet'**
  String get hotelVenueZoneEntrance;

  /// No description provided for @hotelVenueZoneLayouts.
  ///
  /// In en, this message translates to:
  /// **'Layouts'**
  String get hotelVenueZoneLayouts;

  /// No description provided for @hotelVenueZoneStageShort.
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get hotelVenueZoneStageShort;

  /// No description provided for @hotelVenueZoneBridalShort.
  ///
  /// In en, this message translates to:
  /// **'Suite'**
  String get hotelVenueZoneBridalShort;

  /// No description provided for @hotelVenueZoneEntranceShort.
  ///
  /// In en, this message translates to:
  /// **'Entrance'**
  String get hotelVenueZoneEntranceShort;

  /// No description provided for @hotelVenueZoneFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter photos by zone'**
  String get hotelVenueZoneFilter;

  /// No description provided for @hotelVenueZoneAll.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String hotelVenueZoneAll(num count);

  /// No description provided for @hotelVenueZoneCount.
  ///
  /// In en, this message translates to:
  /// **'{zone} {count}'**
  String hotelVenueZoneCount(String zone, num count);

  /// No description provided for @hotelVenueMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos and videos'**
  String get hotelVenueMediaTitle;

  /// No description provided for @hotelVenueMediaTabs.
  ///
  /// In en, this message translates to:
  /// **'Photos or videos'**
  String get hotelVenueMediaTabs;

  /// No description provided for @hotelVenueMediaTabPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos {count}'**
  String hotelVenueMediaTabPhotos(num count);

  /// No description provided for @hotelVenueMediaTabVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos {count}'**
  String hotelVenueMediaTabVideos(num count);

  /// No description provided for @hotelVenueMediaEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No photos'**
  String get hotelVenueMediaEmptyTitle;

  /// No description provided for @hotelVenueAddPhotosCta.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get hotelVenueAddPhotosCta;

  /// No description provided for @hotelVenueAddVideoCta.
  ///
  /// In en, this message translates to:
  /// **'Add video'**
  String get hotelVenueAddVideoCta;

  /// No description provided for @hotelVenueAddPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get hotelVenueAddPhotoTitle;

  /// No description provided for @hotelVenueAddVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a video'**
  String get hotelVenueAddVideoTitle;

  /// No description provided for @hotelVenuePhotoSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get hotelVenuePhotoSheetTitle;

  /// No description provided for @hotelVenueVideoSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get hotelVenueVideoSheetTitle;

  /// No description provided for @hotelVenuePhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String hotelVenuePhotoCount(num count);

  /// No description provided for @hotelVenueReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get hotelVenueReorder;

  /// No description provided for @hotelVenueReorderDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get hotelVenueReorderDone;

  /// No description provided for @hotelVenueReorderHint.
  ///
  /// In en, this message translates to:
  /// **'Use the arrows'**
  String get hotelVenueReorderHint;

  /// No description provided for @hotelVenueShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get hotelVenueShowAll;

  /// No description provided for @hotelVenueEmptyRoomOnly.
  ///
  /// In en, this message translates to:
  /// **'Empty rooms only'**
  String get hotelVenueEmptyRoomOnly;

  /// No description provided for @hotelVenueAttentionRejected.
  ///
  /// In en, this message translates to:
  /// **'{count} to replace'**
  String hotelVenueAttentionRejected(num count);

  /// No description provided for @hotelVenueStatusReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get hotelVenueStatusReview;

  /// No description provided for @hotelVenueStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get hotelVenueStatusRejected;

  /// No description provided for @hotelVenueStatusLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get hotelVenueStatusLive;

  /// No description provided for @hotelVenueReviewNote.
  ///
  /// In en, this message translates to:
  /// **'Only you see it'**
  String get hotelVenueReviewNote;

  /// No description provided for @hotelVenueUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading · {percent}'**
  String hotelVenueUploading(String percent);

  /// No description provided for @hotelVenueUploadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload progress'**
  String get hotelVenueUploadingLabel;

  /// No description provided for @hotelVenueUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get hotelVenueUploadFailed;

  /// No description provided for @hotelVenueUploadQueued.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get hotelVenueUploadQueued;

  /// No description provided for @hotelVenueUploadRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get hotelVenueUploadRetry;

  /// No description provided for @hotelVenueOfflineQueueNote.
  ///
  /// In en, this message translates to:
  /// **'Offline. Uploads wait here.'**
  String get hotelVenueOfflineQueueNote;

  /// No description provided for @hotelVenueVideoOpen.
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String hotelVenueVideoOpen(String name);

  /// No description provided for @hotelVenueVideoLimits.
  ///
  /// In en, this message translates to:
  /// **'Up to {size} MB'**
  String hotelVenueVideoLimits(num size);

  /// No description provided for @hotelVenueVideoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Too large'**
  String get hotelVenueVideoTooLarge;

  /// No description provided for @hotelVenueVideoTooLargeBody.
  ///
  /// In en, this message translates to:
  /// **'Max {size} MB'**
  String hotelVenueVideoTooLargeBody(num size);

  /// No description provided for @hotelVenueVideoEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No videos'**
  String get hotelVenueVideoEmptyTitle;

  /// No description provided for @hotelVenueVideoNote.
  ///
  /// In en, this message translates to:
  /// **'Plays on tap'**
  String get hotelVenueVideoNote;

  /// No description provided for @hotelVenueVideoDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete video'**
  String get hotelVenueVideoDelete;

  /// No description provided for @hotelVenueVideoDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this video?'**
  String get hotelVenueVideoDeleteTitle;

  /// No description provided for @hotelVenueVideoDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'It leaves the listing.'**
  String get hotelVenueVideoDeleteBody;

  /// No description provided for @hotelVenueNewVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'New walkthrough video'**
  String get hotelVenueNewVideoTitle;

  /// No description provided for @hotelVenueToastVideoDeleted.
  ///
  /// In en, this message translates to:
  /// **'Video deleted'**
  String get hotelVenueToastVideoDeleted;

  /// No description provided for @hotelVenueToastVideoAdded.
  ///
  /// In en, this message translates to:
  /// **'Video added'**
  String get hotelVenueToastVideoAdded;

  /// No description provided for @hotelVenueCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get hotelVenueCover;

  /// No description provided for @hotelVenueSetCover.
  ///
  /// In en, this message translates to:
  /// **'Set as cover'**
  String get hotelVenueSetCover;

  /// No description provided for @hotelVenueEditPhoto.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get hotelVenueEditPhoto;

  /// No description provided for @hotelVenueDeletePhoto.
  ///
  /// In en, this message translates to:
  /// **'Delete photo'**
  String get hotelVenueDeletePhoto;

  /// No description provided for @hotelVenueDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this photo?'**
  String get hotelVenueDeleteTitle;

  /// No description provided for @hotelVenueDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'It leaves the listing.'**
  String get hotelVenueDeleteBody;

  /// No description provided for @hotelVenueDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get hotelVenueDeleteConfirm;

  /// No description provided for @hotelVenueDeleteKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get hotelVenueDeleteKeep;

  /// No description provided for @hotelVenueReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace photo'**
  String get hotelVenueReplace;

  /// No description provided for @hotelVenueReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace photo'**
  String get hotelVenueReplaceTitle;

  /// No description provided for @hotelVenueReasonPerson.
  ///
  /// In en, this message translates to:
  /// **'A person is visible'**
  String get hotelVenueReasonPerson;

  /// No description provided for @hotelVenueReplaceShort.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get hotelVenueReplaceShort;

  /// No description provided for @hotelVenueReasonPersonBody.
  ///
  /// In en, this message translates to:
  /// **'Use an empty room.'**
  String get hotelVenueReasonPersonBody;

  /// No description provided for @hotelVenueFieldZone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get hotelVenueFieldZone;

  /// No description provided for @hotelVenueFieldAlt.
  ///
  /// In en, this message translates to:
  /// **'Alt text'**
  String get hotelVenueFieldAlt;

  /// No description provided for @hotelVenueAltHelper.
  ///
  /// In en, this message translates to:
  /// **'For screen readers'**
  String get hotelVenueAltHelper;

  /// No description provided for @hotelVenueAltBothFirst.
  ///
  /// In en, this message translates to:
  /// **'Add both languages'**
  String get hotelVenueAltBothFirst;

  /// No description provided for @hotelVenueUploadZoneFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a zone'**
  String get hotelVenueUploadZoneFirst;

  /// No description provided for @hotelVenueToastCover.
  ///
  /// In en, this message translates to:
  /// **'Cover photo updated'**
  String get hotelVenueToastCover;

  /// No description provided for @hotelVenueToastDeleted.
  ///
  /// In en, this message translates to:
  /// **'Photo deleted'**
  String get hotelVenueToastDeleted;

  /// No description provided for @hotelVenueToastPhotoSaved.
  ///
  /// In en, this message translates to:
  /// **'Photo details saved'**
  String get hotelVenueToastPhotoSaved;

  /// No description provided for @hotelVenueSourceCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get hotelVenueSourceCamera;

  /// No description provided for @hotelVenueSourceLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get hotelVenueSourceLibrary;

  /// No description provided for @hotelVenueSourceVideo.
  ///
  /// In en, this message translates to:
  /// **'Choose a video'**
  String get hotelVenueSourceVideo;

  /// No description provided for @hotelVenueUploadCta.
  ///
  /// In en, this message translates to:
  /// **'Upload photo'**
  String get hotelVenueUploadCta;

  /// No description provided for @hotelVenueFaceTitle.
  ///
  /// In en, this message translates to:
  /// **'A person is visible'**
  String get hotelVenueFaceTitle;

  /// No description provided for @hotelVenueFaceBody.
  ///
  /// In en, this message translates to:
  /// **'Retake or crop the photo.'**
  String get hotelVenueFaceBody;

  /// No description provided for @hotelVenueFaceRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get hotelVenueFaceRetake;

  /// No description provided for @hotelVenueFaceCrop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get hotelVenueFaceCrop;

  /// No description provided for @hotelVenueFaceFirst.
  ///
  /// In en, this message translates to:
  /// **'Retake or crop first'**
  String get hotelVenueFaceFirst;

  /// No description provided for @hotelVenueToastUploadStarted.
  ///
  /// In en, this message translates to:
  /// **'Upload started'**
  String get hotelVenueToastUploadStarted;

  /// No description provided for @hotelVenueToastQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get hotelVenueToastQueued;

  /// No description provided for @hotelVenueToastPhotoAdded.
  ///
  /// In en, this message translates to:
  /// **'Photo added'**
  String get hotelVenueToastPhotoAdded;

  /// No description provided for @hotelVenueToastReplaced.
  ///
  /// In en, this message translates to:
  /// **'Photo replaced'**
  String get hotelVenueToastReplaced;

  /// No description provided for @hotelVenueChipReview.
  ///
  /// In en, this message translates to:
  /// **'Under review {count}'**
  String hotelVenueChipReview(num count);

  /// No description provided for @hotelVenueUploadDemoPhoto.
  ///
  /// In en, this message translates to:
  /// **'New photo'**
  String get hotelVenueUploadDemoPhoto;

  /// No description provided for @hotelVenueSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get hotelVenueSave;

  /// No description provided for @hotelVenueSavedState.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get hotelVenueSavedState;

  /// No description provided for @hotelVenueFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get hotelVenueFieldName;

  /// No description provided for @hotelVenueFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get hotelVenueFieldDescription;

  /// No description provided for @hotelVenueNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name in both languages'**
  String get hotelVenueNameRequired;

  /// No description provided for @hotelVenueReservedName.
  ///
  /// In en, this message translates to:
  /// **'Reserved name'**
  String get hotelVenueReservedName;

  /// No description provided for @hotelVenueAudWomen.
  ///
  /// In en, this message translates to:
  /// **'Ladies'**
  String get hotelVenueAudWomen;

  /// No description provided for @hotelVenueAudMen.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get hotelVenueAudMen;

  /// No description provided for @hotelVenueAudMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get hotelVenueAudMixed;

  /// No description provided for @hotelVenueGuestRange.
  ///
  /// In en, this message translates to:
  /// **'{from}–{to}'**
  String hotelVenueGuestRange(String from, String to);

  /// No description provided for @hotelVenueAllDays.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get hotelVenueAllDays;

  /// No description provided for @hotelVenueHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hotelVenueHidden;

  /// No description provided for @hotelVenueOfflineChange.
  ///
  /// In en, this message translates to:
  /// **'Needs a connection to change.'**
  String get hotelVenueOfflineChange;

  /// No description provided for @hotelVenuePackagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get hotelVenuePackagesTitle;

  /// No description provided for @hotelVenuePkgNew.
  ///
  /// In en, this message translates to:
  /// **'New package'**
  String get hotelVenuePkgNew;

  /// No description provided for @hotelVenuePkgEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No packages'**
  String get hotelVenuePkgEmptyTitle;

  /// No description provided for @hotelVenuePkgActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Show {name} to couples'**
  String hotelVenuePkgActiveLabel(String name);

  /// No description provided for @hotelVenueToastPkgHidden.
  ///
  /// In en, this message translates to:
  /// **'{name} hidden'**
  String hotelVenueToastPkgHidden(String name);

  /// No description provided for @hotelVenueToastPkgShown.
  ///
  /// In en, this message translates to:
  /// **'{name} visible'**
  String hotelVenueToastPkgShown(String name);

  /// No description provided for @hotelVenueArchivedHead.
  ///
  /// In en, this message translates to:
  /// **'Archived ({count})'**
  String hotelVenueArchivedHead(num count);

  /// No description provided for @hotelVenueRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get hotelVenueRestore;

  /// No description provided for @hotelVenueToastRestored.
  ///
  /// In en, this message translates to:
  /// **'{name} restored'**
  String hotelVenueToastRestored(String name);

  /// No description provided for @hotelVenueToastArchived.
  ///
  /// In en, this message translates to:
  /// **'{name} archived'**
  String hotelVenueToastArchived(String name);

  /// No description provided for @hotelVenueEditPackage.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String hotelVenueEditPackage(String name);

  /// No description provided for @hotelVenueNeedPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a price'**
  String get hotelVenueNeedPrice;

  /// No description provided for @hotelVenuePkgEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit package'**
  String get hotelVenuePkgEditTitle;

  /// No description provided for @hotelVenueSecName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get hotelVenueSecName;

  /// No description provided for @hotelVenueSecAudience.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get hotelVenueSecAudience;

  /// No description provided for @hotelVenueSecPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get hotelVenueSecPricing;

  /// No description provided for @hotelVenueSecGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get hotelVenueSecGuests;

  /// No description provided for @hotelVenueSecInclusions.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get hotelVenueSecInclusions;

  /// No description provided for @hotelVenueSecPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get hotelVenueSecPreview;

  /// No description provided for @hotelVenueSecStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get hotelVenueSecStatus;

  /// No description provided for @hotelVenueAudienceLabel.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get hotelVenueAudienceLabel;

  /// No description provided for @hotelVenueAudienceNeeded.
  ///
  /// In en, this message translates to:
  /// **'Choose an audience'**
  String get hotelVenueAudienceNeeded;

  /// No description provided for @hotelVenueHallsLabel.
  ///
  /// In en, this message translates to:
  /// **'Halls'**
  String get hotelVenueHallsLabel;

  /// No description provided for @hotelVenueHallsNeeded.
  ///
  /// In en, this message translates to:
  /// **'Choose a hall'**
  String get hotelVenueHallsNeeded;

  /// No description provided for @hotelVenueBasisLabel.
  ///
  /// In en, this message translates to:
  /// **'Pricing basis'**
  String get hotelVenueBasisLabel;

  /// No description provided for @hotelVenueBasisFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get hotelVenueBasisFlat;

  /// No description provided for @hotelVenueBasisFlatPlus.
  ///
  /// In en, this message translates to:
  /// **'Flat + guest'**
  String get hotelVenueBasisFlatPlus;

  /// No description provided for @hotelVenueDaysWeekday.
  ///
  /// In en, this message translates to:
  /// **'Weekday · {from} to {to}'**
  String hotelVenueDaysWeekday(String from, String to);

  /// No description provided for @hotelVenueDaysWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend · {from} to {to}'**
  String hotelVenueDaysWeekend(String from, String to);

  /// No description provided for @hotelVenueDaysSwitch.
  ///
  /// In en, this message translates to:
  /// **'Offer on {days}'**
  String hotelVenueDaysSwitch(String days);

  /// No description provided for @hotelVenueBundleNote.
  ///
  /// In en, this message translates to:
  /// **'Priced from two packages'**
  String get hotelVenueBundleNote;

  /// No description provided for @hotelVenueTierNeeded.
  ///
  /// In en, this message translates to:
  /// **'Offer on some days'**
  String get hotelVenueTierNeeded;

  /// No description provided for @hotelVenueGuestsMin.
  ///
  /// In en, this message translates to:
  /// **'Min guests'**
  String get hotelVenueGuestsMin;

  /// No description provided for @hotelVenueGuestsMax.
  ///
  /// In en, this message translates to:
  /// **'Max guests'**
  String get hotelVenueGuestsMax;

  /// No description provided for @hotelVenueMaxBelowMin.
  ///
  /// In en, this message translates to:
  /// **'Max below min'**
  String get hotelVenueMaxBelowMin;

  /// No description provided for @hotelVenueMaxOverHall.
  ///
  /// In en, this message translates to:
  /// **'Over hall capacity ({max})'**
  String hotelVenueMaxOverHall(String max);

  /// No description provided for @hotelVenueInclusionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get hotelVenueInclusionAdd;

  /// No description provided for @hotelVenueInclusionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String hotelVenueInclusionRemove(String name);

  /// No description provided for @hotelVenueInclusionSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get hotelVenueInclusionSheetTitle;

  /// No description provided for @hotelVenueInclusionPick.
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get hotelVenueInclusionPick;

  /// No description provided for @hotelVenueInclusionOwn.
  ///
  /// In en, this message translates to:
  /// **'Your own'**
  String get hotelVenueInclusionOwn;

  /// No description provided for @hotelVenueInclusionOwnLabel.
  ///
  /// In en, this message translates to:
  /// **'Inclusion'**
  String get hotelVenueInclusionOwnLabel;

  /// No description provided for @hotelVenueInclusionBoth.
  ///
  /// In en, this message translates to:
  /// **'Both languages'**
  String get hotelVenueInclusionBoth;

  /// No description provided for @hotelVenueActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get hotelVenueActiveTitle;

  /// No description provided for @hotelVenueArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get hotelVenueArchive;

  /// No description provided for @hotelVenueArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive?'**
  String get hotelVenueArchiveTitle;

  /// No description provided for @hotelVenueArchiveBody.
  ///
  /// In en, this message translates to:
  /// **'Hidden from couples. You can restore it.'**
  String get hotelVenueArchiveBody;

  /// No description provided for @hotelVenueArchiveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get hotelVenueArchiveConfirm;

  /// No description provided for @hotelVenuePvDate.
  ///
  /// In en, this message translates to:
  /// **'Date and guests'**
  String get hotelVenuePvDate;

  /// No description provided for @hotelVenuePvGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests only'**
  String get hotelVenuePvGuests;

  /// No description provided for @hotelVenuePvNone.
  ///
  /// In en, this message translates to:
  /// **'Neither'**
  String get hotelVenuePvNone;

  /// No description provided for @hotelVenuePvOff.
  ///
  /// In en, this message translates to:
  /// **'Not offered'**
  String get hotelVenuePvOff;

  /// No description provided for @hotelVenuePvNoName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get hotelVenuePvNoName;

  /// No description provided for @hotelVenueToastPkgSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get hotelVenueToastPkgSaved;

  /// No description provided for @hotelVenueToastPkgCreated.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get hotelVenueToastPkgCreated;

  /// No description provided for @hotelVenueReasonPrices.
  ///
  /// In en, this message translates to:
  /// **'Enter prices'**
  String get hotelVenueReasonPrices;

  /// No description provided for @hotelVenueReasonGuests.
  ///
  /// In en, this message translates to:
  /// **'Fix guest numbers'**
  String get hotelVenueReasonGuests;

  /// No description provided for @hotelVenueSettingIndoor.
  ///
  /// In en, this message translates to:
  /// **'Indoor'**
  String get hotelVenueSettingIndoor;

  /// No description provided for @hotelVenueSettingOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get hotelVenueSettingOutdoor;

  /// No description provided for @hotelVenueSettingMixed.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get hotelVenueSettingMixed;

  /// No description provided for @hotelVenueNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get hotelVenueNone;

  /// No description provided for @hotelVenueHallsTitle.
  ///
  /// In en, this message translates to:
  /// **'Halls'**
  String get hotelVenueHallsTitle;

  /// No description provided for @hotelVenueHallEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit hall'**
  String get hotelVenueHallEditTitle;

  /// No description provided for @hotelVenueSecCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get hotelVenueSecCapacity;

  /// No description provided for @hotelVenueSecHallAudience.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get hotelVenueSecHallAudience;

  /// No description provided for @hotelVenueSecSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get hotelVenueSecSessions;

  /// No description provided for @hotelVenueSecFacilities.
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get hotelVenueSecFacilities;

  /// No description provided for @hotelVenueSecSections.
  ///
  /// In en, this message translates to:
  /// **'By section'**
  String get hotelVenueSecSections;

  /// No description provided for @hotelVenueCapMax.
  ///
  /// In en, this message translates to:
  /// **'Max guests'**
  String get hotelVenueCapMax;

  /// No description provided for @hotelVenueCapMin.
  ///
  /// In en, this message translates to:
  /// **'Min · {audience}'**
  String hotelVenueCapMin(String audience);

  /// No description provided for @hotelVenueMinAboveMax.
  ///
  /// In en, this message translates to:
  /// **'Min above max'**
  String get hotelVenueMinAboveMax;

  /// No description provided for @hotelVenueAudAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Choose an audience'**
  String get hotelVenueAudAtLeastOne;

  /// No description provided for @hotelVenueSettingLabel.
  ///
  /// In en, this message translates to:
  /// **'Setting'**
  String get hotelVenueSettingLabel;

  /// No description provided for @hotelVenueAudienceAllowed.
  ///
  /// In en, this message translates to:
  /// **'Audiences allowed'**
  String get hotelVenueAudienceAllowed;

  /// No description provided for @hotelVenueExclusiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Whole day'**
  String get hotelVenueExclusiveTitle;

  /// No description provided for @hotelVenueSessionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add session'**
  String get hotelVenueSessionAdd;

  /// No description provided for @hotelVenueSessionLine.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String hotelVenueSessionLine(String from, String to);

  /// No description provided for @hotelVenueSessionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Add a session'**
  String get hotelVenueSessionNeeded;

  /// No description provided for @hotelVenueSessionEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit session'**
  String get hotelVenueSessionEditTitle;

  /// No description provided for @hotelVenueSessionNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New session'**
  String get hotelVenueSessionNewTitle;

  /// No description provided for @hotelVenueSessionName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get hotelVenueSessionName;

  /// No description provided for @hotelVenueSessionStart.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get hotelVenueSessionStart;

  /// No description provided for @hotelVenueSessionEnd.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get hotelVenueSessionEnd;

  /// No description provided for @hotelVenueSessionSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get hotelVenueSessionSetup;

  /// No description provided for @hotelVenueSessionTeardown.
  ///
  /// In en, this message translates to:
  /// **'Teardown'**
  String get hotelVenueSessionTeardown;

  /// No description provided for @hotelVenueSessionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get hotelVenueSessionDelete;

  /// No description provided for @hotelVenueSessionAfterMidnight.
  ///
  /// In en, this message translates to:
  /// **'After midnight'**
  String get hotelVenueSessionAfterMidnight;

  /// No description provided for @hotelVenueSessionNameNeeded.
  ///
  /// In en, this message translates to:
  /// **'Name both languages'**
  String get hotelVenueSessionNameNeeded;

  /// No description provided for @hotelVenuePresetsLabel.
  ///
  /// In en, this message translates to:
  /// **'Start from a preset'**
  String get hotelVenuePresetsLabel;

  /// No description provided for @hotelVenuePresetAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get hotelVenuePresetAfternoon;

  /// No description provided for @hotelVenuePresetEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get hotelVenuePresetEvening;

  /// No description provided for @hotelVenuePresetFull.
  ///
  /// In en, this message translates to:
  /// **'Full day'**
  String get hotelVenuePresetFull;

  /// No description provided for @hotelVenueAmIncluded.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get hotelVenueAmIncluded;

  /// No description provided for @hotelVenueAmExtra.
  ///
  /// In en, this message translates to:
  /// **'Extra cost'**
  String get hotelVenueAmExtra;

  /// No description provided for @hotelVenueAmNone.
  ///
  /// In en, this message translates to:
  /// **'Not offered'**
  String get hotelVenueAmNone;

  /// No description provided for @hotelVenueAmenityOf.
  ///
  /// In en, this message translates to:
  /// **'{name} · {audience}'**
  String hotelVenueAmenityOf(String name, String audience);

  /// No description provided for @hotelVenueAmenityChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose for {name}'**
  String hotelVenueAmenityChoose(String name);

  /// No description provided for @hotelVenueSectionWomen.
  ///
  /// In en, this message translates to:
  /// **'Ladies'**
  String get hotelVenueSectionWomen;

  /// No description provided for @hotelVenueSectionMen.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get hotelVenueSectionMen;

  /// No description provided for @hotelVenueSectionMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get hotelVenueSectionMixed;

  /// No description provided for @hotelVenueFactPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get hotelVenueFactPhoto;

  /// No description provided for @hotelVenueFactMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get hotelVenueFactMusic;

  /// No description provided for @hotelVenuePhotoFemale.
  ///
  /// In en, this message translates to:
  /// **'Women only'**
  String get hotelVenuePhotoFemale;

  /// No description provided for @hotelVenuePhotoAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get hotelVenuePhotoAllowed;

  /// No description provided for @hotelVenuePhotoNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get hotelVenuePhotoNone;

  /// No description provided for @hotelVenueMusicDj.
  ///
  /// In en, this message translates to:
  /// **'DJ'**
  String get hotelVenueMusicDj;

  /// No description provided for @hotelVenueMusicLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get hotelVenueMusicLive;

  /// No description provided for @hotelVenueMusicDuff.
  ///
  /// In en, this message translates to:
  /// **'Duff'**
  String get hotelVenueMusicDuff;

  /// No description provided for @hotelVenueMusicNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get hotelVenueMusicNone;

  /// No description provided for @hotelVenueLinkRules.
  ///
  /// In en, this message translates to:
  /// **'Booking rules'**
  String get hotelVenueLinkRules;

  /// No description provided for @hotelVenueToastHallSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get hotelVenueToastHallSaved;

  /// No description provided for @hotelVenuePolTitle.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get hotelVenuePolTitle;

  /// No description provided for @hotelVenueSecChildren.
  ///
  /// In en, this message translates to:
  /// **'Boys'**
  String get hotelVenueSecChildren;

  /// No description provided for @hotelVenueSecDress.
  ///
  /// In en, this message translates to:
  /// **'Dress code'**
  String get hotelVenueSecDress;

  /// No description provided for @hotelVenueChildrenNoLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get hotelVenueChildrenNoLimit;

  /// No description provided for @hotelVenueChildrenLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get hotelVenueChildrenLimit;

  /// No description provided for @hotelVenueChildrenAge.
  ///
  /// In en, this message translates to:
  /// **'Max age'**
  String get hotelVenueChildrenAge;

  /// No description provided for @hotelVenueYears.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} year} other{{count} years}}'**
  String hotelVenueYears(int count);

  /// No description provided for @hotelVenueDressLabel.
  ///
  /// In en, this message translates to:
  /// **'Dress code'**
  String get hotelVenueDressLabel;

  /// No description provided for @hotelVenueDressNeeded.
  ///
  /// In en, this message translates to:
  /// **'Dress code in both languages'**
  String get hotelVenueDressNeeded;

  /// No description provided for @hotelVenueToastPolicySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get hotelVenueToastPolicySaved;

  /// No description provided for @hotelVenueRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking rules'**
  String get hotelVenueRulesTitle;

  /// No description provided for @hotelVenueRulesHall.
  ///
  /// In en, this message translates to:
  /// **'Hall'**
  String get hotelVenueRulesHall;

  /// No description provided for @hotelVenueSecMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get hotelVenueSecMode;

  /// No description provided for @hotelVenueSecResponse.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get hotelVenueSecResponse;

  /// No description provided for @hotelVenueModeRequest.
  ///
  /// In en, this message translates to:
  /// **'Request to book'**
  String get hotelVenueModeRequest;

  /// No description provided for @hotelVenueRespondLabel.
  ///
  /// In en, this message translates to:
  /// **'Reply within'**
  String get hotelVenueRespondLabel;

  /// No description provided for @hotelVenueRespondWarn.
  ///
  /// In en, this message translates to:
  /// **'May lower response rate'**
  String get hotelVenueRespondWarn;

  /// No description provided for @hotelVenueNoticeDays.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get hotelVenueNoticeDays;

  /// No description provided for @hotelVenueLinkCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get hotelVenueLinkCalendar;

  /// No description provided for @hotelVenueToastRulesSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get hotelVenueToastRulesSaved;

  /// No description provided for @hotelVenueWindowsRow.
  ///
  /// In en, this message translates to:
  /// **'Voucher windows'**
  String get hotelVenueWindowsRow;

  /// No description provided for @hotelVenueReasonVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher above standard'**
  String get hotelVenueReasonVoucher;

  /// No description provided for @hotelVenueStdFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get hotelVenueStdFlat;

  /// No description provided for @hotelVenueStdPerGuest.
  ///
  /// In en, this message translates to:
  /// **'Per guest'**
  String get hotelVenueStdPerGuest;

  /// No description provided for @hotelVenueVchFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get hotelVenueVchFlat;

  /// No description provided for @hotelVenueVchPerGuest.
  ///
  /// In en, this message translates to:
  /// **'Per guest'**
  String get hotelVenueVchPerGuest;

  /// No description provided for @hotelVenueVoucherAboveFlat.
  ///
  /// In en, this message translates to:
  /// **'Above standard'**
  String get hotelVenueVoucherAboveFlat;

  /// No description provided for @hotelVenueVoucherAboveGuest.
  ///
  /// In en, this message translates to:
  /// **'Above standard'**
  String get hotelVenueVoucherAboveGuest;

  /// No description provided for @hotelVenueVchBelowFee.
  ///
  /// In en, this message translates to:
  /// **'Saving under {fee}'**
  String hotelVenueVchBelowFee(String fee);

  /// No description provided for @hotelVenueVchSaving.
  ///
  /// In en, this message translates to:
  /// **'Saves {amount}'**
  String hotelVenueVchSaving(String amount);

  /// No description provided for @hotelVenuePvStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard {standard}'**
  String hotelVenuePvStandard(String standard);

  /// No description provided for @hotelVenueNoVoucherTag.
  ///
  /// In en, this message translates to:
  /// **'No voucher price'**
  String get hotelVenueNoVoucherTag;

  /// No description provided for @hotelVenueHoursRun.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String hotelVenueHoursRun(String from, String to);

  /// No description provided for @hotelVenueHoursLine.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String hotelVenueHoursLine(String from, String to);

  /// No description provided for @hotelVenueHoursOpen.
  ///
  /// In en, this message translates to:
  /// **'Opens'**
  String get hotelVenueHoursOpen;

  /// No description provided for @hotelVenueHoursClose.
  ///
  /// In en, this message translates to:
  /// **'Closes'**
  String get hotelVenueHoursClose;

  /// No description provided for @hotelVenueHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hotelVenueHoursTitle;

  /// No description provided for @hotelVenueSecHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hotelVenueSecHours;

  /// No description provided for @hotelVenueSecTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get hotelVenueSecTerms;

  /// No description provided for @hotelVenueTermsLabel.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get hotelVenueTermsLabel;

  /// No description provided for @hotelVenueTermsNeeded.
  ///
  /// In en, this message translates to:
  /// **'Terms in both languages'**
  String get hotelVenueTermsNeeded;

  /// No description provided for @hotelVenueVoucherTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher terms'**
  String get hotelVenueVoucherTermsTitle;

  /// No description provided for @hotelVenueVtFee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get hotelVenueVtFee;

  /// No description provided for @hotelVenueVtValidity.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get hotelVenueVtValidity;

  /// No description provided for @hotelVenueVtConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get hotelVenueVtConfirm;

  /// No description provided for @hotelVenueVtRedeem.
  ///
  /// In en, this message translates to:
  /// **'At venue'**
  String get hotelVenueVtRedeem;

  /// No description provided for @hotelVenueVtRedeemValue.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get hotelVenueVtRedeemValue;

  /// No description provided for @hotelVenueSecConfirm.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get hotelVenueSecConfirm;

  /// No description provided for @hotelVenueConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get hotelVenueConfirmLabel;

  /// No description provided for @hotelVenueConfirmFixed.
  ///
  /// In en, this message translates to:
  /// **'{hours}'**
  String hotelVenueConfirmFixed(String hours);

  /// No description provided for @hotelVenueNoticeShort.
  ///
  /// In en, this message translates to:
  /// **'Notice shorter than reply window'**
  String get hotelVenueNoticeShort;

  /// No description provided for @hotelVenueLinkVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher prices'**
  String get hotelVenueLinkVoucher;

  /// No description provided for @hotelVenueLinkVisits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get hotelVenueLinkVisits;

  /// No description provided for @hotelVenueTlRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get hotelVenueTlRequest;

  /// No description provided for @hotelVenueTlReply.
  ///
  /// In en, this message translates to:
  /// **'Reply {hours}'**
  String hotelVenueTlReply(String hours);

  /// No description provided for @hotelVenueTlConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm {hours}'**
  String hotelVenueTlConfirm(String hours);

  /// No description provided for @hotelVenueTlPay.
  ///
  /// In en, this message translates to:
  /// **'Pay venue'**
  String get hotelVenueTlPay;

  /// No description provided for @hotelVenueTlPayText.
  ///
  /// In en, this message translates to:
  /// **'{voucher} · {standard}'**
  String hotelVenueTlPayText(String voucher, String standard);

  /// No description provided for @hotelVenueSecProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get hotelVenueSecProfile;

  /// No description provided for @hotelVenueTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Venue type'**
  String get hotelVenueTypeLabel;

  /// No description provided for @hotelVenueTypePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get hotelVenueTypePending;

  /// No description provided for @hotelVenueToastTypeSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get hotelVenueToastTypeSent;

  /// No description provided for @hotelVenueSecHalls.
  ///
  /// In en, this message translates to:
  /// **'Halls'**
  String get hotelVenueSecHalls;

  /// No description provided for @hotelVenueStd.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get hotelVenueStd;

  /// No description provided for @hotelVenueVch.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get hotelVenueVch;

  /// No description provided for @hotelVisitsActorHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get hotelVisitsActorHotel;

  /// No description provided for @hotelVisitsActorSupport.
  ///
  /// In en, this message translates to:
  /// **'Ghazal support'**
  String get hotelVisitsActorSupport;

  /// No description provided for @hotelVisitsActorSystem.
  ///
  /// In en, this message translates to:
  /// **'Ghazal'**
  String get hotelVisitsActorSystem;

  /// No description provided for @hotelVisitsArrivalTitle.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get hotelVisitsArrivalTitle;

  /// No description provided for @hotelVisitsArrivalError.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get hotelVisitsArrivalError;

  /// No description provided for @hotelVisitsDemoJump.
  ///
  /// In en, this message translates to:
  /// **'Demo: jump to the day of the visit'**
  String get hotelVisitsDemoJump;

  /// No description provided for @hotelVisitsArrivedDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} arrived'**
  String hotelVisitsArrivedDoneTitle(String name);

  /// No description provided for @hotelVisitsMarkArrived.
  ///
  /// In en, this message translates to:
  /// **'Mark arrived'**
  String get hotelVisitsMarkArrived;

  /// No description provided for @hotelVisitsDidNotArrive.
  ///
  /// In en, this message translates to:
  /// **'No-show'**
  String get hotelVisitsDidNotArrive;

  /// No description provided for @hotelVisitsMissedCta.
  ///
  /// In en, this message translates to:
  /// **'No-show'**
  String get hotelVisitsMissedCta;

  /// No description provided for @hotelVisitsMissedDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark no-show?'**
  String get hotelVisitsMissedDialogTitle;

  /// No description provided for @hotelVisitsMissedDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Ghazal support is informed.'**
  String get hotelVisitsMissedDialogBody;

  /// No description provided for @hotelVisitsMissedDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} did not arrive'**
  String hotelVisitsMissedDoneTitle(String name);

  /// No description provided for @hotelVisitsMissedFrom.
  ///
  /// In en, this message translates to:
  /// **'From {time}'**
  String hotelVisitsMissedFrom(String time);

  /// No description provided for @hotelVisitsOnTheWayTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} is on the way'**
  String hotelVisitsOnTheWayTitle(String name);

  /// No description provided for @hotelVisitsOnTheWayBody.
  ///
  /// In en, this message translates to:
  /// **'{time}'**
  String hotelVisitsOnTheWayBody(String time);

  /// No description provided for @hotelVisitsSlotEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'Window ended'**
  String get hotelVisitsSlotEndedTitle;

  /// No description provided for @hotelVisitsSlotEndedBody.
  ///
  /// In en, this message translates to:
  /// **'{name}'**
  String hotelVisitsSlotEndedBody(String name);

  /// No description provided for @hotelVisitsAttachTitle.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get hotelVisitsAttachTitle;

  /// No description provided for @hotelVisitsAttachCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get hotelVisitsAttachCamera;

  /// No description provided for @hotelVisitsAttachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get hotelVisitsAttachPhoto;

  /// No description provided for @hotelVisitsAttachDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get hotelVisitsAttachDocument;

  /// No description provided for @hotelVisitsAvailTitle.
  ///
  /// In en, this message translates to:
  /// **'Visit hours'**
  String get hotelVisitsAvailTitle;

  /// No description provided for @hotelVisitsAvailabilityAction.
  ///
  /// In en, this message translates to:
  /// **'Visit hours'**
  String get hotelVisitsAvailabilityAction;

  /// No description provided for @hotelVisitsAvailErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Did not load'**
  String get hotelVisitsAvailErrorTitle;

  /// No description provided for @hotelVisitsAvailHiddenTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin and Manager only'**
  String get hotelVisitsAvailHiddenTitle;

  /// No description provided for @hotelVisitsAvailHiddenBody.
  ///
  /// In en, this message translates to:
  /// **'Ask your manager.'**
  String get hotelVisitsAvailHiddenBody;

  /// No description provided for @hotelVisitsMasterTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept visits'**
  String get hotelVisitsMasterTitle;

  /// No description provided for @hotelVisitsOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Visits off'**
  String get hotelVisitsOffTitle;

  /// No description provided for @hotelVisitsOffBody.
  ///
  /// In en, this message translates to:
  /// **'Hidden from your page'**
  String get hotelVisitsOffBody;

  /// No description provided for @hotelVisitsSecDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get hotelVisitsSecDays;

  /// No description provided for @hotelVisitsDayNoVisits.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get hotelVisitsDayNoVisits;

  /// No description provided for @hotelVisitsDayFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get hotelVisitsDayFrom;

  /// No description provided for @hotelVisitsDayTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get hotelVisitsDayTo;

  /// No description provided for @hotelVisitsDayOpenLabel.
  ///
  /// In en, this message translates to:
  /// **'Visits on {day}'**
  String hotelVisitsDayOpenLabel(String day);

  /// No description provided for @hotelVisitsDayPick.
  ///
  /// In en, this message translates to:
  /// **'{what} at {time}'**
  String hotelVisitsDayPick(String what, String time);

  /// No description provided for @hotelVisitsDayErrorOrder.
  ///
  /// In en, this message translates to:
  /// **'End after start'**
  String get hotelVisitsDayErrorOrder;

  /// No description provided for @hotelVisitsDayErrorBounds.
  ///
  /// In en, this message translates to:
  /// **'Within business hours'**
  String get hotelVisitsDayErrorBounds;

  /// No description provided for @hotelVisitsSeeBusinessHours.
  ///
  /// In en, this message translates to:
  /// **'Business hours'**
  String get hotelVisitsSeeBusinessHours;

  /// No description provided for @hotelVisitsTimeFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get hotelVisitsTimeFrom;

  /// No description provided for @hotelVisitsTimeTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get hotelVisitsTimeTo;

  /// No description provided for @hotelVisitsTimeSet.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get hotelVisitsTimeSet;

  /// No description provided for @hotelVisitsSecSlot.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get hotelVisitsSecSlot;

  /// No description provided for @hotelVisitsSlotChip.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String hotelVisitsSlotChip(String minutes);

  /// No description provided for @hotelVisitsSecRepDefault.
  ///
  /// In en, this message translates to:
  /// **'Default rep'**
  String get hotelVisitsSecRepDefault;

  /// No description provided for @hotelVisitsRepNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get hotelVisitsRepNone;

  /// No description provided for @hotelVisitsSecBlackouts.
  ///
  /// In en, this message translates to:
  /// **'Blackout dates'**
  String get hotelVisitsSecBlackouts;

  /// No description provided for @hotelVisitsBlackoutsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add dates'**
  String get hotelVisitsBlackoutsAdd;

  /// No description provided for @hotelVisitsBlackoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Blackout dates'**
  String get hotelVisitsBlackoutTitle;

  /// No description provided for @hotelVisitsBlackoutNeed.
  ///
  /// In en, this message translates to:
  /// **'Pick a day'**
  String get hotelVisitsBlackoutNeed;

  /// No description provided for @hotelVisitsBlackoutAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get hotelVisitsBlackoutAdd;

  /// No description provided for @hotelVisitsBlackoutRange.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String hotelVisitsBlackoutRange(String from, String to);

  /// No description provided for @hotelVisitsBlackoutRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove blackout {range}'**
  String hotelVisitsBlackoutRemove(String range);

  /// No description provided for @hotelVisitsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get hotelVisitsSave;

  /// No description provided for @hotelVisitsSaveClean.
  ///
  /// In en, this message translates to:
  /// **'No changes'**
  String get hotelVisitsSaveClean;

  /// No description provided for @hotelVisitsSaveInvalid.
  ///
  /// In en, this message translates to:
  /// **'Fix days'**
  String get hotelVisitsSaveInvalid;

  /// No description provided for @hotelVisitsSaveOfflineToast.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get hotelVisitsSaveOfflineToast;

  /// No description provided for @hotelVisitsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get hotelVisitsSaved;

  /// No description provided for @hotelVisitsSavedBanner.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get hotelVisitsSavedBanner;

  /// No description provided for @hotelVisitsGuardTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave unsaved?'**
  String get hotelVisitsGuardTitle;

  /// No description provided for @hotelVisitsGuardBody.
  ///
  /// In en, this message translates to:
  /// **'Changes are lost.'**
  String get hotelVisitsGuardBody;

  /// No description provided for @hotelVisitsGuardLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get hotelVisitsGuardLeave;

  /// No description provided for @hotelVisitsGuardStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get hotelVisitsGuardStay;

  /// No description provided for @hotelVisitsChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Visit chat'**
  String get hotelVisitsChatTitle;

  /// No description provided for @hotelVisitsChatErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat did not load'**
  String get hotelVisitsChatErrorTitle;

  /// No description provided for @hotelVisitsChatOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline. Last update {time}'**
  String hotelVisitsChatOfflineBanner(String time);

  /// No description provided for @hotelVisitsChatReadOnlyRole.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get hotelVisitsChatReadOnlyRole;

  /// No description provided for @hotelVisitsChatClosedAfter.
  ///
  /// In en, this message translates to:
  /// **'Chat closed'**
  String get hotelVisitsChatClosedAfter;

  /// No description provided for @hotelVisitsChatClosedCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get hotelVisitsChatClosedCancelled;

  /// No description provided for @hotelVisitsChatClosedDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get hotelVisitsChatClosedDeclined;

  /// No description provided for @hotelVisitsMsgFailed.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get hotelVisitsMsgFailed;

  /// No description provided for @hotelVisitsMsgQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get hotelVisitsMsgQueued;

  /// No description provided for @hotelVisitsMsgSending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get hotelVisitsMsgSending;

  /// No description provided for @hotelVisitsRecordHold.
  ///
  /// In en, this message translates to:
  /// **'Hold to record'**
  String get hotelVisitsRecordHold;

  /// No description provided for @hotelVisitsQrConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm visit'**
  String get hotelVisitsQrConfirm;

  /// No description provided for @hotelVisitsQrConfirmText.
  ///
  /// In en, this message translates to:
  /// **'Visit confirmed. We look forward to welcoming you.'**
  String get hotelVisitsQrConfirmText;

  /// No description provided for @hotelVisitsQrEntrance.
  ///
  /// In en, this message translates to:
  /// **'Main entrance'**
  String get hotelVisitsQrEntrance;

  /// No description provided for @hotelVisitsQrEntranceText.
  ///
  /// In en, this message translates to:
  /// **'Please use the main entrance.'**
  String get hotelVisitsQrEntranceText;

  /// No description provided for @hotelVisitsQrParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get hotelVisitsQrParking;

  /// No description provided for @hotelVisitsQrParkingText.
  ///
  /// In en, this message translates to:
  /// **'Parking is at the front.'**
  String get hotelVisitsQrParkingText;

  /// No description provided for @hotelVisitsLineConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed for {when}'**
  String hotelVisitsLineConfirmed(String when);

  /// No description provided for @hotelVisitsLineReschedule.
  ///
  /// In en, this message translates to:
  /// **'{name} proposed {when}'**
  String hotelVisitsLineReschedule(String name, String when);

  /// No description provided for @hotelVisitsLineArrived.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String hotelVisitsLineArrived(String name);

  /// No description provided for @hotelVisitsLineCompleted.
  ///
  /// In en, this message translates to:
  /// **'Visit complete'**
  String get hotelVisitsLineCompleted;

  /// No description provided for @hotelVisitsLineDeclined.
  ///
  /// In en, this message translates to:
  /// **'Visit declined'**
  String get hotelVisitsLineDeclined;

  /// No description provided for @hotelVisitsLineCancelled.
  ///
  /// In en, this message translates to:
  /// **'Visit cancelled'**
  String get hotelVisitsLineCancelled;

  /// No description provided for @hotelVisitsLineMissed.
  ///
  /// In en, this message translates to:
  /// **'Client did not arrive'**
  String get hotelVisitsLineMissed;

  /// No description provided for @hotelVisitsLineClosed.
  ///
  /// In en, this message translates to:
  /// **'Chat closed'**
  String get hotelVisitsLineClosed;

  /// No description provided for @hotelVisitsMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get hotelVisitsMembersTitle;

  /// No description provided for @hotelVisitsRepTitle.
  ///
  /// In en, this message translates to:
  /// **'Representative'**
  String get hotelVisitsRepTitle;

  /// No description provided for @hotelVisitsQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get hotelVisitsQueueTitle;

  /// No description provided for @hotelVisitsSegments.
  ///
  /// In en, this message translates to:
  /// **'Visits by status'**
  String get hotelVisitsSegments;

  /// No description provided for @hotelVisitsSegRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get hotelVisitsSegRequested;

  /// No description provided for @hotelVisitsSegUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get hotelVisitsSegUpcoming;

  /// No description provided for @hotelVisitsSegPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get hotelVisitsSegPast;

  /// No description provided for @hotelVisitsRequestedAgo.
  ///
  /// In en, this message translates to:
  /// **'{ago}'**
  String hotelVisitsRequestedAgo(String ago);

  /// No description provided for @hotelVisitsOpenVisit.
  ///
  /// In en, this message translates to:
  /// **'Open the visit of {name}, {when}'**
  String hotelVisitsOpenVisit(String name, String when);

  /// No description provided for @hotelVisitsEmptyRequestedTitle.
  ///
  /// In en, this message translates to:
  /// **'No requests'**
  String get hotelVisitsEmptyRequestedTitle;

  /// No description provided for @hotelVisitsEmptyRequestedBody.
  ///
  /// In en, this message translates to:
  /// **'Clients can book a visit from your venue page.'**
  String get hotelVisitsEmptyRequestedBody;

  /// No description provided for @hotelVisitsEmptyUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'No upcoming visits'**
  String get hotelVisitsEmptyUpcomingTitle;

  /// No description provided for @hotelVisitsEmptyUpcomingBody.
  ///
  /// In en, this message translates to:
  /// **'Confirmed visits appear here with their chat.'**
  String get hotelVisitsEmptyUpcomingBody;

  /// No description provided for @hotelVisitsEmptyPastTitle.
  ///
  /// In en, this message translates to:
  /// **'No past visits'**
  String get hotelVisitsEmptyPastTitle;

  /// No description provided for @hotelVisitsEmptyPastBody.
  ///
  /// In en, this message translates to:
  /// **'Completed, declined and missed visits are kept here.'**
  String get hotelVisitsEmptyPastBody;

  /// No description provided for @hotelVisitsSeeUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get hotelVisitsSeeUpcoming;

  /// No description provided for @hotelVisitsErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Did not load'**
  String get hotelVisitsErrorTitle;

  /// No description provided for @hotelVisitsErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get hotelVisitsErrorBody;

  /// No description provided for @hotelVisitsOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline. Saved {time}'**
  String hotelVisitsOfflineBanner(String time);

  /// No description provided for @hotelVisitsOfflineBannerShort.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get hotelVisitsOfflineBannerShort;

  /// No description provided for @hotelVisitsOfflineReason.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get hotelVisitsOfflineReason;

  /// No description provided for @hotelVisitsReadOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get hotelVisitsReadOnlyNote;

  /// No description provided for @hotelVisitsNoAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'No access'**
  String get hotelVisitsNoAccessTitle;

  /// No description provided for @hotelVisitsNoAccessBody.
  ///
  /// In en, this message translates to:
  /// **'Ask your manager'**
  String get hotelVisitsNoAccessBody;

  /// No description provided for @hotelVisitsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get hotelVisitsConfirm;

  /// No description provided for @hotelVisitsPropose.
  ///
  /// In en, this message translates to:
  /// **'Another time'**
  String get hotelVisitsPropose;

  /// No description provided for @hotelVisitsOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get hotelVisitsOpenChat;

  /// No description provided for @hotelVisitsComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get hotelVisitsComplete;

  /// No description provided for @hotelVisitsCorrectMissed.
  ///
  /// In en, this message translates to:
  /// **'Client arrived'**
  String get hotelVisitsCorrectMissed;

  /// No description provided for @hotelVisitsToastConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get hotelVisitsToastConfirmed;

  /// No description provided for @hotelVisitsToastProposed.
  ///
  /// In en, this message translates to:
  /// **'Proposal sent'**
  String get hotelVisitsToastProposed;

  /// No description provided for @hotelVisitsToastDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get hotelVisitsToastDeclined;

  /// No description provided for @hotelVisitsToastAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get hotelVisitsToastAssigned;

  /// No description provided for @hotelVisitsToastCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get hotelVisitsToastCompleted;

  /// No description provided for @hotelVisitsProposeTitle.
  ///
  /// In en, this message translates to:
  /// **'Another time'**
  String get hotelVisitsProposeTitle;

  /// No description provided for @hotelVisitsProposeDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get hotelVisitsProposeDay;

  /// No description provided for @hotelVisitsProposeTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get hotelVisitsProposeTime;

  /// No description provided for @hotelVisitsProposeCta.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get hotelVisitsProposeCta;

  /// No description provided for @hotelVisitsProposeNeed.
  ///
  /// In en, this message translates to:
  /// **'Pick day and time'**
  String get hotelVisitsProposeNeed;

  /// No description provided for @hotelVisitsDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get hotelVisitsDeclineTitle;

  /// No description provided for @hotelVisitsDeclineReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get hotelVisitsDeclineReason;

  /// No description provided for @hotelVisitsReasonUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get hotelVisitsReasonUnavailable;

  /// No description provided for @hotelVisitsReasonClosed.
  ///
  /// In en, this message translates to:
  /// **'Venue closed'**
  String get hotelVisitsReasonClosed;

  /// No description provided for @hotelVisitsReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get hotelVisitsReasonOther;

  /// No description provided for @hotelVisitsDeclineNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get hotelVisitsDeclineNote;

  /// No description provided for @hotelVisitsDeclineNoteRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get hotelVisitsDeclineNoteRequired;

  /// No description provided for @hotelVisitsDeclineNeed.
  ///
  /// In en, this message translates to:
  /// **'Pick a reason'**
  String get hotelVisitsDeclineNeed;

  /// No description provided for @hotelVisitsDeclineCta.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get hotelVisitsDeclineCta;

  /// No description provided for @hotelVisitsDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Visit · {when}'**
  String hotelVisitsDetailTitle(String when);

  /// No description provided for @hotelVisitsDetailErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Did not load'**
  String get hotelVisitsDetailErrorTitle;

  /// No description provided for @hotelVisitsSecClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get hotelVisitsSecClient;

  /// No description provided for @hotelVisitsSecVisit.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get hotelVisitsSecVisit;

  /// No description provided for @hotelVisitsFactRequested.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get hotelVisitsFactRequested;

  /// No description provided for @hotelVisitsFactProposed.
  ///
  /// In en, this message translates to:
  /// **'Proposed'**
  String get hotelVisitsFactProposed;

  /// No description provided for @hotelVisitsSecNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get hotelVisitsSecNote;

  /// No description provided for @hotelVisitsSecRep.
  ///
  /// In en, this message translates to:
  /// **'Representative'**
  String get hotelVisitsSecRep;

  /// No description provided for @hotelVisitsSecChat.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get hotelVisitsSecChat;

  /// No description provided for @hotelVisitsSecTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get hotelVisitsSecTimeline;

  /// No description provided for @hotelVisitsLimitedNote.
  ///
  /// In en, this message translates to:
  /// **'{name} only'**
  String hotelVisitsLimitedNote(String name);

  /// No description provided for @hotelVisitsNoteRequested.
  ///
  /// In en, this message translates to:
  /// **'Awaiting reply'**
  String get hotelVisitsNoteRequested;

  /// No description provided for @hotelVisitsNoteReschedule.
  ///
  /// In en, this message translates to:
  /// **'Proposed {when}'**
  String hotelVisitsNoteReschedule(String when);

  /// No description provided for @hotelVisitsNoteConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get hotelVisitsNoteConfirmed;

  /// No description provided for @hotelVisitsNoteDayOf.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String hotelVisitsNoteDayOf(String time);

  /// No description provided for @hotelVisitsNoteArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived {time}'**
  String hotelVisitsNoteArrived(String time);

  /// No description provided for @hotelVisitsNoteCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get hotelVisitsNoteCompleted;

  /// No description provided for @hotelVisitsNoteDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get hotelVisitsNoteDeclined;

  /// No description provided for @hotelVisitsNoteDeclinedReason.
  ///
  /// In en, this message translates to:
  /// **'Declined: {reason}'**
  String hotelVisitsNoteDeclinedReason(String reason);

  /// No description provided for @hotelVisitsNoteCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get hotelVisitsNoteCancelled;

  /// No description provided for @hotelVisitsNoteMissed.
  ///
  /// In en, this message translates to:
  /// **'No-show'**
  String get hotelVisitsNoteMissed;

  /// No description provided for @hotelVisitsTlRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get hotelVisitsTlRequested;

  /// No description provided for @hotelVisitsTlConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get hotelVisitsTlConfirmed;

  /// No description provided for @hotelVisitsTlReschedule.
  ///
  /// In en, this message translates to:
  /// **'Another time proposed'**
  String get hotelVisitsTlReschedule;

  /// No description provided for @hotelVisitsTlArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get hotelVisitsTlArrived;

  /// No description provided for @hotelVisitsTlCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get hotelVisitsTlCompleted;

  /// No description provided for @hotelVisitsTlDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get hotelVisitsTlDeclined;

  /// No description provided for @hotelVisitsTlCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get hotelVisitsTlCancelled;

  /// No description provided for @hotelVisitsTlMissed.
  ///
  /// In en, this message translates to:
  /// **'Did not arrive'**
  String get hotelVisitsTlMissed;

  /// No description provided for @hotelVisitsVisitors.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No visitors} one{{count} visitor} other{{count} visitors}}'**
  String hotelVisitsVisitors(int count);

  /// No description provided for @hotelVisitsProposeShort.
  ///
  /// In en, this message translates to:
  /// **'Another time'**
  String get hotelVisitsProposeShort;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppL10nAr();
    case 'en':
      return AppL10nEn();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
