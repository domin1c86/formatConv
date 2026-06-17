import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;

import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../models/conversion_options.dart';
import '../models/conversion_result.dart';
import '../providers/conversion_provider.dart';
import '../providers/settings_provider.dart';

enum _FileTab { all, video, audio, image }

enum _RightTab { formats, results }

enum _SettingsTab { general, preferences, advanced, about }

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
  final Set<String> _selectedFileCards = {};

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
                        child: DefaultTextStyle.merge(
                          style: const TextStyle(fontFamily: 'MiSans'),
                          child: _LeftPane(
                            strings: strings,
                            provider: provider,
                            selectedFiles: _selectedFileCards,
                            fileTab: _fileTab,
                            page: _page,
                            onFileTabChanged: (tab) => setState(() {
                              _fileTab = tab;
                              _page = 0;
                            }),
                            onPageChanged: (page) =>
                                setState(() => _page = page),
                            onFileSelectionChanged: _toggleFileSelection,
                            onFileRemoved: _removeFile,
                            onOpenSettings: () =>
                                _showSettings(settingsController),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: DefaultTextStyle.merge(
                          style: const TextStyle(fontFamily: 'MiSans'),
                          child: _RightPane(
                            strings: strings,
                            provider: provider,
                            settingsController: settingsController,
                            selectedFiles: _selectedFileCards,
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
                      ),
                    ],
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: contentWidth * 0.34,
                        child: DefaultTextStyle.merge(
                          style: const TextStyle(fontFamily: 'MiSans'),
                          child: _LeftPane(
                            strings: strings,
                            provider: provider,
                            selectedFiles: _selectedFileCards,
                            fileTab: _fileTab,
                            page: _page,
                            onFileTabChanged: (tab) => setState(() {
                              _fileTab = tab;
                              _page = 0;
                            }),
                            onPageChanged: (page) =>
                                setState(() => _page = page),
                            onFileSelectionChanged: _toggleFileSelection,
                            onFileRemoved: _removeFile,
                            onOpenSettings: () =>
                                _showSettings(settingsController),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: DefaultTextStyle.merge(
                          style: const TextStyle(fontFamily: 'MiSans'),
                          child: _RightPane(
                            strings: strings,
                            provider: provider,
                            settingsController: settingsController,
                            selectedFiles: _selectedFileCards,
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

  Future<void> _showSettings(SettingsController controller) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => _SettingsDialog(
        controller: controller,
      ),
    );
  }

  void _toggleFileSelection(String filePath) {
    setState(() {
      if (_selectedFileCards.contains(filePath)) {
        _selectedFileCards.remove(filePath);
      } else {
        _selectedFileCards.add(filePath);
      }
    });
  }

  void _removeFile(String filePath) {
    ref.read(conversionProvider).removeFile(filePath);
    setState(() => _selectedFileCards.remove(filePath));
  }
}

class _LeftPane extends StatelessWidget {
  final AppStrings strings;
  final ConversionProvider provider;
  final Set<String> selectedFiles;
  final _FileTab fileTab;
  final int page;
  final ValueChanged<_FileTab> onFileTabChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<String> onFileSelectionChanged;
  final ValueChanged<String> onFileRemoved;
  final VoidCallback onOpenSettings;

  const _LeftPane({
    required this.strings,
    required this.provider,
    required this.selectedFiles,
    required this.fileTab,
    required this.page,
    required this.onFileTabChanged,
    required this.onPageChanged,
    required this.onFileSelectionChanged,
    required this.onFileRemoved,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final controlHeightBudget = constraints.maxHeight * 0.16;
        final settingsHeight =
            math.min(54.0, math.max(46.0, controlHeightBudget * 0.36));
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
                selectedFiles: selectedFiles,
                processedFiles: provider.processedFiles,
                selectedTab: fileTab,
                page: page,
                onFilesAdded: provider.addFiles,
                onTabChanged: onFileTabChanged,
                onPageChanged: onPageChanged,
                onFileSelectionChanged: onFileSelectionChanged,
                onFileRemoved: onFileRemoved,
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
    final tokens = _themeTokens(context);
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
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          hoverColor: Colors.transparent,
          splashColor: tokens.primary.withValues(alpha: 0.08),
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
                  ? tokens.primary.withValues(alpha: 0.12)
                  : _hovering
                      ? tokens.hover
                      : tokens.surface,
              borderRadius: BorderRadius.circular(tokens.cardRadius),
              border: Border.all(
                color: _dragging ? tokens.primary : tokens.border,
                width: _dragging ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tokens.surfaceMuted,
                    borderRadius: BorderRadius.circular(
                        math.max(0, tokens.cardRadius - 2)),
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
                            ).copyWith(color: tokens.muted),
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
  final Set<String> selectedFiles;
  final Set<String> processedFiles;
  final _FileTab selectedTab;
  final int page;
  final ValueChanged<List<String>> onFilesAdded;
  final ValueChanged<_FileTab> onTabChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<String> onFileSelectionChanged;
  final ValueChanged<String> onFileRemoved;

  const _AddedFilesPanel({
    required this.strings,
    required this.files,
    required this.selectedFiles,
    required this.processedFiles,
    required this.selectedTab,
    required this.page,
    required this.onFilesAdded,
    required this.onTabChanged,
    required this.onPageChanged,
    required this.onFileSelectionChanged,
    required this.onFileRemoved,
  });

  @override
  State<_AddedFilesPanel> createState() => _AddedFilesPanelState();
}

class _AddedFilesPanelState extends State<_AddedFilesPanel> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final tokens = _themeTokens(context);
    final tabs = _availableTabs(widget.files, widget.strings);
    final filtered = widget.files
        .where((file) => _matchesTab(file, widget.selectedTab))
        .toList()
      ..sort((a, b) {
        final aDone = widget.processedFiles.contains(a);
        final bDone = widget.processedFiles.contains(b);
        if (aDone != bDone) return aDone ? 1 : -1;
        return p
            .basename(a)
            .toLowerCase()
            .compareTo(p.basename(b).toLowerCase());
      });
    const pageSize = 24;
    final totalPages = math.max(1, (filtered.length / pageSize).ceil());
    final currentPage = widget.page.clamp(0, totalPages - 1).toInt();
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
          color: _dragging ? tokens.hover : tokens.surface,
          borderRadius: BorderRadius.circular(tokens.cardRadius + 4),
          border: Border.all(
            color: _dragging ? tokens.primary : tokens.border,
            width: _dragging ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.strings.addedFiles,
                    style: TextStyle(
                      color: tokens.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.selectedFiles.isNotEmpty)
                  Text(
                    widget.strings.selectedCardCount(
                      widget.selectedFiles.length,
                    ),
                    style: TextStyle(color: tokens.muted, fontSize: 12),
                  ),
              ],
            ),
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
                        style: TextStyle(color: tokens.muted),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 420 ? 3 : 2;
                        final denseColumns =
                            (constraints.maxWidth / 112).floor().clamp(3, 6);
                        return GridView.builder(
                          itemCount: visible.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: constraints.maxWidth >= 360
                                ? denseColumns
                                : columns,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.82,
                          ),
                          itemBuilder: (context, index) {
                            final file = visible[index];
                            return _FileCard(
                              key: ValueKey(file),
                              strings: widget.strings,
                              filePath: file,
                              selected: widget.selectedFiles.contains(file),
                              processed: widget.processedFiles.contains(file),
                              selectedFiles: widget.selectedFiles,
                              onToggleSelected: () =>
                                  widget.onFileSelectionChanged(file),
                              onRemove: () => widget.onFileRemoved(file),
                            );
                          },
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
  final AppStrings strings;
  final String filePath;
  final bool selected;
  final bool processed;
  final Set<String> selectedFiles;
  final VoidCallback onToggleSelected;
  final VoidCallback onRemove;

  const _FileCard({
    super.key,
    required this.strings,
    required this.filePath,
    required this.selected,
    required this.processed,
    required this.selectedFiles,
    required this.onToggleSelected,
    required this.onRemove,
  });

  @override
  State<_FileCard> createState() => _FileCardState();
}

class _FileCardState extends State<_FileCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final tokens = _themeTokens(context);
    final name = p.basename(widget.filePath);
    final type = _fileType(widget.filePath);
    final accent =
        (widget.processed ? const Color(0xFF52FF88) : _typeColor(type))
            .withValues(alpha: _hovering ? 0.5 : 1);
    final icon = switch (type) {
      _FileTab.video => Icons.movie_outlined,
      _FileTab.audio => Icons.graphic_eq_rounded,
      _FileTab.image => Icons.image_outlined,
      _FileTab.all => Icons.insert_drive_file_outlined,
    };
    const cardHeight = 116.0;
    const closeIconSize = cardHeight / 5;

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: _hovering
            ? tokens.primary.withValues(alpha: 0.16)
            : tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(
          color: widget.selected
              ? tokens.primary
              : _hovering
                  ? tokens.primary
                  : tokens.border,
          width: widget.selected ? 2.8 : 1.5,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(math.max(0, tokens.cardRadius - 4)),
                  border: Border.all(color: accent, width: 2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: BorderRadius.circular(
                          math.max(0, tokens.cardRadius - 7)),
                      border: Border.all(color: tokens.border),
                    ),
                    child: switch (type) {
                      _FileTab.image => Image.file(
                          File(widget.filePath),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            icon,
                            size: 26,
                            color: tokens.muted,
                          ),
                        ),
                      _FileTab.video => _VideoPreview(
                          filePath: widget.filePath,
                          fallback: Icon(icon, size: 26, color: tokens.muted),
                        ),
                      _ => Icon(icon, size: 26, color: tokens.muted),
                    },
                  ),
                ),
                const SizedBox(height: 5),
                Tooltip(
                  message: name,
                  waitDuration: const Duration(milliseconds: 1500),
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: tokens.ink,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 3,
            right: 3,
            child: IgnorePointer(
              ignoring: !_hovering,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: _hovering ? 1 : 0,
                child: Tooltip(
                  message: widget.strings.removeFile,
                  waitDuration: const Duration(milliseconds: 500),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onRemove,
                      child: Container(
                        width: closeIconSize + 8,
                        height: closeIconSize + 8,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: tokens.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: tokens.border),
                        ),
                        child: SvgPicture.asset(
                          'windows/runner/resources/close.svg',
                          width: closeIconSize,
                          height: closeIconSize,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final dragFiles = widget.selected && widget.selectedFiles.isNotEmpty
        ? widget.selectedFiles.toList()
        : [widget.filePath];

    return Draggable<List<String>>(
      data: dragFiles,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 96, height: 116, child: child),
      ),
      childWhenDragging: Opacity(opacity: 0.45, child: child),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: InkWell(
          mouseCursor: SystemMouseCursors.grab,
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          onTap: widget.onToggleSelected,
          child: child,
        ),
      ),
    );
  }
}

