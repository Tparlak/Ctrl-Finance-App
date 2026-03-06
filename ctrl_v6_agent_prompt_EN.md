# CTRL FINANCE APP — v6.2 AUTONOMOUS LOGO ENGINE
## For: Antigravity IDE Autonomous Agent
## Target Repo: https://github.com/Tparlak/Ctrl-Finance-App
## Builds on: v5.0 (Phases 1-17 assumed complete)

---

## ⚠️ CRITICAL PRE-READ — API REALITY CHECK

The prompt originally referenced **Clearbit Logo API** (`logo.clearbit.com`).

> **Clearbit Logo API was permanently shut down on December 8, 2025. It returns errors for all requests as of today (March 2026). DO NOT implement it.**

The correct modern replacement is **logo.dev** — the officially recommended migration path from Clearbit themselves. It is free for up to 500,000 requests/month (far more than a personal app needs), requires a **publishable API key** (safe for mobile client-side use), and explicitly supports Android/iOS mobile apps.

**Architecture decision:** The key is user-provided (stored in app settings), making the feature optional and zero-cost to the user.

---

## ⚠️ AGENT PRIME DIRECTIVES (PHASE 18 SPECIFIC)

1. **Read all existing transaction-related files before touching anything.**
2. **The logo engine is purely additive** — zero changes to existing transaction logic, Hive models, or providers.
3. **No new Hive models needed** — logo URLs are cached on-disk by `cached_network_image`, not in Hive.
4. **Graceful degradation is non-negotiable** — if logo fails for ANY reason, the existing category icon shows. The user must never see a broken UI.
5. **Performance guard** — never fire a logo request on every `build()` call. Cache URL strings in memory with a `Map<String, String?>` lookup table.
6. **Turkish merchant intelligence** — the domain resolution algorithm must understand Turkish brand names (e.g., "Şok Market" → `sokmarket.com.tr`).
7. After completion: `flutter analyze` must show zero errors.

---

## PRE-FLIGHT: READ THESE FILES FIRST

```bash
# Find transaction list item widget
find lib -name "*transaction*item*" -o -name "*transaction*tile*" -o -name "*transaction*card*" | sort

# Find transaction model
find lib -name "*transaction*model*" -o -name "*transaction*.dart" | grep -v ".g.dart" | sort

# Find category model (to understand icon system)
find lib -name "*category*" | grep -v ".g.dart" | sort

# Read the transaction list item file completely
cat <path_found_above>/transaction_list_item.dart

# Check existing pubspec for any logo/image packages already present
grep -E "cached_network|logo|image" pubspec.yaml
```

---

## PHASE 18 — AUTONOMOUS LOGO ENGINE

### 18A. Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  cached_network_image: ^3.4.1    # On-device logo caching
  # http is already added in Phase 13 — do NOT add again
```

Run: `flutter pub get`

### 18B. API Key Storage in App Settings

The logo.dev publishable key is stored in the app's settings — this means it's optional. If the user hasn't entered a key, the engine falls back to category icons immediately.

Add to the existing settings provider (find it with `grep -r "SharedPreferences\|settings" lib --include="*.dart" -l`):

```dart
// Add to SettingsProvider (or create lib/providers/settings_provider.dart if none exists):

class SettingsProvider extends ChangeNotifier {
  static const _logoKeyPref = 'logo_dev_api_key';
  String _logoApiKey = '';

  String get logoApiKey => _logoApiKey;
  bool get logoEnabled => _logoApiKey.trim().isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _logoApiKey = prefs.getString(_logoKeyPref) ?? '';
    notifyListeners();
  }

  Future<void> setLogoApiKey(String key) async {
    _logoApiKey = key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_logoKeyPref, _logoApiKey);
    notifyListeners();
  }
}
```

Register `SettingsProvider` in `main.dart` MultiProvider if it doesn't exist yet.

### 18C. Turkish Merchant Domain Resolver

This is the core intelligence of the engine. Create `lib/data/services/logo_fetcher.dart`:

```dart
import 'package:flutter/foundation.dart';

/// Resolves a transaction description to a logo.dev URL.
/// Returns null if resolution is not possible (triggers fallback to category icon).
class LogoFetcher {
  // ── In-memory cache: description → resolved domain (or null if unresolvable) ──
  static final Map<String, String?> _domainCache = {};

  // ── logo.dev CDN base ────────────────────────────────────────────────────────
  static const _base = 'https://img.logo.dev';

