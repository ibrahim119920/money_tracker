import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/constants.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curved);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // ── BAGIAN ATAS ──────────────────────────────────────────────
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(AppRadius.prominent),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerLow,
                              borderRadius: AppRadius.cardBorder,
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              size: AppIconSize.prominent,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Money Tracker',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Catat. Kelola. Kendalikan.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            width: 80,
                            height: AppSpacing.xxs,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── BAGIAN TENGAH ────────────────────────────────────────────
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _FeatureItem(
                          icon: Icons.wallet_outlined,
                          label: 'Multi Dompet & Rekening',
                          description: 'Kelola semua akunmu dalam satu tempat',
                          showDivider: true,
                        ),
                        _FeatureItem(
                          icon: Icons.bar_chart_rounded,
                          label: 'Laporan Bulanan',
                          description:
                              'Pantau arus kas dengan grafik yang jelas',
                          showDivider: true,
                        ),
                        _FeatureItem(
                          icon: Icons.sync_rounded,
                          label: 'Sinkronisasi Cloud',
                          description: 'Data aman tersimpan di semua perangkat',
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── BAGIAN BAWAH ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    0,
                    AppSpacing.screenHorizontal,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: AppComponentHeight.interactive,
                        child: FilledButton(
                          onPressed: () => context.push(AppRoutes.register),
                          child: const Text('Mulai Sekarang'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        height: AppComponentHeight.interactive,
                        child: OutlinedButton(
                          onPressed: () => context.push(AppRoutes.login),
                          child: const Text(
                            'Masuk ke Akun',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Gratis selamanya · Tanpa iklan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.showDivider,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppIconSize.regular,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
      ],
    );
  }
}
