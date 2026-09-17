import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_boilerplate/core/navigation/app_navigator.dart';
import 'package:flutter_boilerplate/core/services/flavor_service.dart';
import 'package:flutter_boilerplate/core/services/issue_tracking_service.dart';
import 'package:flutter_boilerplate/core/ui/error_notice.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:overlay_support/overlay_support.dart';

class _MockAppNavigator extends Mock implements AppNavigator {}

class _MockBuildContext extends Mock implements BuildContext {}

class _FakeOverlayEntry extends Fake implements OverlaySupportEntry {}

DioException _dio(DioExceptionType type, {int? status}) => DioException(
  requestOptions: RequestOptions(path: '/todos'),
  type: type,
  response: status == null
      ? null
      : Response(
          requestOptions: RequestOptions(path: '/todos'),
          statusCode: status,
        ),
);

void main() {
  late _MockAppNavigator navigator;
  late IssueTrackingService service;

  setUpAll(() {
    registerFallbackValue(const SizedBox());
  });

  setUp(() {
    navigator = _MockAppNavigator();
    when(() => navigator.context).thenReturn(_MockBuildContext());
    when(
      () => navigator.showScaffoldMessage(any()),
    ).thenReturn(_FakeOverlayEntry());
    service = IssueTrackingService(navigator, FlavorProd());
  });

  String? shownMessage() {
    final captured = verify(
      () => navigator.showScaffoldMessage(captureAny()),
    ).captured;
    return (captured.single as ErrorNotice).message;
  }

  group('shouldReport', () {
    test('should report server errors and plain exceptions', () {
      expect(
        IssueTrackingService.shouldReport(
          _dio(DioExceptionType.badResponse, status: 500),
        ),
        isTrue,
      );
      expect(IssueTrackingService.shouldReport(StateError('x')), isTrue);
      expect(IssueTrackingService.shouldReport(Exception('x')), isTrue);
    });

    test('should not report connectivity errors, cancellations or 401', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
        DioExceptionType.cancel,
      ]) {
        expect(
          IssueTrackingService.shouldReport(_dio(type)),
          isFalse,
          reason: '$type',
        );
      }
      expect(
        IssueTrackingService.shouldReport(
          _dio(DioExceptionType.badResponse, status: 401),
        ),
        isFalse,
      );
    });

    test('should not report a thrown value that is not an error', () {
      expect(IssueTrackingService.shouldReport('just a string'), isFalse);
    });
  });

  group('trackIssue', () {
    test('should show a generic notice in production', () {
      service.trackIssue(_dio(DioExceptionType.badResponse, status: 500));

      expect(shownMessage(), isNot(contains('DioException')));
    });

    test('should show the raw error outside production', () {
      IssueTrackingService(
        navigator,
        FlavorDev(),
      ).trackIssue(StateError('broken invariant'));

      expect(shownMessage(), contains('broken invariant'));
    });

    test('should prefer the caller message', () {
      service.trackIssue(Exception('x'), message: 'Could not save');

      expect(shownMessage(), 'Could not save');
    });

    test('should not show a notice for connectivity errors', () {
      // The connection page already says the device is offline.
      service.trackIssue(_dio(DioExceptionType.connectionError));

      verifyNever(() => navigator.showScaffoldMessage(any()));
    });

    test('should not show a notice for a 401', () {
      // AuthInterceptor logs the user out; a notice on top is noise.
      service.trackIssue(_dio(DioExceptionType.badResponse, status: 401));

      verifyNever(() => navigator.showScaffoldMessage(any()));
    });

    test('should not throw when there is no navigator context', () {
      when(() => navigator.context).thenReturn(null);

      expect(() => service.trackIssue(Exception('early')), returnsNormally);
      verifyNever(() => navigator.showScaffoldMessage(any()));
    });
  });

  group('trackHandledError and trackSilentError', () {
    test('should never show a notice', () {
      final error = _dio(DioExceptionType.badResponse, status: 500);

      service
        ..trackHandledError(error, handlingContext: 'load_todos')
        ..trackSilentError(error, context: 'background_sync');

      verifyNever(() => navigator.showScaffoldMessage(any()));
    });
  });
}