  // ──────────────────────────────────────────────────────────────────────────────
  // PUBLIC: Get the logo URL for a transaction description.
  // Returns null → caller should show category icon fallback.
  // apiKey: the logo.dev publishable key (pk_...) from settings.
  // ──────────────────────────────────────────────────────────────────────────────
  static String? getLogoUrl({
    required String description,
    required String apiKey,
  }) {
    if (apiKey.isEmpty) return null;
    if (description.trim().isEmpty) return null;

    final cacheKey = description.toLowerCase().trim();

    // Return cached result immediately (including null for known-unresolvable)
    if (_domainCache.containsKey(cacheKey)) {
      final domain = _domainCache[cacheKey];
      if (domain == null) return null;
      return '$_base/$domain?token=$apiKey&size=64&format=png';
    }

    // Resolve domain from description
    final domain = _resolveDomain(cacheKey);
    _domainCache[cacheKey] = domain; // cache even null results

    if (domain == null) return null;
    return '$_base/$domain?token=$apiKey&size=64&format=png';
  }

  /// Clear the in-memory cache (call on settings change)
  static void clearCache() => _domainCache.clear();

  // ──────────────────────────────────────────────────────────────────────────────
  // DOMAIN RESOLUTION ALGORITHM
  // Priority: 1. Known Turkish brands → 2. Generic normalization
  // ──────────────────────────────────────────────────────────────────────────────
  static String? _resolveDomain(String description) {
    // 1. Exact match in known Turkish/global brand dictionary
    final known = _knownBrands[description];
    if (known != null) return known;

    // 2. Partial match — check if description CONTAINS a known brand name
    for (final entry in _knownBrands.entries) {
      if (description.contains(entry.key)) return entry.value;
    }

    // 3. Generic normalization for unknown brands
    // Only attempt if description looks like a brand name (not generic like "Market alışveriş")
    final normalized = _normalizeToLikelyDomain(description);
    return normalized; // may be null if normalization fails heuristic checks
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // KNOWN TURKISH + GLOBAL BRAND DICTIONARY
  // Add more entries as needed. Keys are lowercase normalized.
  // ──────────────────────────────────────────────────────────────────────────────
  static const Map<String, String> _knownBrands = {
    // ── Supermarkets / Grocery ────────────────────────────────────────────────
    'şok':                    'sokmarket.com.tr',
    'sok market':             'sokmarket.com.tr',
    'şok market':             'sokmarket.com.tr',
    'a101':                   'a101.com.tr',
    'bim':                    'bim.com.tr',
    'migros':                 'migros.com.tr',
    'carrefour':              'carrefoursa.com.tr',
    'carrefoursa':            'carrefoursa.com.tr',
    'metro':                  'metro-cc.com.tr',
    'metro market':           'metro-cc.com.tr',
    'hakmar':                 'hakmar.com.tr',
    'file market':            'filemarket.com.tr',
    'onur market':            'onurmarket.com.tr',
    'macro':                  'macrocenter.com.tr',
    'macrocenter':            'macrocenter.com.tr',
    'özdilek':                'ozdilek.com.tr',

    // ── Fast Food / Restaurants ───────────────────────────────────────────────
    'mcdonalds':              'mcdonalds.com.tr',
    'mc donalds':             'mcdonalds.com.tr',
    'burger king':            'burgerking.com.tr',
    'kfc':                    'kfc.com.tr',
    'pizza hut':              'pizzahut.com.tr',
    'dominos':                'dominos.com.tr',
    'domino\'s':              'dominos.com.tr',
    'subway':                 'subway.com',
    'starbucks':              'starbucks.com.tr',
    'kahve dünyası':          'kahvedunyasi.com.tr',
    'caffè nero':             'caffenero.com.tr',
    'gloria jeans':           'gloriajeanscoffees.com.tr',
    'simit sarayı':           'simitsarayi.com',
    'popeyes':                'popeyes.com',
    'arby\'s':                'arbys.com.tr',

    // ── Fuel Stations ─────────────────────────────────────────────────────────
    'opet':                   'opet.com.tr',
    'shell':                  'shell.com.tr',
    'bp':                     'bp.com.tr',
    'petrol ofisi':           'petrolofisi.com.tr',
    'po':                     'petrolofisi.com.tr',
    'total':                  'totalenergies.com.tr',
    'lukoil':                 'lukoil.com.tr',
    'hayaloil':               'hayaloil.com.tr',

    // ── Banks / Finance ───────────────────────────────────────────────────────
    'akbank':                 'akbank.com',
    'garanti':                'garantibbva.com.tr',
    'garantibbva':            'garantibbva.com.tr',
    'ziraat':                 'ziraatbank.com.tr',
    'ziraat bankası':         'ziraatbank.com.tr',
    'halkbank':               'halkbank.com.tr',
    'vakıfbank':              'vakifbank.com.tr',
    'vakifbank':              'vakifbank.com.tr',
    'yapı kredi':             'yapikredi.com.tr',
    'yapikredi':              'yapikredi.com.tr',
    'qnb finansbank':         'qnbfinansbank.com',
    'finansbank':             'qnbfinansbank.com',
    'enpara':                 'enpara.com',
    'papara':                 'papara.com',
    'odeabank':               'odeabank.com.tr',
    'denizbank':              'denizbank.com',
    'teb':                    'teb.com.tr',
    'türkiye ekonomi bankası':'teb.com.tr',
    'hsbc':                   'hsbc.com.tr',
    'citibank':               'citibank.com.tr',
    'ing bank':               'ingbank.com.tr',
    'ingbank':                'ingbank.com.tr',
    'ptt bank':               'pttbank.com.tr',
    'kuveyt türk':            'kuveytturk.com.tr',

    // ── Telecom ───────────────────────────────────────────────────────────────
    'turkcell':               'turkcell.com.tr',
    'vodafone':               'vodafone.com.tr',
    'türk telekom':           'turktelekom.com.tr',
    'türktelekom':            'turktelekom.com.tr',
    'superonline':            'superonline.net',

    // ── Utilities ─────────────────────────────────────────────────────────────
    'tedaş':                  'tedas.gov.tr',
    'başkent doğalgaz':       'baskentgaz.com.tr',
    'igdaş':                  'igdas.com.tr',
    'iski':                   'iski.istanbul',
    'kocaeli su':             'isaski.gov.tr',
    'isaski':                 'isaski.gov.tr',
    'enerjisa':               'enerjisa.com.tr',
    'akenerji':               'akenerji.com.tr',

    // ── E-commerce / Delivery ─────────────────────────────────────────────────
    'trendyol':               'trendyol.com',
    'hepsiburada':            'hepsiburada.com',
    'amazon':                 'amazon.com.tr',
    'n11':                    'n11.com',
    'gittigidiyor':           'gittigidiyor.com',
    'çiçeksepeti':            'ciceksepeti.com',
    'morhipo':                'morhipo.com',
    'boyner':                 'boyner.com.tr',
    'lcw':                    'lcw.com',
    'lc waikiki':             'lcw.com',
    'koton':                  'koton.com',
    'zara':                   'zara.com',
    'h&m':                    'hm.com',
    'mango':                  'mango.com',
    'pull&bear':              'pullandbear.com',

    // ── Delivery Apps ─────────────────────────────────────────────────────────
    'yemeksepeti':            'yemeksepeti.com',
    'trendyol go':            'trendyol.com',
    'getir':                  'getir.com',
    'banabi':                 'banabi.com.tr',
    'mavi':                   'mavi.com',

    // ── Healthcare ────────────────────────────────────────────────────────────
    'eczane':                 'eczanebul.com',    // generic fallback
    'dr. max':                'drmax.com.tr',
    'seçkin eczane':          'seckineczane.com.tr',

    // ── Insurance ─────────────────────────────────────────────────────────────
    'axa sigorta':            'axa.com.tr',
    'allianz':                'allianz.com.tr',
    'mapfre':                 'mapfre.com.tr',
    'türkiye sigorta':        'turkiyesigorta.com.tr',
    'ray sigorta':            'raysigorta.com.tr',

    // ── Global Tech / Subscriptions ───────────────────────────────────────────
    'netflix':                'netflix.com',
    'spotify':                'spotify.com',
    'youtube':                'youtube.com',
    'google':                 'google.com',
    'apple':                  'apple.com',
    'microsoft':              'microsoft.com',
    'steam':                  'steampowered.com',
    'playstation':            'playstation.com',
    'xbox':                   'xbox.com',
    'discord':                'discord.com',
    'zoom':                   'zoom.us',
    'dropbox':                'dropbox.com',
    'adobe':                  'adobe.com',

    // ── Transport ─────────────────────────────────────────────────────────────
    'uber':                   'uber.com',
    'bitaksi':                'bitaksi.com',
    'turk hava yolları':      'turkishairlines.com',
    'thy':                    'turkishairlines.com',
    'pegasus':                'flypgs.com',
    'sunexpress':             'sunexpress.com',
    'anadolujet':             'anadolujet.com',

    // ── Education ─────────────────────────────────────────────────────────────
    'udemy':                  'udemy.com',
    'coursera':               'coursera.org',
    'duolingo':               'duolingo.com',

    // ── Other Turkish Brands ──────────────────────────────────────────────────
    'ikea':                   'ikea.com.tr',
    'mediamarkt':             'mediamarkt.com.tr',
    'teknosa':                'teknosa.com',
    'vatan bilgisayar':       'vatanbilgisayar.com',
    'd&r':                    'dr.com.tr',
    'kitapyurdu':             'kitapyurdu.com',
    'decathlon':              'decathlon.com.tr',
    'intersport':             'intersport.com.tr',
    'çankaya':                'cankayanet.com.tr', // example
    'sahibinden':             'sahibinden.com',
    'emlakjet':               'emlakjet.com',
  };

  // ──────────────────────────────────────────────────────────────────────────────
  // GENERIC NORMALIZATION
  // Converts "Migros Kocaeli" → "migros.com.tr" via heuristics.
  // Returns null if the description doesn't look like a recognizable brand.
  // ──────────────────────────────────────────────────────────────────────────────
  static String? _normalizeToLikelyDomain(String input) {
    // Remove Turkish stop words and location suffixes
    final stopWords = [
      'market', 'markets', 'mağaza', 'mağazası', 'şubesi', 'şube',
      'istanbul', 'ankara', 'izmir', 'kocaeli', 'bursa', 'gebze',
      'a.ş', 'a.ş.', 'ltd', 'sti', 'ştı', 'şti.',
      'kargo', 'teslimat', 'ödeme', 'fatura', 'alışveriş',
      'no:', 'no.', '#',
    ];

    String cleaned = input;
    for (final word in stopWords) {
      cleaned = cleaned.replaceAll(word, '').trim();
    }

    // Normalize Turkish characters
    cleaned = _normalizeTurkish(cleaned).trim();

    // Remove non-alphanumeric except spaces
    cleaned = cleaned.replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();

    // Reject if too short or looks generic
    if (cleaned.length < 3) return null;
    if (cleaned.split(' ').length > 3) return null; // too many words = description not a brand

    // Collapse spaces and build domain candidate
    final domainBase = cleaned.replaceAll(' ', '');

    // Try .com.tr first (Turkish brands), then .com
    // We return the candidate and let logo.dev 404 handle the rest
    return '$domainBase.com.tr';
  }

  static String _normalizeTurkish(String s) {
    return s
        .replaceAll('ş', 's').replaceAll('ğ', 'g').replaceAll('ü', 'u')
        .replaceAll('ö', 'o').replaceAll('ı', 'i').replaceAll('ç', 'c')
        .replaceAll('Ş', 's').replaceAll('Ğ', 'g').replaceAll('Ü', 'u')
        .replaceAll('Ö', 'o').replaceAll('İ', 'i').replaceAll('Ç', 'c');
  }
}
```

### 18D. LogoWidget — The Core Reusable Widget

Create `lib/presentation/widgets/logo_widget.dart`:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/logo_fetcher.dart';
import '../../providers/settings_provider.dart';

/// Displays a brand logo fetched from logo.dev, with category icon fallback.
/// Drop-in replacement for any Icon widget in transaction list items.
///
/// Usage:
///   LogoWidget(
///     description: transaction.description,
///     fallbackIcon: Icons.shopping_cart,
///     fallbackColor: Colors.orange,
///   )
class LogoWidget extends StatelessWidget {
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
    this.iconSize = 22,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final apiKey = context.select<SettingsProvider, String>((s) => s.logoApiKey);
    final logoUrl = LogoFetcher.getLogoUrl(description: description, apiKey: apiKey);

    // No API key or domain unresolvable → show fallback immediately (zero network cost)
    if (logoUrl == null) return _FallbackIcon(icon: fallbackIcon, color: fallbackColor, size: size, iconSize: iconSize);

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25), // subtle rounding
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          // While loading → show category icon (not a spinner, feels instant)
          placeholder: (context, url) =>
              _FallbackIcon(icon: fallbackIcon, color: fallbackColor, size: size, iconSize: iconSize),
          // 404 / network error → show category icon
          errorWidget: (context, url, error) {
            // Cache the failure so we don't retry on every rebuild
            LogoFetcher.markUnresolvable(description);
            return _FallbackIcon(icon: fallbackIcon, color: fallbackColor, size: size, iconSize: iconSize);
          },
          // Keep stale cache until fresh load completes (smooth UX)
          useOldImageOnUrlChange: true,
          // Cache for 30 days
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
  const _FallbackIcon({required this.icon, this.color, required this.size, required this.iconSize});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.primary).withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(icon, size: iconSize, color: color ?? Theme.of(context).colorScheme.primary),
    );
  }
}
```

### 18E. Custom Cache Manager (30-day TTL)

Add to `lib/data/services/logo_fetcher.dart` (append at the end of the file):

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// ── Custom cache manager — logos cached for 30 days ──────────────────────────
class LogoCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'ctrl_logos';
  static final LogoCacheManager _instance = LogoCacheManager._();
  static LogoCacheManager get instance => _instance;

