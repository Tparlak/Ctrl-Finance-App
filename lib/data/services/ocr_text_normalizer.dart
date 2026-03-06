/// Corrects systematic ML Kit misreadings of Turkish thermal receipt text.
/// Must be applied to rawText BEFORE passing to TurkishReceiptParser.
class OcrTextNormalizer {

  /// Full normalization pipeline. Call on raw ML Kit output.
  static String normalize(String raw) {
    String text = raw;
    text = _fixCommonOcrErrors(text);
    text = _fixTurkishSpecificPatterns(text);
    text = _fixNumberAmbiguities(text);
    text = _normalizeDecimalSeparators(text);
    text = _fixLineBreaks(text);
    return text;
  }

  // ── PASS 1: Common OCR character confusions ─────────────────────────────
  // These happen universally across all thermal receipt scanners
  static String _fixCommonOcrErrors(String text) {
    // The single most impactful fix: '0' (zero) confused with 'O' (letter)
    // Strategy: in ALL-CAPS context (Turkish receipts are all-caps),
    // zeros inside words are almost certainly the letter O
    // We fix known keywords explicitly rather than globally to avoid
    // breaking actual number values
    const keywordFixes = {
      // Amount-related keywords
      r'T0PLAM':      'TOPLAM',
      r'T0PL4M':      'TOPLAM',
      r'TOPKDV':      'TOPKDV',  // already correct — keep
      r'T0PKDV':      'TOPKDV',
      r'ARA\s*T0PLAM':'ARA TOPLAM',
      r'G[EE]NEL\s*T0PLAM': 'GENEL TOPLAM',
      r'TUT4R':       'TUTAR',
      r'T[U|Ü]TAR':   'TUTAR',

      // Date/time keywords
      r'TAR[|İI]H':   'TARİH',
      r'TAR1H':       'TARİH',
      r'SAAT':        'SAAT',

      // Payment keywords
      r'NAK[|İI]T':   'NAKİT',
      r'NAK1T':       'NAKİT',
      r'PARA\s*[ÜU]ST[ÜU]': 'PARA ÜSTÜ',
      r'PARA\s*UST[UÜ]': 'PARA ÜSTÜ',
      r'KRED[|İI]\s*KART': 'KREDİ KART',
      r'BANKA\s*KART': 'BANKA KARTI',
      r'0NAY':        'ONAY',
      r'ONAY\s*K0DU': 'ONAY KODU',

      // Receipt metadata keywords
      r'F[|İI][SŞ]\s*N0': 'FİŞ NO',
      r'EK[ÜU]\s*N0':     'EKÜ NO',
      r'Z\s*N0':           'Z NO',
      r'VKN\s*[;:]':       'VKN:',

      // Fuel keywords
      r'M[|İI]KTAR':       'MİKTAR',
      r'M0T0R[|İI]N':      'MOTORİN',
      r'MOTORIN':           'MOTORİN',  // missing İ
      r'B[|İI]R[|İI]M\s*F[|İI]YAT': 'BİRİM FİYAT',
      r'ARAC\s*PLAKA':     'ARAÇ PLAKA',
      r'YAKLIT':            'YAKIT',    // OCR sometimes adds extra L

      // Market-specific
      r'[*]\s*\*\s*\*\s*F\s*[|İI]\s*[SŞ]': '* * * FİŞ',
    };

    for (final entry in keywordFixes.entries) {
      text = text.replaceAll(RegExp(entry.key, caseSensitive: false), entry.value);
    }
    return text;
  }

