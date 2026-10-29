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
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat currentNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
  String get commonStateErrorGeneric => 'حدث خطأ من جانبنا. لم يتم تغيير أي شيء. يُرجى المحاولة مرة أخرى.';

  @override
  String get commonStateErrorLoad => 'تعذّر تحميل المحتوى. يُرجى المحاولة مرة أخرى.';

  @override
  String get commonStateErrorNetwork => 'تعذّر الاتصال. يُرجى التأكد من الاتصال بالإنترنت والمحاولة مرة أخرى.';

  @override
  String get commonStateErrorPayment => 'تعذّر إتمام الدفع. لم يُخصم أي مبلغ.';

  @override
  String get commonStateErrorNoAccess => 'لا تملكون صلاحية الوصول. يُرجى مراجعة المدير.';

  @override
  String get commonStateErrorNotFound => 'هذه الصفحة لم تعد متاحة.';

  @override
  String get commonStateSaved => 'تم الحفظ';

  @override
  String get commonStateCopied => 'تم النسخ';

  @override
  String get commonStateSent => 'تم الإرسال';

  @override
  String get commonNoPaymentNowFull => 'لا دفع الآن. لا يُخصم أي مبلغ قبل موافقة الفندق.';

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
    final intl.NumberFormat currentNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'صورة ⁦$currentString⁩ من ⁦$totalString⁩';
  }

  @override
  String commonA11yRating(num rating, num max) {
    final intl.NumberFormat ratingNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String ratingString = ratingNumberFormat.format(rating);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat hoursNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat hoursNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
  String get commonReviewAskSupportHide => 'اطلبوا من الدعم إخفاء المراجعة أو حذفها';

  @override
  String commonVideoLimit(String size) {
    return 'حتى $size ميغابايت للفيديو الواحد';
  }

  @override
  String get uiClientBriefCardDate => 'التاريخ';

  @override
  String get uiClientBriefCardArea => 'المحافظة';

  @override
  String get uiClientBriefCardGuests => 'الضيوف';

  @override
  String get uiClientBriefCardBudget => 'الميزانية';

  @override
  String get uiClientBriefCardNameDate => 'التاريخ';

  @override
  String get uiClientBriefCardNameArea => 'المحافظة';

  @override
  String get uiClientBriefCardNameGuests => 'عدد الضيوف';

  @override
  String get uiClientBriefCardNameBudget => 'ميزانية القاعة والضيافة';

  @override
  String uiClientBriefCardRow(String label, String value) {
    return '$label: $value';
  }

  @override
  String get uiClientBriefCardShowHalls => 'عرض القاعات';

  @override
  String uiClientBriefCardShowCount(String count) {
    return 'عرض $count';
  }

  @override
  String uiClientBriefCardMore(String n) {
    return '+$n';
  }

  @override
  String get uiClientBriefCardTitle => 'تفاصيل زفافكم';

  @override
  String get uiClientBriefSentenceWomen => 'حفل نسائي';

  @override
  String get uiClientBriefSentenceMen => 'حفل رجالي';

  @override
  String get uiClientBriefSentenceMixed => 'حفل مختلط';

  @override
  String get uiClientBriefSentenceReception => 'حفل';

  @override
  String get uiClientBriefSentenceForGuests => 'لعدد';

  @override
  String get uiClientBriefSentenceOn => 'يوم';

  @override
  String get uiClientBriefSentenceIn => 'في';

  @override
  String get uiClientBriefSentenceBudgetOf => 'بميزانية';

  @override
  String get uiClientBriefSentenceChooseGuests => 'إضافة الضيوف';

  @override
  String get uiClientBriefSentenceChooseDate => 'اختيار التاريخ';

  @override
  String get uiClientBriefSentenceChooseArea => 'اختيار المحافظة';

  @override
  String get uiClientBriefSentenceChooseBudget => 'تحديد الميزانية';

  @override
  String uiClientBriefSentenceField(String what) {
    return 'تغيير $what';
  }

  @override
  String get uiClientBriefSentenceWhatDate => 'التاريخ';

  @override
  String get uiClientBriefSentenceWhatGuests => 'عدد الضيوف';

  @override
  String get uiClientBriefSentenceWhatArea => 'المحافظة';

  @override
  String get uiClientBriefSentenceWhatBudget => 'الميزانية';

  @override
  String get uiClientBriefSentenceEditLabel => 'تعديل التاريخ والضيوف والمنطقة والميزانية';

  @override
  String get uiClientVoucherWindowEyebrow => 'سعر الكوبون';

  @override
  String uiClientVoucherWindowEvents(String window) {
    return 'للمناسبات $window';
  }

  @override
  String uiClientVoucherWindowEventsOn(String days) {
    return 'للمناسبات يوم $days';
  }

  @override
  String get uiClientVoucherWindowEventsDates => 'للمناسبات في تواريخ محددة';

  @override
  String uiClientVoucherWindowUntil(String date) {
    return 'السعر متاح حتى $date';
  }

  @override
  String get uiClientVoucherWindowView => 'عرض القاعة';

  @override
  String get uiClientVoucherWindowEnded => 'انتهى هذا السعر';

  @override
  String get uiClientVoucherWindowScheduled => 'يبدأ قريبًا';

  @override
  String uiClientVoucherWindowFromTo(String from, String to) {
    return 'من $from إلى $to';
  }

  @override
  String get uiClientCountdownEyebrow => 'زفافكم';

  @override
  String uiClientCountdownUnit(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'يوم', many: 'يومًا', few: 'أيام', two: 'يومان', one: 'يوم', zero: 'يوم');
    return '$_temp0';
  }

  @override
  String get uiClientCountdownToGo => 'حتى زفافكم';

  @override
  String get uiClientCountdownYear => 'عام كامل من التحضير أمامكم.';

  @override
  String get uiClientCountdownHalf => 'ستة أشهر تفصلكم عن الحفل.';

  @override
  String get uiClientCountdownMonth => 'شهر واحد يفصلكم عن الحفل، وقت مناسب لحسم التفاصيل.';

  @override
  String get uiClientCountdownWeek => 'أسبوع واحد يفصلكم عن الحفل. تم تثبيت عدد الضيوف.';

  @override
  String get uiClientCountdownTomorrowLine => 'كل شيء جاهز ليوم غدٍ.';

  @override
  String get uiClientCountdownTodayLine => 'اليوم يومكم.';

  @override
  String get uiClientCountdownProgress => 'الوقت المنقضي من الانتظار';

  @override
  String get uiClientCountdownTomorrow => 'غدًا';

  @override
  String get uiClientCountdownToday => 'اليوم';

  @override
  String get uiClientVenueCardTagWomen => 'نسائي';

  @override
  String get uiClientVenueCardTagMen => 'رجالي';

  @override
  String get uiClientVenueCardTagMixed => 'مختلط';

  @override
  String get uiClientVenueCardBookedOnDate => 'محجوز في تاريخكم';

  @override
  String get uiClientVenueCardGovernment => 'الحجز عبر وزارة الشؤون الاجتماعية';

  @override
  String get uiClientVenueCardGovernmentTag => 'قاعة حكومية';

  @override
  String get uiClientVenueCardFeatured => 'مميزة';

  @override
  String get uiClientVenueCardWindow => 'سعر كوبون خاص';

  @override
  String get uiClientVenueCardNoPhotos => 'الصور قريبًا';

  @override
  String get uiClientVenueCardHasVideo => 'يتوفر جولة مرئية';

  @override
  String get uiClientVenueCardPriceDropped => 'انخفض السعر';

  @override
  String get uiClientVenueCardSelect => 'اختيار هذه القاعة';

  @override
  String uiClientVenueCardPhotosOf(String name) {
    return 'صور $name';
  }

  @override
  String uiClientVenueCardOpen(String name) {
    return 'فتح $name';
  }

  @override
  String get uiClientCompareAddOne => 'أضيفوا قاعة أخرى للمقارنة';

  @override
  String get uiClientCompareCompare => 'مقارنة';

  @override
  String uiClientCompareRemoveFrom(String name) {
    return 'إزالة $name من المقارنة';
  }

  @override
  String get uiClientCompareClear => 'مسح المقارنة';

  @override
  String get uiClientCompareExpand => 'عرض شريط المقارنة';

  @override
  String uiClientCompareEmptySlot(String n) {
    return 'خانة فارغة $n';
  }

  @override
  String uiClientCompareTrayLabel(String pair) {
    return 'مقارنة ($pair)';
  }

  @override
  String get uiClientCompareBest => 'الأفضل في هذا الصف';

  @override
  String get uiClientCompareDifferences => 'الفروقات فقط';

  @override
  String uiClientCompareHidden(String n) {
    return 'تم إخفاء $n من الصفوف المتشابهة';
  }

  @override
  String get uiClientCompareHiddenOne => 'تم إخفاء صف متشابه واحد';

  @override
  String get uiClientCompareAllShown => 'عرض كل الصفوف';

  @override
  String get uiClientCompareNoLonger => 'لم تعد مدرجة';

  @override
  String uiClientCompareYours(String n) {
    return 'عددكم $n';
  }

  @override
  String uiClientCompareOpen(String name) {
    return 'فتح $name';
  }

  @override
  String uiClientComparePick(String name) {
    return 'اختيار $name';
  }

  @override
  String uiClientCompareUnpick(String name) {
    return 'إلغاء اختيار $name';
  }

  @override
  String get uiClientCompareGroupDate => 'تاريخكم';

  @override
  String get uiClientCompareGroupPrice => 'السعر';

  @override
  String get uiClientCompareGroupCapacity => 'السعة والتجهيز';

  @override
  String get uiClientCompareGroupFacilities => 'المرافق';

  @override
  String get uiClientCompareRating => 'التقييم';

  @override
  String get uiClientCompareGroupDistance => 'المسافة';

  @override
  String get uiClientCompareGroupBooking => 'النوع والتسعير';

  @override
  String get uiClientComparePhotos => 'الصور';

  @override
  String get uiClientCompareRowAvailability => 'التوفر';

  @override
  String get uiClientCompareRowPriceDate => 'سعر الكوبون لتاريخكم';

  @override
  String get uiClientCompareRowPriceFrom => 'سعر الكوبون ابتداءً من';

  @override
  String get uiClientCompareRowStandard => 'السعر العادي';

  @override
  String get uiClientCompareRowSavings => 'توفّرون';

  @override
  String get uiClientCompareNoVoucher => 'لا يوجد سعر كوبون';

  @override
  String get uiClientCompareRowPerGuest => 'للضيف';

  @override
  String get uiClientCompareRowCapacity => 'أكبر قاعة';

  @override
  String get uiClientCompareRowValet => 'فاليه';

  @override
  String get uiClientCompareRowPhotography => 'التصوير';

  @override
  String uiClientCompareRowDistance(String origin) {
    return 'المسافة من $origin';
  }

  @override
  String get uiClientCompareRowPackages => 'الباقات';

  @override
  String get uiClientCompareRowType => 'نوع المكان';

  @override
  String get uiClientComparePickDate => 'اختاروا تاريخًا';

  @override
  String get uiClientCompareIncluded => 'مشمول';

  @override
  String get uiClientCompareExtra => 'برسوم إضافية';

  @override
  String get uiClientCompareNotOffered => 'غير متوفر';

  @override
  String get uiClientCompareWomenOnly => 'مصوّرات فقط';

  @override
  String get uiClientCompareAllowed => 'مسموح';

  @override
  String get uiClientCompareNotAllowed => 'غير مسموح';

  @override
  String uiClientCompareFits(String n) {
    return 'تستوعب $n';
  }

  @override
  String uiClientCompareBelow(String n) {
    return 'أقل من $n';
  }

  @override
  String uiClientCompareUpTo(String n) {
    return 'حتى $n';
  }

  @override
  String get uiClientComparePerGuestUnit => 'للضيف';

  @override
  String get uiClientCompareGetVoucher => 'الحصول على كوبون';

  @override
  String get uiClientCompareOfficial => 'رسمي';

  @override
  String get uiClientCompareSeeDates => 'التواريخ';

  @override
  String get uiClientCompareBestRated => 'الأعلى تقييمًا';

  @override
  String get uiClientCompareLowest => 'الأقل سعرًا';

  @override
  String get uiClientCompareClosest => 'الأقرب';

  @override
  String get uiClientCompareTypeOfficial => 'القناة الرسمية';

  @override
  String get uiClientComparePerPerson => 'سعر للضيف';

  @override
  String get uiClientComparePackagesWord => 'باقات';

  @override
  String get uiClientCompareBoth => 'الاثنان';

  @override
  String get uiClientReviewAnonymous => 'ضيف';

  @override
  String get uiClientReviewVerified => 'حجز موثّق';

  @override
  String uiClientReviewReply(String venue) {
    return 'ردّ من $venue';
  }

  @override
  String get uiClientReviewMore => 'قراءة المزيد';

  @override
  String get uiClientReviewLess => 'عرض أقل';

  @override
  String get uiClientReviewPhotos => 'صور من هذه المناسبة';

  @override
  String get uiClientReviewLadies => 'الحفل النسائي';

  @override
  String get uiClientReviewMen => 'الحفل الرجالي';

  @override
  String get uiClientReviewCatVenue => 'القاعة';

  @override
  String get uiClientReviewCatFood => 'الطعام';

  @override
  String get uiClientReviewCatService => 'الخدمة';

  @override
  String get uiClientReviewCatValue => 'القيمة';

  @override
  String get uiClientReviewNone => 'لا توجد تقييمات بعد. سيكتب الضيوف الأوائل هنا بعد مناسبتهم.';

  @override
  String uiClientReviewScore(String label, String value) {
    return '$label: $value';
  }

  @override
  String get uiClientVenueInfoGroupSpace => 'المساحات';

  @override
  String get uiClientVenueInfoGroupService => 'الخدمات';

  @override
  String get uiClientVenueInfoGroupProduction => 'الإنتاج';

  @override
  String get uiClientVenueInfoGroupPolicy => 'قواعد المكان';

  @override
  String get uiClientVenueInfoIncluded => 'مشمول';

  @override
  String get uiClientVenueInfoExtra => 'إضافة';

  @override
  String uiClientVenueInfoExtraFrom(String price) {
    return 'إضافة، تبدأ من $price';
  }

  @override
  String get uiClientVenueInfoNotOffered => 'غير متوفر';

  @override
  String uiClientVenueInfoShowAll(String n) {
    return 'عرض كل المرافق ($n)';
  }

  @override
  String get uiClientVenueInfoShowLess => 'عرض أقل';

  @override
  String get uiClientVenueInfoPhotography => 'التصوير';

  @override
  String get uiClientVenueInfoMusic => 'الموسيقى';

  @override
  String get uiClientVenueInfoEntrance => 'المدخل';

  @override
  String get uiClientVenueInfoCloakroom => 'غرفة العبايات';

  @override
  String get uiClientVenueInfoPrayer => 'المصلى';

  @override
  String get uiClientVenueInfoSecurity => 'الحراسة';

  @override
  String get uiClientVenueInfoBoys => 'الأولاد';

  @override
  String get uiClientVenueInfoCatering => 'الضيافة الخارجية';

  @override
  String get uiClientVenueInfoDecor => 'الديكور الخارجي';

  @override
  String get uiClientVenueInfoBukhoor => 'البخور';

  @override
  String get uiClientVenueInfoCutOff => 'نهاية المناسبة';

  @override
  String get uiClientVenueInfoExtraHour => 'ساعة إضافية';

  @override
  String get uiClientVenueInfoBackup => 'قاعة بديلة داخلية';

  @override
  String get uiClientVenueInfoPhotoFemale => 'مصوّرات فقط';

  @override
  String get uiClientVenueInfoPhotoAllowed => 'التصوير مسموح';

  @override
  String get uiClientVenueInfoPhotoNone => 'لا تصوير';

  @override
  String get uiClientVenueInfoMusicBand => 'منسّق أو فرقة';

  @override
  String get uiClientVenueInfoMusicLive => 'موسيقى حيّة';

  @override
  String get uiClientVenueInfoMusicDuff => 'دفوف وأناشيد فقط';

  @override
  String get uiClientVenueInfoMusicNone => 'بلا موسيقى';

  @override
  String get uiClientVenueInfoNo => 'غير متوفر';

  @override
  String get uiClientVenueInfoSeparate => 'مدخل منفصل';

  @override
  String get uiClientVenueInfoSecurityFemale => 'حراسة نسائية';

  @override
  String uiClientVenueInfoBoysUpTo(String n) {
    return 'حتى عمر $n سنوات';
  }

  @override
  String get uiClientVenueInfoBoysAny => 'لجميع الأعمار';

  @override
  String get uiClientVenueInfoAllowed => 'مسموح';

  @override
  String get uiClientVenueInfoApproval => 'بموافقة المكان';

  @override
  String get uiClientVenueInfoNotAllowed => 'غير مسموح';

  @override
  String get uiClientVenueInfoAvailable => 'متوفرة';

  @override
  String get uiClientVenueInfoMapOpen => 'فتح في الخرائط';

  @override
  String uiClientVenueInfoMapDrive(String time, String origin) {
    return '$time من $origin';
  }

  @override
  String uiClientVenueInfoMapPin(String name) {
    return 'موقع $name';
  }

  @override
  String uiClientVenueInfoBlock(String n) {
    return 'قطعة $n';
  }

  @override
  String get uiClientCompareDiffOnly => 'الفروقات';

  @override
  String get uiClientCompareDiffAll => 'الكل';

  @override
  String get uiClientCompareDiffLabel => 'الصفوف المعروضة';

  @override
  String get uiClientCompareHowVoucher => 'بالكوبون';

  @override
  String get uiClientCompareHowStandard => 'سعر عادي فقط';

  @override
  String get uiClientCompareRowHow => 'طريقة الحجز';

  @override
  String get uiClientCompareBarVoucher => 'كوبون';

  @override
  String get uiClientCompareBarDates => 'التواريخ';

  @override
  String get uiClientCompareBarOfficial => 'رسمي';

  @override
  String uiClientCompareDriveMinutes(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString دقيقة',
      many: '$countString دقيقة',
      few: '$countString دقائق',
      two: 'دقيقتان',
      one: 'دقيقة',
      zero: 'أقل من دقيقة',
    );
    return '$_temp0';
  }

  @override
  String uiClientChecklistDone(String done, String total) {
    return 'تم إنجاز $done من $total';
  }

  @override
  String get uiClientChecklistProgress => 'تقدم القائمة';

  @override
  String uiClientChecklistDue(String date) {
    return 'الموعد $date';
  }

  @override
  String uiClientChecklistOverdue(String date) {
    return 'تأخر منذ $date';
  }

  @override
  String get uiClientChecklistNoDate => 'بلا موعد';

  @override
  String get uiClientChecklistAuto => 'يكتمل عند تأكيد الحجز';

  @override
  String uiClientChecklistCompletedOn(String date) {
    return 'تم $date';
  }

  @override
  String get uiClientChecklistChoose => 'اختيار';

  @override
  String get uiClientChecklistYours => 'مهمتكم';

  @override
  String get uiClientBudgetTotal => 'ميزانية الزفاف';

  @override
  String get uiClientBudgetPaid => 'المدفوع';

  @override
  String get uiClientBudgetCommitted => 'الملتزم به';

  @override
  String get uiClientBudgetRemaining => 'المتبقي';

  @override
  String uiClientBudgetOf(String paid, String allocated) {
    return '$paid من $allocated';
  }

  @override
  String uiClientBudgetOver(String amount) {
    return 'تجاوز بمقدار $amount';
  }

  @override
  String uiClientBudgetAlertCategory(String name) {
    return 'تجاوزت «$name» حصتها من الميزانية.';
  }

  @override
  String get uiClientBudgetAlertTotal => 'خططكم أعلى من إجمالي الميزانية.';

  @override
  String get uiClientBudgetLinked => 'مرتبط بحجزكم';

  @override
  String get uiClientBudgetCategories => 'حسب الفئة';

  @override
  String uiClientBudgetBarLabel(String paid, String paidAmount, String committed, String committedAmount, String remaining, String remainingAmount) {
    return '$paid: $paidAmount، $committed: $committedAmount، $remaining: $remainingAmount';
  }

  @override
  String get uiClientTierSuits => 'مناسبة لـ';

  @override
  String get uiClientTierConsult => 'طلب استشارة';

  @override
  String uiClientTierMarks(String n) {
    return '$n من 3 علامات';
  }

  @override
  String uiClientServiceOpen(String name) {
    return 'فتح $name';
  }

  @override
  String get uiClientVendorVerified => 'موثّق';

  @override
  String get uiClientVendorFemaleTeam => 'فريق نسائي للقاعات النسائية';

  @override
  String uiClientVendorReplies(String time) {
    return 'يرد عادةً خلال $time';
  }

  @override
  String get uiClientChatSent => 'أُرسلت';

  @override
  String get uiClientChatDelivered => 'وصلت';

  @override
  String get uiClientChatRead => 'قُرئت';

  @override
  String get uiClientChatPlay => 'تشغيل الرسالة الصوتية';

  @override
  String get uiClientChatPause => 'إيقاف الرسالة الصوتية';

  @override
  String get uiClientChatVoice => 'رسالة صوتية';

  @override
  String get uiClientChatPhoto => 'صورة';

  @override
  String uiClientChatDownload(String name) {
    return 'تنزيل $name';
  }

  @override
  String get uiClientChatOpenPhoto => 'فتح الصورة';

  @override
  String get uiClientChatPdf => 'PDF';

  @override
  String uiClientChatKb(String n) {
    return '$n ك.ب';
  }

  @override
  String get uiClientChatDraft => 'مسودة';

  @override
  String get uiClientChatYou => 'أنتم: ';

  @override
  String get uiClientChatPinned => 'مثبتة';

  @override
  String uiClientChatUnread(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
  String get uiClientThreadVoucher => 'الكوبون';

  @override
  String get uiClientThreadRequest => 'الطلب';

  @override
  String get uiClientThreadApproval => 'الموافقة';

  @override
  String get uiClientThreadConfirmation => 'التأكيد';

  @override
  String get uiClientThreadRedemption => 'الاستخدام';

  @override
  String get uiClientThreadVoucherLong => 'شراء الكوبون';

  @override
  String get uiClientThreadRequestLong => 'إرسال الطلب';

  @override
  String get uiClientThreadApprovalLong => 'موافقة المكان';

  @override
  String get uiClientThreadConfirmationLong => 'تأكيدكم';

  @override
  String get uiClientThreadRedemptionLong => 'تم الاستخدام';

  @override
  String get uiClientThreadConfirmationStep => 'التأكيد';

  @override
  String get uiClientThreadRedemptionStep => 'في القاعة';

  @override
  String get uiClientThreadConfirmationStepLong => 'تأكيدكم';

  @override
  String get uiClientThreadRedemptionStepLong => 'في القاعة';

  @override
  String get uiClientThreadNotRedeemed => 'لم يُستخدم';

  @override
  String get uiClientThreadLabel => 'مراحل الحجز';

  @override
  String uiClientThreadStepOf(String n, String total) {
    return 'المرحلة $n من $total';
  }

  @override
  String get uiClientBookingCardDate => 'التاريخ';

  @override
  String get uiClientBookingCardVoucherPrice => 'سعر الكوبون';

  @override
  String get uiClientBookingCardQuantity => 'الكمية';

  @override
  String uiClientBookingCardOpen(String ref) {
    return 'فتح الحجز $ref';
  }

  @override
  String uiClientBookingCardConfirmBy(String when, String left) {
    return 'التأكيد حتى $when · $left';
  }

  @override
  String get uiClientPackageHallOnly => 'تأجير القاعة';

  @override
  String get uiClientPackagePlus => 'إضافة إلى';

  @override
  String uiClientPackageForGuests(String guests) {
    return 'لعدد $guests';
  }

  @override
  String uiClientPackageUpTo(String guests) {
    return 'حتى $guests';
  }

  @override
  String get uiClientPackageIncluded => 'يشمل';

  @override
  String get uiClientPackageNotCovered => 'للعلم';

  @override
  String get uiClientPackageSelected => 'تم اختيار هذه الباقة';

  @override
  String get uiClientPackageUnavailable => 'غير متاحة في تاريخكم';

  @override
  String uiClientPackageShowAll(String n) {
    return 'عرض كل المشمولات ($n)';
  }

  @override
  String get uiClientPackageShowLess => 'عرض أقل';

  @override
  String get uiClientPackageLadies => 'نسائي';

  @override
  String get uiClientPackageMen => 'رجالي';

  @override
  String get uiClientPackageMixed => 'مختلط';

  @override
  String get uiClientBreakdownLines => 'تفاصيل السعر';

  @override
  String get uiClientBreakdownStandardTotal => 'السعر العادي';

  @override
  String get uiClientBreakdownVoucherTotal => 'سعر الكوبون';

  @override
  String get uiClientBreakdownSave => 'توفّرون';

  @override
  String get uiClientBreakdownWho => 'لمن تدفعون';

  @override
  String get uiClientBreakdownGhazal => 'غزل · الكوبون';

  @override
  String get uiClientBreakdownGhazalPaid => 'تم دفعه مرة واحدة عند شراء الكوبون';

  @override
  String uiClientBreakdownVenue(String venue) {
    return '$venue · مباشرة';
  }

  @override
  String get uiClientBreakdownVenueReview => 'بعد التأكيد تدفعون للمكان مباشرة بهذا السعر.';

  @override
  String get uiClientBreakdownVenueConfirmed => 'ادفعوا للمكان مباشرة، ثم اعرضوا رمز الكوبون.';

  @override
  String get uiClientBreakdownVenueRedeemed => 'تمت التسوية مع المكان وتم استخدام الكوبون.';

  @override
  String get uiClientBreakdownInclusive => 'السعر شامل وفق شروط المكان. غزل لا تضيف أي مبلغ.';

  @override
  String get uiClientBreakdownNoMore => 'لا مبلغ إضافي لغزل.';

  @override
  String get uiClientPaymentKnet => 'كي نت';

  @override
  String get uiClientPaymentKnetNote => 'بطاقات البنوك الكويتية';

  @override
  String get uiClientPaymentVisa => 'فيزا';

  @override
  String get uiClientPaymentMastercard => 'ماستركارد';

  @override
  String get uiClientPaymentCardNote => 'بطاقة ائتمان أو خصم';

  @override
  String get uiClientPaymentApplePay => 'Apple Pay';

  @override
  String get uiClientPaymentApplePayNote => 'بالبطاقة المحفوظة في جهازكم';

  @override
  String get uiClientPaymentGooglePay => 'Google Pay';

  @override
  String get uiClientPaymentGooglePayNote => 'بالبطاقة المحفوظة في جهازكم';

  @override
  String get uiClientPaymentRecommended => 'موصى بها عند بلوغ حد كي نت';

  @override
  String get uiClientPaymentUnavailable => 'غير متاحة على هذا الجهاز';

  @override
  String get uiClientPaymentSelected => 'محددة';

  @override
  String get uiClientReceiptTitle => 'إيصال';

  @override
  String get uiClientReceiptIssuer => 'غزل';

  @override
  String get uiClientReceiptNumber => 'رقم الإيصال';

  @override
  String get uiClientReceiptVoucherCode => 'رمز الكوبون';

  @override
  String get uiClientReceiptIssued => 'تاريخ الدفع';

  @override
  String get uiClientReceiptVia => 'وسيلة الدفع';

  @override
  String uiClientReceiptLine(String name) {
    return 'كوبون خاص بـ $name';
  }

  @override
  String get uiClientReceiptTotal => 'الإجمالي';

  @override
  String get uiClientReceiptFooter => 'صادر بالدينار الكويتي (KWD). أرقام غربية بثلاث خانات عشرية.';

  @override
  String get uiClientNotificationUnread => 'غير مقروء';

  @override
  String get uiClientNotificationMarketing => 'عرض';

  @override
  String get uiClientProviderNoteText => 'هل أنت مزوّد خدمة؟ قدّم طلبك في تطبيق الشريك';

  @override
  String get uiClientProviderNoteCta => 'تقديم';

  @override
  String get uiFiltersCapacityFrom => 'من';

  @override
  String get uiFiltersCapacityTo => 'إلى';

  @override
  String uiFiltersCapacitySummary(String range) {
    return '$range ضيف';
  }

  @override
  String get uiFiltersCapacityMin => 'أقل عدد من الضيوف';

  @override
  String get uiFiltersCapacityMax => 'أكثر عدد من الضيوف';

  @override
  String uiHotelTimeLeft(String time) {
    return 'باقي $time';
  }

  @override
  String get uiHotelRowNew => 'جديد';

  @override
  String get uiHotelCardPackage => 'الباقة';

  @override
  String get uiHotelCardVoucherPrice => 'سعر الكوبون';

  @override
  String get uiHotelCardNoOther => 'لا توجد طلبات أخرى لهذا التاريخ';

  @override
  String get uiHotelCardVerified => 'رقم موثّق';

  @override
  String get uiHotelCardFirstBooking => 'أول حجز';

  @override
  String get uiHotelCardCompare => 'مقارنة';

  @override
  String get uiHotelCardHeld => 'التاريخ محجوز';

  @override
  String get uiHotelCardHeldReason => 'التاريخ محجوز مؤقتًا';

  @override
  String get uiHotelCardConfirmBy => 'يؤكد العميل حتى';

  @override
  String get uiHotelCardUndoMessage => 'تمت الموافقة على الطلب';

  @override
  String uiHotelCardChat(String name) {
    return 'مراسلة $name';
  }

  @override
  String uiHotelCardCall(String name) {
    return 'الاتصال بـ$name';
  }

  @override
  String uiHotelCardOpen(String date) {
    return 'فتح الطلب: $date';
  }

  @override
  String get uiHotelCardTagWomen => 'نسائي';

  @override
  String get uiHotelCardTagMen => 'رجالي';

  @override
  String get uiHotelCardTagMixed => 'مختلط';

  @override
  String get uiHotelCardHours => 'الوقت';

  @override
  String get uiHotelCardSpecialRequests => 'طلبات خاصة';

  @override
  String uiHotelCardOthers(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'طلب آخر لهذا التاريخ',
      many: 'طلبًا آخر لهذا التاريخ',
      few: 'طلبات أخرى لهذا التاريخ',
      two: 'طلبان آخران لهذا التاريخ',
      one: 'طلب آخر لهذا التاريخ',
      zero: 'لا طلبات أخرى لهذا التاريخ',
    );
    return '$_temp0';
  }

  @override
  String get uiHotelTimelineNow => 'الآن';

  @override
  String get uiHotelTimelineEmpty => 'لا شيء مجدول اليوم';

  @override
  String get uiHotelStripConfirmed => 'مؤكد';

  @override
  String get uiHotelStripPending => 'بانتظار الرد أو محجوز مؤقتًا';

  @override
  String get uiHotelStripOpen => 'متاح';

  @override
  String get uiHotelStripToday => 'اليوم';

  @override
  String get uiHotelStripSep => '، ';

  @override
  String uiHotelStripConfirmedCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString حجز مؤكد',
      many: '$countString حجزًا مؤكدًا',
      few: '$countString حجوزات مؤكدة',
      two: 'حجزان مؤكدان',
      one: 'حجز مؤكد',
      zero: 'لا حجوزات مؤكدة',
    );
    return '$_temp0';
  }

  @override
  String uiHotelStripPendingCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString طلب بانتظار الرد',
      many: '$countString طلبًا بانتظار الرد',
      few: '$countString طلبات بانتظار الرد',
      two: 'طلبان بانتظار الرد',
      one: 'طلب بانتظار الرد',
      zero: 'لا طلبات بانتظار الرد',
    );
    return '$_temp0';
  }

  @override
  String uiHotelStripOpenCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString فترة متاحة',
      many: '$countString فترة متاحة',
      few: '$countString فترات متاحة',
      two: 'فترتان متاحتان',
      one: 'فترة متاحة',
      zero: 'لا فترات متاحة',
    );
    return '$_temp0';
  }

  @override
  String uiHotelKpiUp(String pct) {
    return 'ارتفاع $pct';
  }

  @override
  String uiHotelKpiDown(String pct) {
    return 'انخفاض $pct';
  }

  @override
  String get uiHotelKpiFlat => 'دون تغيير';

  @override
  String get uiHotelOccBooked => 'محجوز';

  @override
  String get uiHotelOccHeld => 'محجوز مؤقتًا';

  @override
  String get uiHotelOccBlocked => 'مغلق';

  @override
  String get uiHotelOccOpen => 'متاح';

  @override
  String uiHotelOccOf(String booked, String total) {
    return '$booked من $total ليلة قاعة محجوزة';
  }

  @override
  String uiHotelOccNights(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ليلة قاعة',
      many: 'ليلة قاعة',
      few: 'ليالي قاعات',
      two: 'ليلتا قاعة',
      one: 'ليلة قاعة',
      zero: 'ليلة قاعة',
    );
    return '$_temp0';
  }

  @override
  String get uiHotelVactRequests => 'الطلبات الواردة';

  @override
  String get uiHotelVactAwaiting => 'بانتظار تأكيد العميل';

  @override
  String get uiHotelVactRedeemed => 'كوبونات تم استخدامها';

  @override
  String get uiHotelVactChart => 'الكوبونات المشتراة يوميًا';

  @override
  String get uiHotelVactDaily => 'المشتراة يوميًا';

  @override
  String get uiHotelCalFree => 'متاح';

  @override
  String get uiHotelCalRequest => 'طلب';

  @override
  String get uiHotelCalRequestLegend => 'طلب بانتظار الرد';

  @override
  String get uiHotelCalSep => '، ';

  @override
  String uiHotelCalHoldUntil(String time) {
    return 'محجوز حتى $time';
  }

  @override
  String get uiHotelCalOpen => 'متاح';

  @override
  String get uiHotelCalBlock => 'إغلاق';

  @override
  String get uiHotelCalBlockDate => 'إغلاق هذا التاريخ';

  @override
  String uiHotelCalBy(String name) {
    return 'بواسطة $name';
  }

  @override
  String uiHotelCalAgenda(String date) {
    return 'مواعيد $date';
  }

  @override
  String uiHotelCalRequests(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ طلب بانتظار الرد لهذا التاريخ',
      many: '⁦$countString⁩ طلبًا بانتظار الرد لهذا التاريخ',
      few: '⁦$countString⁩ طلبات بانتظار الرد لهذا التاريخ',
      two: 'طلبان بانتظار الرد لهذا التاريخ',
      one: 'طلب واحد بانتظار الرد لهذا التاريخ',
      zero: 'لا طلبات بانتظار الرد لهذا التاريخ',
    );
    return '$_temp0';
  }

  @override
  String get uiHotelCalReasonOfflineBooking => 'حجز خارج غزل';

  @override
  String get uiHotelCalReasonMaintenance => 'صيانة';

  @override
  String get uiHotelCalReasonPrivateEvent => 'مناسبة خاصة';

  @override
  String get uiHotelCalReasonOther => 'أخرى';

  @override
  String get uiHotelCalSetup => 'التجهيز';

  @override
  String get uiHotelCalTeardown => 'الفك والتنظيف';

  @override
  String get uiHotelCalOpenDay => 'متاح: لا حجز ولا تثبيت في هذا التاريخ';

  @override
  String get uiHotelCalDragHint => 'اضغطوا مطوّلًا على تاريخ ثم اسحبوا عبر التواريخ. أو انقروا على تاريخ البداية ثم تاريخ النهاية.';

  @override
  String get uiHotelCalSheetTitle => 'إغلاق التواريخ';

  @override
  String get uiHotelCalSheetShortcuts => 'اختصارات';

  @override
  String get uiHotelCalSheetReason => 'السبب';

  @override
  String get uiHotelCalSheetHalls => 'القاعات';

  @override
  String get uiHotelCalSheetOpen => 'فتح';

  @override
  String get uiHotelCalSheetOffer => 'عرض';

  @override
  String get uiHotelCalSheetNone => 'اختاروا التواريخ';

  @override
  String get uiHotelCalSheetGrid => 'اختيار التواريخ المراد إغلاقها';

  @override
  String get uiHotelCalSheetNote => 'تختفي من نتائج العملاء فور الإغلاق.';

  @override
  String uiHotelCalSheetDates(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
  String get uiHotelActionsReschedule => 'اقتراح موعد آخر';

  @override
  String get uiHotelActionsRescheduleWhy => 'اقتراح حتى ثلاثة مواعيد بسعر الكوبون نفسه. أمام العميل 48 ساعة للرد.';

  @override
  String get uiHotelActionsRevoke => 'سحب الموافقة';

  @override
  String get uiHotelActionsRevokeWhy => 'يُخلى التاريخ ويعود الكوبون إلى العميل.';

  @override
  String get uiHotelActionsCancel => 'إلغاء الحجز';

  @override
  String get uiHotelActionsCancelWhy => 'يعود الكوبون إلى العميل. ويُسجَّل الإلغاء في سجلكم.';

  @override
  String get uiHotelStatusRef => 'رقم الحجز';

  @override
  String get uiHotelStatusVoucher => 'الكوبون';

  @override
  String get uiHotelStatusClientPays => 'يدفع العميل لكم مباشرة';

  @override
  String get uiHotelStatusStandard => 'السعر العادي';

  @override
  String get uiHotelStatusDirect => 'تتم التسوية بينكم وبين العميل خارج التطبيق.';

  @override
  String uiHotelStatusAwaiting(String when, String left) {
    return 'بانتظار تأكيد العميل حتى $when · $left';
  }

  @override
  String get uiHotelStatusRedeem => 'استخدام الكوبون';

  @override
  String uiHotelStatusRedeemed(String when, String name) {
    return 'تم الاستخدام $when بواسطة $name';
  }

  @override
  String uiHotelStatusRedeemedNoName(String when) {
    return 'تم الاستخدام $when';
  }

  @override
  String get uiHotelGuestBookingFor => 'الحجز باسم';

  @override
  String get uiHotelGuestContact => 'التواصل';

  @override
  String get uiHotelGuestPhone => 'الهاتف';

  @override
  String get uiHotelGuestNotShared => 'لم يُشارَك بعد. راسلوا عبر المحادثة.';

  @override
  String get uiHotelGuestVerified => 'رقم موثّق';

  @override
  String get uiHotelGuestFirst => 'أول حجز';

  @override
  String get uiHotelGuestCall => 'اتصال';

  @override
  String get uiHotelGuestChat => 'محادثة';

  @override
  String get uiHotelGuestVoucher => 'الكوبون';

  @override
  String get uiHotelGuestCallWhy => 'لم يشارك العميل رقمه';

  @override
  String get uiHotelGuestBride => 'العروس';

  @override
  String get uiHotelGuestGroom => 'العريس';

  @override
  String get uiHotelGuestFamily => 'أحد أفراد العائلة';

  @override
  String get uiHotelGuestPlanner => 'منسّق أعراس';

  @override
  String get uiHotelValidityEventDates => 'تواريخ المناسبة';

  @override
  String get uiHotelValidityHelper => 'يسري سعر الكوبون الأقل على المناسبات في هذه التواريخ.';

  @override
  String get uiHotelValidityWindow => 'مدة هذا السعر';

  @override
  String uiHotelValidityHours(String n) {
    return '$n ساعة';
  }

  @override
  String uiHotelValidityEnds(String time) {
    return 'ينتهي $time';
  }

  @override
  String get uiHotelValidityScheduled => 'مجدول';

  @override
  String get uiHotelValidityActive => 'نشط';

  @override
  String get uiHotelValidityEnded => 'منتهٍ';

  @override
  String uiHotelValidityStarts(String time) {
    return 'يبدأ $time';
  }

  @override
  String get uiHotelWindowLabel => 'كما يراه العملاء';

  @override
  String get uiHotelWindowSaving => 'التوفير مقارنة بالسعر العادي';

  @override
  String uiHotelPackageGuests(String from, String to) {
    return 'من $from إلى $to ضيف';
  }

  @override
  String get uiHotelPackagePrice => 'السعر العادي للضيف';

  @override
  String get uiHotelPackagePriceFlat => 'السعر العادي';

  @override
  String get uiHotelPackageVoucherPrice => 'سعر الكوبون للضيف';

  @override
  String get uiHotelPackageVoucherPriceFlat => 'سعر الكوبون';

  @override
  String get uiHotelPackagePriceHelper => 'بالدينار الكويتي حتى ثلاث خانات عشرية. ما يدفعه العميل لكم دون كوبون.';

  @override
  String get uiHotelPackageVoucherHelper => 'أقل من السعر العادي. ما يدفعه العميل لكم بكوبون غزل.';

  @override
  String get uiHotelPackagePriceError => 'أدخلوا مبلغًا مثل 52 أو 52.500.';

  @override
  String get uiHotelPackageVoucherError => 'يجب أن يكون سعر الكوبون أقل من السعر العادي.';

  @override
  String uiHotelPackageVoucherSmall(String amount) {
    return 'يوفّر العميل $amount وهو لا يزيد على ثمن الكوبون، لذلك لا يُعرض الكوبون.';
  }

  @override
  String uiHotelPackageSaving(String amount, String unit) {
    return 'يوفّر العميل $amount$unit بالكوبون';
  }

  @override
  String uiHotelPackageStructure(String structure) {
    return 'التسعير: $structure';
  }

  @override
  String get uiHotelPackagePerPerson => 'للضيف';

  @override
  String get uiHotelPackagePackage => 'باقة';

  @override
  String get uiHotelPackageMin => 'الحد الأدنى للضيوف';

  @override
  String get uiHotelPackageMax => 'الحد الأقصى للضيوف';

  @override
  String uiHotelPackageRule(String step) {
    return 'يتغير بمقدار $step';
  }

  @override
  String get uiHotelPackageInclusions => 'ما تشمله الباقة';

  @override
  String uiHotelPackageRemove(String name) {
    return 'إزالة $name';
  }

  @override
  String get uiHotelPackageAdd => 'إضافة';

  @override
  String uiHotelPackageActiveOf(String name) {
    return 'الباقة $name مفعّلة';
  }

  @override
  String get uiHotelPackageDashboard => 'تُعدَّل أسعار المواسم والعطل والتواريخ الخاصة من لوحة التحكم.';

  @override
  String uiHotelPackageEdit(String name) {
    return 'تعديل $name';
  }

  @override
  String get uiHotelPackageKd => 'د.ك';

  @override
  String get uiHotelPhotosCover => 'الغلاف';

  @override
  String get uiHotelPhotosAdd => 'إضافة صور';

  @override
  String get uiHotelPhotosReview => 'قيد المراجعة';

  @override
  String get uiHotelPhotosRejected => 'مرفوضة';

  @override
  String uiHotelPhotosEarlier(String n) {
    return 'نقل الصورة $n للأمام';
  }

  @override
  String uiHotelPhotosLater(String n) {
    return 'نقل الصورة $n للخلف';
  }

  @override
  String get uiHotelPhotosDrag => 'اسحبوا لإعادة الترتيب';

  @override
  String uiHotelPhotosOpen(String n, String zone) {
    return 'الصورة $n: $zone';
  }

  @override
  String get uiHotelPhotosHall => 'القاعة';

  @override
  String get uiHotelPhotosStageKosha => 'المنصة والكوشة';

  @override
  String get uiHotelPhotosBridalSuite => 'جناح العروس';

  @override
  String get uiHotelPhotosBuffet => 'البوفيه';

  @override
  String get uiHotelPhotosOutdoors => 'الخارج';

  @override
  String get uiHotelPhotosEntranceValet => 'المدخل والفاليه';

  @override
  String get uiHotelPhotosLayout => 'التصاميم';

  @override
  String get uiHotelHoursClosed => 'مغلق';

  @override
  String uiHotelHoursOpen(String day) {
    return 'مفتوح يوم $day';
  }

  @override
  String get uiHotelHoursFrom => 'يفتح';

  @override
  String get uiHotelHoursTo => 'يغلق';

  @override
  String get uiHotelHoursNextDay => 'اليوم التالي';

  @override
  String get uiHotelHoursCopy => 'نسخ إلى كل الأيام';

  @override
  String get uiHotelHoursInvalid => 'وقت الإغلاق يسبق وقت الفتح.';

  @override
  String uiHotelHoursPick(String what, String time) {
    return '$what الساعة $time';
  }

  @override
  String get uiHotelReviewAnonymous => 'مجهول الهوية';

  @override
  String get uiHotelReviewVerified => 'حجز موثّق';

  @override
  String get uiHotelReviewNeeds => 'بانتظار الرد';

  @override
  String get uiHotelReviewReported => 'تم الإبلاغ · قيد مراجعة غزل';

  @override
  String uiHotelReviewEvent(String month) {
    return 'مناسبة في $month';
  }

  @override
  String get uiHotelReviewReply => 'الرد';

  @override
  String get uiHotelReviewReport => 'إبلاغ';

  @override
  String get uiHotelReviewDraft => 'مسودتكم';

  @override
  String uiHotelReviewYours(String name) {
    return 'رد من $name';
  }

  @override
  String get uiHotelReviewOnce => 'الرد علني ويُرسل مرة واحدة.';

  @override
  String get uiHotelStaffYou => 'أنتم';

  @override
  String get uiHotelStaffActive => 'نشط';

  @override
  String uiHotelStaffLastSeen(String time) {
    return 'آخر ظهور $time';
  }

  @override
  String get uiHotelStaffPending => 'الدعوة قيد الانتظار';

  @override
  String uiHotelStaffExpires(String date) {
    return 'تنتهي $date';
  }

  @override
  String get uiHotelStaffDeactivated => 'معطّل';

  @override
  String get uiHotelStaffAllowed => 'مسموح';

  @override
  String get uiHotelStaffNotAllowed => 'ليس لهذا الدور';

  @override
  String uiHotelStaffOpen(String name) {
    return 'صلاحيات $name';
  }

  @override
  String get uiHotelStaffAccept => 'قبول الطلبات والاعتذار واقتراح موعد آخر';

  @override
  String get uiHotelStaffBlock => 'إغلاق التواريخ وفتحها';

  @override
  String get uiHotelStaffCancel => 'تغيير موعد حجز مؤكد أو إلغاؤه';

  @override
  String get uiHotelStaffCash => 'تسجيل مبلغ نقدي مستلم';

  @override
  String get uiHotelStaffRevenue => 'الاطلاع على الإيرادات والدفعات';

  @override
  String get uiHotelStaffOffers => 'إنشاء العروض وإنهاؤها';

  @override
  String get uiHotelStaffManage => 'الموظفون وبيانات الحساب البنكي';

  @override
  String get uiHotelStaffSwitchable => 'يمكن للمالك إيقافه';

  @override
  String get uiHotelPhotosMakeCover => 'جعلها الغلاف';

  @override
  String get uiHotelPhotosDelete => 'حذف';

  @override
  String get uiHotelPhotosOpenAction => 'فتح';

  @override
  String get uiHotelPhotosDeleted => 'تم حذف الصورة';

  @override
  String get uiInputsOtpGroup => 'رمز التحقق';

  @override
  String uiInputsOtpCell(String n, String total) {
    return 'الخانة $n من $total';
  }

  @override
  String get uiInputsPhoneCountry => 'رمز الدولة';

  @override
  String get uiInputsPhoneNumber => 'رقم الجوال';

  @override
  String get uiInputsStepperIncrease => 'زيادة';

  @override
  String get uiInputsStepperDecrease => 'إنقاص';

  @override
  String get uiInputsRangeMinimum => 'الحد الأدنى';

  @override
  String get uiInputsRangeMaximum => 'الحد الأقصى';

  @override
  String get uiInputsSelectChoose => 'اختيار';

  @override
  String uiInputsSelectCount(String n) {
    return 'تم اختيار $n';
  }

  @override
  String get uiInputsSelectNoResults => 'لا توجد نتائج';

  @override
  String get uiInputsCalendarStartDate => 'تاريخ البداية';

  @override
  String get uiInputsCalendarEndDate => 'تاريخ النهاية';

  @override
  String get uiInputsCalendarHint => 'استخدم مفاتيح الأسهم للتنقل بين الأيام.';

  @override
  String uiInputsCalendarPriceBasis(String currency, String unit) {
    return '$currency · $unit';
  }

  @override
  String uiInputsDateFieldRange(String from, String to) {
    return 'من $from إلى $to';
  }

  @override
  String get uiInputsDateFieldChooseDate => 'اختيار التاريخ';

  @override
  String get uiInputsDateFieldChooseDates => 'اختيار التواريخ';

  @override
  String get uiInputsSlotSession => 'الفترة';

  @override
  String get uiKitErrorValidationFailed => 'بعض البيانات تحتاج إلى مراجعة. يُرجى التحقق من الحقول المحددة.';

  @override
  String get uiKitErrorAuthRequired => 'يُرجى تسجيل الدخول للمتابعة.';

  @override
  String get uiKitErrorTokenExpired => 'انتهت الجلسة. يُرجى تسجيل الدخول مرة أخرى.';

  @override
  String get uiKitErrorSessionRevoked => 'تم تسجيل خروجكم من هذا الجهاز. يُرجى تسجيل الدخول مرة أخرى.';

  @override
  String get uiKitErrorPhoneVerificationRequired => 'يُرجى توثيق رقم الجوال أولاً ثم المحاولة مرة أخرى.';

  @override
  String get uiKitErrorForbidden => 'دوركم لا يتيح هذا الإجراء. يُرجى مراجعة المدير.';

  @override
  String get uiKitErrorStepUpRequired => 'أكدوا برمز جديد أو بكلمة المرور للمتابعة.';

  @override
  String get uiKitErrorNotFound => 'لم يعد هذا متاحاً.';

  @override
  String get uiKitErrorVenueContextRequired => 'اختاروا القاعة أو حساب الخدمة الذي تعملون عليه.';

  @override
  String get uiKitErrorOtpInvalid => 'الرمز غير صحيح. يُرجى التحقق منه والمحاولة مرة أخرى.';

  @override
  String get uiKitErrorOtpExpired => 'انتهت صلاحية الرمز. اطلبوا رمزاً جديداً.';

  @override
  String get uiKitErrorOtpLocked => 'تكررت المحاولات الخاطئة. يُرجى المحاولة لاحقاً.';

  @override
  String get uiKitErrorCredentialsInvalid => 'البيانات لا تطابق أي حساب. يُرجى التحقق منها والمحاولة مرة أخرى.';

  @override
  String get uiKitErrorRateLimited => 'محاولات كثيرة. يُرجى الانتظار قليلاً ثم المحاولة مرة أخرى.';

  @override
  String get uiKitErrorIdempotencyInProgress => 'هذا الطلب قيد المعالجة. يُرجى الانتظار لحظة.';

  @override
  String get uiKitErrorPreconditionFailed => 'تم تغيير هذا من مكان آخر. أعيدوا التحميل وحاولوا مرة أخرى.';

  @override
  String get uiKitErrorBookingStateConflict => 'تم تحديث هذا الطلب في هذه الأثناء. أعيدوا التحميل لمعرفة حالته.';

  @override
  String get uiKitErrorSlotUnavailable => 'هذا التاريخ لم يعد متاحاً. يُرجى تحديد تاريخ آخر.';

  @override
  String get uiKitErrorOpenRequestLimit => 'وصلتم إلى الحد الأقصى للطلبات المفتوحة. انتظروا رداً أو اسحبوا أحد الطلبات.';

  @override
  String get uiKitErrorQuoteExpired => 'انتهت صلاحية هذا العرض. يُرجى مراجعته مرة أخرى.';

  @override
  String get uiKitErrorQuoteChanged => 'تغيّر السعر منذ عرضه. يُرجى مراجعة العرض الجديد.';

  @override
  String get uiKitErrorLeadTimeTooShort => 'هذا التاريخ قريب جداً. يُرجى تحديد تاريخ لاحق.';

  @override
  String get uiKitErrorGuestsOutOfRange => 'عدد الضيوف خارج النطاق الذي يتيحه هذا الخيار.';

  @override
  String get uiKitErrorAudienceNotAllowed => 'هذه القاعة لا تتيح هذا الخيار لفئتكم.';

  @override
  String get uiKitErrorChannelNotBookable => 'تستقبل هذه الجهة الطلبات عبر قناتها الرسمية فقط.';

  @override
  String get uiKitErrorVoucherNotOffered => 'الكوبون لا يخفض السعر لهذا الخيار.';

  @override
  String get uiKitErrorVoucherNotUsable => 'لا يمكن استخدام هذا الكوبون. قد يكون منتهياً أو ملغى أو مرتبطاً بطلب.';

  @override
  String get uiKitErrorVoucherTargetMismatch => 'هذا الكوبون مرتبط بقاعة أو خدمة أخرى.';

  @override
  String get uiKitErrorVoucherCheckoutExpired => 'انتهت مهلة الدفع ولم يُخصم أي مبلغ. ابدؤوا من جديد.';

  @override
  String get uiKitErrorVoucherUnknown => 'لا يوجد كوبون بهذا الرمز. يُرجى التحقق منه والمحاولة مرة أخرى.';

  @override
  String get uiKitErrorVoucherOtherPartner => 'هذا الكوبون يخص قاعة أو خدمة أخرى.';

  @override
  String get uiKitErrorVoucherNotConfirmed => 'لم يؤكد العميل هذا الطلب بعد.';

  @override
  String get uiKitErrorVoucherAlreadyUsed => 'تم استخدام هذا الكوبون من قبل.';

  @override
  String get uiKitErrorCreditNotEligible => 'لا يمكن النظر في هذا الكوبون لإصدار كوبون رصيد.';

  @override
  String get uiKitErrorRefundRequestExists => 'يوجد طلب لهذا الكوبون لدى الدعم بالفعل.';

  @override
  String get uiKitErrorConfirmWindowEnded => 'انتهت مهلة التأكيد.';

  @override
  String get uiKitErrorUndoWindowEnded => 'انتهت مهلة التراجع.';

  @override
  String get uiKitErrorPaymentGatewayError => 'خدمة الدفع غير متاحة. لم يُخصم أي مبلغ. يُرجى المحاولة بعد قليل.';

  @override
  String get uiKitErrorPlanRatesNotAnnounced => 'سيتم الإعلان عن أسعار الباقات قريباً.';

  @override
  String get uiKitErrorListingNotEditable => 'لا يمكن تعديل هذا الإعلان في حالته الحالية.';

  @override
  String get uiKitErrorListingStateConflict => 'هذا الإعلان ليس في حالة تتيح هذا الإجراء.';

  @override
  String get uiKitErrorMediaTooLarge => 'حجم الملف كبير جداً. يُرجى استخدام ملف أصغر.';

  @override
  String get uiKitErrorMediaTypeUnsupported => 'نوع الملف غير مقبول.';

  @override
  String get uiKitErrorReviewAlreadyReplied => 'لهذا التقييم رد بالفعل.';

  @override
  String get uiKitErrorReviewNotAllowed => 'يمكن كتابة التقييم بعد اكتمال المناسبة، ومرة واحدة فقط.';

  @override
  String get uiKitErrorVisitSlotTaken => 'هذا الموعد لم يعد متاحاً. يُرجى تحديد موعد آخر.';

  @override
  String get uiKitErrorVisitNotAllowed => 'هذه الجهة لا تستقبل الزيارات عبر التطبيق.';

  @override
  String get uiKitErrorVisitStateConflict => 'تم تحديث هذه الزيارة في هذه الأثناء. أعيدوا التحميل لمعرفة حالتها.';

  @override
  String get uiKitErrorStaffLastAdmin => 'لا يمكن إزالة آخر مسؤول أو تغيير دوره.';

  @override
  String get uiKitErrorInvitationExpired => 'انتهت صلاحية هذه الدعوة أو تم استخدامها. اطلبوا دعوة جديدة.';

  @override
  String get uiKitErrorEmailAlreadyInvited => 'هذا البريد لديه دعوة قيد الانتظار بالفعل.';

  @override
  String get uiKitErrorAccountDeletionBlocked => 'لا يمكن حذف الحساب بوجود طلب مؤكد قادم.';

  @override
  String get uiKitErrorAppUpdateRequired => 'يُرجى تحديث التطبيق للمتابعة.';

  @override
  String get uiKitErrorOffline => 'لا يوجد اتصال. يُرجى التأكد من الاتصال بالإنترنت والمحاولة مرة أخرى.';

  @override
  String get uiKitErrorTimeout => 'استغرق الأمر وقتاً طويلاً. يُرجى المحاولة مرة أخرى.';

  @override
  String get uiKitDemoTitle => 'أدوات العرض';

  @override
  String get uiKitDemoHotspot => 'أدوات العرض';

  @override
  String get uiKitDemoModeTitle => 'الخادم';

  @override
  String get uiKitDemoModeInProcess => 'نموذج محاكاة داخل التطبيق';

  @override
  String uiKitDemoModeRemote(String url) {
    return 'واجهة خارجية على $url';
  }

  @override
  String get uiKitDemoStoryTitle => 'القصة';

  @override
  String get uiKitDemoReset => 'إعادة ضبط القصة';

  @override
  String get uiKitDemoResetDone => 'عادت القصة إلى البداية.';

  @override
  String get uiKitDemoPersonaTitle => 'من يستخدم التطبيق';

  @override
  String get uiKitDemoPersonaGuest => 'زائر';

  @override
  String get uiKitDemoPersonaNewClient => 'عميلة جديدة';

  @override
  String get uiKitDemoPersonaReem => 'ريم';

  @override
  String get uiKitDemoPersonaHotelManager => 'مدير الفندق';

  @override
  String get uiKitDemoPersonaHotelAdmin => 'مسؤول الفندق';

  @override
  String get uiKitDemoPersonaProvider => 'مزوّد خدمة';

  @override
  String get uiKitDemoScenarioTitle => 'الطلبات القادمة';

  @override
  String get uiKitDemoScenarioNone => 'عادي';

  @override
  String get uiKitDemoScenarioSlow => 'بطيء';

  @override
  String get uiKitDemoScenarioError => 'خطأ';

  @override
  String get uiKitDemoScenarioOffline => 'دون اتصال';

  @override
  String get uiKitDemoScenarioEmpty => 'فارغ';

  @override
  String get uiKitDemoScenarioExpired => 'انتهاء الجلسة';

  @override
  String get uiKitDemoClockTitle => 'الساعة';

  @override
  String uiKitDemoClockNow(String time) {
    return 'وقت القصة: $time';
  }

  @override
  String get uiKitDemoAdvanceHour => 'تقديم ساعة';

  @override
  String get uiKitDemoAdvanceDay => 'تقديم يوم';

  @override
  String get uiKitDemoJumpTitle => 'الانتقال إلى مرحلة من القصة';

  @override
  String get uiKitDemoPointPending => 'بانتظار الرد';

  @override
  String get uiKitDemoPointApproved => 'تمت الموافقة';

  @override
  String get uiKitDemoPointConfirmed => 'مؤكد';

  @override
  String get uiKitDemoPointRedeemed => 'تم الاستخدام';

  @override
  String get uiKitDemoPointCompleted => 'مكتمل';

  @override
  String get uiKitDemoPointDeclined => 'لم يُقبل';

  @override
  String get uiKitDemoPointExpired => 'انتهت المهلة';

  @override
  String get uiKitDemoPointLapsed => 'سقط الكوبون';

  @override
  String get uiKitDemoPointCancelled => 'ملغي';

  @override
  String get uiKitDemoPointCounterOffer => 'عرض بديل';

  @override
  String get uiKitDemoLanguageTitle => 'اللغة والأرقام';

  @override
  String get uiKitDemoDigitsEastern => 'الأرقام العربية الشرقية';

  @override
  String get uiKitDemoDigitsWestern => 'الأرقام الغربية';

  @override
  String get uiProviderAdPlanExemptBody => 'بلا رسوم للفنادق الكبيرة';

  @override
  String uiProviderAdPlanPerPeriod(String period) {
    return 'لكل $period';
  }

  @override
  String get uiProviderAdPlanWeek => 'أسبوع';

  @override
  String get uiProviderAdPlanMonth => 'شهر';

  @override
  String get uiProviderAdPlanYear => 'سنة';

  @override
  String get uiProviderAdPlanStarts => 'تبدأ من يوم الموافقة';

  @override
  String uiProviderAdPlanChoose(String name) {
    return 'اختيار الباقة $name';
  }

  @override
  String get uiProviderMajorHotelExemptFee => 'معفى من الرسوم';

  @override
  String get uiProviderMajorHotelExplain => 'لا تُحتسب على الفنادق الكبيرة رسوم إدراج أو إعلان. وتخضع كل قوائمها للمراجعة قبل النشر.';

  @override
  String uiProviderListingEndsOn(String date) {
    return 'تنتهي $date';
  }

  @override
  String get uiProviderListingStartsAfter => 'تبدأ عند الموافقة';

  @override
  String get uiProviderListingNoPlan => 'لم تُختر باقة بعد';

  @override
  String get uiProviderListingReview => 'لدى فريق المراجعة';

  @override
  String get uiProviderListingRejectContentNotCompliant => 'المحتوى لا يتوافق مع إرشادات النشر';

  @override
  String get uiProviderListingRejectWrongCategory => 'الفئة غير مناسبة';

  @override
  String get uiProviderListingRejectMissingDetails => 'بعض البيانات ناقصة';

  @override
  String get uiProviderListingRejectUnclearPricing => 'الأسعار غير واضحة';

  @override
  String get uiProviderListingRejectOther => 'راجعوا ملاحظة المراجع';

  @override
  String get uiProviderTimelineLabel => 'سجل المراجعة';

  @override
  String get uiProviderTimelineDraft => 'تم حفظ المسودة';

  @override
  String get uiProviderTimelinePaymentPending => 'بانتظار الدفع';

  @override
  String get uiProviderTimelinePendingReview => 'أُرسلت للمراجعة';

  @override
  String get uiProviderTimelineApproved => 'تمت الموافقة';

  @override
  String get uiProviderTimelineRejected => 'لم تتم الموافقة';

  @override
  String get uiProviderTimelineActive => 'نُشرت على غزل';

  @override
  String get uiProviderTimelineExpired => 'انتهت مدة الباقة';

  @override
  String get uiProviderTimelinePaused => 'تم الإيقاف المؤقت';

  @override
  String get uiProviderTimelineYou => 'أنتم';

  @override
  String get uiProviderTimelineSystem => 'غزل';

  @override
  String get uiProviderTimelineModerator => 'فريق مراجعة غزل';

  @override
  String uiProviderTimelineModeratorBy(String name) {
    return 'فريق مراجعة غزل · $name';
  }

  @override
  String get uiProviderTimelineNextReview => 'مراجعة يدوية من فريق غزل';

  @override
  String get uiProviderTimelineNextReviewNote => 'تُراجع كل قائمة من حيث المحتوى والفئة قبل النشر. الدفع وحده لا يؤدي إلى النشر.';

  @override
  String get uiProviderTimelineNextLive => 'النشر';

  @override
  String get uiProviderTimelineNextLiveNote => 'تبدأ مدة الباقة من يوم النشر.';

  @override
  String uiProviderTimelineKeptUntil(String date) {
    return 'تبقى باقتكم محفوظة حتى $date لإعادة الإرسال.';
  }

  @override
  String get uiProviderTimelineReasonContentNotCompliant => 'المحتوى لا يتوافق مع إرشادات النشر';

  @override
  String get uiProviderTimelineReasonWrongCategory => 'الفئة غير مناسبة';

  @override
  String get uiProviderTimelineReasonMissingDetails => 'بعض البيانات ناقصة';

  @override
  String get uiProviderTimelineReasonUnclearPricing => 'الأسعار غير واضحة';

  @override
  String get uiProviderTimelineReasonOther => 'راجعوا الملاحظة';

  @override
  String get uiSharedGuests => 'الضيوف';

  @override
  String get uiSharedFrom => 'من';

  @override
  String get uiSharedPerNight => 'لليلة';

  @override
  String get uiSharedRentalFee => 'رسوم الإيجار';

  @override
  String get uiSharedVoucher => 'كوبون';

  @override
  String get uiSharedLessThanMinute => 'أقل من دقيقة متبقية';

  @override
  String uiSharedSpokenDays(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString يوم',
      many: '$countString يومًا',
      few: '$countString أيام',
      two: 'يومان',
      one: 'يوم',
      zero: '$countString يوم',
    );
    return '$_temp0';
  }

  @override
  String uiSharedSpokenHours(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString ساعة',
      many: '$countString ساعة',
      few: '$countString ساعات',
      two: 'ساعتان',
      one: 'ساعة',
      zero: '$countString ساعة',
    );
    return '$_temp0';
  }

  @override
  String uiSharedSpokenMinutes(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString دقيقة',
      many: '$countString دقيقة',
      few: '$countString دقائق',
      two: 'دقيقتان',
      one: 'دقيقة',
      zero: '$countString دقيقة',
    );
    return '$_temp0';
  }

  @override
  String uiSharedSpokenJoin(String first, String second) {
    return '$first و$second';
  }

  @override
  String get stubNotBuilt => 'لم تُبنَ بعد';

  @override
  String get uiVisitsStripLabel => 'أعضاء المحادثة';

  @override
  String get uiVisitsStripOpen => 'عرض أعضاء المحادثة';

  @override
  String uiVisitsCardWith(String name) {
    return 'مع $name';
  }

  @override
  String get uiVisitsCardChat => 'فتح المحادثة الجماعية';

  @override
  String get uiVisitsCardReadOnly => 'المحادثة للقراءة فقط';

  @override
  String get uiVoucherCardCode => 'الرمز';

  @override
  String uiVoucherCardQrLabel(String code) {
    return 'رمز QR للكوبون $code';
  }

  @override
  String get uiVoucherCardCopy => 'نسخ';

  @override
  String get uiVoucherCardFull => 'ملء الشاشة';

  @override
  String get uiVoucherCardDate => 'تاريخ المناسبة';

  @override
  String get uiVoucherCardPackage => 'الباقة';

  @override
  String get uiVoucherCardValidUntil => 'صالح حتى';

  @override
  String get uiVoucherCardUsedOn => 'استُخدم في';

  @override
  String get uiVoucherPriceNetTitle => 'التوفير';

  @override
  String uiVoucherPriceNet(String amount, String fee) {
    return 'توفّرون $amount بعد كوبون بقيمة $fee.';
  }

  @override
  String get uiVoucherPricePackage => 'سعر الباقة';

  @override
  String get uiVoucherSummaryHead => 'كوبونكم';

  @override
  String get uiVoucherSummaryBoundTo => 'خاص بـ';

  @override
  String get uiVoucherSummaryDate => 'تاريخ الحفل';

  @override
  String get uiVoucherSummaryPackage => 'الباقة';

  @override
  String get uiVoucherSummaryGuests => 'عدد الضيوف';

  @override
  String get uiVoucherSummarySave => 'توفّرون';

  @override
  String get uiVoucherSummaryPayToday => 'تدفعون لغزل اليوم';

  @override
  String get uiVoucherSummaryPayOnce => 'ثمن الكوبون، مرة واحدة';

  @override
  String uiVoucherSummaryDirectly(String amount, String venue) {
    return 'والباقي، $amount، تدفعونه إلى $venue مباشرة بعد التأكيد. غزل ليست طرفًا في هذه الدفعة.';
  }

  @override
  String get uiVoucherSummaryRuleBound => 'الكوبون خاص بهذا المكان وهذا العرض.';

  @override
  String uiVoucherSummaryRuleReuse(String days) {
    return 'إذا اعتذر المكان، يمكنكم استخدامه هنا من جديد خلال $days.';
  }

  @override
  String get uiVoucherSummaryRuleCredit => 'إذا اعتذر المكان أو لم يرد، اطلبوا كوبون رصيد من الدعم.';

  @override
  String get uiVoucherConfirmEyebrow => 'أكدوا حجزكم';

  @override
  String uiVoucherConfirmBy(String when) {
    return 'التأكيد حتى $when';
  }

  @override
  String get uiVoucherConfirmHeld => 'التاريخ محجوز لكم حتى ذلك الوقت. لا مبلغ إضافي لغزل.';

  @override
  String get uiVoucherConfirmLapsedTitle => 'انتهت مهلة التأكيد';

  @override
  String get uiVoucherConfirmLapsedBody => 'تم إخلاء التاريخ، ولم يعد الكوبون صالحًا.';

  @override
  String get uiVoucherConfirmDoneTitle => 'تم تأكيد الحجز';

  @override
  String uiVoucherConfirmDoneAt(String when) {
    return 'تم التأكيد في $when';
  }

  @override
  String get uiVoucherConfirmThread => 'المدة المنقضية من مهلة التأكيد';
}