  LogoCacheManager._()
      : super(Config(
          key,
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 500,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ));
}
```

Also add `markUnresolvable` to `LogoFetcher` class:

```dart
/// Called by LogoWidget error handler to prevent retry storms
static void markUnresolvable(String description) {
  _domainCache[description.toLowerCase().trim()] = null;
}
```

**Note:** `flutter_cache_manager` is a transitive dependency of `cached_network_image` — no separate pubspec entry needed.

### 18F. Integrate LogoWidget into Transaction List Item

Find the existing transaction list item file (identified in pre-flight). Replace the existing icon/avatar widget with `LogoWidget`. The pattern to find and replace:

```dart
// BEFORE — find any of these patterns:
Icon(categoryIcon, ...)
CircleAvatar(child: Icon(...))
Container(child: Icon(Icons.someIcon, ...))

// AFTER — replace with:
LogoWidget(
  description: transaction.description,
  fallbackIcon: transaction.categoryIcon,   // adjust to match actual field name
  fallbackColor: transaction.categoryColor, // adjust to match actual field name
  size: 44,
  iconSize: 22,
)
```

**Important:** The exact field names (`categoryIcon`, `categoryColor`) depend on what exists in the current `TransactionModel` or `CategoryModel`. Read both files before substituting.

If the transaction model doesn't have a direct `categoryIcon` field but resolves it through a `CategoryModel`, pass the resolved icon:

```dart
// Example with CategoryProvider lookup:
final category = context.read<CategoryProvider>().findByName(transaction.category);
final icon = _iconFromString(category?.icon ?? 'shopping_cart');
final color = _colorFromString(category?.color ?? '#6C63FF');

