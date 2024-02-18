import 'package:flutter/material.dart';
import 'package:single_child_two_dimensional_scroll_view/'
    'single_child_two_dimensional_scroll_view.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ScrollController verticalScrollController = ScrollController();
  late final ScrollController horintalScrollController = ScrollController();
  late final key = GlobalKey();
  @override
  void dispose() {
    verticalScrollController.dispose();
    horintalScrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Example 2D Single Child Scroll View',
      home: Scaffold(
          body: Scrollbar(
        controller: verticalScrollController,
        child: Scrollbar(
          controller: horintalScrollController,
          child: SingleChildTwoDimensionalScrollView(
            verticalController: verticalScrollController,
            horizontalController: horintalScrollController,
            child: ColoredBox(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.blue,
                    width: 1500,
                    height: 1500,
                    child: Center(
                        child:
                            Text(List.filled(1400, 'hello world').join(' ')))),
              ),
            ),
          ),
        ),
      )),
    );
  }
}
