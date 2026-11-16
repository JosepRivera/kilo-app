import 'dart:async';

import 'package:material_ui/material_ui.dart';

class ElapsedLabel extends StatefulWidget {
  const ElapsedLabel({super.key, required this.since});

  final DateTime since;

  @override
  State<ElapsedLabel> createState() => _ElapsedLabelState();
}

class _ElapsedLabelState extends State<ElapsedLabel> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = DateTime.now().difference(widget.since).inSeconds;
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    final theme = Theme.of(context);
    return Text(
      '$minutes:$rest',
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
