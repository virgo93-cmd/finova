import 'package:finova/core/services/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
    child: Column(
      children: [
        Icon(icon, size: 46, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(message, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 12), action!],
      ],
    ),
  );
}

class FinovaBannerAd extends StatefulWidget {
  const FinovaBannerAd({super.key, required this.enabled});
  final bool enabled;
  @override
  State<FinovaBannerAd> createState() => _FinovaBannerAdState();
}

class _FinovaBannerAdState extends State<FinovaBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;
  @override
  void initState() {
    super.initState();
    if (widget.enabled && AdConfig.releaseConfigured) {
      _ad = BannerAd(
        size: AdSize.banner,
        adUnitId: AdConfig.banner,
        listener: BannerAdListener(
          onAdLoaded: (_) => mounted ? setState(() => _loaded = true) : null,
          onAdFailedToLoad: (ad, _) {
            ad.dispose();
          },
        ),
        request: const AdRequest(),
      )..load();
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _loaded && _ad != null
      ? SizedBox(
          width: _ad!.size.width.toDouble(),
          height: _ad!.size.height.toDouble(),
          child: AdWidget(ad: _ad!),
        )
      : const SizedBox.shrink();
}
