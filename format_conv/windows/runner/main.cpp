#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <iostream>
#include <memory>
#include <vector>

#include "flutter/generated_plugin_registrant.h"
#include "runner/flutter_window.h"
#include "runner/utils.h"
#include "runner/window_configuration.h"
#include "runner/win32_window.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t* command_line, _In_ int show_command) {
  // Attach to console if available (for debug output).
  CreateAndAttachConsole();

  // Initialize COM for the Flutter engine.
  CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // Create the Dart project.
  flutter::DartProject project(GetExecutableDirectory());

  // Create the Flutter window.
  FlutterWindow window(project);
  POINT origin = {10, 10};
  SIZE size = {kFlutterWindowWidth, kFlutterWindowHeight};
  if (!window.Create(kFlutterWindowTitle, origin, size)) {
    return EXIT_FAILURE;
  }

  // Run the message loop.
  MSG msg;
  while (GetMessage(&msg, nullptr, 0, 0)) {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }

  CoUninitialize();
  return EXIT_SUCCESS;
}
