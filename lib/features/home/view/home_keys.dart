import 'package:flutter/widgets.dart';

/// Stable widget keys for the Home feature.
///
/// Flutter exports a widget's [Key] as its accessibility identifier, which is
/// what Maestro matches on with `id:`. The string literals below are therefore
/// a contract with `.maestro/flows/home/` — renaming one breaks the E2E flows.
///
/// See ADR-0015.
class HomeKeys {
  HomeKeys._();

  static const skeletonList = Key('home_skeleton_list');
  static const errorState = Key('home_error_state');
  static const errorRetry = Key('home_error_retry');
  static const emptyState = Key('home_empty_state');
  static const todoList = Key('home_todo_list');
  static const filterEmptyState = Key('home_filter_empty_state');
  static const addTodoFab = Key('home_add_todo_fab');
  static const filterAll = Key('home_filter_all');
  static const filterActive = Key('home_filter_active');
  static const filterDone = Key('home_filter_done');
  static const logoutButton = Key('home_logout_button');
}
