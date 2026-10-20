// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'gz_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class GzL10nAr extends GzL10n {
  GzL10nAr([String locale = 'ar']) : super(locale);

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
  String get stubNotBuilt => 'لم تُبنَ بعد';
}
