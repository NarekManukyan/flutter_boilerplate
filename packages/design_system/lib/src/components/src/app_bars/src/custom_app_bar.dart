import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../../design_system.dart';

class CustomAppBar extends HookWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.backgroundColor,
    this.title,
    this.bottom,
    this.titleSpacing = 0,
    this.toolbarHeight = kToolbarHeight,
    this.hasDivider = false,
    this.centerTitle = true,
    this.actions = const <Widget>[],
  });

  final Color? backgroundColor;
  final Widget? title;
  final Widget? bottom;
  final double? titleSpacing;
  final double toolbarHeight;
  final bool hasDivider;
  final bool centerTitle;
  final List<Widget> actions;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final appBarBottom = useMemoized(
      () {
        if (bottom != null) {
          return PreferredSize(
            preferredSize: Size.fromHeight(toolbarHeight),
            child: bottom!,
          );
        }

        if (hasDivider) {
          return PreferredSize(
            preferredSize: Size.fromHeight(toolbarHeight),
            child: const Divider(),
          );
        }
      },
      [bottom, context.isDarkMode],
    );

    return AppBar(
      backgroundColor: backgroundColor ?? context.backgroundSurface,
      iconTheme: const IconThemeData(size: 20),
      titleSpacing: titleSpacing,
      centerTitle: centerTitle,
      elevation: 0,
      bottom: appBarBottom,
      toolbarHeight: toolbarHeight,
      flexibleSpace: FlexibleSpaceBar(
        background:
            ColoredBox(color: backgroundColor ?? context.backgroundSurface),
      ),
      title: title == null
          ? null
          : DefaultTextStyle(
              style: context.labelLBold.setColor(context.textNeutral),
              child: title!,
            ),
      actions: [
        Row(
          children: [
            ...actions,
          ],
        ),
      ],
    );
  }
}
