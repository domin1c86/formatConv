import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/conversion_provider.dart';
import '../widgets/file_selector.dart';
import '../widgets/format_selector.dart';
import '../widgets/preview_panel.dart';
import '../widgets/progress_indicator.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _maxContentWidth = 1440.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(conversionProvider);
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      body: Column(
        children: [
          _GlobalNav(strings: strings),
          _SubNav(strings: strings),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = _horizontalPadding(constraints.maxWidth);
                final compact = constraints.maxWidth < 920;

                return ColoredBox(
                  color: const Color(0xFFF5F5F7),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      compact ? 24 : 32,
                      horizontalPadding,
                      32,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HeroBand(strings: strings),
                            const SizedBox(height: 24),
                            if (compact)
                              _CompactWorkspace(provider: provider, strings: strings)
                            else
                              _DesktopWorkspace(provider: provider, strings: strings),
                            if (provider.error != null) ...[
                              const SizedBox(height: 16),
                              _ErrorBanner(message: provider.error!),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double _horizontalPadding(double width) {
    if (width >= 1600) return 64;
    if (width >= 1200) return 40;
    if (width >= 720) return 24;
    return 16;
  }
}

class _GlobalNav extends ConsumerWidget {
  final AppStrings strings;

  const _GlobalNav({required this.strings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLanguageProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final showLinks = constraints.maxWidth >= 620;

        return Container(
          height: 44,
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                strings.productName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showLinks) ...[
                const SizedBox(width: 32),
                _NavText(strings.navFiles),
                _NavText(strings.navFormats),
                _NavText(strings.navResults),
              ],
              const Spacer(),
              SegmentedButton<AppLanguage>(
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  side: WidgetStateProperty.all(
                    const BorderSide(color: Color(0xFF333333)),
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? Colors.black
                        : Colors.white;
                  }),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? Colors.white
                        : Colors.black;
                  }),
                ),
                segments: [
                  ButtonSegment(
                    value: AppLanguage.en,
                    label: Text(strings.languageEnglish),
                  ),
                  ButtonSegment(
                    value: AppLanguage.zh,
                    label: Text(strings.languageChinese),
                  ),
                ],
                selected: {language},
                onSelectionChanged: (selection) {
                  ref.read(appLanguageProvider.notifier).state = selection.first;
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavText extends StatelessWidget {
  final String label;

  const _NavText(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 22),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFCCCCCC),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SubNav extends StatelessWidget {
  final AppStrings strings;

  const _SubNav({required this.strings});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xEAF5F5F7),
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        children: [
          Text(
            strings.appTitle,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFC),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: const Text(
              'Windows',
              style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBand extends StatelessWidget {
  final AppStrings strings;

  const _HeroBand({required this.strings});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleSize = constraints.maxWidth < 640 ? 34.0 : 48.0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                strings.heroTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: titleSize,
                  height: 1.08,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Text(
                  strings.heroSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 18,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DesktopWorkspace extends StatelessWidget {
  final ConversionProvider provider;
  final AppStrings strings;

  const _DesktopWorkspace({
    required this.provider,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 380,
          child: FileSelector(
            strings: strings,
            selectedFileCount: provider.selectedFiles.length,
            onFilesSelected: provider.selectFiles,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _WorkSurface(provider: provider, strings: strings),
        ),
      ],
    );
  }
}

class _CompactWorkspace extends StatelessWidget {
  final ConversionProvider provider;
  final AppStrings strings;

  const _CompactWorkspace({
    required this.provider,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FileSelector(
          strings: strings,
          selectedFileCount: provider.selectedFiles.length,
          onFilesSelected: provider.selectFiles,
        ),
        const SizedBox(height: 16),
        _WorkSurface(provider: provider, strings: strings),
      ],
    );
  }
}

class _WorkSurface extends StatelessWidget {
  final ConversionProvider provider;
  final AppStrings strings;

  const _WorkSurface({
    required this.provider,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SurfacePanel(
          child: FormatSelector(
            strings: strings,
            selectedFiles: provider.selectedFiles,
            onConvert: provider.startConversion,
          ),
        ),
        if (provider.selectedFiles.isNotEmpty || provider.results.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SurfacePanel(
            child: FilePreviewPanel(
              strings: strings,
              selectedFiles: provider.selectedFiles,
              results: provider.results,
            ),
          ),
        ],
        if (provider.isConverting) ...[
          const SizedBox(height: 16),
          ConversionProgress(
            strings: strings,
            progress: provider.progress,
            onCancel: provider.cancelConversion,
          ),
        ],
      ],
    );
  }
}

class _SurfacePanel extends StatelessWidget {
  final Widget child;

  const _SurfacePanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: child,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFB3B3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB00020), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF8A0017), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
