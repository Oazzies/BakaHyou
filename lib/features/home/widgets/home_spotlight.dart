import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_rating_stars.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

/// The Home feed's hero: an auto-rotating showcase of the hottest series right
/// now. Every big discovery surface opens on one of these; ours cycles the top
/// trending titles so Home arrives on motion rather than a static rail.
class HomeSpotlight extends StatefulWidget {
  final List<Series> series;

  const HomeSpotlight({super.key, required this.series});

  @override
  State<HomeSpotlight> createState() => _HomeSpotlightState();
}

class _HomeSpotlightState extends State<HomeSpotlight> {
  static const double _height = 208;
  static const Duration _interval = Duration(seconds: 6);

  final PageController _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(HomeSpotlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The feed hands us a fresh list on refresh / filter changes; snap back to
    // the front so the rotation stays predictable.
    if (oldWidget.series.length != widget.series.length) {
      _page = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.series.length < 2) return;
    _timer = Timer.periodic(_interval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page + 1) % widget.series.length;
      _controller.animateToPage(
        next,
        duration: AppMotion.slow,
        curve: AppMotion.emphasized,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.series;
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.horizontalPadding,
        4,
        AppConstants.horizontalPadding,
        24,
      ),
      child: Column(
        children: [
          SizedBox(
            height: _height,
            // Pause the rotation while the reader is interacting, resume after.
            child: Listener(
              onPointerDown: (_) => _timer?.cancel(),
              onPointerUp: (_) => _startTimer(),
              child: PageView.builder(
                controller: _controller,
                itemCount: items.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _SpotlightCard(series: items[i]),
              ),
            ),
          ),
          if (items.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: AppMotion.base,
                  curve: AppMotion.emphasized,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 3,
                  width: active ? 22 : 8,
                  decoration: BoxDecoration(
                    color: active
                        ? AppConstants.accentColor
                        : AppConstants.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  final Series series;

  const _SpotlightCard({required this.series});

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final rating = double.tryParse(series.rating) ?? 0;
    final meta = <String>[
      if (series.type.isNotEmpty) _cap(series.type),
      if (series.year.isNotEmpty) series.year,
    ].join('  ·  ');

    return MbTappable(
      pressedScale: 0.98,
      onTap: () => Navigator.of(context).push(
        AppTransitions.slideUp(
          SeriesDetailScreen(series: series, heroTagPrefix: 'home_spotlight'),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: Container(
          color: AppConstants.tertiaryBackground,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // A blurred blow-up of the cover fills the frame; scrims from the
              // left and bottom carry the copy without burying the art.
              WidgetUtils.networkImage(
                url: series.coverUrl,
                fit: BoxFit.cover,
                blurred: true,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xEE0B0B0B), Color(0x000B0B0B)],
                    stops: [0.05, 0.7],
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xCC0B0B0B), Color(0x000B0B0B)],
                    stops: [0.0, 0.75],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('trending').toUpperCase(),
                      style: AppTypography.monoLabel(
                        color: AppConstants.accentColor,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 260,
                      child: Text(
                        series.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.display(
                          color: AppConstants.textColor,
                          fontSize: 22,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (meta.isNotEmpty)
                          Flexible(
                            child: Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.sans(
                                color: AppConstants.textMutedColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (meta.isNotEmpty && rating > 0)
                          Text(
                            '   ·   ',
                            style: AppTypography.sans(
                              color: AppConstants.textMutedColor,
                              fontSize: 12,
                            ),
                          ),
                        if (rating > 0)
                          MbRatingStars(
                            rating: rating,
                            outOf: 100,
                            fontSize: 12,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading placeholder for [HomeSpotlight] — mirrors its footprint so the feed
/// doesn't jump when the first trending payload lands.
class HomeSpotlightSkeleton extends StatelessWidget {
  const HomeSpotlightSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.horizontalPadding,
        4,
        AppConstants.horizontalPadding,
        24,
      ),
      child: Shimmer.fromColors(
        baseColor: AppConstants.tertiaryBackground,
        highlightColor: AppConstants.secondaryBackground,
        period: const Duration(milliseconds: 1400),
        child: Container(
          height: 208,
          decoration: BoxDecoration(
            color: AppConstants.tertiaryBackground,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          ),
        ),
      ),
    );
  }
}
