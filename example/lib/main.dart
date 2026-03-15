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
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    ScrollViewPage(),
    TableExamplePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '2D Scroll View Example',
      home: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_vert),
              label: 'Scroll',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.table_chart),
              label: 'Table',
            ),
          ],
        ),
      ),
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

/// A page demonstrating a table-like layout that scrolls in both dimensions.
///
/// The table is built using plain [Column] and [Row] widgets with fixed-size
/// [Container] cells. We cannot use [ListView.builder] (or any scrollable
/// widget such as [GridView]) for the inner content, because nesting a
/// scrollable inside [SingleChildTwoDimensionalScrollView] conflicts with
/// Flutter's scroll-physics negotiation — the inner scrollable would consume
/// the gesture before the outer 2-D scroll view ever sees it.
class TableExamplePage extends StatefulWidget {
  const TableExamplePage({super.key});

  @override
  State<TableExamplePage> createState() => _TableExamplePageState();
}

class _TableExamplePageState extends State<TableExamplePage> {
  static const int _rows = 50;
  static const int _columns = 20;
  static const double _cellWidth = 120;
  static const double _cellHeight = 48;

  late final ScrollController _verticalController = ScrollController();
  late final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  Widget _headerCell(int column) {
    return Container(
      width: _cellWidth,
      height: _cellHeight,
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        border: Border.all(color: Colors.blue.shade300),
      ),
      alignment: Alignment.center,
      child: Text(
        'Col ${column + 1}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _dataCell(int row, int column) {
    return Container(
      width: _cellWidth,
      height: _cellHeight,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      alignment: Alignment.center,
      child: Text('Row ${row + 1}, Col ${column + 1}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Table Example'),
      ),
      body: Scrollbar(
        controller: _verticalController,
        child: Scrollbar(
          controller: _horizontalController,
          child: SingleChildTwoDimensionalScrollView(
            verticalController: _verticalController,
            horizontalController: _horizontalController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    for (int c = 0; c < _columns; c++) _headerCell(c),
                  ],
                ),
                // Data rows
                for (int r = 0; r < _rows; r++)
                  Row(
                    children: [
                      for (int c = 0; c < _columns; c++) _dataCell(r, c),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
