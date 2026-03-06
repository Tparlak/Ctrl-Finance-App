import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/logo_fetcher.dart';
import '../../providers/logo_settings_provider.dart';

/// Displays a brand logo fetched from logo.dev, with category icon fallback.
/// Drop-in replacement for any icon container in transaction list items.
///
/// Usage:
///   LogoWidget(
///     description: transaction.description,
///     fallbackIcon: Icons.shopping_cart,
///     fallbackColor: Colors.orange,
///   )
class LogoWidget extends ConsumerWidget {
  final String description;
  final IconData fallbackIcon;
  final Color? fallbackColor;
  final double size;
  final double iconSize;

  const LogoWidget({
    required this.description,
    required this.fallbackIcon,
    this.fallbackColor,
    this.size = 40,
    this.iconSize = 20,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(logoSettingsProvider);
    final logoUrl = LogoFetcher.getLogoUrl(
      description: description,
      apiKey: settings.logoApiKey,
    );

    // No API key or domain unresolvable → show fallback immediately (zero network cost)
    if (logoUrl == null) {
      return _FallbackIcon(
        icon: fallbackIcon,
        color: fallbackColor,
        size: size,
        iconSize: iconSize,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          // While loading → show category icon (not a spinner)
          placeholder: (context, url) => _FallbackIcon(
            icon: fallbackIcon,
            color: fallbackColor,
            size: size,
            iconSize: iconSize,
          ),
          // 404 / network error → show category icon
          errorWidget: (context, url, error) {
            // Cache the failure so we don't retry on every rebuild
            LogoFetcher.markUnresolvable(description);
            return _FallbackIcon(
              icon: fallbackIcon,
              color: fallbackColor,
              size: size,
              iconSize: iconSize,
            );
          },
          useOldImageOnUrlChange: true,
          cacheManager: LogoCacheManager.instance,
        ),
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;
  final double iconSize;
  const _FallbackIcon({
    required this.icon,
    this.color,
    required this.size,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: isDark ? 0.15 : 0.12),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(icon, size: iconSize, color: effectiveColor),
    );
  }
}
