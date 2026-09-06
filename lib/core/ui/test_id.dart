import 'package:flutter/widgets.dart';

/// Tags [child] so that one constant selects it from both test tiers.
///
/// A plain [Key] is **not** exported to the native accessibility tree, so
/// Maestro cannot see it — verified on device: a Flutter widget carrying only a
/// `Key` shows up with an empty `resource-id`. `Semantics(identifier:)` is what
/// sets `UIAccessibilityElement.accessibilityIdentifier` on iOS and
/// `AccessibilityNodeInfo.setViewIdResourceName` on Android, which is what
/// Maestro matches with `id:`.
///
/// This widget applies both, from a single id string:
///  * `Semantics(identifier:)` for Maestro flows — `- tapOn: { id: "..." }`
///  * a [Key] for widget tests — `find.byKey(Key(HomeKeys.todoList))`
///
/// Ids live in the feature's `*_keys.dart`. See ADR-0015 and the
/// `write-maestro-flow` playbook.
class TestId extends StatelessWidget {
  const TestId(this.id, {required this.child, super.key});

  /// The accessibility identifier. Also used as the widget [Key] value.
  final String id;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: id,
      // `identifier` already forces its own SemanticsNode; `explicitChildNodes`
      // keeps the child's own semantics (labels, button-ness) from being merged
      // away into this node.
      explicitChildNodes: true,
      child: KeyedSubtree(key: Key(id), child: child),
    );
  }
}

extension TestIdX on Widget {
  /// `SomeWidget().withTestId(HomeKeys.todoList)` — the inline form, for use
  /// sites where wrapping would cost more indentation than it is worth.
  Widget withTestId(String id) => TestId(id, child: this);
}
