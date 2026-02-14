import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const double kWebMaxWidth = 800;

/// Web版で横幅を制限した showDialog ラッパー
Future<T?> showConstrainedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  TraversalEdgeBehavior? traversalEdgeBehavior,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    traversalEdgeBehavior: traversalEdgeBehavior,
    builder: (context) {
      final child = builder(context);
      if (kIsWeb) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kWebMaxWidth),
            child: child,
          ),
        );
      }
      return child;
    },
  );
}

/// Web版で横幅を制限した showModalBottomSheet ラッパー
Future<T?> showConstrainedModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
}) {
  final effectiveConstraints = kIsWeb
      ? BoxConstraints(
          maxWidth: kWebMaxWidth,
          minWidth: constraints?.minWidth ?? 0,
          maxHeight: constraints?.maxHeight ?? double.infinity,
          minHeight: constraints?.minHeight ?? 0,
        )
      : constraints;

  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    backgroundColor: backgroundColor,
    elevation: elevation,
    shape: shape,
    clipBehavior: clipBehavior,
    constraints: effectiveConstraints,
    barrierColor: barrierColor,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: showDragHandle,
    routeSettings: routeSettings,
    transitionAnimationController: transitionAnimationController,
    anchorPoint: anchorPoint,
  );
}
