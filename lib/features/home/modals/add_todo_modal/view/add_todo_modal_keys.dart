import 'package:flutter/widgets.dart';

/// Stable widget keys for the Add Todo modal.
///
/// These strings are the accessibility identifiers Maestro matches on with
/// `id:` — renaming one breaks `.maestro/flows/home/`. See ADR-0015.
class AddTodoModalKeys {
  AddTodoModalKeys._();

  static const sheet = Key('add_todo_sheet');
  static const titleField = Key('add_todo_title_field');
  static const submit = Key('add_todo_submit');
  static const cancel = Key('add_todo_cancel');
  static const counter = Key('add_todo_counter');
  static const errorText = Key('add_todo_error');
}
