import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'profile': 'Profile',
      'account': 'Account',
      'editProfile': 'Edit Profile',
      'changePersonalInfo': 'Change your personal information',
      'privacySecurity': 'Privacy & Security',
      'manageDataPrivacy': 'Manage your data and privacy settings',
      'notifications': 'Notifications',
      'customizeNotifications': 'Customize your notification preferences',
      'appSettings': 'App Settings',
      'language': 'Language',
      'changeLanguage': 'Change app language',
      'appearance': 'Appearance',
      'darkModeThemeSettings': 'Dark mode and theme settings',
      'support': 'Support',
      'helpCenter': 'Help Center',
      'getHelp': 'Get help with the app',
      'about': 'About',
      'appInfo': 'App information and version',
      'logout': 'Logout',
      'english': 'English',
      'arabic': 'Arabic',
      // Stats screen translations
      'statistics': 'Statistics',
      'expenses': 'Expenses',
      'smsExpenses': 'SMS Expenses',
      'daily': 'Daily',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'yearly': 'Yearly',
      'total': 'Total',
      'thisWeek': 'This Week',
      'thisMonth': 'This Month',
      'thisYear': 'This Year',
      'fromLast': 'from last',
      'byCategory': 'By Category',
      'recentExpenses': 'Recent Expenses',
      'editExpense': 'Edit Expense',
      'merchant': 'Merchant',
      'category': 'Category',
      'customCategory': 'Custom Category',
      'enterCustomCategory': 'Or enter a custom category',
      'amount': 'Amount: SAR ',
      'amountCannotBeModified': '(Amount cannot be modified)',
      'cancel': 'Cancel',
      'save': 'Save',
      'expenseUpdated': 'Expense updated successfully',
      'errorUpdatingExpense': 'Error updating expense:',
      'noSmsExpensesFound': 'No SMS expenses found',
      'tapRefreshButton':
          'Tap the refresh button to scan your messages for expenses',
      'smsPermissionDenied': 'SMS permission denied',
      'noNewExpensesFound': 'No new expenses found in SMS',
      'errorExtractingSms': 'Error extracting expenses:',
      'saveAll': 'Save All',
      'expenseSaved': 'Expense saved successfully',
      'errorSavingExpense': 'Error saving expense:',
      'savedExpenses': 'Saved {count} expenses',
      'errorSavingExpenses': 'Error saving expenses:',
    },
    'ar': {
      'profile': 'الملف الشخصي',
      'account': 'الحساب',
      'editProfile': 'تعديل الملف الشخصي',
      'changePersonalInfo': 'تغيير المعلومات الشخصية',
      'privacySecurity': 'الخصوصية والأمان',
      'manageDataPrivacy': 'إدارة إعدادات البيانات والخصوصية',
      'notifications': 'الإشعارات',
      'customizeNotifications': 'تخصيص تفضيلات الإشعارات',
      'appSettings': 'إعدادات التطبيق',
      'language': 'اللغة',
      'changeLanguage': 'تغيير لغة التطبيق',
      'appearance': 'المظهر',
      'darkModeThemeSettings': 'الوضع المظلم وإعدادات السمة',
      'support': 'الدعم',
      'helpCenter': 'مركز المساعدة',
      'getHelp': 'الحصول على مساعدة مع التطبيق',
      'about': 'حول',
      'appInfo': 'معلومات التطبيق والإصدار',
      'logout': 'تسجيل الخروج',
      'english': 'الإنجليزية',
      'arabic': 'العربية',
      // Stats screen translations
      'statistics': 'الإحصائيات',
      'expenses': 'المصروفات',
      'smsExpenses': 'مصروفات الرسائل',
      'daily': 'يومي',
      'weekly': 'أسبوعي',
      'monthly': 'شهري',
      'yearly': 'سنوي',
      'total': 'المجموع',
      'thisWeek': 'هذا الأسبوع',
      'thisMonth': 'هذا الشهر',
      'thisYear': 'هذه السنة',
      'fromLast': 'من الفترة السابقة',
      'byCategory': 'حسب الفئة',
      'recentExpenses': 'المصروفات الأخيرة',
      'editExpense': 'تعديل المصروف',
      'merchant': 'التاجر',
      'category': 'الفئة',
      'customCategory': 'فئة مخصصة',
      'enterCustomCategory': 'أو أدخل فئة مخصصة',
      'amount': 'المبلغ: ريال ',
      'amountCannotBeModified': '(لا يمكن تعديل المبلغ)',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'expenseUpdated': 'تم تحديث المصروف بنجاح',
      'errorUpdatingExpense': 'خطأ في تحديث المصروف:',
      'noSmsExpensesFound': 'لم يتم العثور على مصروفات في الرسائل',
      'tapRefreshButton': 'اضغط على زر التحديث لفحص رسائلك بحثًا عن المصروفات',
      'smsPermissionDenied': 'تم رفض إذن الرسائل',
      'noNewExpensesFound': 'لم يتم العثور على مصروفات جديدة في الرسائل',
      'errorExtractingSms': 'خطأ في استخراج المصروفات:',
      'saveAll': 'حفظ الكل',
      'expenseSaved': 'تم حفظ المصروف بنجاح',
      'errorSavingExpense': 'خطأ في حفظ المصروف:',
      'savedExpenses': 'تم حفظ {count} مصروفات',
      'errorSavingExpenses': 'خطأ في حفظ المصروفات:',
    },
  };

  // Existing getters
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
  String get account => _localizedValues[locale.languageCode]!['account']!;
  String get editProfile =>
      _localizedValues[locale.languageCode]!['editProfile']!;
  String get changePersonalInfo =>
      _localizedValues[locale.languageCode]!['changePersonalInfo']!;
  String get privacySecurity =>
      _localizedValues[locale.languageCode]!['privacySecurity']!;
  String get manageDataPrivacy =>
      _localizedValues[locale.languageCode]!['manageDataPrivacy']!;
  String get notifications =>
      _localizedValues[locale.languageCode]!['notifications']!;
  String get customizeNotifications =>
      _localizedValues[locale.languageCode]!['customizeNotifications']!;
  String get appSettings =>
      _localizedValues[locale.languageCode]!['appSettings']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get changeLanguage =>
      _localizedValues[locale.languageCode]!['changeLanguage']!;
  String get appearance =>
      _localizedValues[locale.languageCode]!['appearance']!;
  String get darkModeThemeSettings =>
      _localizedValues[locale.languageCode]!['darkModeThemeSettings']!;
  String get support => _localizedValues[locale.languageCode]!['support']!;
  String get helpCenter =>
      _localizedValues[locale.languageCode]!['helpCenter']!;
  String get getHelp => _localizedValues[locale.languageCode]!['getHelp']!;
  String get about => _localizedValues[locale.languageCode]!['about']!;
  String get appInfo => _localizedValues[locale.languageCode]!['appInfo']!;
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
  String get english => _localizedValues[locale.languageCode]!['english']!;
  String get arabic => _localizedValues[locale.languageCode]!['arabic']!;

  // Stats screen getters
  String get statistics =>
      _localizedValues[locale.languageCode]!['statistics']!;
  String get expenses => _localizedValues[locale.languageCode]!['expenses']!;
  String get smsExpenses =>
      _localizedValues[locale.languageCode]!['smsExpenses']!;
  String get daily => _localizedValues[locale.languageCode]!['daily']!;
  String get weekly => _localizedValues[locale.languageCode]!['weekly']!;
  String get monthly => _localizedValues[locale.languageCode]!['monthly']!;
  String get yearly => _localizedValues[locale.languageCode]!['yearly']!;
  String get total => _localizedValues[locale.languageCode]!['total']!;
  String get thisWeek => _localizedValues[locale.languageCode]!['thisWeek']!;
  String get thisMonth => _localizedValues[locale.languageCode]!['thisMonth']!;
  String get thisYear => _localizedValues[locale.languageCode]!['thisYear']!;
  String get fromLast => _localizedValues[locale.languageCode]!['fromLast']!;
  String get byCategory =>
      _localizedValues[locale.languageCode]!['byCategory']!;
  String get recentExpenses =>
      _localizedValues[locale.languageCode]!['recentExpenses']!;
  String get editExpense =>
      _localizedValues[locale.languageCode]!['editExpense']!;
  String get merchant => _localizedValues[locale.languageCode]!['merchant']!;
  String get category => _localizedValues[locale.languageCode]!['category']!;
  String get customCategory =>
      _localizedValues[locale.languageCode]!['customCategory']!;
  String get enterCustomCategory =>
      _localizedValues[locale.languageCode]!['enterCustomCategory']!;
  String get amount => _localizedValues[locale.languageCode]!['amount']!;
  String get amountCannotBeModified =>
      _localizedValues[locale.languageCode]!['amountCannotBeModified']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get expenseUpdated =>
      _localizedValues[locale.languageCode]!['expenseUpdated']!;
  String get errorUpdatingExpense =>
      _localizedValues[locale.languageCode]!['errorUpdatingExpense']!;
  String get noSmsExpensesFound =>
      _localizedValues[locale.languageCode]!['noSmsExpensesFound']!;
  String get tapRefreshButton =>
      _localizedValues[locale.languageCode]!['tapRefreshButton']!;
  String get smsPermissionDenied =>
      _localizedValues[locale.languageCode]!['smsPermissionDenied']!;
  String get noNewExpensesFound =>
      _localizedValues[locale.languageCode]!['noNewExpensesFound']!;
  String get errorExtractingSms =>
      _localizedValues[locale.languageCode]!['errorExtractingSms']!;
  String get saveAll => _localizedValues[locale.languageCode]!['saveAll']!;
  String get expenseSaved =>
      _localizedValues[locale.languageCode]!['expenseSaved']!;
  String get errorSavingExpense =>
      _localizedValues[locale.languageCode]!['errorSavingExpense']!;

  String savedExpenses(int count) {
    return _localizedValues[locale.languageCode]!['savedExpenses']!
        .replaceAll('{count}', count.toString());
  }

  String get errorSavingExpenses =>
      _localizedValues[locale.languageCode]!['errorSavingExpenses']!;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
