import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Maikago'**
  String get appTitle;

  /// The description of the application
  ///
  /// In en, this message translates to:
  /// **'Simple and easy-to-use shopping list management app'**
  String get appDescription;

  /// Button text to add a new item
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// Label for item name input field
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// Label for price input field
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// Label for quantity input field
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// Label for total amount
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Settings menu item
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Theme settings
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Font settings
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get font;

  /// Font size settings
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// About menu item
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Feedback menu item
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// Donation menu item
  ///
  /// In en, this message translates to:
  /// **'Donation'**
  String get donation;

  /// Calculator menu item
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get calculator;

  /// Usage menu item
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get usage;

  /// Upcoming features menu item
  ///
  /// In en, this message translates to:
  /// **'Upcoming Features'**
  String get upcomingFeatures;

  /// Welcome dialog title
  ///
  /// In en, this message translates to:
  /// **'Thank you for installing Maikago!'**
  String get welcomeTitle;

  /// Welcome dialog description
  ///
  /// In en, this message translates to:
  /// **'We\'ll help make your shopping life more enjoyable and efficient. Let\'s start smart shopping!'**
  String get welcomeDescription;

  /// Smart shopping title
  ///
  /// In en, this message translates to:
  /// **'Achieve savings through smart shopping'**
  String get smartShoppingTitle;

  /// Smart shopping description
  ///
  /// In en, this message translates to:
  /// **'To save money on shopping, it\'s important to decide what to buy in advance and calculate prices while shopping. Avoid unnecessary expenses and prevent budget overruns!'**
  String get smartShoppingDescription;

  /// No more switching title
  ///
  /// In en, this message translates to:
  /// **'No more switching between memo and calculator'**
  String get noMoreSwitchingTitle;

  /// No more switching description
  ///
  /// In en, this message translates to:
  /// **'Switching between memo and calculator is annoying. Maikago is an app that combines these functions! From creating shopping lists to calculating total amounts, everything is here.'**
  String get noMoreSwitchingDescription;

  /// Tab limit feature title
  ///
  /// In en, this message translates to:
  /// **'Tab Limit'**
  String get tabLimit;

  /// Theme customization feature title
  ///
  /// In en, this message translates to:
  /// **'Theme Customization'**
  String get themeCustomization;

  /// Font customization feature title
  ///
  /// In en, this message translates to:
  /// **'Font Customization'**
  String get fontCustomization;

  /// Group sharing feature title
  ///
  /// In en, this message translates to:
  /// **'Group Sharing'**
  String get groupSharing;

  /// Analytics feature title
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// Ad removal feature title
  ///
  /// In en, this message translates to:
  /// **'Ad Removal'**
  String get adRemoval;

  /// Export feature title
  ///
  /// In en, this message translates to:
  /// **'Export Feature'**
  String get exportFeature;

  /// Backup feature title
  ///
  /// In en, this message translates to:
  /// **'Backup Feature'**
  String get backupFeature;

  /// Category selection
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Request/improvement category
  ///
  /// In en, this message translates to:
  /// **'Request/Improvement'**
  String get requestImprovement;

  /// Bug report category
  ///
  /// In en, this message translates to:
  /// **'Bug Report'**
  String get bugReport;

  /// Other category
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// Subject field label
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// Message field label
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// Send button text
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Loading text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Error text
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Success text
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Warning text
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// Information text
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// Confirm text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Yes text
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No text
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Close text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Back text
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Next text
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Previous text
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// Search text
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Filter text
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Sort text
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// Refresh text
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Retry text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
