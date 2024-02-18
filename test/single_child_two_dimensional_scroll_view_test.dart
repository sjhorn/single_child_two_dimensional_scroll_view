import 'package:flutter_test/flutter_test.dart';

import 'package:single_child_two_dimensional_scroll_view/single_child_two_dimensional_scroll_view.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'rendering_tester.dart' show TestClipPaintingContext;
import 'semantics_tester.dart';

class TestScrollPosition extends ScrollPositionWithSingleContext {
  TestScrollPosition({
    required super.physics,
    required ScrollContext state,
    double super.initialPixels,
    super.oldPosition,
  }) : super(
          context: state,
        );
}

class TestScrollController extends ScrollController {
  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
      ScrollContext context, ScrollPosition? oldPosition) {
    return TestScrollPosition(
      physics: physics,
      state: context,
      initialPixels: initialScrollOffset,
      oldPosition: oldPosition,
    );
  }
}

Widget primaryScrollControllerBoilerplate(
    {required Widget child, required ScrollController controller}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: PrimaryScrollController(
        controller: controller,
        child: child,
      ),
    ),
  );
}

void main() {
  testWidgets('SingleChildTwoDimensionalScrollView overflow and clipRect test',
      (WidgetTester tester) async {
    // the test widowSize is Size(800.0, 600.0)
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildTwoDimensionalScrollView(
          child: SizedBox(width: 800.0, height: 600.0),
        ),
      ),
    );

    // 1st, check that the render object has received the default clip behavior.
    final dynamic renderObject = tester.allRenderObjects
        .where((RenderObject o) =>
            o.runtimeType.toString() == '_RenderSingleChild2DViewPort')
        .first;
    expect(renderObject.clipBehavior,
        equals(Clip.hardEdge)); // ignore: avoid_dynamic_calls

    // 2nd, height == window.height test: check that the painting context does not call pushClipRect .
    TestClipPaintingContext context = TestClipPaintingContext();
    renderObject.paint(context, Offset.zero); // ignore: avoid_dynamic_calls
    expect(context.clipBehavior, equals(Clip.none));

    // 3rd, height overflow test: check that the painting context call pushClipRect.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildTwoDimensionalScrollView(
          child: Container(height: 600.1),
        ),
      ),
    );
    renderObject.paint(context, Offset.zero); // ignore: avoid_dynamic_calls
    expect(context.clipBehavior, equals(Clip.hardEdge));

    // 4th, width == window.width test: check that the painting context do not call pushClipRect.
    context = TestClipPaintingContext();
    expect(context.clipBehavior, equals(Clip.none)); // initial value
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildTwoDimensionalScrollView(
          child: Container(width: 800.0),
        ),
      ),
    );
    renderObject.paint(context, Offset.zero); // ignore: avoid_dynamic_calls
    expect(context.clipBehavior, equals(Clip.none));

    // 5th, width overflow test: check that the painting context call pushClipRect.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildTwoDimensionalScrollView(
          child: Container(width: 800.1),
        ),
      ),
    );
    renderObject.paint(context, Offset.zero); // ignore: avoid_dynamic_calls
    expect(context.clipBehavior, equals(Clip.hardEdge));
  });

  testWidgets('SingleChildTwoDimensionalScrollView respects clipBehavior',
      (WidgetTester tester) async {
    await tester.pumpWidget(
        SingleChildTwoDimensionalScrollView(child: Container(height: 2000.0)));

    // 1st, check that the render object has received the default clip behavior.
    final dynamic renderObject = tester.allRenderObjects
        .where((RenderObject o) =>
            o.runtimeType.toString() == '_RenderSingleChild2DViewPort')
        .first;
    expect(renderObject.clipBehavior,
        equals(Clip.hardEdge)); // ignore: avoid_dynamic_calls

    // 2nd, check that the painting context has received the default clip behavior.
    final TestClipPaintingContext context = TestClipPaintingContext();
    renderObject.paint(context, Offset.zero); // ignore: avoid_dynamic_calls
    expect(context.clipBehavior, equals(Clip.hardEdge));

    // 3rd, check that the underlying Scrollable(s) have the same clipBehavior
    // Regression test for https://github.com/flutter/flutter/issues/133330
    Finder scrollable =
        find.byWidgetPredicate((Widget widget) => widget is Scrollable);
    expect(
      (tester.widgetList(scrollable).first as Scrollable).clipBehavior,
      Clip.hardEdge,
    );
    expect(
      (tester.widgetList(scrollable).last as Scrollable).clipBehavior,
      Clip.hardEdge,
    );

    // 4th, pump a new widget to check that the render object can update its clip behavior.
    await tester.pumpWidget(SingleChildTwoDimensionalScrollView(
        clipBehavior: Clip.antiAlias, child: Container(height: 2000.0)));
    expect(renderObject.clipBehavior,
        equals(Clip.antiAlias)); // ignore: avoid_dynamic_calls

    // 5th, check that a non-default clip behavior can be sent to the painting context.
    renderObject.paint(context, Offset.zero); // ignore: avoid_dynamic_calls
    expect(context.clipBehavior, equals(Clip.antiAlias));

    // 6th, check that the underlying Scrollable has the same clipBehavior
    // Regression test for https://github.com/flutter/flutter/issues/133330
    scrollable =
        find.byWidgetPredicate((Widget widget) => widget is Scrollable);
    expect(
      (tester.widgetList(scrollable).first as Scrollable).clipBehavior,
      Clip.antiAlias,
    );
    expect(
      (tester.widgetList(scrollable).last as Scrollable).clipBehavior,
      Clip.antiAlias,
    );
  });

  testWidgets('SingleChildTwoDimensionalScrollView control test',
      (WidgetTester tester) async {
    await tester.pumpWidget(SingleChildTwoDimensionalScrollView(
      child: Container(
        height: 2000.0,
        color: const Color(0xFF00FF00),
      ),
    ));

    final RenderBox box = tester.renderObject(find.byType(Container));
    expect(box.localToGlobal(Offset.zero), equals(Offset.zero));

    await tester.drag(find.byType(SingleChildTwoDimensionalScrollView),
        const Offset(0.0, -200.0));
    await tester.pumpAndSettle();
    expect(box.localToGlobal(Offset.zero), equals(const Offset(0.0, -200.0)));
  });

  testWidgets('Changing controllers changes scroll position',
      (WidgetTester tester) async {
    final TestScrollController verticalController = TestScrollController();
    final TestScrollController horizontalController = TestScrollController();
    addTearDown(verticalController.dispose);
    addTearDown(horizontalController.dispose);

    await tester.pumpWidget(SingleChildTwoDimensionalScrollView(
      child: Container(
        height: 2000.0,
        color: const Color(0xFF00FF00),
      ),
    ));

    await tester.pumpWidget(SingleChildTwoDimensionalScrollView(
      verticalController: verticalController,
      horizontalController: horizontalController,
      child: Container(
        height: 2000.0,
        color: const Color(0xFF00FF00),
      ),
    ));

    final TwoDimensionalScrollableState scrollable =
        tester.state(find.byType(TwoDimensionalScrollable));
    expect(scrollable.verticalScrollable.position, isA<TestScrollPosition>());
    expect(scrollable.horizontalScrollable.position, isA<TestScrollPosition>());
  });

  testWidgets('Sets PrimaryScrollController when primary',
      (WidgetTester tester) async {
    final ScrollController primaryScrollController = ScrollController();
    addTearDown(primaryScrollController.dispose);
    await tester.pumpWidget(PrimaryScrollController(
      controller: primaryScrollController,
      child: SingleChildTwoDimensionalScrollView(
        primary: true,
        child: Container(
          height: 2000.0,
          color: const Color(0xFF00FF00),
        ),
      ),
    ));

    final TwoDimensionalScrollable scrollable =
        tester.widget(find.byType(TwoDimensionalScrollable));
    expect(scrollable.verticalDetails.controller, primaryScrollController);
  });

  testWidgets(
      'Changing scroll controller inside dirty layout builder does not assert',
      (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(Center(
      child: SizedBox(
        width: 750.0,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildTwoDimensionalScrollView(
              child: Container(
                height: 2000.0,
                color: const Color(0xFF00FF00),
              ),
            );
          },
        ),
      ),
    ));

    await tester.pumpWidget(Center(
      child: SizedBox(
        width: 700.0,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildTwoDimensionalScrollView(
              verticalController: controller,
              child: Container(
                height: 2000.0,
                color: const Color(0xFF00FF00),
              ),
            );
          },
        ),
      ),
    ));
  });

  testWidgets('SingleChildTwoDimensionalScrollView are not primary by default',
      (WidgetTester tester) async {
    const SingleChildTwoDimensionalScrollView view =
        SingleChildTwoDimensionalScrollView();
    expect(view.primary, isNull);
  });

  testWidgets(
      'SingleChildTwoDimensionalScrollView with controllers are not primary by default',
      (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);
    final view = SingleChildTwoDimensionalScrollView(
      verticalController: controller,
    );
    expect(view.primary, isNull);
  });

  testWidgets(
      'SingleChildScrollViews use PrimaryScrollController by default on mobile',
      (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(primaryScrollControllerBoilerplate(
      child: const SingleChildTwoDimensionalScrollView(),
      controller: controller,
    ));
    expect(controller.hasClients, isTrue);
  }, variant: TargetPlatformVariant.mobile());

  testWidgets(
      "Vertical SingleChildScrollViews don't use PrimaryScrollController by default on desktop",
      (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(primaryScrollControllerBoilerplate(
      child: const SingleChildTwoDimensionalScrollView(),
      controller: controller,
    ));
    expect(controller.hasClients, isFalse);
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('Nested scrollables have a null PrimaryScrollController',
      (WidgetTester tester) async {
    const Key innerKey = Key('inner');
    final ScrollController primaryScrollController = ScrollController();
    addTearDown(primaryScrollController.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PrimaryScrollController(
          controller: primaryScrollController,
          child: SingleChildTwoDimensionalScrollView(
            primary: true,
            child: Container(
              constraints:
                  const BoxConstraints(maxHeight: 200.0, maxWidth: 200.0),
              child: ListView(key: innerKey, primary: true),
            ),
          ),
        ),
      ),
    );

    final Scrollable innerScrollable = tester.widget(
      find.descendant(
        of: find.byKey(innerKey),
        matching: find.byType(Scrollable),
      ),
    );
    expect(innerScrollable.controller, isNull);
  });

  // testWidgets('SingleChildTwoDimensionalScrollView semantics',
  //   (WidgetTester tester) async {
  // final SemanticsTester semantics = SemanticsTester(tester);
  // final ScrollController controller = ScrollController();
  // addTearDown(controller.dispose);

  // await tester.pumpWidget(
  //   Directionality(
  //     textDirection: TextDirection.ltr,
  //     child: SingleChildTwoDimensionalScrollView(
  //       verticalController: controller,
  //       child: Column(
  //         children: List<Widget>.generate(30, (int i) {
  //           return SizedBox(
  //             height: 200.0,
  //             width: 200.0,
  //             child: Text('Tile $i'),
  //           );
  //         }),
  //       ),
  //     ),
  //   ),
  // );

  // List<TestSemantics> generateSemanticsChildren(
  //     {int startHidden = -1, int endHidden = 30}) {
  //   final List<TestSemantics> children = <TestSemantics>[];
  //   for (int index = 0; index < 30; index += 1) {
  //     final bool isHidden = index <= startHidden || index >= endHidden;
  //     children.add(TestSemantics(
  //       label: 'Tile $index',
  //       textDirection: TextDirection.ltr,
  //       flags: isHidden ? const <SemanticsFlag>[SemanticsFlag.isHidden] : 0,
  //     ));
  //   }
  //   return children;
  // }

  // expect(
  //     semantics,
  //     hasSemantics(
  //       TestSemantics(
  //         children: <TestSemantics>[
  //           TestSemantics(
  //             flags: <SemanticsFlag>[
  //               SemanticsFlag.hasImplicitScrolling,
  //             ],
  //             actions: <SemanticsAction>[
  //               SemanticsAction.scrollUp,
  //             ],
  //             children: generateSemanticsChildren(endHidden: 3),
  //           ),
  //         ],
  //       ),
  //       ignoreRect: true,
  //       ignoreTransform: true,
  //       ignoreId: true,
  //     ));

  // controller.jumpTo(3000.0);
  // await tester.pumpAndSettle();

  // expect(
  //     semantics,
  //     hasSemantics(
  //       TestSemantics(
  //         children: <TestSemantics>[
  //           TestSemantics(
  //             flags: <SemanticsFlag>[
  //               SemanticsFlag.hasImplicitScrolling,
  //             ],
  //             actions: <SemanticsAction>[
  //               SemanticsAction.scrollUp,
  //               SemanticsAction.scrollDown,
  //             ],
  //             children:
  //                 generateSemanticsChildren(startHidden: 14, endHidden: 18),
  //           ),
  //         ],
  //       ),
  //       ignoreRect: true,
  //       ignoreTransform: true,
  //       ignoreId: true,
  //     ));

  // controller.jumpTo(6000.0);
  // await tester.pumpAndSettle();

  // expect(
  //     semantics,
  //     hasSemantics(
  //       TestSemantics(
  //         children: <TestSemantics>[
  //           TestSemantics(
  //             flags: <SemanticsFlag>[
  //               SemanticsFlag.hasImplicitScrolling,
  //             ],
  //             actions: <SemanticsAction>[
  //               SemanticsAction.scrollDown,
  //             ],
  //             children: generateSemanticsChildren(startHidden: 26),
  //           ),
  //         ],
  //       ),
  //       ignoreRect: true,
  //       ignoreTransform: true,
  //       ignoreId: true,
  //     ));

  //   semantics.dispose();
  // });

  // testWidgets('SingleChildScrollView semantics clips cover entire child vertical', (WidgetTester tester) async {
  //   final ScrollController controller = ScrollController();
  //   addTearDown(controller.dispose);
  //   final UniqueKey scrollView = UniqueKey();
  //   final UniqueKey childBox = UniqueKey();
  //   const double length = 10000;
  //   await tester.pumpWidget(
  //     Directionality(
  //       textDirection: TextDirection.ltr,
  //       child: SingleChildScrollView(
  //         key: scrollView,
  //         controller: controller,
  //         child: SizedBox(key: childBox, height: length),
  //       ),
  //     ),
  //   );
  //   final RenderObject scrollRenderObject = tester.renderObject(find.byKey(scrollView));
  //   RenderAbstractViewport? viewport;
  //   void findsRenderViewPort(RenderObject child) {
  //     if (viewport != null) {
  //       return;
  //     }
  //     if (child is RenderAbstractViewport) {
  //       viewport = child;
  //       return;
  //     }
  //     child.visitChildren(findsRenderViewPort);
  //   }
  //   scrollRenderObject.visitChildren(findsRenderViewPort);
  //   expect(viewport, isNotNull);
  //   final RenderObject childRenderObject = tester.renderObject(find.byKey(childBox));
  //   Rect semanticsClip = viewport!.describeSemanticsClip(childRenderObject)!;
  //   expect(semanticsClip.size.height, length);

  //   controller.jumpTo(2000);
  //   await tester.pump();
  //   semanticsClip = viewport!.describeSemanticsClip(childRenderObject)!;
  //   expect(semanticsClip.size.height, length);
  // });

  // testWidgets('SingleChildScrollView semantics clips cover entire child', (WidgetTester tester) async {
  //   final ScrollController controller = ScrollController();
  //   addTearDown(controller.dispose);
  //   final UniqueKey scrollView = UniqueKey();
  //   final UniqueKey childBox = UniqueKey();
  //   const double length = 10000;
  //   await tester.pumpWidget(
  //     Directionality(
  //       textDirection: TextDirection.ltr,
  //       child: SingleChildScrollView(
  //         key: scrollView,
  //         scrollDirection: Axis.horizontal,
  //         controller: controller,
  //         child: SizedBox(key: childBox, width: length),
  //       ),
  //     ),
  //   );
  //   final RenderObject scrollRenderObject = tester.renderObject(find.byKey(scrollView));
  //   RenderAbstractViewport? viewport;
  //   void findsRenderViewPort(RenderObject child) {
  //     if (viewport != null) {
  //       return;
  //     }
  //     if (child is RenderAbstractViewport) {
  //       viewport = child;
  //       return;
  //     }
  //     child.visitChildren(findsRenderViewPort);
  //   }
  //   scrollRenderObject.visitChildren(findsRenderViewPort);
  //   expect(viewport, isNotNull);
  //   final RenderObject childRenderObject = tester.renderObject(find.byKey(childBox));
  //   Rect semanticsClip = viewport!.describeSemanticsClip(childRenderObject)!;
  //   expect(semanticsClip.size.width, length);

  //   controller.jumpTo(2000);
  //   await tester.pump();
  //   semanticsClip = viewport!.describeSemanticsClip(childRenderObject)!;
  //   expect(semanticsClip.size.width, length);
  // });

  testWidgets(
      'SingleChildTwoDimensionalScrollView getOffsetToReveal - will not assert on axis mismatch',
      (WidgetTester tester) async {
    final ScrollController controller =
        ScrollController(initialScrollOffset: 300.0);
    addTearDown(controller.dispose);
    List<Widget> children;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            height: 200.0,
            width: 300.0,
            child: SingleChildTwoDimensionalScrollView(
              verticalController: controller,
              child: Column(
                children: children = List<Widget>.generate(20, (int i) {
                  return SizedBox(
                    height: 100.0,
                    width: 300.0,
                    child: Text('Tile $i'),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );

    final RenderAbstractViewport viewport =
        tester.allRenderObjects.whereType<RenderAbstractViewport>().first;

    final RenderObject target = tester.renderObject(find.byWidget(children[5]));
    viewport.getOffsetToReveal(target, 0.0, axis: Axis.horizontal);
  });

  testWidgets('SingleChildTwoDimensionalScrollView getOffsetToReveal - down',
      (WidgetTester tester) async {
    final ScrollController controller =
        ScrollController(initialScrollOffset: 300.0);
    addTearDown(controller.dispose);
    List<Widget> children;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            height: 200.0,
            width: 300.0,
            child: SingleChildTwoDimensionalScrollView(
              verticalController: controller,
              child: Column(
                children: children = List<Widget>.generate(20, (int i) {
                  return SizedBox(
                    height: 100.0,
                    width: 300.0,
                    child: Text('Tile $i'),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );

    final RenderAbstractViewport viewport =
        tester.allRenderObjects.whereType<RenderAbstractViewport>().first;

    final RenderObject target = tester.renderObject(find.byWidget(children[5]));
    RevealedOffset revealed = viewport.getOffsetToReveal(target, 0.0);
    expect(revealed.offset, 500.0);
    expect(revealed.rect, const Rect.fromLTWH(0.0, 0.0, 300.0, 100.0));

    revealed = viewport.getOffsetToReveal(target, 1.0);
    expect(revealed.offset, 400.0);
    expect(revealed.rect, const Rect.fromLTWH(0.0, 100.0, 300.0, 100.0));

    revealed = viewport.getOffsetToReveal(target, 0.0,
        rect: const Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
    expect(revealed.offset, 540.0);
    expect(revealed.rect, const Rect.fromLTWH(40.0, 0.0, 10.0, 10.0));

    revealed = viewport.getOffsetToReveal(target, 1.0,
        rect: const Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
    expect(revealed.offset, 350.0);
    expect(revealed.rect, const Rect.fromLTWH(40.0, 190.0, 10.0, 10.0));
  });

  // testWidgets('SingleChildTwoDimensionalScrollView getOffsetToReveal - up',
  //     (WidgetTester tester) async {
  //   final ScrollController controller =
  //       ScrollController(initialScrollOffset: 300.0);
  //   addTearDown(controller.dispose);
  //   final List<Widget> children = List<Widget>.generate(20, (int i) {
  //     return SizedBox(
  //       height: 100.0,
  //       width: 300.0,
  //       child: Text('Tile $i'),
  //     );
  //   });
  //   await tester.pumpWidget(
  //     Directionality(
  //       textDirection: TextDirection.ltr,
  //       child: Center(
  //         child: SizedBox(
  //           height: 200.0,
  //           width: 300.0,
  //           child: SingleChildTwoDimensionalScrollView(
  //             verticalController: controller,
  //             reverseVertical: true,
  //             child: Column(
  //               children: children.reversed.toList(),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   final RenderAbstractViewport viewport =
  //       tester.allRenderObjects.whereType<RenderAbstractViewport>().first;

  //   final RenderObject target = tester.renderObject(find.byWidget(children[5]));
  //   RevealedOffset revealed = viewport.getOffsetToReveal(target, 0.0);
  //   expect(revealed.offset, 500.0);
  //   expect(revealed.rect, const Rect.fromLTWH(0.0, 100.0, 300.0, 100.0));

  //   revealed = viewport.getOffsetToReveal(target, 1.0);
  //   expect(revealed.offset, 400.0);
  //   expect(revealed.rect, const Rect.fromLTWH(0.0, 0.0, 300.0, 100.0));

  //   revealed = viewport.getOffsetToReveal(target, 0.0,
  //       rect: const Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
  //   expect(revealed.offset, 550.0);
  //   expect(revealed.rect, const Rect.fromLTWH(40.0, 190.0, 10.0, 10.0));

  //   revealed = viewport.getOffsetToReveal(target, 1.0,
  //       rect: const Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
  //   expect(revealed.offset, 360.0);
  //   expect(revealed.rect, const Rect.fromLTWH(40.0, 0.0, 10.0, 10.0));
  // });

  // testWidgets('SingleChildScrollView getOffsetToReveal - right', (WidgetTester tester) async {
  //   final ScrollController controller = ScrollController(initialScrollOffset: 300.0);
  //   addTearDown(controller.dispose);
  //   List<Widget> children;

  //   await tester.pumpWidget(
  //     Directionality(
  //       textDirection: TextDirection.ltr,
  //       child: Center(
  //         child: SizedBox(
  //           height: 300.0,
  //           width: 200.0,
  //           child: SingleChildScrollView(
  //             scrollDirection: Axis.horizontal,
  //             controller: controller,
  //             child: Row(
  //               children: children = List<Widget>.generate(20, (int i) {
  //                 return SizedBox(
  //                   height: 300.0,
  //                   width: 100.0,
  //                   child: Text('Tile $i'),
  //                 );
  //               }),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   final RenderAbstractViewport viewport = tester.allRenderObjects.whereType<RenderAbstractViewport>().first;

  //   final RenderObject target = tester.renderObject(find.byWidget(children[5]));
  //   RevealedOffset revealed = viewport.getOffsetToReveal(target, 0.0);
  //   expect(revealed.offset, 500.0);
  //   expect(revealed.rect, const Rect.fromLTWH(0.0, 0.0, 100.0, 300.0));

  //   revealed = viewport.getOffsetToReveal(target, 1.0);
  //   expect(revealed.offset, 400.0);
  //   expect(revealed.rect, const Rect.fromLTWH(100.0, 0.0, 100.0, 300.0));

  //   revealed = viewport.getOffsetToReveal(target, 0.0, rect: const Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
  //   expect(revealed.offset, 540.0);
  //   expect(revealed.rect, const Rect.fromLTWH(0.0, 40.0, 10.0, 10.0));

  //   revealed = viewport.getOffsetToReveal(target, 1.0, rect: const Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
  //   expect(revealed.offset, 350.0);
  //   expect(revealed.rect, const Rect.fromLTWH(190.0, 40.0, 10.0, 10.0));
  // });

  // testWidgets('SingleChildScrollView getOffsetToReveal - left', (WidgetTester tester) async {
  //   final ScrollController controller = ScrollController(initialScrollOffset: 300.0);
  //   addTearDown(controller.dispose);
  //   final List<Widget> children = List<Widget>.generate(20, (int i) {
  //     return SizedBox(
  //       height: 300.0,
  //       width: 100.0,
  //       child: Text('Tile $i'),
  //     );
  //   });

  //   await tester.pumpWidget(
  //     Directionality(
  //       textDirection: TextDirection.ltr,
  //       child: Center(
  //         child: SizedBox(
  //           height: 300.0,
  //           width: 200.0,
  //           child: SingleChildScrollView(
  //             scrollDirection: Axis.horizontal,
  //             reverse: true,
  //             controller: controller,
  //             child: Row(
  //               children: children.reversed.toList(),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   final RenderAbstractViewport viewport = tester.allRenderObjects.whereType<RenderAbstractViewport>().first;

  //   final RenderObject target = tester.renderObject(find.byWidget(children[5]));
  //   RevealedOffset revealed = viewport.getOffsetToReveal(target, 0.0);
  //   expect(revealed.offset, 500.0);
  //   expect(revealed.rect, const Rect.fromLTWH(100.0, 0.0, 100.0, 300.0));

  //   revealed = viewport.getOffsetToReveal(target, 1.0);
  //   expect(revealed.offset, 400.0);
  //   expect(revealed.rect, const Rect.fromLTWH(0.0, 0.0, 100.0, 300.0));

  //   revealed = viewport.getOffsetToReveal(target, 0.0, rect: const Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
  //   expect(revealed.offset, 550.0);
  //   expect(revealed.rect, const Rect.fromLTWH(190.0, 40.0, 10.0, 10.0));

  //   revealed = viewport.getOffsetToReveal(target, 1.0, rect: const Rect.fromLTWH(40.0, 40.0, 10.0, 10.0));
  //   expect(revealed.offset, 360.0);
  //   expect(revealed.rect, const Rect.fromLTWH(0.0, 40.0, 10.0, 10.0));
  // });

  // testWidgets('Nested SingleChildScrollView showOnScreen', (WidgetTester tester) async {
  //   final List<List<Widget>> children = List<List<Widget>>.generate(10, (int x) {
  //     return List<Widget>.generate(10, (int y) {
  //       return SizedBox(
  //         key: UniqueKey(),
  //         height: 100.0,
  //         width: 100.0,
  //       );
  //     });
  //   });
  //   late ScrollController controllerX;
  //   addTearDown(() => controllerX.dispose());
  //   late ScrollController controllerY;
  //   addTearDown(() => controllerY.dispose());

  //   /// Builds a gird:
  //   ///
  //   ///       <- x ->
  //   ///   0 1 2 3 4 5 6 7 8 9
  //   /// 0 c c c c c c c c c c
  //   /// 1 c c c c c c c c c c
  //   /// 2 c c c c c c c c c c
  //   /// 3 c c c c c c c c c c  y
  //   /// 4 c c c c v v c c c c
  //   /// 5 c c c c v v c c c c
  //   /// 6 c c c c c c c c c c
  //   /// 7 c c c c c c c c c c
  //   /// 8 c c c c c c c c c c
  //   /// 9 c c c c c c c c c c
  //   ///
  //   /// Each c is a 100x100 container, v are containers visible in initial
  //   /// viewport.

  //   await tester.pumpWidget(
  //     Directionality(
  //       textDirection: TextDirection.ltr,
  //       child: Center(
  //         child: SizedBox(
  //           height: 200.0,
  //           width: 200.0,
  //           child: SingleChildScrollView(
  //             controller: controllerY = ScrollController(initialScrollOffset: 400.0),
  //             child: SingleChildScrollView(
  //               controller: controllerX = ScrollController(initialScrollOffset: 400.0),
  //               scrollDirection: Axis.horizontal,
  //               child: Column(
  //                 children: children.map((List<Widget> widgets) {
  //                   return Row(
  //                     children: widgets,
  //                   );
  //                 }).toList(),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   expect(controllerX.offset, 400.0);
  //   expect(controllerY.offset, 400.0);

  //   // Already in viewport
  //   tester.renderObject(find.byWidget(children[4][4])).showOnScreen();
  //   await tester.pumpAndSettle();
  //   expect(controllerX.offset, 400.0);
  //   expect(controllerY.offset, 400.0);

  //   controllerX.jumpTo(400.0);
  //   controllerY.jumpTo(400.0);
  //   await tester.pumpAndSettle();

  //   // Above viewport
  //   tester.renderObject(find.byWidget(children[3][4])).showOnScreen();
  //   await tester.pumpAndSettle();
  //   expect(controllerX.offset, 400.0);
  //   expect(controllerY.offset, 300.0);

  //   controllerX.jumpTo(400.0);
  //   controllerY.jumpTo(400.0);
  //   await tester.pumpAndSettle();

  //   // Below viewport
  //   tester.renderObject(find.byWidget(children[6][4])).showOnScreen();
  //   await tester.pumpAndSettle();
  //   expect(controllerX.offset, 400.0);
  //   expect(controllerY.offset, 500.0);

  //   controllerX.jumpTo(400.0);
  //   controllerY.jumpTo(400.0);
  //   await tester.pumpAndSettle();

  //   // Left of viewport
  //   tester.renderObject(find.byWidget(children[4][3])).showOnScreen();
  //   await tester.pumpAndSettle();
  //   expect(controllerX.offset, 300.0);
  //   expect(controllerY.offset, 400.0);

  //   controllerX.jumpTo(400.0);
  //   controllerY.jumpTo(400.0);
  //   await tester.pumpAndSettle();

  //   // Right of viewport
  //   tester.renderObject(find.byWidget(children[4][6])).showOnScreen();
  //   await tester.pumpAndSettle();
  //   expect(controllerX.offset, 500.0);
  //   expect(controllerY.offset, 400.0);

  //   controllerX.jumpTo(400.0);
  //   controllerY.jumpTo(400.0);
  //   await tester.pumpAndSettle();

  //   // Above and left of viewport
  //   tester.renderObject(find.byWidget(children[3][3])).showOnScreen();
  //   await tester.pumpAndSettle();
  //   expect(controllerX.offset, 300.0);
  //   expect(controllerY.offset, 300.0);

  //   controllerX.jumpTo(400.0);
  //   controllerY.jumpTo(400.0);
  //   await tester.pumpAndSettle();

  //   // Below and left of viewport
  //   tester.renderObject(find.byWidget(children[6][3])).showOnScreen();
  //   await tester.pumpAndSettle();
  //   expect(controllerX.offset, 300.0);
  //   expect(controllerY.offset, 500.0);

  //   controllerX.jumpTo(400.0);
  //   controllerY.jumpTo(400.0);
  //   await tester.pumpAndSettle();

  //   // Above and right of viewport
  //   tester.renderObject(find.byWidget(children[3][6])).showOnScreen();
  //   await tester.pumpAndSettle();
  //   expect(controllerX.offset, 500.0);
  //   expect(controllerY.offset, 300.0);

  //   controllerX.jumpTo(400.0);
  //   controllerY.jumpTo(400.0);
  //   await tester.pumpAndSettle();

  //   // Below and right of viewport
  //   tester.renderObject(find.byWidget(children[6][6])).showOnScreen();
  //   await tester.pumpAndSettle();
  //   expect(controllerX.offset, 500.0);
  //   expect(controllerY.offset, 500.0);

  //   controllerX.jumpTo(400.0);
  //   controllerY.jumpTo(400.0);
  //   await tester.pumpAndSettle();

  //   // Below and right of viewport with animations
  //   tester.renderObject(find.byWidget(children[6][6])).showOnScreen(duration: const Duration(seconds: 2));
  //   await tester.pump();
  //   await tester.pump(const Duration(seconds: 1));
  //   expect(tester.hasRunningAnimations, isTrue);
  //   expect(controllerX.offset, greaterThan(400.0));
  //   expect(controllerX.offset, lessThan(500.0));
  //   expect(controllerY.offset, greaterThan(400.0));
  //   expect(controllerY.offset, lessThan(500.0));
  //   await tester.pumpAndSettle();
  //   expect(controllerX.offset, 500.0);
  //   expect(controllerY.offset, 500.0);
  // });

  // group('Nested SingleChildScrollView (same orientation) showOnScreen', () {
  //   late List<Widget> children;

  //   Future<void> buildNestedScroller({ required WidgetTester tester, ScrollController? inner, ScrollController? outer }) {
  //     return tester.pumpWidget(
  //       Directionality(
  //         textDirection: TextDirection.ltr,
  //         child: Center(
  //           child: SizedBox(
  //             height: 200.0,
  //             width: 300.0,
  //             child: SingleChildScrollView(
  //               controller: outer,
  //               child: Column(
  //                 children: <Widget>[
  //                   const SizedBox(
  //                     height: 200.0,
  //                   ),
  //                   SizedBox(
  //                     height: 200.0,
  //                     width: 300.0,
  //                     child: SingleChildScrollView(
  //                       controller: inner,
  //                       child: Column(
  //                         children: children = List<Widget>.generate(10, (int i) {
  //                           return SizedBox(
  //                             height: 100.0,
  //                             width: 300.0,
  //                             child: Text('$i'),
  //                           );
  //                         }),
  //                       ),
  //                     ),
  //                   ),
  //                   const SizedBox(
  //                     height: 200.0,
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //   }

  //   testWidgets('in view in inner, but not in outer', (WidgetTester tester) async {
  //     final ScrollController inner = ScrollController();
  //     addTearDown(inner.dispose);
  //     final ScrollController outer = ScrollController();
  //     addTearDown(outer.dispose);
  //     await buildNestedScroller(
  //       tester: tester,
  //       inner: inner,
  //       outer: outer,
  //     );
  //     expect(outer.offset, 0.0);
  //     expect(inner.offset, 0.0);

  //     tester.renderObject(find.byWidget(children[0])).showOnScreen();
  //     await tester.pumpAndSettle();
  //     expect(inner.offset, 0.0);
  //     expect(outer.offset, 100.0);
  //   });

  //   testWidgets('not in view of neither inner nor outer', (WidgetTester tester) async {
  //     final ScrollController inner = ScrollController();
  //     addTearDown(inner.dispose);
  //     final ScrollController outer = ScrollController();
  //     addTearDown(outer.dispose);
  //     await buildNestedScroller(
  //       tester: tester,
  //       inner: inner,
  //       outer: outer,
  //     );
  //     expect(outer.offset, 0.0);
  //     expect(inner.offset, 0.0);

  //     tester.renderObject(find.byWidget(children[5])).showOnScreen();
  //     await tester.pumpAndSettle();
  //     expect(inner.offset, 400.0);
  //     expect(outer.offset, 200.0);
  //   });

  //   testWidgets('in view in inner and outer', (WidgetTester tester) async {
  //     final ScrollController inner = ScrollController(initialScrollOffset: 200.0);
  //     addTearDown(inner.dispose);
  //     final ScrollController outer = ScrollController(initialScrollOffset: 200.0);
  //     addTearDown(outer.dispose);
  //     await buildNestedScroller(
  //       tester: tester,
  //       inner: inner,
  //       outer: outer,
  //     );
  //     expect(outer.offset, 200.0);
  //     expect(inner.offset, 200.0);

  //     tester.renderObject(find.byWidget(children[2])).showOnScreen();
  //     await tester.pumpAndSettle();
  //     expect(outer.offset, 200.0);
  //     expect(inner.offset, 200.0);
  //   });

  //   testWidgets('inner shown in outer, but item not visible', (WidgetTester tester) async {
  //     final ScrollController inner = ScrollController(initialScrollOffset: 200.0);
  //     addTearDown(inner.dispose);
  //     final ScrollController outer = ScrollController(initialScrollOffset: 200.0);
  //     addTearDown(outer.dispose);
  //     await buildNestedScroller(
  //       tester: tester,
  //       inner: inner,
  //       outer: outer,
  //     );
  //     expect(outer.offset, 200.0);
  //     expect(inner.offset, 200.0);

  //     tester.renderObject(find.byWidget(children[5])).showOnScreen();
  //     await tester.pumpAndSettle();
  //     expect(outer.offset, 200.0);
  //     expect(inner.offset, 400.0);
  //   });

  //   testWidgets('inner half shown in outer, item only visible in inner', (WidgetTester tester) async {
  //     final ScrollController inner = ScrollController();
  //     addTearDown(inner.dispose);
  //     final ScrollController outer = ScrollController(initialScrollOffset: 100.0);
  //     addTearDown(outer.dispose);
  //     await buildNestedScroller(
  //       tester: tester,
  //       inner: inner,
  //       outer: outer,
  //     );
  //     expect(outer.offset, 100.0);
  //     expect(inner.offset, 0.0);

  //     tester.renderObject(find.byWidget(children[1])).showOnScreen();
  //     await tester.pumpAndSettle();
  //     expect(outer.offset, 200.0);
  //     expect(inner.offset, 0.0);
  //   });
  // });

  // testWidgets('keyboardDismissBehavior tests', (WidgetTester tester) async {
  //   final List<FocusNode> focusNodes = List<FocusNode>.generate(50, (int i) => FocusNode());
  //   addTearDown(() {
  //     for (final FocusNode node in focusNodes) {
  //       node.dispose();
  //     }
  //   });

  //   Future<void> boilerplate(ScrollViewKeyboardDismissBehavior behavior) {
  //     return tester.pumpWidget(
  //       MaterialApp(
  //         home: Scaffold(
  //           body: SingleChildScrollView(
  //             padding: EdgeInsets.zero,
  //             keyboardDismissBehavior: behavior,
  //             child: Column(
  //               children: focusNodes.map((FocusNode focusNode) {
  //                 return SizedBox(
  //                   height: 50,
  //                   child: TextField(focusNode: focusNode),
  //                 );
  //               }).toList(),
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //   }

  //   // ScrollViewKeyboardDismissBehavior.onDrag dismiss keyboard on drag
  //   await boilerplate(ScrollViewKeyboardDismissBehavior.onDrag);

  //   Finder finder = find.byType(TextField).first;
  //   TextField textField = tester.widget(finder);
  //   await tester.showKeyboard(finder);
  //   expect(textField.focusNode!.hasFocus, isTrue);

  //   await tester.drag(finder, const Offset(0.0, -40.0));
  //   await tester.pumpAndSettle();
  //   expect(textField.focusNode!.hasFocus, isFalse);

  //   // ScrollViewKeyboardDismissBehavior.manual does no dismiss the keyboard
  //   await boilerplate(ScrollViewKeyboardDismissBehavior.manual);

  //   finder = find.byType(TextField).first;
  //   textField = tester.widget(finder);
  //   await tester.showKeyboard(finder);
  //   expect(textField.focusNode!.hasFocus, isTrue);

  //   await tester.drag(finder, const Offset(0.0, -40.0));
  //   await tester.pumpAndSettle();
  //   expect(textField.focusNode!.hasFocus, isTrue);
  // });
}