  // ── PASS 2: Turkish-specific character pattern fixes ────────────────────
  static String _fixTurkishSpecificPatterns(String text) {
    // Fix pipe character misread as İ or I (very common in Turkish)
    // "|" → "İ" only inside known Turkish word patterns
    text = text.replaceAll(RegExp(r'\bTAR\|H\b'), 'TARİH');
    text = text.replaceAll(RegExp(r'\bNAK\|T\b'), 'NAKİT');
    text = text.replaceAll(RegExp(r'\bM\|KTAR\b'), 'MİKTAR');
    text = text.replaceAll(RegExp(r'\bKRED\|\s*KART\b'), 'KREDİ KART');
    text = text.replaceAll(RegExp(r'\bB\|R\|M\b'), 'BİRİM');
    text = text.replaceAll(RegExp(r'\bF\|YAT\b'), 'FİYAT');
    text = text.replaceAll(RegExp(r'\bF\|[SŞ]\b'), 'FİŞ');

    // Fix 'l' (lowercase L) misread as '1' (one) in known keywords
    text = text.replaceAll(RegExp(r'\bTOP1AM\b', caseSensitive: false), 'TOPLAM');
    text = text.replaceAll(RegExp(r'\b1T\b'), 'LT');   // "1T" → "LT" (liters)
    text = text.replaceAll(RegExp(r'\bLT\)\s*:\s*'), 'LT): ');

    return text;
  }

  // ── PASS 3: Number/letter ambiguity in non-keyword positions ────────────
  // Only in clearly numeric contexts (after currency keywords, amount columns)
  static String _fixNumberAmbiguities(String text) {
    // Fix "O" (letter O) used instead of "0" (zero) in number sequences
    // Pattern: digits surrounding an O → it's a zero
    // e.g., "1O,50" → "10,50", "4O,OO" → "40,00"
    text = text.replaceAllMapped(
      RegExp(r'(\d)O(\d)'),
      (m) => '${m.group(1)}0${m.group(2)}',
    );
    text = text.replaceAllMapped(
      RegExp(r'(\d)O([,\.])'),
      (m) => '${m.group(1)}0${m.group(2)}',
    );
    text = text.replaceAllMapped(
      RegExp(r'([,\.])O(\d)'),
      (m) => '${m.group(1)}0${m.group(2)}',
    );
    return text;
  }

  // ── PASS 4: Decimal separator normalization ──────────────────────────────
  // Turkish receipts use comma as decimal separator (44,30 not 44.30)
  // OCR sometimes produces periods instead of commas in amounts
  static String _normalizeDecimalSeparators(String text) {
    // Pattern: "44.30" where it's clearly a 2-decimal amount → "44,30"
    // Only normalize if the pattern matches a price (not a date or ID)
    text = text.replaceAllMapped(
      RegExp(r'\b(\d{1,5})\.(\d{2})\b(?!\d)'),
      (m) {
        final intPart = int.tryParse(m.group(1)!);
        // Don't convert if it looks like a year (2024, 2025, 2026)
        if (intPart != null && intPart >= 2000 && intPart <= 2099) {
          return m.group(0)!; // keep as-is (it's a year)
        }
        return '${m.group(1)},${m.group(2)}';
      },
    );
    return text;
  }

  // ── PASS 5: Line break normalization ─────────────────────────────────────
  // ML Kit sometimes merges two lines or splits one line incorrectly
  static String _fixLineBreaks(String text) {
    // Ensure keywords always start on their own line
    const lineStartKeywords = [
      'TOPLAM', 'TOPKDV', 'NAKİT', 'NAKIT', 'PARA ÜSTÜ',
      'TARİH', 'TARIH', 'FİŞ NO', 'EKÜ NO', 'Z NO',
      'TUTAR', 'MİKTAR', 'BİRİM FİYAT', 'ONAY KODU',
      'ARAÇ PLAKA', 'MOTORIN', 'BENZİN',
    ];
    for (final kw in lineStartKeywords) {
      // If keyword appears mid-line (not at start), force a newline before it
      text = text.replaceAll(
        RegExp(r'(?<=[^\n])(' + RegExp.escape(kw) + r')', caseSensitive: false),
        '\n$kw',
      );
    }
    return text;
  }
}
