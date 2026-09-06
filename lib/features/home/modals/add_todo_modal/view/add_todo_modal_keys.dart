/// Stable accessibility identifiers for the Add Todo modal.
///
/// Applied with `TestId` — see `lib/core/ui/test_id.dart`. A plain `Key` is not
/// visible to Maestro; `Semantics(identifier:)` is. ADR-0015.
class AddTodoModalKeys {
  AddTodoModalKeys._();

  static const sheet = 'add_todo_sheet';
  static const titleField = 'add_todo_title_field';
  static const submit = 'add_todo_submit';
  static const cancel = 'add_todo_cancel';
  static const counter = 'add_todo_counter';
  static const errorText = 'add_todo_error';
}