class _VideoPreview extends StatefulWidget {
  final String filePath;
  final Widget fallback;

  const _VideoPreview({required this.filePath, required this.fallback});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late final Future<File?> _thumbnail = _loadThumbnail();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _thumbnail,
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file != null && file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => widget.fallback,
          );
        }
        return widget.fallback;
      },
    );
  }

  Future<File?> _loadThumbnail() async {
    final cacheDir = Directory(p.join(
      Directory.systemTemp.path,
      'formatconv_video_thumbnails',
    ));
    try {
      cacheDir.createSync(recursive: true);
      final stat = File(widget.filePath).statSync();
      final cacheKey =
          '${widget.filePath.hashCode.abs()}_${stat.modified.millisecondsSinceEpoch}';
      final output = File(p.join(cacheDir.path, '$cacheKey.jpg'));
      if (output.existsSync()) return output;

      final ffmpeg = _resolveFfmpegExecutable();
      final result = await Process.run(
        ffmpeg,
        [
          '-y',
          '-ss',
          '00:00:01',
          '-i',
          widget.filePath,
          '-frames:v',
          '1',
          '-vf',
          'scale=240:-1',
          output.path,
        ],
        runInShell: false,
      );
      if (result.exitCode == 0 && output.existsSync()) return output;
    } catch (_) {}
    return null;
  }
}

