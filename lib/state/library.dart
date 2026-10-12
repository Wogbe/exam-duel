import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/study_set.dart';

/// The maps the learner has built, most recent first. Saved on the device once [load] has run;
/// before that (tests, the preview) it lives in memory only.
class MapLibrary extends ChangeNotifier {
  static const _key = 'learn.maps';
  static const maxMaps = 20;

  SharedPreferences? _prefs;
  final _maps = <StudySet>[];

  List<StudySet> get maps => List.unmodifiable(_maps);

  Future<void> load() async {
    final prefs = _prefs = await SharedPreferences.getInstance();
    _maps.clear();
    try {
      for (final j in jsonDecode(prefs.getString(_key) ?? '[]') as List) {
        try {
          _maps.add(StudySet.fromJson(j as Map<String, dynamic>));
        } catch (_) {} // skip one unreadable map, keep the rest
      }
    } catch (_) {} // unreadable data: start empty
    notifyListeners();
  }

  /// Puts [set] first, replacing an older copy with the same id.
  void add(StudySet set) {
    _maps
      ..removeWhere((m) => m.id == set.id)
      ..insert(0, set);
    _changed();
  }

  /// Removes a map and returns where it was (for [restore]), or null if it was not there.
  /// Its progress is kept, so adding the same map again picks up where it left off.
  int? remove(String id) {
    final i = _maps.indexWhere((m) => m.id == id);
    if (i < 0) return null;
    _maps.removeAt(i);
    _changed();
    return i;
  }

  /// Puts a removed map back where it was.
  void restore(StudySet set, int index) {
    _maps
      ..removeWhere((m) => m.id == set.id)
      ..insert(index.clamp(0, _maps.length), set);
    _changed();
  }

  void _changed() {
    if (_maps.length > maxMaps) _maps.removeRange(maxMaps, _maps.length);
    _prefs?.setString(_key, jsonEncode([for (final m in _maps) m.toJson()]));
    notifyListeners();
  }
}

final library = MapLibrary();
