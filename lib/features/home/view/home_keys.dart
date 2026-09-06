/// Stable accessibility identifiers for the Home feature.
///
/// Applied with `TestId` (`lib/core/ui/test_id.dart`), which sets both a
/// `Semantics(identifier:)` — what Maestro matches with `id:` — and a widget
/// `Key` for widget tests. A plain `Key` alone is NOT visible to Maestro.
///
/// These strings are a contract with `.maestro/flows/home/`. See ADR-0015.
class HomeKeys {
  HomeKeys._();

  static const skeletonList = 'home_skeleton_list';
  static const errorState = 'home_error_state';
  static const errorRetry = 'home_error_retry';
  static const emptyState = 'home_empty_state';
  static const todoList = 'home_todo_list';
  static const filterEmptyState = 'home_filter_empty_state';
  static const addTodoFab = 'home_add_todo_fab';
  static const filterAll = 'home_filter_all';
  static const filterActive = 'home_filter_active';
  static const filterDone = 'home_filter_done';
  static const logoutButton = 'home_logout_button';
}
