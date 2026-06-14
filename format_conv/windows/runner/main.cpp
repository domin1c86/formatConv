#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <iostream>

#include "flutter/generated_plugin_registrant.h"
#include "runner/flutter_window.h"
#include "runner/utils.h"
#include "runner/window_configuration.h"
#include "runner/win32_window.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t* command_line, _In_ int show_command) {
  std::cout << "Format Converter - Windows Runner" << std::endl;
  return EXIT_SUCCESS;
}
