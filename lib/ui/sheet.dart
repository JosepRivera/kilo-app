import 'package:flutter/cupertino.dart';

import '../theme/forecast_palette.dart';

const _sheetRadius = 38.0;
const _sheetInset = 8.0;

Future<T?> showFloatingSheet<T>(
  BuildContext context, {
  String? title,
  required WidgetBuilder builder,
}) => showCupertinoModalPopup<T>(
  context: context,
  builder: (context) => _FloatingSheet(title: title, child: builder(context)),
);

class _FloatingSheet extends StatelessWidget {
  const _FloatingSheet({required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _sheetInset,
        0,
        _sheetInset,
        bottom > 0 ? bottom * 0.4 : _sheetInset,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_sheetRadius),
        child: ColoredBox(
          color: p.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: p.track,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                SizedBox(
                  height: 52,
                  child: NavigationToolbar(
                    middle: title == null
                        ? null
                        : Text(
                            title!,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: p.text,
                            ),
                          ),
                    trailing: CircleButton(
                      icon: CupertinoIcons.xmark,
                      label: 'Cerrar',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CircleButton extends StatelessWidget {
  const CircleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.prominent = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final enabled = onPressed != null;
    final fill = prominent && enabled ? p.accent : p.track;
    final ink = prominent && enabled
        ? p.onAccent
        : (enabled ? p.text : p.muted);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        onPressed: onPressed,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: ink),
        ),
      ),
    );
  }
}

class AlertAction {
  const AlertAction(this.label, this.onPressed, {this.primary = false});

  final String label;
  final VoidCallback onPressed;
  final bool primary;
}

Future<void> showCapsuleAlert(
  BuildContext context, {
  required String title,
  required String message,
  required List<AlertAction> actions,
}) => showCupertinoDialog<void>(
  context: context,
  barrierDismissible: true,
  builder: (context) =>
      _CapsuleAlert(title: title, message: message, actions: actions),
);

class _CapsuleAlert extends StatelessWidget {
  const _CapsuleAlert({
    required this.title,
    required this.message,
    required this.actions,
  });

  final String title;
  final String message;
  final List<AlertAction> actions;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(34),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 30,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: p.text,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: p.muted,
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                for (final (i, a) in actions.indexed) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: CupertinoButton(
                      color: a.primary ? p.accent : p.track,
                      borderRadius: BorderRadius.circular(22),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onPressed: () {
                        Navigator.pop(context);
                        a.onPressed();
                      },
                      child: Text(
                        a.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: a.primary ? p.onAccent : p.text,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
