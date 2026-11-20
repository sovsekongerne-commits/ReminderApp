import 'package:shared_preferences/shared_preferences.dart';

/// Husker de ord, man har brugt på sine lister, så appen kan foreslå dem
/// igen ("mæ" → "Mælk"). Gemmes kun lokalt på telefonen.
class ItemHistoryRepository {
  static const String _key = 'item_history_v1';
  static const int _maxWords = 300;

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? <String>[];
  }

  /// Lægger ordet forrest (senest brugt først) uden dubletter.
  Future<List<String>> remember(String word) async {
    final w = word.trim();
    final list = await load();
    if (w.isEmpty) return list;
    list.removeWhere((x) => x.toLowerCase() == w.toLowerCase());
    list.insert(0, w);
    if (list.length > _maxWords) list.removeRange(_maxWords, list.length);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, list);
    return list;
  }

  /// Op til [limit] forslag, der starter med [query] og ikke allerede er på
  /// listen [exclude].
  static List<String> suggest(
    List<String> history,
    String query, {
    List<String> exclude = const [],
    int limit = 3,
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final ex = exclude.map((e) => e.toLowerCase()).toSet();
    return history
        .where((w) {
          final l = w.toLowerCase();
          return l.startsWith(q) && l != q && !ex.contains(l);
        })
        .take(limit)
        .toList();
  }
}
