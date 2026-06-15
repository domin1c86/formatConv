import 'dart:io';
import 'dart:math' as math;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../models/conversion_options.dart';
import '../models/conversion_result.dart';
import '../providers/conversion_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/progress_indicator.dart';

enum _FileTab { all, video, audio, image }

enum _RightTab { formats, results }

enum _SettingsTab { general, preferences, advanced, custom, about }

const _videoExtensions = {
  '.mp4',
  '.mkv',
  '.mov',
  '.avi',
  '.webm',
  '.flv',
  '.wmv',
  '.mpeg',
  '.3gp'
};
const _imageExtensions = {
  '.jpeg',
  '.jpg',
  '.png',
  '.webp',
  '.tiff',
  '.tif',
  '.bmp',
  '.gif',
  '.ico',
  '.svg'
};
const _audioExtensions = {
  '.mp3',
  '.flac',
  '.wav',
  '.aac',
  '.ogg',
  '.wma',
  '.m4a',
  '.opus'
};

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _FileTab _fileTab = _FileTab.all;
  _RightTab _rightTab = _RightTab.formats;
  bool _showHistory = false;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(conversionProvider);
    final settingsController = ref.watch(settingsProvider);
    final settings = settingsController.settings;
    final strings = AppStrings(settings.language);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 980;
            final contentWidth = math.min(constraints.maxWidth, 1880.0);
            final padding = constraints.maxWidth >= 1600 ? 28.0 : 18.0;

            final content = compact
                ? Column(
                    children: [
                      SizedBox(
                        height: math.max(520, constraints.maxHeight * 0.48),
                        child: _LeftPane(
                          strings: strings,
                          provider: provider,
                          fileTab: _fileTab,
                          page: _page,
                          onFileTabChanged: (tab) => setState(() {
                            _fileTab = tab;
                            _page = 0;
                          }),
                          onPageChanged: (page) => setState(() => _page = page),
                          onOpenSettings: () =>
                              _showSettings(strings, settingsController),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _RightPane(
                          strings: strings,
                          provider: provider,
                          settingsController: settingsController,
                          rightTab: _rightTab,
                          showHistory: _showHistory,
                          onRightTabChanged: (tab) =>
                              setState(() => _rightTab = tab),
                          onShowHistory: () =>
                              setState(() => _showHistory = true),
                          onShowCurrent: () =>
                              setState(() => _showHistory = false),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: contentWidth * 0.34,
                        child: _LeftPane(
                          strings: strings,
                          provider: provider,
                          fileTab: _fileTab,
                          page: _page,
                          onFileTabChanged: (tab) => setState(() {
                            _fileTab = tab;
                            _page = 0;
                          }),
                          onPageChanged: (page) => setState(() => _page = page),
                          onOpenSettings: () =>
                              _showSettings(strings, settingsController),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _RightPane(
                          strings: strings,
                          provider: provider,
                          settingsController: settingsController,
                          rightTab: _rightTab,
                          showHistory: _showHistory,
                          onRightTabChanged: (tab) =>
                              setState(() => _rightTab = tab),
                          onShowHistory: () =>
                              setState(() => _showHistory = true),
                          onShowCurrent: () =>
                              setState(() => _showHistory = false),
                        ),
                      ),
                    ],
                  );

            return ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: SizedBox(
                  width: contentWidth,
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: content,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showSettings(
      AppStrings strings, SettingsController controller) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => _SettingsDialog(
        strings: strings,
        controller: controller,
      ),
    );
  }
}

class _LeftPane extends StatelessWidget {
  final AppStrings strings;
  final ConversionProvider provider;
  final _FileTab fileTab;
  final int page;
  final ValueChanged<_FileTab> onFileTabChanged;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onOpenSettings;

  const _LeftPane({
    required this.strings,
    required this.provider,
    required this.fileTab,
    required this.page,
    required this.onFileTabChanged,
    required this.onPageChanged,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final controlHeightBudget = constraints.maxHeight * 0.16;
        final settingsHeight = math.min(54.0, math.max(46.0, controlHeightBudget * 0.36));
        final addHeight = math.min(
          92.0,
          math.max(76.0, controlHeightBudget - settingsHeight),
        );
        return Column(
          children: [
            SizedBox(
              height: addHeight,
              child: _AddFilesTile(
                strings: strings,
                selectedFileCount: provider.selectedFiles.length,
                onFilesAdded: provider.addFiles,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _AddedFilesPanel(
                strings: strings,
                files: provider.selectedFiles,
                selectedTab: fileTab,
                page: page,
                onFilesAdded: provider.addFiles,
                onTabChanged: onFileTabChanged,
                onPageChanged: onPageChanged,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: settingsHeight,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(strings.settings),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AddFilesTile extends StatefulWidget {
  final AppStrings strings;
  final int selectedFileCount;
  final ValueChanged<List<String>> onFilesAdded;

  const _AddFilesTile({
    required this.strings,
    required this.selectedFileCount,
    required this.onFilesAdded,
  });

  @override
  State<_AddFilesTile> createState() => _AddFilesTileState();
}

class _AddFilesTileState extends State<_AddFilesTile> {
  bool _dragging = false;
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (details) {
        setState(() => _dragging = false);
        widget.onFilesAdded(details.files.map((file) => file.path).toList());
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(14),
          hoverColor: Colors.transparent,
          splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          onTap: () async {
            final result =
                await FilePicker.platform.pickFiles(allowMultiple: true);
            if (result != null) {
              widget.onFilesAdded(result.paths.whereType<String>().toList());
            }
          },
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _dragging
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                : _hovering
                    ? const Color(0xFFF0F7FF)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _dragging
                  ? Theme.of(context).colorScheme.primary
                  : const Color(0xFFE0E0E0),
              width: _dragging ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 260,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.strings.addFiles,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.selectedFileCount == 0
                              ? widget.strings.dropFiles
                              : widget.strings
                                  .selectedCount(widget.selectedFileCount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.15,
                            color: Color(0xFF6E6E73),
                          ),
                        ),
                      ],
                    ),
                  ),
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

class _AddedFilesPanel extends StatefulWidget {
  final AppStrings strings;
  final List<String> files;
  final _FileTab selectedTab;
  final int page;
  final ValueChanged<List<String>> onFilesAdded;
  final ValueChanged<_FileTab> onTabChanged;
  final ValueChanged<int> onPageChanged;

  const _AddedFilesPanel({
    required this.strings,
    required this.files,
    required this.selectedTab,
    required this.page,
    required this.onFilesAdded,
    required this.onTabChanged,
    required this.onPageChanged,
  });

  @override
  State<_AddedFilesPanel> createState() => _AddedFilesPanelState();
}

class _AddedFilesPanelState extends State<_AddedFilesPanel> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final tabs = _availableTabs(widget.files, widget.strings);
    final filtered = widget.files
        .where((file) => _matchesTab(file, widget.selectedTab))
        .toList();
    const pageSize = 12;
    final totalPages = math.max(1, (filtered.length / pageSize).ceil());
    final currentPage = widget.page.clamp(0, totalPages - 1);
    final visible =
        filtered.skip(currentPage * pageSize).take(pageSize).toList();

    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (details) {
        setState(() => _dragging = false);
        widget.onFilesAdded(details.files.map((file) => file.path).toList());
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _dragging ? const Color(0xFFF0F7FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _dragging
                ? Theme.of(context).colorScheme.primary
                : const Color(0xFFE0E0E0),
            width: _dragging ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.strings.addedFiles,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _TabStrip<_FileTab>(
              tabs: tabs,
              selected: widget.selectedTab,
              onChanged: widget.onTabChanged,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Text(
                        widget.strings.noFiles,
                        style: const TextStyle(color: Color(0xFF6E6E73)),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 420 ? 3 : 2;
                        return GridView.builder(
                          itemCount: visible.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.05,
                          ),
                          itemBuilder: (context, index) =>
                              _FileCard(filePath: visible[index]),
                        );
                      },
                    ),
            ),
            if (totalPages > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: currentPage == 0
                        ? null
                        : () => widget.onPageChanged(currentPage - 1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Text('${currentPage + 1} / $totalPages'),
                  IconButton(
                    onPressed: currentPage >= totalPages - 1
                        ? null
                        : () => widget.onPageChanged(currentPage + 1),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<_TabItem<_FileTab>> _availableTabs(
      List<String> files, AppStrings strings) {
    final items = [_TabItem(strings.all, _FileTab.all)];
    if (files.any((file) => _fileType(file) == _FileTab.video)) {
      items.add(_TabItem(strings.video, _FileTab.video));
    }
    if (files.any((file) => _fileType(file) == _FileTab.audio)) {
      items.add(_TabItem(strings.audio, _FileTab.audio));
    }
    if (files.any((file) => _fileType(file) == _FileTab.image)) {
      items.add(_TabItem(strings.image, _FileTab.image));
    }
    return items;
  }
}

class _FileCard extends StatefulWidget {
  final String filePath;

  const _FileCard({required this.filePath});

  @override
  State<_FileCard> createState() => _FileCardState();
}

class _FileCardState extends State<_FileCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final name = p.basename(widget.filePath);
    final type = _fileType(widget.filePath);
    final icon = switch (type) {
      _FileTab.video => Icons.movie_outlined,
      _FileTab.audio => Icons.graphic_eq_rounded,
      _FileTab.image => Icons.image_outlined,
      _FileTab.all => Icons.insert_drive_file_outlined,
    };

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _hovering ? const Color(0xFFF0F7FF) : const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _hovering
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFFE5E5EA),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEDEDF2)),
              ),
              child: Icon(icon, size: 34, color: const Color(0xFF6E6E73)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, height: 1.15),
          ),
        ],
      ),
    );

    return Draggable<List<String>>(
      data: [widget.filePath],
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 130, height: 130, child: child),
      ),
      childWhenDragging: Opacity(opacity: 0.45, child: child),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: child,
      ),
    );
  }
}

