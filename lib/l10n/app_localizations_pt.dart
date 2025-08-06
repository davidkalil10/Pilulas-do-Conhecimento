// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Pílulas do Conhecimento';

  @override
  String get appSubtitle =>
      'Sua dose diária de aprendizado sobre seu novo Renault!';

  @override
  String get searchHint => 'Buscar vídeos e temas...';

  @override
  String get sortButton => 'Ordenar';

  @override
  String get sortByDate => 'Por Data';

  @override
  String get sortByAlphabet => 'A-Z';

  @override
  String get updatedOn => 'Atualizado em';

  @override
  String get closeButton => 'Fechar';
}
