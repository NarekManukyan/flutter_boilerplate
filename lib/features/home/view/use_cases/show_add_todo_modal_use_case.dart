import 'package:injectable/injectable.dart';

import '../../../../core/navigation/app_navigator.dart';
import '../../modals/add_todo_modal/view/add_todo_modal.dart';

@injectable
class ShowAddTodoModalUseCase {
  final AppNavigator _appNavigator;

  ShowAddTodoModalUseCase(this._appNavigator);

  Future<void> call() async {
    await _appNavigator.showModal(builder: (_) => const AddTodoModal());
  }
}
