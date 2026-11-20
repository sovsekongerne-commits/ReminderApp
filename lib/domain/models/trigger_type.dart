/// TriggerType definerer hvornår en påmindelse aktiveres.
enum TriggerType {
  /// Udløses når brugeren ankommer til det valgte sted
  arrival,

  /// Udløses når brugeren forlader det valgte sted
  departure,

  /// Udløses på et specifikt tidspunkt uden stedkrav
  time,

  /// Udløses når brugeren ankommer/forlader stedet OG tidsbetingelsen er opfyldt
  locationWithTimeCondition;

  bool get isLocationBased =>
      this == TriggerType.arrival ||
      this == TriggerType.departure ||
      this == TriggerType.locationWithTimeCondition;
}
