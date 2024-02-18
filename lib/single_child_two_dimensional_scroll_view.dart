// Copyright 2024 by Scott Horn. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A box in which a single widget can be scrolled in two dimensions.
///
/// This widget is useful when you have a single box that will normally be
/// entirely visible, for example a clock face in a time picker, but you need to
/// make sure it can be scrolled if the container gets too small in two axes
///
/// Sometimes a layout is designed around the flexible properties of a
/// [Column] + [Row], but there is the concern that in some cases, there might
/// not be enough room to see the entire contents. This could be because some
/// devices have unusually small screens, a resized small (sometimes due to
/// virtual keyboard), or because the application can
/// be used in landscape mode where the aspect ratio isn't what was
/// originally envisioned, or because the application is being shown in a
/// small window in split-screen mode. In any case, as a result, it might
/// make sense to wrap the layout in a [SingleChildTwoDimensionalScrollView].
///
/// Doing so, however, usually results in a conflict between the [Column]/[Row],
/// which typically tries to grow as big as it can, and the
/// [SingleChildTowDimensional ScrollView], which provides its children with
/// an infinite amount of space.
///
/// To resolve this apparent conflict, there are a couple of techniques, as
/// discussed below.
///
/// ### Centering, spacing, or aligning fixed-height content
///
/// If the content has fixed (or intrinsic) dimensions but needs to be spaced out,
/// centered, or otherwise positioned using the [Flex] layout model of a [Column],
/// / [Row] the following technique can be used to provide the [Column] / [Row]
/// with a minimum dimension while allowing it to shrink-wrap the contents
/// when there isn't enough room to apply these spacing or alignment needs.
///
/// A [LayoutBuilder] is used to obtain the size of the viewport (implicit ly via
/// the constraints that the [SingleChildTwoDimensionalScrollView] sees,
/// since viewports typically grow to fit their maximum width/height constraint).
/// Then, inside the scroll view, a [ConstrainedBox] is used to set the minimum
/// height / width of the [Column] and or [Row].
///
/// The [Column] has no [Expanded] children, so rather than take on the infinite
/// height from its [BoxConstraints.maxHeight], (the viewport provides no maximum height
/// constraint), it automatically tries to shrink to fit its children. It cannot
/// be smaller than its [BoxConstraints.minHeight], though, and It therefore
/// becomes the bigger of the minimum height provided by the
/// [ConstrainedBox] and the sum of the heights of the children.
///
/// If the children aren't enough to fit that minimum size, the [Column] / [Row]
/// ends up with some remaining space to allocate as specified by its
/// [Column.mainAxisAlignment] / [Row.mainAxisAlignment] argument.
///
/// {@tool dartpad}
/// In this example, the child is able to scroll in two dimensions.
///
/// When using this technique, [Expanded] and [Flexible] are not useful, because
/// in both cases the "available space" is infinite (since this is in a viewport).
///
/// ** See code in examples/lib/main.dart **
/// {@end-tool}
///
class SingleChildTwoDimensionalScrollView extends StatelessWidget {
  /// Creates a box in which a single widget can be scrolled in two dimensions.
  const SingleChildTwoDimensionalScrollView({
    super.key,
    this.padding,
    this.reverseVertical = false,
    this.reverseHoritonal = false,
    this.primary,
    this.verticalPhysics,
    this.verticalController,
    this.horizontalPhysics,
    this.horizontalController,
    this.child,
    this.dragStartBehavior = DragStartBehavior.start,
    this.clipBehavior = Clip.hardEdge,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.diagonalDragBehavior = DiagonalDragBehavior.none,
  });

  /// The amount of space by which to inset the child.
  final EdgeInsetsGeometry? padding;

  /// Whether the vertical scroll view scrolls in the reading direction.
  ///
  /// For example, if the scroll view scrolls from top to bottom
  /// when [reverse] is false and from bottom to top when [reverse] is true.
  ///
  /// Defaults to false.
  final bool reverseVertical;