class _RightPane extends StatelessWidget {
  final AppStrings strings;
  final ConversionProvider provider;
  final SettingsController settingsController;
  final _RightTab rightTab;
  final bool showHistory;
  final ValueChanged<_RightTab> onRightTabChanged;
  final VoidCallback onShowHistory;
  final VoidCallback onShowCurrent;

  const _RightPane({
    required this.strings,
    required this.provider,
    required this.settingsController,
    required this.rightTab,
    required this.showHistory,
    required this.onRightTabChanged,
    required this.onShowHistory,
    required this.onShowCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return _StickyPanel(
      child: Column(
        children: [
          _TabStrip<_RightTab>(
            tabs: [
              _TabItem(strings.formatSelection, _RightTab.formats),
              _TabItem(strings.resultDisplay, _RightTab.results),
            ],
            selected: rightTab,
            onChanged: onRightTabChanged,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: rightTab == _RightTab.formats
                ? _FormatSelection(
                    strings: strings,
                    provider: provider,
                    settingsController: settingsController,
                    onShowResults: () => onRightTabChanged(_RightTab.results),
                  )
                : _ResultsView(
                    strings: strings,
                    results: provider.results.values.toList(),
                    history: settingsController.history,
                    showHistory: showHistory,
                    onShowHistory: onShowHistory,
                    onShowCurrent: onShowCurrent,
                  ),
          ),
          if (provider.isConverting) ...[
            const SizedBox(height: 12),
            ConversionProgress(
              strings: strings,
              progress: provider.progress,
              onCancel: provider.cancelConversion,
            ),
          ],
          if (provider.error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: provider.error!),
          ],
        ],
      ),
    );
  }
}

