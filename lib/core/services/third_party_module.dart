import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

/// Registrations for third-party classes the app cannot annotate itself, so
/// they arrive through constructors like everything else (ADR-0007) and can be
/// replaced by fakes in tests.
@module
abstract class ThirdPartyModule {
  @lazySingleton
  Connectivity get connectivity => Connectivity();
}
