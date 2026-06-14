#include <flutter/flutter_engine.h>
#include <flutter/flutter_window_controller.h>

#include <cstdlib>
#include <iostream>
#include <memory>
#include <vector>

#include "flutter/generated_plugin_registrant.h"

int main(int argc, char** argv) {
  // Initialize the Flutter engine
  std::vector<std::string> arguments(argv, argv + argc);
  flutter::FlutterProjectBundle project_bundle(arguments);
  auto engine = std::make_unique<flutter::FlutterEngine>(project_bundle);

  if (!engine->Run()) {
    std::cerr << "Failed to start Flutter engine" << std::endl;
    return EXIT_FAILURE;
  }

  // Register plugins
  RegisterPlugins(engine.get());

  // Create the window controller
  flutter::FlutterWindowController window_controller(
      engine->engine()->GetOpenGLProcAddressResolver());

  if (!window_controller.CreateWindow(800, 600, "Format Converter",
                                       engine->engine())) {
    std::cerr << "Failed to create window" << std::endl;
    return EXIT_FAILURE;
  }

  window_controller.RunEventLoop();
  return EXIT_SUCCESS;
}
