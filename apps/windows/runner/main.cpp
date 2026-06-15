#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

void EnableHighDpiAwareness() {
  const HMODULE user32 = ::LoadLibraryW(L"user32.dll");
  if (user32 != nullptr) {
    using SetProcessDpiAwarenessContextFn =
        BOOL(WINAPI *)(DPI_AWARENESS_CONTEXT);
    const auto set_process_dpi_awareness_context =
        reinterpret_cast<SetProcessDpiAwarenessContextFn>(
            ::GetProcAddress(user32, "SetProcessDpiAwarenessContext"));
    if (set_process_dpi_awareness_context != nullptr &&
        set_process_dpi_awareness_context(
            DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)) {
      ::FreeLibrary(user32);
      return;
    }
    ::FreeLibrary(user32);
  }

  const HMODULE shcore = ::LoadLibraryW(L"shcore.dll");
  if (shcore != nullptr) {
    using SetProcessDpiAwarenessFn = HRESULT(WINAPI *)(int);
    const auto set_process_dpi_awareness =
        reinterpret_cast<SetProcessDpiAwarenessFn>(
            ::GetProcAddress(shcore, "SetProcessDpiAwareness"));
    constexpr int kProcessPerMonitorDpiAware = 2;
    if (set_process_dpi_awareness != nullptr &&
        SUCCEEDED(set_process_dpi_awareness(kProcessPerMonitorDpiAware))) {
      ::FreeLibrary(shcore);
      return;
    }
    ::FreeLibrary(shcore);
  }

  ::SetProcessDPIAware();
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  EnableHighDpiAwareness();

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Format Converter", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
