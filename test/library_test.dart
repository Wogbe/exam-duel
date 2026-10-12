import 'dart:convert';

import 'package:exam_duel/data/sample_sets.dart';
import 'package:exam_duel/data/study_set.dart';
import 'package:exam_duel/state/library.dart';
import 'package:exam_duel/state/progress.dart';
import 'package:exam_duel/theme/mastery.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a study set survives a JSON round trip', () {
    for (final s in studySets) {
      final back = StudySet.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
      expect(back.id, s.id);
      expect(back.topics.map((t) => (t.name, t.mastery)), s.topics.map((t) => (t.name, t.mastery)));
      expect(back.questions.length, s.questions.length);
      expect(back.questions.first.options, s.questions.first.options);
      expect(back.duelTopic, s.duelTopic);
    }
  });

  test('a saved set that makes no sense is rejected', () {
    Map<String, dynamic> good() => jsonDecode(jsonEncode(studySets.first.toJson())) as Map<String, dynamic>;
    expect(() => StudySet.fromJson(good()..['topics'] = []), throwsA(anything));
    expect(() => StudySet.fromJson(good()..['duelTopic'] = 99), throwsA(anything));
    final bad = good();
    (bad['questions'] as List).first['answer'] = 7;
    expect(() => StudySet.fromJson(bad), throwsA(anything));
  });

  test('the library puts the newest map first, never lists one twice, and caps the list', () async {
    final lib = MapLibrary();
    lib.add(studySets[0]);
    lib.add(studySets[1]);
    lib.add(studySets[0]);
    expect(lib.maps.map((m) => m.id), [studySets[0].id, studySets[1].id]);
    for (var i = 0; i < 30; i++) {
      lib.add(StudySet.fromJson({...studySets.first.toJson(), 'id': 'm$i'}));
    }
    expect(lib.maps.length, MapLibrary.maxMaps);
    expect(lib.maps.first.id, 'm29');
  });

  test('maps and progress come back after a restart', () async {
    final lib = MapLibrary();
    final prog = Progress();
    await lib.load();
    await prog.load();
    lib.add(studySets[1]);
    lib.add(studySets[0]);
    final topic = prog.suggest(studySets[0])!;
    final before = prog.mastery(studySets[0], topic);
    prog.levelUp(studySets[0], topic);
    await Future<void>.delayed(Duration.zero);

    final lib2 = MapLibrary();
    final prog2 = Progress();
    await lib2.load();
    await prog2.load();
    expect(lib2.maps.map((m) => m.id), [studySets[0].id, studySets[1].id]);
    expect(prog2.mastery(studySets[0], topic).index, before.index + 1);
    expect(prog2.readiness(studySets[0]), prog.readiness(studySets[0]));
  });

  test('unreadable saved data starts empty instead of crashing, and one bad map is skipped', () async {
    SharedPreferences.setMockInitialValues({'learn.maps': 'not json', 'learn.progress': '[1,2]'});
    final lib = MapLibrary();
    final prog = Progress();
    await lib.load();
    await prog.load();
    expect(lib.maps, isEmpty);
    expect(prog.mastery(studySets.first, 0), studySets.first.topics.first.mastery);

    SharedPreferences.setMockInitialValues({
      'learn.maps': jsonEncode([
        {'id': 'broken'},
        studySets.first.toJson(),
      ]),
    });
    final lib2 = MapLibrary();
    await lib2.load();
    expect(lib2.maps.map((m) => m.id), [studySets.first.id]);
    expect(Mastery.values.length, 4); // keeps the import honest if mastery levels change
  });
}
