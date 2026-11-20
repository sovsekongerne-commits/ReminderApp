/// AppStrings indeholder alle danske tekster og labels i appen.
class AppStrings {
  AppStrings._();

  // App & Headers
  static const String appName = 'Sted & Påmindelse';
  static const String remindersTitle = 'Påmindelser';
  static const String placesTitle = 'Steder';
  static const String activeRemindersCount = 'aktive';

  // Hilsner
  static const String greetingMorning = 'Godmorgen';
  static const String greetingAfternoon = 'God eftermiddag';
  static const String greetingEvening = 'Godaften';
  static const String greetingNight = 'Godnat';

  // Opret Påmindelse
  static const String newReminder = 'Ny seddel';
  static const String editReminder = 'Ret seddel';
  static const String reminderInputHint =
      'F.eks. Indkøb, hent medicin...';
  static const String reminderInputLabel = 'Påmindelse';
  static const String whereSection = 'HVOR';
  static const String triggerSection = 'HVORNÅR';
  static const String timeConditionSection = 'TIDSPUNKT (VALGFRIT)';
  static const String addTimeCondition = 'Tilføj klokkeslæt';
  static const String removeTimeCondition = 'Fjern tid';
  static const String triggerArrival = 'Ved ankomst';
  static const String triggerDeparture = 'Ved afgang';
  static const String triggerTimeOnly = 'Kun på klokkeslæt';
  static const String saveReminder = 'Gem seddel';
  static const String updateReminder = 'Gem ændringer';

  // Opret / Vælg Sted
  static const String newPlace = 'Nyt sted';
  static const String placeNameHint = 'F.eks. Sommerhus, Bageren, Mormor...';
  static const String placeNameLabel = 'Navn på sted';
  static const String placeIconLabel = 'Vælg et lille ikon';
  static const String placeRadiusLabel = 'Afstand (radius)';
  static const String savePlace = 'Gem sted';
  static const String allPlaces = 'Alle';
  static const String editPlacesMode = 'Rediger steder';
  static const String doneEditing = 'Færdig';

  // Handlinger
  static const String edit = 'Rediger';
  static const String delete = 'Slet';
  static const String cancel = 'Annuller';
  static const String complete = 'Udført';
  static const String undo = 'Fortryd';

  // Tomme tilstande
  static const String noActiveReminders = 'Her er helt tomt og roligt';
  static const String noActiveRemindersSub =
      'Tryk på knappen forneden for at huske noget.';
  static const String noFilteredReminders =
      'Intet at huske her endnu';

  // Tidsformateringer
  static const String afterTimePrefix = 'Efter kl.';
  static const String atTimePrefix = 'Kl.';
  static const String today = 'I dag';
  static const String tomorrow = 'I morgen';

  // Mormor-guide
  static const String guideTitle = 'Sådan bruger du appen';
  static const String guideButton = 'Nem vejledning';
  static const String guideIntro =
      'Velkommen! Her hjælper vi dig med at huske alt det vigtige – helt uden besvær.';
}
