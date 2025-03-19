import 'core/constants/flavor_type.dart';
import 'main.dart' as app;

Future<void> main() async {
  await app.run(env: FlavorType.PROD);
}