class _FormatSelection extends StatefulWidget {
  final AppStrings strings;
  final ConversionProvider provider;
  final SettingsController settingsController;
  final VoidCallback onShowResults;

  const _FormatSelection({
    required this.strings,
    required this.provider,
    required this.settingsController,
    required this.onShowResults,
  });

  @override
  State<_FormatSelection> createState() => _FormatSelectionState();
}

class _FormatSelectionState extends State<_FormatSelection> {
  final Map<String, ConversionOptions> _options = {};

  @override
  Widget build(BuildContext context) {
    final settings = widget.settingsController.settings;
    final files = widget.provider.selectedFiles;
    final hasVideo = files.any((file) => _fileType(file) == _FileTab.video);
    final hasAudio = files.any((file) => _fileType(file) == _FileTab.audio);
    final hasImage = files.any((file) => _fileType(file) == _FileTab.image);

    return ListView(
      children: [
        if (files.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(widget.strings.emptyFormatHint,
                style: const TextStyle(color: Color(0xFF6E6E73))),
          ),
        if (hasVideo)
          _FormatRow(
            title: widget.strings.videoFormats,
            type: _FileTab.video,
            formats: supportedVideoFormats
                .where(settings.visibleVideoFormats.contains)
                .toList(),
            strings: widget.strings,
            getOptions: _getOptions,
            onOptionsChanged: _setOptions,
            onConvert: _convert,
          ),
        if (hasAudio)
          _FormatRow(
            title: widget.strings.audioFormats,
            type: _FileTab.audio,
            formats: supportedAudioFormats
                .where(settings.visibleAudioFormats.contains)
                .toList(),
            strings: widget.strings,
            getOptions: _getOptions,
            onOptionsChanged: _setOptions,
            onConvert: _convert,
          ),
        if (hasImage)
          _FormatRow(
            title: widget.strings.imageFormats,
            type: _FileTab.image,
            formats: supportedImageFormats
                .where(settings.visibleImageFormats.contains)
                .toList(),
            strings: widget.strings,
            getOptions: _getOptions,
            onOptionsChanged: _setOptions,
            onConvert: _convert,
          ),
        if (!hasVideo && !hasAudio && !hasImage && files.isNotEmpty)
          Text(widget.strings.unsupportedFileType,
              style: const TextStyle(color: Color(0xFFB35A00))),
      ],
    );
  }

  ConversionOptions _getOptions(String format) {
    return _options[format] ??
        ConversionOptions(
            overwrite: widget.settingsController.settings.overwriteSource);
  }

  void _setOptions(String format, ConversionOptions options) {
    setState(() => _options[format] = options);
  }

  void _convert(String format, List<String>? files) {
    widget.provider.startConversion(
      format,
      _getOptions(format).copyWith(
          overwrite: widget.settingsController.settings.overwriteSource),
      files: files,
      settings: widget.settingsController.settings,
      onResult: widget.settingsController.addHistory,
    );
    widget.onShowResults();
  }
}

