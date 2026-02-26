import 'dart:async';

import 'package:flutter/material.dart';

import '../models/home_models.dart';

/// Auto-scrolling hero banner with dot indicators.
/// Uses a plain [PageView] — no external packages required.
class HeroSlider extends StatefulWidget {
  const HeroSlider({
    super.key,
    required this.slides,
    this.height = 200,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.onActionTap,
  });

  final List<HeroSlide> slides;
  final double height;
  final Duration autoPlayInterval;

  /// Called with the slide's [actionRoute] when the CTA button is tapped.
  final void Function(String route)? onActionTap;

  @override
  State<HeroSlider> createState() => _HeroSliderState();
}

class _HeroSliderState extends State<HeroSlider> {
  late final PageController _controller;
  late Timer _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    // Start well into the virtual page list so we can scroll both ways.
    _controller = PageController(initialPage: _current);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (!mounted) return;
      final next = (_current + 1) % widget.slides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.slides.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) =>
                _SlideCard(slide: widget.slides[i], onActionTap: widget.onActionTap),
          ),
        ),
        const SizedBox(height: 12),
        _DotIndicators(count: widget.slides.length, current: _current),
      ],
    );
  }
}

// ── Single slide card ──────────────────────────────────────────────────────────
class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.slide, this.onActionTap});

  final HeroSlide slide;
  final void Function(String)? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: slide.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: slide.gradient.first.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    slide.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    slide.subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  if (slide.actionLabel != null) ...[
                    const SizedBox(height: 14),
                    _CTAButton(
                      label: slide.actionLabel!,
                      onTap: slide.actionRoute != null
                          ? () => onActionTap?.call(slide.actionRoute!)
                          : null,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Decorative icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(slide.icon, color: Colors.white, size: 36),
            ),
          ],
        ),
      ),
    );
  }
}

class _CTAButton extends StatelessWidget {
  const _CTAButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ),
    );
  }
}

// ── Dot indicators ─────────────────────────────────────────────────────────────
class _DotIndicators extends StatelessWidget {
  const _DotIndicators({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? color : color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
