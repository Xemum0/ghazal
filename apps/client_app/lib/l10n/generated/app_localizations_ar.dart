// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppL10nAr extends AppL10n {
  AppL10nAr([String locale = 'ar']) : super(locale);

  @override
  String get commonActionAccept => 'قبول';

  @override
  String get commonActionAdd => 'إضافة';

  @override
  String get commonActionApply => 'تطبيق';

  @override
  String get commonActionBack => 'رجوع';

  @override
  String get commonActionCall => 'اتصال';

  @override
  String get commonActionCancel => 'إلغاء';

  @override
  String get commonActionClear => 'مسح';

  @override
  String get commonActionClose => 'إغلاق';

  @override
  String get commonActionConfirm => 'تأكيد';

  @override
  String get commonActionContinue => 'متابعة';

  @override
  String get commonActionDecline => 'اعتذار';

  @override
  String get commonActionDone => 'تم';

  @override
  String get commonActionEdit => 'تعديل';

  @override
  String get commonActionMessage => 'مراسلة';

  @override
  String get commonActionNext => 'التالي';

  @override
  String get commonActionOpenWhatsapp => 'فتح واتساب';

  @override
  String get commonActionPrevious => 'السابق';

  @override
  String get commonActionRemove => 'إزالة';

  @override
  String get commonActionReschedule => 'تغيير الموعد';

  @override
  String get commonActionReset => 'إعادة الضبط';

  @override
  String get commonActionRetry => 'إعادة المحاولة';

  @override
  String get commonActionSave => 'حفظ';

  @override
  String get commonActionSearch => 'بحث';

  @override
  String get commonActionSeeAll => 'عرض الكل';

  @override
  String get commonActionSend => 'إرسال';

  @override
  String get commonActionShare => 'مشاركة';

  @override
  String get commonActionShowLess => 'عرض أقل';

  @override
  String get commonActionSkip => 'تخطي';

  @override
  String get commonActionUndo => 'تراجع';

  @override
  String get commonActionWhatsapp => 'واتساب';

  @override
  String get commonAvailabilityAvailable => 'متاح';

  @override
  String get commonAvailabilityBlocked => 'مغلق';

  @override
  String get commonAvailabilityBooked => 'محجوز';

  @override
  String get commonAvailabilityFree => 'متاح';

  @override
  String get commonAvailabilityHeld => 'محجوز مؤقتًا';

  @override
  String get commonAvailabilityPast => 'تاريخ سابق';

  @override
  String get commonAvailabilityUnavailable => 'غير متاح';

  @override
  String commonAvailabilityLineFree(String date) {
    return '$date · متاح';
  }

  @override
  String commonAvailabilityLineBooked(String date) {
    return '$date · محجوز';
  }

  @override
  String get commonCalendarAvailability => 'التوفر';

  @override
  String get commonCalendarPrices => 'الأسعار';

  @override
  String get commonCalendarToday => 'اليوم';

  @override
  String get commonCalendarSelected => 'محدد';

  @override
  String get commonCalendarPeak => 'أيام الذروة';

  @override
  String get commonCalendarPreviousMonth => 'الشهر السابق';

  @override
  String get commonCalendarNextMonth => 'الشهر التالي';

  @override
  String commonCalendarOccasionApproximate(String occasion) {
    return '$occasion (تقريبي)';
  }

  @override
  String get commonStatusRequested => 'بانتظار الرد';

  @override
  String get commonStatusAwaitingDeposit => 'تمت الموافقة · بانتظار العربون';

  @override
  String get commonStatusConfirmed => 'مؤكد';

  @override
  String get commonStatusRejected => 'لم يُقبل الطلب';

  @override
  String get commonStatusExpired => 'انتهت المهلة';

  @override
  String get commonStatusCancelled => 'ملغي';

  @override
  String get commonStatusCompleted => 'مكتمل';

  @override
  String get commonStatusRefunded => 'تم الاسترداد';

  @override
  String get commonStatusNoShow => 'عدم حضور';

  @override
  String get commonStatusHeadlineConfirmed => 'حجز مؤكد';

  @override
  String get commonStatusCancelledByYou => 'ملغي بطلب منكم';

  @override
  String get commonStatusCancelledByVenue => 'ملغي من القاعة';

  @override
  String get commonStatusHotelMissed => 'انتهت المهلة';

  @override
  String get commonStatusUrgent => 'عاجل';

  @override
  String commonStatusTimeLeft(String time) {
    return 'باقي $time';
  }

  @override
  String get commonFilterAll => 'الكل';

  @override
  String get commonTierWeekday => 'أيام الأسبوع';

  @override
  String get commonTierWeekend => 'نهاية الأسبوع';

  @override
  String get commonTierHoliday => 'عطلة';

  @override
  String get commonTierSeason => 'موسم';

  @override
  String get commonTierSpecialDate => 'تاريخ مميز';

  @override
  String get commonUnitPerGuest => 'للضيف';

  @override
  String get commonUnitPerNight => 'لليلة';

  @override
  String get commonUnitPerDay => 'لليوم';

  @override
  String get commonUnitPerHour => 'للساعة';

  @override
  String commonUnitMinGuests(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ ضيف',
      many: '⁦$countString⁩ ضيفًا',
      few: '⁦$countString⁩ ضيوف',
      two: 'ضيفان',
      one: 'ضيف واحد',
      zero: 'لا ضيوف',
    );
    return 'الحد الأدنى $_temp0';
  }

  @override
  String commonUnitUpToGuests(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ ضيف',
      many: '⁦$countString⁩ ضيفًا',
      few: '⁦$countString⁩ ضيوف',
      two: 'ضيفين',
      one: 'ضيف واحد',
      zero: 'لا ضيوف',
    );
    return 'حتى $_temp0';
  }

  @override
  String commonCountGuests(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ ضيف',
      many: '⁦$countString⁩ ضيفًا',
      few: '⁦$countString⁩ ضيوف',
      two: 'ضيفان',
      one: 'ضيف واحد',
      zero: 'لا ضيوف',
    );
    return '$_temp0';
  }

  @override
  String commonCountDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ يوم',
      many: '⁦$countString⁩ يومًا',
      few: '⁦$countString⁩ أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: 'لا أيام',
    );
    return '$_temp0';
  }

  @override
  String commonCountHours(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ ساعة',
      many: '⁦$countString⁩ ساعة',
      few: '⁦$countString⁩ ساعات',
      two: 'ساعتان',
      one: 'ساعة واحدة',
      zero: 'لا ساعات',
    );
    return '$_temp0';
  }

  @override
  String commonCountMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ دقيقة',
      many: '⁦$countString⁩ دقيقة',
      few: '⁦$countString⁩ دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
      zero: 'لا دقائق',
    );
    return '$_temp0';
  }

  @override
  String commonCountHalls(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ قاعة',
      many: '⁦$countString⁩ قاعة',
      few: '⁦$countString⁩ قاعات',
      two: 'قاعتان',
      one: 'قاعة واحدة',
      zero: 'لا قاعات',
    );
    return '$_temp0';
  }

  @override
  String commonCountPackages(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ باقة',
      many: '⁦$countString⁩ باقة',
      few: '⁦$countString⁩ باقات',
      two: 'باقتان',
      one: 'باقة واحدة',
      zero: 'لا باقات',
    );
    return '$_temp0';
  }

  @override
  String commonCountMessages(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ رسالة',
      many: '⁦$countString⁩ رسالة',
      few: '⁦$countString⁩ رسائل',
      two: 'رسالتان',
      one: 'رسالة واحدة',
      zero: 'لا رسائل',
    );
    return '$_temp0';
  }

  @override
  String commonCountBookings(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ حجز',
      many: '⁦$countString⁩ حجزًا',
      few: '⁦$countString⁩ حجوزات',
      two: 'حجزان',
      one: 'حجز واحد',
      zero: 'لا حجوزات',
    );
    return '$_temp0';
  }

  @override
  String commonCountSessions(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ فترة',
      many: '⁦$countString⁩ فترة',
      few: '⁦$countString⁩ فترات',
      two: 'فترتان',
      one: 'فترة واحدة',
      zero: 'لا فترات',
    );
    return '$_temp0';
  }

  @override
  String commonCountMonths(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ شهر',
      many: '⁦$countString⁩ شهرًا',
      few: '⁦$countString⁩ أشهر',
      two: 'شهران',
      one: 'شهر واحد',
      zero: 'لا أشهر',
    );
    return '$_temp0';
  }

  @override
  String commonCountDates(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ تاريخ',
      many: '⁦$countString⁩ تاريخًا',
      few: '⁦$countString⁩ تواريخ',
      two: 'تاريخان',
      one: 'تاريخ واحد',
      zero: 'لا تواريخ',
    );
    return '$_temp0';
  }

  @override
  String commonCountRequests(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ طلب',
      many: '⁦$countString⁩ طلبًا',
      few: '⁦$countString⁩ طلبات',
      two: 'طلبان',
      one: 'طلب واحد',
      zero: 'لا طلبات',
    );
    return '$_temp0';
  }

  @override
  String commonCountReviews(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ تقييم',
      many: '⁦$countString⁩ تقييمًا',
      few: '⁦$countString⁩ تقييمات',
      two: 'تقييمان',
      one: 'تقييم واحد',
      zero: 'لا تقييمات',
    );
    return '$_temp0';
  }

  @override
  String commonCountPhotos(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ صورة',
      many: '⁦$countString⁩ صورة',
      few: '⁦$countString⁩ صور',
      two: 'صورتان',
      one: 'صورة واحدة',
      zero: 'لا صور',
    );
    return '$_temp0';
  }

  @override
  String commonCountdownDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'باقي ⁦$countString⁩ يوم',
      many: 'باقي ⁦$countString⁩ يومًا',
      few: 'باقي ⁦$countString⁩ أيام',
      two: 'باقي يومان',
      one: 'باقي يوم واحد',
      zero: 'اليوم',
    );
    return '$_temp0';
  }

  @override
  String commonCounter(num current, num total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '⁦$currentString⁩ من ⁦$totalString⁩';
  }

  @override
  String get commonStateLoading => 'جارٍ التحميل';

  @override
  String get commonStateTitleGeneric => 'حدث خطأ ما';

  @override
  String get commonStateTitleLoad => 'تعذّر التحميل';

  @override
  String get commonStateTitleNetwork => 'لا يوجد اتصال';

  @override
  String get commonStateTitlePayment => 'تعذّر الدفع';

  @override
  String get commonStateTitleNoAccess => 'لا صلاحية';

  @override
  String get commonStateTitleNotFound => 'غير موجود';

  @override
  String get commonStateTitleEmptySearch => 'لا نتائج';

  @override
  String get commonStateTitleEmpty => 'لا شيء هنا';

  @override
  String get commonStateOffline => 'لا يوجد اتصال';

  @override
  String get commonStateErrorGeneric =>
      'حدث خطأ من جانبنا. لم يتم تغيير أي شيء. يُرجى المحاولة مرة أخرى.';

  @override
  String get commonStateErrorLoad =>
      'تعذّر تحميل المحتوى. يُرجى المحاولة مرة أخرى.';

  @override
  String get commonStateErrorNetwork =>
      'تعذّر الاتصال. يُرجى التأكد من الاتصال بالإنترنت والمحاولة مرة أخرى.';

  @override
  String get commonStateErrorPayment => 'تعذّر إتمام الدفع. لم يُخصم أي مبلغ.';

  @override
  String get commonStateErrorNoAccess =>
      'لا تملكون صلاحية الوصول. يُرجى مراجعة المدير.';

  @override
  String get commonStateErrorNotFound => 'هذه الصفحة لم تعد متاحة.';

  @override
  String get commonStateSaved => 'تم الحفظ';

  @override
  String get commonStateCopied => 'تم النسخ';

  @override
  String get commonStateSent => 'تم الإرسال';

  @override
  String get commonNoPaymentNowFull =>
      'لا دفع الآن. لا يُخصم أي مبلغ قبل موافقة الفندق.';

  @override
  String get commonMoneyDeposit => 'العربون';

  @override
  String get commonMoneyBalance => 'المبلغ المتبقي';

  @override
  String get commonMoneyTotal => 'الإجمالي';

  @override
  String get commonMoneyServiceCharge => 'رسوم الخدمة';

  @override
  String get commonMoneyRentalFee => 'رسوم الإيجار';

  @override
  String get commonLabelOptional => 'اختياري';

  @override
  String get commonLabelRequired => 'مطلوب';

  @override
  String get commonLabelNotDecided => 'لم يتحدد';

  @override
  String get commonLabelToday => 'اليوم';

  @override
  String get commonLabelTomorrow => 'غدًا';

  @override
  String get commonLabelKuwaitTime => 'بتوقيت الكويت';

  @override
  String get commonLabelSponsored => 'إعلان';

  @override
  String get commonLabelNew => 'جديد';

  @override
  String get commonLabelOr => 'أو';

  @override
  String get commonLabelLanguage => 'اللغة';

  @override
  String get commonLabelSettings => 'الإعدادات';

  @override
  String get commonLanguageEnglish => 'الإنجليزية';

  @override
  String get commonLanguageArabic => 'العربية';

  @override
  String get commonFieldRequired => 'هذا الحقل مطلوب.';

  @override
  String get commonFieldInvalid => 'القيمة المدخلة غير صالحة.';

  @override
  String get commonFieldPhoneInvalid => 'رقم الهاتف غير صالح.';

  @override
  String get commonA11yFavouriteAdd => 'حفظ في المفضلة';

  @override
  String get commonA11yFavouriteRemove => 'إزالة من المفضلة';

  @override
  String get commonA11yCompareAdd => 'إضافة إلى المقارنة';

  @override
  String get commonA11yCompareRemove => 'إزالة من المقارنة';

  @override
  String commonA11yPhotoCounter(num current, num total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'صورة ⁦$currentString⁩ من ⁦$totalString⁩';
  }

  @override
  String commonA11yRating(num rating, num max) {
    final intl.NumberFormat ratingNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String ratingString = ratingNumberFormat.format(rating);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'التقييم ⁦$ratingString⁩ من ⁦$maxString⁩';
  }

  @override
  String get commonA11ySelected => 'محدد';

  @override
  String get commonStatusPending => 'بانتظار الرد';

  @override
  String get commonStatusApproved => 'تمت الموافقة';

  @override
  String get commonStatusRedeemed => 'تم الاستخدام';

  @override
  String get commonStatusDeclined => 'لم يُقبل';

  @override
  String get commonStatusHotelPending => 'بانتظار الرد';

  @override
  String get commonStatusHotelApproved => 'بانتظار العميل';

  @override
  String get commonStatusHotelRedeemed => 'تم الاستخدام';

  @override
  String get commonStatusHotelDeclined => 'تم الاعتذار';

  @override
  String get commonStatusHotelLapsed => 'انتهت المهلة';

  @override
  String get commonStatusDateProposed => 'موعد جديد';

  @override
  String get commonVoucherStatusUnpaid => 'قيد الدفع';

  @override
  String get commonVoucherStatusActive => 'جاهز';

  @override
  String get commonVoucherStatusBound => 'مرتبط بطلب';

  @override
  String get commonVoucherStatusUsed => 'تم الاستخدام';

  @override
  String get commonVoucherStatusExpired => 'منتهي الصلاحية';

  @override
  String get commonVisitStatusRequested => 'طلب زيارة';

  @override
  String get commonVisitStatusConfirmed => 'مؤكدة';

  @override
  String get commonVisitStatusReschedule => 'وقت جديد';

  @override
  String get commonVisitStatusArrived => 'تم الوصول';

  @override
  String get commonVisitStatusCompleted => 'تمت';

  @override
  String get commonVisitStatusDeclined => 'غير متاح';

  @override
  String get commonVisitStatusCancelled => 'ملغية';

  @override
  String get commonVisitStatusMissed => 'لم تتم';

  @override
  String get commonListingStatusDraft => 'مسودة';

  @override
  String get commonListingStatusPayment => 'غير مدفوع';

  @override
  String get commonListingStatusReview => 'قيد المراجعة';

  @override
  String get commonListingStatusApproved => 'تمت الموافقة';

  @override
  String get commonListingStatusRejected => 'لم تُعتمد';

  @override
  String get commonListingStatusActive => 'منشور';

  @override
  String get commonListingStatusExpired => 'انتهت المدة';

  @override
  String get commonListingStatusPaused => 'متوقف مؤقتًا';

  @override
  String get commonVoucher => 'كوبون';

  @override
  String get commonVoucherPrice => 'سعر الكوبون';

  @override
  String get commonStandardPrice => 'السعر العادي';

  @override
  String commonYouSave(String amount) {
    return 'توفّرون $amount';
  }

  @override
  String commonSaveAmount(String amount) {
    return 'وفّروا $amount';
  }

  @override
  String get commonConfirmBooking => 'تأكيد الحجز';

  @override
  String get commonRedeemVoucher => 'استخدام الكوبون';

  @override
  String get commonVoucherCode => 'رمز الكوبون';

  @override
  String commonValidUntil(String date) {
    return 'صالح حتى $date';
  }

  @override
  String get commonLabelGuestVoucher => 'سعر الكوبون بعد التسجيل';

  @override
  String get commonRoleClient => 'العميل';

  @override
  String get commonRoleYou => 'أنتم';

  @override
  String get commonRoleHotelRep => 'ممثل الفندق';

  @override
  String get commonRoleSupport => 'دعم غزل';

  @override
  String get commonVenueTypePrivateHall => 'قاعة خاصة';

  @override
  String get commonVenueTypeGovernmental => 'منشأة حكومية';

  @override
  String get commonVenueTypeHotel => 'فندق';

  @override
  String get commonPricingPerPerson => 'سعر للضيف';

  @override
  String get commonPricingPackages => 'باقات';

  @override
  String get commonPricingPackage => 'باقة';

  @override
  String get commonPricingStructure => 'طريقة التسعير';

  @override
  String get commonFilterGovernorate => 'المحافظة';

  @override
  String get commonFilterVenueType => 'نوع المكان';

  @override
  String get commonFilterCapacity => 'السعة';

  @override
  String get commonPlanWeekly => 'أسبوعي';

  @override
  String get commonPlanMonthly => 'شهري';

  @override
  String get commonPlanAnnual => 'سنوي';

  @override
  String get commonRatesSoon => 'الأسعار تُعلن قريبًا';

  @override
  String get commonExempt => 'معفى';

  @override
  String get commonMajorHotel => 'فندق كبير';

  @override
  String get commonA11yInfo => 'معلومات إضافية';

  @override
  String get commonLabelDetails => 'التفاصيل';

  @override
  String get commonVoucherStatusForfeited => 'غير صالح';

  @override
  String get commonVoucherStatusCredit => 'رصيد';

  @override
  String get commonVoucherStatusCreditIssued => 'تم إصدار رصيد';

  @override
  String get commonVoucherCredit => 'كوبون رصيد';

  @override
  String get commonVoucherAnyVenue => 'أي قاعة أو فندق أو خدمة';

  @override
  String commonVoucherNotValidNote(int hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '⁦$hoursString⁩ ساعة',
      many: '⁦$hoursString⁩ ساعة',
      few: '⁦$hoursString⁩ ساعات',
      two: 'ساعتين',
      one: 'ساعة',
      zero: 'لا ساعات',
    );
    return 'لم يُؤكَّد خلال $_temp0';
  }

  @override
  String commonVoucherConfirmIn24h(int hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '⁦$hoursString⁩ ساعة',
      many: '⁦$hoursString⁩ ساعة',
      few: '⁦$hoursString⁩ ساعات',
      two: 'ساعتين',
      one: 'ساعة',
      zero: 'لا ساعات',
    );
    return 'أكدوا لدى الفندق أو الخدمة خلال $_temp0، وإلا أصبح الكوبون غير صالح';
  }

  @override
  String get commonAskSupport => 'اسألوا الدعم';

  @override
  String get commonCreditRequested => 'تم إرسال الطلب إلى الدعم';

  @override
  String get commonBillingContract => 'عقد عمل';

  @override
  String get commonBillingPlan => 'باقة';

  @override
  String get commonBillingContractTerms => 'بالشروط المتفق عليها';

  @override
  String get commonStaffInvitedByEmail => 'دعوة بالبريد';

  @override
  String get commonCalendarByEmail => 'التقويم بالبريد الإلكتروني';

  @override
  String get commonReviewAskSupportHide =>
      'اطلبوا من الدعم إخفاء المراجعة أو حذفها';

  @override
  String commonVideoLimit(String size) {
    return 'حتى $size ميغابايت للفيديو الواحد';
  }

  @override
  String get clientAuthSharedNotNow => 'ليس الآن';

  @override
  String get clientAuthSharedSupport => 'الدعم';

  @override
  String get clientAuthSharedApple => 'آبل';

  @override
  String get clientAuthSharedGoogle => 'جوجل';

  @override
  String get clientAuthSharedUsePassword => 'كلمة المرور';

  @override
  String get clientAuthSharedUseCode => 'رمز واتساب';

  @override
  String get clientAuthSharedSignIn => 'تسجيل الدخول';

  @override
  String get clientAuthSharedCreateAccount => 'إنشاء حساب';

  @override
  String get clientAuthSharedSignedIn => 'تم الدخول';

  @override
  String get clientAuthSharedAccountReady => 'الحساب جاهز';

  @override
  String get clientAuthSharedPhone => 'الجوال';

  @override
  String get clientAuthSharedSendCode => 'إرسال الرمز';

  @override
  String get clientAuthSharedDate => 'التاريخ';

  @override
  String get clientAuthSharedGuests => 'الضيوف';

  @override
  String get clientAuthSharedLegalTerms => 'شروط الاستخدام';

  @override
  String get clientAuthSharedLegalPrivacy => 'سياسة الخصوصية';

  @override
  String get clientAuthSharedLegalNote => 'النص الكامل قبل الإطلاق';

  @override
  String get clientAuthSharedTermsSection1 => 'استخدام غزل';

  @override
  String get clientAuthSharedTermsSection2 => 'الكوبون';

  @override
  String get clientAuthSharedTermsSection3 => 'الدفع للقاعة';

  @override
  String get clientAuthSharedTermsSection4 => 'مسؤولياتكم';

  @override
  String get clientAuthSharedPrivacySection1 => 'ما نجمعه من بيانات';

  @override
  String get clientAuthSharedPrivacySection2 => 'كيف نستخدمها';

  @override
  String get clientAuthSharedPrivacySection3 => 'من يطّلع عليها';

  @override
  String get clientAuthSharedPrivacySection4 => 'خياراتكم';

  @override
  String get clientAuthSharedInfoTitle => 'حسابكم';

  @override
  String get clientAuthSharedPartnerNote =>
      'فندق أو مقدم خدمة؟ استخدموا تطبيق غزل للشركاء.';

  @override
  String get clientAuthSharedSmallPrint =>
      'تسري <terms>شروط الاستخدام</terms> و<privacy>سياسة الخصوصية</privacy> عليكم، وتؤكدون موافقتكم عليهما عند إنشاء الحساب.';

  @override
  String get clientAuthReasonSendRequest => 'إرسال الطلب';

  @override
  String get clientAuthReasonVoucher => 'كوبون';

  @override
  String get clientAuthReasonVisit => 'زيارة';

  @override
  String get clientAuthReasonChat => 'رسالة';

  @override
  String get clientAuthReasonReview => 'تقييم';

  @override
  String get clientAuthReasonPlanner => 'استشارة';

  @override
  String get clientAuthReasonQuote => 'عرض سعر';

  @override
  String get clientAuthReasonSave => 'المفضلة';

  @override
  String clientAuthGateErrorDigits(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ رقم',
      many: '⁦$countString⁩ رقمًا',
      few: '⁦$countString⁩ أرقام',
      two: 'رقمان',
      one: 'رقم واحد',
      zero: 'لا أرقام',
    );
    return 'يلزم $_temp0';
  }

  @override
  String get clientAuthGateErrorNotOnWhatsapp => 'ليس على واتساب';

  @override
  String get clientAuthGateNotOnWhatsappDetail =>
      'تعذّر إرسال رمز إلى هذا الرقم عبر واتساب. يمكنكم المتابعة عبر آبل أو جوجل، أو التواصل مع الدعم.';

  @override
  String get clientAuthOtpTitle => 'رمز واتساب';

  @override
  String get clientAuthOtpSheetTitle => 'تأكيد الرقم';

  @override
  String get clientAuthOtpLabel => 'الرمز';

  @override
  String get clientAuthOtpVerify => 'تأكيد';

  @override
  String get clientAuthOtpWrong => 'رمز خاطئ';

  @override
  String clientAuthOtpAttemptsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقيت ⁦$countString⁩ محاولة',
      many: 'بقيت ⁦$countString⁩ محاولة',
      few: 'بقيت ⁦$countString⁩ محاولات',
      two: 'بقيت محاولتان',
      one: 'بقيت محاولة واحدة',
      zero: 'لا محاولات متبقية',
    );
    return '$_temp0';
  }

  @override
  String get clientAuthOtpExpired => 'انتهى الرمز';

  @override
  String get clientAuthOtpResent => 'تم الإرسال';

  @override
  String clientAuthOtpResendIn(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'إعادة إرسال الرمز بعد ⁦$countString⁩ ثانية',
      many: 'إعادة إرسال الرمز بعد ⁦$countString⁩ ثانية',
      few: 'إعادة إرسال الرمز بعد ⁦$countString⁩ ثوانٍ',
      two: 'إعادة إرسال الرمز بعد ثانيتين',
      one: 'إعادة إرسال الرمز بعد ثانية واحدة',
      zero: 'إعادة إرسال الرمز الآن',
    );
    return '$_temp0';
  }

  @override
  String clientAuthOtpTimer(String count) {
    return '$count ث';
  }

  @override
  String get clientAuthOtpResend => 'إعادة الإرسال';

  @override
  String get clientAuthOtpChange => 'تغيير';

  @override
  String get clientAuthOtpChangeNumber => 'تغيير الرقم';

  @override
  String get clientAuthOtpLocked => 'محاولات كثيرة';

  @override
  String get clientAuthOtpLockedDetail =>
      'يمكنكم المحاولة لاحقًا أو التواصل مع الدعم.';

  @override
  String get clientAuthOtpDeliveryFailed => 'لم يصل الرمز';

  @override
  String get clientAuthOtpDeliveryFailedDetail =>
      'لم يصل الرمز إلى واتساب. يمكنكم إعادة الإرسال أو المتابعة بطريقة أخرى.';

  @override
  String get clientAuthOtpSendAgain => 'إرسال مجددًا';

  @override
  String get clientAuthOtpSuccessTitle => 'تم التأكيد';

  @override
  String get clientAuthOtpOpening => 'جارٍ فتح واتساب';

  @override
  String get clientAuthNameTitle => 'إنشاء حساب';

  @override
  String get clientAuthNameLabel => 'الاسم';

  @override
  String get clientAuthNamePlaceholder => 'الاسم الكامل';

  @override
  String get clientAuthNameEmailLabel => 'البريد الإلكتروني';

  @override
  String get clientAuthNameAccept => 'أوافق';

  @override
  String get clientAuthNameLegalTitle => 'الشروط والخصوصية';

  @override
  String get clientAuthNameKept => 'محفوظ في حسابكم';

  @override
  String get clientAuthNameMonogram => 'حرف اسمكم';

  @override
  String get clientAuthPwdForgotTitle => 'استعادة الدخول';

  @override
  String get clientAuthPwdResetTitle => 'كلمة مرور جديدة';

  @override
  String get clientAuthPwdPassword => 'كلمة المرور';

  @override
  String get clientAuthPwdShow => 'إظهار كلمة المرور';

  @override
  String get clientAuthPwdHide => 'إخفاء كلمة المرور';

  @override
  String get clientAuthPwdForgot => 'نسيتم؟';

  @override
  String get clientAuthPwdForgotLabel => 'نسيتم كلمة المرور';

  @override
  String get clientAuthPwdEnterCode => 'إدخال الرمز';

  @override
  String get clientAuthPwdVerified => 'تم تأكيد الرقم عبر واتساب';

  @override
  String clientAuthPwdStrength(String level) {
    return 'قوة كلمة المرور: $level';
  }

  @override
  String get clientAuthPwdStrengthWeak => 'ضعيفة';

  @override
  String get clientAuthPwdStrengthFair => 'مقبولة';

  @override
  String get clientAuthPwdStrengthStrong => 'قوية';

  @override
  String clientAuthPwdRuleLength(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ حرف على الأقل',
      many: '⁦$countString⁩ حرفًا على الأقل',
      few: '⁦$countString⁩ أحرف على الأقل',
      two: 'حرفان على الأقل',
      one: 'حرف واحد على الأقل',
      zero: 'لا أحرف',
    );
    return '$_temp0';
  }

  @override
  String get clientAuthPwdRuleMix => 'حرف ورقم';

  @override
  String get clientAuthPwdRulePhone => 'ليست رقم جوالكم';

  @override
  String get clientAuthPwdRuleMet => 'تم';

  @override
  String get clientAuthPwdRuleOpen => 'لم يتحقق بعد';

  @override
  String get clientAuthPwdInvalid => 'البيانات غير صحيحة';

  @override
  String get clientAuthPwdLocked => 'متوقف مؤقتًا';

  @override
  String get clientAuthPwdUpdatedTitle => 'تم التحديث';

  @override
  String get clientAuthBioTitle => 'الفتح بالبصمة أو الوجه';

  @override
  String clientAuthBioMethod(String method) {
    String _temp0 = intl.Intl.selectLogic(method, {
      'face': 'بصمة الوجه',
      'touch': 'بصمة الإصبع',
      'other': 'بصمة الإصبع',
    });
    return '$_temp0';
  }

  @override
  String clientAuthBioPromptDetail(String method) {
    String _temp0 = intl.Intl.selectLogic(method, {
      'face': 'بصمة الوجه',
      'touch': 'بصمة الإصبع',
      'other': 'بصمة الإصبع',
    });
    return 'تقتصر $_temp0 على فتح تسجيل الدخول المحفوظ على هذا الهاتف، ولا تغني عن أول تسجيل دخول.';
  }

  @override
  String get clientAuthBioTurnOn => 'تفعيل';

  @override
  String get clientAuthBioUnlock => 'فتح';

  @override
  String get clientAuthBioFailedTitle => 'غير مطابق';

  @override
  String get clientAuthBioFailedDetail =>
      'يمكنكم المحاولة مرة أخرى أو الدخول بطريقة أخرى. حسابكم غير مغلق.';

  @override
  String get clientAuthBioUnavailableRow => 'الفتح بالبصمة';

  @override
  String get clientAuthBioUnavailableDetail =>
      'يلزم إضافة بصمة الوجه أو الإصبع من إعدادات الهاتف لتفعيل هذه الميزة. تفتح البصمة تسجيل الدخول المحفوظ على هذا الهاتف فقط.';

  @override
  String get clientAuthBioEnabledTitle => 'تم التفعيل';

  @override
  String clientBookingStepOf(String step, String total) {
    return 'الخطوة $step من $total';
  }

  @override
  String get clientBookingStepsLabel => 'مراحل الطلب';

  @override
  String get clientBookingLeaveTitle => 'مغادرة الطلب؟';

  @override
  String get clientBookingLeaveBody => 'المسودة محفوظة.';

  @override
  String get clientBookingLeaveConfirm => 'مغادرة';

  @override
  String get clientBookingLeaveKeep => 'متابعة التعديل';

  @override
  String get clientBookingEstimateLabel => 'تقريبي';

  @override
  String get clientBookingOfflineBanner => 'دون اتصال. المسودة محفوظة.';

  @override
  String get clientBookingPriceErrorBanner => 'تعذّر تحديث السعر';

  @override
  String get clientBookingPriceTitle => 'السعر';

  @override
  String get clientBookingVoucherTotalLabel => 'سعر الكوبون';

  @override
  String get clientBookingVoucherEstimateLabel => 'سعر الكوبون (تقريبي)';

  @override
  String clientBookingYouSaveNet(String amount) {
    return 'توفّرون $amount بعد رسوم الكوبون';
  }

  @override
  String get clientBookingReplyWithin => 'ترد القاعة خلال';

  @override
  String get clientBookingReplyFast => 'يُطلب من القاعة الرد خلال';

  @override
  String get clientBookingEventTitle => 'مناسبتكم';

  @override
  String get clientBookingDateChange => 'تغيير التاريخ';

  @override
  String get clientBookingDateTakenAction => 'تواريخ متاحة';

  @override
  String clientBookingDateTakenBanner(String date) {
    return '$date غير متاح';
  }

  @override
  String get clientBookingDateTakenReason => 'اختاروا تاريخًا آخر';

  @override
  String get clientBookingHostingLabel => 'الحفل';

  @override
  String get clientBookingHostingWomen => 'الحفل النسائي';

  @override
  String get clientBookingHostingMen => 'الحفل الرجالي';

  @override
  String get clientBookingHostingMixed => 'الحفل المختلط';

  @override
  String get clientBookingHostingWomenShort => 'نسائي';

  @override
  String get clientBookingHostingMenShort => 'رجالي';

  @override
  String get clientBookingHostingMixedShort => 'مختلط';

  @override
  String get clientBookingHallLabel => 'القاعة';

  @override
  String get clientBookingSessionLabel => 'الفترة';

  @override
  String get clientBookingGuestsLabel => 'الضيوف';

  @override
  String get clientBookingGuestsPresets => 'أعداد شائعة';

  @override
  String get clientBookingOccasionLabel => 'المناسبة';

  @override
  String get clientBookingOccasionWedding => 'زفاف';

  @override
  String get clientBookingOccasionMilka => 'ملكة';

  @override
  String get clientBookingOccasionHenna => 'حنّة';

  @override
  String get clientBookingOccasionEngagement => 'خطوبة';

  @override
  String get clientBookingOccasionOther => 'أخرى';

  @override
  String get clientBookingNeedVoucherTitle => 'الكوبون أولًا';

  @override
  String get clientBookingNeedVoucherInfoTitle => 'الكوبون';

  @override
  String get clientBookingNeedVoucherBody =>
      'لا يُرسل الطلب بدون كوبون. الكوبون يمنحكم سعر الكوبون ويصل إلى القاعة مع طلبكم.';

  @override
  String get clientBookingHostingOneVoucher =>
      'الكوبون الواحد يغطي حفلًا واحدًا. الحفل الثاني طلب مستقل بكوبون خاص به.';

  @override
  String clientBookingNeedVoucherAction(String fee) {
    return 'شراء الكوبون $fee';
  }

  @override
  String get clientBookingFromVoucher => 'من كوبونكم';

  @override
  String get clientBookingFromVoucherChange => 'تغيير';

  @override
  String get clientBookingFromVoucherChangeAria => 'تغيير ما يرتبط به الكوبون';

  @override
  String get clientBookingPackageTitle => 'الباقة';

  @override
  String get clientBookingPackageSelected => 'محددة';

  @override
  String get clientBookingPackageIncludes => 'تشمل';

  @override
  String get clientBookingPackageDetails => 'التفاصيل';

  @override
  String get clientBookingPackageFlat => 'سعر الباقة';

  @override
  String get clientBookingPackageNoVoucher => 'بلا كوبون';

  @override
  String get clientBookingPackageChangeVoucher => 'يفتح الكوبون لهذا العرض';

  @override
  String get clientBookingPackageNotCoveredToast => 'لا يشمله الكوبون';

  @override
  String get clientBookingPackageNoneTitle => 'لا باقة مناسبة';

  @override
  String clientBookingPackageNoneBody(String guests) {
    return 'لا توجد باقة تناسب $guests في هذه القاعة. يمكنكم تعديل العدد أو اختيار قاعة أخرى.';
  }

  @override
  String get clientBookingPackageNoneInfoTitle => 'الباقات';

  @override
  String get clientBookingPackageNoneAction => 'تغيير العدد';

  @override
  String get clientBookingPackageMissingReason => 'اختاروا باقة';

  @override
  String get clientBookingPackageBreakdownOpen => 'عرض تفاصيل السعر';

  @override
  String get clientBookingExtrasTitle => 'الإضافات';

  @override
  String get clientBookingExtrasInfoTitle => 'الإضافات';

  @override
  String get clientBookingExtrasIncluded => 'مشمولة';

  @override
  String get clientBookingExtrasNone => 'بدون إضافات';

  @override
  String get clientBookingExtrasNoneOffered =>
      'لا تقدّم هذه القاعة إضافات لحجزكم. يمكنكم المتابعة.';

  @override
  String get clientBookingExtrasLead =>
      'اختيارية وتُحتسب بشكل منفصل، بسعر الكوبون حيثما توفّر لدى القاعة.';

  @override
  String get clientBookingExtrasSettledNote =>
      'الإضافات تُسدَّد للقاعة مباشرةً.';

  @override
  String get clientBookingDetailsTitle => 'بياناتكم';

  @override
  String get clientBookingNameLabel => 'الاسم';

  @override
  String get clientBookingNameError => 'أضيفوا الاسم';

  @override
  String get clientBookingPhoneLabel => 'الجوال';

  @override
  String get clientBookingPhoneVerified => 'موثّق';

  @override
  String get clientBookingPhoneVerify => 'توثيق';

  @override
  String clientBookingPhoneDigits(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ رقم',
      many: '⁦$countString⁩ رقمًا',
      few: '⁦$countString⁩ أرقام',
      two: 'رقمان',
      one: 'رقم واحد',
      zero: 'لا أرقام',
    );
    return 'يلزم $_temp0';
  }

  @override
  String get clientBookingEmailLabel => 'البريد';

  @override
  String get clientBookingForLabel => 'الحجز لصالح';

  @override
  String get clientBookingForSelf => 'لي';

  @override
  String get clientBookingForOther => 'لغيري';

  @override
  String get clientBookingForNameLabel => 'اسم الشخص';

  @override
  String get clientBookingForRelationLabel => 'الصلة';

  @override
  String get clientBookingRelationBride => 'العروس';

  @override
  String get clientBookingRelationGroom => 'العريس';

  @override
  String get clientBookingRelationFamily => 'العائلة';

  @override
  String get clientBookingRelationPlanner => 'المنسّق';

  @override
  String get clientBookingRequestsLabel => 'طلبات';

  @override
  String get clientBookingRequestsSuggestions => 'طلبات شائعة';

  @override
  String get clientBookingSuggestPhotographer => 'مصوّرة فقط';

  @override
  String clientBookingSuggestKosha(String time) {
    return 'دخول فريق الكوشة من $time';
  }

  @override
  String get clientBookingSuggestWheelchair => 'مدخل مهيّأ للكراسي المتحركة';

  @override
  String get clientBookingSuggestPhotographerShort => 'مصوّرة';

  @override
  String get clientBookingSuggestKoshaShort => 'الكوشة';

  @override
  String get clientBookingSuggestWheelchairShort => 'كرسي متحرك';

  @override
  String get clientBookingPrivacyWord => 'الخصوصية';

  @override
  String clientBookingPrivacy(String venue) {
    return 'يظهر اسمكم ورقم هاتفكم لدى $venue لهذا الطلب فقط، ويظهر رمز كوبونكم لها عند الاستخدام فقط.';
  }

  @override
  String get clientBookingReviewTitle => 'المراجعة';

  @override
  String get clientBookingReviewExtras => 'الإضافات';

  @override
  String get clientBookingReviewContact => 'جهة الاتصال';

  @override
  String get clientBookingReviewPackage => 'الباقة';

  @override
  String get clientBookingReviewPriceNote =>
      'السعر شامل ويُثبَّت عند الإرسال. لا مبلغ إضافي لغزل، وبعد التأكيد تدفعون للقاعة مباشرةً.';

  @override
  String get clientBookingNextTitle => 'ما يحدث بعد ذلك';

  @override
  String get clientBookingNextSend => 'إرسال';

  @override
  String get clientBookingNextReply => 'الرد';

  @override
  String get clientBookingNextConfirm => 'التأكيد';

  @override
  String get clientBookingNextVenue => 'الاستخدام';

  @override
  String get clientBookingNextReplyNote => 'الرد المتوقع قبل';

  @override
  String get clientBookingNextConfirmNote => 'مهلة التأكيد بعد الموافقة';

  @override
  String clientBookingNextVenueNote(String venue) {
    return 'تدفعون إلى $venue مباشرةً وتعرضون رمز الكوبون.';
  }

  @override
  String get clientBookingConsent => 'أوافق';

  @override
  String get clientBookingConsentTitle => 'الشروط';

  @override
  String get clientBookingConsentBody =>
      'أوافق على شروط القاعة وشروط الكوبون وشروط المنصة.';

  @override
  String get clientBookingConsentRead => 'قراءة الشروط';

  @override
  String get clientBookingSend => 'إرسال الطلب';

  @override
  String get clientBookingSendFailed => 'لم يُرسل. حاولوا مجددًا.';

  @override
  String get clientBookingReasonConsent => 'وافقوا للإرسال';

  @override
  String get clientBookingReasonLimit => 'الطلبات مكتملة';

  @override
  String get clientBookingReasonVoucher => 'الكوبون مطلوب';

  @override
  String get clientBookingReasonPhone => 'وثّقوا الجوال';

  @override
  String clientBookingLimitBanner(String count, String max) {
    return '$count من $max مفتوحة';
  }

  @override
  String get clientBookingLimitAction => 'عرض';

  @override
  String get clientBookingLimitInfoTitle => 'الطلبات المفتوحة';

  @override
  String get clientBookingLimitInfo => 'اسحبوا طلبًا مفتوحًا لإرسال طلب آخر.';

  @override
  String get clientBookingPhoneBanner => 'الجوال غير موثّق';

  @override
  String get clientBookingVoucherUneconomic => 'توفير غير كافٍ';

  @override
  String get clientBookingVoucherUneconomicInfo =>
      'في هذا العرض لم يعد التوفير أكبر من سعر الكوبون، لذلك لا يمكن استخدام الكوبون له.';

  @override
  String get clientBookingVoucherCardTitle => 'الكوبون';

  @override
  String get clientBookingVoucherChange => 'تغيير الكوبون';

  @override
  String get clientBookingVoucherValid => 'صالح حتى';

  @override
  String get clientBookingQuoteChanged =>
      'تغيّر إجمالي طلبكم منذ حصولكم على الكوبون بسبب الإضافات التي اخترتموها. الكوبون ما زال ساريًا.';

  @override
  String get clientBookingQuoteChangedShort => 'تغيّر الإجمالي';

  @override
  String get clientBookingSentTitle => 'تم إرسال الطلب';

  @override
  String get clientBookingSentInfoTitle => 'طلبكم';

  @override
  String clientBookingSentBody(String venue, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ ساعة',
      many: '⁦$countString⁩ ساعة',
      few: '⁦$countString⁩ ساعات',
      two: 'ساعتين',
      one: 'ساعة',
      zero: 'لا ساعات',
    );
    return 'لم يُحجز التاريخ بعد. إذا وافق $venue، نثبّته لكم $_temp0 لتؤكدوا الحجز. كوبونكم مرفق بالطلب.';
  }

  @override
  String get clientBookingSentWithdraw =>
      'يمكنكم سحب الطلب، ويعود الكوبون إليكم ويمكن استخدامه هنا من جديد.';

  @override
  String get clientBookingSentDate => 'التاريخ';

  @override
  String get clientBookingSentHall => 'القاعة';

  @override
  String get clientBookingSentGuests => 'الضيوف';

  @override
  String get clientBookingSentReference => 'رقم الطلب';

  @override
  String get clientBookingSentVoucherPrice => 'سعر الكوبون';

  @override
  String get clientBookingSentHeld => 'التاريخ محجوز';

  @override
  String get clientBookingSentHeldLong => 'التاريخ محجوز لدى عروسين آخرين';

  @override
  String get clientBookingSentView => 'عرض الطلب';

  @override
  String get clientBookingSentDiscover => 'استكشاف';

  @override
  String get clientBookingSentWedding => 'زفافي';

  @override
  String get clientBookingSentNotifTitle => 'تحديثات الحجز';

  @override
  String get clientBookingSentNotifYes => 'تفعيل';

  @override
  String get clientBookingSentNotifNo => 'لاحقًا';

  @override
  String get clientBookingSentNotifToast => 'التحديثات مفعّلة';

  @override
  String get clientBookingSentOffline => 'دون اتصال. الملخص محفوظ.';

  @override
  String get clientBookingPlannerTitle => 'منسّق الأعراس';

  @override
  String get clientBookingPlannerNo => 'لاحقًا';

  @override
  String get clientBookingTakenTitle => 'التاريخ غير متاح';

  @override
  String get clientBookingTakenSessionTitle => 'الفترة غير متاحة';

  @override
  String get clientBookingTakenExpiredTitle => 'انتهت المهلة';

  @override
  String get clientBookingTakenLoading => 'جارٍ البحث عن تواريخ متاحة';

  @override
  String get clientBookingTakenNearest => 'أقرب التواريخ المتاحة';

  @override
  String clientBookingTakenSimilar(String date) {
    return 'قاعات مشابهة متاحة يوم $date';
  }

  @override
  String get clientBookingTakenAnother => 'تاريخ آخر';

  @override
  String get clientBookingTakenResults => 'النتائج';

  @override
  String get clientBookingTakenNone => 'لا تواريخ قريبة';

  @override
  String clientBookingTakenNoneInfo(String date) {
    return 'لا توجد تواريخ متاحة قريبة من $date في هذه القاعة. يمكنكم اختيار تاريخ آخر أو استعراض قاعات أخرى.';
  }

  @override
  String get clientBookingTakenVoucherValid => 'كوبونكم ما زال صالحًا';

  @override
  String get clientBookingTakenRebindFailed => 'لا ينتقل الكوبون إليه';

  @override
  String clientBookingTakenRebound(String date) {
    return 'انتقل الكوبون إلى $date';
  }

  @override
  String get clientBookingConfirmHeading => 'التأكيد';

  @override
  String get clientBookingConfirmByLabel => 'التأكيد قبل';

  @override
  String get clientBookingConfirmLapsedLabel => 'انتهت في';

  @override
  String get clientBookingConfirmWindowLabel => 'مهلة التأكيد';

  @override
  String clientBookingConfirmLeft(String time) {
    return 'المتبقي للتأكيد $time';
  }

  @override
  String get clientBookingConfirmSummary => 'ما وافقت عليه القاعة';

  @override
  String get clientBookingConfirmSaveNet => 'توفّرون بعد رسوم الكوبون';

  @override
  String get clientBookingConfirmPayTitle => 'الدفع';

  @override
  String get clientBookingConfirmPay =>
      'لا مبلغ يُدفع هنا. تدفعون للقاعة مباشرةً بعد التأكيد.';

  @override
  String get clientBookingConfirmConsentBody =>
      'أوافق على شروط القاعة وشروط الكوبون.';

  @override
  String get clientBookingConfirmNoteCancel =>
      'التأكيد يحجز التاريخ بسعر الكوبون. الإلغاء بعد التأكيد يُخلي التاريخ ويُستهلك الكوبون.';

  @override
  String get clientBookingConfirmReasonConsent => 'وافقوا للتأكيد';

  @override
  String get clientBookingConfirmAction => 'تأكيد الحجز';

  @override
  String get clientBookingConfirmSeeNext => 'عرض الخيارات';

  @override
  String get clientBookingConfirmCancel => 'إلغاء الطلب';

  @override
  String get clientBookingConfirmViewRequest => 'عرض الطلب';

  @override
  String get clientBookingConfirmOffline =>
      'دون اتصال. أعيدوا الاتصال للتأكيد.';

  @override
  String get clientBookingUpdatedTitle => 'تحديث الطلب';

  @override
  String get clientBookingUpdatedAction => 'التفاصيل';

  @override
  String get clientBookingDoneHeading => 'تم تأكيد الحجز';

  @override
  String get clientBookingDoneVoucherTitle => 'الكوبون';

  @override
  String get clientBookingDonePayWord => 'ادفعوا للقاعة';

  @override
  String get clientBookingDonePayTitle => 'لدى القاعة';

  @override
  String clientBookingDonePay(String venue) {
    return 'ادفعوا إلى $venue مباشرةً، ثم أظهروا هذا الرمز عند الدفع.';
  }

  @override
  String get clientBookingDoneCopied => 'تم النسخ';

  @override
  String get clientBookingDoneChecklist => 'تم تسجيل القاعة كمنجزة في قائمتكم';

  @override
  String get clientBookingDoneSetDate => 'تعيين موعد الزفاف';

  @override
  String get clientBookingDoneDateSet => 'تم تعيين الموعد';

  @override
  String get clientBookingDoneActions => 'الخطوات التالية';

  @override
  String get clientBookingDoneDirections => 'الاتجاهات';

  @override
  String get clientBookingDoneVisit => 'حجز زيارة';

  @override
  String get clientBookingDoneCall => 'الاتصال بالقاعة';

  @override
  String get clientBookingDoneCalling => 'جارٍ الاتصال بالقاعة';

  @override
  String get clientBookingDoneCalendar => 'إضافة إلى التقويم';

  @override
  String get clientBookingDoneCalendarToast => 'أُضيف إلى التقويم';

  @override
  String get clientBookingDoneShared => 'تم نسخ الرابط';

  @override
  String get clientBookingDoneView => 'عرض الحجز';

  @override
  String get clientBookingMapsTitle => 'الاتجاهات';

  @override
  String get clientBookingMapsGoogle => 'خرائط جوجل';

  @override
  String get clientBookingMapsApple => 'خرائط آبل';

  @override
  String get clientBookingMapsWaze => 'ويز';

  @override
  String get clientBookingMapsToast => 'جارٍ فتح الاتجاهات';

  @override
  String get clientBookingEndedTitle => 'انتهت المهلة';

  @override
  String get clientBookingEndedRevokedTitle => 'سُحبت الموافقة';

  @override
  String get clientBookingEndedTakenTitle => 'التاريخ غير متاح';

  @override
  String clientBookingEndedLapsed(String duration, String date) {
    return 'انتهت مهلة التأكيد ($duration)، وتم تحرير موعد $date وسقط الكوبون.';
  }

  @override
  String clientBookingEndedRevoked(String venue, String date) {
    return 'لم يعد بإمكان $venue تثبيت موعد $date، لذلك سُحبت الموافقة.';
  }

  @override
  String clientBookingEndedTaken(String date, String venue) {
    return 'لم يعد $date متاحًا في $venue.';
  }

  @override
  String get clientBookingEndedVoucherTitle => 'كوبونكم';

  @override
  String get clientBookingEndedVoucherPlain =>
      'عاد الكوبون إليكم ويمكن استخدامه لطلب جديد هنا.';

  @override
  String get clientBookingEndedRefund => 'اطلبوا رصيدًا';

  @override
  String get clientBookingEndedNew => 'طلب جديد';

  @override
  String get clientBookingEndedFreeDates => 'تواريخ متاحة';

  @override
  String get clientBookingEndedViewVenue => 'القاعة';

  @override
  String get clientBookingEndedOffline => 'دون اتصال. أعيدوا الاتصال للمتابعة.';

  @override
  String get clientBookingEndedReleased => 'تحرر الموعد';

  @override
  String get clientBookingEndedWindow => 'مهلة التأكيد';

  @override
  String get clientBookingEndedUntil => 'صالح حتى';

  @override
  String get clientBookingEndedVoucherForfeited =>
      'غير صالح. الكوبون الذي لا يُؤكَّد في القاعة خلال المهلة لا يعود.';

  @override
  String clientBookingEndedVoucherCredit(String venue, String date) {
    return 'عاد الكوبون إليكم. استخدموه من جديد في $venue حتى $date، أو اطلبوا كوبون رصيد من الدعم.';
  }

  @override
  String get clientBookingsTitle => 'الحجوزات';

  @override
  String get clientBookingsFindHall => 'البحث عن قاعة';

  @override
  String get clientBookingsSectionNeeds => 'بانتظار قراركم';

  @override
  String get clientBookingsSectionPending => 'معلّقة';

  @override
  String get clientBookingsSectionConfirmed => 'مؤكدة';

  @override
  String get clientBookingsSectionPast => 'السابقة';

  @override
  String get clientBookingsPastFilter => 'تصفية الطلبات السابقة';

  @override
  String get clientBookingsPastNone => 'لا طلبات بهذه الحالة';

  @override
  String get clientBookingsLimitLabel => 'الطلبات المفتوحة';

  @override
  String get clientBookingsLimitReached => 'أغلقوا طلبًا لإرسال آخر';

  @override
  String get clientBookingsGuestTitle => 'تابعوا طلباتكم';

  @override
  String get clientBookingsGuestAction => 'تسجيل الدخول';

  @override
  String get clientBookingsEmptyTitle => 'لا طلبات بعد';

  @override
  String get clientBookingsEmptyAction => 'تصفح القاعات';

  @override
  String clientBookingsEmptyActionDate(String date) {
    return 'قاعات $date';
  }

  @override
  String get clientBookingsVouchers => 'الكوبونات';

  @override
  String get clientBookingsReceipts => 'الإيصالات';

  @override
  String get clientBookingsAudienceWomen => 'الحفل النسائي';

  @override
  String get clientBookingsAudienceMen => 'الحفل الرجالي';

  @override
  String get clientBookingsAudienceMixed => 'حفل مختلط';

  @override
  String get clientBookingsSessionDay => 'فترة نهارية';

  @override
  String get clientBookingsSessionAfternoon => 'فترة العصر';

  @override
  String get clientBookingsSessionEvening => 'فترة مسائية';

  @override
  String get clientBookingsRowReplyBy => 'الرد قبل';

  @override
  String get clientBookingsRowVoucherBack => 'عاد الكوبون';

  @override
  String get clientBookingsRowVoucherUsed => 'استُخدم الكوبون';

  @override
  String get clientBookingsDetailTitle => 'الحجز';

  @override
  String get clientBookingsThreadLabel => 'مراحل الحجز';

  @override
  String get clientBookingsHeadFacts => 'بيانات الحجز';

  @override
  String get clientBookingsFactDate => 'التاريخ';

  @override
  String get clientBookingsFactHall => 'القاعة';

  @override
  String get clientBookingsFactGuests => 'الضيوف';

  @override
  String get clientBookingsFactQuantity => 'الكمية';

  @override
  String get clientBookingsFactPackage => 'الباقة';

  @override
  String get clientBookingsFactNotes => 'ملاحظات';

  @override
  String get clientBookingsPendingTitle => 'تم إرسال الطلب';

  @override
  String get clientBookingsPendingBody =>
      'الكوبون مرفق بالطلب. لم يُحجز أي تاريخ بعد.';

  @override
  String get clientBookingsPendingHeldTitle => 'التاريخ محجوز';

  @override
  String get clientBookingsPendingHeld =>
      'طلب آخر حصل على الموافقة ويحجز هذا التاريخ حاليًا. إذا انتهت مهلته يمكن قبول طلبكم. الكوبون يبقى مرفقًا به.';

  @override
  String get clientBookingsPendingWithdraw => 'سحب الطلب';

  @override
  String get clientBookingsApprovedCancel => 'إلغاء الطلب';

  @override
  String get clientBookingsCancelBooking => 'إلغاء الحجز';

  @override
  String get clientBookingsConfirmWindow => 'مهلة التأكيد';

  @override
  String get clientBookingsConfirmLeft => 'الوقت المتبقي';

  @override
  String get clientBookingsConfirmInfoTitle => 'مهلة التأكيد';

  @override
  String get clientBookingsConfirmInfo =>
      'التاريخ محجوز لكم حتى ذلك الوقت. لا مبلغ إضافي لغزل.';

  @override
  String get clientBookingsStepPay => 'الدفع للقاعة';

  @override
  String get clientBookingsStepShow => 'إظهار الرمز';

  @override
  String get clientBookingsConfirmedInfoTitle => 'الخطوة التالية';

  @override
  String clientBookingsConfirmedPay(String venue) {
    return 'ادفعوا مباشرةً إلى $venue، ثم أظهروا هذا الرمز.';
  }

  @override
  String get clientBookingsAddToCalendar => 'التقويم';

  @override
  String get clientBookingsCalendarAdded => 'أُضيف إلى التقويم';

  @override
  String get clientBookingsBookVisit => 'زيارة';

  @override
  String get clientBookingsRedeemedOn => 'تاريخ الاستخدام';

  @override
  String get clientBookingsRedeemedPrice => 'السعر المطبّق';

  @override
  String get clientBookingsProposedWas => 'التاريخ الأصلي';

  @override
  String get clientBookingsProposedReply => 'الرد قبل';

  @override
  String get clientBookingsDeclinedDate => 'التاريخ غير متاح';

  @override
  String get clientBookingsDeclinedCapacity => 'السعة لا تناسب';

  @override
  String get clientBookingsDeclinedPackage => 'الباقة غير متاحة';

  @override
  String get clientBookingsDeclinedOther => 'لم يُقبل الطلب';

  @override
  String get clientBookingsExpiredTitle => 'لا رد';

  @override
  String get clientBookingsExpiredConfirmTitle => 'انتهت مهلة التأكيد';

  @override
  String clientBookingsExpiredConfirm(String date) {
    return 'انتهت مهلة التأكيد، فتم إخلاء التاريخ المحجوز في $date.';
  }

  @override
  String get clientBookingsExpiredDeadline => 'الموعد النهائي';

  @override
  String get clientBookingsCancelledOn => 'تاريخ الإلغاء';

  @override
  String get clientBookingsCancelledByYou => 'بطلبكم';

  @override
  String get clientBookingsCancelledByVenue => 'من القاعة';

  @override
  String get clientBookingsIssueOpen => 'إبلاغ';

  @override
  String get clientBookingsIssueUntil => 'الإبلاغ حتى';

  @override
  String get clientBookingsIssueReportedTitle => 'تم إرسال البلاغ';

  @override
  String get clientBookingsIssueReportedBody =>
      'وصل بلاغكم إلى دعم غزل، وسنتابعه معكم في الرسائل.';

  @override
  String get clientBookingsIssueTitle => 'الإبلاغ عن مشكلة';

  @override
  String get clientBookingsIssueFacts => 'تفاصيل البلاغ';

  @override
  String get clientBookingsIssueReasonPrice => 'السعر غير مطبّق';

  @override
  String get clientBookingsIssueReasonNotRedeemed => 'لم يُستخدم';

  @override
  String get clientBookingsIssueReasonOther => 'سبب آخر';

  @override
  String get clientBookingsIssueNote => 'ملاحظة';

  @override
  String get clientBookingsIssueSend => 'إرسال البلاغ';

  @override
  String get clientBookingsIssueSent => 'تم إرسال البلاغ';

  @override
  String get clientBookingsShowVoucher => 'عرض الكوبون';

  @override
  String get clientBookingsChooseDate => 'اختيار الموعد';

  @override
  String get clientBookingsSendSimilar => 'قاعات مشابهة';

  @override
  String get clientBookingsSendNew => 'طلب جديد';

  @override
  String get clientBookingsWriteReview => 'كتابة تقييم';

  @override
  String get clientBookingsSectionAlternatives => 'قاعات متاحة';

  @override
  String get clientBookingsSectionEvent => 'المناسبة';

  @override
  String get clientBookingsSectionPrice => 'السعر';

  @override
  String get clientBookingsSectionContact => 'التواصل';

  @override
  String get clientBookingsTerms => 'الشروط';

  @override
  String get clientBookingsMessage => 'مراسلة';

  @override
  String get clientBookingsUsuallyReplies => 'يرد عادةً خلال';

  @override
  String get clientBookingsCallDisplayOnly => 'فتح الهاتف';

  @override
  String get clientBookingsPriceStandard => 'السعر العادي';

  @override
  String get clientBookingsPriceSaving => 'التوفير';

  @override
  String get clientBookingsPricePerGuest => 'للضيف';

  @override
  String get clientBookingsPriceBasis => 'أساس السعر';

  @override
  String get clientBookingsPriceGhazal => 'كوبون غزل';

  @override
  String get clientBookingsPricePaid => 'مدفوع';

  @override
  String get clientBookingsPriceVenue => 'القاعة، دفع مباشر';

  @override
  String get clientBookingsPriceSettled => 'تمت التسوية';

  @override
  String get clientBookingsPriceOffApp => 'خارج التطبيق';

  @override
  String get clientBookingsPriceInfoTitle => 'شروط السعر';

  @override
  String get clientBookingsPriceInfoInclusive =>
      'القاعة تحدد هذا السعر شاملًا. غزل لا تضيف عليه شيئًا.';

  @override
  String get clientBookingsPriceInfoGhazal => 'لا مبلغ إضافي لغزل.';

  @override
  String get clientBookingsOutcomeBackTitle => 'عاد الكوبون';

  @override
  String clientBookingsOutcomeBackReusable(String venue, String date) {
    return 'استخدموه مجددًا في $venue حتى $date.';
  }

  @override
  String clientBookingsOutcomeBackCredit(String venue, String date) {
    return 'استخدموه مجددًا في $venue حتى $date، أو اطلبوا كوبون رصيد من الدعم.';
  }

  @override
  String get clientBookingsOutcomeBackPlain => 'الكوبون جاهز لطلب آخر.';

  @override
  String get clientBookingsOutcomeUsedTitle => 'استُخدم الكوبون';

  @override
  String get clientBookingsOutcomeUsedBody =>
      'إلغاء الحجز المؤكد يستهلك الكوبون، ولا يُعاد أي مبلغ.';

  @override
  String get clientBookingsOutcomeCreditTitle => 'صدر كوبون رصيد';

  @override
  String get clientBookingsOutcomeCreditBody =>
      'كوبون الرصيد في حسابكم. استخدموه في أي قاعة أو فندق أو خدمة.';

  @override
  String get clientBookingsOutcomeExpiredTitle => 'انتهى الكوبون';

  @override
  String get clientBookingsOutcomeExpiredBody =>
      'انتهت صلاحية الكوبون، ولا يمكن استخدامه.';

  @override
  String get clientBookingsOutcomeAction => 'إعادة الاستخدام';

  @override
  String get clientBookingsOutcomeUntil => 'يمكن استخدامه حتى';

  @override
  String get clientBookingsOutcomeAskSupport => 'اسألوا الدعم';

  @override
  String get clientBookingsOutcomeInfoTitle => 'شروط الكوبون';

  @override
  String clientBookingsTicketQr(String code) {
    return 'رمز الاستجابة السريعة للكوبون $code';
  }

  @override
  String get clientBookingsTicketShowFull => 'تكبير';

  @override
  String get clientBookingsTicketUsedOn => 'استُخدم في';

  @override
  String get clientBookingsTicketValidUntil => 'صالح حتى';

  @override
  String get clientBookingsCancelTitleWithdraw => 'سحب الطلب';

  @override
  String get clientBookingsCancelTitleApproved => 'إلغاء الطلب';

  @override
  String get clientBookingsCancelTitleConfirmed => 'إلغاء الحجز';

  @override
  String get clientBookingsCancelDateLabel => 'التاريخ';

  @override
  String get clientBookingsCancelDateReleased => 'إخلاء التاريخ';

  @override
  String get clientBookingsCancelVoucherLabel => 'الكوبون';

  @override
  String get clientBookingsCancelVoucherBack => 'يعود الكوبون';

  @override
  String get clientBookingsCancelVoucherUsed => 'يُستهلك الكوبون';

  @override
  String clientBookingsCancelVoucherBackBody(String venue, String date) {
    return 'يعود الكوبون إليكم ويمكنكم استخدامه من جديد في $venue حتى $date.';
  }

  @override
  String get clientBookingsCancelVoucherUsedBody =>
      'إلغاء الحجز المؤكد يستهلك الكوبون، ولا يُعاد أي مبلغ.';

  @override
  String clientBookingsCancelDateWithdraw(String venue) {
    return 'تُبلَّغ $venue فورًا. لم يكن أي تاريخ محجوزًا لكم بعد.';
  }

  @override
  String clientBookingsCancelDateApproved(String date) {
    return 'يُخلى التاريخ المحجوز في $date.';
  }

  @override
  String clientBookingsCancelDateConfirmed(String date, String venue) {
    return 'يُخلى الحجز في $venue بتاريخ $date.';
  }

  @override
  String clientBookingsCancelVenueMoney(String venue) {
    return 'أي مبلغ دفعتموه إلى $venue مباشرةً يُسوّى بينكم وبين القاعة.';
  }

  @override
  String get clientBookingsCancelInfoTitle => 'الإلغاء';

  @override
  String get clientBookingsCancelAltAction => 'مراسلة القاعة';

  @override
  String get clientBookingsCancelKeep => 'إبقاء الطلب';

  @override
  String get clientBookingsCancelKeepBooking => 'إبقاء الحجز';

  @override
  String get clientBookingsCancelReasonTitle => 'السبب؟';

  @override
  String get clientBookingsCancelReasonPlans => 'تغيّرت الخطط';

  @override
  String get clientBookingsCancelReasonVenue => 'قاعة أخرى';

  @override
  String get clientBookingsCancelReasonDate => 'تغيّر الموعد';

  @override
  String get clientBookingsCancelReasonBudget => 'الميزانية';

  @override
  String get clientBookingsCancelReasonOther => 'أخرى';

  @override
  String get clientBookingsCancelNote => 'ملاحظة';

  @override
  String get clientBookingsCancelActionWithdraw => 'سحب الطلب';

  @override
  String get clientBookingsCancelActionApproved => 'إلغاء الطلب';

  @override
  String get clientBookingsCancelActionConfirmed => 'إلغاء الحجز';

  @override
  String get clientBookingsCancelErrorTitle => 'تعذّر الإلغاء';

  @override
  String get clientBookingsCancelErrorBody => 'لم يتغيّر شيء.';

  @override
  String get clientBookingsCancelDoneWithdrawn => 'تم سحب الطلب';

  @override
  String get clientBookingsCancelDoneApproved => 'تم إلغاء الطلب';

  @override
  String get clientBookingsCancelDoneConfirmed => 'تم إلغاء الحجز';

  @override
  String get clientBookingsProposalCounterTitle => 'مواعيد جديدة';

  @override
  String clientBookingsProposalCounterBody(String venue, String date) {
    return 'تعذّر على $venue استضافتكم في $date. اختاروا أحد هذه المواعيد. سعر الكوبون يبقى كما هو.';
  }

  @override
  String get clientBookingsProposalInfoTitle => 'تفاصيل العرض';

  @override
  String get clientBookingsProposalFacts => 'التفاصيل';

  @override
  String get clientBookingsProposalDatesLabel => 'المواعيد المقترحة';

  @override
  String clientBookingsProposalOptionLabel(String date, String price) {
    return '$date، سعر الكوبون $price';
  }

  @override
  String get clientBookingsProposalTaken => 'محجوز';

  @override
  String clientBookingsProposalTakenBanner(String date) {
    return 'تم حجز $date في هذه الأثناء. اختاروا موعدًا آخر أو راسلوا القاعة.';
  }

  @override
  String get clientBookingsProposalHeld => 'سعر الكوبون ثابت في جميع المواعيد.';

  @override
  String get clientBookingsNoPenalty =>
      'لا غرامة في حال الاعتذار. كوبونكم يبقى لكم.';

  @override
  String get clientBookingsProposalReplyBy => 'الرد قبل';

  @override
  String get clientBookingsProposalConfirmBy => 'التأكيد قبل';

  @override
  String get clientBookingsProposalAccept => 'قبول الموعد';

  @override
  String get clientBookingsProposalDeclineTitle => 'الاعتذار عن المواعيد؟';

  @override
  String get clientBookingsProposalDeclineAction => 'تأكيد الاعتذار';

  @override
  String get clientBookingsProposalDeclineKeep => 'متابعة الاختيار';

  @override
  String get clientBookingsProposalAcceptedTitle => 'تم قبول الموعد';

  @override
  String get clientBookingsProposalClosedTitle => 'تم إغلاق الطلب';

  @override
  String get clientBookingsProposalExpiredTitle => 'انتهى العرض';

  @override
  String get clientBookingsLater => 'لاحقًا';

  @override
  String get clientBookingsReceiptsTitle => 'الإيصالات';

  @override
  String get clientBookingsReceiptsInfoTitle => 'مدفوعات المناسبة';

  @override
  String get clientBookingsReceiptsNote =>
      'مدفوعات المناسبة تتم بينكم وبين القاعة ولا تظهر هنا.';

  @override
  String get clientBookingsReceiptsEmptyTitle => 'لا إيصالات';

  @override
  String get clientBookingsReceiptsReceipt => 'إيصال';

  @override
  String get clientBookingsReceiptsCredit => 'كوبون رصيد';

  @override
  String get clientBookingsReceiptsSaved => 'محفوظ على الهاتف';

  @override
  String get clientBookingsMethodKnet => 'كي نت';

  @override
  String get clientBookingsMethodApplePay => 'أبل باي';

  @override
  String get clientBookingsMethodGooglePay => 'جوجل باي';

  @override
  String get clientBookingsMethodCard => 'بطاقة';

  @override
  String get clientBookingsViewerPreview =>
      'معاينة المستند بالعربية والإنجليزية';

  @override
  String get clientBookingsViewerDownload => 'تنزيل';

  @override
  String get clientBookingsViewerDownloaded => 'تم التنزيل';

  @override
  String get clientBookingsViewerSavedAt => 'محفوظ على الهاتف';

  @override
  String get clientBookingsViewerShareToast => 'اختاروا تطبيقًا';

  @override
  String get clientBookingsViewerOpen => 'فتح';

  @override
  String get clientBookingsViewerOpenToast => 'جارٍ الفتح';

  @override
  String get clientBookingsViewerOpenVoucher => 'الكوبون';

  @override
  String get clientBookingsOutcomeForfeitedTitle => 'الكوبون غير صالح';

  @override
  String clientBookingsOutcomeForfeitedBody(String venue, num hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    return 'لم يُؤكَّد في $venue خلال ⁦$hoursString⁩ ساعة، فسقط الكوبون. لا يُعاد أي مبلغ.';
  }

  @override
  String get clientDiscoverHeroHeadline => 'قاعة ليلتكم';

  @override
  String clientDiscoverBellUnread(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'الإشعارات، ⁦$countString⁩ إشعار غير مقروء',
      many: 'الإشعارات، ⁦$countString⁩ إشعارًا غير مقروء',
      few: 'الإشعارات، ⁦$countString⁩ إشعارات غير مقروءة',
      two: 'الإشعارات، إشعاران غير مقروءين',
      one: 'الإشعارات، إشعار واحد غير مقروء',
      zero: 'الإشعارات',
    );
    return '$_temp0';
  }

  @override
  String get clientDiscoverSwitchLabel => 'التصفح';

  @override
  String get clientDiscoverVariantsTitle => 'بطاقات الحالة';

  @override
  String get clientDiscoverCategoryLuxuryHotels => 'فنادق';

  @override
  String get clientDiscoverCategoryWeddingHalls => 'قاعات';

  @override
  String get clientDiscoverCategoryGovernment => 'حكومية';

  @override
  String get clientDiscoverCategoryBeach => 'شاطئية';

  @override
  String get clientDiscoverCategoryOutdoor => 'خارجية';

  @override
  String get clientDiscoverCategoryVip => 'VIP';

  @override
  String get clientDiscoverBrowseTitle => 'التصنيفات';

  @override
  String clientDiscoverFreeTitle(String date) {
    return 'متاحة $date';
  }

  @override
  String get clientDiscoverShortlistTitle => 'المحفوظة';

  @override
  String get clientDiscoverShortlistCompare => 'مقارنة';

  @override
  String get clientDiscoverFeaturedTitle => 'مميزة';

  @override
  String get clientDiscoverRecommendedTitle => 'مقترحة لكم';

  @override
  String get clientDiscoverTrendingTitle => 'رائجة';

  @override
  String get clientDiscoverNearbyTitle => 'قريبة';

  @override
  String get clientDiscoverEmptyTitle => 'محجوزة بالكامل';

  @override
  String get clientDiscoverEmptyWiden => 'تغيير التاريخ';

  @override
  String get clientDiscoverLocateDialogTitle => 'استخدام الموقع؟';

  @override
  String get clientDiscoverLocateAllow => 'السماح';

  @override
  String get clientDiscoverLocateNotNow => 'ليس الآن';

  @override
  String get clientDiscoverEmptyNearLabel => 'أقرب التواريخ المتاحة';

  @override
  String get clientDiscoverEmptyDateSet => 'تحديث التاريخ';

  @override
  String get clientDiscoverBrowseAll => 'كل القاعات';

  @override
  String get clientDiscoverBriefLabel => 'تفاصيل زفافكم';

  @override
  String get clientDiscoverBriefChooseDate => 'التاريخ';

  @override
  String get clientDiscoverBriefChooseArea => 'المنطقة';

  @override
  String get clientDiscoverBriefAddGuests => 'الضيوف';

  @override
  String get clientDiscoverBriefSetBudget => 'الميزانية';

  @override
  String clientDiscoverBriefAreaMore(String first, String more) {
    return '$first +$more';
  }

  @override
  String clientDiscoverCtaCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'عرض ⁦$countString⁩ قاعة',
      many: 'عرض ⁦$countString⁩ قاعة',
      few: 'عرض ⁦$countString⁩ قاعات',
      two: 'عرض قاعتين',
      one: 'عرض قاعة',
      zero: 'عرض القاعات',
    );
    return '$_temp0';
  }

  @override
  String get clientDiscoverCtaShow => 'عرض القاعات';

  @override
  String get clientDiscoverCtaNearest => 'أقرب التواريخ';

  @override
  String get clientDiscoverResultsTitle => 'القاعات';

  @override
  String get clientDiscoverResultsSearchPlaceholder => 'قاعة أو منطقة';

  @override
  String get clientDiscoverResultsFilters => 'التصفية';

  @override
  String get clientDiscoverResultsClearAll => 'مسح';

  @override
  String clientDiscoverResultsRemoveChip(String name) {
    return 'إزالة $name';
  }

  @override
  String get clientDiscoverResultsMap => 'الخريطة';

  @override
  String get clientDiscoverResultsList => 'القائمة';

  @override
  String get clientDiscoverResultsBriefHint => 'تعديل التفاصيل';

  @override
  String get clientDiscoverResultsSeeFreeDates => 'التواريخ المتاحة';

  @override
  String get clientDiscoverResultsGovernmentNote =>
      'للاطلاع فقط. الحجز عبر القناة الرسمية. بدون كوبون.';

  @override
  String get clientDiscoverResultsRefreshed => 'تحديث القاعات';

  @override
  String clientDiscoverResultsNoneRelax(String filter) {
    return 'إزالة $filter';
  }

  @override
  String get clientDiscoverResultsNoneDates => 'أقرب التواريخ المتاحة';

  @override
  String get clientDiscoverResultsOfflineMap =>
      'الخريطة تحتاج اتصالًا. القائمة تعمل.';

  @override
  String get clientDiscoverSearchRecent => 'الأخيرة';

  @override
  String get clientDiscoverSearchClearRecent => 'مسح';

  @override
  String get clientDiscoverSortTitle => 'الترتيب';

  @override
  String get clientDiscoverSortRecommended => 'المقترحة';

  @override
  String get clientDiscoverSortRating => 'التقييم';

  @override
  String get clientDiscoverSortNewest => 'الأحدث';

  @override
  String get clientDiscoverSortPrice => 'الأقل سعرًا';

  @override
  String get clientDiscoverSortPriceDesc => 'الأعلى سعرًا';

  @override
  String get clientDiscoverSortDistance => 'الأقرب';

  @override
  String get clientDiscoverChipAreasAll => 'كل المناطق';

  @override
  String clientDiscoverChipRating(String rating) {
    return '$rating+';
  }

  @override
  String get clientDiscoverArrangementWomen => 'نسائي';

  @override
  String get clientDiscoverArrangementMen => 'رجالي';

  @override
  String get clientDiscoverArrangementMixed => 'مختلط';

  @override
  String get clientDiscoverSettingIndoor => 'داخلي';

  @override
  String get clientDiscoverSettingOutdoor => 'خارجي';

  @override
  String get clientDiscoverSettingMixed => 'كلاهما';

  @override
  String get clientDiscoverFacilityParking => 'مواقف';

  @override
  String get clientDiscoverFacilityValet => 'فاليه';

  @override
  String get clientDiscoverFacilityBridal => 'العروس';

  @override
  String get clientDiscoverFacilityBuffet => 'بوفيه';

  @override
  String get clientDiscoverFacilityDecor => 'ديكور';

  @override
  String get clientDiscoverFacilityPhotography => 'تصوير';

  @override
  String get clientDiscoverLevelPrestige => 'فاخر';

  @override
  String get clientDiscoverLevelSignature => 'راقٍ';

  @override
  String get clientDiscoverLevelClassic => 'كلاسيكي';

  @override
  String get clientDiscoverLevelGovernment => 'حكومي';

  @override
  String get clientDiscoverFiltersTitle => 'التصفية';

  @override
  String get clientDiscoverFiltersGroupArrangement => 'الحفل';

  @override
  String get clientDiscoverFiltersGroupType => 'نوع المكان';

  @override
  String get clientDiscoverFiltersGroupPrice => 'السعر العادي';

  @override
  String get clientDiscoverFiltersGroupCapacity => 'السعة';

  @override
  String get clientDiscoverFiltersGroupSetting => 'طبيعة المكان';

  @override
  String get clientDiscoverFiltersGroupFacilities => 'المرافق';

  @override
  String get clientDiscoverFiltersGroupRating => 'التقييم';

  @override
  String get clientDiscoverFiltersGroupLevel => 'المستوى';

  @override
  String get clientDiscoverFiltersGroupBrand => 'سلسلة الفندق';

  @override
  String clientDiscoverFiltersCta(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'عرض ⁦$countString⁩ قاعة',
      many: 'عرض ⁦$countString⁩ قاعة',
      few: 'عرض ⁦$countString⁩ قاعات',
      two: 'عرض قاعتين',
      one: 'عرض قاعة',
      zero: 'لا قاعات',
    );
    return '$_temp0';
  }

  @override
  String get clientDiscoverFiltersCtaNone => 'لا قاعات';

  @override
  String get clientDiscoverFiltersClear => 'مسح';

  @override
  String clientDiscoverFiltersExpand(String group) {
    return 'عرض $group';
  }

  @override
  String clientDiscoverFiltersCollapse(String group) {
    return 'إخفاء $group';
  }

  @override
  String get clientDiscoverBriefTitle => 'تفاصيل زفافكم';

  @override
  String get clientDiscoverBriefClear => 'مسح';

  @override
  String get clientDiscoverBriefBack => 'العودة إلى تفاصيل زفافكم';

  @override
  String get clientDiscoverBriefDateTitle => 'التاريخ';

  @override
  String get clientDiscoverBriefDateFlexible => 'أي شهر';

  @override
  String get clientDiscoverBriefAreaTitle => 'المنطقة';

  @override
  String get clientDiscoverBriefGuestsTitle => 'الضيوف';

  @override
  String get clientDiscoverBriefGuestsPresets => 'اختيارات سريعة';

  @override
  String get clientDiscoverBriefGuestsSection => 'البحث عن';

  @override
  String get clientDiscoverBriefBudgetTitle => 'الميزانية';

  @override
  String get clientDiscoverBriefBudgetHelper => 'القاعة والضيافة فقط';

  @override
  String get clientDiscoverBriefBudgetBands => 'فئات الميزانية';

  @override
  String clientDiscoverBriefBudgetUnder(String amount) {
    return 'دون $amount';
  }

  @override
  String get clientDiscoverBriefDone => 'تم';

  @override
  String get clientDiscoverMergeTitle => 'تفاصيل مختلفة';

  @override
  String get clientDiscoverMergePhone => 'هذا الهاتف';

  @override
  String get clientDiscoverMergeAccount => 'حسابكم';

  @override
  String get clientDiscoverMapTitle => 'الخريطة';

  @override
  String get clientDiscoverMapPins => 'القاعات على الخريطة';

  @override
  String clientDiscoverMapCluster(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ قاعة هنا، اضغطوا للتقريب',
      many: '⁦$countString⁩ قاعة هنا، اضغطوا للتقريب',
      few: '⁦$countString⁩ قاعات هنا، اضغطوا للتقريب',
      two: 'قاعتان هنا، اضغطوا للتقريب',
      one: 'قاعة واحدة هنا، اضغطوا للتقريب',
      zero: 'لا قاعات هنا',
    );
    return '$_temp0';
  }

  @override
  String get clientDiscoverMapZoomOut => 'عرض كل القاعات';

  @override
  String get clientDiscoverMapLocate => 'موقعي';

  @override
  String get clientDiscoverMapSearchArea => 'بحث هنا';

  @override
  String clientDiscoverMapDenied(String area) {
    return 'قرب $area';
  }

  @override
  String get clientDiscoverMapLocated => 'قربكم';

  @override
  String get clientDiscoverMapNoneAction => 'كل القاعات';

  @override
  String get clientDiscoverMapOfflineAction => 'القائمة';

  @override
  String get clientDiscoverMapViewLabel => 'العرض';

  @override
  String get clientDiscoverRefreshed => 'تم التحديث';

  @override
  String get clientDiscoverVoucherTitle => 'أسعار الكوبون';

  @override
  String get clientDiscoverWeekTitle => 'هذا الأسبوع';

  @override
  String get clientDiscoverCardGetVoucher => 'شراء كوبون';

  @override
  String get clientDiscoverCardView => 'عرض';

  @override
  String get clientDiscoverChipRegion => 'المنطقة';

  @override
  String get clientDiscoverChipDate => 'التاريخ';

  @override
  String get clientDiscoverChipVoucher => 'كوبون';

  @override
  String get clientDiscoverSortVoucher => 'سعر الكوبون';

  @override
  String get clientDiscoverMapVoucherPin => 'سعر الكوبون';

  @override
  String get clientDiscoverFiltersGroupRegion => 'المنطقة';

  @override
  String get clientDiscoverFiltersGroupStructure => 'التسعير';

  @override
  String get clientDiscoverFiltersGroupDate => 'التاريخ';

  @override
  String get clientDiscoverFiltersGroupVoucher => 'سعر الكوبون';

  @override
  String get clientDiscoverFiltersDateOpen => 'التقويم';

  @override
  String get clientDiscoverFiltersVoucherTitle => 'كوبون فقط';

  @override
  String get clientDiscoverBriefAreaAll => 'الكل';

  @override
  String get clientDiscoverBriefAreaClearGroup => 'مسح';

  @override
  String get clientDiscoverRegionPlaceholder => 'منطقة أو قاعة';

  @override
  String get clientDiscoverRegionNear => 'قريب مني';

  @override
  String get clientDiscoverRegionListLabel => 'المحافظات والمناطق';

  @override
  String get clientDiscoverDatesTitle => 'التواريخ';

  @override
  String get clientDiscoverDatesFlexible => 'أي شهر';

  @override
  String clientDiscoverDatesHint(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '⁦$daysString⁩ يوم',
      many: '⁦$daysString⁩ يومًا',
      few: '⁦$daysString⁩ أيام',
      two: 'يومين',
      one: 'يوم',
      zero: 'لا أيام',
    );
    return 'حتى $_temp0';
  }

  @override
  String get clientDiscoverDatesLegend => 'القاعات المتاحة في كل يوم';

  @override
  String get clientDiscoverDatesMany => 'كثيرة';

  @override
  String get clientDiscoverDatesFew => 'قليلة';

  @override
  String get clientDiscoverDatesNoneLegend => 'لا شيء';

  @override
  String get clientDiscoverDatesNone => 'لا قاعات';

  @override
  String get clientDiscoverDatesApply => 'تطبيق';

  @override
  String get clientDiscoverDatesClear => 'مسح';

  @override
  String get clientDiscoverStatusNoDate => 'تحديد التاريخ';

  @override
  String clientDiscoverStatusBrief(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ قاعة متاحة',
      many: '⁦$countString⁩ قاعة متاحة',
      few: '⁦$countString⁩ قاعات متاحة',
      two: 'قاعتان متاحتان',
      one: 'قاعة متاحة',
      zero: 'لا قاعات متاحة',
    );
    return '$_temp0';
  }

  @override
  String get clientDiscoverA11yDate => 'التاريخ';

  @override
  String get clientDiscoverA11yTime => 'الوقت';

  @override
  String get clientDiscoverA11yTimeLeft => 'الوقت المتبقي';

  @override
  String get clientDiscoverA11yUpdated => 'آخر تحديث';

  @override
  String get clientDiscoverA11yDrive => 'مدة القيادة';

  @override
  String get clientDiscoverMergeKeep => 'اعتماد';

  @override
  String get clientDiscoverA11yDaysLeft => 'الأيام المتبقية';

  @override
  String clientDiscoverMinutes(String minutes) {
    return '$minutes د';
  }

  @override
  String get clientDiscoverFiltersVoucherCount => 'قاعات بكوبون';

  @override
  String clientDiscoverKm(num km) {
    final intl.NumberFormat kmNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String kmString = kmNumberFormat.format(km);

    return '⁦$kmString⁩ كم';
  }

  @override
  String get clientDiscoverA11yDistance => 'المسافة';

  @override
  String clientDiscoverBriefBudgetOver(String amount) {
    return '$amount فأكثر';
  }

  @override
  String get clientMessagesInboxTitle => 'الرسائل';

  @override
  String clientMessagesBellUnread(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'الإشعارات، ⁦$countString⁩ إشعار غير مقروء',
      many: 'الإشعارات، ⁦$countString⁩ إشعارًا غير مقروء',
      few: 'الإشعارات، ⁦$countString⁩ إشعارات غير مقروءة',
      two: 'الإشعارات، إشعاران غير مقروءين',
      one: 'الإشعارات، إشعار واحد غير مقروء',
      zero: 'الإشعارات',
    );
    return '$_temp0';
  }

  @override
  String get clientMessagesFilterGroup => 'تصفية المحادثات';

  @override
  String get clientMessagesFilterVenues => 'القاعات';

  @override
  String get clientMessagesFilterVisits => 'الزيارات';

  @override
  String get clientMessagesFilterPlanner => 'التنسيق';

  @override
  String get clientMessagesFilterProviders => 'الخدمات';

  @override
  String get clientMessagesFilterSupport => 'الدعم';

  @override
  String get clientMessagesPinned => 'مثبتة';

  @override
  String get clientMessagesYou => 'أنتم';

  @override
  String get clientMessagesPreviewVoice => 'رسالة صوتية';

  @override
  String get clientMessagesPreviewPhoto => 'صورة';

  @override
  String get clientMessagesPreviewDocument => 'مستند';

  @override
  String clientMessagesUnreadCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ رسالة غير مقروءة',
      many: '⁦$countString⁩ رسالة غير مقروءة',
      few: '⁦$countString⁩ رسائل غير مقروءة',
      two: 'رسالتان غير مقروءتين',
      one: 'رسالة واحدة غير مقروءة',
      zero: 'لا رسائل غير مقروءة',
    );
    return '$_temp0';
  }

  @override
  String clientMessagesOfflineStamp(String time) {
    return 'دون اتصال · $time';
  }

  @override
  String clientMessagesDayMonth(String day, String month) {
    return '$day $month';
  }

  @override
  String get clientMessagesEmptyTitle => 'لا رسائل بعد';

  @override
  String get clientMessagesEmptyAction => 'تصفح القاعات';

  @override
  String get clientMessagesEmptySupport => 'الدعم';

  @override
  String get clientMessagesGuestLabel => 'تسجيل الدخول لمتابعة الرسائل';

  @override
  String get clientMessagesGuestAction => 'تسجيل الدخول';

  @override
  String get clientMessagesVisitMembers => 'أعضاء المحادثة';

  @override
  String get clientMessagesInfoTitle => 'التفاصيل';

  @override
  String clientMessagesRepliesWithin(int hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'يرد عادةً خلال ⁦$hoursString⁩ ساعة',
      many: 'يرد عادةً خلال ⁦$hoursString⁩ ساعة',
      few: 'يرد عادةً خلال ⁦$hoursString⁩ ساعات',
      two: 'يرد عادةً خلال ساعتين',
      one: 'يرد عادةً خلال ساعة',
      zero: 'يرد عادةً في وقت قصير',
    );
    return '$_temp0';
  }

  @override
  String get clientMessagesContextView => 'عرض الطلب';

  @override
  String get clientMessagesContextConfirm => 'تأكيد';

  @override
  String get clientMessagesFactDate => 'تاريخ المناسبة';

  @override
  String get clientMessagesFactGuests => 'الضيوف';

  @override
  String get clientMessagesFactTimeLeft => 'الوقت المتبقي للتأكيد';

  @override
  String get clientMessagesFactDue => 'موعد الاستحقاق';

  @override
  String get clientMessagesFactMeeting => 'الاجتماع';

  @override
  String get clientMessagesFactDaysLeft => 'الأيام المتبقية للزفاف';

  @override
  String get clientMessagesAudienceWomen => 'الحفل النسائي';

  @override
  String get clientMessagesAudienceMen => 'الحفل الرجالي';

  @override
  String get clientMessagesAudienceMixed => 'حفل مختلط';

  @override
  String get clientMessagesComposerPlaceholder => 'رسالة';

  @override
  String get clientMessagesComposerLabel => 'الرسالة';

  @override
  String get clientMessagesAttach => 'إرفاق';

  @override
  String get clientMessagesRecordHold => 'اضغطوا مطولًا لتسجيل رسالة صوتية';

  @override
  String get clientMessagesRecording => 'قيد التسجيل';

  @override
  String get clientMessagesSlideCancel => 'إلغاء';

  @override
  String get clientMessagesReleaseCancel => 'أفلتوا';

  @override
  String get clientMessagesRecordDelete => 'حذف التسجيل';

  @override
  String get clientMessagesRecordSend => 'إرسال الرسالة الصوتية';

  @override
  String get clientMessagesRecordTooShort => 'اضغطوا مطولًا';

  @override
  String get clientMessagesMsgSending => 'قيد الإرسال';

  @override
  String get clientMessagesMsgFailed => 'فشل الإرسال';

  @override
  String get clientMessagesMsgQueued => 'بالانتظار';

  @override
  String get clientMessagesUploading => 'قيد الرفع';

  @override
  String get clientMessagesUploadCancel => 'إلغاء الرفع';

  @override
  String get clientMessagesOfflineQueue => 'دون اتصال';

  @override
  String get clientMessagesSuggestAvailability => 'التواريخ';

  @override
  String get clientMessagesSuggestVisit => 'زيارة';

  @override
  String get clientMessagesSuggestVoucher => 'الكوبون';

  @override
  String clientMessagesSuggestAvailabilityText(String date) {
    return 'السلام عليكم، هل يوم $date متاح للحفل النسائي؟';
  }

  @override
  String get clientMessagesSuggestAvailabilityAny =>
      'السلام عليكم، ما التواريخ المتاحة لديكم للحفل النسائي؟';

  @override
  String clientMessagesSuggestVoucherText(String date) {
    return 'السلام عليكم، كم سعر الكوبون للحفل النسائي ليوم $date؟';
  }

  @override
  String get clientMessagesSuggestVoucherAny =>
      'السلام عليكم، ممكن تعطوننا سعر الكوبون للحفل النسائي؟';

  @override
  String get clientMessagesSupportIntro => 'أهلًا بكم، كيف نخدمكم؟';

  @override
  String get clientMessagesBlockedNote => 'محظورة';

  @override
  String get clientMessagesUnblock => 'إلغاء الحظر';

  @override
  String get clientMessagesUnblockedToast => 'تم إلغاء الحظر';

  @override
  String get clientMessagesSysRequestSent => 'تم الإرسال';

  @override
  String get clientMessagesSysApproved => 'تمت الموافقة';

  @override
  String get clientMessagesSysConfirmed => 'مؤكد';

  @override
  String get clientMessagesSysRedeemed => 'تم الاستخدام';

  @override
  String get clientMessagesSysNotAccepted => 'لم يُقبل';

  @override
  String get clientMessagesSysExpired => 'لا رد';

  @override
  String get clientMessagesSysLapsed => 'انتهت المهلة';

  @override
  String get clientMessagesSysCancelled => 'ملغي';

  @override
  String get clientMessagesSysInfoTitle => 'الكوبون';

  @override
  String get clientMessagesSysInfoKept => 'الكوبون ما زال لكم.';

  @override
  String clientMessagesSysInfoPay(String venue) {
    return 'ادفعوا إلى $venue مباشرةً وأظهروا رمز الكوبون.';
  }

  @override
  String get clientMessagesOpenPhoto => 'صور المحادثة';

  @override
  String get clientMessagesPhotoViewer => 'عارض الصور';

  @override
  String get clientMessagesStatusDelivered => 'وصلت';

  @override
  String get clientMessagesStatusRead => 'قرئت';

  @override
  String get clientMessagesCardCalendar => 'التقويم';

  @override
  String get clientMessagesCardCalendarToast => 'تمت الإضافة';

  @override
  String get clientMessagesCardChange => 'تغيير';

  @override
  String get clientMessagesCardVendor => 'الصفحة';

  @override
  String get clientMessagesAttachTitle => 'إرفاق';

  @override
  String get clientMessagesAttachCamera => 'الكاميرا';

  @override
  String get clientMessagesAttachPhoto => 'الصور';

  @override
  String get clientMessagesAttachDocument => 'مستند';

  @override
  String get clientMessagesAttachRecent => 'أحدث الصور';

  @override
  String clientMessagesAttachLimits(String photo, String video) {
    return 'الصور حتى $photo، والفيديو حتى $video. وسائط المحادثة خاصة بينكم وبين الطرف الآخر.';
  }

  @override
  String get clientMessagesAttachLimitsTitle => 'الحدود';

  @override
  String clientMessagesUnitMb(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '⁦$nString⁩ ميغابايت';
  }

  @override
  String clientMessagesUnitSeconds(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '⁦$nString⁩ ثانية',
      many: '⁦$nString⁩ ثانية',
      few: '⁦$nString⁩ ثوان',
      two: 'ثانيتان',
      one: 'ثانية واحدة',
      zero: 'لا ثوان',
    );
    return '$_temp0';
  }

  @override
  String clientMessagesUnitKb(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '⁦$nString⁩ ك.ب';
  }

  @override
  String get clientMessagesDocPreview => 'معاينة المستند';

  @override
  String get clientMessagesDocQuotation => 'عرض سعر';

  @override
  String get clientMessagesDocEvent => 'تاريخ المناسبة';

  @override
  String get clientMessagesDocHall => 'الصالة';

  @override
  String get clientMessagesDocGuests => 'الضيوف';

  @override
  String get clientMessagesDocPackage => 'الباقة';

  @override
  String get clientMessagesDocFileSize => 'حجم الملف';

  @override
  String get clientMessagesDocStandard => 'العادي';

  @override
  String get clientMessagesDocVoucher => 'الكوبون';

  @override
  String get clientMessagesDocSaving => 'التوفير';

  @override
  String get clientMessagesDocDownload => 'تنزيل';

  @override
  String get clientMessagesDocSaved => 'تم الحفظ';

  @override
  String clientMessagesDocOpen(String name) {
    return 'فتح $name';
  }

  @override
  String get clientMessagesInfoBooking => 'الطلب المرتبط';

  @override
  String get clientMessagesInfoShared => 'الصور والمستندات';

  @override
  String get clientMessagesInfoMute => 'كتم';

  @override
  String get clientMessagesInfoMuted => 'تم الكتم';

  @override
  String get clientMessagesInfoUnmuted => 'تم إلغاء الكتم';

  @override
  String get clientMessagesInfoCall => 'اتصال';

  @override
  String get clientMessagesInfoReport => 'إبلاغ';

  @override
  String get clientMessagesInfoBlock => 'حظر';

  @override
  String get clientMessagesInfoMembers => 'الأعضاء';

  @override
  String get clientMessagesInfoMembersNote =>
      'هؤلاء الثلاثة فقط في المحادثة. أرقام الهواتف غير مشاركة.';

  @override
  String get clientMessagesInfoVisit => 'الزيارة';

  @override
  String get clientMessagesInfoVisitNote =>
      'دعم غزل جزء من هذه المحادثة، لذا لا يمكن حظرها. لإيقافها ألغوا الزيارة.';

  @override
  String get clientMessagesInfoSupportNote => 'لا يمكن حظر محادثات الدعم.';

  @override
  String get clientMessagesInfoPrivate =>
      'وسائط المحادثة خاصة بينكم وبين الطرف الآخر.';

  @override
  String get clientMessagesInfoPrivateTitle => 'الخصوصية';

  @override
  String get clientMessagesInfoNeedsConnection => 'يلزم اتصال';

  @override
  String get clientMessagesInfoErrorReport => 'فشل الإرسال';

  @override
  String get clientMessagesReportPick => 'اختيار الرسالة';

  @override
  String get clientMessagesReportReasonTitle => 'السبب';

  @override
  String get clientMessagesReasonSpam => 'إزعاج';

  @override
  String get clientMessagesReasonAbusive => 'مسيء';

  @override
  String get clientMessagesReasonInappropriate => 'غير لائق';

  @override
  String get clientMessagesReasonOther => 'أخرى';

  @override
  String get clientMessagesReportNote => 'ملاحظة';

  @override
  String get clientMessagesReportSubmit => 'إرسال البلاغ';

  @override
  String get clientMessagesReportDone => 'تم الإبلاغ';

  @override
  String get clientMessagesReportDoneDetail =>
      'تبقى الرسالة في محادثتكم. سيطلع عليها فريقنا ويتصرف إذا خالفت قواعدنا.';

  @override
  String get clientMessagesReportNoMessages => 'لا رسائل';

  @override
  String get clientMessagesReportNeedMessage => 'اختاروا رسالة';

  @override
  String get clientMessagesReportNeedReason => 'اختاروا سببًا';

  @override
  String get clientMessagesBlockTitle => 'حظر المحادثة؟';

  @override
  String clientMessagesBlockBodyBooking(String phone) {
    return 'التحديثات تصلكم. اتصلوا على $phone';
  }

  @override
  String get clientMessagesBlockConfirm => 'حظر';

  @override
  String get clientMessagesBlockKeep => 'إلغاء';

  @override
  String get clientMessagesBlockedDoneTitle => 'تم الحظر';

  @override
  String get clientMessagesBlockedDoneDetail =>
      'لن تصلكم رسائل من هذا الطرف. يمكنكم إلغاء الحظر في أي وقت.';

  @override
  String get clientMessagesNtfTitle => 'الإشعارات';

  @override
  String get clientMessagesNtfPrefs => 'إعدادات الإشعارات';

  @override
  String get clientMessagesNtfFilterGroup => 'تصفية الإشعارات';

  @override
  String get clientMessagesNtfBookings => 'الطلبات';

  @override
  String get clientMessagesNtfVouchers => 'الكوبونات';

  @override
  String get clientMessagesNtfVisits => 'الزيارات';

  @override
  String get clientMessagesNtfMessages => 'الرسائل';

  @override
  String get clientMessagesNtfPlanning => 'التخطيط';

  @override
  String get clientMessagesNtfUnreadOnly => 'غير المقروءة';

  @override
  String get clientMessagesNtfUnread => 'غير مقروء';

  @override
  String get clientMessagesNtfMarkAll => 'قراءة الكل';

  @override
  String get clientMessagesNtfAllRead => 'تمت القراءة';

  @override
  String get clientMessagesNtfEmptyTitle => 'لا إشعارات';

  @override
  String get clientMessagesNtfUnreadEmptyTitle => 'لا جديد';

  @override
  String get clientMessagesNtfShowAll => 'عرض الكل';

  @override
  String get clientMessagesNtfDeniedTitle => 'الإشعارات متوقفة';

  @override
  String get clientMessagesNtfDeniedInfo =>
      'ما زالت التحديثات تظهر هنا. اسمحوا بالإشعارات من إعدادات الهاتف لتصلكم فور حدوثها.';

  @override
  String get clientMessagesNtfOpenSettings => 'الإعدادات';

  @override
  String get clientMessagesNtfSettingsToast => 'يفتح إعدادات الهاتف';

  @override
  String get clientMessagesNtfOffer => 'عرض';

  @override
  String get clientMessagesNtfKindRequestSent => 'تم الإرسال';

  @override
  String get clientMessagesNtfKindApproved => 'تمت الموافقة';

  @override
  String get clientMessagesNtfKindConfirmReminder => 'تأكيد';

  @override
  String get clientMessagesNtfKindConfirmed => 'مؤكد';

  @override
  String get clientMessagesNtfKindDeclined => 'لم يُقبل';

  @override
  String get clientMessagesNtfKindExpired => 'انتهت المهلة';

  @override
  String get clientMessagesNtfKindCancelled => 'ملغي';

  @override
  String get clientMessagesNtfKindVoucherReady => 'الكوبون جاهز';

  @override
  String get clientMessagesNtfKindVoucherKept => 'الكوبون لكم';

  @override
  String get clientMessagesNtfKindRedeemed => 'تم الاستخدام';

  @override
  String get clientMessagesNtfKindRefunded => 'رصيد';

  @override
  String get clientMessagesNtfKindExpiring => 'ينتهي قريبًا';

  @override
  String get clientMessagesNtfKindVisitRequested => 'طلب زيارة';

  @override
  String get clientMessagesNtfKindVisitConfirmed => 'الزيارة مؤكدة';

  @override
  String get clientMessagesNtfKindVisitSoon => 'الزيارة قريبًا';

  @override
  String get clientMessagesNtfKindVisitChat => 'محادثة الزيارة';

  @override
  String get clientMessagesNtfKindNewVenue => 'قاعة جديدة';

  @override
  String get clientMessagesNtfKindReview => 'التقييم';

  @override
  String get clientMessagesNtfKindCountdown => 'الزفاف';

  @override
  String get clientMessagesNtfKindChecklist => 'المهام';

  @override
  String get clientMessagesPromptTitle => 'تنبيهات الحجز';

  @override
  String get clientMessagesPromptBody =>
      'سنخبركم فور رد القاعة على طلبكم، وحين يصبح الكوبون جاهزًا.';

  @override
  String get clientMessagesPromptNote =>
      'لا نرسل إلا ما يلزمكم، ولا نزعجكم ليلًا.';

  @override
  String get clientMessagesPromptOn => 'تفعيل';

  @override
  String get clientMessagesPromptLater => 'ليس الآن';

  @override
  String get clientMessagesPromptOnToast => 'تم التفعيل';

  @override
  String get clientMessagesOsTitle => 'يرغب «غزل» في إرسال إشعارات إليكم';

  @override
  String get clientMessagesOsBody =>
      'تحديثات الطلبات والكوبونات وتذكيرات الزيارات.';

  @override
  String get clientMessagesOsAllow => 'سماح';

  @override
  String get clientMessagesOsDeny => 'عدم السماح';

  @override
  String get clientMessagesMissingTitle => 'غير مدرجة';

  @override
  String get clientMessagesMissingArea => 'المنطقة';

  @override
  String get clientMyWeddingHubTitle => 'زفافكم';

  @override
  String get clientMyWeddingHubNotifications => 'الإشعارات';

  @override
  String clientMyWeddingHeroUnit(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يوم',
      many: 'يومًا',
      few: 'أيام',
      two: 'يومان',
      one: 'يوم',
      zero: 'يوم',
    );
    return '$_temp0';
  }

  @override
  String get clientMyWeddingHeroTimeline => 'محطات العد';

  @override
  String get clientMyWeddingHeroDate => 'موعد الزفاف';

  @override
  String get clientMyWeddingHeroWordToday => 'اليوم';

  @override
  String get clientMyWeddingHeroWordTomorrow => 'غدًا';

  @override
  String get clientMyWeddingHeroSetDate => 'تحديد الموعد';

  @override
  String get clientMyWeddingDoneTitle => 'مبروك';

  @override
  String get clientMyWeddingDoneReviewAction => 'تقييم';

  @override
  String get clientMyWeddingDayDirections => 'الاتجاهات';

  @override
  String get clientMyWeddingDayCall => 'الاتصال بالقاعة';

  @override
  String get clientMyWeddingDayMessage => 'مراسلة المنسّقة';

  @override
  String get clientMyWeddingDayDirectionsToast => 'فتح الاتجاهات';

  @override
  String get clientMyWeddingDayCallToast => 'جارٍ الاتصال بالقاعة';

  @override
  String get clientMyWeddingNextTitle => 'التالي';

  @override
  String get clientMyWeddingNextWaiting => 'بانتظار الرد';

  @override
  String clientMyWeddingNextWaitingLabel(String when) {
    return 'الرد المتوقع قبل $when';
  }

  @override
  String get clientMyWeddingNextHalls => 'عرض القاعات';

  @override
  String get clientMyWeddingNextHallsLabel => 'قاعات متاحة في موعدكم';

  @override
  String get clientMyWeddingVoucherOpen => 'فتح';

  @override
  String clientMyWeddingNextConfirmLabel(String when) {
    return 'التأكيد قبل $when';
  }

  @override
  String get clientMyWeddingTaskVenue => 'القاعة';

  @override
  String get clientMyWeddingTaskPhotographer => 'المصوّرة';

  @override
  String get clientMyWeddingTaskDress => 'الفستان';

  @override
  String get clientMyWeddingTaskInvitations => 'الدعوات';

  @override
  String get clientMyWeddingTaskCake => 'الكيكة';

  @override
  String get clientMyWeddingTaskMusic => 'الموسيقى';

  @override
  String get clientMyWeddingTaskFlowers => 'الزهور';

  @override
  String get clientMyWeddingTaskTransport => 'السيارات';

  @override
  String clientMyWeddingTasksLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ مهمة متبقية',
      many: '⁦$countString⁩ مهمة متبقية',
      few: '⁦$countString⁩ مهام متبقية',
      two: 'مهمتان متبقيتان',
      one: 'مهمة واحدة متبقية',
      zero: 'لا مهام متبقية',
    );
    return '$_temp0';
  }

  @override
  String get clientMyWeddingBookingsTitle => 'الحجوزات';

  @override
  String get clientMyWeddingBookingsEmptyTitle => 'لا حجوزات';

  @override
  String get clientMyWeddingBookingsEmptyAction => 'استكشاف القاعات';

  @override
  String get clientMyWeddingBookingGuests => 'الضيوف';

  @override
  String get clientMyWeddingPlannerTitle => 'تنسيق الأعراس';

  @override
  String get clientMyWeddingPlannerOfferAction => 'عرض الباقات';

  @override
  String get clientMyWeddingPlannerDismiss => 'إخفاء العرض';

  @override
  String clientMyWeddingPlannerCall(String when) {
    return 'مكالمة فيديو $when';
  }

  @override
  String get clientMyWeddingToolsLabel => 'أدوات التخطيط';

  @override
  String get clientMyWeddingToolChecklist => 'المهام';

  @override
  String get clientMyWeddingToolBudget => 'الميزانية';

  @override
  String get clientMyWeddingToolBudgetOver => 'تجاوز';

  @override
  String get clientMyWeddingToolSaved => 'المفضلة';

  @override
  String get clientMyWeddingToolServices => 'الخدمات';

  @override
  String get clientMyWeddingGuestAction => 'تسجيل الدخول';

  @override
  String get clientMyWeddingSample => 'نموذج';

  @override
  String get clientMyWeddingUpdated => 'آخر تحديث';

  @override
  String get clientMyWeddingDateDiffersLabel => 'تاريخ الحجز';

  @override
  String get clientMyWeddingDateDiffersAction => 'اعتماد التاريخ';

  @override
  String get clientMyWeddingDateUpdated => 'تم تحديث الموعد';

  @override
  String get clientMyWeddingChecklistTitle => 'المهام';

  @override
  String get clientMyWeddingChecklistAdd => 'إضافة مهمة';

  @override
  String clientMyWeddingChecklistProgress(String done, String total) {
    return '$done من $total';
  }

  @override
  String get clientMyWeddingChecklistBandBooking => 'الحجز';

  @override
  String clientMyWeddingChecklistBandMore(String count) {
    return '$count+ أشهر';
  }

  @override
  String clientMyWeddingChecklistBandMonths(String from, String to) {
    return '$from–$to أشهر';
  }

  @override
  String get clientMyWeddingChecklistBandMonth => 'الشهر الأخير';

  @override
  String get clientMyWeddingChecklistBandWeek => 'الأسبوع الأخير';

  @override
  String get clientMyWeddingChecklistBandNoDate => 'لاحقًا';

  @override
  String get clientMyWeddingChecklistBandDone => 'منجزة';

  @override
  String clientMyWeddingChecklistDue(String when) {
    return 'الموعد $when';
  }

  @override
  String clientMyWeddingChecklistOverdue(String when) {
    return 'تأخرت منذ $when';
  }

  @override
  String get clientMyWeddingChecklistAuto => 'تكتمل عند تأكيد الحجز';

  @override
  String clientMyWeddingChecklistBrowseLabel(String task) {
    return '$task: تصفح الخدمات';
  }

  @override
  String clientMyWeddingChecklistViewBookingLabel(String task) {
    return '$task: عرض الحجز';
  }

  @override
  String get clientMyWeddingChecklistEdit => 'تعديل المهمة';

  @override
  String get clientMyWeddingChecklistToastDone => 'تم إنجاز المهمة';

  @override
  String get clientMyWeddingChecklistAllDone => 'اكتملت القائمة';

  @override
  String get clientMyWeddingChecklistEmptyTitle => 'لا موعد بعد';

  @override
  String get clientMyWeddingChecklistEmptyAction => 'تحديد الموعد';

  @override
  String get clientMyWeddingTaskSheetAdd => 'إضافة مهمة';

  @override
  String get clientMyWeddingTaskSheetEdit => 'تعديل المهمة';

  @override
  String get clientMyWeddingTaskTitlePlaceholder => 'المهمة';

  @override
  String get clientMyWeddingTaskTitleError => 'أدخلوا الاسم';

  @override
  String get clientMyWeddingTaskDueLabel => 'الموعد';

  @override
  String get clientMyWeddingTaskCategoryLabel => 'الفئة';

  @override
  String get clientMyWeddingTaskCategoryPlaceholder => 'بلا فئة';

  @override
  String get clientMyWeddingTaskDelete => 'حذف';

  @override
  String get clientMyWeddingTaskAdded => 'تمت الإضافة';

  @override
  String get clientMyWeddingTaskDeleted => 'تم الحذف';

  @override
  String get clientMyWeddingBudgetTitle => 'الميزانية';

  @override
  String get clientMyWeddingBudgetEdit => 'تعديل الميزانية';

  @override
  String get clientMyWeddingBudgetRemaining => 'المتبقي';

  @override
  String get clientMyWeddingBudgetOver => 'تجاوز';

  @override
  String get clientMyWeddingBudgetTotalLabel => 'إجمالي الميزانية';

  @override
  String get clientMyWeddingBudgetPaid => 'المدفوع';

  @override
  String get clientMyWeddingBudgetCommitted => 'المحجوز';

  @override
  String clientMyWeddingBudgetBarLabel(
    String paid,
    String committed,
    String remaining,
  ) {
    return 'المدفوع $paid، المحجوز $committed، المتبقي $remaining';
  }

  @override
  String get clientMyWeddingBudgetAddExpense => 'إضافة مصروف';

  @override
  String clientMyWeddingBudgetAlertSoft(String category, String percent) {
    return '$category $percent';
  }

  @override
  String clientMyWeddingBudgetAlertOver(String category, String amount) {
    return '$category $amount';
  }

  @override
  String get clientMyWeddingBudgetCategories => 'الفئات';

  @override
  String get clientMyWeddingBudgetLedger => 'المدفوعات';

  @override
  String get clientMyWeddingBudgetInfoTitle => 'الكوبون والقاعة';

  @override
  String get clientMyWeddingBudgetInfoBody =>
      'الكوبون تدفعونه في التطبيق. سعر القاعة تدفعونه للقاعة مباشرةً، خارج غزل.';

  @override
  String clientMyWeddingBudgetUsedLabel(String percent) {
    return 'استُهلك $percent';
  }

  @override
  String clientMyWeddingBudgetOverByLabel(String amount) {
    return 'تجاوز الحصة بمقدار $amount';
  }

  @override
  String get clientMyWeddingBudgetLinked => 'مرتبط بحجزكم';

  @override
  String get clientMyWeddingBudgetPlanned => 'مخطط';

  @override
  String get clientMyWeddingBudgetEmptyTitle => 'لا ميزانية بعد';

  @override
  String get clientMyWeddingBudgetEmptyAction => 'تحديد الميزانية';

  @override
  String get clientMyWeddingBudgetAdded => 'تمت الإضافة';

  @override
  String get clientMyWeddingExpenseTitleAdd => 'إضافة مصروف';

  @override
  String get clientMyWeddingExpenseTitleEdit => 'تعديل المصروف';

  @override
  String get clientMyWeddingExpenseAmount => 'المبلغ';

  @override
  String get clientMyWeddingExpenseAmountError => 'أدخلوا المبلغ';

  @override
  String get clientMyWeddingExpenseCategory => 'الفئة';

  @override
  String get clientMyWeddingExpenseNote => 'ملاحظة';

  @override
  String get clientMyWeddingExpenseDate => 'التاريخ';

  @override
  String get clientMyWeddingExpenseStatus => 'حالة الدفع';

  @override
  String get clientMyWeddingExpensePaid => 'مدفوع';

  @override
  String get clientMyWeddingExpensePlanned => 'مخطط';

  @override
  String get clientMyWeddingExpenseDelete => 'حذف';

  @override
  String get clientMyWeddingExpenseDeleteTitle => 'حذف المصروف؟';

  @override
  String get clientMyWeddingExpenseKeep => 'إبقاء';

  @override
  String get clientMyWeddingExpenseSuccessTitle => 'تمت الإضافة';

  @override
  String get clientMyWeddingExpenseOfflineReason => 'يلزم اتصال للحفظ';

  @override
  String get clientMyWeddingExpenseDeleted => 'تم الحذف';

  @override
  String get clientMyWeddingExpenseSampleLabel => 'فنانة حناء';

  @override
  String get clientMyWeddingSetupTitle => 'ميزانيتكم';

  @override
  String get clientMyWeddingSetupTotal => 'الإجمالي';

  @override
  String get clientMyWeddingSetupPresets => 'مبالغ مقترحة';

  @override
  String get clientMyWeddingSetupCategories => 'التوزيع';

  @override
  String get clientMyWeddingSetupVenueReference => 'نطاق القاعة والضيافة لديكم';

  @override
  String get clientMyWeddingSetupUnallocated => 'المتبقي';

  @override
  String get clientMyWeddingSetupOver => 'فوق الإجمالي';

  @override
  String clientMyWeddingSetupAlertSoft(String percent) {
    return 'تنبيه عند $percent';
  }

  @override
  String clientMyWeddingSetupAlertHard(String percent) {
    return 'تنبيه عند $percent';
  }

  @override
  String get clientMyWeddingSetupError => 'تعذّر الحفظ';

  @override
  String get clientMyWeddingSetupErrorDetail =>
      'تعذّر حفظ الميزانية. لم يتم تغيير أي شيء.';

  @override
  String get clientMyWeddingSetupSaved => 'تم الحفظ';

  @override
  String get clientMyWeddingCatVenueCatering => 'القاعة';

  @override
  String get clientMyWeddingCatPhotoVideo => 'التصوير';

  @override
  String get clientMyWeddingCatFlowersDecor => 'الزهور';

  @override
  String get clientMyWeddingCatAttire => 'الأزياء';

  @override
  String get clientMyWeddingCatMakeupHenna => 'المكياج';

  @override
  String get clientMyWeddingCatCars => 'السيارات';

  @override
  String get clientMyWeddingCatInvitations => 'الدعوات';

  @override
  String get clientMyWeddingCatMusic => 'الموسيقى';

  @override
  String get clientMyWeddingCatHoneymoon => 'شهر العسل';

  @override
  String get clientOnboardingAltLanguage =>
      'منصة عرس تحيط بها أقواس من الورود والخضرة وأقمشة وردية وبيضاء مع طاولة زهور طويلة في المقدمة';

  @override
  String clientOnboardingStepProgress(num current, num total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'الخطوة ⁦$currentString⁩ من ⁦$totalString⁩';
  }

  @override
  String get clientOnboardingLanguageTitle => 'اختيار اللغة';

  @override
  String get clientOnboardingLanguageGroup => 'لغة التطبيق';

  @override
  String get clientOnboardingLanguageSignIn => 'دخول';

  @override
  String get clientOnboardingLanguageSignInOffline =>
      'الدخول يحتاج إلى اتصال بالإنترنت.';

  @override
  String get clientOnboardingIntroLabel => 'تعريف سريع';

  @override
  String get clientOnboardingIntroSlide1Title => 'مقارنة ثلاث قاعات';

  @override
  String get clientOnboardingIntroSlide2Title => 'التواريخ المتاحة';

  @override
  String get clientOnboardingIntroSlide3Title => 'كوبون بسعر أقل';

  @override
  String get clientOnboardingIntroStart => 'البدء';

  @override
  String get clientOnboardingInfoTitle => 'إجاباتكم';

  @override
  String get clientOnboardingInfoBody =>
      'كلها اختيارية، وتبقى على هذا الجهاز إلى حين التسجيل. يمكن تعديلها في أي وقت من حسابكم.';

  @override
  String get clientOnboardingAboutTitle => 'من يخطط؟';

  @override
  String get clientOnboardingAboutRoleLabel => 'الصفة';

  @override
  String get clientOnboardingAboutRoleBride => 'العروس';

  @override
  String get clientOnboardingAboutRoleGroom => 'العريس';

  @override
  String get clientOnboardingAboutRoleFamily => 'العائلة';

  @override
  String get clientOnboardingAboutRolePlanner => 'المنسّق';

  @override
  String get clientOnboardingAboutNameLabel => 'الاسم';

  @override
  String get clientOnboardingAboutPartnerDefault => 'اسم الشريك';

  @override
  String get clientOnboardingAboutPartnerGroom => 'اسم العريس';

  @override
  String get clientOnboardingAboutPartnerBride => 'اسم العروس';

  @override
  String get clientOnboardingAboutPartnerCouple => 'اسما العروسين';

  @override
  String get clientOnboardingAboutMonogram => 'معاينة الحرف الأول';

  @override
  String get clientOnboardingDateTitle => 'موعد الزفاف';

  @override
  String get clientOnboardingDateOccasions => 'مناسبات هذا الشهر';

  @override
  String clientOnboardingDateOccasionOne(String name, String date) {
    return '$name · $date';
  }

  @override
  String clientOnboardingDateOccasionRange(
    String name,
    String from,
    String to,
  ) {
    return '$name · من $from إلى $to';
  }

  @override
  String get clientOnboardingDateNotDecided => 'لم نحدد';

  @override
  String get clientOnboardingDateFlexible => 'مرن';

  @override
  String get clientOnboardingDateFlexibleTitle => 'شهر مرن';

  @override
  String get clientOnboardingDatePickDate => 'اختيار تاريخ';

  @override
  String get clientOnboardingDateMonthsLabel => 'الأشهر';

  @override
  String get clientOnboardingGuestsTitle => 'الضيوف والميزانية';

  @override
  String get clientOnboardingGuestsSection => 'الضيوف';

  @override
  String get clientOnboardingGuestsExpected => 'عدد الضيوف المتوقع';

  @override
  String get clientOnboardingGuestsPresets => 'أعداد شائعة للضيوف';

  @override
  String clientOnboardingGuestsPresetMax(String count) {
    return '$count+';
  }

  @override
  String get clientOnboardingGuestsSplitTitle => 'نسائي ورجالي';

  @override
  String get clientOnboardingGuestsSplitLabel => 'حفل نسائي وحفل رجالي منفصلان';

  @override
  String get clientOnboardingGuestsLadies => 'الحفل النسائي';

  @override
  String get clientOnboardingGuestsMen => 'الحفل الرجالي';

  @override
  String get clientOnboardingBudgetSection => 'القاعة والضيافة';

  @override
  String get clientOnboardingBudgetBands => 'شرائح الميزانية';

  @override
  String clientOnboardingBudgetUnder(String amount) {
    return 'أقل من $amount';
  }

  @override
  String clientOnboardingBudgetAbove(String amount) {
    return '$amount فأكثر';
  }

  @override
  String get clientOnboardingBudgetRange => 'نطاق ميزانية مخصص';

  @override
  String get clientOnboardingSkipHalf => 'لاحقًا';

  @override
  String get clientOnboardingAreasTitle => 'المناطق';

  @override
  String get clientOnboardingAreasSearch => 'البحث عن منطقة';

  @override
  String clientOnboardingAreasSelected(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ منطقة محددة',
      many: '⁦$countString⁩ منطقة محددة',
      few: '⁦$countString⁩ مناطق محددة',
      two: 'منطقتان محددتان',
      one: 'منطقة واحدة محددة',
      zero: 'لم تُحدد مناطق',
    );
    return '$_temp0';
  }

  @override
  String get clientOnboardingAreasDemoQuery => 'مشر';

  @override
  String clientOnboardingAreasMore(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ منطقة أخرى',
      many: '⁦$countString⁩ منطقة أخرى',
      few: '⁦$countString⁩ مناطق أخرى',
      two: 'منطقتان أخريان',
      one: 'منطقة أخرى',
      zero: 'لا مناطق أخرى',
    );
    return '$_temp0';
  }

  @override
  String get clientOnboardingAreasNoHallsNote =>
      'لا قاعات هنا. تظهر كل القاعات.';

  @override
  String get clientPaymentTopTitle => 'الدفع';

  @override
  String clientPaymentSave(String amount) {
    return 'توفير $amount';
  }

  @override
  String get clientPaymentLabelHall => 'القاعة';

  @override
  String get clientPaymentLabelPackage => 'الباقة';

  @override
  String get clientPaymentLabelDate => 'التاريخ';

  @override
  String get clientPaymentLabelGuests => 'الضيوف';

  @override
  String get clientPaymentLabelOpenUntil => 'مفتوحة حتى';

  @override
  String get clientPaymentLabelSaving => 'التوفير';

  @override
  String get clientPaymentLabelAmount => 'المبلغ';

  @override
  String get clientPaymentLabelMethod => 'الطريقة';

  @override
  String get clientPaymentLabelVoucherFor => 'كوبون لدى';

  @override
  String get clientPaymentAmountLabel => 'كوبون غزل، دفعة واحدة';

  @override
  String clientPaymentTimerSr(String time) {
    return 'الوقت المتبقي: $time';
  }

  @override
  String get clientPaymentMethodsTitle => 'طريقة الدفع';

  @override
  String get clientPaymentMethodsLabel => 'طريقة الدفع';

  @override
  String get clientPaymentMethodKnet => 'KNET';

  @override
  String get clientPaymentMethodApplePay => 'آبل باي';

  @override
  String get clientPaymentMethodGooglePay => 'جوجل باي';

  @override
  String get clientPaymentMethodCard => 'فيزا أو ماستركارد';

  @override
  String get clientPaymentMethodCardShort => 'بطاقة';

  @override
  String get clientPaymentMethodSuggested => 'مقترحة';

  @override
  String get clientPaymentSecureTitle => 'دفع آمن';

  @override
  String get clientPaymentHonestKnet =>
      'يفتح كي نت صفحة البنك الآمنة ويعمل ببطاقات البنوك الكويتية فقط.';

  @override
  String get clientPaymentHonestWallet =>
      'تؤكدون الدفع من جهازكم، ولا تطّلع غزل على بيانات بطاقتكم أبدًا.';

  @override
  String get clientPaymentHonestCard =>
      'تُدخلون بيانات البطاقة في صفحة مزوّد الدفع الآمنة، ولا تطّلع عليها غزل ولا تحفظها.';

  @override
  String get clientPaymentCtaPay => 'الدفع الآن';

  @override
  String get clientPaymentTermPrice => 'سعر الكوبون';

  @override
  String get clientPaymentTermDirect => 'دفع مباشر';

  @override
  String get clientPaymentTermReturns => 'يعود الكوبون';

  @override
  String get clientPaymentHowLink => 'كيف يعمل الكوبون';

  @override
  String get clientPaymentHasVoucherBanner => 'الكوبون لديكم';

  @override
  String get clientPaymentSessionErrorTitle => 'تعذّر بدء الدفع';

  @override
  String get clientPaymentSessionError => 'تعذّر بدء الدفع. لم يُخصم أي مبلغ.';

  @override
  String get clientPaymentExpiredBanner => 'انتهت الجلسة';

  @override
  String get clientPaymentCancelledToast => 'إلغاء بلا خصم';

  @override
  String get clientPaymentGatewayTitle => 'دفع آمن';

  @override
  String get clientPaymentGatewayBack => 'إغلاق الدفع';

  @override
  String get clientPaymentLeaveTitle => 'مغادرة الدفع؟';

  @override
  String get clientPaymentLeaveBody => 'لم يُخصم بعد';

  @override
  String get clientPaymentLeaveConfirm => 'مغادرة';

  @override
  String get clientPaymentLeaveStay => 'البقاء';

  @override
  String get clientPaymentRedirectTitle => 'فتح الصفحة الآمنة';

  @override
  String get clientPaymentRedirectBody =>
      'ستُكملون الدفع في صفحة آمنة، ولا يُخصم أي مبلغ قبل ذلك.';

  @override
  String get clientPaymentRedirectPrivacy =>
      'لا تطّلع غزل على رقم البطاقة أو الرقم السري.';

  @override
  String get clientPaymentReturnedTitle => 'جارٍ التحقق';

  @override
  String get clientPaymentLostTitle => 'انقطع الاتصال';

  @override
  String get clientPaymentLostBody =>
      'نتحقق من دفعتكم، ولا حاجة للدفع مرة أخرى.';

  @override
  String get clientPaymentCancelTitle => 'إلغاء الدفع';

  @override
  String get clientPaymentNotCharged => 'لم يُخصم';

  @override
  String get clientPaymentNotChargedLabel => 'حالة الخصم';

  @override
  String get clientPaymentReceivedLabel => 'استلام الدفع';

  @override
  String get clientPaymentBankNote => 'صفحة البنك';

  @override
  String get clientPaymentCardPageNote => 'صفحة البطاقة';

  @override
  String get clientPaymentBankBank => 'البنك';

  @override
  String get clientPaymentBankCard => 'رقم البطاقة';

  @override
  String get clientPaymentBankExpiry => 'الانتهاء';

  @override
  String get clientPaymentBankPin => 'الرقم السري';

  @override
  String get clientPaymentBankItemName => 'كوبون غزل';

  @override
  String get clientPaymentBankSubmit => 'إرسال';

  @override
  String get clientPaymentCardHolder => 'الاسم';

  @override
  String get clientPaymentCardCvv => 'رمز الأمان';

  @override
  String get clientPaymentProtoLabel => 'تجريبي';

  @override
  String get clientPaymentProtoApproved => 'مقبولة';

  @override
  String get clientPaymentProtoDeclined => 'مرفوضة';

  @override
  String get clientPaymentProtoSlow => 'بطيئة';

  @override
  String get clientPaymentProtoLost => 'منقطعة';

  @override
  String get clientPaymentProtoLate => 'متأخرة';

  @override
  String get clientPaymentConfirmTitle => 'جارٍ التأكيد';

  @override
  String get clientPaymentConfirmLongTitle => 'التأكيد مستمر';

  @override
  String get clientPaymentConfirmNotify => 'سنُعلمكم';

  @override
  String get clientPaymentConfirmNotifyLabel => 'إشعار';

  @override
  String get clientPaymentConfirmKeep => 'متابعة الانتظار';

  @override
  String get clientPaymentConfirmLeave => 'مغادرة';

  @override
  String get clientPaymentConfirmOffline =>
      'لا يوجد اتصال. نؤكد دفعتكم وسنُعلمكم فور اكتمال التأكيد.';

  @override
  String get clientPaymentConfirmSuccessTitle => 'استلمنا الدفع';

  @override
  String get clientPaymentConfirmProgress => 'جارٍ التحقق';

  @override
  String get clientPaymentViewVoucher => 'عرض الكوبون';

  @override
  String get clientPaymentFailTitleExpired => 'انتهت الجلسة';

  @override
  String get clientPaymentFailTitleLate => 'الكوبون جاهز';

  @override
  String get clientPaymentFailBodyDeclined =>
      'لم يقبل البنك العملية. يمكنكم المحاولة مجددًا أو اختيار طريقة دفع أخرى.';

  @override
  String get clientPaymentFailBodyCancelled =>
      'غادرتم صفحة الدفع قبل اكتمالها.';

  @override
  String clientPaymentFailBodyExpired(String time, String minutes) {
    return 'انتهت جلسة دفع هذا الكوبون في $time، بعد $minutes. يمكنكم البدء من جديد بنفس العرض.';
  }

  @override
  String get clientPaymentFailBodyLate =>
      'وصلت دفعتكم بعد انتهاء جلسة الدفع، وقد اعتمدناها. الكوبون أصبح لكم.';

  @override
  String get clientPaymentFailBodyOffline =>
      'أعيدوا الاتصال للمحاولة مجددًا. لا يُخصم أي مبلغ قبل اكتمال الدفع.';

  @override
  String get clientPaymentFailAnother => 'طريقة أخرى';

  @override
  String get clientPaymentFailStartAgain => 'إعادة البدء';

  @override
  String get clientPaymentSupport => 'الدعم';

  @override
  String get clientPaymentDoneTitle => 'الكوبون جاهز';

  @override
  String get clientPaymentDoneLate => 'وصلت الدفعة متأخرة';

  @override
  String get clientPaymentDoneLateNote =>
      'وصلت دفعتكم بعد انتهاء جلسة الدفع. الكوبون مفعّل ومرتبط بالتاريخ المعروض.';

  @override
  String get clientPaymentDoneReuse =>
      'إذا اعتُذر عن الطلب أو لم يصل رد، يعود الكوبون إليكم.';

  @override
  String get clientPaymentDoneCta => 'إرسال الطلب';

  @override
  String get clientPaymentDoneRowVouchers => 'كوبوناتي';

  @override
  String get clientPaymentDoneRowReceipt => 'الإيصال';

  @override
  String get clientPaymentTermsTitle => 'شروط الكوبون';

  @override
  String get clientPaymentTermsLabel => 'شروط الكوبون';

  @override
  String get clientPlannerOfferTitle => 'تحتاجون منسّقة؟';

  @override
  String get clientPlannerTitle => 'التنسيق';

  @override
  String get clientPlannerCompareTitle => 'مقارنة';

  @override
  String get clientPlannerCompareLabel => 'مقارنة الباقات';

  @override
  String get clientPlannerTierPickerLabel => 'الباقة';

  @override
  String get clientPlannerFromPrefix => 'من';

  @override
  String clientPlannerMarks(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ علامة خيط',
      many: '⁦$countString⁩ علامة خيط',
      few: '⁦$countString⁩ علامات خيط',
      two: 'علامتا خيط',
      one: 'علامة خيط واحدة',
      zero: 'بلا علامات',
    );
    return '$_temp0';
  }

  @override
  String clientPlannerCompareChoose(String name) {
    return 'اختيار $name';
  }

  @override
  String clientPlannerCompareChosen(String name) {
    return '$name، تم الاختيار';
  }

  @override
  String get clientPlannerIncluded => 'مشمول';

  @override
  String get clientPlannerNotIncluded => 'غير مشمول';

  @override
  String get clientPlannerIncludedLabel => 'ما تشمله الباقة';

  @override
  String get clientPlannerEverythingIn => 'كل ما في';

  @override
  String get clientPlannerIncSilver0 => 'منسّقة الحفل';

  @override
  String get clientPlannerIncSilver1 => 'جدول الحفل';

  @override
  String get clientPlannerIncSilver2 => 'متابعة الموردين';

  @override
  String get clientPlannerIncSilver3 => 'جولة القاعة';

  @override
  String get clientPlannerIncGold0 => 'تخطيط منذ الحجز';

  @override
  String get clientPlannerIncGold1 => 'موردون وعروض';

  @override
  String get clientPlannerIncGold2 => 'فكرة التنسيق';

  @override
  String get clientPlannerIncGold3 => 'اجتماعان';

  @override
  String get clientPlannerIncRoyal0 => 'كوشة مخصصة';

  @override
  String get clientPlannerIncRoyal1 => 'إدارة الإنتاج';

  @override
  String get clientPlannerIncRoyal2 => 'عقود الموردين';

  @override
  String get clientPlannerIncRoyal3 => 'فريق مخصص';

  @override
  String get clientPlannerWeddingLabel => 'زفافكم';

  @override
  String get clientPlannerPriceInfoTitle => 'السعر';

  @override
  String get clientPlannerPriceInfo =>
      'السعر النهائي يُتفق عليه مع المنسّقة بعد الاستشارة. لا دفع الآن.';

  @override
  String get clientPlannerRequestConsultation => 'طلب استشارة';

  @override
  String get clientPlannerNotNowToast => 'متاحة دائمًا في زفافكم';

  @override
  String get clientPlannerOtherPlanners => 'منسّقون آخرون';

  @override
  String get clientPlannerGuestSignIn => 'تسجيل الدخول';

  @override
  String get clientPlannerRetryToast => 'تعذّر الاتصال';

  @override
  String get clientPlannerRequestTitle => 'استشارة';

  @override
  String get clientPlannerRequestChange => 'تغيير الباقة';

  @override
  String get clientPlannerRequestTimesTitle => 'الأوقات';

  @override
  String get clientPlannerRequestDayLabel => 'اليوم';

  @override
  String clientPlannerRequestWindowLabel(String day) {
    return 'فترات يوم $day';
  }

  @override
  String clientPlannerRequestDayWithChoices(String day, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ فترة',
      many: '⁦$countString⁩ فترة',
      few: '⁦$countString⁩ فترات',
      two: 'فترتان',
      one: 'فترة واحدة',
      zero: 'بلا فترات',
    );
    return '$day، $_temp0';
  }

  @override
  String get clientPlannerRequestWindowMorning => 'صباحًا';

  @override
  String get clientPlannerRequestWindowAfternoon => 'عصرًا';

  @override
  String get clientPlannerRequestWindowEvening => 'مساءً';

  @override
  String get clientPlannerRequestWindowsError => 'اختاروا فترة';

  @override
  String get clientPlannerRequestReachLabel => 'التواصل';

  @override
  String get clientPlannerRequestReachChat => 'محادثة';

  @override
  String get clientPlannerRequestReachWhatsapp => 'واتساب';

  @override
  String get clientPlannerRequestReachPhone => 'اتصال';

  @override
  String get clientPlannerRequestNotesLabel => 'ملاحظات';

  @override
  String get clientPlannerRequestSend => 'إرسال الطلب';

  @override
  String get clientPlannerRequestSuccessTitle => 'تم الإرسال';

  @override
  String get clientPlannerRequestSentToast => 'سنخبركم هنا';

  @override
  String get clientPlannerRequestOpenTitle => 'طلب مفتوح';

  @override
  String get clientPlannerViewRequest => 'عرض الطلب';

  @override
  String get clientPlannerStatusTitle => 'منسّقتكم';

  @override
  String get clientPlannerStatusHeadWaiting => 'نختار منسّقتكم';

  @override
  String get clientPlannerStatusThreadLabel => 'مراحل الطلب';

  @override
  String get clientPlannerStatusStepRequested => 'الطلب';

  @override
  String get clientPlannerStatusStepAssigned => 'المنسّقة';

  @override
  String get clientPlannerStatusStepMeeting => 'الموعد';

  @override
  String get clientPlannerStatusCancelTitle => 'إلغاء الطلب؟';

  @override
  String get clientPlannerStatusCancelBody => 'لن تخسروا شيئًا.';

  @override
  String get clientPlannerStatusCancelConfirm => 'إلغاء الطلب';

  @override
  String get clientPlannerStatusCancelKeep => 'إبقاء';

  @override
  String get clientPlannerStatusCancelledToast => 'تم الإلغاء';

  @override
  String get clientPlannerStatusSchedule => 'تحديد موعد';

  @override
  String clientPlannerStatusMessageName(String name) {
    return 'مراسلة $name';
  }

  @override
  String get clientPlannerStatusMeetingLabel => 'الاجتماع القادم';

  @override
  String get clientPlannerStatusAddToCalendar => 'إضافة إلى التقويم';

  @override
  String get clientPlannerStatusCalendarToast => 'تمت الإضافة للتقويم';

  @override
  String clientPlannerStatusAssignedToast(String name) {
    return '$name منسّقتكم';
  }

  @override
  String get clientPlannerTypeVideo => 'فيديو';

  @override
  String get clientPlannerTypePhone => 'اتصال';

  @override
  String get clientPlannerTypeVideoName => 'مكالمة فيديو';

  @override
  String get clientPlannerTypePhoneName => 'مكالمة هاتفية';

  @override
  String get clientPlannerMeetingTitle => 'تحديد موعد';

  @override
  String get clientPlannerMeetingDayLabel => 'اليوم';

  @override
  String get clientPlannerMeetingTimeLabel => 'الوقت';

  @override
  String get clientPlannerMeetingTypeLabel => 'نوع الاجتماع';

  @override
  String clientPlannerMeetingDayNoSlots(String day) {
    return '$day، لا مواعيد متاحة';
  }

  @override
  String get clientPlannerMeetingConfirm => 'تأكيد';

  @override
  String get clientPlannerMeetingNoSlotsTitle => 'لا مواعيد متاحة';

  @override
  String get clientPlannerMeetingTaken => 'الوقت محجوز';

  @override
  String get clientPlannerMeetingSuccessTitle => 'الموعد مؤكد';

  @override
  String get clientPlannerMeetingCalendar => 'التقويم';

  @override
  String clientProfileSharedVersion(String version) {
    return '$version';
  }

  @override
  String get clientProfileSharedOn => 'مفعّل';

  @override
  String get clientProfileSharedOff => 'متوقف';

  @override
  String get clientProfileSharedKeep => 'إبقاء الحساب';

  @override
  String get clientProfileSharedSupport => 'الدعم';

  @override
  String get clientProfileSharedTerms => 'الشروط';

  @override
  String get clientProfileSharedPrivacy => 'الخصوصية';

  @override
  String get clientProfileSharedSignIn => 'تسجيل الدخول';

  @override
  String get clientProfileSharedSignOut => 'تسجيل الخروج';

  @override
  String get clientProfileSharedSignOutTitle => 'تسجيل الخروج؟';

  @override
  String get clientProfileSharedSignOutStay => 'البقاء';

  @override
  String get clientProfileSharedSignedOut => 'تم الخروج';

  @override
  String get clientProfileSharedOpeningSettings => 'فتح الإعدادات';

  @override
  String get clientProfileSharedSaveFailed => 'تعذّر الحفظ';

  @override
  String get clientProfileHubTitle => 'حسابكم';

  @override
  String get clientProfileHubAccount => 'الحساب';

  @override
  String get clientProfileHubVerified => 'موثّق';

  @override
  String get clientProfileHubRowWedding => 'الزفاف';

  @override
  String get clientProfileHubRowBookings => 'الحجوزات';

  @override
  String get clientProfileHubRowVouchers => 'كوبوناتي';

  @override
  String get clientProfileHubRowVisits => 'الزيارات';

  @override
  String get clientProfileHubRowReceipts => 'الإيصالات';

  @override
  String get clientProfileHubRowSaved => 'المفضلة';

  @override
  String get clientProfileHubRowPersonal => 'البيانات الشخصية';

  @override
  String get clientProfileHubRowNotifications => 'الإشعارات';

  @override
  String get clientProfileHubCountPaid => 'المدفوع';

  @override
  String get clientProfileHubCountReady => 'جاهز';

  @override
  String get clientProfileHubCountUpcoming => 'قادمة';

  @override
  String get clientProfileHubCountHalls => 'القاعات';

  @override
  String get clientProfileDigitsTitle => 'الأرقام';

  @override
  String get clientProfileLegalTitle => 'الشروط والخصوصية';

  @override
  String get clientProfileWedTitle => 'بيانات الزفاف';

  @override
  String get clientProfileWedRole => 'الصفة';

  @override
  String get clientProfileWedRoleBride => 'العروس';

  @override
  String get clientProfileWedRoleGroom => 'العريس';

  @override
  String get clientProfileWedRoleFamily => 'العائلة';

  @override
  String get clientProfileWedRolePlanner => 'منسّق أعراس';

  @override
  String get clientProfileWedName => 'اسمكم';

  @override
  String get clientProfileWedPartnerDefault => 'اسم الشريك';

  @override
  String get clientProfileWedPartnerGroom => 'اسم العريس';

  @override
  String get clientProfileWedPartnerBride => 'اسم العروس';

  @override
  String get clientProfileWedPartnerCouple => 'اسما العروسين';

  @override
  String get clientProfileWedDate => 'موعد الزفاف';

  @override
  String get clientProfileWedCountdown => 'الأيام المتبقية';

  @override
  String clientProfileWedDaysUnit(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يوم',
      many: 'يومًا',
      few: 'أيام',
      two: 'يومان',
      one: 'يوم',
      zero: 'يوم',
    );
    return '$_temp0';
  }

  @override
  String get clientProfileWedGuests => 'الضيوف';

  @override
  String get clientProfileWedLadies => 'نسائي';

  @override
  String get clientProfileWedMen => 'رجالي';

  @override
  String get clientProfileWedBudget => 'القاعة والضيافة';

  @override
  String get clientProfileWedAreas => 'المناطق';

  @override
  String get clientProfileWedTotal => 'الميزانية الكاملة';

  @override
  String get clientProfileWedDiffersAction => 'اعتماد التاريخ';

  @override
  String get clientProfileWedDateUpdated => 'تم التحديث';

  @override
  String get clientProfilePersTitle => 'البيانات الشخصية';

  @override
  String get clientProfilePersName => 'الاسم';

  @override
  String get clientProfilePersNameError => 'أضيفوا اسمكم';

  @override
  String get clientProfilePersMonogram => 'الحرف الأول';

  @override
  String get clientProfilePersEmail => 'البريد';

  @override
  String get clientProfilePersEmailError => 'راجعوا البريد';

  @override
  String get clientProfilePersPhone => 'الجوال';

  @override
  String get clientProfilePersPhoneChange => 'تغيير';

  @override
  String get clientProfilePersPhoneNote =>
      'لا يظهر رقمكم للقاعات ومزوّدي الخدمات إلا في الطلبات التي ترسلونها إليهم.';

  @override
  String get clientProfilePersPhoneNoteTitle => 'رقمكم';

  @override
  String get clientProfilePersMethods => 'الدخول';

  @override
  String get clientProfilePersMethodWhatsapp => 'واتساب';

  @override
  String get clientProfilePersMethodApple => 'آبل';

  @override
  String get clientProfilePersMethodGoogle => 'جوجل';

  @override
  String get clientProfilePersMethodHidden => 'بريد مخفي';

  @override
  String get clientProfilePersMethodLinked => 'مرتبط';

  @override
  String get clientProfilePersMethodNotLinked => 'غير مرتبط';

  @override
  String get clientProfilePhoneTitle => 'تغيير الرقم';

  @override
  String get clientProfilePhoneNew => 'الرقم الجديد';

  @override
  String get clientProfilePhoneSend => 'إرسال الرمز';

  @override
  String clientProfilePhoneErrorDigits(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ رقم',
      many: '⁦$countString⁩ رقمًا',
      few: '⁦$countString⁩ أرقام',
      two: 'رقمان',
      one: 'رقم واحد',
      zero: 'لا أرقام',
    );
    return 'يلزم $_temp0';
  }

  @override
  String get clientProfilePhoneDone => 'تم التحديث';

  @override
  String get clientProfileNotifTitle => 'الإشعارات';

  @override
  String get clientProfileNotifDenied => 'متوقفة في الهاتف';

  @override
  String get clientProfileNotifGroupAlways => 'تصلكم دائمًا';

  @override
  String get clientProfileNotifRequests => 'الطلبات';

  @override
  String get clientProfileNotifVouchers => 'الكوبونات';

  @override
  String get clientProfileNotifVisits => 'الزيارات';

  @override
  String get clientProfileNotifGroupReminders => 'التذكيرات';

  @override
  String get clientProfileNotifConfirm => 'تأكيد الطلب';

  @override
  String get clientProfileNotifConfirmFact => 'مهلة التأكيد';

  @override
  String get clientProfileNotifVisitReminders => 'الزيارة';

  @override
  String get clientProfileNotifVoucherExpiry => 'انتهاء الكوبون';

  @override
  String get clientProfileNotifMilestones => 'العد التنازلي';

  @override
  String get clientProfileNotifGroupMarketing => 'العروض والأخبار';

  @override
  String get clientProfileNotifOffers => 'عروض القاعات';

  @override
  String get clientProfileNotifPriceDrops => 'انخفاض الأسعار';

  @override
  String get clientProfileNotifNewVenues => 'قاعات جديدة';

  @override
  String get clientProfileNotifFrequencyTitle => 'التكرار';

  @override
  String clientProfileNotifFrequency(int count, int days) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ رسالة',
      many: '⁦$countString⁩ رسالة',
      few: '⁦$countString⁩ رسائل',
      two: 'رسالتين',
      one: 'رسالة واحدة',
      zero: 'لا رسائل',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '⁦$daysString⁩ يوم',
      many: '⁦$daysString⁩ يومًا',
      few: '⁦$daysString⁩ أيام',
      two: 'يومين',
      one: 'يوم',
      zero: 'لا أيام',
    );
    return 'بحد أقصى $_temp0 في الأسبوع، ولا رسائل خلال آخر $_temp1 قبل الزفاف.';
  }

  @override
  String get clientProfileNotifChannels => 'طريقة الإرسال';

  @override
  String get clientProfileNotifChannelPush => 'التطبيق';

  @override
  String get clientProfileNotifChannelWhatsapp => 'واتساب';

  @override
  String get clientProfileNotifChannelEmail => 'البريد';

  @override
  String get clientProfileNotifChannelEmailAdd => 'إضافة بريد';

  @override
  String get clientProfileNotifQuiet => 'ساعات الهدوء';

  @override
  String get clientProfileNotifQuietOffers => 'العروض';

  @override
  String get clientProfileNotifQuietAlerts => 'التنبيهات';

  @override
  String get clientProfileNotifPhone => 'الهاتف';

  @override
  String clientProfileSetBiometric(String method) {
    String _temp0 = intl.Intl.selectLogic(method, {
      'face': 'بصمة الوجه',
      'touch': 'بصمة الإصبع',
      'other': 'بصمة الإصبع',
    });
    return '$_temp0';
  }

  @override
  String get clientProfileSetBiometricHint => 'فعّلوها من إعدادات الهاتف';

  @override
  String get clientProfileSetBiometricOff => 'تم الإيقاف';

  @override
  String get clientProfileSetLocation => 'الموقع';

  @override
  String get clientProfileSetLocationValue => 'أثناء الاستخدام';

  @override
  String get clientProfileSetUsage => 'بيانات الاستخدام';

  @override
  String get clientProfileSetUsageDetail => 'لتحسين غزل، دون أي بيانات دفع.';

  @override
  String get clientProfileDelTitle => 'حذف الحساب';

  @override
  String get clientProfileDelItemData => 'البيانات الشخصية';

  @override
  String get clientProfileDelItemPlans => 'الخطط';

  @override
  String get clientProfileDelOutAnonymised => 'مجهولة الهوية';

  @override
  String get clientProfileDelOutKept => 'محفوظة';

  @override
  String get clientProfileDelOutRemoved => 'محذوفة';

  @override
  String get clientProfileDelOutWithdrawn => 'مسحوب';

  @override
  String get clientProfileDelDetailTitle => 'ماذا سيحدث';

  @override
  String get clientProfileDelSheetData =>
      'تصبح بياناتكم الشخصية مجهولة الهوية.';

  @override
  String get clientProfileDelSheetReceipts =>
      'تُحفظ إيصالات الكوبون والسجلات المحاسبية كما يقتضي القانون.';

  @override
  String get clientProfileDelSheetSaved =>
      'تُحذف المفضلة وقائمة المهام والميزانية.';

  @override
  String get clientProfileDelSheetApple => 'يُلغى الدخول عبر آبل.';

  @override
  String clientProfileDelSheetRequest(String venue) {
    return 'سيُسحب طلبكم المعلّق إلى $venue، وينتهي كوبونه مع حذف الحساب.';
  }

  @override
  String clientProfileDelVoucher(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ كوبون جاهز',
      many: '⁦$countString⁩ كوبونًا جاهزًا',
      few: '⁦$countString⁩ كوبونات جاهزة',
      two: 'كوبونان جاهزان',
      one: 'كوبون جاهز',
      zero: 'لا كوبونات جاهزة',
    );
    return '$_temp0';
  }

  @override
  String get clientProfileDelVoucherRefund => 'استخدموه';

  @override
  String clientProfileDelVoucherDetailRefund(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'لديكم ⁦$countString⁩ كوبون جاهز. استخدموها أولًا، فبعد حذف الحساب تنتهي ولا تعود.',
      many:
          'لديكم ⁦$countString⁩ كوبونًا جاهزًا. استخدموها أولًا، فبعد حذف الحساب تنتهي ولا تعود.',
      few:
          'لديكم ⁦$countString⁩ كوبونات جاهزة. استخدموها أولًا، فبعد حذف الحساب تنتهي ولا تعود.',
      two: 'لديكم كوبونان جاهزان. استخدموهما أولًا، فبعد حذف الحساب ينتهيان ولا يعودان.',
      one: 'لديكم كوبون جاهز. استخدموه أولًا، فبعد حذف الحساب ينتهي ولا يعود.',
      zero: 'لا كوبونات جاهزة.',
    );
    return '$_temp0';
  }

  @override
  String clientProfileDelVoucherDetailEnds(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'لديكم ⁦$countString⁩ كوبون جاهز، وتنتهي مع حذف الحساب. استخدموها أولًا إن كنتم تحتاجونها.',
      many:
          'لديكم ⁦$countString⁩ كوبونًا جاهزًا، وتنتهي مع حذف الحساب. استخدموها أولًا إن كنتم تحتاجونها.',
      few:
          'لديكم ⁦$countString⁩ كوبونات جاهزة، وتنتهي مع حذف الحساب. استخدموها أولًا إن كنتم تحتاجونها.',
      two: 'لديكم كوبونان جاهزان، وينتهيان مع حذف الحساب. استخدماهما أولًا إن كنتم تحتاجونهما.',
      one: 'لديكم كوبون جاهز، وينتهي مع حذف الحساب. استخدموه أولًا إن كنتم تحتاجونه.',
      zero: 'لا كوبونات جاهزة.',
    );
    return '$_temp0';
  }

  @override
  String get clientProfileDelUndone => 'لا يمكن التراجع';

  @override
  String get clientProfileDelDeleting => 'جارٍ الحذف';

  @override
  String get clientProfileDelSuccessTitle => 'الحساب محذوف';

  @override
  String get clientProfileDelSuccessDetail =>
      'أصبحت بياناتكم الشخصية مجهولة الهوية، وتبقى الإيصالات محفوظة كما يقتضي القانون. يمكنكم إنشاء حساب جديد في أي وقت.';

  @override
  String get clientProfileDelErrorTitle => 'تعذّر الحذف';

  @override
  String get clientProfileDelErrorDetail =>
      'لم يتغيّر شيء. حاولوا مجددًا أو راسلوا الدعم.';

  @override
  String get clientProfileDelBlockedTitle => 'الحذف متوقف';

  @override
  String clientProfileDelBlockedDetail(String venue, String date) {
    return 'حذف الحساب متوقف مؤقتًا لأن حجزكم في $venue بتاريخ $date مؤكد. يمكنكم إلغاؤه، أو طلب الحذف بعد تاريخ الحفل.';
  }

  @override
  String clientProfileDelBlockedApprovedDetail(String venue) {
    return 'حذف الحساب متوقف مؤقتًا لأن $venue وافق على طلبكم وينتظر تأكيدكم. أكّدوا الطلب أو ألغوه أولًا.';
  }

  @override
  String get clientProfileDelBlockedSchedule => 'جدولة الحذف';

  @override
  String get clientProfileDelBlockedOpen => 'فتح الطلب';

  @override
  String get clientProfileDelBlockedCancel => 'إلغاء الحجز';

  @override
  String get clientProfileDelBlockedCancelRequest => 'إلغاء الطلب';

  @override
  String get clientProfileDelScheduledTitle => 'الحذف مجدول';

  @override
  String get clientProfileDelScheduledCancel => 'إلغاء الحذف';

  @override
  String get clientProfileDelScheduledCancelled => 'الحذف ملغى';

  @override
  String clientReviewsRewardsStarCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ نجمة',
      many: '⁦$countString⁩ نجمة',
      few: '⁦$countString⁩ نجوم',
      two: 'نجمتان',
      one: 'نجمة واحدة',
      zero: 'لا نجوم',
    );
    return '$_temp0';
  }

  @override
  String clientReviewsRewardsStarsAndBelow(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ نجمة فأقل',
      many: '⁦$countString⁩ نجمة فأقل',
      few: '⁦$countString⁩ نجوم فأقل',
      two: 'نجمتان فأقل',
      one: 'نجمة فأقل',
      zero: 'لا نجوم',
    );
    return '$_temp0';
  }

  @override
  String get clientReviewsRewardsAudienceWomen => 'الحفل النسائي';

  @override
  String get clientReviewsRewardsAudienceMen => 'الحفل الرجالي';

  @override
  String get clientReviewsRewardsAudienceMixed => 'حفل مختلط';

  @override
  String get clientReviewsRewardsRating => 'التقييم';

  @override
  String get clientReviewsRewardsGuest => 'ضيف';

  @override
  String get clientReviewsRewardsInReview => 'قيد المراجعة';

  @override
  String clientReviewsRewardsOpens(String date) {
    return 'يُفتح $date';
  }

  @override
  String clientReviewsRewardsOpensName(String date) {
    return 'يُفتح التقييم بعد مناسبتكم بتاريخ $date.';
  }

  @override
  String get clientReviewsRewardsShowMore => 'عرض المزيد';

  @override
  String get clientReviewsRewardsListTitle => 'التقييمات';

  @override
  String get clientReviewsRewardsListWrite => 'كتابة تقييم';

  @override
  String get clientReviewsRewardsListEvent => 'مناسبتكم';

  @override
  String get clientReviewsRewardsListSignIn => 'تسجيل الدخول';

  @override
  String get clientReviewsRewardsListSignInName => 'لتقييم مناسبتكم';

  @override
  String get clientReviewsRewardsListInfoTitle => 'تقييمات موثّقة';

  @override
  String get clientReviewsRewardsListInfoReal => 'التقييم لمن أتمّ حجزه فقط.';

  @override
  String get clientReviewsRewardsListInfoVenue =>
      'للقاعة ردّ واحد، ولا يمكنها تعديل التقييم أو حذفه.';

  @override
  String get clientReviewsRewardsListInfoNew =>
      'كونوا أول من يقيّم بعد مناسبتكم.';

  @override
  String get clientReviewsRewardsListFilterLabel => 'تصفية التقييمات';

  @override
  String get clientReviewsRewardsListFilterPhotos => 'صور';

  @override
  String get clientReviewsRewardsListSortRecent => 'الأحدث';

  @override
  String get clientReviewsRewardsListSortHighest => 'الأعلى';

  @override
  String get clientReviewsRewardsListSortLowest => 'الأدنى';

  @override
  String get clientReviewsRewardsListSortTitle => 'ترتيب';

  @override
  String get clientReviewsRewardsListMore => 'خيارات إضافية لهذا التقييم';

  @override
  String get clientReviewsRewardsListMoreReviews => 'المزيد';

  @override
  String get clientReviewsRewardsListVerified => 'حجز موثّق';

  @override
  String clientReviewsRewardsListReplyFrom(String venue) {
    return 'ردّ من $venue';
  }

  @override
  String get clientReviewsRewardsListReportTitle => 'إبلاغ';

  @override
  String get clientReviewsRewardsListReasonAbusive => 'مسيء';

  @override
  String get clientReviewsRewardsListReasonNotVenue => 'لا يخص القاعة';

  @override
  String get clientReviewsRewardsListReasonPeople => 'تظهر أشخاصًا';

  @override
  String get clientReviewsRewardsListReasonOther => 'أخرى';

  @override
  String get clientReviewsRewardsListReportReason => 'حدّدوا السبب';

  @override
  String get clientReviewsRewardsListReportSent => 'أُرسل البلاغ';

  @override
  String get clientReviewsRewardsListReported => 'تم الإبلاغ';

  @override
  String get clientReviewsRewardsWriteTitle => 'كتابة تقييم';

  @override
  String clientReviewsRewardsWritePrompt(String venue) {
    return 'كيف كانت تجربتكم في $venue؟';
  }

  @override
  String get clientReviewsRewardsWriteOverall => 'التقييم العام';

  @override
  String get clientReviewsRewardsWriteStar1 => 'ضعيف';

  @override
  String get clientReviewsRewardsWriteStar2 => 'مقبول';

  @override
  String get clientReviewsRewardsWriteStar3 => 'جيد';

  @override
  String get clientReviewsRewardsWriteStar4 => 'جيد جدًا';

  @override
  String get clientReviewsRewardsWriteStar5 => 'ممتاز';

  @override
  String get clientReviewsRewardsWriteCatVenue => 'القاعة';

  @override
  String get clientReviewsRewardsWriteCatFood => 'الطعام';

  @override
  String get clientReviewsRewardsWriteCatService => 'الخدمة';

  @override
  String get clientReviewsRewardsWriteCatValue => 'القيمة';

  @override
  String get clientReviewsRewardsWriteTextLabel => 'تعليق';

  @override
  String get clientReviewsRewardsWriteMediaTitle => 'الصور';

  @override
  String get clientReviewsRewardsWriteMediaNoPeople => 'بلا أشخاص';

  @override
  String get clientReviewsRewardsWriteMediaInfoTitle => 'ضوابط التقييم';

  @override
  String get clientReviewsRewardsWriteMediaRule =>
      'لا يمكن نشر الصور أو المقاطع التي يظهر فيها أشخاص.';

  @override
  String get clientReviewsRewardsWriteMediaAllowed =>
      'نرحّب بصور القاعة والديكور والطعام والتفاصيل.';

  @override
  String get clientReviewsRewardsWriteMediaChecked =>
      'تُفحص التقييمات قبل ظهورها، وتنتظر الصور فريقنا ولا يراها غيركم.';

  @override
  String get clientReviewsRewardsWriteMediaAdd => 'إضافة صورة أو مقطع';

  @override
  String get clientReviewsRewardsWriteMediaUploading => 'جارٍ الرفع';

  @override
  String get clientReviewsRewardsWriteMediaRejected => 'أشخاص';

  @override
  String get clientReviewsRewardsWriteMediaRejectedNote =>
      'لا يمكن نشر هذه الصورة لأنها تُظهر أشخاصًا. يمكنكم حذفها أو إضافة صورة أخرى.';

  @override
  String get clientReviewsRewardsWriteMediaRemove => 'حذف هذه الصورة';

  @override
  String get clientReviewsRewardsWriteNameHide => 'إخفاء الاسم';

  @override
  String get clientReviewsRewardsWriteSubmitReason => 'أضيفوا تقييمًا';

  @override
  String get clientReviewsRewardsWriteOffline =>
      'لا يوجد اتصال. المسودة محفوظة.';

  @override
  String get clientReviewsRewardsWriteOfflineReason => 'يلزم اتصال';

  @override
  String get clientReviewsRewardsWriteError => 'لم يُرسل. المسودة محفوظة.';

  @override
  String get clientReviewsRewardsWriteLockedAction => 'عرض الحجز';

  @override
  String get clientReviewsRewardsWriteDoneTitle => 'شكرًا لكم';

  @override
  String get clientReviewsRewardsWriteDoneHelper => 'يظهر بعد مراجعة سريعة';

  @override
  String get clientReviewsRewardsWriteDoneSee => 'عرض التقييمات';

  @override
  String get clientReviewsRewardsWriteAlreadyTitle => 'سبق تقييمكم';

  @override
  String get clientSavedCompareSavedTitle => 'المفضلة';

  @override
  String get clientSavedCompareSavedTabsLabel => 'عناصر المفضلة';

  @override
  String clientSavedCompareSavedSummaryFree(num free, num total, String date) {
    final intl.NumberFormat freeNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String freeString = freeNumberFormat.format(free);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '⁦$freeString⁩ من ⁦$totalString⁩ قاعة متاحة يوم $date',
      many: '⁦$freeString⁩ من ⁦$totalString⁩ قاعة متاحة يوم $date',
      few: '⁦$freeString⁩ من ⁦$totalString⁩ قاعات متاحة يوم $date',
      two: '⁦$freeString⁩ من قاعتين متاحة يوم $date',
      one: 'قاعة واحدة متاحة يوم $date',
      zero: 'لا قاعات',
    );
    return '$_temp0';
  }

  @override
  String clientSavedCompareSavedSummaryOneFree(String date) {
    return 'القاعة متاحة يوم $date';
  }

  @override
  String clientSavedCompareSavedSummaryOneBusy(String date) {
    return 'القاعة غير متاحة يوم $date';
  }

  @override
  String get clientSavedCompareSavedSelect => 'تحديد';

  @override
  String get clientSavedCompareSavedSelectNeedTwo => 'اختاروا قاعتين على الأقل';

  @override
  String clientSavedCompareSavedSelectRow(String name) {
    return 'تحديد $name';
  }

  @override
  String clientSavedCompareSavedDeselectRow(String name) {
    return 'إلغاء تحديد $name';
  }

  @override
  String clientSavedCompareSavedAvailFree(String date) {
    return 'ما زال متاحًا يوم $date';
  }

  @override
  String get clientSavedCompareSavedAvailHeld => 'محجوز مؤقتًا';

  @override
  String clientSavedCompareSavedAvailBooked(String date) {
    return 'محجوز يوم $date';
  }

  @override
  String get clientSavedCompareSavedSavingChanged => 'تغير التوفير';

  @override
  String clientSavedCompareSavedVoucherReadyOpen(String name) {
    return 'فتح كوبونكم لدى $name';
  }

  @override
  String get clientSavedCompareSavedUnlisted => 'غير مدرجة';

  @override
  String get clientSavedCompareSavedRemoved => 'تمت الإزالة';

  @override
  String get clientSavedCompareSavedGuestBanner => 'على هذا الهاتف فقط';

  @override
  String get clientSavedCompareSavedGuestSignIn => 'تسجيل الدخول';

  @override
  String get clientSavedCompareLastUpdated => 'آخر تحديث';

  @override
  String get clientSavedCompareSavedEmptyVenuesTitle => 'لا قاعات محفوظة';

  @override
  String get clientSavedCompareSavedEmptyVenuesAction => 'استكشاف القاعات';

  @override
  String get clientSavedCompareSavedEmptyServicesTitle => 'لا خدمات محفوظة';

  @override
  String get clientSavedCompareSavedEmptyServicesAction => 'استكشاف الخدمات';

  @override
  String get clientSavedCompareSavedEmptyPackagesTitle => 'لا باقات محفوظة';

  @override
  String get clientSavedCompareSavedEmptyPackagesAction => 'عرض الباقات';

  @override
  String get clientSavedCompareSavedPlannerLabel => 'تنسيق الأعراس';

  @override
  String get clientSavedCompareSavedFrom => 'من';

  @override
  String get clientSavedCompareFactGuests => 'الضيوف';

  @override
  String get clientSavedCompareFactDate => 'التاريخ';

  @override
  String get clientSavedCompareFactFreeHalls => 'القاعات المتاحة في تاريخكم';

  @override
  String get clientSavedCompareFactWomen => 'نسائي';

  @override
  String get clientSavedCompareFactMen => 'رجالي';

  @override
  String get clientSavedCompareFactMixed => 'مختلط';

  @override
  String get clientSavedCompareFactEdit => 'تعديل التفاصيل';

  @override
  String get clientSavedCompareTrayTitle => 'المقارنة';

  @override
  String get clientSavedCompareTrayAddOne => 'أضيفوا قاعة أخرى';

  @override
  String clientSavedCompareTrayAction(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'مقارنة (⁦$countString⁩)';
  }

  @override
  String clientSavedCompareTrayRemove(String name) {
    return 'إزالة $name من المقارنة';
  }

  @override
  String clientSavedCompareTrayBadge(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'فتح المقارنة، ⁦$countString⁩ قاعة',
      many: 'فتح المقارنة، ⁦$countString⁩ قاعة',
      few: 'فتح المقارنة، ⁦$countString⁩ قاعات',
      two: 'فتح المقارنة، قاعتان',
      one: 'فتح المقارنة، قاعة واحدة',
      zero: 'مقارنتكم فارغة',
    );
    return '$_temp0';
  }

  @override
  String get clientSavedCompareReplaceTitle => 'استبدال أي قاعة؟';

  @override
  String clientSavedCompareReplaceBody(num max, String name) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'يمكن مقارنة ⁦$maxString⁩ قاعات كحد أقصى. اختاروا القاعة التي سيحل $name محلها.';
  }

  @override
  String get clientSavedCompareReplaceDone => 'تم تحديث المقارنة';

  @override
  String get clientSavedCompareCompareTitle => 'المقارنة';

  @override
  String get clientSavedCompareCompareLinkCopied => 'تم نسخ الرابط';

  @override
  String get clientSavedCompareCompareRowAvailability => 'التوفر';

  @override
  String get clientSavedCompareCompareRowPrice => 'السعر';

  @override
  String get clientSavedCompareCompareRowPriceFrom => 'السعر ابتداءً من';

  @override
  String get clientSavedCompareCompareRowCapacity => 'سعة أكبر قاعة';

  @override
  String get clientSavedCompareCompareRowSetting => 'نوع المكان';

  @override
  String get clientSavedCompareCompareRowValet => 'خدمة الفاليه';

  @override
  String get clientSavedCompareCompareRowParking => 'مواقف مجانية';

  @override
  String get clientSavedCompareCompareRowBridal => 'جناح العروس';

  @override
  String get clientSavedCompareCompareRowBuffet => 'البوفيه';

  @override
  String get clientSavedCompareCompareRowPhotography => 'التصوير';

  @override
  String get clientSavedCompareCompareRowRating => 'التقييم';

  @override
  String clientSavedCompareCompareRowDistance(String origin) {
    return 'المسافة بالسيارة من $origin';
  }

  @override
  String clientSavedCompareCompareDriveMinutes(num minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '⁦$minutesString⁩ دقيقة',
      many: '⁦$minutesString⁩ دقيقة',
      few: '⁦$minutesString⁩ دقائق',
      two: 'دقيقتان',
      one: 'دقيقة',
      zero: 'أقل من دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get clientSavedCompareCompareRowPackages => 'الباقات';

  @override
  String get clientSavedCompareCompareRowHow => 'قناة الحجز';

  @override
  String get clientSavedCompareCompareRowPhotos => 'الصور';

  @override
  String get clientSavedCompareCompareValHowVoucher => 'بالكوبون';

  @override
  String get clientSavedCompareCompareValHowStandard => 'سعر عادي فقط';

  @override
  String get clientSavedCompareCompareValHowOfficial => 'القناة الرسمية';

  @override
  String get clientSavedCompareCompareValIncluded => 'مشمولة';

  @override
  String get clientSavedCompareCompareValExtra => 'برسوم إضافية';

  @override
  String get clientSavedCompareCompareValNotOffered => 'غير متوفرة';

  @override
  String get clientSavedCompareCompareValIndoor => 'داخلية';

  @override
  String get clientSavedCompareCompareValOutdoor => 'خارجية';

  @override
  String get clientSavedCompareCompareValWomenOnly => 'مصوّرات فقط';

  @override
  String get clientSavedCompareCompareValAllowed => 'مسموح';

  @override
  String get clientSavedCompareCompareValNotAllowed => 'غير مسموح';

  @override
  String get clientSavedCompareCompareValBelow => 'أقل من عددكم';

  @override
  String get clientSavedCompareCompareValFrom => 'من';

  @override
  String get clientSavedCompareCompareShowPackages => 'عرض الباقات';

  @override
  String get clientSavedCompareCompareHidePackages => 'إخفاء الباقات';

  @override
  String get clientSavedCompareCompareBadgeRated => 'الأعلى تقييمًا';

  @override
  String get clientSavedCompareCompareBadgeLowest => 'الأقل سعرًا';

  @override
  String get clientSavedCompareCompareBadgeClosest => 'الأقرب';

  @override
  String get clientSavedCompareCompareActionVoucher => 'كوبون';

  @override
  String get clientSavedCompareCompareActionView => 'عرض';

  @override
  String get clientSavedCompareCompareActionDates => 'التواريخ';

  @override
  String get clientSavedCompareCompareActionOfficial => 'رسمي';

  @override
  String clientSavedCompareCompareActionFor(String action, String name) {
    return '$action: $name';
  }

  @override
  String clientSavedCompareCompareOpen(String name) {
    return 'فتح $name';
  }

  @override
  String clientSavedCompareComparePick(String name) {
    return 'اختيار $name';
  }

  @override
  String clientSavedCompareCompareUnpick(String name) {
    return 'تم اختيار $name';
  }

  @override
  String clientSavedCompareComparePicked(String name) {
    return 'اخترتم $name.';
  }

  @override
  String get clientSavedCompareCompareSetDate => 'تحديد التاريخ';

  @override
  String get clientSavedCompareCompareFewerTitle => 'أضيفوا قاعة ثانية';

  @override
  String get clientSavedCompareCompareFewerAction => 'اختيار قاعة';

  @override
  String get clientSavedCompareCompareDiffLabel => 'الصفوف المعروضة';

  @override
  String get clientSavedCompareCompareDiffOnly => 'الفروقات';

  @override
  String get clientSavedCompareCompareDiffAll => 'الكل';

  @override
  String get clientSavedCompareKeyTitle => 'الرموز';

  @override
  String get clientSavedCompareKeyBest => 'الأفضل';

  @override
  String get clientSavedCompareKeySave => 'التوفير';

  @override
  String clientSavedCompareCompareHidden(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ صف متشابه مخفي',
      many: '⁦$countString⁩ صفًا متشابهًا مخفيًا',
      few: '⁦$countString⁩ صفوف متشابهة مخفية',
      two: 'صفان متشابهان مخفيان',
      one: 'صف متشابه مخفي',
      zero: 'لا صفوف مخفية',
    );
    return '$_temp0';
  }

  @override
  String get clientServicesFrom => 'من';

  @override
  String clientServicesOpenName(String name) {
    return 'فتح $name';
  }

  @override
  String get clientServicesArea => 'المنطقة';

  @override
  String get clientServicesProviders => 'المقدّمون';

  @override
  String get clientServicesSoon => 'قريبًا';

  @override
  String get clientServicesVoucherAvailable => 'أسعار الكوبون متاحة';

  @override
  String get clientServicesSavedView => 'عرض';

  @override
  String get clientServicesRequestSent => 'تم الإرسال';

  @override
  String get clientServicesReconnect => 'أعيدوا الاتصال للمتابعة';

  @override
  String get clientServicesHowTitle => 'كيف يعمل';

  @override
  String get clientServicesUnitEvent => 'للحفل';

  @override
  String get clientServicesUnitCake => 'للكيكة';

  @override
  String get clientServicesUnitSession => 'للجلسة';

  @override
  String get clientServicesUnitDress => 'للفستان';

  @override
  String get clientServicesUnitSuit => 'للبدلة';

  @override
  String get clientServicesUnitCard => 'للبطاقة';

  @override
  String get clientServicesUnitBooking => 'للحجز';

  @override
  String get clientServicesUnitPackage => 'للباقة';

  @override
  String get clientServicesHubTitle => 'الخدمات';

  @override
  String get clientServicesHubSwitchLabel => 'التصفّح';

  @override
  String get clientServicesHubGroupsLabel => 'الفئات';

  @override
  String get clientServicesHubMoreHeading => 'المزيد';

  @override
  String get clientServicesHubPlannerTitle => 'تنسيق الأعراس';

  @override
  String get clientServicesHubSavedTitle => 'المحفوظ';

  @override
  String get clientServicesHubGovernmentNote => 'أضيفوا الضيافة والديكور';

  @override
  String clientServicesHubVoucherLine(String fee) {
    return 'احصلوا على كوبون غزل بقيمة $fee من صفحة مقدّم الخدمة لتفتحوا أسعارًا أقل. الدفع لمقدّم الخدمة مباشرةً دائمًا.';
  }

  @override
  String get clientServicesListTitle => 'المقدّمون';

  @override
  String get clientServicesListSiblings => 'خدمات ذات صلة';

  @override
  String get clientServicesListFemaleTeam => 'فريق نسائي';

  @override
  String clientServicesListGridLabel(String category) {
    return 'المقدّمون في $category';
  }

  @override
  String get clientServicesListNoResultsTitle => 'لا نتائج';

  @override
  String get clientServicesListClear => 'مسح التصفية';

  @override
  String get clientServicesListEmptyTitle => 'لا نتائج بعد';

  @override
  String get clientServicesFilterTitle => 'التصفية';

  @override
  String get clientServicesFilterLabel => 'تصفية';

  @override
  String get clientServicesSheetSortLabel => 'الترتيب';

  @override
  String clientServicesSheetUpTo(String price) {
    return 'حتى $price';
  }

  @override
  String clientServicesSheetRatingAtLeast(String rating) {
    return '$rating+';
  }

  @override
  String clientServicesSheetShow(String count) {
    return 'عرض $count';
  }

  @override
  String get clientServicesSortRecommended => 'الأنسب';

  @override
  String get clientServicesSortPrice => 'السعر';

  @override
  String get clientServicesSortRating => 'التقييم';

  @override
  String get clientServicesProfileTitle => 'المقدّم';

  @override
  String clientServicesProfileHeroLabel(String name) {
    return 'صور أعمال $name';
  }

  @override
  String get clientServicesProfileReply => 'يردّ خلال';

  @override
  String get clientServicesProfileVerified => 'موثّق';

  @override
  String get clientServicesProfileEventTitle => 'المناسبة';

  @override
  String get clientServicesProfileEventInfoTitle => 'الموعد';

  @override
  String get clientServicesProfileAvailabilityBody =>
      'يؤكّد مقدّم الخدمة توفّره للموعد في المحادثة.';

  @override
  String get clientServicesProfileEventNote =>
      'يرتبط الكوبون بهذا التاريخ وهذه الباقة.';

  @override
  String get clientServicesProfileAsk => 'استفسار';

  @override
  String get clientServicesProfilePackagesTitle => 'الباقات';

  @override
  String clientServicesProfilePackageChoose(String name) {
    return 'اختيار $name';
  }

  @override
  String clientServicesProfilePackageChosen(String name) {
    return '$name، تم الاختيار';
  }

  @override
  String get clientServicesProfileIncludes => 'تشمل';

  @override
  String get clientServicesProfileBudgetTitle => 'إضافة إلى الميزانية';

  @override
  String get clientServicesProfileReviewsTitle => 'التقييمات';

  @override
  String get clientServicesProfileGetVoucher => 'طلب كوبون';

  @override
  String get clientServicesProfileRequest => 'عرض سعر';

  @override
  String get clientServicesProfileOpenChat => 'فتح المحادثة';

  @override
  String get clientServicesHowRequestLabel => 'الطلب';

  @override
  String get clientServicesHowSettleLabel => 'الدفع للمقدّم';

  @override
  String clientServicesHowPayTitle(String fee) {
    return 'ادفعوا $fee إلكترونيًا';
  }

  @override
  String get clientServicesHowPayBody =>
      'عبر كي نت أو البطاقة أو أبل باي أو جوجل باي. يرتبط الكوبون بهذا المقدّم وهذه الباقة.';

  @override
  String get clientServicesHowRequestTitle => 'اطلبوا بسعر الكوبون';

  @override
  String clientServicesHowRequestBody(String hours) {
    return 'يردّ مقدّم الخدمة. وبعد الموافقة لديكم $hours للتأكيد.';
  }

  @override
  String get clientServicesHowSettleTitle => 'ادفعوا لمقدّم الخدمة مباشرةً';

  @override
  String get clientServicesHowSettleBody =>
      'تسدّدون حسب اتفاقكم مع المقدّم وتعرضون رمز الكوبون. غزل لا تستلم أي مبلغ مقابل الخدمة.';

  @override
  String get clientServicesQuoteTitle => 'عرض سعر';

  @override
  String get clientServicesQuotePackage => 'الباقة';

  @override
  String get clientServicesQuoteDate => 'تاريخ المناسبة';

  @override
  String get clientServicesQuoteDatePlaceholder => 'اختيار التاريخ';

  @override
  String get clientServicesQuoteVenue => 'القاعة';

  @override
  String get clientServicesQuoteGuests => 'الضيوف';

  @override
  String get clientServicesQuoteNoteLabel => 'ملاحظة لمقدّم الخدمة';

  @override
  String get clientServicesQuoteNotePlaceholder => 'ملاحظة';

  @override
  String get clientServicesQuoteSend => 'إرسال الطلب';

  @override
  String get clientServicesQuoteDateError => 'التاريخ مطلوب';

  @override
  String get clientServicesQuoteGuestNote => 'سجّلوا الدخول للإرسال';

  @override
  String get clientServicesQuoteThreadExists => 'يضاف إلى المحادثة';

  @override
  String get clientServicesQuoteErrorTitle => 'تعذّر الإرسال';

  @override
  String get clientServicesQuoteErrorBody => 'لم يضع شيء مما كتبتموه.';

  @override
  String get clientServicesQuoteVoucherFailed => 'كوبونكم محفوظ ولم يتم الخصم.';

  @override
  String get clientServicesQuoteAttachTitle => 'استخدام الكوبون';

  @override
  String get clientServicesQuoteAttachInfoTitle => 'الطلب بالكوبون';

  @override
  String get clientServicesQuoteAttachNote =>
      'يصبح استفساركم طلبًا بسعر الكوبون. يقبله مقدّم الخدمة أو يعتذر أو يقترح موعدًا آخر.';

  @override
  String get clientServicesQuoteNextTitle => 'الخطوة التالية';

  @override
  String get clientServicesQuoteViewRequest => 'عرض الطلب';

  @override
  String clientServicesQuoteVoucherSuccessBody(String vendor, String hours) {
    return 'يردّ $vendor في الرسائل. وبعد موافقته لديكم $hours للتأكيد.';
  }

  @override
  String get clientShellTabBarLabel => 'التنقل الرئيسي';

  @override
  String get clientShellTabDiscover => 'استكشف';

  @override
  String get clientShellTabSaved => 'المفضلة';

  @override
  String get clientShellTabMyWedding => 'زفافكم';

  @override
  String get clientShellTabMessages => 'الرسائل';

  @override
  String get clientShellTabProfile => 'حسابكم';

  @override
  String clientShellTabUnread(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ رسالة غير مقروءة',
      many: '⁦$countString⁩ رسالة غير مقروءة',
      few: '⁦$countString⁩ رسائل غير مقروءة',
      two: 'رسالتان غير مقروءتين',
      one: 'رسالة واحدة غير مقروءة',
      zero: 'لا رسائل غير مقروءة',
    );
    return '$_temp0';
  }

  @override
  String clientShellGreeting(String name) {
    return 'أهلًا وسهلًا، $name';
  }

  @override
  String get clientShellGreetingAnonymous => 'أهلًا وسهلًا';

  @override
  String get clientShellBriefTitle => 'تفاصيل زفافكم';

  @override
  String get clientShellBriefEditLabel =>
      'تعديل التاريخ والضيوف والمنطقة والميزانية';

  @override
  String get clientShellBriefDate => 'التاريخ';

  @override
  String get clientShellBriefGuests => 'عدد الضيوف';

  @override
  String get clientShellBriefArea => 'المنطقة';

  @override
  String get clientShellBriefBudget => 'ميزانية القاعة والضيافة';

  @override
  String get clientShellBriefNotDecided => 'لم يتحدد';

  @override
  String get clientShellBriefFlexibleMonth => 'شهر مرن';

  @override
  String get clientShellSwitchVenues => 'القاعات';

  @override
  String get clientShellSwitchServices => 'الخدمات';

  @override
  String get clientShellSwitchPackages => 'الباقات';

  @override
  String clientShellCompareTray(String pair) {
    return 'مقارنة ($pair)';
  }

  @override
  String get clientVenueTierPrestige => 'فاخر';

  @override
  String get clientVenueTierSignature => 'راقٍ';

  @override
  String get clientVenueTierClassic => 'كلاسيكي';

  @override
  String get clientVenueTierGovernment => 'قاعة حكومية';

  @override
  String get clientVenueAboutTitle => 'نبذة';

  @override
  String get clientVenueTypeHotel => 'فندق';

  @override
  String get clientVenueTypeHall => 'قاعة';

  @override
  String get clientVenueTypeResort => 'منتجع';

  @override
  String get clientVenueTypeVilla => 'فيلا';

  @override
  String get clientVenueTypeOutdoor => 'خارجي';

  @override
  String get clientVenueTypeConvention => 'مركز مؤتمرات';

  @override
  String clientVenueAddressLine(String block, String street) {
    return 'قطعة $block، $street';
  }

  @override
  String clientVenueRegionLine(String area, String governorate) {
    return '$area، $governorate';
  }

  @override
  String clientVenueHeroLabel(String venue) {
    return 'صور $venue';
  }

  @override
  String get clientVenueHeroOpen => 'فتح معرض الصور';

  @override
  String get clientVenueNoPhotos => 'الصور قريبًا';

  @override
  String get clientVenueZoneHall => 'القاعة';

  @override
  String get clientVenueZoneStage => 'الكوشة والمنصة';

  @override
  String get clientVenueZoneBridal => 'جناح العروس';

  @override
  String get clientVenueZoneBuffet => 'البوفيه';

  @override
  String get clientVenueZoneOutdoors => 'الخارج';

  @override
  String get clientVenueZoneEntrance => 'المدخل والفاليه';

  @override
  String get clientVenueZoneLayout => 'ترتيب الجلسات';

  @override
  String get clientVenueZoneVideo => 'الفيديو';

  @override
  String clientVenueZoneWithHall(String zone, String hall) {
    return '$zone، $hall';
  }

  @override
  String clientVenueGalleryLabel(String venue) {
    return 'معرض صور $venue';
  }

  @override
  String clientVenueGalleryCounter(num current, num total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '⁦$currentString⁩/⁦$totalString⁩';
  }

  @override
  String get clientVenueGalleryZones => 'أقسام الصور';

  @override
  String get clientVenueVideoPlay => 'تشغيل الفيديو';

  @override
  String get clientVenueVideoPause => 'إيقاف الفيديو مؤقتًا';

  @override
  String get clientVenueVideoScrub => 'موضع التشغيل';

  @override
  String get clientVenueVideoCaption => 'المدخل والقاعة والكوشة';

  @override
  String get clientVenueDateLabel => 'تاريخكم';

  @override
  String get clientVenueDateChoose => 'اختيار التاريخ';

  @override
  String get clientVenueDateChangeLabel => 'تغيير التاريخ';

  @override
  String get clientVenueGuestsAdd => 'إضافة الضيوف';

  @override
  String get clientVenueGuestsChangeLabel => 'تعديل عدد الضيوف';

  @override
  String get clientVenueGuestsLabel => 'الضيوف';

  @override
  String get clientVenueEstimateLabel => 'الإجمالي التقديري';

  @override
  String clientVenueEstimateMinimum(String guests) {
    return 'السعر محسوب على الحد الأدنى: $guests';
  }

  @override
  String get clientVenueHeldSr =>
      'التاريخ محجوز مؤقتًا لحفل آخر، ولا يزال بإمكانكم إرسال طلب.';

  @override
  String get clientVenueNearestTitle => 'أقرب التواريخ المتاحة';

  @override
  String get clientVenueSeeAllDates => 'كل التواريخ';

  @override
  String clientVenueWindowApplied(String title) {
    return '$title ينطبق على تاريخكم';
  }

  @override
  String get clientVenueHowTitle => 'كيف يعمل الكوبون';

  @override
  String get clientVenueThreadTitle => 'حجزكم في خمس خطوات';

  @override
  String get clientVenueThreadLabel =>
      'خطوات الحجز: الكوبون، الطلب، الموافقة، التأكيد، لدى المكان';

  @override
  String get clientVenueThreadVoucher => 'الكوبون';

  @override
  String get clientVenueThreadRequest => 'الطلب';

  @override
  String get clientVenueThreadApproval => 'الموافقة';

  @override
  String get clientVenueThreadConfirm => 'التأكيد';

  @override
  String get clientVenueThreadAtVenue => 'لدى المكان';

  @override
  String clientVenueThreadNote(String fee, String venue) {
    return 'تدفعون لغزل $fee مرة واحدة ثمنًا للكوبون، وأي مبلغ آخر تدفعونه مباشرةً إلى $venue.';
  }

  @override
  String clientVenueResponseUsually(int hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '⁦$hoursString⁩ ساعة',
      many: '⁦$hoursString⁩ ساعة',
      few: '⁦$hoursString⁩ ساعات',
      two: 'ساعتين',
      one: 'ساعة واحدة',
      zero: 'أقل من ساعة',
    );
    return 'يرد عادةً خلال $_temp0';
  }

  @override
  String get clientVenueOwnedView => 'عرض';

  @override
  String get clientVenueHallsTitle => 'القاعات';

  @override
  String get clientVenueHallSwitchLabel => 'اختيار القاعة';

  @override
  String get clientVenueHallFacts => 'معلومات';

  @override
  String get clientVenueHallCapacity => 'السعة';

  @override
  String get clientVenueHallIndoor => 'داخلية';

  @override
  String get clientVenueHallOutdoor => 'خارجية';

  @override
  String get clientVenueHallMixed => 'داخلية وخارجية';

  @override
  String get clientVenueHallExclusive => 'حفل واحد في اليوم';

  @override
  String get clientVenueHallExclusiveShort => 'حصرية';

  @override
  String get clientVenueSessionSwitchLabel => 'اختيار الفترة';

  @override
  String get clientVenueMore => 'عرض المزيد';

  @override
  String get clientVenueLess => 'عرض أقل';

  @override
  String get clientVenuePackagesTitle => 'الباقات';

  @override
  String get clientVenuePackagesDetails => 'تفاصيل الباقة';

  @override
  String get clientVenuePackagesNone => 'لا باقات متاحة';

  @override
  String get clientVenuePkgMinGuests => 'الحد الأدنى للضيوف';

  @override
  String get clientVenuePkgIncludes => 'المشمولات';

  @override
  String get clientVenuePkgIncludesAll => 'عرض كل المشمولات';

  @override
  String get clientVenuePkgMenu => 'القائمة';

  @override
  String get clientVenuePkgExtras => 'إضافات';

  @override
  String get clientVenuePkgSave => 'حفظ الباقة';

  @override
  String get clientVenuePkgSaved => 'إزالة الباقة من المحفوظات';

  @override
  String get clientVenuePkgTierWeekday => 'أيام الأسبوع';

  @override
  String get clientVenuePkgTierWeekend => 'نهاية الأسبوع';

  @override
  String get clientVenuePkgTierSeason => 'الموسم';

  @override
  String get clientVenuePkgTierHoliday => 'العطلات';

  @override
  String get clientVenuePkgTierSpecialDate => 'تاريخ مميز';

  @override
  String clientVenuePkgTierLabel(String date) {
    return 'سعر $date';
  }

  @override
  String get clientVenuePkgOverTitle => 'يتجاوز السعة';

  @override
  String clientVenuePkgOverCap(String hall, String guests) {
    return 'تتسع $hall حتى $guests. يمكنكم اختيار قاعة أخرى أو عدد ضيوف أقل.';
  }

  @override
  String clientVenuePkgUnavailable(String date) {
    return 'غير متاحة يوم $date';
  }

  @override
  String get clientVenueFacilitiesTitle => 'المرافق';

  @override
  String get clientVenueFacilitiesAll => 'كل المرافق';

  @override
  String get clientVenueFacIncluded => 'مشمول';

  @override
  String get clientVenueFacExtra => 'إضافة';

  @override
  String get clientVenueFacOff => 'غير متوفر';

  @override
  String get clientVenuePoliciesTitle => 'السياسات';

  @override
  String get clientVenuePolicyTerms => 'الشروط';

  @override
  String get clientVenuePolicyRules => 'قواعد القاعة';

  @override
  String get clientVenuePolicyGood => 'للعلم';

  @override
  String get clientVenueFaqTitle => 'أسئلة';

  @override
  String get clientVenueReviewsTitle => 'التقييمات';

  @override
  String clientVenueReviewsAll(String count) {
    return 'عرض كل التقييمات ($count)';
  }

  @override
  String get clientVenueReviewsNone => 'لا تقييمات بعد';

  @override
  String get clientVenueCatVenue => 'القاعة';

  @override
  String get clientVenueCatFood => 'الطعام';

  @override
  String get clientVenueCatService => 'الخدمة';

  @override
  String get clientVenueCatValue => 'القيمة';

  @override
  String get clientVenueReviewAnon => 'ضيف';

  @override
  String get clientVenueReviewReply => 'ردّ المكان';

  @override
  String get clientVenueLocationTitle => 'الموقع';

  @override
  String clientVenueDriveFrom(String origin) {
    return 'بالسيارة من $origin';
  }

  @override
  String get clientVenueMapsShort => 'الخرائط';

  @override
  String get clientVenueMapsTitle => 'الخرائط';

  @override
  String get clientVenueMapsGoogle => 'خرائط غوغل';

  @override
  String get clientVenueMapsApple => 'خرائط آبل';

  @override
  String get clientVenueMapsWaze => 'ويز';

  @override
  String clientVenueMapsOpening(String app) {
    return 'فتح $app';
  }

  @override
  String get clientVenueSimilarTitle => 'قاعات مشابهة';

  @override
  String get clientVenueCtaChooseDate => 'اختيار التاريخ';

  @override
  String get clientVenueCtaSeeDates => 'التواريخ المتاحة';

  @override
  String get clientVenueCtaGetVoucher => 'شراء الكوبون';

  @override
  String get clientVenueCtaSendRequest => 'إرسال الطلب';

  @override
  String get clientVenueCtaVisit => 'حجز زيارة';

  @override
  String get clientVenueCtaContact => 'تواصل';

  @override
  String get clientVenueCtaChangeGuests => 'تعديل الضيوف';

  @override
  String get clientVenueVisitNone => 'لا توجد مواعيد زيارة متاحة حاليًا';

  @override
  String get clientVenueCtaOffline => 'إعادة الاتصال';

  @override
  String clientVenueOfflineBanner(String time) {
    return 'غير متصل، حُفظ $time';
  }

  @override
  String get clientVenueCompareAdded => 'أُضيفت للمقارنة';

  @override
  String get clientVenueCompareView => 'عرض';

  @override
  String get clientVenueSavedRemoved => 'تمت الإزالة';

  @override
  String get clientVenueSavedView => 'عرض';

  @override
  String get clientVenueShareCopied => 'نُسخ الرابط';

  @override
  String get clientVenueDelistedTitle => 'لم يعد مدرجًا';

  @override
  String get clientVenueDelistedCta => 'استعراض القاعات';

  @override
  String clientVenueTotalFor(String guests) {
    return 'الإجمالي لعدد $guests';
  }

  @override
  String get clientVenueContactTitle => 'تواصل';

  @override
  String clientVenueContactCalling(String venue) {
    return 'اتصال: $venue';
  }

  @override
  String get clientVenueContactWhatsapp => 'فتح واتساب';

  @override
  String get clientVenueContactChat => 'مراسلة';

  @override
  String get clientVenueCalTitle => 'التواريخ';

  @override
  String get clientVenueCalMonthJump => 'الانتقال إلى شهر';

  @override
  String get clientVenueCalMonthTitle => 'الشهر';

  @override
  String clientVenueCalMonthDensity(String month, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ تاريخ متاح',
      many: '⁦$countString⁩ تاريخًا متاحًا',
      few: '⁦$countString⁩ تواريخ متاحة',
      two: 'تاريخان متاحان',
      one: 'تاريخ واحد متاح',
      zero: 'لا تواريخ متاحة',
    );
    return '$month: $_temp0';
  }

  @override
  String clientVenueCalBasis(String guests) {
    return 'الأسعار بالدينار لعدد $guests';
  }

  @override
  String get clientVenueCalGuestsCta => 'إضافة الضيوف';

  @override
  String get clientVenueCalNone => 'لا تواريخ متاحة';

  @override
  String get clientVenueCalPickHint => 'اختيار تاريخ يعرض التقدير.';

  @override
  String get clientVenueCalPickFree => 'اختاروا أحد التواريخ المتاحة.';

  @override
  String get clientVenueCalOccasionsLabel => 'مناسبات هذا الشهر';

  @override
  String clientVenueCalChosen(String date) {
    return 'تم اعتماد $date';
  }

  @override
  String get clientVenueCalUse => 'اعتماد التاريخ';

  @override
  String get clientVenuePolTitle => 'السياسات';

  @override
  String get clientVenuePolTabsLabel => 'أقسام السياسات';

  @override
  String get clientVenuePolTabTerms => 'الشروط';

  @override
  String get clientVenuePolTabRules => 'القواعد';

  @override
  String get clientVenuePolTabGood => 'للعلم';

  @override
  String get clientVenuePolRulesLabel => 'نوع الحفل';

  @override
  String get clientVenuePolChildren => 'الأطفال';

  @override
  String get clientVenuePolDress => 'زي الحضور';

  @override
  String get clientVenuePolHours => 'ساعات العمل';

  @override
  String get clientVenuePolClosures => 'فترات الإغلاق';

  @override
  String clientVenuePolHoursLine(String days, String open, String close) {
    return '$days: $open – $close';
  }

  @override
  String clientVenuePolClosureLine(String name, String from, String to) {
    return '$name: $from – $to';
  }

  @override
  String get clientVenueAudWomen => 'نسائي';

  @override
  String get clientVenueAudMen => 'رجالي';

  @override
  String get clientVenueAudMixed => 'مختلط';

  @override
  String get clientVenueRulePhotography => 'التصوير';

  @override
  String get clientVenueRulePhotoFemale => 'نساء فقط';

  @override
  String get clientVenueRuleMusic => 'الموسيقى';

  @override
  String get clientVenueRuleMusicBand => 'دي جي أو فرقة';

  @override
  String get clientVenueRuleMusicLive => 'حيّة';

  @override
  String get clientVenueRuleMusicDuff => 'دفوف فقط';

  @override
  String get clientVenueRuleAllowed => 'مسموح';

  @override
  String get clientVenueRuleApproval => 'بموافقة';

  @override
  String get clientVenueRuleNot => 'غير مسموح';

  @override
  String get clientVenueRuleNone => 'بلا';

  @override
  String get clientVenueRuleEntrance => 'مدخل منفصل';

  @override
  String get clientVenueRuleCloakroom => 'غرفة العبايات';

  @override
  String get clientVenueRulePrayer => 'المصلى';

  @override
  String get clientVenueRuleSecurity => 'حراسة نسائية';

  @override
  String get clientVenueRuleBackup => 'قاعة بديلة';

  @override
  String get clientVenueRuleBoys => 'عمر الأولاد';

  @override
  String get clientVenueRuleCatering => 'ضيافة خارجية';

  @override
  String get clientVenueRuleDecor => 'ديكور خارجي';

  @override
  String get clientVenueRuleBukhoor => 'البخور';

  @override
  String get clientVenueRuleCutoff => 'نهاية الحفل';

  @override
  String get clientVenueRuleExtraHour => 'ساعة إضافية';

  @override
  String clientVenueTermsVenueTitle(String venue) {
    return 'شروط $venue';
  }

  @override
  String get clientVenueTermsVoucherTitle => 'كوبون غزل';

  @override
  String clientVenueTermsVoucherFee(String fee) {
    return '$fee مرة واحدة لغزل';
  }

  @override
  String get clientVenueTermsVoucherBound => 'خاص بهذه القاعة وهذا العرض';

  @override
  String get clientVenueTermsDirect => 'الدفع والإلغاء مع القاعة';

  @override
  String clientVenueTermsVoucherReuse(String days) {
    return 'اعتذار أو عدم رد: استخدام جديد خلال $days أو طلب رصيد من الدعم';
  }

  @override
  String clientVenueTermsVoucherConfirm(String hours) {
    return 'التأكيد خلال $hours من الموافقة';
  }

  @override
  String get clientVenueGovFeesTitle => 'الرسوم';

  @override
  String get clientVenueGovSecurity => 'مبلغ التأمين';

  @override
  String get clientVenueGovRefundable => 'قابل للاسترداد';

  @override
  String get clientVenueGovHallOnly =>
      'القاعة فقط: الديكور والضيافة على حسابكم.';

  @override
  String get clientVenueGovHallOnlyShort => 'القاعة فقط';

  @override
  String get clientVenueGovFeesInfoTitle => 'عن الرسوم';

  @override
  String get clientVenueGovRulesTitle => 'القواعد';

  @override
  String get clientVenueGovRuleNoChange => 'لا تغيير للتاريخ';

  @override
  String get clientVenueGovRulePay => 'الدفع في الموعد';

  @override
  String get clientVenueGovRulePayInfo =>
      'الدفع عبر القناة الرسمية خلال المدة التي تحددها، وإلا يُلغى الحجز تلقائيًا.';

  @override
  String get clientVenueGovRuleKnet => 'KNET';

  @override
  String get clientVenueGovAvail => 'التطبيق الرسمي';

  @override
  String get clientVenueGovCtaOfficial => 'الحجز الرسمي';

  @override
  String get clientVenueGovCtaCatering => 'خدمات الحفل';

  @override
  String get clientVenueGovLeaveTitle => 'مغادرة غزل';

  @override
  String get clientVenueGovLeaveBody =>
      'الحجز والدفع عبر القناة الرسمية، ولا تضمنه غزل.';

  @override
  String get clientVenueGovLeaveToast => 'فتح القناة الرسمية';

  @override
  String get clientVenueGovSelfLink => 'تسجيل الحجز';

  @override
  String get clientVenueGovSelfTitle => 'تسجيل الحجز';

  @override
  String get clientVenueGovSelfDate => 'التاريخ';

  @override
  String get clientVenueGovSelfFee => 'الرسوم المدفوعة';

  @override
  String get clientVenueGovSelfNote =>
      'هذا سجل لميزانيتكم وقائمة مهامكم والعد التنازلي فقط، وليس حجزًا عبر غزل.';

  @override
  String get clientVenueGovSelfInfoTitle => 'ليس حجزًا';

  @override
  String get clientVenueGovSelfToast => 'تم الحفظ في زفافكم';

  @override
  String get clientVenueGovSelfView => 'عرض';

  @override
  String get clientVenueGovWhyTitle => 'سبب غياب الكوبون';

  @override
  String get clientVenueGovWhyBody =>
      'رسوم المنشآت الحكومية رسمية وثابتة، فلا يوجد سعر خاص من غزل.';

  @override
  String get clientVenueGovBrowse => 'استعراض القاعات';

  @override
  String get clientVisitsBookTitle => 'احجزوا زيارة';

  @override
  String get clientVisitsBookAction => 'طلب الزيارة';

  @override
  String get clientVisitsInfoTitle => 'زيارة مجانية';

  @override
  String get clientVisitsInfoFree => 'الزيارة مجانية ولا تحتاج كوبون.';

  @override
  String clientVisitsInfoChat(String venue) {
    return 'ستفتح لكم محادثة مع $venue ودعم غزل لتأكيد الموعد.';
  }

  @override
  String clientVisitsInfoWindow(String minutes) {
    return 'مدة كل موعد $minutes دقيقة، ويمكنكم الوصول في أي وقت خلاله.';
  }

  @override
  String get clientVisitsSlotDay => 'اليوم';

  @override
  String get clientVisitsSlotMorning => 'صباحًا';

  @override
  String get clientVisitsSlotAfternoon => 'بعد الظهر';

  @override
  String get clientVisitsSlotEvening => 'مساءً';

  @override
  String get clientVisitsSlotTaken => 'محجوز';

  @override
  String clientVisitsNoWeek(String date) {
    return 'متاح من $date';
  }

  @override
  String get clientVisitsTakenNext => 'أقرب المواعيد';

  @override
  String get clientVisitsNotSent => 'فشل الإرسال';

  @override
  String get clientVisitsVisitors => 'الزوار';

  @override
  String clientVisitsVisitorsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ زائر',
      many: '⁦$countString⁩ زائرًا',
      few: '⁦$countString⁩ زوار',
      two: 'زائران',
      one: 'زائر واحد',
      zero: 'لا زوار',
    );
    return '$_temp0';
  }

  @override
  String get clientVisitsNoteLabel => 'ملاحظة للمكان';

  @override
  String get clientVisitsNote => 'ملاحظة';

  @override
  String get clientVisitsFactDay => 'اليوم';

  @override
  String get clientVisitsFactWindow => 'وقت الوصول';

  @override
  String get clientVisitsFactVisitors => 'الزوار';

  @override
  String get clientVisitsRequestedTitle => 'تم طلب الزيارة';

  @override
  String get clientVisitsOpenChat => 'فتح المحادثة';

  @override
  String get clientVisitsBackToVenue => 'المكان';

  @override
  String get clientVisitsRedirecting => 'جاري الفتح';

  @override
  String get clientVisitsStay => 'البقاء';

  @override
  String get clientVisitsSummary => 'تفاصيل الزيارة';

  @override
  String get clientVisitsStepsLabel => 'مراحل الزيارة';

  @override
  String get clientVisitsStepRequest => 'الطلب';

  @override
  String get clientVisitsStepConfirm => 'التأكيد';

  @override
  String get clientVisitsStepWay => 'في الطريق';

  @override
  String get clientVisitsStepArrival => 'الوصول';

  @override
  String get clientVisitsMembersOpen => 'أعضاء المحادثة';

  @override
  String get clientVisitsRoleHotel => 'الفندق';

  @override
  String get clientVisitsRoleSupport => 'الدعم';

  @override
  String get clientVisitsMembersTitle => 'أعضاء المحادثة';

  @override
  String get clientVisitsMembersPrivateTitle => 'خاصة';

  @override
  String get clientVisitsMembersPrivate =>
      'الثلاثة فقط يقرؤون هذه المحادثة، ولا تظهر أرقام الهواتف، ولا يمكن حظر دعم غزل.';

  @override
  String get clientVisitsMembersVenue => 'صفحة المكان';

  @override
  String get clientVisitsMembersReport => 'إبلاغ أو حظر';

  @override
  String get clientVisitsClosed => 'مغلقة';

  @override
  String get clientVisitsMessageVenue => 'مراسلة المكان';

  @override
  String get clientVisitsRecordTooShort => 'اضغطوا مطولًا للتسجيل';

  @override
  String get clientVisitsAttachTitle => 'إرفاق';

  @override
  String get clientVisitsPhotoViewer => 'الصور';

  @override
  String get clientVisitsGetVoucher => 'الكوبون';

  @override
  String get clientVisitsConfirmedToast => 'الموعد مؤكد';

  @override
  String get clientVisitsGuestTitle => 'زياراتكم';

  @override
  String get clientVisitsGuestAction => 'تسجيل الدخول';

  @override
  String get clientVisitsMsgSending => 'جاري الإرسال';

  @override
  String get clientVisitsMsgQueued => 'بانتظار الاتصال';

  @override
  String get clientVisitsMsgDelete => 'حذف';

  @override
  String get clientVisitsPinLabel => 'زيارتكم';

  @override
  String get clientVisitsConfirmTime => 'تأكيد';

  @override
  String get clientVisitsChangeOrCancel => 'تغيير أو إلغاء';

  @override
  String get clientVisitsOnTheWay => 'في الطريق';

  @override
  String get clientVisitsArrived => 'وصلنا';

  @override
  String get clientVisitsNeedsConnection => 'يلزم اتصال';

  @override
  String get clientVisitsChooseAnother => 'موعد آخر';

  @override
  String get clientVisitsSysOpened => 'بدأت المحادثة';

  @override
  String get clientVisitsSysConfirmed => 'الزيارة مؤكدة';

  @override
  String get clientVisitsSysProposed => 'وقت جديد مقترح';

  @override
  String get clientVisitsSysDeclined => 'غير متاح. المحادثة مغلقة.';

  @override
  String get clientVisitsSysCancelled => 'الزيارة ملغية. المحادثة مغلقة.';

  @override
  String get clientVisitsSysArrived => 'تم الوصول';

  @override
  String get clientVisitsSysCompleted => 'اكتملت الزيارة';

  @override
  String get clientVisitsSysClosed => 'المحادثة مغلقة';

  @override
  String get clientVisitsSysMissed => 'زيارة فائتة';

  @override
  String get clientVisitsSysAccepted => 'الموعد الجديد مقبول';

  @override
  String clientVisitsSysAsked(String when) {
    return 'طلبتم موعدًا آخر: $when';
  }

  @override
  String get clientVisitsTapOnTheWay => 'نحن في الطريق إليكم.';

  @override
  String get clientVisitsTapArrived => 'وصلنا.';

  @override
  String clientVisitsDemoSupport(String name) {
    return 'أهلًا $name، معاكم لمى من دعم غزل. أنا هنا معكم ومع الفندق لتأكيد وصولكم.';
  }

  @override
  String get clientVisitsDemoClient =>
      'السلام عليكم، نبي نزور القاعة أنا والوالدة.';

  @override
  String clientVisitsDemoHotelConfirm(String name, String day, String time) {
    return 'أهلًا $name. زيارتكم مؤكدة $day الساعة $time، وبنستقبلكم عند المدخل الرئيسي.';
  }

  @override
  String clientVisitsDemoHotelPropose(String name, String day, String time) {
    return '$name، هذا الموعد ما عاد متاحًا. يناسبكم $day الساعة $time؟';
  }

  @override
  String clientVisitsDemoHotelDecline(String name) {
    return 'شكرًا $name. ما نقدر نستقبل زيارات في هذا الوقت، وتقدرون تختارون يومًا آخر.';
  }

  @override
  String get clientVisitsDemoHere => 'وصلنا، نحن عند المدخل الرئيسي.';

  @override
  String get clientVisitsDemoPending =>
      'هل يوجد موقف للسيارات قريب من المدخل الرئيسي؟';

  @override
  String clientVisitsDemoHotelAck(String name) {
    return 'شكرًا $name، تم التسجيل. نراكم في الموعد.';
  }

  @override
  String clientVisitsDemoHotelAckRequested(String name) {
    return 'شكرًا $name. استلمنا طلبكم وبنؤكد الموعد قريبًا.';
  }

  @override
  String get clientVisitsListTitle => 'زياراتي';

  @override
  String get clientVisitsTabUpcoming => 'القادمة';

  @override
  String get clientVisitsTabPast => 'السابقة';

  @override
  String get clientVisitsEmptyTitle => 'لا زيارات';

  @override
  String get clientVisitsEmptyAction => 'تصفح القاعات';

  @override
  String get clientVisitsChangeTitle => 'زيارتكم';

  @override
  String get clientVisitsInfoFeeTitle => 'بلا رسوم';

  @override
  String get clientVisitsInfoNoFee => 'لا رسوم، ولا تخسرون شيئًا.';

  @override
  String clientVisitsInfoRecord(String venue) {
    return 'يظهر التغيير في المحادثة ويعلم $venue به.';
  }

  @override
  String get clientVisitsRowAsk => 'موعد آخر';

  @override
  String get clientVisitsRowCancel => 'إلغاء الزيارة';

  @override
  String get clientVisitsAskAction => 'إرسال الطلب';

  @override
  String get clientVisitsPickReason => 'اختيار السبب';

  @override
  String get clientVisitsReasonPlans => 'تغيرت الخطط';

  @override
  String get clientVisitsReasonOtherVenue => 'مكان آخر';

  @override
  String get clientVisitsReasonOther => 'أخرى';

  @override
  String get clientVisitsKeepVisit => 'إبقاء الزيارة';

  @override
  String get clientVisitsDoneAskTitle => 'تم الإرسال';

  @override
  String clientVisitsDoneAskDetail(String venue) {
    return 'سيرد $venue في المحادثة.';
  }

  @override
  String get clientVisitsDoneCancelTitle => 'تم الإلغاء';

  @override
  String clientVisitsDoneCancelDetail(String venue) {
    return 'لا رسوم. المحادثة مغلقة و$venue على علم.';
  }

  @override
  String get clientVisitsNothingChanged => 'لا تغيير';

  @override
  String get clientVouchersAskOpen => 'فتح محادثة الدعم';

  @override
  String clientVouchersAskText(String code) {
    return 'السلام عليكم، تعذّر استخدام الكوبون $code. هل يمكنكم إصدار كوبون رصيد؟';
  }

  @override
  String get clientVouchersAskTitle => 'استخدام أو دعم';

  @override
  String get clientVouchersAttachedToast => 'الكوبون مرتبط';

  @override
  String clientVouchersBackCredit(String date) {
    return 'استخدموه هنا حتى $date، أو اطلبوا كوبون رصيد من الدعم.';
  }

  @override
  String clientVouchersBackKept(String date) {
    return 'استخدموه هنا حتى $date.';
  }

  @override
  String get clientVouchersBackLine => 'يعود عند الاعتذار';

  @override
  String get clientVouchersBrowseHalls => 'تصفح القاعات';

  @override
  String get clientVouchersChooseAnother => 'اختيار آخر';

  @override
  String get clientVouchersChooseLabel => 'اختيار كوبون';

  @override
  String get clientVouchersCodeCopied => 'تم النسخ';

  @override
  String clientVouchersConsumedBody(String name) {
    return 'ألغيتم لدى $name بعد التأكيد، فاستهلك الكوبون.';
  }

  @override
  String get clientVouchersContact => 'التواصل';

  @override
  String clientVouchersCreditBody(String validity, String confirm) {
    return 'من دعم غزل. استخدموه لدى أي قاعة أو فندق أو خدمة خلال $validity، ثم أكدوا هناك خلال $confirm.';
  }

  @override
  String get clientVouchersCreditDeclined => 'لم يصدر كوبون رصيد';

  @override
  String get clientVouchersCreditIssuedBody =>
      'أصدر الدعم لكم كوبون رصيد، يصلح لدى أي قاعة أو فندق أو خدمة.';

  @override
  String get clientVouchersCtaSignIn => 'تسجيل الدخول';

  @override
  String get clientVouchersDetailTitle => 'الكوبون';

  @override
  String get clientVouchersEmptyHistory => 'لا سجل';

  @override
  String get clientVouchersEmptyReady => 'لا كوبونات';

  @override
  String get clientVouchersEmptyRequest => 'لا طلبات';

  @override
  String clientVouchersExpiredBody(String date) {
    return 'انتهت صلاحيته في $date دون استخدام.';
  }

  @override
  String get clientVouchersExplainerTitle => 'كيف يعمل';

  @override
  String get clientVouchersForRequestTitle => 'كوبونكم';

  @override
  String clientVouchersForfeitedBody(String hours) {
    return 'انتهت مهلة $hours للتأكيد لدى المكان أو الخدمة، فلم يعد الكوبون صالحًا ولا يعود.';
  }

  @override
  String get clientVouchersGetAnother => 'كوبون آخر';

  @override
  String get clientVouchersGetVoucher => 'شراء كوبون';

  @override
  String get clientVouchersGuestTitle => 'كوبوناتكم';

  @override
  String get clientVouchersHistPaid => 'الدفع';

  @override
  String get clientVouchersHistRequested => 'الطلب';

  @override
  String get clientVouchersHistReturned => 'عاد';

  @override
  String get clientVouchersHistoryLabel => 'سجل الكوبون';

  @override
  String get clientVouchersInfoBack => 'سبب العودة';

  @override
  String get clientVouchersInfoFit => 'السبب';

  @override
  String get clientVouchersInfoPay => 'دفع مباشر';

  @override
  String get clientVouchersInfoPaying => 'الدفع';

  @override
  String get clientVouchersInfoRequest => 'طلبكم';

  @override
  String get clientVouchersInfoUsedUp => 'تم استهلاكه';

  @override
  String clientVouchersInfoWaiting(String name) {
    return 'بانتظار رد $name. يبقى الكوبون مع هذا الطلب حتى يصل الرد.';
  }

  @override
  String get clientVouchersInfoWindow => 'مهلة التأكيد';

  @override
  String get clientVouchersInvalidSaving =>
      'مع هذه التعديلات يقلّ التوفير لدى المكان عن سعر الكوبون.';

  @override
  String clientVouchersInvalidTarget(String bound, String other) {
    return 'الكوبون يخص $bound، وطلبكم الآن موجّه إلى $other.';
  }

  @override
  String get clientVouchersKeep => 'إبقاء الكوبون';

  @override
  String get clientVouchersLabelConfirmBy => 'التأكيد حتى';

  @override
  String get clientVouchersLabelEvent => 'تاريخ المناسبة';

  @override
  String get clientVouchersLabelExpired => 'انتهى في';

  @override
  String get clientVouchersLabelExpires => 'ينتهي في';

  @override
  String get clientVouchersLabelHall => 'القاعة';

  @override
  String get clientVouchersLabelMethod => 'طريقة الدفع';

  @override
  String get clientVouchersLabelPackage => 'الباقة';

  @override
  String get clientVouchersLabelReuse => 'قابل للاستخدام حتى';

  @override
  String get clientVouchersLabelUsed => 'تاريخ الاستخدام';

  @override
  String get clientVouchersLabelValid => 'صالح حتى';

  @override
  String get clientVouchersNoLongerFits => 'لم يعد مناسبًا';

  @override
  String clientVouchersNoneBody(String name, String fee) {
    return 'الكوبون يتيح لكم طلب $name بسعر الكوبون. قيمته $fee وتدفع مرة واحدة إلكترونيًا.';
  }

  @override
  String get clientVouchersNoneTitle => 'يلزم كوبون';

  @override
  String get clientVouchersOfflineSaved => 'بلا اتصال، محفوظ بالهاتف';

  @override
  String get clientVouchersOnePer => 'كوبون واحد لكل طلب.';

  @override
  String get clientVouchersOwned => 'لديكم كوبون';

  @override
  String clientVouchersPayBody(String name) {
    return 'ادفعوا إلى $name مباشرةً بحسب الاتفاق. يمسح الفريق الرمز ثم يسجّل استخدامه.';
  }

  @override
  String clientVouchersPayFee(String fee) {
    return 'دفع $fee';
  }

  @override
  String get clientVouchersPayingBody =>
      'بانتظار تأكيد البنك، ويصبح الكوبون جاهزًا فور ذلك.';

  @override
  String get clientVouchersPhaseDirect => 'دفع مباشر';

  @override
  String get clientVouchersPhaseUsedUp => 'تم استهلاكه';

  @override
  String get clientVouchersPhaseWaiting => 'بانتظار الرد';

  @override
  String get clientVouchersPriceChanged => 'السعر محدّث';

  @override
  String get clientVouchersQrAwake => 'تبقى الشاشة مضاءة ومستيقظة أثناء العرض.';

  @override
  String clientVouchersQrLabel(String code) {
    return 'رمز الاستجابة السريعة للكوبون $code';
  }

  @override
  String get clientVouchersQuoteLabel => 'الاختيار المرتبط بالكوبون';

  @override
  String get clientVouchersRestore => 'استعادة الاختيار';

  @override
  String get clientVouchersRestoredToast => 'تمت الاستعادة';

  @override
  String get clientVouchersReuseOnly =>
      'يصدر الدعم كوبون رصيد فقط إذا تعذّر على المكان أو الخدمة قبول طلبكم. يمكنكم استخدام هذا الكوبون هنا مجددًا.';

  @override
  String get clientVouchersSegHistory => 'السجل';

  @override
  String get clientVouchersSegLabel => 'مجموعات الكوبونات';

  @override
  String get clientVouchersSegReady => 'جاهزة';

  @override
  String get clientVouchersSegRequest => 'ضمن طلب';

  @override
  String get clientVouchersSendRequest => 'إرسال الطلب';

  @override
  String get clientVouchersShowCode => 'عرض الرمز';

  @override
  String get clientVouchersStepDirect => 'دفع مباشر';

  @override
  String get clientVouchersStepRequest => 'الطلب';

  @override
  String get clientVouchersStepsLabel => 'خطوات الكوبون';

  @override
  String get clientVouchersStillFits => 'ما زال مناسبًا';

  @override
  String get clientVouchersSupport => 'الدعم';

  @override
  String clientVouchersTermBack(String days) {
    return 'إذا اعتذر المكان أو لم يرد أو ألغى، يعود الكوبون: استخدموه هنا خلال $days أو اطلبوا كوبون رصيد من الدعم.';
  }

  @override
  String clientVouchersTermDirect(String name) {
    return 'تدفعون إلى $name مباشرةً خارج التطبيق بعد التأكيد، وغزل ليست طرفًا في هذه الدفعة.';
  }

  @override
  String clientVouchersTermForfeit(String confirm) {
    return 'بعد الموافقة، أكدوا خلال $confirm بالدفع لدى المكان أو الخدمة، وإلا لم يعد الكوبون صالحًا.';
  }

  @override
  String get clientVouchersTermUsed =>
      'إذا ألغيتم بعد التأكيد، يستهلك الكوبون.';

  @override
  String clientVouchersTermValid(String validity) {
    return 'صالح $validity من يوم الدفع.';
  }

  @override
  String clientVouchersTermWhat(String fee, String name) {
    return 'كوبون بقيمة $fee يتيح لكم طلب $name بسعر الكوبون، وهو خاص بهذا الاختيار فقط.';
  }

  @override
  String clientVouchersTermWindows(String name, String reply, String confirm) {
    return 'يرد $name خلال $reply، وبعد الموافقة تؤكدون خلال $confirm.';
  }

  @override
  String get clientVouchersTermWithdraw =>
      'إذا سحبتم الطلب قبل الموافقة، تستخدمونه هنا مجددًا.';

  @override
  String get clientVouchersTermsTitle => 'شروط الكوبون';

  @override
  String get clientVouchersTooSmallBody =>
      'في هذا الاختيار لن يوفّر الكوبون أكثر من قيمته، لذلك لا نعرضه. تواصلوا مع المكان وادفعوا السعر العادي.';

  @override
  String get clientVouchersTooSmallTitle => 'لا حاجة لكوبون';

  @override
  String get clientVouchersUseAgain => 'استخدام مجددًا';

  @override
  String get clientVouchersUseThis => 'استخدام الكوبون';

  @override
  String get clientVouchersUsedUpBody => 'ألغيتم بعد التأكيد، فاستهلك الكوبون.';

  @override
  String get clientVouchersViewReceipt => 'عرض الإيصال';

  @override
  String get clientVouchersViewReceiptShort => 'الإيصال';

  @override
  String get clientVouchersViewRequest => 'عرض الطلب';

  @override
  String get clientVouchersWalletTitle => 'كوبوناتي';

  @override
  String clientVouchersWhyDeclined(String name) {
    return 'لم يتمكن $name من قبول الطلب.';
  }

  @override
  String clientVouchersWhyNoResponse(String name) {
    return 'لم يرد $name في الوقت المحدد.';
  }

  @override
  String clientVouchersWhyRevoked(String name) {
    return 'سحب $name موافقته.';
  }

  @override
  String get clientVouchersWhySlotTaken => 'حجز طلب آخر هذا التاريخ.';

  @override
  String clientVouchersWhySuspended(String name) {
    return 'استقبال الطلبات متوقف لدى $name حاليًا.';
  }

  @override
  String clientVouchersWhyVenueCancelled(String name) {
    return 'ألغى $name الحجز.';
  }

  @override
  String get clientVouchersWhyWithdrawn => 'سحبتم الطلب.';

  @override
  String get clientVouchersWindowBody =>
      'التاريخ محجوز حتى انتهاء المهلة، وبعدها تنتهي الموافقة ولا يعود الكوبون صالحًا.';

  @override
  String get clientVouchersWindowLeft => 'الوقت المتبقي للتأكيد';

  @override
  String get clientVouchersWordDeclined => 'اعتذر المكان';

  @override
  String get clientVouchersWordNoResponse => 'لم يرد';

  @override
  String get clientVouchersWordRevoked => 'موافقة ملغاة';

  @override
  String get clientVouchersWordSlotTaken => 'التاريخ محجوز';

  @override
  String get clientVouchersWordSuspended => 'متوقف';

  @override
  String get clientVouchersWordVenueCancelled => 'ألغاه المكان';

  @override
  String get clientVouchersWordWithdrawn => 'تم السحب';
}