class _FormatRow extends StatelessWidget {
  final String title;
  final _FileTab type;
  final List<String> formats;
  final AppStrings strings;
  final ConversionOptions Function(String format) getOptions;
  final void Function(String format, ConversionOptions options)
      onOptionsChanged;
  final void Function(String format, List<String>? files) onConvert;

  const _FormatRow({
    required this.title,
    required this.type,
    required this.formats,
    required this.strings,
    required this.getOptions,
    required this.onOptionsChanged,
    required this.onConvert,
  });

  @override
  Widget build(BuildContext context) {
    final controller = ScrollController();
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Scrollbar(
            controller: controller,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: controller,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: formats
                    .map(
                      (format) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _MiniFormatCard(
                          strings: strings,
                          type: type,
                          format: format,
                          options: getOptions(format),
                          onOptionsChanged: (options) =>
                              onOptionsChanged(format, options),
                          onConvert: (files) => onConvert(format, files),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniFormatCard extends StatefulWidget {
  final AppStrings strings;
  final _FileTab type;
  final String format;
  final ConversionOptions options;
  final ValueChanged<ConversionOptions> onOptionsChanged;
  final ValueChanged<List<String>?> onConvert;

  const _MiniFormatCard({
    required this.strings,
    required this.type,
    required this.format,
    required this.options,
    required this.onOptionsChanged,
    required this.onConvert,
  });

  @override
  State<_MiniFormatCard> createState() => _MiniFormatCardState();
}

class _MiniFormatCardState extends State<_MiniFormatCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<List<String>>(
      onWillAcceptWithDetails: (details) => details.data.isNotEmpty,
      onAcceptWithDetails: (details) => widget.onConvert(details.data),
      builder: (context, candidateData, rejectedData) {
        final active = candidateData.isNotEmpty;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 118,
            height: 54,
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFFEAF4FF)
                  : _hovering
                      ? const Color(0xFFF0F7FF)
                      : const Color(0xFFFAFAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active || _hovering
                    ? Theme.of(context).colorScheme.primary
                    : const Color(0xFFE0E0E0),
                width: active ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    mouseCursor: SystemMouseCursors.click,
                    hoverColor: Colors.transparent,
                    borderRadius:
                        const BorderRadius.horizontal(left: Radius.circular(12)),
                    onTap: () => widget.onConvert(null),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.format,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.settings_outlined, size: 16),
                  onPressed: () => _showFormatSettings(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showFormatSettings(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => _FormatSettingsDialog(
        strings: widget.strings,
        type: widget.type,
        format: widget.format,
        options: widget.options,
        onChanged: widget.onOptionsChanged,
      ),
    );
  }
}

class _FormatSettingsDialog extends StatefulWidget {
  final AppStrings strings;
  final _FileTab type;
  final String format;
  final ConversionOptions options;
  final ValueChanged<ConversionOptions> onChanged;

  const _FormatSettingsDialog({
    required this.strings,
    required this.type,
    required this.format,
    required this.options,
    required this.onChanged,
  });

  @override
  State<_FormatSettingsDialog> createState() => _FormatSettingsDialogState();
}

class _FormatSettingsDialogState extends State<_FormatSettingsDialog> {
  late ConversionOptions _options = widget.options;

  @override
  Widget build(BuildContext context) {
    final codecs = _codecsFor(widget.format, widget.type);
    final bitrates = widget.type == _FileTab.audio
        ? const ['96k', '128k', '192k', '256k', '320k']
        : const <String>[];
    final algorithms = widget.type == _FileTab.image && _options.quality < 100
        ? const ['LZW', 'Zip', 'JPEG', 'WebP', 'RLE']
        : const <String>[];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('${widget.strings.formatSettings} - ${widget.format}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SliderSetting(
              label: widget.strings.compressionRatio,
              value: _options.quality,
              onChanged: (value) => _update(
                  _options.copyWith(quality: value, lossless: value >= 100)),
            ),
            if (bitrates.isNotEmpty)
              _DropdownSetting(
                label: widget.strings.bitrate,
                value: _options.bitrate,
                values: bitrates,
                onChanged: (value) =>
                    _update(_options.copyWith(bitrate: value)),
              ),
            if (codecs.isNotEmpty)
              _DropdownSetting(
                label: widget.strings.codec,
                value: _options.codec,
                values: codecs,
                onChanged: (value) => _update(_options.copyWith(codec: value)),
              ),
            if (algorithms.isNotEmpty)
              _DropdownSetting(
                label: widget.strings.compressionAlgorithm,
                value: _options.compressionAlgorithm,
                values: algorithms,
                onChanged: (value) =>
                    _update(_options.copyWith(compressionAlgorithm: value)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(widget.strings.save)),
      ],
    );
  }

  void _update(ConversionOptions options) {
    setState(() => _options = options);
    widget.onChanged(options);
  }
}

class _ResultsView extends StatelessWidget {
  final AppStrings strings;
  final List<ConversionResult> results;
  final List<ConversionResult> history;
  final bool showHistory;
  final VoidCallback onShowHistory;
  final VoidCallback onShowCurrent;

  const _ResultsView({
    required this.strings,
    required this.results,
    required this.history,
    required this.showHistory,
    required this.onShowHistory,
    required this.onShowCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final visible = showHistory ? history : results;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(showHistory ? strings.historyHint : strings.completedThisRun,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const Spacer(),
            if (showHistory)
              TextButton(
                  onPressed: onShowCurrent,
                  child: Text(strings.completedThisRun)),
          ],
        ),
        if (!showHistory) ...[
          const SizedBox(height: 10),
          _HistoryHintCard(
            strings: strings,
            historyCount: history.length,
            onTap: onShowHistory,
          ),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(strings.noFiles,
                      style: const TextStyle(color: Color(0xFF6E6E73))))
              : ListView.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _ResultCard(strings: strings, result: visible[index]),
                ),
        ),
      ],
    );
  }
}

