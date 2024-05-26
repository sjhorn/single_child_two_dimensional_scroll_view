# Single Child Two Dimensional Scroll View
[![Pub Package](https://img.shields.io/pub/v/single_child_two_dimensional_scroll_view.svg)](https://pub.dev/packages/single_child_two_dimensional_scroll_view)

[![GitHub Issues](https://img.shields.io/github/issues/sjhorn/single_child_two_dimensional_scroll_view.svg)](https://github.com/sjhorn/
single_child_two_dimensional_scroll_view/issues)

[![GitHub Forks](https://img.shields.io/github/forks/sjhorn/single_child_two_dimensional_scroll_view.svg)](https://github.com/sjhorn/
single_child_two_dimensional_scroll_view/network)

[![GitHub Stars](https://img.shields.io/github/stars/sjhorn/single_child_two_dimensional_scroll_view.svg)](https://github.com/sjhorn/
single_child_two_dimensional_scroll_view/stargazers)

![GitHub License](https://img.shields.io/github/license/sjhorn/single_child_two_dimensional_scroll_view)

A package that provides a widget that allows a single child to scroll in two dimensions, built on the two-dimensional foundation of the Flutter framework.

## Features

This package provides support for a SingleChildTwoDimensionalScrollView widget that scrolls in both the vertical and horizontal axes.

### SingleChildTwoDimensionalScrollView

`SingleChildTwoDimensionalScrollView` is insipired by [SingleChildScrollView](https://api.flutter.dev/flutter/widgets/SingleChildScrollView-class.html) API and based on [TwoDimensionalScrollView](https://pub.dev/packages/two_dimensional_scrollables).

- Scroll diagonally, or lock axes with the `diagonalDragBehavior` type. 

## Getting started

### Depend on it

Run this command with Flutter:

```sh
$ flutter pub add single_child_two_dimensional_scroll_view
```

### Import it

Now in your Dart code, you can use:

```sh
import 'package:single_child_two_dimensional_scroll_view/single_child_two_dimensional_scroll_view.dart';
```

## Usage

### SingleChildTwoDimensionalScrollView

The code in `example/` shows a `SingleChildTwoDimensionalScrollView` that allows a 2000 x 2000 pixel child scroll in two dimensions. 


## Additional information

The package uses the two-dimensional foundation from the Flutter framework,
meaning most of the core functionality of 2D scrolling is not implemented here.
This also means any subclass of the foundation can create different 2D scrolling
widgets and be added to the collection. If you want to contribute to
this package, you can open a pull request in [Flutter Packages](https://github.com/flutter/packages)
and add the tag "p: two_dimensional_scrollables".