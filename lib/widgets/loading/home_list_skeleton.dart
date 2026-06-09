import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';

final class HomeListSkeleton extends StatefulWidget {
  const HomeListSkeleton({super.key});

  @override
  State<HomeListSkeleton> createState() => _HomeListSkeletonState();
}

final class _HomeListSkeletonState extends State<HomeListSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
      value: 0.5,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _c.stop();
      _c.value = 0.5;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final a = 0.32 + _c.value * 0.28;
        return Padding(
          padding: AppSpacing.screenHV,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _bar(a, 0.55),
              const SizedBox(height: AppSpacing.lg),
              _bar(a, 0.92),
              const SizedBox(height: AppSpacing.cardGap),
              _bar(a, 1),
              const SizedBox(height: AppSpacing.cardGap),
              _bar(a, 1),
              const SizedBox(height: AppSpacing.cardGap),
              _bar(a, 0.85),
            ],
          ),
        );
      },
    );
  }

  Widget _bar(double alpha, double flex) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.slate700.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: DesignTokens.borderSubtle.withValues(alpha: 0.5),
        ),
      ),
      child: SizedBox(height: 88 * flex),
    );
  }
}
