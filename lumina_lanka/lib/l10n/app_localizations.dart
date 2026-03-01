import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

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
    Locale('si'),
    Locale('ta'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Lumina Lanka'**
  String get appName;

  /// No description provided for @mapScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapScreenTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @supportAndEmergency.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT & EMERGENCY'**
  String get supportAndEmergency;

  /// No description provided for @councilEmergencyLine.
  ///
  /// In en, this message translates to:
  /// **'Council Emergency Line'**
  String get councilEmergencyLine;

  /// No description provided for @electricityBoard.
  ///
  /// In en, this message translates to:
  /// **'Electricity Board (CEB)'**
  String get electricityBoard;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @staffLogin.
  ///
  /// In en, this message translates to:
  /// **'Staff Login'**
  String get staffLogin;

  /// No description provided for @publicLogin.
  ///
  /// In en, this message translates to:
  /// **'Public User Login'**
  String get publicLogin;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get guestUser;

  /// No description provided for @publicUser.
  ///
  /// In en, this message translates to:
  /// **'PUBLIC USER'**
  String get publicUser;

  /// No description provided for @mapMarker.
  ///
  /// In en, this message translates to:
  /// **'MAP MARKER'**
  String get mapMarker;

  /// No description provided for @electrician.
  ///
  /// In en, this message translates to:
  /// **'ELECTRICIAN'**
  String get electrician;

  /// No description provided for @councilAdmin.
  ///
  /// In en, this message translates to:
  /// **'COUNCIL ADMIN'**
  String get councilAdmin;

  /// No description provided for @statPolesMarked.
  ///
  /// In en, this message translates to:
  /// **'Poles Marked by You'**
  String get statPolesMarked;

  /// No description provided for @statIssuesResolved.
  ///
  /// In en, this message translates to:
  /// **'Total Issues Resolved'**
  String get statIssuesResolved;

  /// No description provided for @statTotalPoles.
  ///
  /// In en, this message translates to:
  /// **'Total Poles in System'**
  String get statTotalPoles;

  /// No description provided for @councilDashboard.
  ///
  /// In en, this message translates to:
  /// **'Council Dashboard'**
  String get councilDashboard;

  /// No description provided for @totalPoles.
  ///
  /// In en, this message translates to:
  /// **'Total Poles'**
  String get totalPoles;

  /// No description provided for @pendingRepairs.
  ///
  /// In en, this message translates to:
  /// **'Pending Repairs'**
  String get pendingRepairs;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @recentReports.
  ///
  /// In en, this message translates to:
  /// **'Recent Reports'**
  String get recentReports;

  /// No description provided for @noReportsFound.
  ///
  /// In en, this message translates to:
  /// **'No reports found.'**
  String get noReportsFound;

  /// No description provided for @networkHealth.
  ///
  /// In en, this message translates to:
  /// **'Network Health'**
  String get networkHealth;

  /// No description provided for @working.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get working;

  /// No description provided for @faulty.
  ///
  /// In en, this message translates to:
  /// **'Faulty'**
  String get faulty;

  /// No description provided for @reportsLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Reports (Last 7 Days)'**
  String get reportsLast7Days;

  /// No description provided for @myTasks.
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get myTasks;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All Caught Up!'**
  String get allCaughtUp;

  /// No description provided for @noPendingTasks.
  ///
  /// In en, this message translates to:
  /// **'There are no pending tasks right now.'**
  String get noPendingTasks;

  /// No description provided for @markAsResolved.
  ///
  /// In en, this message translates to:
  /// **'Mark as Resolved'**
  String get markAsResolved;

  /// No description provided for @reportAnIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an Issue'**
  String get reportAnIssue;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @showOnlyBroken.
  ///
  /// In en, this message translates to:
  /// **'Show Only Broken'**
  String get showOnlyBroken;

  /// No description provided for @reportsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Reports Submitted'**
  String get reportsSubmitted;

  /// No description provided for @myPastReports.
  ///
  /// In en, this message translates to:
  /// **'My Past Reports'**
  String get myPastReports;

  /// No description provided for @noPastReports.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t submitted any reports yet.'**
  String get noPastReports;
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
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