  /// Whether the scroll view scrolls in the reading direction.
  ///
  /// For example, if the reading direction is left-to-right then the scroll
  /// view scrolls from left to right when [reverse] is false and from right
  /// to left when [reverse] is true.
  ///
  /// Defaults to false.
  final bool reverseHoritonal;

  /// {@macro flutter.widgets.scroll_view.primary}
  final bool? primary;

  /// How the vertical scroll axis should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics? verticalPhysics;

  /// An object that can be used to control the position to which this vertical
  /// scroll axis is scrolled.
  ///
  /// Must be null if [primary] is true.
  ///
  /// A [ScrollController] serves several purposes. It can be used to control
  /// the initial scroll position (see [ScrollController.initialScrollOffset]).
  /// It can be used to control whether the scroll view should automatically
  /// save and restore its scroll position in the [PageStorage] (see
  /// [ScrollController.keepScrollOffset]). It can be used to read the current
  /// scroll position (see [ScrollController.offset]), or change it (see
  /// [ScrollController.animateTo]).
  final ScrollController? verticalController;

  // How the horizontal scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics? horizontalPhysics;

  /// An object that can be used to control the position to which this vertical
  /// scroll axis is scrolled.
  ///
  /// Must be null if [primary] is true.
  ///
  /// A [ScrollController] serves several purposes. It can be used to control
  /// the initial scroll position (see [ScrollController.initialScrollOffset]).
  /// It can be used to control whether the scroll view should automatically
  /// save and restore its scroll position in the [PageStorage] (see
  /// [ScrollController.keepScrollOffset]). It can be used to read the current
  /// scroll position (see [ScrollController.offset]), or change it (see
  /// [ScrollController.animateTo]).
  final ScrollController? horizontalController;

  /// The widget that scrolls in two dimensions.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// {@macro flutter.widgets.scroll_view.keyboardDismissBehavior}
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// {@macro flutter.widgets.scrollable.diagonalDragBehavior}
  final DiagonalDragBehavior diagonalDragBehavior;

  @override
  Widget build(BuildContext context) {
    Widget contents = child ?? const SizedBox.shrink();
    if (padding != null) {
      contents = Padding(padding: padding!, child: contents);
    }
    return _SingleChild2DScrollView(
      verticalDetails: ScrollableDetails.vertical(
        reverse: reverseVertical,
        physics: verticalPhysics,
        controller: verticalController,
        decorationClipBehavior: clipBehavior,
      ),
      horizontalDetails: ScrollableDetails.horizontal(
        reverse: reverseHoritonal,
        physics: horizontalPhysics,
        controller: horizontalController,
        decorationClipBehavior: clipBehavior,
      ),
      delegate:
          TwoDimensionalChildBuilderDelegate(builder: (_, __) => contents),
      primary: primary,
      keyboardDismissBehavior: keyboardDismissBehavior,
      clipBehavior: clipBehavior,
      diagonalDragBehavior: diagonalDragBehavior,
    );
  }
}

class _SingleChild2DScrollView extends TwoDimensionalScrollView {
  const _SingleChild2DScrollView({
    required super.verticalDetails,
    required super.horizontalDetails,
    required TwoDimensionalChildDelegate delegate,
    super.primary,
    super.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    super.clipBehavior = Clip.hardEdge,
    super.diagonalDragBehavior,
  }) : super(delegate: delegate);

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
  ) {
    return _SingleChild2DViewPort(
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalDetails.direction,
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalDetails.direction,
      delegate: delegate,
      mainAxis: mainAxis,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
    );
  }
}

class _SingleChild2DViewPort extends TwoDimensionalViewport {
  const _SingleChild2DViewPort({
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.delegate,
    required super.mainAxis,
    super.cacheExtent,
    super.clipBehavior = Clip.hardEdge,
  });

  @override
  _RenderSingleChild2DViewPort createRenderObject(BuildContext context) {
    return _RenderSingleChild2DViewPort(
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalAxisDirection,
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalAxisDirection,
      mainAxis: mainAxis,
      cacheExtent: cacheExtent,
      childManager: context as TwoDimensionalChildManager,
      clipBehavior: clipBehavior,
      delegate: delegate as TwoDimensionalChildBuilderDelegate,
    );
  }

