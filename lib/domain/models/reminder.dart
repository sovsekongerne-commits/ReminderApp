/// Et punkt på en huskeseddel / indkøbsliste.
class ChecklistItem {
  final String id;
  final String text;
  final bool isDone;

  const ChecklistItem({
    required this.id,
    required this.text,
    this.isDone = false,
  });

  ChecklistItem copyWith({String? id, String? text, bool? isDone}) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'isDone': isDone};

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
        id: json['id'] as String,
        text: json['text'] as String,
        isDone: json['isDone'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChecklistItem &&
          id == other.id &&
          text == other.text &&
          isDone == other.isDone;

  @override
  int get hashCode => Object.hash(id, text, isDone);
}

/// En huskeseddel. Den udløses, når man ANKOMMER til et af dens steder.
///
/// - [placeIds]: et eller flere steder (f.eks. både Netto og Rema 1000).
/// - [checklistItems]: valgfri punkter, der kan krydses af.
/// - [imagePath]: valgfrit billede.
/// - [afterMinutes]: valgfrit "efter kl." som minutter efter midnat.
/// - [isRecurring]: "Mind mig hver gang" – sedlen bliver aldrig udført,
///   fluebenene nulstilles i stedet ved næste ankomst.
class Reminder {
  final String id;
  final String title;
  final List<String> placeIds;
  final List<ChecklistItem> checklistItems;
  final String? imagePath;
  final int? afterMinutes;
  final bool isRecurring;
  final bool enabled;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Reminder({
    required this.id,
    required this.title,
    this.placeIds = const [],
    this.checklistItems = const [],
    this.imagePath,
    this.afterMinutes,
    this.isRecurring = false,
    this.enabled = true,
    required this.createdAt,
    this.completedAt,
  });

  bool get isCompleted => completedAt != null;
  bool get hasItems => checklistItems.isNotEmpty;
  bool get allItemsDone =>
      checklistItems.isNotEmpty && checklistItems.every((i) => i.isDone);
  int get doneCount => checklistItems.where((i) => i.isDone).length;
  bool isAt(String placeId) => placeIds.contains(placeId);

  /// Sand hvis klokkeslæt-betingelsen er opfyldt (eller ikke sat).
  bool timeAllows(DateTime now) =>
      afterMinutes == null || now.hour * 60 + now.minute >= afterMinutes!;

  String? get afterLabel =>
      afterMinutes == null ? null : formatMinutes(afterMinutes!);

  /// 960 → "16:00"
  static String formatMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Reminder copyWith({
    String? id,
    String? title,
    List<String>? placeIds,
    List<ChecklistItem>? checklistItems,
    String? imagePath,
    int? afterMinutes,
    bool? isRecurring,
    bool? enabled,
    DateTime? createdAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool clearAfter = false,
    bool clearImagePath = false,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      placeIds: placeIds ?? this.placeIds,
      checklistItems: checklistItems ?? this.checklistItems,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      afterMinutes: clearAfter ? null : (afterMinutes ?? this.afterMinutes),
      isRecurring: isRecurring ?? this.isRecurring,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  /// Fjerner alle flueben.
  Reminder resetItems() => copyWith(
        checklistItems: [
          for (final i in checklistItems) i.copyWith(isDone: false),
        ],
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'placeIds': placeIds,
      'checklistItems': checklistItems.map((e) => e.toJson()).toList(),
      'imagePath': imagePath,
      'afterMinutes': afterMinutes,
      'isRecurring': isRecurring,
      'enabled': enabled,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  /// Læser både det nye format og det gamle (placeId, timeCondition,
  /// isArrival), så eksisterende sedler ikke går tabt efter opdateringen.
  factory Reminder.fromJson(Map<String, dynamic> json) {
    List<String> placeIds;
    final rawIds = json['placeIds'];
    if (rawIds is List) {
      placeIds = rawIds.whereType<String>().toList();
    } else {
      final old = json['placeId'] as String?;
      placeIds = old == null ? <String>[] : <String>[old];
    }

    int? after = (json['afterMinutes'] as num?)?.toInt();
    if (after == null && json['timeCondition'] is String) {
      final t = DateTime.tryParse(json['timeCondition'] as String);
      if (t != null) after = t.hour * 60 + t.minute;
    }

    return Reminder(
      id: json['id'] as String,
      title: json['title'] as String,
      placeIds: placeIds,
      checklistItems: (json['checklistItems'] as List<dynamic>?)
              ?.map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      imagePath: json['imagePath'] as String?,
      afterMinutes: after,
      isRecurring: json['isRecurring'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Reminder && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
