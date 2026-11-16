import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../formatters.dart';

class AmountField extends StatefulWidget {
  const AmountField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.prefix,
    this.suffix,
    this.showLabel = true,
    this.autofocus = false,
    this.focusNode,
  });

  final String label;
  final double? value;
  final ValueChanged<double?> onChanged;
  final String? prefix;
  final String? suffix;
  final bool showLabel;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  static final _digits = FilteringTextInputFormatter.allow(RegExp('[0-9.,]'));

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _text(widget.value));
  }

  @override
  void didUpdateWidget(AmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != parseAmount(_controller.text)) {
      _controller.text = _text(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _text(double? value) => value == null ? '' : editableAmount(value);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.showLabel ? null : widget.label,
      child: TextField(
        controller: _controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [_digits],
        textAlign: TextAlign.end,
        onChanged: (text) => widget.onChanged(parseAmount(text)),
        decoration: InputDecoration(
          labelText: widget.showLabel ? widget.label : null,
          hintText: '0',
          prefixText: widget.prefix,
          suffixText: widget.suffix,
          isDense: true,
        ),
      ),
    );
  }
}
