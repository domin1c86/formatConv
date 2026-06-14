cmake_minimum_required(VERSION 3.14)
project(windows_runner LANGUAGES CXX)

set(BINARY_NAME "format_conv")

add_executable(${BINARY_NAME} WIN32
  "runner/main.cpp"
  "runner/window_configuration.h"
  "runner/resource.h"
  "runner/Runner.rc"
  "runner/flutter_window.cpp"
  "runner/flutter_window.h"
  "runner/win32_window.cpp"
  "runner/win32_window.h"
  "runner/utils.cpp"
  "runner/utils.h"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

apply_standard_settings(${BINARY_NAME})

target_compile_definitions(${BINARY_NAME} PRIVATE NOMINMAX)

target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)

target_include_directories(${BINARY_NAME} PRIVATE
  "${CMAKE_SOURCE_DIR}"
)

add_dependencies(${BINARY_NAME> flutter_assemble)
