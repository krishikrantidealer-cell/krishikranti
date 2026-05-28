import 'package:flutter/material.dart';
import 'package:krishikranti/core/dynamic_translation_service.dart';

/// A drop-in replacement for [Text] that translates dynamic backend content.
///
/// - Renders the original text **immediately** (no loading state / layout shift)
/// - When a translation becomes available it swaps in silently
/// - Triggers translation in background on first render
///
/// Usage:
/// ```dart
/// // Instead of:
/// Text(product.title, style: ...)
/// // Use:
/// TranslatableText(product.title, style: ...)
/// ```
class TranslatableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool? softWrap;
  final double? textScaleFactor;
  final StrutStyle? strutStyle;

  const TranslatableText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textScaleFactor,
    this.strutStyle,
  });

  @override
  Widget build(BuildContext context) {
    final service = DynamicTranslationService();

    // Fire-and-forget translation in background (safe to call from build)
    // Uses WidgetsBinding to defer to the next frame so we don't call
    // setState during build.
    if (text.isNotEmpty && service.currentLangCode != 'en') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        service.ensureTranslated(text);
      });
    }

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final displayText = service.getTranslation(text);
        return Text(
          displayText,
          style: style,
          textAlign: textAlign,
          overflow: overflow,
          maxLines: maxLines,
          softWrap: softWrap,
          strutStyle: strutStyle,
        );
      },
    );
  }
}

/// Extension on [BuildContext] for imperative translation access.
///
/// Usage:
/// ```dart
/// final translated = context.tr(product.title);
/// ```
extension TranslationExtension on BuildContext {
  /// Returns the cached translation for [text], or [text] itself if not available.
  String tr(String text) => DynamicTranslationService().getTranslation(text);

  /// Pre-warms translations for a list of strings (fire-and-forget).
  void preTranslate(List<String> texts) =>
      DynamicTranslationService().ensureAllTranslated(texts);
}