LogoWidget(
  description: transaction.description,
  fallbackIcon: icon,
  fallbackColor: color,
  size: 44,
)
```

### 18G. Settings Screen — API Key Input

Find the existing Settings screen. Add a new section for Logo Engine configuration:

```dart
// In settings_screen.dart — add this section:

// ── Logo Engine Section ────────────────────────────────────────────────────
Consumer<SettingsProvider>(builder: (ctx, settings, _) {
  final controller = TextEditingController(text: settings.logoApiKey);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(
          '🏷️ LOGO MOTORU',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5),
        ),
      ),

      // GlassCard container
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8, height: 8, margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: settings.logoEnabled ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  settings.logoEnabled ? 'Aktif — İşlem logoları çekiliyor' : 'Pasif — API key girilmedi',
                  style: TextStyle(
                    fontSize: 12,
                    color: settings.logoEnabled ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'logo.dev Publishable Key',
                hintText: 'pk_...',
                helperText: 'logo.dev → ücretsiz kayıt → Dashboard → API Keys',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => settings.setLogoApiKey(v),
              obscureText: false, // publishable keys are safe to show
            ),
            const SizedBox(height: 8),
            // Test logo button
            if (settings.logoEnabled)
              TextButton.icon(
                icon: const Icon(Icons.preview, size: 16),
                label: const Text('Önizle — Migros'),
                onPressed: () {
                  final url = LogoFetcher.getLogoUrl(
                    description: 'migros',
                    apiKey: settings.logoApiKey,
                  );
                  showDialog(
                    context: ctx,
                    builder: (_) => AlertDialog(
                      title: const Text('Logo Testi'),
                      content: url != null
                          ? CachedNetworkImage(
                              imageUrl: url,
                              width: 80, height: 80,
                              errorWidget: (_, __, ___) => const Text('Logo yüklenemedi'),
                            )
                          : const Text('URL oluşturulamadı'),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat'))],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    ],
  );
}),
```

### 18H. App Startup — Initialize SettingsProvider

In `main.dart`, ensure `SettingsProvider` is initialized at startup:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ... existing Hive init ...

  final settingsProvider = SettingsProvider();
  await settingsProvider.init(); // loads saved API key from SharedPreferences

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        // ... all other existing providers ...
      ],
      child: const MyApp(),
    ),
  );
}
```

### Phase 18 Verification

```bash
# 1. Build check
flutter analyze
flutter build apk --debug

# 2. Manual test checklist:
```

- [ ] `flutter pub get` succeeds — `cached_network_image` installed
- [ ] Settings screen shows "🏷️ LOGO MOTORU" section
- [ ] Without API key: green dot = grey, no network calls made
- [ ] After entering a valid `pk_...` key: dot turns green
- [ ] Migros preview button loads Migros logo in dialog
- [ ] Transaction list: "Migros" description → Migros logo appears
- [ ] Transaction list: "Şok Market" → ŞOK logo appears
- [ ] Transaction list: "Elektrik Faturası" → no logo fetched, category icon shows (expected)
- [ ] Unknown brand: category icon fallback (no broken UI)
- [ ] Airplane mode: cached logos still appear, uncached → category icon
- [ ] Logo appears same on second app open (cached, no re-fetch)
- [ ] `flutter analyze` → zero errors or warnings

---

## IMPLEMENTATION NOTES FOR AGENT

### How logo.dev works for mobile apps

logo.dev publishable keys (`pk_...`) are **designed for client-side use** including mobile apps. From their docs:

> "Use anywhere — browsers, mobile apps, client-side code. Only works with img.logo.dev."

No `Referer` header is needed for mobile apps using the publishable key — this is only required for web browsers. So `CachedNetworkImage` works directly with the URL + token parameter.

### URL format

```
https://img.logo.dev/{domain}?token={pk_...}&size=64&format=png
```

Parameters:
- `size`: pixel size (64 is optimal for 44px avatar at 1.5x screen density)
- `format`: `png` or `webp` (png safer for Dart Image cache)
- No `Referer` header needed for mobile

### Free tier limits

500,000 requests/month. A personal finance app with ~100 unique merchants, with 30-day client cache, would make approximately 100 requests per month total. This is **0.02% of the free limit**.

### What happens on logo.dev 404 (brand not found)

logo.dev returns either:
1. A real logo PNG → success
2. A generated monogram (first letter of domain, colored) → acceptable fallback
3. An HTTP error → `CachedNetworkImage.errorWidget` fires → category icon shown

The monogram behavior means the user almost never sees the raw category icon, even for unknown brands — they see a professional colored letter instead.

---

## FINAL BUILD SEQUENCE

```bash
# Update version
# pubspec.yaml: version: 6.2.0+62

flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter build apk --release

ls -lh build/app/outputs/flutter-apk/
# Expected: Ctrl-v6.2.apk
```

---

## FINAL COMPLETION CHECKLIST — v6.2

| Item | Feature | Status |
|------|---------|--------|
| 18A | cached_network_image dependency | ☐ |
| 18B | SettingsProvider + API key storage | ☐ |
| 18C | LogoFetcher — Turkish brand dictionary (50+ brands) | ☐ |
| 18C | LogoFetcher — Generic normalization fallback | ☐ |
| 18D | LogoWidget with CachedNetworkImage + fallback | ☐ |
| 18E | LogoCacheManager — 30-day TTL | ☐ |
| 18F | TransactionListItem integrated with LogoWidget | ☐ |
| 18G | Settings screen — API key input + status indicator | ☐ |
| 18G | Settings screen — Migros preview test button | ☐ |
| 18H | SettingsProvider initialized in main.dart | ☐ |
| ✅  | No network calls when API key is empty | ☐ |
| ✅  | Graceful fallback for all failure modes | ☐ |
| ✅  | 30-day logo cache working | ☐ |
| ✅  | pubspec version: 6.2.0+62 | ☐ |
| ✅  | flutter analyze — zero errors | ☐ |
| ✅  | Release APK: Ctrl-v6.2.apk | ☐ |
