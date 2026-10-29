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
  String get hotelAccessLanguageSwitch => 'تبديل اللغة';

  @override
  String get hotelAccessPasswordShow => 'إظهار كلمة المرور';

  @override
  String get hotelAccessPasswordHide => 'إخفاء كلمة المرور';

  @override
  String get hotelAccessPhotoAlt => 'قاعة مقبّبة مشرقة بنوافذ سقفية وأقواس وطاولات مأدبة طويلة بمفارش بيضاء وكراسٍ ذهبية على أرضية باركيه';

  @override
  String get hotelAccessSupportTitle => 'دعم غزل';

  @override
  String get hotelAccessSupportAction => 'مراسلة الدعم';

  @override
  String get hotelAccessSupportShort => 'الدعم';

  @override
  String get hotelAccessAdminTitle => 'مسؤول الحساب';

  @override
  String get hotelAccessAdminAction => 'مراسلة المسؤول';

  @override
  String get hotelAccessSigninTitle => 'تسجيل الدخول';

  @override
  String get hotelAccessSigninEmailLabel => 'البريد الإلكتروني';

  @override
  String get hotelAccessSigninPasswordLabel => 'كلمة المرور';

  @override
  String get hotelAccessSigninForgot => 'نسيتم؟';

  @override
  String get hotelAccessSigninForgotLabel => 'نسيتم كلمة المرور';

  @override
  String get hotelAccessSigninInvite => 'دعوة';

  @override
  String get hotelAccessSigninApplyLine => 'مزوّد خدمة أو قاعة خاصة جديدة؟';

  @override
  String get hotelAccessSigninApply => 'قدّم طلب انضمام';

  @override
  String get hotelAccessSigninSubmit => 'تسجيل الدخول';

  @override
  String get hotelAccessSigninInvalid => 'بيانات غير صحيحة';

  @override
  String get hotelAccessSigninInvalidTitle => 'لم يتم الدخول';

  @override
  String get hotelAccessSigninInvalidDetail => 'البريد الإلكتروني أو كلمة المرور غير صحيحة. لم يتم تسجيل الدخول.';

  @override
  String get hotelAccessSigninPaused => 'المحاولات متوقفة';

  @override
  String hotelAccessSigninPausedDetail(String time) {
    return 'تم إيقاف المحاولات مؤقتًا. يمكنكم المحاولة بعد $time بتوقيت الكويت.';
  }

  @override
  String hotelAccessSigninPausedUntil(String time) {
    return 'متوقف حتى $time';
  }

  @override
  String get hotelAccessInviteTitle => 'بدعوة فقط';

  @override
  String get hotelAccessInviteStepLink => 'رابط البريد';

  @override
  String get hotelAccessInviteStepCode => 'الرمز';

  @override
  String get hotelAccessInviteSteps => 'كيف تعمل الدعوة';

  @override
  String get hotelAccessInviteLink => 'فتح الرابط';

  @override
  String hotelAccessInviteFrom(String name) {
    return 'دعوة من $name';
  }

  @override
  String get hotelAccessVerifyTitle => 'إدخال الرمز';

  @override
  String get hotelAccessVerifyApplicationTitle => 'تأكيد البريد الإلكتروني';

  @override
  String get hotelAccessVerifyLabel => 'رمز التحقق';

  @override
  String get hotelAccessVerifyStepEmail => 'البريد';

  @override
  String hotelAccessVerifySentTo(String email) {
    return 'أُرسل الرمز بالبريد إلى $email';
  }

  @override
  String get hotelAccessVerifySubmit => 'تأكيد';

  @override
  String get hotelAccessVerifyWrong => 'رمز خاطئ';

  @override
  String hotelAccessVerifyAttemptsLeft(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
  String get hotelAccessVerifyExpired => 'انتهى الرمز';

  @override
  String get hotelAccessVerifyTooMany => 'محاولات كثيرة';

  @override
  String get hotelAccessVerifyResent => 'تم الإرسال';

  @override
  String hotelAccessVerifyTimer(String count) {
    return '$count ث';
  }

  @override
  String hotelAccessVerifyResendIn(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ ثانية',
      many: '⁦$countString⁩ ثانية',
      few: '⁦$countString⁩ ثوانٍ',
      two: 'ثانيتين',
      one: 'ثانية واحدة',
      zero: 'لحظة',
    );
    return 'إعادة إرسال الرمز بعد $_temp0';
  }

  @override
  String get hotelAccessVerifyResend => 'إعادة الإرسال';

  @override
  String get hotelAccessVerifyFailed => 'لم يصل الرمز';

  @override
  String get hotelAccessVerifyFailedDetail => 'تعذّر إرسال الرمز بالبريد. يمكنكم إعادة الإرسال أو التواصل مع الدعم.';

  @override
  String get hotelAccessVerifySuccessTitle => 'الجهاز موثوق';

  @override
  String get hotelAccessVerifyApplicationDone => 'تم تأكيد البريد';

  @override
  String hotelAccessVerifyTrustDays(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ يوم',
      many: '⁦$countString⁩ يومًا',
      few: '⁦$countString⁩ أيام',
      two: 'يومين',
      one: 'يوم واحد',
      zero: 'لحظة',
    );
    return 'موثوق لمدة $_temp0';
  }

  @override
  String hotelAccessVerifyTrustFact(String count) {
    return '$count يوم';
  }

  @override
  String get hotelAccessVerifySteps => 'خطوات التحقق';

  @override
  String hotelAccessVerifyStepCounter(num current, num total) {
    final intl.NumberFormat currentNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'الخطوة ⁦$currentString⁩ من ⁦$totalString⁩';
  }

  @override
  String get hotelAccessAuthTitle => 'رمز المصادقة';

  @override
  String get hotelAccessStepupTitle => 'تأكيد الهوية';

  @override
  String get hotelAccessStepupActionInvite => 'دعوة موظف';

  @override
  String get hotelAccessStepupActionRemove => 'إزالة موظف';

  @override
  String get hotelAccessStepupActionBilling => 'بيانات الفوترة';

  @override
  String get hotelAccessStepupDone => 'تم التأكيد';

  @override
  String get hotelAccessSetupTitle => 'كلمة المرور';

  @override
  String get hotelAccessSetupCardLabel => 'الدعوة';

  @override
  String get hotelAccessSetupInvitedEmail => 'البريد في الدعوة';

  @override
  String hotelAccessSetupValidUntil(String date) {
    return 'صالحة حتى $date';
  }

  @override
  String get hotelAccessSetupRoleInfo => 'صلاحيات هذا الدور';

  @override
  String get hotelAccessSetupPasswordLabel => 'كلمة المرور';

  @override
  String get hotelAccessSetupConfirmLabel => 'تأكيد';

  @override
  String get hotelAccessSetupMismatch => 'غير متطابقة';

  @override
  String hotelAccessSetupStrength(String level) {
    return 'قوة كلمة المرور: $level';
  }

  @override
  String get hotelAccessSetupStrengthWeak => 'ضعيفة';

  @override
  String get hotelAccessSetupStrengthFair => 'مقبولة';

  @override
  String get hotelAccessSetupStrengthStrong => 'قوية';

  @override
  String hotelAccessSetupRuleLength(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
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
  String get hotelAccessSetupRuleMix => 'حرف ورقم';

  @override
  String get hotelAccessSetupRuleMet => 'تم';

  @override
  String get hotelAccessSetupRuleOpen => 'لم يتحقق بعد';

  @override
  String get hotelAccessSetupError => 'لم يتم الحفظ';

  @override
  String get hotelAccessSetupErrorDetail => 'تعذّر حفظ كلمة المرور. لم يتم تغيير أي شيء. يمكنكم المحاولة مرة أخرى.';

  @override
  String get hotelAccessSetupSuccessTitle => 'تم الحفظ';

  @override
  String get hotelAccessSetupExpiredTitle => 'الدعوة منتهية';

  @override
  String get hotelAccessSetupExpiredDetail => 'تتوقف الدعوات عن العمل بعد أيام قليلة. يمكن لمسؤول الحساب أو دعم غزل إرسال دعوة جديدة.';

  @override
  String get hotelAccessSetupUsedTitle => 'الدعوة مستخدمة';

  @override
  String get hotelAccessSetupUsedDetail => 'كلمة المرور محفوظة بالفعل. يمكنكم الدخول بالبريد وكلمة المرور.';

  @override
  String get hotelAccessStatusUnderReviewTitle => 'قيد المراجعة';

  @override
  String get hotelAccessStatusUnderReviewBody => 'حسابكم قيد المراجعة. سنراسلكم بالبريد عند التفعيل.';

  @override
  String get hotelAccessStatusApplicationTitle => 'الطلب قيد المراجعة';

  @override
  String get hotelAccessStatusApplicationBody => 'تراجع غزل كل طلب وتراسلكم بالقرار عبر البريد الإلكتروني. تضيفون إعلاناتكم بعد القبول.';

  @override
  String get hotelAccessStatusRejectedTitle => 'لم يُعتمد الطلب';

  @override
  String get hotelAccessStatusEditResubmit => 'تعديل وإعادة الإرسال';

  @override
  String get hotelAccessStatusApprovedTitle => 'تم قبول الطلب';

  @override
  String get hotelAccessStatusReasonsLabel => 'السبب';

  @override
  String get hotelAccessStatusProtoTitle => 'فريق غزل';

  @override
  String get hotelAccessStatusProtoApprove => 'قبول';

  @override
  String get hotelAccessStatusProtoReject => 'رفض';

  @override
  String get hotelAccessStatusSuspendedTitle => 'موقوف مؤقتًا';

  @override
  String get hotelAccessStatusSuspendedBody => 'تم إيقاف هذا الحساب مؤقتًا. للاستفسار يمكن التواصل مع دعم غزل.';

  @override
  String get hotelAccessStatusDeactivatedTitle => 'الوصول متوقف';

  @override
  String get hotelAccessStatusDeactivatedBody => 'تم إيقاف وصولكم إلى هذا الحساب. يمكنكم التواصل مع مسؤول الحساب.';

  @override
  String get hotelAccessStatusRevokedTitle => 'انتهت الجلسة';

  @override
  String get hotelAccessStatusRevokedBody => 'أنهى مسؤول الحساب هذه الجلسة. يلزم تسجيل الدخول مجددًا.';

  @override
  String get hotelAccessStatusNoAccessBody => 'لا تملكون صلاحية الوصول. يمكنكم مراجعة مسؤول الحساب.';

  @override
  String get hotelAccessStatusSignOut => 'تسجيل الخروج';

  @override
  String get hotelAccessStatusSwitchVenue => 'تبديل القاعة';

  @override
  String get hotelAccessStatusActive => 'نشطة';

  @override
  String get hotelBookingsTitle => 'الحجوزات';

  @override
  String get hotelBookingsSearch => 'بحث في الحجوزات';

  @override
  String get hotelBookingsSearchPlaceholder => 'الاسم، المرجع، التاريخ';

  @override
  String get hotelBookingsFilterByDate => 'تصفية حسب التاريخ';

  @override
  String get hotelBookingsSegments => 'أقسام الحجوزات';

  @override
  String get hotelBookingsSegPending => 'المعلقة';

  @override
  String get hotelBookingsSegUpcoming => 'القادمة';

  @override
  String get hotelBookingsSegPast => 'السابقة';

  @override
  String get hotelBookingsWaitingTitle => 'بانتظار العميل';

  @override
  String hotelBookingsOpenRequest(String date) {
    return 'فتح الطلب: $date';
  }

  @override
  String hotelBookingsTimeLeft(String time) {
    return 'باقي $time';
  }

  @override
  String get hotelBookingsAudienceWomen => 'نسائي';

  @override
  String get hotelBookingsAudienceMen => 'رجالي';

  @override
  String get hotelBookingsAudienceMixed => 'مختلط';

  @override
  String get hotelBookingsVerified => 'رقم موثّق';

  @override
  String get hotelBookingsFirstBooking => 'أول حجز';

  @override
  String hotelBookingsMessageName(String name) {
    return 'مراسلة $name';
  }

  @override
  String hotelBookingsCallName(String name) {
    return 'الاتصال بالعميل $name';
  }

  @override
  String get hotelBookingsSpecialRequests => 'طلبات خاصة';

  @override
  String get hotelBookingsHeldLine => 'التاريخ محجوز';

  @override
  String hotelBookingsOthersSameDate(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+⁦$countString⁩ طلب آخر لهذا التاريخ',
      many: '+⁦$countString⁩ طلبًا آخر لهذا التاريخ',
      few: '+⁦$countString⁩ طلبات أخرى لهذا التاريخ',
      two: '+⁦$countString⁩ طلبان آخران لهذا التاريخ',
      one: '+⁦$countString⁩ طلب آخر لهذا التاريخ',
      zero: 'لا طلبات أخرى',
    );
    return '$_temp0';
  }

  @override
  String get hotelBookingsCompare => 'مقارنة';

  @override
  String get hotelBookingsViewOnly => 'للعرض فقط';

  @override
  String get hotelBookingsOfflineShort => 'غير متصل';

  @override
  String hotelBookingsOfflineBanner(String time) {
    return 'غير متصل · آخر تحديث $time';
  }

  @override
  String get hotelBookingsProposeDate => 'اقتراح تاريخ آخر';

  @override
  String get hotelBookingsEmptyPendingTitle => 'لا طلبات معلقة';

  @override
  String get hotelBookingsSeeUpcoming => 'عرض القادمة';

  @override
  String get hotelBookingsNextEvent => 'المناسبة القادمة';

  @override
  String get hotelBookingsEmptyUpcomingTitle => 'لا حجوزات';

  @override
  String get hotelBookingsPastFilter => 'تصفية السابقة';

  @override
  String hotelBookingsNoResultsTitle(String query) {
    return 'لا نتائج عن $query';
  }

  @override
  String get hotelBookingsRecentTitle => 'الأخيرة';

  @override
  String hotelBookingsAcceptedToast(String name) {
    return 'تمت الموافقة · $name';
  }

  @override
  String get hotelBookingsAwaitingCouple => 'بانتظار العميل';

  @override
  String hotelBookingsConfirmLeft(String time) {
    return 'باقي $time للتأكيد';
  }

  @override
  String get hotelBookingsNotRedeemed => 'الكوبون غير مستخدم';

  @override
  String hotelBookingsRedeemedBy(String name, String date) {
    return 'استُخدم بواسطة $name، $date';
  }

  @override
  String get hotelBookingsRedeemedPlain => 'تم الاستخدام';

  @override
  String get hotelBookingsActorVenue => 'الفندق';

  @override
  String get hotelBookingsActorGhazal => 'غزل';

  @override
  String get hotelBookingsActorSystem => 'النظام';

  @override
  String get hotelBookingsActorClient => 'العميل';

  @override
  String get hotelBookingsByVenue => 'ألغاه الفندق';

  @override
  String get hotelBookingsByClient => 'ألغاه العميل';

  @override
  String get hotelBookingsDeclineDate => 'التاريخ غير متاح';

  @override
  String get hotelBookingsDeclineCapacity => 'السعة';

  @override
  String get hotelBookingsDeclinePackage => 'الباقة';

  @override
  String get hotelBookingsDeclineOther => 'أخرى';

  @override
  String get hotelBookingsDeclineReason => 'السبب';

  @override
  String hotelBookingsSilence(String time) {
    return 'دون رد لمدة $time';
  }

  @override
  String get hotelBookingsFactsLabel => 'التفاصيل';

  @override
  String get hotelBookingsFactDate => 'تاريخ المناسبة';

  @override
  String get hotelBookingsFactGuests => 'الضيوف';

  @override
  String get hotelBookingsFactHall => 'القاعة';

  @override
  String get hotelBookingsFactTime => 'الوقت';

  @override
  String get hotelBookingsSessionDay => 'فترة نهارية';

  @override
  String get hotelBookingsSessionAfternoon => 'فترة العصر';

  @override
  String get hotelBookingsSessionEvening => 'فترة مسائية';

  @override
  String hotelBookingsBillable(int count) {
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
      zero: 'بلا ضيوف',
    );
    return 'الحساب على أساس $_temp0';
  }

  @override
  String get hotelBookingsFilterTitle => 'التواريخ';

  @override
  String get hotelBookingsFilterBy => 'تصفية حسب';

  @override
  String get hotelBookingsFilterEvent => 'المناسبة';

  @override
  String get hotelBookingsFilterRequest => 'الطلب';

  @override
  String hotelBookingsRangeLine(String from, String to) {
    return '$from – $to';
  }

  @override
  String get hotelBookingsRangeApplied => 'تصفية التاريخ مطبّقة';

  @override
  String get hotelBookingsDetailTitle => 'الحجز';

  @override
  String hotelBookingsReplyLeft(String time) {
    return 'باقي $time للرد';
  }

  @override
  String get hotelBookingsDaysToGo => 'الأيام المتبقية';

  @override
  String get hotelBookingsEventToday => 'المناسبة اليوم';

  @override
  String get hotelBookingsKnotVoucher => 'كوبون';

  @override
  String get hotelBookingsKnotRequest => 'الطلب';

  @override
  String get hotelBookingsKnotApproval => 'الموافقة';

  @override
  String get hotelBookingsKnotConfirmed => 'التأكيد';

  @override
  String get hotelBookingsKnotRedeemed => 'الاستخدام';

  @override
  String get hotelBookingsProgressLabel => 'مراحل الحجز';

  @override
  String hotelBookingsStepOf(String n, String total) {
    return 'المرحلة $n من $total';
  }

  @override
  String get hotelBookingsIssueReported => 'أبلغ العميل عن مشكلة';

  @override
  String get hotelBookingsIssueLink => 'الدعم';

  @override
  String get hotelBookingsCreateWindow => 'تحديد السعر';

  @override
  String get hotelBookingsDateFreeAgain => 'التاريخ متاح';

  @override
  String get hotelBookingsShowMore => 'عرض المزيد';

  @override
  String get hotelBookingsShowLess => 'عرض أقل';

  @override
  String get hotelBookingsRowServiceDate => 'تاريخ الخدمة';

  @override
  String get hotelBookingsEventTitle => 'المناسبة';

  @override
  String get hotelBookingsRowPackage => 'الباقة';

  @override
  String get hotelBookingsRowHall => 'القاعة';

  @override
  String get hotelBookingsRowDate => 'التاريخ';

  @override
  String get hotelBookingsRowTime => 'الوقت';

  @override
  String get hotelBookingsRowRedeemedBy => 'استخدمه';

  @override
  String get hotelBookingsPriceTitle => 'السعر';

  @override
  String get hotelBookingsClientSaves => 'توفير العميل';

  @override
  String get hotelBookingsInfoPriceTitle => 'سعر الكوبون';

  @override
  String get hotelBookingsDirectNote => 'تحصّلون هذا المبلغ مباشرة من العميل. ولا تعرض غزل أي حالة دفع.';

  @override
  String get hotelBookingsVoucherBound => 'مرتبط بطلب';

  @override
  String get hotelBookingsVoucherRedeemed => 'تم الاستخدام';

  @override
  String get hotelBookingsVoucherReturned => 'أُعيد';

  @override
  String get hotelBookingsVoucherExpired => 'منتهي';

  @override
  String get hotelBookingsVoucherNotValid => 'غير صالح';

  @override
  String get hotelBookingsProposalTitle => 'مواعيد جديدة';

  @override
  String get hotelBookingsProposalWindow => 'رد العميل قبل';

  @override
  String get hotelBookingsPriceChanged => 'السعر يتغير';

  @override
  String get hotelBookingsInfoReturned => 'عاد كوبون العميل إليه، والتاريخ متاح من جديد.';

  @override
  String get hotelBookingsInfoClientUsed => 'ألغى العميل بعد التأكيد، لذلك استُهلك كوبونه. التاريخ متاح من جديد.';

  @override
  String get hotelBookingsInfoVenue => 'أُعيد كوبون العميل ويمكنه طلب رصيد من الدعم. وسُجِّل ذلك في سجل الموثوقية.';

  @override
  String get hotelBookingsMarkCompleted => 'إكمال';

  @override
  String get hotelBookingsCancelBooking => 'إلغاء الحجز';

  @override
  String get hotelBookingsCancelInfoTitle => 'الإلغاء';

  @override
  String get hotelBookingsCancelNote => 'يعود الكوبون إلى العميل، ويمكنه طلب رصيد من الدعم. ويُسجَّل ذلك في سجل الموثوقية.';

  @override
  String get hotelBookingsRevokeApproval => 'سحب الموافقة';

  @override
  String get hotelBookingsReplyToReview => 'رد';

  @override
  String get hotelBookingsCompletedToast => 'تم الإكمال';

  @override
  String get hotelBookingsAuditTitle => 'السجل';

  @override
  String get hotelBookingsAuditRequested => 'استلام';

  @override
  String get hotelBookingsAuditApproved => 'موافقة';

  @override
  String get hotelBookingsAuditConfirmed => 'تأكيد';

  @override
  String get hotelBookingsAuditRedeemed => 'استخدام';

  @override
  String get hotelBookingsAuditDeclined => 'اعتذار';

  @override
  String get hotelBookingsAuditExpired => 'انتهاء المهلة';

  @override
  String get hotelBookingsAuditLapsed => 'سقوط الموافقة';

  @override
  String get hotelBookingsAuditRevoked => 'سحب الموافقة';

  @override
  String get hotelBookingsAuditCancelled => 'إلغاء';

  @override
  String get hotelBookingsAuditCompleted => 'إكمال';

  @override
  String get hotelBookingsAuditProposal => 'موعد جديد';

  @override
  String get hotelBookingsAuditUpdated => 'تحديث';

  @override
  String get hotelBookingsChatRow => 'محادثة';

  @override
  String get hotelBookingsNotShared => 'الرقم غير مشارك';

  @override
  String get hotelBookingsContactPrivacy => 'يظهر هذا الرقم لهذا الحجز فقط. ولا يظهر رمز كوبون العميل إلا عند استخدامه.';

  @override
  String get hotelBookingsContactOffline => 'لا يوجد اتصال. الاتصال الهاتفي متاح، وتُرسل الرسائل عند عودة الاتصال.';

  @override
  String get hotelBookingsRoleNoContact => 'صلاحية حسابكم لا تتيح التواصل مع العملاء. راجعوا المدير.';

  @override
  String hotelBookingsCallToast(String name) {
    return 'اتصال بالعميل $name';
  }

  @override
  String hotelBookingsWhatsappToast(String name) {
    return 'واتساب $name';
  }

  @override
  String get hotelBookingsRedeemMode => 'طريقة الإدخال';

  @override
  String get hotelBookingsModeScan => 'مسح';

  @override
  String get hotelBookingsModeType => 'رمز';

  @override
  String get hotelBookingsTypeCode => 'إدخال الرمز';

  @override
  String get hotelBookingsScanDemo => 'محاكاة';

  @override
  String get hotelBookingsTorchOn => 'تشغيل الإضاءة';

  @override
  String get hotelBookingsTorchOff => 'إيقاف الإضاءة';

  @override
  String get hotelBookingsCameraDeniedTitle => 'الكاميرا متوقفة';

  @override
  String get hotelBookingsCameraDeniedBody => 'فعّلوا الكاميرا من إعدادات الهاتف للمسح، أو أدخلوا الرمز يدويًا.';

  @override
  String get hotelBookingsCheckCode => 'فحص الرمز';

  @override
  String get hotelBookingsChecking => 'جارٍ التحقق';

  @override
  String get hotelBookingsTryAnother => 'رمز آخر';

  @override
  String get hotelBookingsErrUnknownField => 'الرمز غير موجود';

  @override
  String get hotelBookingsErrUnknownTitle => 'الرمز غير موجود';

  @override
  String get hotelBookingsErrUnknownBody => 'تحققوا منه وحاولوا مرة أخرى.';

  @override
  String get hotelBookingsErrOtherTitle => 'كوبون جهة أخرى';

  @override
  String get hotelBookingsErrOtherBody => 'لا يمكن استخدامه إلا لدى الجهة المخصص لها. ولا تظهر أي تفاصيل أخرى.';

  @override
  String get hotelBookingsErrNotConfirmedTitle => 'لم يؤكد بعد';

  @override
  String get hotelBookingsErrNotConfirmedBody => 'يجب أن يؤكد العميل الحجز قبل استخدام الكوبون.';

  @override
  String get hotelBookingsErrUsedPlain => 'استُخدم سابقًا';

  @override
  String get hotelBookingsErrUsedBody => 'الكوبون يُستخدم مرة واحدة فقط. تواصلوا مع الدعم إن بدا ذلك خطأً.';

  @override
  String get hotelBookingsErrExpiredTitle => 'غير صالح';

  @override
  String get hotelBookingsErrExpiredBody => 'لم يعد بالإمكان استخدامه.';

  @override
  String get hotelBookingsRedeemErrorBody => 'لم يتم تغيير أي شيء. يُرجى المحاولة مرة أخرى.';

  @override
  String get hotelBookingsRoleHiddenBody => 'اطلبوا من المسؤول أو المدير أو الاستقبال استخدام الكوبون.';

  @override
  String get hotelBookingsRedeemFine => 'لا يمكن التراجع عن الاستخدام. ويستطيع فريق الدعم التعديل عند حدوث خطأ.';

  @override
  String get hotelBookingsRedeemedFine => 'يدفع العميل لكم مباشرة. ولا تعرض غزل أي مبلغ مستحق.';

  @override
  String hotelBookingsRedeemedCached(String time) {
    return 'غير متصل · محفوظ $time';
  }

  @override
  String get hotelBookingsViewBooking => 'عرض الحجز';

  @override
  String get hotelBookingsProtoTag => 'تجريبي';

  @override
  String get hotelBookingsProtoTitle => 'اختصارات تجريبية';

  @override
  String get hotelBookingsProtoReady => 'كوبون جاهز';

  @override
  String get hotelBookingsProtoNotConfirmed => 'لم يؤكد بعد';

  @override
  String get hotelBookingsProtoUsed => 'استُخدم سابقًا';

  @override
  String get hotelBookingsProtoOther => 'جهة أخرى';

  @override
  String get hotelBookingsBackToList => 'الحجوزات';

  @override
  String hotelBookingsDurJoin(String first, String second) {
    return '$first و$second';
  }

  @override
  String get hotelCalendarTitle => 'التقويم';

  @override
  String get hotelCalendarViewLabel => 'عرض التقويم';

  @override
  String get hotelCalendarViewMonth => 'شهر';

  @override
  String get hotelCalendarViewWeek => 'أسبوع';

  @override
  String get hotelCalendarViewDay => 'يوم';

  @override
  String get hotelCalendarHallsLabel => 'القاعات';

  @override
  String get hotelCalendarHallsAll => 'الكل';

  @override
  String hotelCalendarGridLabel(String month) {
    return 'التقويم، $month';
  }

  @override
  String get hotelCalendarPrevWeek => 'الأسبوع السابق';

  @override
  String get hotelCalendarNextWeek => 'الأسبوع التالي';

  @override
  String get hotelCalendarPrevDay => 'اليوم السابق';

  @override
  String get hotelCalendarNextDay => 'اليوم التالي';

  @override
  String get hotelCalendarWeekLabel => 'أسبوع';

  @override
  String get hotelCalendarActionBlock => 'إغلاق التواريخ';

  @override
  String get hotelCalendarActionSelect => 'تحديد التواريخ';

  @override
  String get hotelCalendarReadOnly => 'للعرض فقط';

  @override
  String hotelCalendarOfflineStamp(String time) {
    return 'غير متصل · $time';
  }

  @override
  String get hotelCalendarOfflineNeed => 'يلزم اتصال';

  @override
  String get hotelCalendarNudgeTitle => 'التقويم محدَّث؟';

  @override
  String get hotelCalendarNudgeDone => 'التقويم مؤكد';

  @override
  String get hotelCalendarEmptyTitle => 'لا حجوزات';

  @override
  String hotelCalendarAgendaTitle(String date) {
    return 'جدول $date';
  }

  @override
  String get hotelCalendarOpenDay => 'عرض اليوم';

  @override
  String get hotelCalendarOpenLabel => 'متاح';

  @override
  String get hotelCalendarRequestedLabel => 'طلب';

  @override
  String hotelCalendarBlockedBy(String name) {
    return 'أغلقه $name';
  }

  @override
  String get hotelCalendarBlock => 'إغلاق';

  @override
  String get hotelCalendarOffer => 'عرض';

  @override
  String get hotelCalendarCreateOffer => 'إنشاء عرض';

  @override
  String get hotelCalendarOpenThisDate => 'فتح التاريخ';

  @override
  String get hotelCalendarWhyTitle => 'تعذّر الإغلاق';

  @override
  String get hotelCalendarSoldOutReason => 'لا يمكن إغلاق تاريخ عليه حجز مؤكد. يلزم إلغاء الحجز أولًا.';

  @override
  String get hotelCalendarSoftTitle => 'عطلات متاحة';

  @override
  String hotelCalendarSoftRow(int count, String days) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ تاريخ متاح في نهاية الأسبوع خلال $days يومًا',
      many: '⁦$countString⁩ تاريخًا متاحًا في نهاية الأسبوع خلال $days يومًا',
      few: '⁦$countString⁩ تواريخ متاحة في نهاية الأسبوع خلال $days يومًا',
      two: 'تاريخان متاحان في نهاية الأسبوع خلال $days يومًا',
      one: 'تاريخ متاح في نهاية الأسبوع خلال $days يومًا',
      zero: 'لا تواريخ متاحة في نهاية الأسبوع خلال $days يومًا',
    );
    return '$_temp0';
  }

  @override
  String get hotelCalendarLegendSoft => 'عطلة متاحة';

  @override
  String get hotelCalendarHallFact => 'القاعة';

  @override
  String get hotelCalendarGuestsFact => 'الضيوف';

  @override
  String get hotelCalendarCapacityFact => 'السعة';

  @override
  String get hotelCalendarSessionFact => 'الفترة';

  @override
  String get hotelCalendarHoldLeft => 'الوقت المتبقي';

  @override
  String get hotelCalendarStartsFact => 'يبدأ بعد';

  @override
  String get hotelCalendarBlockedByFact => 'أغلقه';

  @override
  String get hotelCalendarAudienceWomen => 'نسائي';

  @override
  String get hotelCalendarAudienceMen => 'رجالي';

  @override
  String get hotelCalendarAudienceMixed => 'مختلط';

  @override
  String get hotelCalendarKeyTitle => 'الرموز';

  @override
  String get hotelCalendarRequestNote => 'الطلب لا يحجز التاريخ.';

  @override
  String get hotelCalendarTimes => 'الأوقات';

  @override
  String get hotelCalendarSetup => 'التجهيز';

  @override
  String get hotelCalendarEvent => 'الحفل';

  @override
  String get hotelCalendarTeardown => 'الفك';

  @override
  String hotelCalendarTimelineLabel(String hall) {
    return '$hall، الجدول الزمني';
  }

  @override
  String get hotelCalendarOpenBooking => 'فتح الحجز';

  @override
  String hotelCalendarCall(String name) {
    return 'اتصال بالعميل $name';
  }

  @override
  String hotelCalendarMessage(String name) {
    return 'مراسلة العميل $name';
  }

  @override
  String get hotelCalendarHintDrag => 'اضغطوا مطولًا على تاريخ، ثم اسحبوا إلى آخر تاريخ.';

  @override
  String get hotelCalendarHintTap => 'أو انقروا أول تاريخ ثم آخره.';

  @override
  String get hotelCalendarRangeNone => 'اختيار التواريخ';

  @override
  String get hotelCalendarRangeSummary => 'التواريخ';

  @override
  String get hotelCalendarRangeBlock => 'إغلاق';

  @override
  String get hotelCalendarRangeOpen => 'فتح';

  @override
  String get hotelCalendarRangeOffer => 'عرض';

  @override
  String get hotelCalendarSheetBlockTitle => 'إغلاق التواريخ';

  @override
  String get hotelCalendarSheetOpenTitle => 'فتح التواريخ';

  @override
  String get hotelCalendarModeLabel => 'إغلاق أو فتح';

  @override
  String get hotelCalendarModeBlock => 'إغلاق';

  @override
  String get hotelCalendarModeOpen => 'فتح';

  @override
  String get hotelCalendarSumEdit => 'تغيير التواريخ';

  @override
  String get hotelCalendarShortcuts => 'اختصارات';

  @override
  String get hotelCalendarSession => 'الفترة';

  @override
  String get hotelCalendarReason => 'السبب';

  @override
  String get hotelCalendarNote => 'ملاحظة';

  @override
  String get hotelCalendarReasonOffline => 'حجز خارجي';

  @override
  String get hotelCalendarReasonMaintenance => 'صيانة';

  @override
  String get hotelCalendarReasonPrivate => 'مناسبة خاصة';

  @override
  String get hotelCalendarReasonOther => 'أخرى';

  @override
  String get hotelCalendarVisibilityHint => 'يتوقف ظهور التواريخ المغلقة للأزواج خلال ثوانٍ.';

  @override
  String get hotelCalendarOpenHint => 'تعود التواريخ المفتوحة إلى الحجز أمام الأزواج.';

  @override
  String hotelCalendarPendingWarn(int count, String date) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'لدى $date ⁦$countString⁩ طلب بانتظار الرد. ستظهر غير متاحة.',
      many: 'لدى $date ⁦$countString⁩ طلبًا بانتظار الرد. ستظهر غير متاحة.',
      few: 'لدى $date ⁦$countString⁩ طلبات بانتظار الرد. ستظهر غير متاحة.',
      two: 'لدى $date طلبان بانتظار الرد. سيظهران غير متاحين.',
      one: 'لدى $date طلب واحد بانتظار الرد. سيظهر غير متاح.',
      zero: 'لا طلبات بانتظار الرد على $date',
    );
    return '$_temp0';
  }

  @override
  String get hotelCalendarConflictBody => 'لا يمكن إغلاق تاريخ عليه حجز مؤكد. يلزم إلغاء الحجز أولًا.';

  @override
  String get hotelCalendarConflictTip => 'أو اختاروا القاعة المتاحة فقط.';

  @override
  String get hotelCalendarConflictCancel => 'إلغاء الحجز';

  @override
  String get hotelCalendarReasonConflict => 'التواريخ المتاحة فقط';

  @override
  String get hotelCalendarReasonChoose => 'اختيار التواريخ أولًا';

  @override
  String get hotelCalendarAlreadyBlocked => 'مغلقة بالفعل';

  @override
  String hotelCalendarCtaBlock(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'إغلاق ⁦$countString⁩ تاريخ',
      many: 'إغلاق ⁦$countString⁩ تاريخًا',
      few: 'إغلاق ⁦$countString⁩ تواريخ',
      two: 'إغلاق تاريخين',
      one: 'إغلاق تاريخ واحد',
      zero: 'إغلاق',
    );
    return '$_temp0';
  }

  @override
  String hotelCalendarCtaOpen(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'فتح ⁦$countString⁩ تاريخ',
      many: 'فتح ⁦$countString⁩ تاريخًا',
      few: 'فتح ⁦$countString⁩ تواريخ',
      two: 'فتح تاريخين',
      one: 'فتح تاريخ واحد',
      zero: 'فتح',
    );
    return '$_temp0';
  }

  @override
  String get hotelCalendarOpenListTitle => 'تواريخ مغلقة';

  @override
  String get hotelCalendarOpenEmpty => 'لا تواريخ مغلقة';

  @override
  String get hotelCalendarToastBlocked => 'مخفية عن الأزواج';

  @override
  String get hotelCalendarToastOpened => 'متاحة للحجز';

  @override
  String get hotelCalendarPartialTitle => 'تخطي بعض التواريخ';

  @override
  String get hotelCalendarSaveFailed => 'تعذّر الحفظ';

  @override
  String get hotelCalendarEmailTitle => 'التقويم عبر البريد';

  @override
  String get hotelCalendarEmailSwitch => 'أرسلوا لي دعوة بالبريد';

  @override
  String get hotelCalendarEmailAdd => 'بريد آخر';

  @override
  String get hotelCalendarEmailInvalid => 'تأكد من العنوان';

  @override
  String get hotelCalendarEmailTest => 'إرسال تجربة';

  @override
  String get hotelCalendarEmailTestSent => 'تم الإرسال';

  @override
  String get hotelDecisionsFactsLabel => 'التفاصيل';

  @override
  String get hotelDecisionsFactDate => 'التاريخ';

  @override
  String get hotelDecisionsFactGuests => 'الضيوف';

  @override
  String get hotelDecisionsFactSession => 'الفترة';

  @override
  String get hotelDecisionsFactLadies => 'نسائي';

  @override
  String get hotelDecisionsFactMen => 'رجالي';

  @override
  String get hotelDecisionsFactMixed => 'مختلط';

  @override
  String get hotelDecisionsOfflineInfo => 'لا تُؤجَّل القرارات إلى حين عودة الاتصال، لذلك لم يتغيّر شيء.';

  @override
  String get hotelDecisionsTermsTitle => 'الشروط';

  @override
  String get hotelDecisionsReason => 'السبب';

  @override
  String get hotelDecisionsPickReason => 'اختاروا السبب';

  @override
  String get hotelDecisionsNote => 'ملاحظة';

  @override
  String get hotelDecisionsNoteHelper => 'يراها العميل';

  @override
  String get hotelDecisionsNoteRequired => 'الملاحظة مطلوبة';

  @override
  String get hotelDecisionsViewBooking => 'عرض الطلب';

  @override
  String get hotelDecisionsRefresh => 'تحديث';

  @override
  String get hotelDecisionsAcceptTitle => 'قبول الطلب';

  @override
  String get hotelDecisionsAcceptCta => 'قبول';

  @override
  String hotelDecisionsAcceptConsequence(String date, String name, String duration) {
    return 'هذا يحجز <f>$date</f> باسم <n>$name</n> لمدة <f>$duration</f>.';
  }

  @override
  String get hotelDecisionsAcceptConfirmRule => 'إن لم يؤكد العميل، يُفرَج عن التاريخ ويعود إليه كوبونه.';

  @override
  String get hotelDecisionsAcceptPriceHint => 'يُدفع لكم مباشرة خارج التطبيق بعد تأكيد العميل.';

  @override
  String get hotelDecisionsAcceptLowerHint => 'خفض سعر الكوبون اختياري، ولا يكون أعلى من السعر المعروض. يرى العميل التوفير الجديد.';

  @override
  String hotelDecisionsAcceptHoldLabel(String duration) {
    return 'التاريخ محجوز لمدة $duration';
  }

  @override
  String get hotelDecisionsAcceptDeadlineLabel => 'يؤكد العميل حتى';

  @override
  String get hotelDecisionsAcceptOffApp => 'خارج التطبيق';

  @override
  String hotelDecisionsAcceptOthersLine(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يوجد ⁦$countString⁩ طلب آخر لهذا التاريخ',
      many: 'يوجد ⁦$countString⁩ طلبًا آخر لهذا التاريخ',
      few: 'يوجد ⁦$countString⁩ طلبات أخرى لهذا التاريخ',
      two: 'يوجد طلبان آخران لهذا التاريخ',
      one: 'يوجد طلب آخر لهذا التاريخ',
      zero: 'لا توجد طلبات أخرى لهذا التاريخ',
    );
    return '$_temp0';
  }

  @override
  String get hotelDecisionsAcceptCompare => 'مقارنة';

  @override
  String get hotelDecisionsAcceptCompareThis => 'هذا';

  @override
  String get hotelDecisionsAcceptCompareOther => 'الآخر';

  @override
  String get hotelDecisionsAcceptCompareReceived => 'وصل';

  @override
  String get hotelDecisionsAcceptLower => 'سعر أقل';

  @override
  String get hotelDecisionsAcceptLowerLabel => 'خفض بمقدار';

  @override
  String get hotelDecisionsAcceptLowerTooHigh => 'أقل من سعر الكوبون';

  @override
  String get hotelDecisionsAcceptedTitle => 'تمت الموافقة';

  @override
  String hotelDecisionsAcceptedBody(String name, String deadline) {
    return 'التاريخ محجوز باسم <n>$name</n>، والمهلة للتأكيد حتى <f>$deadline</f>.';
  }

  @override
  String get hotelDecisionsAcceptedUndoHint => 'يصل الإشعار إلى العميل بعد ثوانٍ، ويمكنكم التراجع قبل ذلك.';

  @override
  String get hotelDecisionsNotifying => 'إبلاغ العميل';

  @override
  String get hotelDecisionsUndoneTitle => 'عاد للانتظار';

  @override
  String get hotelDecisionsUndoneBody => 'أُفرج عن التاريخ ولم يُبلَّغ العميل.';

  @override
  String get hotelDecisionsConflictTitle => 'محجوز مؤقتًا';

  @override
  String hotelDecisionsConflictBody(String date) {
    return 'طلب موافَق عليه لعميل آخر يحجز <f>$date</f> إلى حين تأكيده. يمكنكم اقتراح تاريخ مختلف.';
  }

  @override
  String get hotelDecisionsAlreadyTitle => 'تم تحديثه';

  @override
  String get hotelDecisionsAlreadyBody => 'غيّره أحد من فريقكم أو العميل قبل لحظات. هذه حالته الآن.';

  @override
  String get hotelDecisionsReleasedTitle => 'تم سحب الطلب';

  @override
  String get hotelDecisionsReleasedBody => 'لم يعد كوبون العميل مرتبطًا بمكانكم، لذلك لا يوجد ما تتم الموافقة عليه. سيختفي الطلب من قائمتكم.';

  @override
  String get hotelDecisionsDeclineTitle => 'الاعتذار عن الطلب';

  @override
  String get hotelDecisionsDeclineReasonDate => 'التاريخ';

  @override
  String get hotelDecisionsDeclineReasonCapacity => 'السعة';

  @override
  String get hotelDecisionsDeclineReasonPackage => 'الباقة';

  @override
  String get hotelDecisionsDeclineReasonOther => 'أخرى';

  @override
  String get hotelDecisionsDeclineSuggestTitle => 'اقتراح مواعيد';

  @override
  String get hotelDecisionsDeclineSuggestBody => 'سيظهر للعميل اعتذار لطيف مع أماكن متاحة في التاريخ نفسه.';

  @override
  String get hotelDecisionsDeclineVoucher => 'يعود الكوبون';

  @override
  String get hotelDecisionsDeclineVoucherInfo => 'يعود كوبون العميل إليه. الاعتذار لا يترتب عليه أي مبلغ.';

  @override
  String get hotelDecisionsDeclineNoUndo => 'لا يمكن التراجع عن الاعتذار.';

  @override
  String get hotelDecisionsDeclineNoUndoShort => 'لا تراجع';

  @override
  String get hotelDecisionsDeclineCtaNext => 'اختيار التواريخ';

  @override
  String get hotelDecisionsDeclineCta => 'اعتذار';

  @override
  String get hotelDecisionsDeclinedTitle => 'تم الاعتذار';

  @override
  String get hotelDecisionsDeclinedBody => 'أُبلغ العميل وعاد إليه كوبونه.';

  @override
  String get hotelDecisionsProposeTitle => 'اقتراح موعد';

  @override
  String hotelDecisionsProposeIntro(String window) {
    return 'اختاروا من تاريخ إلى ثلاثة تواريخ متاحة للقاعة والفترة نفسيهما. أمام العميل $window للرد.';
  }

  @override
  String hotelDecisionsProposeHold(String amount) {
    return 'كل تاريخ يحتفظ بسعر الكوبون المعروض $amount. إن كان سعره المعتاد أعلى، فالفرق على المكان.';
  }

  @override
  String get hotelDecisionsProposeHallLabel => 'القاعة';

  @override
  String hotelDecisionsProposeCalendarLabel(String hall) {
    return 'التواريخ المتاحة في $hall';
  }

  @override
  String get hotelDecisionsProposeOriginal => 'التاريخ الأصلي';

  @override
  String get hotelDecisionsProposeChosen => 'اقتراحكم';

  @override
  String hotelDecisionsProposeRemove(String date) {
    return 'إزالة $date';
  }

  @override
  String get hotelDecisionsProposeTakenBadge => 'التاريخ محجوز';

  @override
  String get hotelDecisionsProposeHeldLabel => 'سعر الكوبون محفوظ';

  @override
  String get hotelDecisionsProposeLowerLabel => 'أقل بمقدار';

  @override
  String get hotelDecisionsProposeReplyLabel => 'مهلة رد العميل';

  @override
  String hotelDecisionsProposeCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ تاريخ مختار',
      many: '⁦$countString⁩ تاريخًا مختارًا',
      few: '⁦$countString⁩ تواريخ مختارة',
      two: 'تاريخان مختاران',
      one: 'تاريخ واحد مختار',
      zero: 'لا تواريخ مختارة',
    );
    return '$_temp0';
  }

  @override
  String get hotelDecisionsProposeCta => 'إرسال الاقتراح';

  @override
  String get hotelDecisionsProposePick => 'اختاروا تاريخًا';

  @override
  String get hotelDecisionsProposeEmptyTitle => 'لا تواريخ متاحة';

  @override
  String hotelDecisionsProposeEmpty(String days) {
    return 'لا توجد تواريخ متاحة خلال $days لهذه القاعة.';
  }

  @override
  String get hotelDecisionsProposeEmptyAction => 'فتح التقويم';

  @override
  String get hotelDecisionsProposeNoHallTitle => 'الاتفاق بالمحادثة';

  @override
  String get hotelDecisionsProposeNoHallBody => 'طلب الخدمة ليس له تقويم قاعات. راسلوا العميل في المحادثة للاتفاق على يوم آخر.';

  @override
  String get hotelDecisionsProposeSentTitle => 'تم إرسال الاقتراح';

  @override
  String hotelDecisionsProposeSentBody(String duration) {
    return 'يبقى الطلب بانتظار الرد مع إرفاق تواريخكم. إن قبل العميل أحدها تبدأ مهلة تأكيد جديدة مدتها $duration.';
  }

  @override
  String hotelDecisionsProposeAwaiting(String name, String deadline) {
    return 'بانتظار <n>$name</n> · الرد قبل <f>$deadline</f>';
  }

  @override
  String hotelDecisionsToastProposed(String window) {
    return 'تم إرسال الاقتراح · $window';
  }

  @override
  String get hotelDecisionsCancelTitle => 'إلغاء الحجز';

  @override
  String get hotelDecisionsCancelTitleApproved => 'سحب الموافقة';

  @override
  String get hotelDecisionsCancelTalkTitle => 'ابدؤوا بالمحادثة';

  @override
  String get hotelDecisionsCancelTalkBody => 'يُتفق على أي موعد جديد مع العميل في المحادثة. وإن تغيّر التاريخ فقد يحتاج العميل إلى طلب جديد.';

  @override
  String get hotelDecisionsCancelReasonHall => 'غير متاحة';

  @override
  String get hotelDecisionsCancelReasonSafety => 'صيانة وسلامة';

  @override
  String get hotelDecisionsCancelReasonOther => 'أخرى';

  @override
  String get hotelDecisionsCancelConsequence => 'ماذا يحدث';

  @override
  String get hotelDecisionsCancelVoucherInfo => 'يعود كوبون العميل إليه ليستخدمه مجددًا.';

  @override
  String get hotelDecisionsCancelStrikeInfo => 'يُسجَّل مؤشر موثوقية ويُتاح التاريخ من جديد.';

  @override
  String get hotelDecisionsCancelNoMoney => 'لا تنتقل أي مبالغ داخل التطبيق. وأي مبلغ دفعه العميل لكم مسبقًا تتم تسويته بينكما.';

  @override
  String get hotelDecisionsConsReturned => 'يعود';

  @override
  String get hotelDecisionsConsStrike => 'مؤشر موثوقية';

  @override
  String get hotelDecisionsConsReopens => 'يُتاح';

  @override
  String get hotelDecisionsCancelCta => 'إلغاء الحجز';

  @override
  String get hotelDecisionsCancelCtaApproved => 'سحب الموافقة';

  @override
  String get hotelDecisionsCancelKeep => 'إبقاء الحجز';

  @override
  String get hotelDecisionsCancelKeepApproved => 'إبقاء الموافقة';

  @override
  String get hotelDecisionsCancelDialogTitle => 'إلغاء الحجز؟';

  @override
  String get hotelDecisionsCancelDialogTitleApproved => 'سحب الموافقة؟';

  @override
  String hotelDecisionsCancelDialogBody(String name, String date) {
    return '<n>$name</n> · <f>$date</f>';
  }

  @override
  String get hotelDecisionsCancelledTitle => 'تم الإلغاء';

  @override
  String get hotelDecisionsCancelledTitleApproved => 'تم سحب الموافقة';

  @override
  String get hotelDecisionsCancelledWindow => 'عرض جديد';

  @override
  String get hotelDecisionsCancelHiddenTitle => 'للمدراء فقط';

  @override
  String get hotelDecisionsCancelHiddenBody => 'يستطيع المدير أو المشرف فقط إلغاء حجز مؤكد.';

  @override
  String hotelGrowOfflineStamp(String time) {
    return 'غير متصل · آخر تحديث $time';
  }

  @override
  String get hotelGrowErrorBody => 'لم يتم تغيير أي شيء. يُرجى التأكد من الاتصال والمحاولة مرة أخرى.';

  @override
  String get hotelGrowTabsLabel => 'أسعار الكوبون حسب الحالة';

  @override
  String get hotelGrowTabActive => 'فعّالة';

  @override
  String get hotelGrowTabScheduled => 'مجدولة';

  @override
  String get hotelGrowTabEnded => 'منتهية';

  @override
  String get hotelGrowPaused => 'متوقف مؤقتًا';

  @override
  String get hotelGrowAppliesAll => 'جميع الباقات';

  @override
  String hotelGrowSoftInsight(int count, num days) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ تاريخ مفتوح في نهاية الأسبوع خلال ⁦$daysString⁩ يومًا',
      many: '⁦$countString⁩ تاريخًا مفتوحًا في نهاية الأسبوع خلال ⁦$daysString⁩ يومًا',
      few: '⁦$countString⁩ تواريخ مفتوحة في نهاية الأسبوع خلال ⁦$daysString⁩ يومًا',
      two: 'تاريخان مفتوحان في نهاية الأسبوع خلال ⁦$daysString⁩ يومًا',
      one: 'تاريخ مفتوح في نهاية الأسبوع خلال ⁦$daysString⁩ يومًا',
      zero: 'لا تواريخ مفتوحة في نهاية الأسبوع خلال ⁦$daysString⁩ يومًا',
    );
    return '$_temp0';
  }

  @override
  String get hotelGrowEmptyTitle => 'لا توجد نوافذ سعر مؤقتة';

  @override
  String get hotelGrowNoScheduledTitle => 'لا عروض مجدولة';

  @override
  String get hotelGrowNoEndedTitle => 'لا توجد نوافذ منتهية';

  @override
  String get hotelGrowShowActive => 'عرض الأسعار الفعّالة';

  @override
  String get hotelGrowActionsLabel => 'إجراءات سعر الكوبون';

  @override
  String get hotelGrowStatStarts => 'يبدأ';

  @override
  String get hotelGrowPreviewWaiting => 'أدخلوا سعر كوبون صحيحًا لتروا البطاقة كما سيراها العملاء.';

  @override
  String get hotelGrowPreviewLabel => 'كما يراه العملاء';

  @override
  String get hotelGrowEffectNote => 'الإيقاف والإنهاء يسريان على العملاء فورًا.';

  @override
  String get hotelGrowPause => 'إيقاف النافذة مؤقتًا';

  @override
  String get hotelGrowResume => 'استئناف النافذة';

  @override
  String get hotelGrowDuplicate => 'نسخ العرض';

  @override
  String get hotelGrowEndNow => 'إنهاء الآن';

  @override
  String hotelGrowToastPaused(String title) {
    return 'تم إيقاف $title مؤقتًا. يرى العملاء سعر الكوبون الدائم.';
  }

  @override
  String hotelGrowToastResumed(String title) {
    return '$title فعّال من جديد.';
  }

  @override
  String hotelGrowToastEnded(String title) {
    return 'انتهى $title.';
  }

  @override
  String hotelGrowEndTitle(String title) {
    return 'إنهاء $title الآن؟';
  }

  @override
  String get hotelGrowEndBody => 'يعود العملاء إلى سعر الكوبون الدائم فورًا. الطلبات المرسلة تحتفظ بسعرها. لا يمكن التراجع عن الإنهاء.';

  @override
  String get hotelGrowEndConfirm => 'إنهاء النافذة';

  @override
  String get hotelGrowEndKeep => 'إبقاء النافذة';

  @override
  String get hotelGrowStepsLabel => 'خطوات نافذة سعر الكوبون';

  @override
  String get hotelGrowValueTitle => 'سعر الكوبون';

  @override
  String hotelGrowOverError(String max) {
    return 'لا يمكن أن يتجاوز سعر الكوبون السعر العادي $max.';
  }

  @override
  String get hotelGrowEmptyValueError => 'أدخلوا سعر الكوبون بالدينار، حتى ثلاث خانات عشرية.';

  @override
  String get hotelGrowBestOnly => 'يُطبَّق أفضل سعر كوبون فقط على كل طلب، والأسعار لا تتراكم.';

  @override
  String get hotelGrowScopeTitle => 'ينطبق على';

  @override
  String get hotelGrowPackagesLabel => 'الباقات';

  @override
  String get hotelGrowHallsLabel => 'القاعات';

  @override
  String get hotelGrowAllHalls => 'جميع القاعات';

  @override
  String get hotelGrowTitleTitle => 'عنوان النافذة';

  @override
  String get hotelGrowTitleEn => 'العنوان بالإنجليزية';

  @override
  String get hotelGrowTitleAr => 'العنوان بالعربية';

  @override
  String get hotelGrowTitleComplete => 'مكتمل';

  @override
  String get hotelGrowCouplesSee => 'يراه العملاء';

  @override
  String get hotelGrowNextReasonTitles => 'أضيفوا العنوان باللغتين للمتابعة.';

  @override
  String get hotelGrowNextReasonValue => 'صحّحوا سعر الكوبون للمتابعة.';

  @override
  String get hotelGrowPrefilledTitle => 'لهذه التواريخ';

  @override
  String get hotelGrowOfflineEdit => 'لا يوجد اتصال. يمكنكم متابعة التعديل، أما النشر فيتطلب اتصالًا.';

  @override
  String get hotelGrowGuardTitle => 'تجاهل هذه النافذة؟';

  @override
  String get hotelGrowGuardDiscard => 'تجاهل';

  @override
  String get hotelGrowGuardKeep => 'متابعة التعديل';

  @override
  String get hotelGrowEditorErrorBody => 'لم يتم حفظ أي شيء. يُرجى التأكد من الاتصال والمحاولة مرة أخرى.';

  @override
  String get hotelGrowDatesTitle => 'تواريخ المناسبات';

  @override
  String get hotelGrowShortcuts => 'اختصارات';

  @override
  String get hotelGrowChooseDates => 'اختيار التواريخ يدويًا';

  @override
  String get hotelGrowNoDatesError => 'اختاروا تاريخ مناسبة واحدًا على الأقل.';

  @override
  String hotelGrowDatesChosen(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم اختيار ⁦$countString⁩ تاريخ',
      many: 'تم اختيار ⁦$countString⁩ تاريخًا',
      few: 'تم اختيار ⁦$countString⁩ تواريخ',
      two: 'تم اختيار تاريخين',
      one: 'تم اختيار تاريخ واحد',
      zero: 'لم تُختر تواريخ',
    );
    return '$_temp0';
  }

  @override
  String get hotelGrowClearDates => 'مسح';

  @override
  String get hotelGrowUseOpenDates => 'استخدام التواريخ المفتوحة';

  @override
  String get hotelGrowOpenWeekend => 'مفتوح في نهاية الأسبوع';

  @override
  String hotelGrowOverlap(String title, String value, String dates) {
    return '$title بسعر $value يغطي $dates. سيُطبَّق سعر الكوبون الأفضل.';
  }

  @override
  String get hotelGrowRunsTitle => 'مدة العرض';

  @override
  String get hotelGrowScheduledPill => 'مجدول';

  @override
  String get hotelGrowStartsLabel => 'يبدأ في';

  @override
  String get hotelGrowEndsLabel => 'ينتهي في';

  @override
  String get hotelGrowEndBeforeStart => 'تاريخ الانتهاء قبل تاريخ البدء.';

  @override
  String get hotelGrowPublish => 'نشر النافذة';

  @override
  String get hotelGrowSchedule => 'جدولة النافذة';

  @override
  String get hotelGrowOfflinePublish => 'أعيدوا الاتصال للنشر.';

  @override
  String get hotelGrowReasonDates => 'اختاروا تواريخ المناسبات أولًا.';

  @override
  String get hotelGrowReasonEnd => 'حدّدوا تاريخ انتهاء صحيحًا أولًا.';

  @override
  String get hotelGrowPublishFailed => 'لم يتم نشر النافذة. لم يتغير شيء، حاولوا مرة أخرى.';

  @override
  String hotelGrowToastPublished(String title) {
    return 'تم نشر $title.';
  }

  @override
  String hotelGrowToastScheduled(String title) {
    return 'تمت جدولة $title.';
  }

  @override
  String get hotelGrowView => 'عرض';

  @override
  String get hotelGrowAnTitle => 'التحليلات';

  @override
  String get hotelGrowAnRangeLabel => 'الفترة';

  @override
  String get hotelGrowAnRangeMonth => 'هذا الشهر';

  @override
  String hotelGrowAnRangeDays(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    return 'آخر ⁦$daysString⁩ يومًا';
  }

  @override
  String get hotelGrowAnRangeCustom => 'فترة محددة';

  @override
  String hotelGrowAnRangeNote(String date) {
    return 'البيانات متاحة اعتبارًا من $date.';
  }

  @override
  String get hotelGrowAnKpiViews => 'المشاهدات';

  @override
  String get hotelGrowAnKpiClicks => 'النقرات';

  @override
  String get hotelGrowAnKpiConversion => 'نسبة التحويل';

  @override
  String get hotelGrowAnVsPrevious => 'عن الفترة السابقة';

  @override
  String hotelGrowAnChartDesc(String metric, String from, String to) {
    return '$metric، من $from إلى $to.';
  }

  @override
  String get hotelGrowAnAsTable => 'عرض كجدول';

  @override
  String get hotelGrowAnAsChart => 'عرض كمخطط';

  @override
  String get hotelGrowAnFunnelTitle => 'من المشاهدة إلى الكوبون';

  @override
  String get hotelGrowAnFunnelDesc => 'المشاهدات والنقرات والكوبونات المشتراة والطلبات والحجوزات المؤكدة والكوبونات المستخدمة خلال الفترة.';

  @override
  String get hotelGrowAnStageConfirmed => 'المؤكدة';

  @override
  String get hotelGrowAnValueLabel => 'العدد';

  @override
  String get hotelGrowAnTopTitle => 'أكثر الباقات حجزًا';

  @override
  String get hotelGrowAnTopDesc => 'الحجوزات المؤكدة لكل باقة خلال الفترة.';

  @override
  String hotelGrowAnTopOpen(String name) {
    return 'فتح $name';
  }

  @override
  String get hotelGrowAnDefsTitle => 'كيف نحسب';

  @override
  String hotelGrowAnDefViews(num minutes) {
    final intl.NumberFormat minutesNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'يُحتسب كل زائر مرة واحدة كل ⁦$minutesString⁩ دقيقة، مهما تكرر فتحه لصفحة القاعة.';
  }

  @override
  String get hotelGrowAnDefClicks => 'الضغط على مراسلة أو اتصال أو الاتجاهات أو مشاركة بعد مشاهدة صفحة القاعة.';

  @override
  String hotelGrowAnDefConversion(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    return 'الحجوزات المؤكدة مقسومة على المشاهدات في الفترة نفسها، وتُنسب إلى آخر مشاهدة خلال ⁦$daysString⁩ يومًا.';
  }

  @override
  String get hotelGrowAnCustomTitle => 'فترة محددة';

  @override
  String hotelGrowAnCustomOutside(String date) {
    return 'لا توجد بيانات قبل $date.';
  }

  @override
  String get hotelGrowAnEmptyTitle => 'لا توجد بيانات بعد';

  @override
  String hotelGrowAnInsufBody(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    return 'تحتاج الاتجاهات إلى ⁦$daysString⁩ أيام من المشاهدات على الأقل. المجاميع حتى الآن أدناه.';
  }

  @override
  String get hotelGrowAnRoleAnalytics => 'دوركم يتيح الاطلاع على أداء الصفحة فقط.';

  @override
  String get hotelGrowRwTitle => 'التقييمات';

  @override
  String get hotelGrowRwCatVenue => 'القاعة';

  @override
  String get hotelGrowRwCatFood => 'الطعام';

  @override
  String get hotelGrowRwCatService => 'الخدمة';

  @override
  String get hotelGrowRwCatValue => 'القيمة';

  @override
  String get hotelGrowRwFilterLabel => 'عرض التقييمات';

  @override
  String get hotelGrowRwFilterAll => 'الكل';

  @override
  String get hotelGrowRwFilterNeeds => 'بانتظار الرد';

  @override
  String get hotelGrowRwFilterReplied => 'تم الرد';

  @override
  String get hotelGrowRwFilterReported => 'تم الإبلاغ';

  @override
  String get hotelGrowRwModerated => 'تتولى غزل مراجعة التقييمات. رد مرة واحدة أو أبلغ عن إساءة. للإخفاء أو الحذف، اسأل الدعم.';

  @override
  String get hotelGrowRwAskSupport => 'اطلب من الدعم الإخفاء أو الحذف';

  @override
  String hotelGrowRwReplyTitle(String name) {
    return 'الرد على $name';
  }

  @override
  String get hotelGrowRwReplyHelp => 'علني، يظهر باسم القاعة، ويُرسل مرة واحدة.';

  @override
  String get hotelGrowRwReplySend => 'إرسال الرد';

  @override
  String get hotelGrowRwReplySent => 'تم نشر ردكم.';

  @override
  String get hotelGrowRwReportTitle => 'الإبلاغ عن هذا التقييم';

  @override
  String get hotelGrowRwReportBody => 'اختاروا السبب. ستراجعه غزل ويبقى التقييم ظاهرًا إلى حين المراجعة.';

  @override
  String get hotelGrowRwReasonAbuse => 'ألفاظ مسيئة';

  @override
  String get hotelGrowRwReasonOff => 'لا يخص هذه القاعة';

  @override
  String get hotelGrowRwReasonPersonal => 'يتضمن بيانات شخصية';

  @override
  String get hotelGrowRwReasonOther => 'سبب آخر';

  @override
  String get hotelGrowRwReportSend => 'إرسال البلاغ';

  @override
  String get hotelGrowRwReported => 'تم الإبلاغ. ستراجعه غزل.';

  @override
  String get hotelGrowRwEmptyTitle => 'لا توجد تقييمات بعد';

  @override
  String get hotelGrowRwNoNeedsTitle => 'تم الرد على جميع التقييمات';

  @override
  String get hotelGrowRwNoFilterTitle => 'لا يوجد شيء هنا';

  @override
  String get hotelGrowRwShowAll => 'عرض كل التقييمات';

  @override
  String get hotelGrowRwAnonymous => 'مجهول الهوية';

  @override
  String get hotelGrowRwSummaryLabel => 'التقييم العام';

  @override
  String get hotelGrowListTitle => 'أسعار الكوبون';

  @override
  String get hotelGrowNewWindow => 'نافذة سعر كوبون جديدة';

  @override
  String get hotelGrowEditorTitle => 'نافذة سعر الكوبون';

  @override
  String get hotelGrowAlwaysOn => 'يعمل دائمًا';

  @override
  String get hotelGrowStandingTitle => 'سعر الكوبون الدائم';

  @override
  String get hotelGrowStandingEditCta => 'تعديل أسعار الباقات';

  @override
  String get hotelGrowStandingExplain => 'كل باقة لها سعر كوبون تعرضه دائمًا بجانب السعر العادي. والنافذة تخفضه لتواريخ مناسبات محددة.';

  @override
  String get hotelGrowStandingNote => 'تُعدَّل الأسعار الدائمة من محرر الباقات، وليس من هنا.';

  @override
  String get hotelGrowStatRequests => 'طلبات';

  @override
  String get hotelGrowStatConfirmed => 'حجوزات مؤكدة';

  @override
  String get hotelGrowStatVouchers => 'كوبونات مشتراة';

  @override
  String get hotelGrowStatEnds => 'ينتهي';

  @override
  String get hotelGrowUnitPackage => 'للباقة';

  @override
  String get hotelGrowTitleSuggestion => 'سعر كوبون أقل';

  @override
  String get hotelGrowPriceLabel => 'سعر الكوبون لكل ضيف';

  @override
  String get hotelGrowPriceLabelFlat => 'سعر الكوبون للباقة';

  @override
  String hotelGrowNoEffect(String standing) {
    return 'هذا السعر ليس أقل من سعر الكوبون الدائم $standing، لذلك لن يغيّر ما يدفعه العملاء.';
  }

  @override
  String hotelGrowBelowFee(String fee) {
    return 'الوفر لن يزيد على رسوم الكوبون $fee، لذلك لن يُعرض الكوبون للعملاء بهذا السعر.';
  }

  @override
  String get hotelGrowRequestPrice => 'سعر الطلب';

  @override
  String get hotelGrowStandardPrice => 'السعر العادي';

  @override
  String get hotelGrowYouSave => 'وفر العميل';

  @override
  String hotelGrowFeeNote(String fee) {
    return 'يدفع العميل أيضًا لغزل رسوم كوبون $fee. وهي ليست جزءًا من سعركم ولا تحصّلونها أنتم.';
  }

  @override
  String get hotelGrowOpenWeekends => 'نهايات الأسبوع المتاحة';

  @override
  String get hotelGrowWeekdays => 'أيام الأسبوع';

  @override
  String hotelGrowOpenWeekendsBody(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    return 'تواريخ الخميس إلى السبت المفتوحة خلال ⁦$daysString⁩ يومًا القادمة';
  }

  @override
  String hotelGrowWeekdaysBody(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    return 'تواريخ الأحد إلى الأربعاء المفتوحة خلال ⁦$daysString⁩ يومًا القادمة';
  }

  @override
  String get hotelGrowUntilEnd => 'حتى أنهيها';

  @override
  String get hotelGrowEndRequired => 'اختاروا تاريخ الانتهاء أو فعّلوا خيار حتى أنهيها.';

  @override
  String get hotelGrowAnKpiVouchers => 'كوبونات مشتراة';

  @override
  String get hotelGrowAnKpiRequests => 'الطلبات';

  @override
  String get hotelGrowAnKpiRedeemed => 'كوبونات مستخدمة';

  @override
  String get hotelGrowAnDefVouchers => 'الكوبونات التي اشتُريت لقاعتكم في الفترة، وتُحتسب عند الدفع لا عند الاستخدام.';

  @override
  String get hotelGrowFactDates => 'التواريخ';

  @override
  String get hotelGrowStatEnded => 'انتهى';

  @override
  String get hotelGrowUnitGuest => 'للضيف';

  @override
  String get hotelGrowFactsLabel => 'التفاصيل';

  @override
  String get hotelGrowStandingCount => 'العروض الدائمة';

  @override
  String get hotelGrowFeeTitle => 'رسوم الكوبون';

  @override
  String get hotelGrowExampleLabel => 'مثال';

  @override
  String get hotelGrowFactGuests => 'الضيوف';

  @override
  String get hotelGrowFactDate => 'التاريخ';

  @override
  String get hotelGrowSaving => 'التوفير';

  @override
  String get hotelGrowCouplesPay => 'يدفع العروسان';

  @override
  String get hotelGrowOffline => 'غير متصل';

  @override
  String get hotelGrowRwReply => 'رد';

  @override
  String get hotelGrowAnRangeFrom => 'من';

  @override
  String get hotelGrowAnRangeTo => 'إلى';

  @override
  String get hotelGrowEffectTitle => 'الأثر';

  @override
  String get hotelGrowFactPackages => 'الباقات';

  @override
  String get hotelGrowStandingInfoTitle => 'العروض الدائمة';

  @override
  String get hotelGrowRwVerified => 'موثّق';

  @override
  String get hotelGrowRwPosted => 'نُشر';

  @override
  String get hotelGrowFactMen => 'رجال';

  @override
  String get hotelGrowFactLadies => 'نساء';

  @override
  String get hotelGrowRwYourReply => 'ردك';

  @override
  String get hotelGrowRwDraft => 'مسودة';

  @override
  String get hotelGrowRwReport => 'إبلاغ';

  @override
  String get hotelGrowStepPrice => 'السعر';

  @override
  String get hotelGrowStepDates => 'التواريخ';

  @override
  String get hotelGrowBoundsLabel => 'نطاق السعر';

  @override
  String get hotelGrowStandingPrice => 'السعر الدائم';

  @override
  String get hotelGrowNoEffectTitle => 'بلا تغيير';

  @override
  String get hotelGrowNoEffectShort => 'بلا تغيير';

  @override
  String get hotelGrowBelowFeeTitle => 'دون الرسوم';

  @override
  String hotelGrowBelowFeeShort(String fee) {
    return 'دون رسوم $fee';
  }

  @override
  String get hotelGrowPreviewTitle => 'معاينة';

  @override
  String get hotelGrowRulesTitle => 'القواعد';

  @override
  String get hotelGrowPublishFailedTitle => 'لم يُنشر';

  @override
  String get hotelGrowOverlapTitle => 'تداخل';

  @override
  String get hotelGrowLowerPrice => 'خفض السعر';

  @override
  String get hotelGrowOpenDates => 'تواريخ متاحة';

  @override
  String get hotelGrowAnApproved => 'مقبول';

  @override
  String get hotelGrowAnInsufTitle => 'بيانات غير كافية';

  @override
  String hotelGrowAnInsufShort(String days) {
    return 'يلزم $days أيام';
  }

  @override
  String get hotelGrowRwReviews => 'التقييمات';

  @override
  String get hotelGrowRwCategories => 'الفئات';

  @override
  String get hotelGrowRwMore => 'المزيد';

  @override
  String get hotelGrowRwRulesTitle => 'القواعد';

  @override
  String hotelProviderOfflineStrip(String time) {
    return 'دون اتصال · محفوظ $time';
  }

  @override
  String get hotelProviderNeedsConnection => 'دون اتصال';

  @override
  String get hotelProviderLangArabic => 'العربية';

  @override
  String get hotelProviderLangEnglish => 'الإنجليزية';

  @override
  String hotelProviderFieldInArabic(String field) {
    return '$field · عربي';
  }

  @override
  String hotelProviderFieldInEnglish(String field) {
    return '$field · إنجليزي';
  }

  @override
  String get hotelProviderPriceError => 'المبلغ بالدينار';

  @override
  String get hotelProviderListTitle => 'الإعلانات';

  @override
  String get hotelProviderListNew => 'جديد';

  @override
  String get hotelProviderListRoleReason => 'للاطلاع فقط';

  @override
  String hotelProviderListGroupAttention(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'إجراء · ⁦$countString⁩';
  }

  @override
  String hotelProviderListGroupRunning(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'منشورة · ⁦$countString⁩';
  }

  @override
  String hotelProviderListGroupEnded(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'منتهية · ⁦$countString⁩';
  }

  @override
  String hotelProviderListRejectedBanner(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '⁦$countString⁩ غير معتمدة';
  }

  @override
  String hotelProviderListExpiryBanner(String date) {
    return 'تنتهي $date';
  }

  @override
  String get hotelProviderListEmptyTitle => 'لا إعلانات بعد';

  @override
  String get hotelProviderListErrorTitle => 'تعذّر التحميل';

  @override
  String get hotelProviderListErrorBody => 'لم يتغيّر شيء. أعيدوا المحاولة.';

  @override
  String get hotelProviderStepFinish => 'إكمال';

  @override
  String get hotelProviderStepChoosePlan => 'الباقة';

  @override
  String get hotelProviderStepFix => 'تعديل';

  @override
  String get hotelProviderStepRenew => 'تجديد';

  @override
  String get hotelProviderStepSubmit => 'إرسال';

  @override
  String get hotelProviderPlanContractTitle => 'عقد تجاري';

  @override
  String get hotelProviderPlanContractBody => 'الشروط حسب العقد';

  @override
  String get hotelProviderPlanTitle => 'الباقة';

  @override
  String get hotelProviderPlanTitleRenew => 'تجديد';

  @override
  String get hotelProviderPlanEditListing => 'تعديل';

  @override
  String get hotelProviderPlanGroup => 'مدة الباقة';

  @override
  String get hotelProviderPlanInclTitle => 'تشمل';

  @override
  String get hotelProviderPlanIncl1 => 'الإعلان';

  @override
  String get hotelProviderPlanIncl2 => 'الطلبات';

  @override
  String get hotelProviderPlanIncl3 => 'الأرقام';

  @override
  String get hotelProviderPlanContinue => 'دفع';

  @override
  String get hotelProviderPlanReasonRates => 'الأسعار قريبًا';

  @override
  String get hotelProviderPlanReasonChoose => 'اختاروا باقة';

  @override
  String get hotelProviderPlanSubmittedToast => 'تم الإرسال';

  @override
  String get hotelProviderPlanSampleNote => 'مبالغ تجريبية';

  @override
  String get hotelProviderPlanPreviewSample => 'أسعار تجريبية';

  @override
  String hotelProviderPlanRenewLive(String date) {
    return 'حتى $date';
  }

  @override
  String hotelProviderPlanRenewExpired(String date) {
    return 'انتهت $date';
  }

  @override
  String get hotelProviderPlanErrorTitle => 'تعذّر التحميل';

  @override
  String get hotelProviderPlanErrorBody => 'لم يتغيّر شيء. أعيدوا المحاولة.';

  @override
  String get hotelProviderPayTitle => 'الدفع';

  @override
  String get hotelProviderPayTotal => 'إجمالي الباقة';

  @override
  String hotelProviderPayAction(String amount) {
    return 'دفع $amount';
  }

  @override
  String get hotelProviderPayWith => 'الدفع عبر';

  @override
  String get hotelProviderChangeMethod => 'تغيير';

  @override
  String get hotelProviderMethodsTitle => 'طريقة الدفع';

  @override
  String get hotelProviderMethodKnet => 'كي نت';

  @override
  String get hotelProviderMethodVisa => 'فيزا';

  @override
  String get hotelProviderMethodMastercard => 'ماستركارد';

  @override
  String get hotelProviderMethodApplePay => 'آبل باي';

  @override
  String get hotelProviderMethodGooglePay => 'جوجل باي';

  @override
  String get hotelProviderSampleBadge => 'تجريبي';

  @override
  String get hotelProviderRefundNote => 'يتولى الدعم استرداد الرسوم عند الطلب.';

  @override
  String get hotelProviderSumListing => 'الإعلان';

  @override
  String get hotelProviderSumPlan => 'الباقة';

  @override
  String get hotelProviderSumAmount => 'المبلغ';

  @override
  String get hotelProviderSumPaid => 'مدفوع';

  @override
  String hotelProviderGatewayTitle(String method) {
    return '$method';
  }

  @override
  String hotelProviderRedirectTitle(String method) {
    return 'إلى $method';
  }

  @override
  String get hotelProviderRedirectBody => 'أبقوا التطبيق مفتوحًا.';

  @override
  String get hotelProviderConfirmingTitle => 'جارٍ التأكيد';

  @override
  String get hotelProviderConfirmingBody => 'لا تدفعوا مرة أخرى.';

  @override
  String get hotelProviderBankMerchant => 'التاجر';

  @override
  String get hotelProviderBankMerchantName => 'غزل';

  @override
  String get hotelProviderBankAmount => 'المبلغ';

  @override
  String get hotelProviderBankCard => 'البطاقة';

  @override
  String get hotelProviderBankExpiry => 'الانتهاء';

  @override
  String get hotelProviderBankPin => 'الرقم السري';

  @override
  String get hotelProviderBankSubmit => 'دفع';

  @override
  String get hotelProviderProtoLabel => 'ردّ البنك';

  @override
  String get hotelProviderProtoApproved => 'موافقة';

  @override
  String get hotelProviderProtoDeclined => 'رفض';

  @override
  String get hotelProviderLeaveTitle => 'مغادرة الدفع؟';

  @override
  String get hotelProviderLeaveBody => 'لم يُخصم أي مبلغ.';

  @override
  String get hotelProviderLeaveStay => 'بقاء';

  @override
  String get hotelProviderLeaveConfirm => 'مغادرة';

  @override
  String get hotelProviderPaidTitle => 'تم الدفع';

  @override
  String get hotelProviderPaidBody => 'إعلانكم قيد المراجعة.';

  @override
  String get hotelProviderRenewedTitle => 'تم التجديد';

  @override
  String get hotelProviderRenewedBody => 'إعلانكم باقٍ منشورًا.';

  @override
  String hotelProviderRenewedNote(String date) {
    return 'حتى $date';
  }

  @override
  String get hotelProviderReceiptLink => 'الإيصال';

  @override
  String get hotelProviderViewStatus => 'الحالة';

  @override
  String get hotelProviderBackToListings => 'الإعلانات';

  @override
  String get hotelProviderFailedTitle => 'تعذّر الدفع';

  @override
  String get hotelProviderFailedBody => 'لم يُخصم أي مبلغ.';

  @override
  String get hotelProviderRetry => 'إعادة المحاولة';

  @override
  String get hotelProviderSwitchMethod => 'طريقة أخرى';

  @override
  String get hotelProviderCancelledTitle => 'أُلغي';

  @override
  String get hotelProviderCancelledBody => 'لم يُخصم أي مبلغ. اختياركم محفوظ.';

  @override
  String get hotelProviderBackToPay => 'رجوع';

  @override
  String get hotelProviderBlockedTitle => 'الأسعار قريبًا';

  @override
  String get hotelProviderBlockedBody => 'لم تُعلن الأسعار بعد، فلا شيء للدفع. إعلانكم واختياركم محفوظان.';

  @override
  String get hotelProviderBackToPlans => 'الباقات';

  @override
  String get hotelProviderOfflinePay => 'دون اتصال';

  @override
  String get hotelProviderPayErrorTitle => 'تعذّر الدفع';

  @override
  String get hotelProviderPayErrorBody => 'لم يُخصم أي مبلغ. أعيدوا المحاولة.';

  @override
  String get hotelProviderReceiptTitle => 'الإيصال';

  @override
  String get hotelProviderReceiptIssuer => 'غزل';

  @override
  String get hotelProviderReceiptNumber => 'الرقم';

  @override
  String get hotelProviderReceiptDate => 'التاريخ';

  @override
  String get hotelProviderReceiptListing => 'الإعلان';

  @override
  String get hotelProviderReceiptPlan => 'الباقة';

  @override
  String get hotelProviderReceiptVia => 'عبر';

  @override
  String get hotelProviderReceiptFoot => 'د.ك';

  @override
  String get hotelProviderReceiptSample => 'تجريبي';

  @override
  String get hotelProviderRequired => 'مطلوب';

  @override
  String get hotelProviderRetryShort => 'إعادة';

  @override
  String get hotelProviderEditorTitle => 'الإعلان';

  @override
  String get hotelProviderEditorTitleNew => 'إعلان جديد';

  @override
  String get hotelProviderEditorCategory => 'الفئة';

  @override
  String get hotelProviderEditorCategoryPlaceholder => 'اختاروا';

  @override
  String get hotelProviderEditorTexts => 'النصوص';

  @override
  String get hotelProviderEditorTitleField => 'العنوان';

  @override
  String get hotelProviderEditorDescField => 'الوصف';

  @override
  String get hotelProviderEditorPhotos => 'الصور';

  @override
  String get hotelProviderEditorPackages => 'الباقات';

  @override
  String get hotelProviderEditorContact => 'التواصل';

  @override
  String get hotelProviderEditorChat => 'المحادثة';

  @override
  String get hotelProviderEditorPhone => 'الهاتف';

  @override
  String get hotelProviderEditorContinue => 'متابعة';

  @override
  String get hotelProviderEditorSubmitChanges => 'إرسال';

  @override
  String get hotelProviderEditorResubmit => 'إعادة الإرسال';

  @override
  String get hotelProviderEditorSaveDraft => 'حفظ المسودة';

  @override
  String get hotelProviderEditorSaved => 'تم الحفظ';

  @override
  String get hotelProviderEditorSavedBanner => 'تم الحفظ';

  @override
  String get hotelProviderEditorDraftSaved => 'حُفظت المسودة';

  @override
  String get hotelProviderEditorDraftNeedsTitle => 'أضيفوا عنوانًا';

  @override
  String get hotelProviderEditorFixFields => 'أكملوا الحقول المحددة';

  @override
  String get hotelProviderEditorValidationNote => 'أكملوا الحقول المحددة';

  @override
  String get hotelProviderEditorError => 'لم يُحفظ';

  @override
  String get hotelProviderEditorLiveNote => 'النسخة المنشورة باقية';

  @override
  String hotelProviderEditorRejectedNote(String note) {
    return '$note';
  }

  @override
  String get hotelProviderGuardTitle => 'تجاهل التغييرات؟';

  @override
  String get hotelProviderGuardBody => 'ستضيع التعديلات غير المحفوظة.';

  @override
  String get hotelProviderGuardDiscard => 'تجاهل';

  @override
  String get hotelProviderGuardKeep => 'متابعة';

  @override
  String get hotelProviderPhotoAdd => 'إضافة';

  @override
  String get hotelProviderPhotoRemove => 'حذف الصورة';

  @override
  String get hotelProviderPhotoCover => 'الغلاف';

  @override
  String get hotelProviderCatsPrimary => 'الرئيسية';

  @override
  String get hotelProviderCatsMore => 'المزيد';

  @override
  String hotelProviderCatsLimit(num count, num max) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return '⁦$countString⁩/⁦$maxString⁩';
  }

  @override
  String get hotelProviderPkgUnnamed => 'بلا اسم';

  @override
  String get hotelProviderPkgAdd => 'إضافة باقة';

  @override
  String get hotelProviderPkgNeeded => 'أضيفوا باقة';

  @override
  String get hotelProviderPkgNoVoucher => 'بلا كوبون';

  @override
  String hotelProviderPkgNoVoucherFull(String fee) {
    return 'بلا كوبون. يجب أن يتجاوز التوفير $fee.';
  }

  @override
  String hotelProviderPkgSaving(String amount) {
    return 'توفير $amount';
  }

  @override
  String get hotelProviderPkgSheetNew => 'باقة جديدة';

  @override
  String get hotelProviderPkgSheetEdit => 'الباقة';

  @override
  String get hotelProviderPkgSave => 'حفظ';

  @override
  String get hotelProviderPkgDelete => 'حذف';

  @override
  String get hotelProviderPkgName => 'الاسم';

  @override
  String get hotelProviderPkgPerPackage => 'باقة';

  @override
  String get hotelProviderPkgVoucherOver => 'أقل من العادي أو يساويه';

  @override
  String get hotelProviderPkgIncludes => 'تشمل';

  @override
  String get hotelProviderPkgInclPlaceholder => 'أضيفوا عنصرًا';

  @override
  String hotelProviderPkgRemoveIncl(String name) {
    return 'حذف $name';
  }

  @override
  String get hotelProviderPreviewTitle => 'المعاينة';

  @override
  String get hotelProviderPreviewNoTitle => 'العنوان';

  @override
  String get hotelProviderPreviewNoPackage => 'أضيفوا باقة';

  @override
  String get hotelProviderReviewTitle => 'المراجعة';

  @override
  String get hotelProviderReviewErrorTitle => 'تعذّر التحميل';

  @override
  String get hotelProviderReviewErrorBody => 'لم يتغيّر شيء. أعيدوا المحاولة.';

  @override
  String get hotelProviderHeadPendingTitle => 'قيد المراجعة';

  @override
  String get hotelProviderHeadApprovedTitle => 'معتمد';

  @override
  String get hotelProviderHeadLiveTitle => 'منشور';

  @override
  String get hotelProviderHeadRevisionTitle => 'التعديل قيد المراجعة';

  @override
  String get hotelProviderHeadRejectedTitle => 'غير معتمد';

  @override
  String hotelProviderLongWait(num hours) {
    final intl.NumberFormat hoursNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    return '⁦$hoursString⁩ س في المراجعة';
  }

  @override
  String get hotelProviderContactSupport => 'الدعم';

  @override
  String get hotelProviderReasons => 'ملاحظات الفريق';

  @override
  String get hotelProviderReasonContent => 'المحتوى';

  @override
  String get hotelProviderReasonCategory => 'الفئة';

  @override
  String get hotelProviderReasonMissing => 'تفاصيل ناقصة';

  @override
  String get hotelProviderReasonPricing => 'السعر';

  @override
  String get hotelProviderReasonOther => 'أخرى';

  @override
  String get hotelProviderAppReasonVerify => 'تعذّر التحقق';

  @override
  String get hotelProviderAppDemoNote => 'أضيفوا رقم الترخيص ووصفًا أوضح للنشاط.';

  @override
  String get hotelProviderApprovalGuardTitle => 'الإعلانات بعد القبول';

  @override
  String get hotelProviderPlanRetained => 'استرداد الرسوم: اطلبوه من الدعم';

  @override
  String get hotelProviderPlanRefunded => 'سُجّل الاسترداد';

  @override
  String get hotelProviderChoosePlanAgain => 'الباقة';

  @override
  String get hotelProviderListingLabel => 'الإعلان';

  @override
  String get hotelProviderTimeline => 'السجل';

  @override
  String get hotelProviderFacts => 'التفاصيل';

  @override
  String get hotelProviderFactSubmitted => 'أُرسل';

  @override
  String get hotelProviderFactFees => 'الرسوم';

  @override
  String get hotelProviderFactNoFees => 'لا شيء';

  @override
  String get hotelProviderFactPaid => 'مدفوعة';

  @override
  String get hotelProviderFactRatesSoon => 'قريبًا';

  @override
  String get hotelProviderFactPlanEnds => 'تنتهي';

  @override
  String hotelProviderDaysLeft(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    return '⁦$daysString⁩ يوم';
  }

  @override
  String get hotelProviderEditResubmit => 'تعديل';

  @override
  String get hotelProviderViewPerformance => 'الأداء';

  @override
  String get hotelProviderProtoTitle => 'المشرف';

  @override
  String get hotelProviderProtoApprove => 'اعتماد';

  @override
  String get hotelProviderProtoReject => 'رفض';

  @override
  String get hotelProviderProtoNote => 'فئة خاطئة، سعر غير واضح.';

  @override
  String get hotelProviderPerfTitle => 'الأداء';

  @override
  String get hotelProviderPerfEdit => 'تعديل';

  @override
  String get hotelProviderPerfErrorTitle => 'تعذّر التحميل';

  @override
  String get hotelProviderPerfErrorBody => 'لم يتغيّر شيء. أعيدوا المحاولة.';

  @override
  String get hotelProviderPerfEmptyTitle => 'لا أرقام بعد';

  @override
  String hotelProviderPerfEnded(String date) {
    return 'انتهت $date';
  }

  @override
  String get hotelProviderPerfRangeLabel => 'الفترة';

  @override
  String get hotelProviderPerfRangeMonth => 'الشهر';

  @override
  String hotelProviderPerfRange30(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    return '⁦$daysString⁩ يوم';
  }

  @override
  String hotelProviderPerfRange90(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    return '⁦$daysString⁩ يوم';
  }

  @override
  String get hotelProviderPerfRangeCustom => 'مخصّصة';

  @override
  String get hotelProviderPerfViews => 'المشاهدات';

  @override
  String get hotelProviderPerfSaves => 'الحفظ';

  @override
  String get hotelProviderPerfVouchers => 'الكوبونات';

  @override
  String get hotelProviderPerfRequests => 'الطلبات';

  @override
  String get hotelProviderPerfRedeemed => 'المستخدمة';

  @override
  String get hotelProviderPerfVsPrevious => 'مقابل السابق';

  @override
  String get hotelProviderPerfFunnel => 'المسار';

  @override
  String get hotelProviderPerfFunnelDesc => 'من المشاهدة إلى الاستخدام';

  @override
  String get hotelProviderPerfCount => 'العدد';

  @override
  String hotelProviderPerfStep(String percent) {
    return '$percent';
  }

  @override
  String hotelProviderPerfInsufficient(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    return 'اختاروا ⁦$daysString⁩ أيام فأكثر';
  }

  @override
  String get hotelProviderPerfTop => 'أعلى الباقات';

  @override
  String get hotelProviderPerfTopDesc => 'حسب الطلبات';

  @override
  String get hotelProviderPerfAsTable => 'جدول';

  @override
  String get hotelProviderPerfAsChart => 'مخطط';

  @override
  String get hotelProviderPerfVenueAnalytics => 'تحليلات القاعة';

  @override
  String get hotelProviderPerfAllListings => 'كل الإعلانات';

  @override
  String get hotelProviderRangeTitle => 'الفترة';

  @override
  String get hotelProviderRangeHint => 'اختاروا التواريخ';

  @override
  String get hotelProviderRangeApply => 'تطبيق';

  @override
  String get hotelProviderContinue => 'متابعة';

  @override
  String get hotelProviderChooseTitle => 'نوع الحساب';

  @override
  String get hotelProviderChooseReason => 'اختاروا واحدًا';

  @override
  String get hotelProviderChooseChains => 'الفنادق وسلاسل القاعات تنضم عبر غزل.';

  @override
  String get hotelProviderTypeProviderTitle => 'مقدّم خدمة';

  @override
  String get hotelProviderTypeHallTitle => 'قاعة خاصة';

  @override
  String get hotelProviderProfileName => 'اسم النشاط';

  @override
  String get hotelProviderFormBarEdit => 'تعديل الطلب';

  @override
  String get hotelProviderProfileGovernorate => 'المحافظة';

  @override
  String get hotelProviderProfileCategories => 'الفئات';

  @override
  String get hotelProviderFormOther => 'فئة أخرى';

  @override
  String get hotelProviderFormOtherHelper => 'غير موجودة؟ اكتبوها هنا.';

  @override
  String get hotelProviderCatsChoose => 'اختيار';

  @override
  String get hotelProviderCatsEdit => 'تعديل';

  @override
  String get hotelProviderProfilePhone => 'الهاتف';

  @override
  String get hotelProviderFormContact => 'الشخص المسؤول';

  @override
  String get hotelProviderFormEmail => 'البريد الإلكتروني';

  @override
  String get hotelProviderFormEmailError => 'بريد غير صالح';

  @override
  String get hotelProviderFormAccountTitle => 'حسابكم';

  @override
  String get hotelProviderFormBusinessTitle => 'نشاطكم التجاري';

  @override
  String get hotelProviderAccountRepeat => 'تأكيد كلمة المرور';

  @override
  String get hotelProviderAccountEmailUsed => 'البريد مسجّل مسبقًا';

  @override
  String get hotelProviderAccountPasswordWeak => 'كلمة المرور ضعيفة';

  @override
  String get hotelProviderFormAbout => 'وصف مختصر';

  @override
  String get hotelProviderFormLicence => 'الترخيص التجاري';

  @override
  String get hotelProviderFormFix => 'أكملوا الحقول المطلوبة.';

  @override
  String hotelProviderFormResubmitNote(String note) {
    return 'لم يُعتمد الطلب: $note';
  }

  @override
  String get hotelProviderPhoneError => 'رقم غير صالح';

  @override
  String get hotelProviderSubmit => 'إرسال الطلب';

  @override
  String get hotelProviderSubmitErrorTitle => 'تعذّر الإرسال';

  @override
  String get hotelProviderSubmitError => 'لم يُرسل شيء. أعيدوا المحاولة.';

  @override
  String get hotelProviderSubmittedBar => 'الطلب';

  @override
  String get hotelProviderSubmittedTitle => 'تم استلام طلبكم';

  @override
  String get hotelProviderSubmittedLine => 'يبقى حسابكم قيد المراجعة.';

  @override
  String get hotelProviderSubmittedNext => 'الخطوات القادمة';

  @override
  String get hotelProviderNextReview => 'تراجع غزل طلبكم';

  @override
  String get hotelProviderNextEmail => 'نراسلكم بالقرار';

  @override
  String get hotelProviderNextListings => 'بعدها تضيفون الإعلانات';

  @override
  String get hotelProviderSubmittedStatus => 'حالة الطلب';

  @override
  String get hotelProviderRejectContent => 'المحتوى';

  @override
  String get hotelProviderRejectCategory => 'الفئة';

  @override
  String get hotelProviderRejectDetails => 'التفاصيل';

  @override
  String get hotelProviderRejectPricing => 'السعر';

  @override
  String get hotelProviderRejectOther => 'ملاحظة';

  @override
  String get hotelProviderPlanSampleCta => 'مبالغ تجريبية للنموذج فقط، وليست سعرًا حقيقيًا.';

  @override
  String get hotelProviderRefundTitle => 'الاسترداد';

  @override
  String get hotelProviderDetails => 'التفاصيل';

  @override
  String get hotelSettingsRoleManager => 'المدير';

  @override
  String get hotelSettingsRoleReception => 'الاستقبال';

  @override
  String get hotelSettingsRoleOwner => 'المسؤول';

  @override
  String get hotelSettingsStepUpTitle => 'تأكيد الهوية';

  @override
  String get hotelSettingsStepUpBodyStaff => 'نرسل رمزًا إلى بريدك الإلكتروني.';

  @override
  String get hotelSettingsStepUpSend => 'إرسال الرمز';

  @override
  String get hotelSettingsMoreTitle => 'المزيد';

  @override
  String get hotelSettingsMoreListing => 'إعلانكم';

  @override
  String get hotelSettingsMoreCompleteness => 'اكتمال اللغتين';

  @override
  String get hotelSettingsMoreLangAr => 'العربية';

  @override
  String get hotelSettingsMoreLangEn => 'الإنجليزية';

  @override
  String get hotelSettingsMorePreview => 'معاينة';

  @override
  String get hotelSettingsMorePreviewHeld => 'تتاح المعاينة بعد اعتماد إعلانكم.';

  @override
  String get hotelSettingsMoreGroupVenue => 'القاعة';

  @override
  String get hotelSettingsMoreGroupVisits => 'الزيارات';

  @override
  String get hotelSettingsMoreGroupGrow => 'النمو';

  @override
  String get hotelSettingsMoreGroupBusiness => 'الأعمال';

  @override
  String get hotelSettingsMoreGroupAccount => 'الحساب';

  @override
  String get hotelSettingsMoreMedia => 'الصور';

  @override
  String get hotelSettingsMorePackages => 'الباقات';

  @override
  String get hotelSettingsMoreHalls => 'القاعات';

  @override
  String get hotelSettingsMorePolicies => 'السياسات';

  @override
  String get hotelSettingsMoreRules => 'القواعد';

  @override
  String get hotelSettingsMoreAvailability => 'التوفر';

  @override
  String get hotelSettingsMoreVisitRequests => 'الطلبات';

  @override
  String get hotelSettingsMoreVisitAvailability => 'المواعيد';

  @override
  String get hotelSettingsMoreVoucherPrices => 'أسعار الكوبون';

  @override
  String get hotelSettingsMoreAnalytics => 'التحليلات';

  @override
  String get hotelSettingsMoreReviews => 'التقييمات';

  @override
  String get hotelSettingsMoreListings => 'الإعلانات';

  @override
  String get hotelSettingsMorePerformance => 'الأداء';

  @override
  String get hotelSettingsMoreNotifications => 'الإشعارات';

  @override
  String get hotelSettingsMoreStaff => 'الموظفون';

  @override
  String get hotelSettingsMoreHours => 'ساعات العمل';

  @override
  String get hotelSettingsMoreLanguage => 'اللغة';

  @override
  String get hotelSettingsMoreBiometric => 'القفل الحيوي';

  @override
  String get hotelSettingsMoreSupport => 'الدعم';

  @override
  String get hotelSettingsMoreSupportToast => 'محادثة الدعم';

  @override
  String get hotelSettingsMoreSwitch => 'تبديل القاعة';

  @override
  String get hotelSettingsMoreLogout => 'تسجيل الخروج';

  @override
  String hotelSettingsMoreVersion(String version) {
    return '$version';
  }

  @override
  String get hotelSettingsMoreTerms => 'الشروط';

  @override
  String get hotelSettingsMorePrivacy => 'الخصوصية';

  @override
  String get hotelSettingsMoreLegalToast => 'النصوص تديرها غزل';

  @override
  String get hotelSettingsMoreAccountType => 'نوع الحساب';

  @override
  String get hotelSettingsMoreBilling => 'الفوترة';

  @override
  String get hotelSettingsMoreBillingAttention => 'يحتاج إلى انتباهكم';

  @override
  String get hotelSettingsLanguageTitle => 'اللغة';

  @override
  String get hotelSettingsLanguageSaved => 'تم حفظ اللغة';

  @override
  String get hotelSettingsSwitchTitle => 'تبديل القاعة';

  @override
  String get hotelSettingsSwitchCurrent => 'القاعة الحالية';

  @override
  String get hotelSettingsLogoutTitle => 'تسجيل الخروج؟';

  @override
  String get hotelSettingsBiometricOnTitle => 'تفعيل القفل الحيوي؟';

  @override
  String get hotelSettingsBiometricOnConfirm => 'تفعيل';

  @override
  String get hotelSettingsBiometricOn => 'القفل مفعّل';

  @override
  String get hotelSettingsBiometricOff => 'القفل متوقف';

  @override
  String get hotelSettingsPreviewTitle => 'المعاينة';

  @override
  String get hotelSettingsAcctTitle => 'نوع الحساب';

  @override
  String get hotelSettingsAcctVenue => 'فندق أو قاعة';

  @override
  String get hotelSettingsAcctProvider => 'مزوّد خدمة';

  @override
  String get hotelSettingsAcctSetup => 'إضافة حساب';

  @override
  String get hotelSettingsAcctSwitchedVenue => 'فندق أو قاعة';

  @override
  String get hotelSettingsAcctSwitchedProvider => 'مزوّد خدمة';

  @override
  String get hotelSettingsNotifAboutTitle => 'عن التنبيهات';

  @override
  String get hotelSettingsNotifAboutLock => 'تنبيهات الطلبات الجديدة تعمل دائمًا لدوركم، بنغمة خاصة بها.';

  @override
  String get hotelSettingsNotifAboutQuiet => 'خارج ساعات العمل يصل التنبيه بصمت ويظهر في قائمتكم.';

  @override
  String get hotelSettingsNotifAboutChannel =>
      'تصل التنبيهات كإشعارات على الهاتف. يصل التصعيد العاجل أيضًا بالبريد الإلكتروني، ولا توجد إشعارات تسويقية.';

  @override
  String get hotelSettingsNotifPushOffTitle => 'الإشعارات متوقفة';

  @override
  String get hotelSettingsNotifPushOffBody => 'لن يصلكم تنبيه بالطلبات الجديدة قبل تشغيلها، ومهلة الرد تواصل العدّ. باقي الإعدادات تعمل كالمعتاد.';

  @override
  String get hotelSettingsNotifPushOffAction => 'فتح الإعدادات';

  @override
  String get hotelSettingsNotifPushOffToast => 'يفتح إعدادات الهاتف';

  @override
  String get hotelSettingsNotifNewRequest => 'الطلبات الجديدة';

  @override
  String get hotelSettingsNotifAlwaysOn => 'يعمل دائمًا';

  @override
  String get hotelSettingsNotifPlaySound => 'تشغيل النغمة';

  @override
  String get hotelSettingsNotifPlaying => 'جارٍ التشغيل';

  @override
  String get hotelSettingsNotifConfirmations => 'التأكيدات';

  @override
  String get hotelSettingsNotifCancelled => 'الإلغاءات';

  @override
  String get hotelSettingsNotifRedemptions => 'الكوبونات';

  @override
  String get hotelSettingsNotifVisits => 'الزيارات';

  @override
  String get hotelSettingsNotifMessages => 'الرسائل';

  @override
  String get hotelSettingsNotifReviews => 'التقييمات';

  @override
  String get hotelSettingsNotifListing => 'الإعلان';

  @override
  String get hotelSettingsNotifPlan => 'الباقة';

  @override
  String get hotelSettingsStaffInvite => 'دعوة موظف';

  @override
  String get hotelSettingsStaffYou => 'أنتم';

  @override
  String get hotelSettingsStaffSupport => 'الدعم';

  @override
  String get hotelSettingsStaffEmptyTitle => 'أنتم وحدكم';

  @override
  String get hotelSettingsStaffName => 'الاسم';

  @override
  String get hotelSettingsStaffNameError => 'أدخلوا الاسم';

  @override
  String get hotelSettingsStaffRole => 'الدور';

  @override
  String get hotelSettingsStaffAccept => 'الرد على الطلبات';

  @override
  String get hotelSettingsStaffSend => 'إرسال الدعوة';

  @override
  String get hotelSettingsStaffSent => 'أُرسلت الدعوة';

  @override
  String get hotelSettingsStaffSaveRole => 'حفظ الدور';

  @override
  String get hotelSettingsStaffSessions => 'إنهاء الجلسات';

  @override
  String get hotelSettingsStaffSessionsDone => 'تم الخروج';

  @override
  String get hotelSettingsStaffDeactivate => 'تعطيل';

  @override
  String hotelSettingsStaffDeactivated(String name) {
    return 'تعطيل $name';
  }

  @override
  String get hotelSettingsStaffReactivate => 'تفعيل';

  @override
  String hotelSettingsStaffReactivated(String name) {
    return 'تفعيل $name';
  }

  @override
  String get hotelSettingsStaffRemove => 'إزالة';

  @override
  String hotelSettingsStaffRemoveTitle(String name) {
    return 'إزالة $name؟';
  }

  @override
  String get hotelSettingsStaffRemoveConfirm => 'إزالة';

  @override
  String hotelSettingsStaffRemoved(String name) {
    return 'أُزيل $name';
  }

  @override
  String get hotelSettingsStaffResend => 'إعادة الإرسال';

  @override
  String get hotelSettingsStaffResent => 'أُعيد الإرسال';

  @override
  String hotelSettingsStaffOpen(String name) {
    return 'تعديل $name';
  }

  @override
  String get hotelSettingsStaffLastSeen => 'آخر ظهور';

  @override
  String get hotelSettingsStaffExpires => 'تنتهي الدعوة';

  @override
  String get hotelSettingsStaffStateDeactivated => 'معطّل';

  @override
  String get hotelSettingsStaffAboutTitle => 'عن الأدوار';

  @override
  String get hotelSettingsStaffVisitNote => 'من يدير الزيارات يستطيع قراءة محادثات الزيارة الجماعية، وفيها أيضًا دعم غزل.';

  @override
  String get hotelSettingsStaffFoot => 'لا يمكن إسناد دور المسؤول من التطبيق. فريق الدعم في غزل يتولى نقل الملكية.';

  @override
  String get hotelSettingsRoleLineManager => 'كل شيء بما فيه استخدام الكوبونات والزيارات والقوائم والفوترة، عدا الموظفين';

  @override
  String get hotelSettingsRoleLineReception => 'الطلبات واستخدام الكوبونات والزيارات والمحادثات';

  @override
  String get hotelSettingsRoleLineAccountant => 'الفوترة والإيصالات، وعرض الطلبات للقراءة فقط';

  @override
  String get hotelSettingsRoleLineMarketing => 'أسعار الكوبون والقوائم والتحليلات والصور';

  @override
  String get hotelSettingsHoursAboutTitle => 'عن الساعات';

  @override
  String get hotelSettingsHoursAbout => 'يراها الأزواج كساعات عمل، وتحدد متى يصدر صوت تنبيه الطلبات الجديدة.';

  @override
  String get hotelSettingsHoursApproxNote => 'رمضان والعيدان تقديريان إلى حين الإعلان، عدّلوهما عند صدوره.';

  @override
  String get hotelSettingsHoursPreview => 'يظهر للأزواج هكذا';

  @override
  String hotelSettingsHoursLine(String days, String from, String to) {
    return '$days $from–$to';
  }

  @override
  String hotelSettingsHoursLineClosed(String days) {
    return '$days مغلق';
  }

  @override
  String hotelSettingsHoursDaysRange(String first, String last) {
    return '$first–$last';
  }

  @override
  String hotelSettingsHoursDaysPair(String first, String last) {
    return '$first و$last';
  }

  @override
  String get hotelSettingsHoursEveryDay => 'كل يوم';

  @override
  String get hotelSettingsHoursAllClosed => 'مغلق';

  @override
  String get hotelSettingsHoursWeek => 'ساعات الأسبوع';

  @override
  String get hotelSettingsHoursTimeFrom => 'الفتح';

  @override
  String get hotelSettingsHoursTimeTo => 'الإغلاق';

  @override
  String get hotelSettingsHoursHour => 'الساعة';

  @override
  String get hotelSettingsHoursMinute => 'الدقائق';

  @override
  String get hotelSettingsHoursAm => 'ص';

  @override
  String get hotelSettingsHoursPm => 'م';

  @override
  String get hotelSettingsHoursSetTime => 'تأكيد';

  @override
  String get hotelSettingsHoursClosures => 'الإغلاقات';

  @override
  String get hotelSettingsHoursClosure => 'إغلاق';

  @override
  String hotelSettingsHoursClosureRange(String from, String to) {
    return '$from–$to';
  }

  @override
  String get hotelSettingsHoursApprox => 'تقريبي';

  @override
  String get hotelSettingsHoursSuggested => 'مقترحة';

  @override
  String get hotelSettingsHoursAddClosure => 'إضافة إغلاق';

  @override
  String get hotelSettingsHoursAddTitle => 'إضافة إغلاق';

  @override
  String get hotelSettingsHoursAddLabel => 'الاسم';

  @override
  String get hotelSettingsHoursAddConfirm => 'إضافة';

  @override
  String hotelSettingsHoursRemoveClosure(String label) {
    return 'إزالة الإغلاق $label';
  }

  @override
  String get hotelSettingsHoursSave => 'حفظ';

  @override
  String get hotelSettingsHoursGuardTitle => 'المغادرة بدون حفظ؟';

  @override
  String get hotelSettingsHoursGuardLeave => 'مغادرة';

  @override
  String get hotelSettingsHoursGuardStay => 'البقاء';

  @override
  String get hotelSettingsHoursViewOnly => 'للعرض فقط';

  @override
  String get hotelSettingsHoursInvalid => 'الوقتان متطابقان';

  @override
  String get hotelSettingsHoursCopy => 'كل الأيام';

  @override
  String get hotelSettingsHoursNextDay => 'اليوم التالي';

  @override
  String hotelSettingsHoursOpenOn(String day) {
    return 'مفتوح يوم $day';
  }

  @override
  String get hotelSettingsHoursClosedWord => 'مغلق';

  @override
  String get hotelSettingsBillExempt => 'فندق رئيسي · بلا رسوم إدراج';

  @override
  String get hotelSettingsBillExemptBody => 'تخضع قوائمكم للمراجعة قبل النشر.';

  @override
  String get hotelSettingsBillEnds => 'تنتهي الباقة';

  @override
  String get hotelSettingsBillEnded => 'انتهت الباقة';

  @override
  String get hotelSettingsBillDaysLeft => 'الأيام المتبقية';

  @override
  String get hotelSettingsBillDaysUnit => 'ي';

  @override
  String get hotelSettingsBillHidden => 'مخفية';

  @override
  String get hotelSettingsBillNone => 'لا باقة';

  @override
  String get hotelSettingsBillNoneBody => 'اختاروا باقة أسبوعية أو شهرية أو سنوية للإعلان. لا يُنشر شيء قبل أن تراجعه غزل.';

  @override
  String get hotelSettingsBillRatesBody => 'يمكنكم اختيار الباقة الآن، ويُفتح الدفع عند الإعلان عن الأسعار.';

  @override
  String get hotelSettingsBillStatusLabel => 'حالة الباقة';

  @override
  String get hotelSettingsBillPillActive => 'سارية';

  @override
  String get hotelSettingsBillPillExpiring => 'تنتهي قريبًا';

  @override
  String get hotelSettingsBillExpiringNote => 'نذكّركم قبل أسبوع ومرة أخرى قبل يوم. جدّدوا لتبقى قائمتكم منشورة.';

  @override
  String get hotelSettingsBillExpiredNote => 'قائمتكم مخفية. جدّدوا الباقة لإعادتها، وتعود إلى المراجعة قبل أن تُنشر من جديد.';

  @override
  String get hotelSettingsBillPlanRow => 'الباقات';

  @override
  String get hotelSettingsBillRenew => 'تجديد';

  @override
  String get hotelSettingsBillChoose => 'اختيار باقة';

  @override
  String get hotelSettingsBillSeePlans => 'عرض الباقات';

  @override
  String get hotelSettingsBillReceipts => 'الإيصالات';

  @override
  String get hotelSettingsBillDirectNote =>
      'يدفع الأزواج لكم مباشرة مقابل المناسبة. لا تستلم غزل أي مبالغ عن المناسبات ولا تخصم منها ولا تحوّلها، ولذلك هذه هي الشاشة الوحيدة للفوترة.';

  @override
  String get hotelSettingsBillViewOnly => 'للعرض فقط';

  @override
  String get hotelSettingsBillDownload => 'تنزيل PDF';

  @override
  String get hotelSettingsBillDownloaded => 'تم حفظ الإيصال';

  @override
  String get hotelSettingsBillMethodKnet => 'كي نت';

  @override
  String get hotelSettingsBillMethodCard => 'بطاقة';

  @override
  String get hotelSettingsBillMethodApplePay => 'آبل باي';

  @override
  String get hotelSettingsBillMethodGooglePay => 'جوجل باي';

  @override
  String get hotelSettingsStaffEmail => 'البريد الإلكتروني';

  @override
  String get hotelSettingsStaffEmailError => 'أدخل بريدًا صحيحًا';

  @override
  String get hotelSettingsBillContractBody => 'شروطك كما تم التعاقد عليها مع غزل. لا توجد باقة معلنة.';

  @override
  String get hotelShellTabBarLabel => 'التنقل الرئيسي';

  @override
  String get hotelShellTabToday => 'اليوم';

  @override
  String get hotelShellTabBookings => 'الحجوزات';

  @override
  String get hotelShellTabCalendar => 'التقويم';

  @override
  String get hotelShellTabMessages => 'الرسائل';

  @override
  String get hotelShellTabMore => 'المزيد';

  @override
  String hotelShellBadgePending(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ طلب بانتظار ردكم',
      many: '⁦$countString⁩ طلبًا بانتظار ردكم',
      few: '⁦$countString⁩ طلبات بانتظار ردكم',
      two: 'طلبان بانتظار ردكم',
      one: 'طلب واحد بانتظار ردكم',
      zero: 'لا طلبات بانتظار ردكم',
    );
    return '$_temp0';
  }

  @override
  String hotelShellBadgeOverflow(num max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return '⁦$maxString⁩+';
  }

  @override
  String get hotelShellBannerNewRequest => 'طلب حجز جديد';

  @override
  String hotelShellGreeting(String name) {
    return 'أهلًا وسهلًا، $name';
  }

  @override
  String hotelShellTodayNeedsReply(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ طلب بانتظار ردكم',
      many: '⁦$countString⁩ طلبًا بانتظار ردكم',
      few: '⁦$countString⁩ طلبات بانتظار ردكم',
      two: 'طلبان بانتظار ردكم',
      one: 'طلب واحد بانتظار ردكم',
      zero: 'لا طلبات بانتظار ردكم',
    );
    return '$_temp0';
  }

  @override
  String hotelShellTodayFirstIn(String time) {
    return 'أقربها خلال $time';
  }

  @override
  String get hotelShellTodayAllClear => 'لا شيء بانتظار ردكم';

  @override
  String get hotelShellNeedsYouTitle => 'بحاجة إلى اهتمامكم';

  @override
  String get hotelShellOfflineBanner => 'لا يوجد اتصال بالإنترنت. يتم عرض آخر ما تم تحميله.';

  @override
  String get hotelTodayBell => 'الإشعارات';

  @override
  String hotelTodayBellUnread(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ إشعار غير مقروء',
      many: '⁦$countString⁩ إشعارًا غير مقروء',
      few: '⁦$countString⁩ إشعارات غير مقروءة',
      two: 'إشعاران غير مقروءين',
      one: 'إشعار واحد غير مقروء',
      zero: 'لا شيء غير مقروء',
    );
    return 'الإشعارات، $_temp0';
  }

  @override
  String hotelTodaySwitchVenue(String venue) {
    return 'تبديل الفندق، الحالية $venue';
  }

  @override
  String hotelTodayStatusFirst(String time) {
    return 'المهلة الأقرب خلال $time';
  }

  @override
  String hotelTodayStatusNeeds(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ طلب بانتظار ردكم',
      many: '⁦$countString⁩ طلبًا بانتظار ردكم',
      few: '⁦$countString⁩ طلبات بانتظار ردكم',
      two: 'طلبان بانتظار ردكم',
      one: 'طلب واحد بانتظار ردكم',
      zero: 'لا شيء بانتظار ردكم',
    );
    return '$_temp0';
  }

  @override
  String get hotelTodayAllClear => 'لا شيء معلق';

  @override
  String hotelTodayStatusMarketing(int windows, String views) {
    final intl.NumberFormat windowsNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String windowsString = windowsNumberFormat.format(windows);

    String _temp0 = intl.Intl.pluralLogic(
      windows,
      locale: localeName,
      other: '⁦$windowsString⁩ سعر كوبون فعّال',
      many: '⁦$windowsString⁩ سعر كوبون فعّال',
      few: '⁦$windowsString⁩ أسعار كوبون فعّالة',
      two: 'سعرا كوبون فعّالان',
      one: 'سعر كوبون فعّال واحد',
      zero: 'لا أسعار كوبون فعّالة',
    );
    return '$_temp0 · $views مشاهدة خلال أسبوع';
  }

  @override
  String get hotelTodayNeedsYouTitle => 'بانتظاركم';

  @override
  String hotelTodaySeeAllCount(String count) {
    return 'عرض الكل ($count)';
  }

  @override
  String hotelTodayWindowEnds(String time) {
    return 'تنتهي مهلة الرد خلال $time';
  }

  @override
  String hotelTodayWaitingLong(String time) {
    return 'بانتظار الرد منذ $time';
  }

  @override
  String get hotelTodayBlockDate => 'إغلاق تاريخ';

  @override
  String get hotelTodayEventsTitle => 'الفعاليات';

  @override
  String get hotelTodayDayView => 'عرض اليوم';

  @override
  String get hotelTodayAudienceWomen => 'الحفل النسائي';

  @override
  String get hotelTodayAudienceMen => 'الحفل الرجالي';

  @override
  String get hotelTodayAudienceMixed => 'حفل مختلط';

  @override
  String hotelTodayStartsIn(String time) {
    return 'يبدأ خلال $time';
  }

  @override
  String get hotelTodayStripLabel => 'التوفر خلال الأيام السبعة القادمة';

  @override
  String get hotelTodayCalendar => 'التقويم';

  @override
  String hotelTodaySoftDates(int count, String days) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ تاريخ متاح في نهاية الأسبوع خلال $days يومًا',
      many: '⁦$countString⁩ تاريخًا متاحًا في نهاية الأسبوع خلال $days يومًا',
      few: '⁦$countString⁩ تواريخ متاحة في نهاية الأسبوع خلال $days يومًا',
      two: 'تاريخان متاحان في نهاية الأسبوع خلال $days يومًا',
      one: 'تاريخ متاح في نهاية الأسبوع خلال $days يومًا',
      zero: 'لا تواريخ متاحة في نهاية الأسبوع خلال $days يومًا',
    );
    return '$_temp0';
  }

  @override
  String get hotelTodayOpenDates => 'تواريخ متاحة خلال الثلاثين يومًا القادمة';

  @override
  String get hotelTodayGlanceTitle => 'التحليلات';

  @override
  String get hotelTodayAnalytics => 'التحليلات';

  @override
  String get hotelTodayViews7 => 'المشاهدات خلال آخر سبعة أيام';

  @override
  String get hotelTodayVsPrevious => 'مقارنة بالأيام السبعة السابقة';

  @override
  String get hotelTodayViewsTrend => 'المشاهدات يوميًا خلال آخر سبعة أيام';

  @override
  String get hotelTodayMessagesTitle => 'الرسائل';

  @override
  String get hotelTodayUnread => 'غير مقروء';

  @override
  String hotelTodayUnreadCount(int count) {
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
  String get hotelTodayYou => 'أنتم';

  @override
  String get hotelTodayPinned => 'مثبتة';

  @override
  String get hotelTodayEnquiry => 'استفسار';

  @override
  String get hotelTodayPreviewVoice => 'رسالة صوتية';

  @override
  String get hotelTodayPreviewPhoto => 'صورة';

  @override
  String get hotelTodayPreviewDocument => 'مستند';

  @override
  String hotelTodayOfflineStamp(String time) {
    return 'غير متصل · آخر تحديث $time';
  }

  @override
  String get hotelTodayOfflineReason => 'غير متصل. يلزم الاتصال بالإنترنت للقبول.';

  @override
  String get hotelTodaySwitchSister => 'فندق لومي مارينا';

  @override
  String get hotelTodayAcceptedToast => 'تمت الموافقة';

  @override
  String get hotelTodayFirstRunNotifTitle => 'السماح بالإشعارات';

  @override
  String get hotelTodayFirstRunNotifBody => 'للطلبات الجديدة مهلة رد محدودة. عند تفعيل الإشعارات يصلكم تنبيه فوري، حتى والتطبيق مغلق.';

  @override
  String get hotelTodayFirstRunNotifPointTime => 'تنبيهات عاجلة';

  @override
  String get hotelTodayFirstRunNotifPointSound => 'نغمة خاصة';

  @override
  String get hotelTodayFirstRunNotifAllow => 'السماح';

  @override
  String get hotelTodayFirstRunNotNow => 'ليس الآن';

  @override
  String get hotelTodayFirstRunLockTitle => 'قفل التطبيق';

  @override
  String get hotelTodayFirstRunLockBody => 'لحماية الطلبات والكوبونات والزيارات إذا فُقد الجهاز أو استخدمه غيركم. يمكن تفعيله لاحقًا من «المزيد».';

  @override
  String get hotelTodayFirstRunLockOn => 'تفعيل';

  @override
  String get hotelTodaySwitchTitle => 'تبديل الفندق';

  @override
  String hotelTodaySwitchPending(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ طلب بانتظار الرد',
      many: '⁦$countString⁩ طلبًا بانتظار الرد',
      few: '⁦$countString⁩ طلبات بانتظار الرد',
      two: 'طلبان بانتظار الرد',
      one: 'طلب واحد بانتظار الرد',
      zero: 'لا طلبات',
    );
    return '$_temp0';
  }

  @override
  String get hotelTodaySwitchCurrent => 'القاعة الحالية';

  @override
  String get hotelTodayRoleManager => 'المدير';

  @override
  String get hotelTodayRoleReception => 'الاستقبال';

  @override
  String hotelTodayDurDays(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ يوم',
      many: '⁦$countString⁩ يومًا',
      few: '⁦$countString⁩ أيام',
      two: 'يومين',
      one: 'يوم واحد',
      zero: 'لا أيام',
    );
    return '$_temp0';
  }

  @override
  String hotelTodayDurHours(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ ساعة',
      many: '⁦$countString⁩ ساعة',
      few: '⁦$countString⁩ ساعات',
      two: 'ساعتين',
      one: 'ساعة واحدة',
      zero: 'لا ساعات',
    );
    return '$_temp0';
  }

  @override
  String hotelTodayDurMinutes(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ دقيقة',
      many: '⁦$countString⁩ دقيقة',
      few: '⁦$countString⁩ دقائق',
      two: 'دقيقتين',
      one: 'دقيقة واحدة',
      zero: 'لا دقائق',
    );
    return '$_temp0';
  }

  @override
  String hotelTodayDurJoin(String first, String second) {
    return '$first و$second';
  }

  @override
  String get hotelTodayNeedsTitle => 'بانتظاركم';

  @override
  String get hotelTodayFiltersLabel => 'تصفية القائمة';

  @override
  String get hotelTodayFilterAll => 'الكل';

  @override
  String get hotelTodayFilterRequests => 'الطلبات';

  @override
  String get hotelTodayFilterMessages => 'الرسائل';

  @override
  String get hotelTodayFilterReviews => 'التقييمات';

  @override
  String get hotelTodayFilterCalendar => 'التقويم';

  @override
  String get hotelTodayNotifFilter => 'عرض الإشعارات';

  @override
  String get hotelTodayMarkAllRead => 'تعليم الكل كمقروء';

  @override
  String get hotelTodayPrefs => 'تفضيلات الإشعارات';

  @override
  String get hotelTodayNotifEmptyTitle => 'لا إشعارات';

  @override
  String get hotelTodayNotifUnreadEmptyTitle => 'الكل مقروء';

  @override
  String get hotelTodayNotifShowAll => 'عرض الكل';

  @override
  String get hotelTodayPushDeniedTitle => 'الإشعارات متوقفة';

  @override
  String get hotelTodayOpenSettings => 'الإعدادات';

  @override
  String get hotelTodayPushDeniedToast => 'فعّلوها من الإعدادات';

  @override
  String get hotelTodayAllRead => 'الكل مقروء';

  @override
  String get hotelTodayInboxTitle => 'الرسائل';

  @override
  String get hotelTodayInboxSearch => 'الاسم أو المرجع';

  @override
  String get hotelTodayInboxSearchLabel => 'البحث في المحادثات';

  @override
  String get hotelTodayInboxFilters => 'تصفية المحادثات';

  @override
  String get hotelTodayInboxUnread => 'غير المقروءة';

  @override
  String get hotelTodayInboxNeedsReply => 'بانتظار الرد';

  @override
  String get hotelTodayInboxLinked => 'مرتبطة';

  @override
  String get hotelTodayInboxEnquiries => 'استفسارات';

  @override
  String get hotelTodayInboxEmptyTitle => 'لا رسائل';

  @override
  String get hotelTodayInboxNoResultsTitle => 'لا نتائج';

  @override
  String get hotelTodayClearSearch => 'مسح';

  @override
  String get hotelTodayInboxSupportOnly => 'الاستقبال يتولى العملاء';

  @override
  String get hotelTodayMarkRead => 'تعليم كمقروءة';

  @override
  String get hotelTodayMarkUnread => 'تعليم كغير مقروءة';

  @override
  String get hotelTodayConversationMenu => 'الخيارات';

  @override
  String hotelTodayHandledBy(String name) {
    return 'المتابعة: $name';
  }

  @override
  String hotelTodayCallClient(String name) {
    return 'اتصال بالعميل $name';
  }

  @override
  String get hotelTodayReport => 'إبلاغ';

  @override
  String get hotelTodayReportSent => 'تم إرسال البلاغ';

  @override
  String hotelTodayContextLine(String audience, String date, String guests) {
    return '$audience · $date · $guests';
  }

  @override
  String hotelTodayOpenBooking(String summary) {
    return 'فتح الطلب، $summary';
  }

  @override
  String get hotelTodayComposerLabel => 'الرسالة';

  @override
  String get hotelTodayComposerPlaceholder => 'رسالة';

  @override
  String get hotelTodayAttach => 'إرفاق';

  @override
  String get hotelTodayAttachTitle => 'إرفاق';

  @override
  String get hotelTodayAttachCamera => 'الكاميرا';

  @override
  String get hotelTodayAttachPhoto => 'الصور';

  @override
  String get hotelTodayAttachDocument => 'مستند';

  @override
  String get hotelTodayRecordHold => 'اضغطوا للتسجيل';

  @override
  String get hotelTodayRecording => 'جارٍ التسجيل';

  @override
  String get hotelTodaySlideCancel => 'اسحبوا للإلغاء';

  @override
  String get hotelTodaySlideLock => 'اسحبوا للأعلى للتثبيت';

  @override
  String get hotelTodayRecordingLocked => 'تم تثبيت التسجيل';

  @override
  String get hotelTodayRecordDelete => 'حذف التسجيل';

  @override
  String get hotelTodayRecordSend => 'إرسال التسجيل';

  @override
  String get hotelTodayQuickLabel => 'ردود سريعة';

  @override
  String get hotelTodayQrAvailability => 'التوفر';

  @override
  String get hotelTodayQrPrice => 'السعر';

  @override
  String get hotelTodayQrVisit => 'زيارة';

  @override
  String get hotelTodayQrAddress => 'العنوان';

  @override
  String hotelTodayQrAvailabilityText(String date) {
    return 'هلا فيكم. التاريخ $date متاح لدينا ويسعدنا استقبالكم.';
  }

  @override
  String hotelTodayQrPriceText(String guests, String total, String standard) {
    return 'بكوبون غزل يصبح إجمالي $guests هو $total بدل $standard، ويتم السداد لنا مباشرة بعد تأكيدكم.';
  }

  @override
  String get hotelTodayQrVisitText => 'يسعدنا استقبالكم لزيارة القاعة. يمكنكم حجز موعد الزيارة من صفحتنا في تطبيق غزل واختيار اليوم المناسب.';

  @override
  String hotelTodayQrAddressText(String venue, String area) {
    return 'موقعنا: $venue، $area.';
  }

  @override
  String get hotelTodayMsgSending => 'جارٍ الإرسال';

  @override
  String get hotelTodayMsgQueued => 'بانتظار الاتصال';

  @override
  String get hotelTodayMsgFailed => 'لم تُرسل';

  @override
  String get hotelTodayDraftTag => 'مسودة';

  @override
  String get hotelTodayThreadEmptyTitle => 'لا رسائل';

  @override
  String get hotelTodayAllPrices => 'كل أسعار الكوبون';

  @override
  String get hotelTodayAwaitingClient => 'بانتظار تأكيد العميل';

  @override
  String get hotelTodayBillingTitle => 'الفوترة';

  @override
  String hotelTodayConfirmWindowEnds(String time) {
    return 'تنتهي مهلة تأكيد العميل خلال $time';
  }

  @override
  String get hotelTodayFilterListing => 'الإعلان';

  @override
  String get hotelTodayFilterVisits => 'الزيارات';

  @override
  String get hotelTodayInboxVisits => 'الزيارات';

  @override
  String get hotelTodayNewPrice => 'سعر جديد';

  @override
  String get hotelTodayNtfListingApproved => 'تمت الموافقة على الإعلان';

  @override
  String get hotelTodayNtfListingRejected => 'لم تتم الموافقة على الإعلان';

  @override
  String get hotelTodayNtfListingSubmitted => 'تم إرسال الإعلان للمراجعة';

  @override
  String get hotelTodayNtfNewRequest => 'طلب جديد';

  @override
  String get hotelTodayNtfRedeemed => 'تم استخدام الكوبون لديكم';

  @override
  String get hotelTodayPricesTitle => 'أسعار الكوبون';

  @override
  String get hotelTodayRedeem => 'استخدام';

  @override
  String get hotelTodayRequestsMonth => 'طلبات هذا الشهر';

  @override
  String get hotelTodayStatusExempt => 'فندق رئيسي · بلا رسوم إدراج';

  @override
  String get hotelTodayStatusListing => 'هناك إعلان بانتظار اهتمامكم';

  @override
  String get hotelTodayStatusNoPlan => 'لا توجد باقة إدراج فعّالة';

  @override
  String hotelTodayStatusPlan(String date) {
    return 'تنتهي باقة الإدراج $date';
  }

  @override
  String hotelTodayStatusVisits(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ طلب زيارة بانتظار ردكم',
      many: '⁦$countString⁩ طلب زيارة بانتظار ردكم',
      few: '⁦$countString⁩ طلبات زيارة بانتظار ردكم',
      two: 'طلبا زيارة بانتظار ردكم',
      one: 'طلب زيارة واحد بانتظار ردكم',
      zero: 'لا طلبات زيارة بانتظار ردكم',
    );
    return '$_temp0';
  }

  @override
  String get hotelTodayTilesTitle => 'هذا الشهر';

  @override
  String get hotelTodayVisitMembers => 'أعضاء المحادثة: العميل وممثل الفندق ودعم غزل';

  @override
  String get hotelTodayVoucherMonthTitle => 'الكوبونات';

  @override
  String get hotelTodayVouchersRedeemed => 'كوبونات تم استخدامها';

  @override
  String get hotelTodayFirstRunFaceId => 'بصمة الوجه';

  @override
  String get hotelTodayFirstRunFingerprint => 'بصمة الإصبع';

  @override
  String get hotelTodayRoleAccountant => 'المحاسب';

  @override
  String get hotelTodayRoleMarketing => 'التسويق';

  @override
  String get hotelTodayReadOnly => 'للاطلاع فقط';

  @override
  String get hotelTodayRedeemName => 'استخدام الكوبون';

  @override
  String get hotelTodayBlockName => 'إغلاق تاريخ';

  @override
  String get hotelTodayNewPriceName => 'سعر كوبون جديد';

  @override
  String get hotelTodayRedeemedName => 'كوبونات تم استخدامها';

  @override
  String get hotelTodayReviewLabel => 'الإعلان قيد المراجعة';

  @override
  String get hotelTodayNoPlan => 'بلا باقة';

  @override
  String get hotelTodayFactDate => 'التاريخ';

  @override
  String get hotelTodayFactGuests => 'الضيوف';

  @override
  String get hotelTodayFactHall => 'القاعة';

  @override
  String get hotelTodayFactTime => 'الوقت';

  @override
  String get hotelTodayFactRating => 'التقييم';

  @override
  String get hotelTodayFactVisitors => 'الزوار';

  @override
  String get hotelTodayFactVoucherPrice => 'سعر الكوبون';

  @override
  String get hotelTodayFactReplyBy => 'الرد قبل';

  @override
  String get hotelTodayFactEnds => 'ينتهي';

  @override
  String get hotelTodayKindRequest => 'طلب';

  @override
  String get hotelTodayKindAwaiting => 'بانتظار العميل';

  @override
  String get hotelTodayKindVisit => 'طلب زيارة';

  @override
  String get hotelTodayKindMessage => 'رسالة';

  @override
  String get hotelTodayKindReview => 'تقييم';

  @override
  String get hotelTodayKindCalendar => 'تأكيد التقويم';

  @override
  String get hotelTodayKindListing => 'إعلان';

  @override
  String get hotelTodayKindPrice => 'سعر كوبون ينتهي';

  @override
  String get hotelTodayCalendarCheck => 'التقويم';

  @override
  String hotelTodayListingEndsIn(String time) {
    return 'تنتهي الباقة خلال $time';
  }

  @override
  String hotelTodayWindowEndsIn(String time) {
    return 'ينتهي السعر خلال $time';
  }

  @override
  String get hotelTodayListings => 'الإعلانات';

  @override
  String get hotelTodayNextLabel => 'الفعالية التالية';

  @override
  String get hotelTodayVouchersBought => 'كوبونات تم شراؤها';

  @override
  String get hotelTodayVouchersTrend => 'الكوبونات المشتراة يوميًا';

  @override
  String get hotelVenueLangBoth => 'عربي · إنجليزي';

  @override
  String hotelVenueLangArMissing(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'عربي ⁦$countString⁩';
  }

  @override
  String hotelVenueLangEnMissing(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'إنجليزي ⁦$countString⁩';
  }

  @override
  String get hotelVenueDashboardTitle => 'لوحة التحكم';

  @override
  String get hotelVenueDashboardCta => 'لوحة التحكم';

  @override
  String get hotelVenueDashboardLead => 'تُعدَّل من لوحة التحكم. الحجوزات القائمة تبقى بشروطها.';

  @override
  String get hotelVenueDashboardItemSeason => 'جداول أسعار المواسم';

  @override
  String get hotelVenueDashboardItemHoliday => 'أسعار العطل والمناسبات';

  @override
  String get hotelVenueDashboardItemSpecial => 'أسعار تاريخ محدد';

  @override
  String get hotelVenueDashboardItemMenus => 'القوائم ومستوياتها';

  @override
  String get hotelVenueDashboardItemService => 'رسوم الخدمة';

  @override
  String get hotelVenueGuardTitle => 'تجاهل التغييرات؟';

  @override
  String get hotelVenueGuardBody => 'لديكم تعديلات غير محفوظة. إذا غادرتم الآن فستُفقد.';

  @override
  String get hotelVenueGuardDiscard => 'تجاهل';

  @override
  String get hotelVenueGuardKeep => 'متابعة التعديل';

  @override
  String hotelVenueOfflineStrip(String time) {
    return 'دون اتصال · $time';
  }

  @override
  String get hotelVenueNeedsConnection => 'يحتاج إلى اتصال.';

  @override
  String get hotelVenueRequired => 'مطلوب';

  @override
  String get hotelVenueErrorTitle => 'تعذّر التحميل';

  @override
  String get hotelVenueErrorBody => 'لم يتغير شيء. تحقق من الاتصال وأعد المحاولة.';

  @override
  String hotelVenueFieldInArabic(String field) {
    return '$field (عربي)';
  }

  @override
  String hotelVenueFieldInEnglish(String field) {
    return '$field (إنجليزي)';
  }

  @override
  String get hotelVenuePriceError => 'مبلغ غير صالح';

  @override
  String get hotelVenueZoneHall => 'القاعة';

  @override
  String get hotelVenueZoneStage => 'المنصة والكوشة';

  @override
  String get hotelVenueZoneBridal => 'جناح العروس';

  @override
  String get hotelVenueZoneBuffet => 'البوفيه';

  @override
  String get hotelVenueZoneOutdoors => 'الخارج';

  @override
  String get hotelVenueZoneEntrance => 'المدخل والفاليه';

  @override
  String get hotelVenueZoneLayouts => 'التصاميم';

  @override
  String get hotelVenueZoneStageShort => 'المنصة';

  @override
  String get hotelVenueZoneBridalShort => 'الجناح';

  @override
  String get hotelVenueZoneEntranceShort => 'المدخل';

  @override
  String get hotelVenueZoneFilter => 'تصفية الصور حسب الموقع';

  @override
  String hotelVenueZoneAll(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'الكل ⁦$countString⁩';
  }

  @override
  String hotelVenueZoneCount(String zone, num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$zone ⁦$countString⁩';
  }

  @override
  String get hotelVenueMediaTitle => 'الصور والفيديو';

  @override
  String get hotelVenueMediaTabs => 'الصور أو الفيديو';

  @override
  String hotelVenueMediaTabPhotos(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'صور ⁦$countString⁩';
  }

  @override
  String hotelVenueMediaTabVideos(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'فيديو ⁦$countString⁩';
  }

  @override
  String get hotelVenueMediaEmptyTitle => 'لا صور';

  @override
  String get hotelVenueAddPhotosCta => 'إضافة صور';

  @override
  String get hotelVenueAddVideoCta => 'إضافة فيديو';

  @override
  String get hotelVenueAddPhotoTitle => 'إضافة صورة';

  @override
  String get hotelVenueAddVideoTitle => 'إضافة فيديو';

  @override
  String get hotelVenuePhotoSheetTitle => 'الصورة';

  @override
  String get hotelVenueVideoSheetTitle => 'الفيديو';

  @override
  String hotelVenuePhotoCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '⁦$countString⁩';
  }

  @override
  String get hotelVenueReorder => 'إعادة الترتيب';

  @override
  String get hotelVenueReorderDone => 'تم';

  @override
  String get hotelVenueReorderHint => 'استخدم الأسهم';

  @override
  String get hotelVenueShowAll => 'عرض الكل';

  @override
  String get hotelVenueEmptyRoomOnly => 'قاعات فارغة فقط';

  @override
  String hotelVenueAttentionRejected(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '⁦$countString⁩ للاستبدال';
  }

  @override
  String get hotelVenueStatusReview => 'مراجعة';

  @override
  String get hotelVenueStatusRejected => 'للاستبدال';

  @override
  String get hotelVenueStatusLive => 'منشورة';

  @override
  String get hotelVenueReviewNote => 'تظهر لك فقط';

  @override
  String hotelVenueUploading(String percent) {
    return 'جارٍ الرفع · $percent';
  }

  @override
  String get hotelVenueUploadingLabel => 'تقدم الرفع';

  @override
  String get hotelVenueUploadFailed => 'فشل الرفع';

  @override
  String get hotelVenueUploadQueued => 'بالانتظار';

  @override
  String get hotelVenueUploadRetry => 'إعادة المحاولة';

  @override
  String get hotelVenueOfflineQueueNote => 'دون اتصال. الرفع ينتظر.';

  @override
  String hotelVenueVideoOpen(String name) {
    return 'فتح $name';
  }

  @override
  String hotelVenueVideoLimits(num size) {
    final intl.NumberFormat sizeNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String sizeString = sizeNumberFormat.format(size);

    return 'حتى ⁦$sizeString⁩ م.ب';
  }

  @override
  String get hotelVenueVideoTooLarge => 'الملف كبير';

  @override
  String hotelVenueVideoTooLargeBody(num size) {
    final intl.NumberFormat sizeNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String sizeString = sizeNumberFormat.format(size);

    return 'الحد ⁦$sizeString⁩ م.ب';
  }

  @override
  String get hotelVenueVideoEmptyTitle => 'لا فيديو';

  @override
  String get hotelVenueVideoNote => 'تُشغَّل بالنقر';

  @override
  String get hotelVenueVideoDelete => 'حذف الفيديو';

  @override
  String get hotelVenueVideoDeleteTitle => 'حذف هذا الفيديو؟';

  @override
  String get hotelVenueVideoDeleteBody => 'يُزال من القائمة.';

  @override
  String get hotelVenueNewVideoTitle => 'فيديو جولة جديد';

  @override
  String get hotelVenueToastVideoDeleted => 'تم حذف الفيديو';

  @override
  String get hotelVenueToastVideoAdded => 'أُضيف الفيديو';

  @override
  String get hotelVenueCover => 'الغلاف';

  @override
  String get hotelVenueSetCover => 'تعيين كصورة غلاف';

  @override
  String get hotelVenueEditPhoto => 'تعديل التفاصيل';

  @override
  String get hotelVenueDeletePhoto => 'حذف الصورة';

  @override
  String get hotelVenueDeleteTitle => 'حذف هذه الصورة؟';

  @override
  String get hotelVenueDeleteBody => 'تُزال من القائمة.';

  @override
  String get hotelVenueDeleteConfirm => 'حذف';

  @override
  String get hotelVenueDeleteKeep => 'إبقاء';

  @override
  String get hotelVenueReplace => 'استبدال الصورة';

  @override
  String get hotelVenueReplaceTitle => 'استبدال الصورة';

  @override
  String get hotelVenueReasonPerson => 'يظهر شخص';

  @override
  String get hotelVenueReplaceShort => 'استبدال';

  @override
  String get hotelVenueReasonPersonBody => 'استخدم صورة قاعة فارغة.';

  @override
  String get hotelVenueFieldZone => 'الموقع في القاعة';

  @override
  String get hotelVenueFieldAlt => 'النص البديل';

  @override
  String get hotelVenueAltHelper => 'لقارئ الشاشة';

  @override
  String get hotelVenueAltBothFirst => 'أضف اللغتين';

  @override
  String get hotelVenueUploadZoneFirst => 'اختيار المنطقة';

  @override
  String get hotelVenueToastCover => 'تم تحديث صورة الغلاف';

  @override
  String get hotelVenueToastDeleted => 'تم حذف الصورة';

  @override
  String get hotelVenueToastPhotoSaved => 'تم حفظ بيانات الصورة';

  @override
  String get hotelVenueSourceCamera => 'الكاميرا';

  @override
  String get hotelVenueSourceLibrary => 'المعرض';

  @override
  String get hotelVenueSourceVideo => 'تحديد فيديو';

  @override
  String get hotelVenueUploadCta => 'رفع الصورة';

  @override
  String get hotelVenueFaceTitle => 'يظهر شخص';

  @override
  String get hotelVenueFaceBody => 'أعد التصوير أو اقتص الصورة.';

  @override
  String get hotelVenueFaceRetake => 'إعادة التصوير';

  @override
  String get hotelVenueFaceCrop => 'اقتطاع';

  @override
  String get hotelVenueFaceFirst => 'إعادة التصوير أو الاقتصاص أولًا';

  @override
  String get hotelVenueToastUploadStarted => 'بدأ الرفع';

  @override
  String get hotelVenueToastQueued => 'في الانتظار';

  @override
  String get hotelVenueToastPhotoAdded => 'أُضيفت الصورة';

  @override
  String get hotelVenueToastReplaced => 'تم الاستبدال';

  @override
  String hotelVenueChipReview(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'قيد المراجعة ⁦$countString⁩';
  }

  @override
  String get hotelVenueUploadDemoPhoto => 'صورة جديدة';

  @override
  String get hotelVenueSave => 'حفظ التغييرات';

  @override
  String get hotelVenueSavedState => 'تم الحفظ';

  @override
  String get hotelVenueFieldName => 'الاسم';

  @override
  String get hotelVenueFieldDescription => 'الوصف';

  @override
  String get hotelVenueNameRequired => 'الاسم باللغتين';

  @override
  String get hotelVenueReservedName => 'اسم محجوز';

  @override
  String get hotelVenueAudWomen => 'نسائي';

  @override
  String get hotelVenueAudMen => 'رجالي';

  @override
  String get hotelVenueAudMixed => 'مختلط';

  @override
  String hotelVenueGuestRange(String from, String to) {
    return '$from–$to';
  }

  @override
  String get hotelVenueAllDays => 'كل الأيام';

  @override
  String get hotelVenueHidden => 'مخفية';

  @override
  String get hotelVenueOfflineChange => 'التعديل يحتاج إلى اتصال.';

  @override
  String get hotelVenuePackagesTitle => 'الباقات';

  @override
  String get hotelVenuePkgNew => 'باقة جديدة';

  @override
  String get hotelVenuePkgEmptyTitle => 'لا باقات';

  @override
  String hotelVenuePkgActiveLabel(String name) {
    return 'إظهار $name للعملاء';
  }

  @override
  String hotelVenueToastPkgHidden(String name) {
    return 'أُخفيت $name';
  }

  @override
  String hotelVenueToastPkgShown(String name) {
    return 'ظهرت $name';
  }

  @override
  String hotelVenueArchivedHead(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'المؤرشفة (⁦$countString⁩)';
  }

  @override
  String get hotelVenueRestore => 'استعادة';

  @override
  String hotelVenueToastRestored(String name) {
    return 'استُعيدت $name';
  }

  @override
  String hotelVenueToastArchived(String name) {
    return 'أُرشفت $name';
  }

  @override
  String hotelVenueEditPackage(String name) {
    return 'تعديل $name';
  }

  @override
  String get hotelVenueNeedPrice => 'أدخل السعر';

  @override
  String get hotelVenuePkgEditTitle => 'تعديل الباقة';

  @override
  String get hotelVenueSecName => 'الاسم';

  @override
  String get hotelVenueSecAudience => 'الفئة';

  @override
  String get hotelVenueSecPricing => 'التسعير';

  @override
  String get hotelVenueSecGuests => 'عدد الضيوف';

  @override
  String get hotelVenueSecInclusions => 'تشمل';

  @override
  String get hotelVenueSecPreview => 'المعاينة';

  @override
  String get hotelVenueSecStatus => 'الحالة';

  @override
  String get hotelVenueAudienceLabel => 'الجمهور';

  @override
  String get hotelVenueAudienceNeeded => 'اختيار الفئة';

  @override
  String get hotelVenueHallsLabel => 'القاعات';

  @override
  String get hotelVenueHallsNeeded => 'اختيار قاعة';

  @override
  String get hotelVenueBasisLabel => 'أساس التسعير';

  @override
  String get hotelVenueBasisFlat => 'مبلغ ثابت';

  @override
  String get hotelVenueBasisFlatPlus => 'ثابت + ضيف';

  @override
  String hotelVenueDaysWeekday(String from, String to) {
    return 'أيام الأسبوع · من $from إلى $to';
  }

  @override
  String hotelVenueDaysWeekend(String from, String to) {
    return 'نهاية الأسبوع · من $from إلى $to';
  }

  @override
  String hotelVenueDaysSwitch(String days) {
    return 'تقديم الباقة في $days';
  }

  @override
  String get hotelVenueBundleNote => 'من باقتين';

  @override
  String get hotelVenueTierNeeded => 'تفعيل أيام';

  @override
  String get hotelVenueGuestsMin => 'أقل عدد';

  @override
  String get hotelVenueGuestsMax => 'أكثر عدد';

  @override
  String get hotelVenueMaxBelowMin => 'الأكثر دون الأقل';

  @override
  String hotelVenueMaxOverHall(String max) {
    return 'فوق سعة القاعة ($max)';
  }

  @override
  String get hotelVenueInclusionAdd => 'إضافة بند';

  @override
  String hotelVenueInclusionRemove(String name) {
    return 'إزالة $name';
  }

  @override
  String get hotelVenueInclusionSheetTitle => 'إضافة';

  @override
  String get hotelVenueInclusionPick => 'المرافق';

  @override
  String get hotelVenueInclusionOwn => 'من عندك';

  @override
  String get hotelVenueInclusionOwnLabel => 'البند';

  @override
  String get hotelVenueInclusionBoth => 'باللغتين';

  @override
  String get hotelVenueActiveTitle => 'ظاهرة';

  @override
  String get hotelVenueArchive => 'أرشفة';

  @override
  String get hotelVenueArchiveTitle => 'أرشفة؟';

  @override
  String get hotelVenueArchiveBody => 'تُخفى عن العملاء ويمكن استعادتها.';

  @override
  String get hotelVenueArchiveConfirm => 'أرشفة';

  @override
  String get hotelVenuePvDate => 'تاريخ وضيوف';

  @override
  String get hotelVenuePvGuests => 'ضيوف فقط';

  @override
  String get hotelVenuePvNone => 'بدونهما';

  @override
  String get hotelVenuePvOff => 'غير متاحة';

  @override
  String get hotelVenuePvNoName => 'الاسم';

  @override
  String get hotelVenueToastPkgSaved => 'تم الحفظ';

  @override
  String get hotelVenueToastPkgCreated => 'تمت الإضافة';

  @override
  String get hotelVenueReasonPrices => 'أدخل الأسعار';

  @override
  String get hotelVenueReasonGuests => 'صحّح الأعداد';

  @override
  String get hotelVenueSettingIndoor => 'داخلي';

  @override
  String get hotelVenueSettingOutdoor => 'في الهواء الطلق';

  @override
  String get hotelVenueSettingMixed => 'كلاهما';

  @override
  String get hotelVenueNone => 'لا يوجد';

  @override
  String get hotelVenueHallsTitle => 'القاعات';

  @override
  String get hotelVenueHallEditTitle => 'تعديل القاعة';

  @override
  String get hotelVenueSecCapacity => 'السعة';

  @override
  String get hotelVenueSecHallAudience => 'الفئة';

  @override
  String get hotelVenueSecSessions => 'الجلسات';

  @override
  String get hotelVenueSecFacilities => 'المرافق';

  @override
  String get hotelVenueSecSections => 'حسب القسم';

  @override
  String get hotelVenueCapMax => 'أكثر عدد';

  @override
  String hotelVenueCapMin(String audience) {
    return 'أقل · $audience';
  }

  @override
  String get hotelVenueMinAboveMax => 'الأقل فوق الأكثر';

  @override
  String get hotelVenueAudAtLeastOne => 'اختيار الفئة';

  @override
  String get hotelVenueSettingLabel => 'نوع القاعة';

  @override
  String get hotelVenueAudienceAllowed => 'الجمهور المسموح';

  @override
  String get hotelVenueExclusiveTitle => 'اليوم كاملًا';

  @override
  String get hotelVenueSessionAdd => 'إضافة فترة';

  @override
  String hotelVenueSessionLine(String from, String to) {
    return 'من $from إلى $to';
  }

  @override
  String get hotelVenueSessionNeeded => 'أضف فترة';

  @override
  String get hotelVenueSessionEditTitle => 'تعديل الجلسة';

  @override
  String get hotelVenueSessionNewTitle => 'جلسة جديدة';

  @override
  String get hotelVenueSessionName => 'الاسم';

  @override
  String get hotelVenueSessionStart => 'البداية';

  @override
  String get hotelVenueSessionEnd => 'النهاية';

  @override
  String get hotelVenueSessionSetup => 'التجهيز';

  @override
  String get hotelVenueSessionTeardown => 'الفك';

  @override
  String get hotelVenueSessionDelete => 'حذف';

  @override
  String get hotelVenueSessionAfterMidnight => 'بعد منتصف الليل';

  @override
  String get hotelVenueSessionNameNeeded => 'الاسم باللغتين';

  @override
  String get hotelVenuePresetsLabel => 'ابدأوا من نموذج جاهز';

  @override
  String get hotelVenuePresetAfternoon => 'بعد الظهر';

  @override
  String get hotelVenuePresetEvening => 'المساء';

  @override
  String get hotelVenuePresetFull => 'اليوم الكامل';

  @override
  String get hotelVenueAmIncluded => 'مشمول';

  @override
  String get hotelVenueAmExtra => 'بتكلفة إضافية';

  @override
  String get hotelVenueAmNone => 'غير متوفر';

  @override
  String hotelVenueAmenityOf(String name, String audience) {
    return '$name · $audience';
  }

  @override
  String hotelVenueAmenityChoose(String name) {
    return 'اختاروا حالة $name';
  }

  @override
  String get hotelVenueSectionWomen => 'النساء';

  @override
  String get hotelVenueSectionMen => 'الرجال';

  @override
  String get hotelVenueSectionMixed => 'مختلط';

  @override
  String get hotelVenueFactPhoto => 'التصوير';

  @override
  String get hotelVenueFactMusic => 'الموسيقى';

  @override
  String get hotelVenuePhotoFemale => 'نساء فقط';

  @override
  String get hotelVenuePhotoAllowed => 'مسموح';

  @override
  String get hotelVenuePhotoNone => 'غير مسموح';

  @override
  String get hotelVenueMusicDj => 'دي جي';

  @override
  String get hotelVenueMusicLive => 'حيّة';

  @override
  String get hotelVenueMusicDuff => 'دف';

  @override
  String get hotelVenueMusicNone => 'بدون موسيقى';

  @override
  String get hotelVenueLinkRules => 'قواعد الحجز';

  @override
  String get hotelVenueToastHallSaved => 'تم الحفظ';

  @override
  String get hotelVenuePolTitle => 'السياسات';

  @override
  String get hotelVenueSecChildren => 'الأولاد';

  @override
  String get hotelVenueSecDress => 'اللباس';

  @override
  String get hotelVenueChildrenNoLimit => 'بلا حد';

  @override
  String get hotelVenueChildrenLimit => 'بحد';

  @override
  String get hotelVenueChildrenAge => 'أكبر سن';

  @override
  String hotelVenueYears(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ سنة',
      many: '⁦$countString⁩ سنة',
      few: '⁦$countString⁩ سنوات',
      two: 'سنتان',
      one: 'سنة',
      zero: '⁦$countString⁩ سنة',
    );
    return '$_temp0';
  }

  @override
  String get hotelVenueDressLabel => 'اللباس';

  @override
  String get hotelVenueDressNeeded => 'الزي باللغتين';

  @override
  String get hotelVenueToastPolicySaved => 'تم الحفظ';

  @override
  String get hotelVenueRulesTitle => 'قواعد الحجز';

  @override
  String get hotelVenueRulesHall => 'القاعة';

  @override
  String get hotelVenueSecMode => 'النمط';

  @override
  String get hotelVenueSecResponse => 'الرد';

  @override
  String get hotelVenueModeRequest => 'طلب حجز';

  @override
  String get hotelVenueRespondLabel => 'الرد خلال';

  @override
  String get hotelVenueRespondWarn => 'قد ينخفض معدل الرد';

  @override
  String get hotelVenueNoticeDays => 'الإشعار المسبق';

  @override
  String get hotelVenueLinkCalendar => 'التقويم';

  @override
  String get hotelVenueToastRulesSaved => 'تم الحفظ';

  @override
  String get hotelVenueWindowsRow => 'فترات الكوبون';

  @override
  String get hotelVenueReasonVoucher => 'الكوبون فوق العادي';

  @override
  String get hotelVenueStdFlat => 'ثابت';

  @override
  String get hotelVenueStdPerGuest => 'للضيف';

  @override
  String get hotelVenueVchFlat => 'ثابت';

  @override
  String get hotelVenueVchPerGuest => 'للضيف';

  @override
  String get hotelVenueVoucherAboveFlat => 'فوق العادي';

  @override
  String get hotelVenueVoucherAboveGuest => 'فوق العادي';

  @override
  String hotelVenueVchBelowFee(String fee) {
    return 'التوفير دون $fee';
  }

  @override
  String hotelVenueVchSaving(String amount) {
    return 'يوفّر $amount';
  }

  @override
  String hotelVenuePvStandard(String standard) {
    return 'عادي $standard';
  }

  @override
  String get hotelVenueNoVoucherTag => 'بلا سعر كوبون';

  @override
  String hotelVenueHoursRun(String from, String to) {
    return 'من $from إلى $to';
  }

  @override
  String hotelVenueHoursLine(String from, String to) {
    return 'من $from إلى $to';
  }

  @override
  String get hotelVenueHoursOpen => 'الافتتاح';

  @override
  String get hotelVenueHoursClose => 'الإغلاق';

  @override
  String get hotelVenueHoursTitle => 'الدوام';

  @override
  String get hotelVenueSecHours => 'الدوام';

  @override
  String get hotelVenueSecTerms => 'الشروط';

  @override
  String get hotelVenueTermsLabel => 'الشروط';

  @override
  String get hotelVenueTermsNeeded => 'الشروط باللغتين';

  @override
  String get hotelVenueVoucherTermsTitle => 'شروط الكوبون';

  @override
  String get hotelVenueVtFee => 'الرسم';

  @override
  String get hotelVenueVtValidity => 'الصلاحية';

  @override
  String get hotelVenueVtConfirm => 'التأكيد';

  @override
  String get hotelVenueVtRedeem => 'في القاعة';

  @override
  String get hotelVenueVtRedeemValue => 'الرمز';

  @override
  String get hotelVenueSecConfirm => 'الإشعار';

  @override
  String get hotelVenueConfirmLabel => 'التأكيد';

  @override
  String hotelVenueConfirmFixed(String hours) {
    return '$hours';
  }

  @override
  String get hotelVenueNoticeShort => 'الإشعار أقصر من مدة الرد';

  @override
  String get hotelVenueLinkVoucher => 'أسعار الكوبون';

  @override
  String get hotelVenueLinkVisits => 'الزيارات';

  @override
  String get hotelVenueTlRequest => 'الطلب';

  @override
  String hotelVenueTlReply(String hours) {
    return 'الرد $hours';
  }

  @override
  String hotelVenueTlConfirm(String hours) {
    return 'التأكيد $hours';
  }

  @override
  String get hotelVenueTlPay => 'الدفع للقاعة';

  @override
  String hotelVenueTlPayText(String voucher, String standard) {
    return '$voucher · $standard';
  }

  @override
  String get hotelVenueSecProfile => 'الملف';

  @override
  String get hotelVenueTypeLabel => 'نوع المكان';

  @override
  String get hotelVenueTypePending => 'قيد المراجعة';

  @override
  String get hotelVenueToastTypeSent => 'أُرسل';

  @override
  String get hotelVenueSecHalls => 'القاعات';

  @override
  String get hotelVenueStd => 'عادي';

  @override
  String get hotelVenueVch => 'كوبون';

  @override
  String get hotelVisitsActorHotel => 'الفندق';

  @override
  String get hotelVisitsActorSupport => 'دعم غزل';

  @override
  String get hotelVisitsActorSystem => 'غزل';

  @override
  String get hotelVisitsArrivalTitle => 'الوصول';

  @override
  String get hotelVisitsArrivalError => 'لم يُحفظ';

  @override
  String get hotelVisitsDemoJump => 'عرض تجريبي: الانتقال إلى يوم الزيارة';

  @override
  String hotelVisitsArrivedDoneTitle(String name) {
    return 'وصل $name';
  }

  @override
  String get hotelVisitsMarkArrived => 'تأكيد الوصول';

  @override
  String get hotelVisitsDidNotArrive => 'لم يحضر';

  @override
  String get hotelVisitsMissedCta => 'لم يحضر';

  @override
  String get hotelVisitsMissedDialogTitle => 'تسجيل عدم الحضور؟';

  @override
  String get hotelVisitsMissedDialogBody => 'يُبلَّغ دعم غزل.';

  @override
  String hotelVisitsMissedDoneTitle(String name) {
    return 'لم يحضر $name';
  }

  @override
  String hotelVisitsMissedFrom(String time) {
    return 'من $time';
  }

  @override
  String hotelVisitsOnTheWayTitle(String name) {
    return '$name في الطريق';
  }

  @override
  String hotelVisitsOnTheWayBody(String time) {
    return '$time';
  }

  @override
  String get hotelVisitsSlotEndedTitle => 'انتهى الموعد';

  @override
  String hotelVisitsSlotEndedBody(String name) {
    return '$name';
  }

  @override
  String get hotelVisitsAttachTitle => 'إرفاق';

  @override
  String get hotelVisitsAttachCamera => 'الكاميرا';

  @override
  String get hotelVisitsAttachPhoto => 'الصور';

  @override
  String get hotelVisitsAttachDocument => 'مستند';

  @override
  String get hotelVisitsAvailTitle => 'ساعات الزيارة';

  @override
  String get hotelVisitsAvailabilityAction => 'ساعات الزيارة';

  @override
  String get hotelVisitsAvailErrorTitle => 'تعذّر التحميل';

  @override
  String get hotelVisitsAvailHiddenTitle => 'للمدير فقط';

  @override
  String get hotelVisitsAvailHiddenBody => 'اسأل المدير.';

  @override
  String get hotelVisitsMasterTitle => 'استقبال الزيارات';

  @override
  String get hotelVisitsOffTitle => 'الزيارات متوقفة';

  @override
  String get hotelVisitsOffBody => 'مخفية عن صفحتك';

  @override
  String get hotelVisitsSecDays => 'الأيام';

  @override
  String get hotelVisitsDayNoVisits => 'متوقف';

  @override
  String get hotelVisitsDayFrom => 'من';

  @override
  String get hotelVisitsDayTo => 'إلى';

  @override
  String hotelVisitsDayOpenLabel(String day) {
    return 'زيارات يوم $day';
  }

  @override
  String hotelVisitsDayPick(String what, String time) {
    return '$what الساعة $time';
  }

  @override
  String get hotelVisitsDayErrorOrder => 'النهاية بعد البداية';

  @override
  String get hotelVisitsDayErrorBounds => 'ضمن ساعات العمل';

  @override
  String get hotelVisitsSeeBusinessHours => 'ساعات العمل';

  @override
  String get hotelVisitsTimeFrom => 'من';

  @override
  String get hotelVisitsTimeTo => 'إلى';

  @override
  String get hotelVisitsTimeSet => 'تعيين';

  @override
  String get hotelVisitsSecSlot => 'المدة';

  @override
  String hotelVisitsSlotChip(String minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get hotelVisitsSecRepDefault => 'المسؤول الافتراضي';

  @override
  String get hotelVisitsRepNone => 'لا أحد';

  @override
  String get hotelVisitsSecBlackouts => 'أيام الإيقاف';

  @override
  String get hotelVisitsBlackoutsAdd => 'إضافة';

  @override
  String get hotelVisitsBlackoutTitle => 'أيام الإيقاف';

  @override
  String get hotelVisitsBlackoutNeed => 'تحديد يوم';

  @override
  String get hotelVisitsBlackoutAdd => 'إضافة';

  @override
  String hotelVisitsBlackoutRange(String from, String to) {
    return 'من $from إلى $to';
  }

  @override
  String hotelVisitsBlackoutRemove(String range) {
    return 'حذف إغلاق $range';
  }

  @override
  String get hotelVisitsSave => 'حفظ';

  @override
  String get hotelVisitsSaveClean => 'لا تغييرات';

  @override
  String get hotelVisitsSaveInvalid => 'صحّح الأيام';

  @override
  String get hotelVisitsSaveOfflineToast => 'غير متصل';

  @override
  String get hotelVisitsSaved => 'تم الحفظ';

  @override
  String get hotelVisitsSavedBanner => 'تم الحفظ';

  @override
  String get hotelVisitsGuardTitle => 'المغادرة دون حفظ؟';

  @override
  String get hotelVisitsGuardBody => 'ستضيع التغييرات.';

  @override
  String get hotelVisitsGuardLeave => 'مغادرة';

  @override
  String get hotelVisitsGuardStay => 'البقاء';

  @override
  String get hotelVisitsChatTitle => 'محادثة الزيارة';

  @override
  String get hotelVisitsChatErrorTitle => 'تعذّر تحميل المحادثة';

  @override
  String hotelVisitsChatOfflineBanner(String time) {
    return 'غير متصل. آخر تحديث $time';
  }

  @override
  String get hotelVisitsChatReadOnlyRole => 'للقراءة فقط';

  @override
  String get hotelVisitsChatClosedAfter => 'أُغلقت المحادثة';

  @override
  String get hotelVisitsChatClosedCancelled => 'أُلغيت الزيارة';

  @override
  String get hotelVisitsChatClosedDeclined => 'رُفضت الزيارة';

  @override
  String get hotelVisitsMsgFailed => 'لم تُرسل';

  @override
  String get hotelVisitsMsgQueued => 'في الانتظار';

  @override
  String get hotelVisitsMsgSending => 'جارٍ الإرسال';

  @override
  String get hotelVisitsRecordHold => 'اضغط للتسجيل';

  @override
  String get hotelVisitsQrConfirm => 'تأكيد الزيارة';

  @override
  String get hotelVisitsQrConfirmText => 'تم تأكيد الزيارة. بانتظاركم.';

  @override
  String get hotelVisitsQrEntrance => 'المدخل الرئيسي';

  @override
  String get hotelVisitsQrEntranceText => 'الدخول من البوابة الرئيسية.';

  @override
  String get hotelVisitsQrParking => 'الموقف';

  @override
  String get hotelVisitsQrParkingText => 'المواقف في الواجهة.';

  @override
  String hotelVisitsLineConfirmed(String when) {
    return 'تم التأكيد: $when';
  }

  @override
  String hotelVisitsLineReschedule(String name, String when) {
    return '$name اقترح $when';
  }

  @override
  String hotelVisitsLineArrived(String name) {
    return 'أهلًا $name';
  }

  @override
  String get hotelVisitsLineCompleted => 'اكتملت الزيارة';

  @override
  String get hotelVisitsLineDeclined => 'رُفضت الزيارة';

  @override
  String get hotelVisitsLineCancelled => 'أُلغيت الزيارة';

  @override
  String get hotelVisitsLineMissed => 'لم يحضر العميل';

  @override
  String get hotelVisitsLineClosed => 'أُغلقت المحادثة';

  @override
  String get hotelVisitsMembersTitle => 'الأعضاء';

  @override
  String get hotelVisitsRepTitle => 'المسؤول';

  @override
  String get hotelVisitsQueueTitle => 'الزيارات';

  @override
  String get hotelVisitsSegments => 'الزيارات حسب الحالة';

  @override
  String get hotelVisitsSegRequested => 'الطلبات';

  @override
  String get hotelVisitsSegUpcoming => 'القادمة';

  @override
  String get hotelVisitsSegPast => 'السابقة';

  @override
  String hotelVisitsRequestedAgo(String ago) {
    return '$ago';
  }

  @override
  String hotelVisitsOpenVisit(String name, String when) {
    return 'فتح زيارة $name، $when';
  }

  @override
  String get hotelVisitsEmptyRequestedTitle => 'لا طلبات';

  @override
  String get hotelVisitsEmptyRequestedBody => 'يمكن للعملاء حجز زيارة من صفحة مكانكم.';

  @override
  String get hotelVisitsEmptyUpcomingTitle => 'لا زيارات قادمة';

  @override
  String get hotelVisitsEmptyUpcomingBody => 'تظهر هنا الزيارات المؤكدة مع محادثاتها.';

  @override
  String get hotelVisitsEmptyPastTitle => 'لا زيارات سابقة';

  @override
  String get hotelVisitsEmptyPastBody => 'تُحفظ هنا الزيارات المكتملة والمرفوضة وتلك التي لم يحضرها أصحابها.';

  @override
  String get hotelVisitsSeeUpcoming => 'القادمة';

  @override
  String get hotelVisitsErrorTitle => 'تعذّر التحميل';

  @override
  String get hotelVisitsErrorBody => 'أعد المحاولة';

  @override
  String hotelVisitsOfflineBanner(String time) {
    return 'غير متصل. حُفظ $time';
  }

  @override
  String get hotelVisitsOfflineBannerShort => 'غير متصل';

  @override
  String get hotelVisitsOfflineReason => 'غير متصل';

  @override
  String get hotelVisitsReadOnlyNote => 'للقراءة فقط';

  @override
  String get hotelVisitsNoAccessTitle => 'لا صلاحية';

  @override
  String get hotelVisitsNoAccessBody => 'اسأل المدير';

  @override
  String get hotelVisitsConfirm => 'تأكيد';

  @override
  String get hotelVisitsPropose => 'وقت آخر';

  @override
  String get hotelVisitsOpenChat => 'فتح المحادثة';

  @override
  String get hotelVisitsComplete => 'إنهاء';

  @override
  String get hotelVisitsCorrectMissed => 'العميل حضر';

  @override
  String get hotelVisitsToastConfirmed => 'تم التأكيد';

  @override
  String get hotelVisitsToastProposed => 'أُرسل الاقتراح';

  @override
  String get hotelVisitsToastDeclined => 'تم الرفض';

  @override
  String get hotelVisitsToastAssigned => 'تم التعيين';

  @override
  String get hotelVisitsToastCompleted => 'اكتملت';

  @override
  String get hotelVisitsProposeTitle => 'وقت آخر';

  @override
  String get hotelVisitsProposeDay => 'اليوم';

  @override
  String get hotelVisitsProposeTime => 'الوقت';

  @override
  String get hotelVisitsProposeCta => 'إرسال';

  @override
  String get hotelVisitsProposeNeed => 'تحديد اليوم والوقت';

  @override
  String get hotelVisitsDeclineTitle => 'رفض';

  @override
  String get hotelVisitsDeclineReason => 'السبب';

  @override
  String get hotelVisitsReasonUnavailable => 'غير متاح في هذا الوقت';

  @override
  String get hotelVisitsReasonClosed => 'المكان مغلق';

  @override
  String get hotelVisitsReasonOther => 'سبب آخر';

  @override
  String get hotelVisitsDeclineNote => 'ملاحظة';

  @override
  String get hotelVisitsDeclineNoteRequired => 'أضف ملاحظة';

  @override
  String get hotelVisitsDeclineNeed => 'تحديد السبب';

  @override
  String get hotelVisitsDeclineCta => 'رفض';

  @override
  String hotelVisitsDetailTitle(String when) {
    return 'زيارة · $when';
  }

  @override
  String get hotelVisitsDetailErrorTitle => 'تعذّر التحميل';

  @override
  String get hotelVisitsSecClient => 'العميل';

  @override
  String get hotelVisitsSecVisit => 'الطلب';

  @override
  String get hotelVisitsFactRequested => 'أُرسل';

  @override
  String get hotelVisitsFactProposed => 'المقترح';

  @override
  String get hotelVisitsSecNote => 'ملاحظة';

  @override
  String get hotelVisitsSecRep => 'المسؤول';

  @override
  String get hotelVisitsSecChat => 'الأعضاء';

  @override
  String get hotelVisitsSecTimeline => 'سجل الزيارة';

  @override
  String hotelVisitsLimitedNote(String name) {
    return '$name فقط';
  }

  @override
  String get hotelVisitsNoteRequested => 'بانتظار ردك';

  @override
  String hotelVisitsNoteReschedule(String when) {
    return 'المقترح $when';
  }

  @override
  String get hotelVisitsNoteConfirmed => 'مؤكدة';

  @override
  String hotelVisitsNoteDayOf(String time) {
    return 'اليوم $time';
  }

  @override
  String hotelVisitsNoteArrived(String time) {
    return 'وصل $time';
  }

  @override
  String get hotelVisitsNoteCompleted => 'اكتملت';

  @override
  String get hotelVisitsNoteDeclined => 'مرفوضة';

  @override
  String hotelVisitsNoteDeclinedReason(String reason) {
    return 'مرفوضة: $reason';
  }

  @override
  String get hotelVisitsNoteCancelled => 'ملغاة';

  @override
  String get hotelVisitsNoteMissed => 'لم يحضر';

  @override
  String get hotelVisitsTlRequested => 'طُلبت';

  @override
  String get hotelVisitsTlConfirmed => 'تم التأكيد';

  @override
  String get hotelVisitsTlReschedule => 'اقتُرح موعد آخر';

  @override
  String get hotelVisitsTlArrived => 'تم الوصول';

  @override
  String get hotelVisitsTlCompleted => 'اكتملت';

  @override
  String get hotelVisitsTlDeclined => 'رُفضت';

  @override
  String get hotelVisitsTlCancelled => 'أُلغيت';

  @override
  String get hotelVisitsTlMissed => 'لم يحضر';

  @override
  String hotelVisitsVisitors(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '⁦$countString⁩ زائر',
      many: '⁦$countString⁩ زائرًا',
      few: '⁦$countString⁩ زائرين',
      two: 'زائران',
      one: 'زائر واحد',
      zero: 'لا زائرين',
    );
    return '$_temp0';
  }

  @override
  String get hotelVisitsProposeShort => 'موعد آخر';
}
