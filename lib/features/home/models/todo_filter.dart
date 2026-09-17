import 'package:api/api.dart';

/// Which todos the Home list shows.
enum TodoFilter {
  all,
  active,
  done;

  bool matches(TodoDto todo) => switch (this) {
    TodoFilter.all => true,
    TodoFilter.active => !todo.completed,
    TodoFilter.done => todo.completed,
  };
}
