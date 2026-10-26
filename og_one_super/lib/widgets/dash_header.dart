import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_strings.dart';
import '../screens/dashboard/core/dash_theme.dart';
import 'dash_common.dart';
import 'dash_search_box.dart';

/// Navy header used by every tab.
/// Pass [searchBox] to overlap a search field on the bottom edge
/// (Home and Apps). Leave it null for a plain header (Activity, Account).
class DashHeader extends StatelessWidget {
  static const double _overlap = 25;

  final String headline;
  final String subline;
  final VoidCallback onMenu;
  final VoidCallback onAiAgent;
  final DashSearchBox? searchBox;
  final double hPad;

  const DashHeader({
    super.key,
    required this.headline,
    required this.subline,
    required this.onMenu,
    required this.onAiAgent,
    required this.hPad,
    this.searchBox,
  });

  @override
  Widget build(BuildContext context) {
    final hasSearch = searchBox != null;

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
              bottom: hasSearch ? DashSearchBox.height - _overlap : 0),
          child: _banner(context, hasSearch ? _overlap + 16 : 22),
        ),
        if (hasSearch)
          Positioned(left: hPad, right: hPad, bottom: 0, child: searchBox!),
      ],
    );
  }

  Widget _ring(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.4),
        ),
      );

  Widget _banner(BuildContext context, double bottomInset) {
    final t = context.t;
    final compact = isCompact(context);
    final narrow = MediaQuery.sizeOf(context).width < 360;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: kHeaderGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kGold.withValues(alpha: 0.30),
                    kGold.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
              top: 50,
              right: 20,
              child: _ring(76, Colors.white.withValues(alpha: 0.08))),
          Positioned(
              bottom: 6,
              left: -50,
              child: _ring(140, Colors.white.withValues(alpha: 0.07))),
          Positioned(
            right: 18,
            bottom: bottomInset - 10,
            child: Icon(
              Icons.grid_view_rounded,
              size: 62,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, 8, hPad, bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SoftButton(
                        icon: Icons.menu_rounded,
                        tooltip: t.menu,
                        onTap: onMenu,
                        onDark: true,
                      ),
                      SizedBox(width: compact ? 8 : 10),
                      DashLogo(size: compact ? 32 : 36),
                      SizedBox(width: compact ? 8 : 10),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            t.appName,
                            maxLines: 1,
                            softWrap: false,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: compact ? 6 : 8),
                      _AiAgentButton(
                        compact: compact,
                        tooltip: '${t.aiAssistant} · ${t.comingSoon}',
                        onTap: onAiAgent,
                      ),
                    ],
                  ),
                  SizedBox(height: narrow ? 14 : 18),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      headline,
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: narrow ? 22 : 26,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 3.5,
                        height: 15,
                        decoration: BoxDecoration(
                          gradient: kGoldGradient,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFFFFD54F)
                                .withValues(alpha: 0.95),
                            fontSize: narrow ? 12 : 13,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiAgentButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;
  final bool compact;

  const _AiAgentButton({
    required this.tooltip,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(compact ? 14 : 22);

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: context.t.aiAgent,
        excludeSemantics: true,
        child: Container(
          decoration: BoxDecoration(
            gradient: kGoldGradient,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: kGold.withValues(alpha: 0.38),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: radius,
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              child: SizedBox(
                height: compact ? 40 : 36,
                width: compact ? 40 : null,
                child: compact
                    ? const Icon(Icons.auto_awesome_rounded,
                        size: 20, color: kNavy)
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome_rounded,
                                size: 16, color: kNavy),
                            const SizedBox(width: 5),
                            Text(
                              context.t.aiAgent,
                              maxLines: 1,
                              style: const TextStyle(
                                color: kNavy,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
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
