import 'package:flutter/material.dart';

class CustomPopupMenuItem<T> extends PopupMenuItem<T> {
  const CustomPopupMenuItem({
    super.key,
    super.value,
    super.onTap,
    super.height,
    super.enabled,
    super.child,
    this.color,
  });
  final Color? color;

  @override
  CustomPopupMenuItemState<T> createState() => CustomPopupMenuItemState<T>();
}

class CustomPopupMenuItemState<T>
    extends PopupMenuItemState<T, CustomPopupMenuItem<T>> {
  @override
  Widget build(BuildContext context) => Material(
        borderOnForeground: false,
        color: widget.color,
        shadowColor: widget.color,
        child: super.build(context),
      );
}
