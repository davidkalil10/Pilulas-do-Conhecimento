// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Pilules de Savoir';

  @override
  String get appSubtitle =>
      'Votre dose quotidienne d\'apprentissage sur votre nouvelle Renault !';

  @override
  String get searchHint => 'Rechercher des vidéos et des sujets...';

  @override
  String get sortButton => 'Trier par';

  @override
  String get sortByDate => 'Par Date';

  @override
  String get sortByAlphabet => 'A-Z';

  @override
  String get updatedOn => 'Mis à jour le';

  @override
  String get closeButton => 'Fermer';
}