class _HistoryHintCard extends StatefulWidget {
  final AppStrings strings;
  final int historyCount;
  final VoidCallback onTap;

  const _HistoryHintCard({
    required this.strings,
    required this.historyCount,
    required this.onTap,
  });

  @override
  State<_HistoryHintCard> createState() => _HistoryHintCardState();
}

class _HistoryHintCardState extends State<_HistoryHintCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(14),
        hoverColor: Colors.transparent,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _hovering ? const Color(0xFFF0F7FF) : const Color(0xFFFAFAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovering
                  ? Theme.of(context).colorScheme.primary
                  : const Color(0xFFE0E0E0),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.history_rounded, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${widget.strings.historyHint} - ${widget.strings.historyHintBody}',
                ),
              ),
              Text('${widget.historyCount}'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final AppStrings strings;
  final ConversionResult result;

  const _ResultCard({required this.strings, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: result.success ? Colors.white : const Color(0xFFFFF6F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: result.success
                ? const Color(0xFFE0E0E0)
                : const Color(0xFFFFB3B3)),
      ),
      child: Row(
        children: [
          Icon(
            result.success
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            color: result.success
                ? const Color(0xFF15803D)
                : const Color(0xFFB00020),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 18,
              runSpacing: 6,
              children: [
                _ResultField(
                    label: strings.sourceFile, value: result.inputName),
                _ResultField(
                    label: strings.outputFile,
                    value: result.outputName.isEmpty
                        ? strings.conversionFailed
                        : result.outputName),
                _ResultField(
                    label: strings.duration,
                    value: _formatDuration(result.duration)),
                _ResultField(
                    label: strings.operationTime,
                    value: _formatTime(result.finishedAt)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed:
                result.success ? () => _openFile(result.outputPath) : null,
            icon: const Icon(Icons.open_in_new_rounded, size: 19),
          ),
        ],
      ),
    );
  }

  void _openFile(String path) {
    if (Platform.isWindows) {
      Process.run('start', ['', path], runInShell: true);
    }
  }
}

class _SettingsDialog extends StatefulWidget {
  final AppStrings strings;
  final SettingsController controller;

  const _SettingsDialog({
    required this.strings,
    required this.controller,
  });

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  _SettingsTab _tab = _SettingsTab.general;
  late AppSettings _settings = widget.controller.settings;
  late final TextEditingController _directoryController =
      TextEditingController(text: _settings.defaultOutputDirectory);
  late final TextEditingController _templateController =
      TextEditingController(text: _settings.namingTemplate);
  late final TextEditingController _fontController =
      TextEditingController(text: _settings.fontFamily);

  @override
  void dispose() {
    _directoryController.dispose();
    _templateController.dispose();
    _fontController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 720),
        child: Row(
          children: [
            Container(
              width: 180,
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F7),
                borderRadius:
                    BorderRadius.horizontal(left: Radius.circular(22)),
              ),
              child: Column(
                children: _SettingsTab.values.map((tab) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SideMenuButton(
                      label: _tabLabel(tab),
                      selected: _tab == tab,
                      onTap: () => setState(() => _tab = tab),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: _buildContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return switch (_tab) {
      _SettingsTab.general => _general(),
      _SettingsTab.preferences => _preferences(),
      _SettingsTab.advanced => _advanced(context),
      _SettingsTab.custom => _custom(),
      _SettingsTab.about => _about(context),
    };
  }

  Widget _general() {
    return _SettingsSection(
      title: widget.strings.common,
      children: [
        _TextSetting(
          label: widget.strings.defaultOutputDirectory,
          controller: _directoryController,
          action: IconButton(
            icon: const Icon(Icons.folder_open_outlined),
            onPressed: () async {
              final selected = await FilePicker.platform.getDirectoryPath();
              if (selected != null) {
                _directoryController.text = selected;
                _save(_settings.copyWith(defaultOutputDirectory: selected));
              }
            },
          ),
          onSubmitted: (value) =>
              _save(_settings.copyWith(defaultOutputDirectory: value)),
        ),
        _SwitchSetting(
          label: widget.strings.askBeforeConvert,
          value: _settings.askBeforeConvert,
          onChanged: (value) =>
              _save(_settings.copyWith(askBeforeConvert: value)),
        ),
        _TextSetting(
          label: widget.strings.namingTemplate,
          controller: _templateController,
          helper: r'Example: $name$_$num$',
          onSubmitted: (value) =>
              _save(_settings.copyWith(namingTemplate: value)),
        ),
        _SwitchSetting(
          label: widget.strings.overwriteSource,
          value: _settings.overwriteSource,
          onChanged: (value) =>
              _save(_settings.copyWith(overwriteSource: value)),
        ),
        _SwitchSetting(
          label: widget.strings.gpuAcceleration,
          value: _settings.gpuAcceleration,
          onChanged: (value) =>
              _save(_settings.copyWith(gpuAcceleration: value)),
        ),
      ],
    );
  }

  Widget _preferences() {
    return _SettingsSection(
      title: widget.strings.preferences,
      children: [
        _SegmentSetting<AppLanguage>(
          label: widget.strings.language,
          values: {
            AppLanguage.en: widget.strings.languageEnglish,
            AppLanguage.zh: widget.strings.languageChinese,
          },
          selected: _settings.language,
          onChanged: (value) => _save(_settings.copyWith(language: value)),
        ),
        _SegmentSetting<AppThemeChoice>(
          label: widget.strings.theme,
          values: {
            AppThemeChoice.light: widget.strings.lightTheme,
            AppThemeChoice.dark: widget.strings.darkTheme,
          },
          selected: _settings.theme,
          onChanged: (value) => _save(_settings.copyWith(theme: value)),
        ),
        _TextSetting(
          label: widget.strings.font,
          controller: _fontController,
          onSubmitted: (value) => _save(_settings.copyWith(fontFamily: value)),
        ),
        Text(widget.strings.visibleFormats,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        _FormatVisibilityGrid(
            settings: _settings, controller: widget.controller),
      ],
    );
  }

  Widget _advanced(BuildContext context) {
    return _SettingsSection(
      title: widget.strings.advanced,
      children: [
        _SwitchSetting(
          label: widget.strings.developerMode,
          value: _settings.developerMode,
          onChanged: (value) async {
            if (value) {
              final confirmed =
                  await _confirm(context, widget.strings.developerWarning);
              if (!confirmed) return;
            }
            _save(_settings.copyWith(developerMode: value));
          },
        ),
        if (_settings.developerMode)
          FilledButton.icon(
            onPressed: () => _editThemeJson(context),
            icon: const Icon(Icons.code_rounded, size: 18),
            label: Text(widget.strings.edit),
          ),
      ],
    );
  }

  Widget _custom() {
    return _SettingsSection(
      title: widget.strings.custom,
      children: [
        Text(
          widget.strings.isZh
              ? '自定义项会在开发者模式中通过主题 JSON 生效。'
              : 'Custom values are applied through the developer theme JSON.',
          style: const TextStyle(color: Color(0xFF6E6E73)),
        ),
      ],
    );
  }

  Widget _about(BuildContext context) {
    return _SettingsSection(
      title: widget.strings.about,
      children: [
        Text(widget.strings.aboutBody, style: const TextStyle(height: 1.45)),
        _SupportLinkRow(strings: widget.strings),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () async {
            final confirmed =
                await _confirm(context, widget.strings.resetWarning);
            if (confirmed) {
              await widget.controller.resetAll();
              setState(() => _settings = widget.controller.settings);
            }
          },
          icon: const Icon(Icons.restart_alt_rounded),
          label: Text(widget.strings.reset),
        ),
      ],
    );
  }

  Future<void> _editThemeJson(BuildContext context) async {
    final controller =
        TextEditingController(text: _settings.effectiveThemeJson);
    final error = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(widget.strings.edit),
        content: SizedBox(
          width: 620,
          height: 420,
          child: TextField(
            controller: controller,
            expands: true,
            maxLines: null,
            minLines: null,
            style: const TextStyle(fontFamily: 'Consolas', fontSize: 13),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(widget.strings.cancel)),
          FilledButton(
            onPressed: () async {
              final message =
                  await widget.controller.saveThemeJson(controller.text);
              if (context.mounted) Navigator.of(context).pop(message);
            },
            child: Text(widget.strings.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (error != null && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(error),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'))
          ],
        ),
      );
    }
    setState(() => _settings = widget.controller.settings);
  }

  Future<bool> _confirm(BuildContext context, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(widget.strings.cancel)),
              FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('OK')),
            ],
          ),
        ) ??
        false;
  }

  String _tabLabel(_SettingsTab tab) {
    return switch (tab) {
      _SettingsTab.general => widget.strings.common,
      _SettingsTab.preferences => widget.strings.preferences,
      _SettingsTab.advanced => widget.strings.advanced,
      _SettingsTab.custom => widget.strings.custom,
      _SettingsTab.about => widget.strings.about,
    };
  }

  void _save(AppSettings settings) {
    setState(() => _settings = settings);
    widget.controller.update(settings);
  }
}

