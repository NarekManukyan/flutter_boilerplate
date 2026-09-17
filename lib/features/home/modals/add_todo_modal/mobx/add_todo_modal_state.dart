import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';

import '../../../../../core/navigation/app_navigator.dart';
import '../../../../../core/state/loading_state.dart';
import '../../../mobx/home_store.dart';
import '../use_cases/create_todo_use_case.dart';

part 'add_todo_modal_state.g.dart';

@injectable
class AddTodoModalState = _AddTodoModalStateBase with _$AddTodoModalState;

abstract class _AddTodoModalStateBase with Store {
  final CreateTodoUseCase _createTodoUseCase;
  final HomeStore _homeStore;
  final AppNavigator _appNavigator;

  _AddTodoModalStateBase(
    this._createTodoUseCase,
    this._homeStore,
    this._appNavigator,
  );

  final TextEditingController titleController = TextEditingController();
  final LoadingState loadingState = LoadingState();

  @readonly
  bool _hasError = false;

  @action
  Future<void> onSubmit() async {
    // Both the button and the keyboard's submit action call this. Without the
    // guard a quick double submit created the todo twice.
    if (loadingState.isLoading) {
      return;
    }
    loadingState.startLoading();
    _hasError = false;
    try {
      final todo = await _createTodoUseCase(titleController.text.trim());
      if (todo == null) {
        // The request failed. Keep the sheet open and say so — a silent no-op
        // leaves the user tapping a button that appears to do nothing.
        _hasError = true;
        return;
      }
      await _homeStore.addTodo(todo);
      await _appNavigator.pop();
    } finally {
      loadingState.stopLoading();
    }
  }

  Future<void> onCancelPressed() => _appNavigator.pop();

  void dispose() {
    titleController.dispose();
  }
}
