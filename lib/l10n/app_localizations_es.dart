// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Know & Go';

  @override
  String get appSubtitle =>
      '¡Tu dosis diaria de aprendizaje sobre tu nuevo Renault!';

  @override
  String get searchHint => 'Buscar videos y temas...';

  @override
  String get sortButton => 'Ordenar por';

  @override
  String get sortByDate => 'Por Fecha';

  @override
  String get sortByAlphabet => 'A-Z';

  @override
  String get updatedOn => 'Actualizado el';

  @override
  String get closeButton => 'Cerrar';

  @override
  String get appCarSelectionTitle => 'cambiar modelo';

  @override
  String get carSelectionWelcomeTitle => 'Bienvenida';

  @override
  String get carSelectionWelcomeSubtitle =>
      'Aquí encontrará guías en video sobre las funciones y características de su Renault. Para comenzar, elija el modelo de su coche.';
}
