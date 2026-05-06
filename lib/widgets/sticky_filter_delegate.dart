import 'package:flutter/material.dart';

class StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  StickyFilterDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => 50.0;

  @override
  double get minExtent => 50.0;

  @override
  bool shouldRebuild(covariant StickyFilterDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
