import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

class FileSelector extends StatelessWidget {
  final AppStrings strings;
  final int selectedFileCount;
  final Function(List<String>) onFilesSelected;

  const FileSelector({
    super.key,
    required this.strings,
    required this.selectedFileCount,
    required this.onFilesSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 360),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF272729),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.selectFiles,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedFileCount > 0
                ? strings.selectedCount(selectedFileCount)
                : strings.noFiles,
            style: const TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: DragTarget<List<String>>(
              onWillAcceptWithDetails: (data) => true,
              onAcceptWithDetails: (details) {
                onFilesSelected(details.data);
              },
              builder: (context, candidateData, rejectedData) {
                final active = candidateData.isNotEmpty;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF2A2A2C) : const Color(0xFF252527),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : const Color(0xFF3A3A3C),
                      width: active ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Color(0x29D2D2D7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.file_upload_outlined,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        strings.dropFiles,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            allowMultiple: true,
                          );
                          if (result != null) {
                            onFilesSelected(result.paths.whereType<String>().toList());
                          }
                        },
                        icon: const Icon(Icons.folder_open_outlined, size: 18),
                        label: Text(strings.browseFiles),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
