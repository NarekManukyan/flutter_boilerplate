import 'package:flutter_boilerplate/core/constants/flavor_type.dart';
import 'package:flutter_boilerplate/core/services/flavor_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlavorService', () {
    // Regression guard: production.json said "PRODUCTION" while FlavorType has
    // PROD, so FlavorProd threw while parsing its config and a prod build
    // crashed before the first frame. Nothing ran it until the flavor was
    // constructed in a test.
    test('should build the production flavor from its config', () {
      final flavor = FlavorProd();

      expect(flavor.flavor, FlavorType.PROD);
      expect(flavor.isProduction, isTrue);
      expect(flavor.config.env, FlavorType.PROD);
    });

    test('should build the development flavor from its config', () {
      final flavor = FlavorDev();

      expect(flavor.flavor, FlavorType.DEVELOPMENT);
      expect(flavor.isDev, isTrue);
      expect(flavor.config.env, FlavorType.DEVELOPMENT);
    });
  });
}
