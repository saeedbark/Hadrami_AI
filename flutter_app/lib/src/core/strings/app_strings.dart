/// Centralized UI copy (mostly Arabic, some English tech labels) for
/// widget/page files, kept in one place so call sites read `AppStrings.xxx`
/// instead of inline literals and text can't drift or duplicate silently
/// across screens. Dataset/lexicon content (dictionary labels, example
/// phrases) is intentionally NOT here -- only UI chrome: titles, subtitles,
/// button labels, hints, error/empty-state messages, tooltips, snackbars.
class AppStrings {
  AppStrings._();

  // ---- Common ----
  // Literals used identically across more than one screen for the same
  // concept (app branding, generic dialog actions, a shared fallback glyph).
  static const String appName = 'قاموس حضرموت';
  static const String commonCancelLabel = 'إلغاء';
  static const String commonClearLabel = 'مسح';
  static const String commonGenericErrorMessage = 'حدث خطأ';
  static const String commonUnknownPlaceholder = '؟';
  static const String commonSettingsLabel = 'الإعدادات';
  static const String commonFavoritesLabel = 'المفضلة';

  // ---- ApiService ----
  static const String apiServiceChatTimeoutReply =
      'انتهت مهلة الانتظار. جرّب مرة أخرى.';
  static const String apiServiceChatConnectionErrorPrefix =
      'تعذّر الاتصال بالخادم. تأكد من تشغيل الـ backend على ';

  // ---- Chat Page ----
  static const String chatAppBarTitle = 'المحادثة الذكية';
  static const String chatClearConversationLabel = 'مسح المحادثة';
  static const String chatClearConfirmMessage = 'هل تريد مسح جميع الرسائل؟';
  static const String chatEmptyTitle = 'مرحباً! أنا مساعدك في اللهجة الحضرمية';
  static const String chatEmptySubtitle =
      'اسألني عن أي كلمة أو عبارة حضرمية، أو اطلب تحويل جملة إلى الفصحى';
  static const String chatSuggestionWordMeaning = 'ما معنى كلمة ويش؟';
  static const String chatSuggestionConvertPhrase =
      'حوّل إلى الفصحى: كيف حالك؟';
  static const String chatSuggestionProverbs = 'أمثال حضرمية شهيرة';
  static const String chatTypingIndicatorLabel = 'جاري الكتابة...';

  // ---- Chat Input ----
  static const String chatInputHint = 'اسأل عن اللهجة الحضرمية...';

  // ---- Dictionary Page ----
  static const String dictionaryAppBarTitle = 'القاموس الكامل';
  static const String dictionaryCloseFiltersTooltip = 'إغلاق البحث والفلاتر';
  static const String dictionaryOpenFiltersTooltip = 'بحث وفلاتر';
  static const String dictionarySearchHint = 'ابحث بالحضرمي أو الفصحى...';
  static const String dictionaryTotalWordsSuffix = 'كلمة';
  static const String dictionaryLetterChipPrefix = 'حرف ';
  static const String dictionaryNoResultsPrefix = 'لا نتائج لـ "';
  static const String dictionaryNoResultsSuffix = '"';
  static const String dictionaryNoResultsSubtitle =
      'جرّب كلمة مختلفة أو تهجئة أخرى';
  static const String dictionaryEmptyMessage = 'لا توجد كلمات';
  static const String dictionaryPosFilterHint = 'نوع الكلمة';
  static const String dictionaryTagFilterHint = 'التصنيف';
  static const String dictionaryAllLetterLabel = 'الكل';

  // ---- Word Detail Sheet ----
  static const String wordDetailFeedbackSuccessMessage = 'شكراً على مساهمتك!';
  static const String wordDetailRootPrefix = 'الجذر: ';
  static const String wordDetailCopyTooltip = 'نسخ';
  static const String wordDetailCopiedSnackbar = 'تم النسخ!';
  static const String wordDetailSynonymsLabel = 'مرادفات';
  static const String wordDetailDefinitionLabel = 'الشرح من القاموس';
  static const String wordDetailExamplesLabel = 'أمثلة';
  static const String wordDetailProverbsLabel = 'أمثال شعبية';
  static const String wordDetailNoteLabel = 'ملاحظة';
  static const String wordDetailSourcePrefix = 'المصدر: ';
  static const String wordDetailIdPrefix = 'رقم الكلمة في القاموس: ';
  static const String wordDetailSuggestCorrectionLabel = 'اقتراح تصحيح';
  static const String wordDetailFeedbackHint = 'المقابل الصحيح بالفصحى...';
  static const String wordDetailSendingLabel = 'جاري الإرسال...';
  static const String wordDetailSendLabel = 'إرسال';