  @override
  void updateRenderObject(BuildContext context,
      covariant _RenderSingleChild2DViewPort renderObject) {
    renderObject
      ..horizontalOffset = horizontalOffset
      ..horizontalAxisDirection = horizontalAxisDirection
      ..verticalOffset = verticalOffset
      ..verticalAxisDirection = verticalAxisDirection
      ..mainAxis = mainAxis
      ..cacheExtent = cacheExtent
      ..clipBehavior = clipBehavior
      ..delegate = delegate;
  }
}

class _RenderSingleChild2DViewPort extends RenderTwoDimensionalViewport {
  _RenderSingleChild2DViewPort({
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required TwoDimensionalChildBuilderDelegate delegate,
    required super.mainAxis,
    required super.cacheExtent,
    required super.childManager,
    required super.clipBehavior,
  }) : super(delegate: delegate);

  @override
  void layoutChildSequence() {
    const vicinity = ChildVicinity(xIndex: 0, yIndex: 0);
    final double offsetX = horizontalOffset.pixels;
    final double offsetY = verticalOffset.pixels;
    final double viewportWidth = viewportDimension.width;
    final double viewportHeight = viewportDimension.height;
    final RenderBox child = buildOrObtainChildFor(vicinity)!;

    child.layout(const BoxConstraints(), parentUsesSize: true);
    final parentChildData = parentDataOf(child);
    parentChildData.layoutOffset =
        _paintOffsetForOffset(child, Offset(offsetX, offsetY));
    horizontalOffset.applyContentDimensions(
        0, clampDouble(child.size.width - viewportWidth, 0, double.infinity));
    verticalOffset.applyContentDimensions(
        0, clampDouble(child.size.height - viewportHeight, 0, double.infinity));
  }

  Offset _paintOffsetForOffset(RenderBox child, Offset offset) {
    return switch ((horizontalAxisDirection, verticalAxisDirection)) {
      (AxisDirection.right, AxisDirection.down) =>
        Offset(-offset.dx, -offset.dy),
      (AxisDirection.right, AxisDirection.up) =>
        Offset(-offset.dx, offset.dy - child.size.height + size.height),
      (AxisDirection.left, AxisDirection.down) =>
        Offset(offset.dx - child.size.width + size.width, -offset.dy),
      (AxisDirection.left, AxisDirection.up) => Offset(
          offset.dx - child.size.width + size.width,
          offset.dy - child.size.height + size.height),
      _ => throw (Exception('invalid state for scrollabe')),
    };
  }

  void _paintChild(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    if (child != null) {
      final TwoDimensionalViewportParentData childParentData =
          parentDataOf(child);
      if (childParentData.isVisible) {
        context.paintChild(child, offset + childParentData.paintOffset!);
      }
    }
  }

  final LayerHandle<ClipRectLayer> _clipRectLayer =
      LayerHandle<ClipRectLayer>();

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    super.dispose();
  }

  bool _shouldClipAtPaintOffset(RenderBox child, Offset offset) {
    assert(firstChild != null);
    switch (clipBehavior) {
      case Clip.none:
        return false;
      case Clip.hardEdge:
      case Clip.antiAlias:
      case Clip.antiAliasWithSaveLayer:
        return offset.dx < 0 ||
            offset.dy < 0 ||
            offset.dx + child.size.width > size.width ||
            offset.dy + child.size.height > size.height;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = firstChild;
    if (child == null) return;
    final paintOffset = parentDataOf(child).paintOffset!;
    if (_shouldClipAtPaintOffset(child, paintOffset)) {
      _clipRectLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & viewportDimension,
        _paintChild,
        clipBehavior: clipBehavior,
        oldLayer: _clipRectLayer.layer,
      );
    } else {
      _clipRectLayer.layer = null;
      _paintChild(context, offset);
    }
  }
}