class _SupportLinkRow extends StatefulWidget {
  final AppStrings strings;

  const _SupportLinkRow({required this.strings});

  @override
  State<_SupportLinkRow> createState() => _SupportLinkRowState();
}

class _SupportLinkRowState extends State<_SupportLinkRow> {
  static const _repoUrl = 'https://github.com/domin1c86/formatConv';
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(14),
        hoverColor: Colors.transparent,
        onTap: _openRepository,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _hovering ? const Color(0xFFF0F7FF) : const Color(0xFFFAFAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovering ? primary : const Color(0xFFE0E0E0),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.strings.clickSupport,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              CustomPaint(
                size: const Size(22, 22),
                painter: _GitHubLogoPainter(color: _hovering ? primary : const Color(0xFF1D1D1F)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openRepository() {
    if (Platform.isWindows) {
      Process.run('start', ['', _repoUrl], runInShell: true);
    }
  }
}

class _GitHubLogoPainter extends CustomPainter {
  final Color color;

  const _GitHubLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale, scale);

    final body = Path()
      ..moveTo(12, 2)
      ..cubicTo(6.48, 2, 2, 6.58, 2, 12.2)
      ..cubicTo(2, 16.68, 4.86, 20.48, 8.84, 21.82)
      ..cubicTo(9.34, 21.92, 9.52, 21.6, 9.52, 21.34)
      ..cubicTo(9.52, 21.1, 9.5, 20.46, 9.5, 19.62)
      ..cubicTo(6.72, 20.24, 6.14, 18.26, 6.14, 18.26)
      ..cubicTo(5.68, 17.08, 5.02, 16.76, 5.02, 16.76)
      ..cubicTo(4.1, 16.12, 5.08, 16.14, 5.08, 16.14)
      ..cubicTo(6.1, 16.22, 6.64, 17.22, 6.64, 17.22)
      ..cubicTo(7.54, 18.8, 9, 18.34, 9.58, 18.08)
      ..cubicTo(9.66, 17.42, 9.92, 16.96, 10.2, 16.7)
      ..cubicTo(7.98, 16.44, 5.64, 15.56, 5.64, 11.64)
      ..cubicTo(5.64, 10.52, 6.02, 9.6, 6.68, 8.9)
      ..cubicTo(6.58, 8.64, 6.22, 7.58, 6.78, 6.18)
      ..cubicTo(6.78, 6.18, 7.64, 5.9, 9.56, 7.24)
      ..cubicTo(10.36, 7.02, 11.22, 6.9, 12.08, 6.9)
      ..cubicTo(12.94, 6.9, 13.8, 7.02, 14.6, 7.24)
      ..cubicTo(16.52, 5.9, 17.36, 6.18, 17.36, 6.18)
      ..cubicTo(17.92, 7.58, 17.56, 8.64, 17.46, 8.9)
      ..cubicTo(18.12, 9.6, 18.5, 10.52, 18.5, 11.64)
      ..cubicTo(18.5, 15.58, 16.16, 16.44, 13.92, 16.7)
      ..cubicTo(14.28, 17.02, 14.6, 17.64, 14.6, 18.58)
      ..cubicTo(14.6, 19.94, 14.58, 21.04, 14.58, 21.34)
      ..cubicTo(14.58, 21.6, 14.76, 21.92, 15.28, 21.82)
      ..cubicTo(19.22, 20.46, 22, 16.68, 22, 12.2)
      ..cubicTo(22, 6.58, 17.52, 2, 12, 2)
      ..close();

    canvas.drawPath(body, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GitHubLogoPainter oldDelegate) => oldDelegate.color != color;
}

class _FormatVisibilityGrid extends StatefulWidget {
  final AppSettings settings;
  final SettingsController controller;

  const _FormatVisibilityGrid({
    required this.settings,
    required this.controller,
  });

  @override
  State<_FormatVisibilityGrid> createState() => _FormatVisibilityGridState();
}

class _FormatVisibilityGridState extends State<_FormatVisibilityGrid> {
  late AppSettings _settings = widget.settings;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        _formatColumn(
            'video', supportedVideoFormats, _settings.visibleVideoFormats),
        _formatColumn(
            'audio', supportedAudioFormats, _settings.visibleAudioFormats),
        _formatColumn(
            'image', supportedImageFormats, _settings.visibleImageFormats),
      ],
    );
  }

  Widget _formatColumn(
      String type, List<String> formats, Set<String> selected) {
    return SizedBox(
      width: 190,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: formats.map((format) {
          final active = selected.contains(format);
          return FilterChip(
            label: Text(format),
            selected: active,
            mouseCursor: SystemMouseCursors.click,
            onSelected: (enabled) async {
              await widget.controller.toggleFormat(type, format, enabled);
              setState(() => _settings = widget.controller.settings);
            },
          );
        }).toList(),
      ),
    );
  }
}