  // ---- Favorites Page ----
  static const String favoritesClearAllTooltip = 'مسح الكل';
  static const String favoritesClearConfirmTitle = 'مسح المفضلة؟';
  static const String favoritesClearConfirmMessage =
      'هل تريد مسح جميع الكلمات المحفوظة؟';
  static const String favoritesEmptyMessage = 'لا توجد كلمات محفوظة';
  static const String favoritesEmptySubtitle = 'اضغط على النجمة لحفظ أي كلمة';

  // ---- Home Page ----
  static const String homeHeroTitle = 'اللهجة الحضرمية';
  static const String homeHeroSubtitle =
      'تصفح الأقسام أو اطّلع على عينات من الكلمات والعبارات';
  static const String homeBrowseDictionaryLabel = 'تصفح القاموس الكامل';
  static const String homeStatsSectionTitle = 'إحصائيات المعجم';
  static const String homeStatsSectionSubtitle =
      'عدد المدخلات في القاموس، والكلمات المكتملة (ذات مقابل فصيح)، ونسبة الاكتمال';
  static const String homeStatsLoadingSubtitle = 'جاري تحميل أرقام القاموس…';
  static const String homeStatsErrorSubtitle = 'تعذّر الاتصال بالخادم';
  static const String homeWordsPhrasesSectionTitle = 'كلمات وعبارات';
  static const String homeWordsPhrasesSectionSubtitle =
      'عبارات شائعة من اللهجة، وعيّنة مباشرة من أول مدخلات المعجم';
  static const String homeSectionsSectionTitle = 'أقسام القاموس';
  static const String homeSectionsSectionSubtitle =
      'تصفّح حسب أول حرف من الكلمة — يظهر عدد الكلمات في كل قسم';
  static const String homeSectionsErrorMessage = 'تعذّر تحميل أقسام القاموس.';
  static const String homeRandomWordSectionTitle = 'كلمة اليوم';
  static const String homeRandomWordSectionSubtitle =
      'اقتراح عشوائي من قاموس حضرموت — اضغط البطاقة للتفاصيل';
  static const String homeSectionTilePrefix = 'قسم ';
  static const String homeSectionWordCountSingular = 'كلمة';
  static const String homeSectionWordCountPlural = 'كلمات';
  static const String homeStatWordsLabel = 'كلمة';
  static const String homeStatCompletedLabel = 'مكتملة';
  static const String homeStatCompletionLabel = 'الاكتمال';
  static const String homeStatProverbsLabel = 'مثل شعبي';
  static const String homeStatPosLabel = 'أصناف نحوية';
  static const String homeStatTagsLabel = 'تصنيفات';

  // ---- Home Provider ----
  static const String homeProviderStatsErrorMessage =
      'تعذّر الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت أو إعادة المحاولة لاحقًا.';

  // ---- Landing Page ----
  static const String landingNavHomeLabel = 'الرئيسية';
  static const String landingNavDictionaryLabel = 'القاموس';
  static const String landingNavChatLabel = 'محادثة';
  static const String landingThemeToggleTooltip = 'تبديل المظهر';

  // ---- Settings Page ----
  static const String settingsThemeSectionLabel = 'المظهر';
  static const String settingsThemeLightLabel = 'فاتح';
  static const String settingsThemeDarkLabel = 'داكن';
  static const String settingsThemeSystemLabel = 'النظام';
  static const String settingsServerStatusSectionLabel = 'حالة الخادم';
  static const String settingsConnectionSuccessPrefix = 'الاتصال ناجح! ';
  static const String settingsConnectionSuccessSuffix = ' كلمة متاحة';
  static const String settingsServerNotRespondingMessage = 'الخادم لا يستجيب';
  static const String settingsConnectionErrorPrefix = 'خطأ: ';
  static const String settingsTestingInProgressLabel = 'جاري الاختبار...';
  static const String settingsTestConnectionLabel = 'اختبار الاتصال';
  static const String settingsAboutSectionLabel = 'عن المشروع';
  static const String settingsInfoVersionLabel = 'الإصدار';
  static const String settingsInfoSourceLabel = 'المصدر';
  static const String settingsInfoSourceValue = 'القاموس الحضرمي';
  static const String settingsInfoBackendLabel = 'Backend';
  static const String settingsInfoBackendValue = 'FastAPI + Python';
  static const String settingsInfoFrontendLabel = 'Frontend';
  static const String settingsInfoFrontendValue = 'Flutter + Riverpod';
  static const String settingsInfoAiLabel = 'AI';
  static const String settingsInfoAiValue = 'RAG + Gemini';
  static const String settingsInfoApiLabel = 'API';

  // ---- Error Widget ----
  static const String errorWidgetRetryLabel = 'إعادة المحاولة';
}
