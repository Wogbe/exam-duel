import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import 'models.dart';

/// Bundled questions and facts. Works fully offline (solo play, daily fact).
class LocalBank {
  LocalBank._(this._questions, this._facts);

  final List<Map<String, dynamic>> _questions;
  final List<Fact> _facts;
  final _rng = Random();

  static Future<LocalBank> load() async {
    final q = jsonDecode(await rootBundle.loadString('assets/data/questions.json')) as List;
    final f = jsonDecode(await rootBundle.loadString('assets/data/facts.json')) as List;
    return LocalBank._(
      q.cast<Map<String, dynamic>>(),
      f.map((e) => Fact(e['t'] as String, e['c'] as String)).toList(),
    );
  }

  int get questionCount => _questions.length;

  /// Random questions, optionally limited to some categories.
  /// Never repeats a question within one batch.
  List<Question> draw(int n, {List<String> categories = const []}) {
    final pool = _questions
        .where((q) => categories.isEmpty || categories.contains(q['c']))
        .toList()
      ..shuffle(_rng);
    return pool.take(n).map((j) => Question.fromBank(j, _rng)).toList();
  }

  /// One endless stream for Quick Fire: reshuffles when the pool runs out.
  Iterable<Question> endless({List<String> categories = const []}) sync* {
    while (true) {
      final batch = draw(1000, categories: categories);
      if (batch.isEmpty) return;
      yield* batch;
    }
  }

  /// Same fact for everyone on the same calendar day, cycling the list.
  Fact factFor(DateTime day) {
    final epochDay = DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/ 86400000;
    return _facts[epochDay % _facts.length];
  }
}