class _StickyPanel extends StatelessWidget {
  final Widget child;

  const _StickyPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: child,
    );
  }
}

class _TabItem<T> {
  final String label;
  final T value;

  const _TabItem(this.label, this.value);
}

class _TabStrip<T> extends StatelessWidget {
  final List<_TabItem<T>> tabs;
  final T selected;
  final ValueChanged<T> onChanged;

  const _TabStrip({
    required this.tabs,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final active = tab.value == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(tab.label),
              selected: active,
              mouseCursor: SystemMouseCursors.click,
              onSelected: (_) => onChanged(tab.value),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SideMenuButton extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SideMenuButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SideMenuButton> createState() => _SideMenuButtonState();
}

class _SideMenuButtonState extends State<_SideMenuButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(12),
        hoverColor: Colors.transparent,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: widget.selected
                ? Colors.white
                : _hovering
                    ? const Color(0xFFEAF4FF)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(widget.label,
            style: TextStyle(
                fontWeight:
                    widget.selected ? FontWeight.w600 : FontWeight.w400)),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        ...children.expand((child) => [child, const SizedBox(height: 14)]),
      ],
    );
  }
}

class _TextSetting extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? helper;
  final Widget? action;
  final ValueChanged<String> onSubmitted;

  const _TextSetting({
    required this.label,
    required this.controller,
    required this.onSubmitted,
    this.helper,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        suffixIcon: action,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SwitchSetting extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSetting({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      mouseCursor: SystemMouseCursors.click,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _SegmentSetting<T> extends StatelessWidget {
  final String label;
  final Map<T, String> values;
  final T selected;
  final ValueChanged<T> onChanged;

  const _SegmentSetting({
    required this.label,
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 110, child: Text(label)),
        SegmentedButton<T>(
          segments: values.entries
              .map((entry) =>
                  ButtonSegment<T>(value: entry.key, label: Text(entry.value)))
              .toList(),
          selected: {selected},
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
      ],
    );
  }
}

class _SliderSetting extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _SliderSetting({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 96, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            onChanged: (value) => onChanged(value.round()),
          ),
        ),
        SizedBox(width: 54, child: Text('$value%', textAlign: TextAlign.end)),
      ],
    );
  }
}

