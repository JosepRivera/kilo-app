import 'package:flutter/cupertino.dart';

import '../theme/forecast_palette.dart';

const _barHeight = 44.0;
const _largeTitleHeight = 52.0;
const _fadeExtra = 28.0;

class FadedHeaderScaffold extends StatefulWidget {
  const FadedHeaderScaffold({
    super.key,
    required this.title,
    required this.children,
    this.largeTitle = true,
    this.leading,
    this.trailing,
    this.bottomPadding = 120,
  });

  final String title;
  final List<Widget> children;
  final bool largeTitle;
  final Widget? leading;
  final Widget? trailing;
  final double bottomPadding;

  @override
  State<FadedHeaderScaffold> createState() => _FadedHeaderScaffoldState();
}

class _FadedHeaderScaffoldState extends State<FadedHeaderScaffold> {
  final _scroll = ScrollController();
  var _collapsed = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final collapsed = _scroll.offset > _largeTitleHeight - 8;
      if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final showSmallTitle = !widget.largeTitle || _collapsed;
    final navTitle = CupertinoTheme.of(context).textTheme.navTitleTextStyle
        .copyWith(color: p.text);
    final largeTitle = CupertinoTheme.of(context)
        .textTheme
        .navLargeTitleTextStyle
        .copyWith(color: p.text);

    return CupertinoPageScaffold(
      backgroundColor: p.background,
      child: Stack(
        children: [
          ListView(
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(
              16,
              top + _barHeight + 4,
              16,
              widget.bottomPadding,
            ),
            children: [
              if (widget.largeTitle)
                SizedBox(
                  height: _largeTitleHeight,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Semantics(
                      header: true,
                      child: Text(widget.title, style: largeTitle),
                    ),
                  ),
                ),
              if (widget.largeTitle) const SizedBox(height: 8),
              for (final (i, c) in widget.children.indexed) ...[
                if (i > 0) const SizedBox(height: 12),
                c,
              ],
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: top + _barHeight + _fadeExtra,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      p.background,
                      p.background,
                      p.background.withValues(alpha: 0),
                    ],
                    stops: [
                      0,
                      (top + _barHeight) / (top + _barHeight + _fadeExtra),
                      1,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: top,
            left: 8,
            right: 8,
            height: _barHeight,
            child: NavigationToolbar(
              leading: widget.leading,
              middle: AnimatedOpacity(
                opacity: showSmallTitle ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: ExcludeSemantics(
                  excluding: widget.largeTitle,
                  child: Text(widget.title, style: navTitle),
                ),
              ),
              trailing: widget.trailing,
            ),
          ),
        ],
      ),
    );
  }
}
