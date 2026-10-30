import 'package:flutter/material.dart';

/// Each mounted sheet owns its controller, including during Stack reordering.
class DliniiSheet extends StatefulWidget {
  const DliniiSheet({super.key, required this.builder});
  final Widget Function(BuildContext, ScrollController, VoidCallback) builder;
  @override
  State<DliniiSheet> createState() => _DliniiSheetState();
}

class _DliniiSheetState extends State<DliniiSheet> {
  final _controller = DraggableScrollableController();
  void _expand() {
    if (_controller.isAttached) {
      _controller.animateTo(
        .86,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    controller: _controller,
    initialChildSize: .30,
    minChildSize: .20,
    maxChildSize: .86,
    snap: true,
    snapSizes: const [.30, .60, .86],
    builder: (context, scroll) => widget.builder(context, scroll, _expand),
  );
}