class _DropdownSetting extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> values;
  final ValueChanged<String?> onChanged;

  const _DropdownSetting({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value != null && values.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('Default')),
        ...values
            .map((value) => DropdownMenuItem(value: value, child: Text(value))),
      ],
      onChanged: onChanged,
    );
  }
}

class _ResultField extends StatelessWidget {
  final String label;
  final String value;

  const _ResultField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6E6E73))),
          const SizedBox(height: 2),
          Text(value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB3B3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB00020), size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style:
                      const TextStyle(color: Color(0xFF8A0017), fontSize: 13))),
        ],
      ),
    );
  }
}

_FileTab _fileType(String file) {
  final ext = p.extension(file).toLowerCase();
  if (_videoExtensions.contains(ext)) return _FileTab.video;
  if (_audioExtensions.contains(ext)) return _FileTab.audio;
  if (_imageExtensions.contains(ext)) return _FileTab.image;
  return _FileTab.all;
}

bool _matchesTab(String file, _FileTab tab) {
  return tab == _FileTab.all || _fileType(file) == tab;
}

List<String> _codecsFor(String format, _FileTab type) {
  if (type == _FileTab.video) {
    return switch (format.toUpperCase()) {
      'MP4' => ['H.264', 'H.265/HEVC', 'MPEG-4'],
      'MKV' => ['H.264', 'H.265/HEVC', 'VP8', 'VP9', 'AV1'],
      'MOV' => ['H.264', 'H.265/HEVC', 'ProRes'],
      'AVI' => ['MPEG-4', 'DivX', 'Xvid'],
      'WEBM' => ['VP8', 'VP9', 'AV1'],
      _ => const <String>[],
    };
  }
  if (type == _FileTab.audio) {
    return switch (format.toUpperCase()) {
      'MP3' => ['libmp3lame'],
      'AAC' => ['aac'],
      'OGG' => ['libvorbis', 'libopus'],
      'OPUS' => ['libopus'],
      'FLAC' => ['flac'],
      'WAV' => ['pcm_s16le'],
      _ => const <String>[],
    };
  }
  return const <String>[];
}

String _formatDuration(Duration duration) {
  final seconds = duration.inSeconds;
  if (seconds < 1) return '${duration.inMilliseconds}ms';
  final minutes = seconds ~/ 60;
  final remain = seconds % 60;
  return minutes > 0 ? '${minutes}m ${remain}s' : '${remain}s';
}

String _formatTime(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${time.year}-${two(time.month)}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}';
}