class _RightPane extends StatelessWidget {
  final AppStrings strings;
  final ConversionProvider provider;
  final SettingsController settingsController;
  final Set<String> selectedFiles;
  final _RightTab rightTab;
  final bool showHistory;
  final ValueChanged<_RightTab> onRightTabChanged;
  final VoidCallback onShowHistory;
  final VoidCallback onShowCurrent;

  const _RightPane({
    required this.strings,
    required this.provider,
    required this.settingsController,
    required this.selectedFiles,
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
                    selectedFiles: selectedFiles,
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
  final Set<String> selectedFiles;
  final VoidCallback onShowResults;

  const _FormatSelection({
    required this.strings,
    required this.provider,
    required this.settingsController,
    required this.selectedFiles,
    required this.onShowResults,
  });

  @override
  State<_FormatSelection> createState() => _FormatSelectionState();
}

class _FormatSelectionState extends State<_FormatSelection> {
  final Map<String, ConversionOptions> _options = {};

  @override
  Widget build(BuildContext context) {
    final tokens = _themeTokens(context);
    final settings = widget.settingsController.settings;
    final files = widget.selectedFiles.isNotEmpty
        ? widget.selectedFiles.toList()
        : widget.provider.selectedFiles;
    final hasVideo = files
        .any((file) => _fileType(file) == _FileTab.video || _isGifFile(file));
    final hasAudio = files.any((file) => _fileType(file) == _FileTab.audio);
    final hasImage = files.any((file) => _fileType(file) == _FileTab.image);
    final showVideoToGif = hasVideo && !hasAudio && !hasImage;
    final imageFormats = supportedImageFormats.where((format) {
      if (!settings.visibleImageFormats.contains(format)) return false;
      return hasImage || (showVideoToGif && format.toUpperCase() == 'GIF');
    }).toList();

    final content = <Widget>[
      if (files.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Text(
            widget.strings.emptyFormatHint,
            style: TextStyle(color: tokens.muted),
          ),
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
      if (imageFormats.isNotEmpty)
        _FormatRow(
          title: widget.strings.imageFormats,
          type: _FileTab.image,
          formats: imageFormats,
          strings: widget.strings,
          getOptions: _getOptions,
          onOptionsChanged: _setOptions,
          onConvert: _convert,
        ),
      if (!hasVideo && !hasAudio && !hasImage && files.isNotEmpty)
        Text(
          widget.strings.unsupportedFileType,
          style: const TextStyle(color: Color(0xFFE6A23C)),
        ),
      const SizedBox(height: 164),
    ];

    return Stack(
      children: [
        ListView(children: content),
        if (widget.provider.conversionTasks.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ConversionTaskShelf(
              tasks: widget.provider.conversionTasks,
              onCancelTask: (taskId) => widget.provider.cancelTask(taskId),
            ),
          ),
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

  Future<void> _convert(
    BuildContext context,
    _FileTab type,
    String format,
    List<String>? files,
  ) async {
    final sourceFiles = files ??
        (widget.selectedFiles.isNotEmpty
            ? widget.selectedFiles.toList()
            : widget.provider.selectedFiles);
    final compatible = _compatibleFiles(type, format, sourceFiles);
    final skipped = sourceFiles
        .where((file) => !compatible.contains(file))
        .map(p.basename)
        .toList();

    if (skipped.isNotEmpty) {
      _showTopNotice(
        context,
        '${widget.strings.typeMismatchTitle}\n${widget.strings.typeMismatchMessage(skipped)}',
      );
    }
    if (compatible.isEmpty) return;

    final currentSettings = widget.settingsController.settings;
    AppSettings effectiveSettings = currentSettings;
    if (currentSettings.askBeforeConvert) {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null || selectedDirectory.isEmpty) {
        return;
      }
      effectiveSettings =
          currentSettings.copyWith(defaultOutputDirectory: selectedDirectory);
    }

    await widget.provider.startConversion(
      format,
      _getOptions(format).copyWith(
        overwrite: effectiveSettings.overwriteSource,
        gpuAcceleration: effectiveSettings.gpuAcceleration,
      ),
      files: compatible,
      settings: effectiveSettings,
      onResult: widget.settingsController.addHistory,
    );
  }
}

class _ConversionTaskShelf extends StatefulWidget {
  final List<ConversionTask> tasks;
  final void Function(String taskId) onCancelTask;

  const _ConversionTaskShelf({
    required this.tasks,
    required this.onCancelTask,
  });

  @override
  State<_ConversionTaskShelf> createState() => _ConversionTaskShelfState();
}

class _ConversionTaskShelfState extends State<_ConversionTaskShelf> {
  final ScrollController _scrollController = ScrollController();
  int _lastTaskCount = 0;

  @override
  void initState() {
    super.initState();
    _lastTaskCount = widget.tasks.length;
  }

  @override
  void didUpdateWidget(covariant _ConversionTaskShelf oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tasks.length > _lastTaskCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.minScrollExtent,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
    _lastTaskCount = widget.tasks.length;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = _themeTokens(context);
    final orderedTasks = widget.tasks.reversed.toList(growable: false);
    return Center(
      child: Container(
        width: 420,
        height: 140,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: tokens.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(tokens.cardRadius + 4),
          border: Border.all(color: tokens.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          notificationPredicate: (notification) => notification.depth == 0,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 10),
            itemCount: orderedTasks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _ConversionTaskCard(
              task: orderedTasks[index],
              onCancel: () => widget.onCancelTask(orderedTasks[index].id),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversionTaskCard extends StatefulWidget {
  final ConversionTask task;
  final VoidCallback onCancel;

  const _ConversionTaskCard({
    required this.task,
    required this.onCancel,
  });

  @override
  State<_ConversionTaskCard> createState() => _ConversionTaskCardState();
}

class _ConversionTaskCardState extends State<_ConversionTaskCard> {
  bool _showCancel = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted &&
          !widget.task.completed &&
          widget.task.conversionId != null) {
        setState(() => _showCancel = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = _themeTokens(context);
    final progress = widget.task.completed && !widget.task.failed
        ? 1.0
        : widget.task.progress.clamp(0.0, 1.0).toDouble();
    const cardWidth = 96.0;
    const cardHeight = 116.0;
    const statusIconSize = cardHeight / 5;
    final canOpen = widget.task.completed &&
        !widget.task.failed &&
        widget.task.outputPath.isNotEmpty &&
        File(widget.task.outputPath).existsSync();
    final displayName = widget.task.outputPath.isNotEmpty
        ? p.basename(widget.task.outputPath)
        : p.basename(widget.task.inputPath);
    final elapsedLongEnough =
        DateTime.now().difference(widget.task.startedAt) >=
            const Duration(milliseconds: 1500);
    final canCancel = (_showCancel || elapsedLongEnough) &&
        !widget.task.completed &&
        widget.task.conversionId != null &&
        !widget.task.cancelled;
    final cancelOpacity = !canCancel
        ? 0.0
        : progress >= 0.95
            ? (1 - ((progress - 0.95) / 0.05)).clamp(0.0, 1.0).toDouble()
            : 1.0;

    return MouseRegion(
      cursor: canOpen ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: InkWell(
        mouseCursor:
            canOpen ? SystemMouseCursors.click : SystemMouseCursors.basic,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        onTap: canOpen ? () => _openPath(widget.task.outputPath) : null,
        child: Tooltip(
          message: displayName,
          waitDuration: const Duration(milliseconds: 1500),
          child: Container(
            width: cardWidth,
            height: cardHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(tokens.cardRadius),
              border: Border.all(
                color: canOpen ? const Color(0xFF52FF88) : tokens.border,
              ),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: double.infinity,
                    height: cardHeight * progress,
                    color: const Color(0xFF61C5FF).withValues(alpha: 0.85),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Expanded(
                        child: _TaskPreview(
                          inputPath: widget.task.inputPath,
                          outputPath: widget.task.outputPath,
                          showOutputPreview: canOpen,
                        ),
                      ),
                      Text(
                        displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: tokens.ink,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 450),
                    opacity: canOpen ? 1 : 0,
                    child: SvgPicture.asset(
                      'windows/runner/resources/finished.svg',
                      width: statusIconSize,
                      height: statusIconSize,
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: IgnorePointer(
                    ignoring: cancelOpacity <= 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 650),
                      opacity: cancelOpacity,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onCancel,
                          child: SizedBox(
                            width: statusIconSize + 8,
                            height: statusIconSize + 8,
                            child: Center(
                              child: SvgPicture.asset(
                                'windows/runner/resources/cancel.svg',
                                width: statusIconSize,
                                height: statusIconSize,
                              ),
                            ),
                          ),
                        ),
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

class _TaskPreview extends StatelessWidget {
  final String inputPath;
  final String outputPath;
  final bool showOutputPreview;

  const _TaskPreview({
    required this.inputPath,
    required this.outputPath,
    required this.showOutputPreview,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = _themeTokens(context);
    final previewPath =
        showOutputPreview && outputPath.isNotEmpty ? outputPath : inputPath;
    final type = _fileType(previewPath);
    final fallback = Icon(
      type == _FileTab.audio
          ? Icons.graphic_eq_rounded
          : type == _FileTab.image
              ? Icons.image_outlined
              : Icons.movie_outlined,
      color: tokens.ink,
      size: 24,
    );

    if (!showOutputPreview) return fallback;

    if (type == _FileTab.image) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(previewPath),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    }

    if (type == _FileTab.video) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _VideoPreview(
          filePath: previewPath,
          fallback: fallback,
        ),
      );
    }

    return fallback;
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
  final void Function(
    BuildContext context,
    _FileTab type,
    String format,
    List<String>? files,
  ) onConvert;

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
                          onConvert: (context, files) =>
                              onConvert(context, type, format, files),
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
  final void Function(BuildContext context, List<String>? files) onConvert;

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
      onWillAcceptWithDetails: (details) =>
          _compatibleFiles(widget.type, widget.format, details.data).isNotEmpty,
      onAcceptWithDetails: (details) => widget.onConvert(context, details.data),
      builder: (context, candidateData, rejectedData) {
        final tokens = _themeTokens(context);
        final active = candidateData.isNotEmpty;
        final rejected = rejectedData.isNotEmpty;
        final dark = Theme.of(context).brightness == Brightness.dark;
        return MouseRegion(
          cursor: rejected
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 118,
            height: 54,
            decoration: BoxDecoration(
              color: active
                  ? tokens.primary.withValues(alpha: 0.10)
                  : rejected
                      ? (dark
                          ? const Color(0xFF3A2022)
                          : const Color(0xFFFFF1F1))
                      : _hovering
                          ? tokens.hover
                          : tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(tokens.cardRadius),
              border: Border.all(
                color: rejected
                    ? const Color(0xFFE5484D)
                    : active || _hovering
                        ? tokens.primary
                        : tokens.border,
                width: active ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    mouseCursor: SystemMouseCursors.click,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12)),
                    onTap: () => widget.onConvert(context, null),
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
    final fields = <Widget>[
      _SliderSetting(
        label: widget.strings.compressionRatio,
        value: _options.quality,
        onChanged: (value) =>
            _update(_options.copyWith(quality: value, lossless: value >= 100)),
      ),
      if (bitrates.isNotEmpty)
        _DropdownSetting(
          label: widget.strings.bitrate,
          value: _options.bitrate,
          values: bitrates,
          strings: widget.strings,
          onChanged: (value) => _update(_options.copyWith(bitrate: value)),
        ),
      if (codecs.isNotEmpty)
        _DropdownSetting(
          label: widget.strings.codec,
          value: _options.codec,
          values: codecs,
          strings: widget.strings,
          onChanged: (value) => _update(_options.copyWith(codec: value)),
        ),
      if (algorithms.isNotEmpty)
        _DropdownSetting(
          label: widget.strings.compressionAlgorithm,
          value: _options.compressionAlgorithm,
          values: algorithms,
          strings: widget.strings,
          onChanged: (value) =>
              _update(_options.copyWith(compressionAlgorithm: value)),
        ),
    ];

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(_themeTokens(context).cardRadius + 4),
      ),
      title: Text('${widget.strings.formatSettings} - ${widget.format}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: fields
              .expand((field) => [field, const SizedBox(height: 20)])
              .take(fields.length * 2 - 1)
              .toList(),
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
    final tokens = _themeTokens(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        hoverColor: Colors.transparent,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _hovering ? tokens.hover : tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(tokens.cardRadius),
            border: Border.all(
              color: _hovering ? tokens.primary : tokens.border,
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
    final tokens = _themeTokens(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: result.success
            ? tokens.surface
            : dark
                ? const Color(0xFF331E22)
                : const Color(0xFFFFF6F6),
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(
            color: result.success ? tokens.border : const Color(0xFFFFB3B3)),
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
  final SettingsController controller;

  const _SettingsDialog({
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
  late final TextEditingController _iconPathController =
      TextEditingController(text: _settings.appIconPath);
  String? _templateError;

  AppStrings get strings => AppStrings(_settings.language);

  @override
  void dispose() {
    _directoryController.dispose();
    _templateController.dispose();
    _iconPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = _themeTokens(context);
    return DefaultTextStyle.merge(
      style: const TextStyle(fontFamily: 'MiSans'),
      child: Dialog(
        insetPadding: const EdgeInsets.all(24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius + 8),
        ),
        child: ColoredBox(
          color: tokens.surface,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980, maxHeight: 720),
            child: Row(
              children: [
                Container(
                  width: 180,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tokens.background,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(tokens.cardRadius + 8),
                    ),
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
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return switch (_tab) {
      _SettingsTab.general => _general(),
      _SettingsTab.preferences => _preferences(),
      _SettingsTab.advanced => _advanced(context),
      _SettingsTab.about => _about(context),
    };
  }

  Widget _general() {
    return _SettingsSection(
      title: strings.common,
      children: [
        _TextSetting(
          label: strings.defaultOutputDirectory,
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
          label: strings.askBeforeConvert,
          value: _settings.askBeforeConvert,
          onChanged: (value) =>
              _save(_settings.copyWith(askBeforeConvert: value)),
        ),
        _NamingTemplateSetting(
          strings: strings,
          controller: _templateController,
          errorText: _templateError,
          onChanged: _saveNamingTemplate,
        ),
        _SwitchSetting(
          label: strings.overwriteSource,
          value: _settings.overwriteSource,
          onChanged: (value) =>
              _save(_settings.copyWith(overwriteSource: value)),
        ),
        _SwitchSetting(
          label: strings.gpuAcceleration,
          value: _settings.gpuAcceleration,
          onChanged: (value) =>
              _save(_settings.copyWith(gpuAcceleration: value)),
        ),
      ],
    );
  }

  Widget _preferences() {
    return _SettingsSection(
      title: strings.preferences,
      children: [
        _SegmentSetting<AppLanguage>(
          label: strings.language,
          values: {
            AppLanguage.en: strings.languageEnglish,
            AppLanguage.zh: strings.languageChinese,
          },
          selected: _settings.language,
          onChanged: (value) => _save(_settings.copyWith(language: value)),
        ),
        _SegmentSetting<AppThemeChoice>(
          label: strings.theme,
          values: {
            AppThemeChoice.light: strings.lightTheme,
            AppThemeChoice.dark: strings.darkTheme,
          },
          selected: _settings.theme,
          onChanged: (value) => _save(_settings.copyWith(theme: value)),
        ),
        Text(strings.visibleFormats,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        _FormatVisibilityGrid(
            settings: _settings, controller: widget.controller),
      ],
    );
  }

  Widget _advanced(BuildContext context) {
    return _SettingsSection(
      title: strings.advanced,
      children: [
        _SwitchSetting(
          label: strings.developerMode,
          value: _settings.developerMode,
          onChanged: (value) async {
            if (value) {
              final confirmed =
                  await _confirm(context, strings.developerWarning);
              if (!confirmed) return;
            }
            _save(_settings.copyWith(developerMode: value));
          },
        ),
        if (_settings.developerMode)
          _SettingsSectionCard(
            title: strings.appearance,
            children: [
              FilledButton.icon(
                onPressed: () => _editThemeJson(context),
                icon: const Icon(Icons.palette_outlined, size: 18),
                label: Text(strings.themeColors),
              ),
              _TextSetting(
                label: strings.appIconPath,
                controller: _iconPathController,
                helper: strings.appIconTip,
                action: IconButton(
                  icon: const Icon(Icons.image_outlined),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['ico'],
                    );
                    final paths = result?.paths.whereType<String>().toList();
                    final path =
                        paths == null || paths.isEmpty ? null : paths.first;
                    if (path != null) {
                      _iconPathController.text = path;
                      _save(_settings.copyWith(appIconPath: path));
                    }
                  },
                ),
                onSubmitted: (value) =>
                    _save(_settings.copyWith(appIconPath: value)),
              ),
              _SliderSetting(
                label: strings.cardRadius,
                value: _settings.cardRadius.round().clamp(0, 36).toInt(),
                min: 0,
                max: 36,
                suffix: 'px',
                onChanged: (value) =>
                    _save(_settings.copyWith(cardRadius: value.toDouble())),
              ),
            ],
          ),
      ],
    );
  }

  Widget _about(BuildContext context) {
    return _SettingsSection(
      title: strings.about,
      children: [
        Text(strings.aboutBody, style: const TextStyle(height: 1.45)),
        _SettingsSectionCard(
          title: strings.thirdPartyLicenses,
          children: [
            Text(
              strings.ffmpegThirdPartyNotice,
              style: TextStyle(color: _themeTokens(context).ink, height: 1.45),
            ),
            Text(
              strings.imageMagickThirdPartyNotice,
              style: TextStyle(color: _themeTokens(context).ink, height: 1.45),
            ),
            Text(
              strings.miSansThirdPartyNotice,
              style: TextStyle(color: _themeTokens(context).ink, height: 1.45),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _openBundledThirdPartyNotices,
                icon: const Icon(Icons.description_outlined),
                label: Text(strings.openThirdPartyNotices),
              ),
            ),
          ],
        ),
        _SupportLinkRow(
          strings: strings,
          serviceLabel: strings.github,
          url: 'https://github.com/domin1c86/formatConv',
          icon: _SupportIcon.github,
        ),
        _SupportLinkRow(
          strings: strings,
          serviceLabel: strings.gitee,
          url: 'https://gitee.com/domin1c/format-conv',
          icon: _SupportIcon.gitee,
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () async {
            final confirmed = await _confirm(context, strings.resetWarning);
            if (confirmed) {
              await widget.controller.resetAll();
              setState(() => _settings = widget.controller.settings);
            }
          },
          icon: const Icon(Icons.restart_alt_rounded),
          label: Text(strings.reset),
        ),
      ],
    );
  }

  Future<void> _editThemeJson(BuildContext context) async {
    final themeJson = _settings.themeJson.isEmpty
        ? const JsonEncoder.withIndent('  ').convert(
            _settings.theme == AppThemeChoice.dark
                ? defaultDarkThemeTokens
                : defaultLightThemeTokens,
          )
        : _settings.effectiveThemeJson;
    final controller = TextEditingController(text: themeJson);
    final error = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(strings.edit),
        content: SizedBox(
          width: 620,
          height: 420,
          child: TextField(
            controller: controller,
            expands: true,
            maxLines: null,
            minLines: null,
            style: const TextStyle(fontFamily: 'MiSans', fontSize: 13),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.cancel)),
          FilledButton(
            onPressed: () async {
              final message = await widget.controller.saveThemeJson(
                controller.text,
                strings,
              );
              if (context.mounted) Navigator.of(context).pop(message);
            },
            child: Text(strings.save),
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
                child: Text(strings.confirm))
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
                  child: Text(strings.cancel)),
              FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(strings.confirm)),
            ],
          ),
        ) ??
        false;
  }

  String _tabLabel(_SettingsTab tab) {
    return switch (tab) {
      _SettingsTab.general => strings.common,
      _SettingsTab.preferences => strings.preferences,
      _SettingsTab.advanced => strings.advanced,
      _SettingsTab.about => strings.about,
    };
  }

  void _save(AppSettings settings) {
    setState(() => _settings = settings);
    widget.controller.update(settings);
  }

  void _saveNamingTemplate(String value) {
    final matches = RegExp(r'\$num').allMatches(value).length;
    if (matches != 1) {
      setState(() => _templateError = strings.namingTemplateRule);
      return;
    }
    setState(() => _templateError = null);
    _save(_settings.copyWith(namingTemplate: value));
  }
}

enum _SupportIcon { github, gitee }

class _SupportLinkRow extends StatefulWidget {
  final AppStrings strings;
  final String serviceLabel;
  final String url;
  final _SupportIcon icon;

  const _SupportLinkRow({
    required this.strings,
    required this.serviceLabel,
    required this.url,
    required this.icon,
  });

  @override
  State<_SupportLinkRow> createState() => _SupportLinkRowState();
}

class _SupportLinkRowState extends State<_SupportLinkRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final tokens = _themeTokens(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(14),
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: _openRepository,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _hovering ? tokens.hover : tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(tokens.cardRadius),
            border: Border.all(
              color: _hovering ? tokens.primary : tokens.border,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.strings.clickSupport,
                  style: TextStyle(
                    color: tokens.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                widget.serviceLabel,
                style: TextStyle(
                  color: _hovering ? tokens.primary : tokens.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              _SupportLogo(
                icon: widget.icon,
                color: _hovering ? tokens.primary : tokens.ink,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openRepository() {
    if (Platform.isWindows) {
      Process.run('start', ['', widget.url], runInShell: true);
    }
  }
}

class _SupportLogo extends StatelessWidget {
  final _SupportIcon icon;
  final Color color;

  const _SupportLogo({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    if (icon == _SupportIcon.github) {
      return CustomPaint(
        size: const Size(22, 22),
        painter: _GitHubLogoPainter(color: color),
      );
    }
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'G',
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
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
  bool shouldRepaint(_GitHubLogoPainter oldDelegate) =>
      oldDelegate.color != color;
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
  void didUpdateWidget(covariant _FormatVisibilityGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(_settings.language);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _formatSection(strings.video, 'video', supportedVideoFormats,
            _settings.visibleVideoFormats),
        const SizedBox(height: 14),
        _formatSection(strings.audio, 'audio', supportedAudioFormats,
            _settings.visibleAudioFormats),
        const SizedBox(height: 14),
        _formatSection(strings.image, 'image', supportedImageFormats,
            _settings.visibleImageFormats),
      ],
    );
  }

  Widget _formatSection(
    String title,
    String type,
    List<String> formats,
    Set<String> selected,
  ) {
    final tokens = _themeTokens(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(color: tokens.ink, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: formats.map((format) {
            final active = selected.contains(format);
            return _FormatVisibilityCard(
              label: format,
              active: active,
              onTap: () async {
                await widget.controller.toggleFormat(type, format, !active);
                setState(() => _settings = widget.controller.settings);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _FormatVisibilityCard extends StatefulWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FormatVisibilityCard({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<_FormatVisibilityCard> createState() => _FormatVisibilityCardState();
}

class _FormatVisibilityCardState extends State<_FormatVisibilityCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final tokens = _themeTokens(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 72,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.active
                ? tokens.primary.withValues(alpha: 0.16)
                : _hovering
                    ? tokens.hover
                    : tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(tokens.cardRadius),
            border: Border.all(
              color:
                  widget.active || _hovering ? tokens.primary : tokens.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.ink,
                    fontSize: 12,
                    fontWeight:
                        widget.active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                widget.active ? Icons.check_rounded : Icons.add_rounded,
                size: 13,
                color: widget.active ? tokens.primary : tokens.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickyPanel extends StatelessWidget {
  final Widget child;

  const _StickyPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final tokens = _themeTokens(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.cardRadius + 4),
        border: Border.all(color: tokens.border),
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
    final tokens = _themeTokens(context);
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
              labelStyle: TextStyle(
                fontFamily: 'MiSans',
                color: tokens.ink,
                fontSize: 14,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
              selectedColor: tokens.primary.withValues(alpha: 0.16),
              backgroundColor: tokens.surface,
              disabledColor: tokens.surfaceMuted,
              side: BorderSide(
                color: active
                    ? tokens.primary.withValues(alpha: 0.25)
                    : tokens.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
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
    final tokens = _themeTokens(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hoverFill = dark ? const Color(0xFF34343A) : const Color(0xFFE8E8EC);
    final hoverBorder =
        dark ? const Color(0xFF34343A) : const Color(0xFFE8E8EC);
    final selectedFill =
        dark ? const Color(0xFF20324A) : const Color(0xFFE3F1FF);
    final fillColor = widget.selected
        ? selectedFill
        : _hovering
            ? hoverFill
            : Colors.transparent;
    final borderColor = widget.selected
        ? tokens.primary
        : _hovering
            ? hoverBorder
            : Colors.transparent;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(tokens.cardRadius),
            border: Border.all(color: borderColor),
          ),
          child: Text(widget.label,
              style: TextStyle(
                  color: tokens.ink,
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
            style: TextStyle(
              color: _themeTokens(context).ink,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 20),
        ...children.expand((child) => [child, const SizedBox(height: 14)]),
      ],
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = _themeTokens(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: tokens.ink, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...children.expand((child) => [child, const SizedBox(height: 12)]),
        ],
      ),
    );
  }
}

class _NamingTemplateSetting extends StatelessWidget {
  final AppStrings strings;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const _NamingTemplateSetting({
    required this.strings,
    required this.controller,
    required this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = _themeTokens(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.namingTemplate,
          style: TextStyle(color: tokens.ink, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              strings.namingTemplatePrefix,
              style: TextStyle(
                color: tokens.ink,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(
              width: 180,
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: onChanged,
                decoration: InputDecoration(
                  isDense: true,
                  errorText: errorText,
                  helperText: strings.namingTemplateRule,
                ),
              ),
            ),
            Text(
              strings.namingTemplateSuffix,
              style: TextStyle(
                color: tokens.ink,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
    final tokens = _themeTokens(context);
    return Row(
      children: [
        SizedBox(width: 110, child: Text(label)),
        SegmentedButton<T>(
          segments: values.entries
              .map((entry) =>
                  ButtonSegment<T>(value: entry.key, label: Text(entry.value)))
              .toList(),
          selected: {selected},
          style: ButtonStyle(
            mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return tokens.primary;
              return tokens.ink;
            }),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return tokens.primary.withValues(alpha: 0.16);
              }
              if (states.contains(WidgetState.hovered)) return tokens.hover;
              return tokens.surfaceMuted;
            }),
            side: WidgetStateProperty.resolveWith((states) {
              return BorderSide(
                color: states.contains(WidgetState.selected)
                    ? tokens.primary
                    : tokens.border,
              );
            }),
          ),
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
      ],
    );
  }
}

class _SliderSetting extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final String suffix;
  final ValueChanged<int> onChanged;

  const _SliderSetting({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 100,
    this.suffix = '%',
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(min, max).toInt();
    return Row(
      children: [
        SizedBox(width: 96, child: Text(label)),
        Expanded(
          child: Slider(
            value: clampedValue.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (value) => onChanged(value.round()),
          ),
        ),
        SizedBox(
          width: 54,
          child: Text('$clampedValue$suffix', textAlign: TextAlign.end),
        ),
      ],
    );
  }
}

class _DropdownSetting extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> values;
  final AppStrings strings;
  final ValueChanged<String?> onChanged;

  const _DropdownSetting({
    required this.label,
    required this.value,
    required this.values,
    required this.strings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = _themeTokens(context);
    return DropdownButtonFormField<String>(
      initialValue: value != null && values.contains(value) ? value : null,
      isDense: true,
      menuMaxHeight: 240,
      dropdownColor: tokens.surfaceMuted,
      borderRadius: BorderRadius.circular(tokens.cardRadius),
      style: TextStyle(color: tokens.ink, fontSize: 13),
      iconEnabledColor: tokens.ink,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: tokens.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          borderSide: BorderSide(color: tokens.primary),
        ),
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(strings.defaultOption),
        ),
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
    final tokens = _themeTokens(context);
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: tokens.muted)),
          const SizedBox(height: 2),
          Text(value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: tokens.ink, fontWeight: FontWeight.w600)),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF331E22) : const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(_themeTokens(context).cardRadius),
        border: Border.all(color: const Color(0xFFFFB3B3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB00020), size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: TextStyle(
                    color: dark
                        ? const Color(0xFFFFC7C7)
                        : const Color(0xFF8A0017),
                    fontSize: 13,
                  ))),
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

Color _typeColor(_FileTab type) {
  return switch (type) {
    _FileTab.video => const Color(0xFF764DF0),
    _FileTab.audio => const Color(0xFFF0C74D),
    _FileTab.image => const Color(0xFFFC7E7E),
    _FileTab.all => const Color(0xFF9CA3AF),
  };
}

bool _isGifFile(String file) => p.extension(file).toLowerCase() == '.gif';

bool _isCompatibleWithTarget(_FileTab targetType, String format, String file) {
  final sourceType = _fileType(file);
  final targetFormat = format.toUpperCase();
  if (targetType == _FileTab.video && _isGifFile(file)) return true;
  if (targetType == _FileTab.image &&
      targetFormat == 'GIF' &&
      sourceType == _FileTab.video) {
    return true;
  }
  return sourceType == targetType;
}

List<String> _compatibleFiles(
  _FileTab targetType,
  String format,
  List<String> files,
) {
  return files
      .where((file) => _isCompatibleWithTarget(targetType, format, file))
      .toList();
}

String _resolveFfmpegExecutable() {
  final exeToolPath =
      p.join(p.dirname(Platform.resolvedExecutable), 'tools', 'ffmpeg.exe');
  if (File(exeToolPath).existsSync()) return exeToolPath;

  final cwdToolPath = p.join(Directory.current.path, 'tools', 'ffmpeg.exe');
  if (File(cwdToolPath).existsSync()) return cwdToolPath;

  return 'ffmpeg';
}

void _showTopNotice(BuildContext context, String message) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) {
      final tokens = _themeTokens(context);
      return Positioned(
        top: 24,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(tokens.cardRadius),
                  border: Border.all(color: const Color(0xFFE5484D)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.block_rounded,
                        color: Color(0xFFE5484D), size: 20),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        message,
                        style: TextStyle(color: tokens.ink, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 4), () {
    if (entry.mounted) entry.remove();
  });
}

void _openPath(String path) {
  if (Platform.isWindows) {
    Process.run('start', ['', path], runInShell: true);
  }
}

void _openBundledThirdPartyNotices() {
  if (!Platform.isWindows) return;

  final executableDir = p.dirname(Platform.resolvedExecutable);
  final candidates = [
    p.join(executableDir, 'licenses', 'THIRD_PARTY_NOTICES.txt'),
    p.join(Directory.current.path, 'licenses', 'THIRD_PARTY_NOTICES.txt'),
    p.join(Directory.current.path, '..', 'THIRD_PARTY_NOTICES.md'),
    p.join(Directory.current.path, 'THIRD_PARTY_NOTICES.md'),
  ];
  final noticePath = candidates.firstWhere(
    (candidate) => File(candidate).existsSync(),
    orElse: () => candidates.first,
  );

  _openPath(noticePath);
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

AppThemeTokens _themeTokens(BuildContext context) {
  return Theme.of(context).extension<AppThemeTokens>() ??
      const AppThemeTokens(
        background: Color(0xFFF5F5F7),
        surface: Colors.white,
        surfaceMuted: Color(0xFFFAFAFC),
        hover: Color(0xFFF0F7FF),
        ink: Color(0xFF1D1D1F),
        muted: Color(0xFF6E6E73),
        primary: Color(0xFF0066CC),
        border: Color(0xFFE0E0E0),
        cardRadius: 14,
      );
}
