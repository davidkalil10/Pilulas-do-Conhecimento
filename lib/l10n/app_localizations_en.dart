// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Know & Go';

  @override
  String get appSubtitle =>
      'Your daily dose of learning about your new Renault!';

  @override
  String get searchHint => 'Search videos and topics...';

  @override
  String get sortButton => 'Sort by';

  @override
  String get sortByDate => 'By Date';

  @override
  String get sortByAlphabet => 'A-Z';

  @override
  String get updatedOn => 'Updated on';

  @override
  String get closeButton => 'Close';

  @override
  String get appCarSelectionTitle => 'change model';

  @override
  String get carSelectionWelcomeTitle => 'Welcome';

  @override
  String get carSelectionWelcomeSubtitle =>
      'Here you\'ll find video guides on the features and functions of your Renault. To get started, choose your car model.';
}
