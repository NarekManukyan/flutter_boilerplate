import '../../injectable.dart';
import '../constants/flavor_type.dart';

void registerGetIt(FlavorType flavorMode) {
  configureDependencies(flavorMode);
}
