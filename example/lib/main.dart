import 'package:flutter/material.dart';
import 'package:single_child_two_dimensional_scroll_view/'
    'single_child_two_dimensional_scroll_view.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '2D Scroll View Example',
      home: ScrollViewPage(),
    );
  }
}

class ScrollViewPage extends StatefulWidget {
  const ScrollViewPage({super.key});

  @override
  State<ScrollViewPage> createState() => _ScrollViewPageState();
}

class _ScrollViewPageState extends State<ScrollViewPage> {
  late final ScrollController verticalScrollController = ScrollController();
  late final ScrollController horizontalScrollController = ScrollController();
  TextDirection _textDirection = TextDirection.ltr;

  @override
  void dispose() {
    verticalScrollController.dispose();
    horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2D Scroll View Example'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SegmentedButton<TextDirection>(
              segments: const [
                ButtonSegment(
                  value: TextDirection.ltr,
                  label: Text('LTR'),
                ),
                ButtonSegment(
                  value: TextDirection.rtl,
                  label: Text('RTL'),
                ),
              ],
              selected: {_textDirection},
              onSelectionChanged: (selected) {
                setState(() {
                  _textDirection = selected.first;
                });
              },
            ),
          ),
        ],
      ),
      body: Directionality(
        textDirection: _textDirection,
        child: Scrollbar(
          controller: verticalScrollController,
          child: Scrollbar(
            controller: horizontalScrollController,
            child: SingleChildTwoDimensionalScrollView(
              verticalController: verticalScrollController,
              horizontalController: horizontalScrollController,
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
                      child: Text(List.filled(1400, 'hello world').join(' ')),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
