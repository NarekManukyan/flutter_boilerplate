import 'package:injectable/injectable.dart';

import '../navigation/app_navigator.dart';

@injectable
class OpenTodoDetailsUseCase {
  final AppNavigator _appNavigator;

  OpenTodoDetailsUseCase(this._appNavigator);

  Future<void> call(String id) async {
    await _appNavigator.push(TodoDetailsRoute(todoId: id));
  }
}
