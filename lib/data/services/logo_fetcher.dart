import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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

  /// Called by LogoWidget error handler to prevent retry storms
  static void markUnresolvable(String description) {
    _domainCache[description.toLowerCase().trim()] = null;
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
    final normalized = _normalizeToLikelyDomain(description);
    return normalized; // may be null if normalization fails heuristic checks
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // KNOWN TURKISH + GLOBAL BRAND DICTIONARY (50+ brands)
  // Keys are lowercase normalized.
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
    'mopaş':                  'bim.com.tr',
    'mopaş marketcilik':      'bim.com.tr',
    'imece':                  'imecemarket.com.tr',

    // ── Fast Food / Restaurants ───────────────────────────────────────────────
    'mcdonalds':              'mcdonalds.com.tr',
    'mc donalds':             'mcdonalds.com.tr',
    'burger king':            'burgerking.com.tr',
    'kfc':                    'kfc.com.tr',
    'pizza hut':              'pizzahut.com.tr',
    'dominos':                'dominos.com.tr',
    "domino's":               'dominos.com.tr',
    'subway':                 'subway.com',
    'starbucks':              'starbucks.com.tr',
    'kahve dünyası':          'kahvedunyasi.com.tr',
    'caffè nero':             'caffenero.com.tr',
    'gloria jeans':           'gloriajeanscoffees.com.tr',
    'simit sarayı':           'simitsarayi.com',
    'popeyes':                'popeyes.com',

    // ── Fuel Stations ─────────────────────────────────────────────────────────
    'opet':                   'opet.com.tr',
    'shell':                  'shell.com.tr',
    'bp':                     'bp.com.tr',
    'petrol ofisi':           'petrolofisi.com.tr',
    'total':                  'totalenergies.com.tr',
    'lukoil':                 'lukoil.com.tr',
    'hayaloil':               'hayaloil.com.tr',
    'alpet':                  'alpet.com.tr',

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
    'hsbc':                   'hsbc.com.tr',
    'ing bank':               'ingbank.com.tr',
    'ingbank':                'ingbank.com.tr',
    'ptt bank':               'pttbank.com.tr',
    'kuveyt türk':            'kuveytturk.com.tr',
    'kuveyt turk':            'kuveytturk.com.tr',

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
    'boyner':                 'boyner.com.tr',
    'lcw':                    'lcw.com',
    'lc waikiki':             'lcw.com',
    'koton':                  'koton.com',
    'zara':                   'zara.com',
    'h&m':                    'hm.com',
    'mango':                  'mango.com',

    // ── Delivery Apps ─────────────────────────────────────────────────────────
    'yemeksepeti':            'yemeksepeti.com',
    'trendyol go':            'trendyol.com',
    'getir':                  'getir.com',
    'banabi':                 'banabi.com.tr',
    'mavi':                   'mavi.com',

    // ── Healthcare ────────────────────────────────────────────────────────────
    'dr. max':                'drmax.com.tr',

    // ── Insurance ─────────────────────────────────────────────────────────────
    'axa sigorta':            'axa.com.tr',
    'allianz':                'allianz.com.tr',
    'mapfre':                 'mapfre.com.tr',

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
    'chatgpt':                'openai.com',
    'openai':                 'openai.com',

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
    'sahibinden':             'sahibinden.com',
    'emlakjet':               'emlakjet.com',
  };

  // ──────────────────────────────────────────────────────────────────────────────
  // GENERIC NORMALIZATION
  // ──────────────────────────────────────────────────────────────────────────────
  static String? _normalizeToLikelyDomain(String input) {
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

    cleaned = _normalizeTurkish(cleaned).trim();
    cleaned = cleaned.replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();

    if (cleaned.length < 3) return null;
    if (cleaned.split(' ').length > 3) return null;

    final domainBase = cleaned.replaceAll(' ', '');
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
