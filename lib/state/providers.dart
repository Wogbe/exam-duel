import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_repository.dart';
import '../data/local_bank.dart';
import '../data/player_store.dart';

/// Overridden in main() once loaded.
final localBankProvider = Provider<LocalBank>((ref) => throw UnimplementedError());
final playerStoreProvider = ChangeNotifierProvider<PlayerStore>((ref) => throw UnimplementedError());
final gameRepoProvider = Provider<GameRepository>((ref) => GameRepository());
