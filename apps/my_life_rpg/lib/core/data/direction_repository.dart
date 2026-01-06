import 'package:my_life_rpg/core/data/base_repository.dart';
import 'package:my_life_rpg/models/direction.dart';

class DirectionRepository extends BaseRepository<Direction> {
  @override
  String get storageKey => 'db_directions';

  @override
  Direction fromJson(Map<String, dynamic> json) => Direction.fromJson(json);
}
